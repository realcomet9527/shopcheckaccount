const bun = @import("../global.zig");
const string = bun.string;
const Output = bun.Output;
const Global = bun.Global;
const Environment = bun.Environment;
const strings = bun.strings;
const MutableString = bun.MutableString;
const StoredFileDescriptorType = bun.StoredFileDescriptorType;
const stringZ = bun.stringZ;
const default_allocator = bun.default_allocator;
const C = bun.C;
const Api = @import("../api/schema.zig").Api;
const std = @import("std");
const options = @import("../options.zig");
const cache = @import("../cache.zig");
const logger = @import("../logger.zig");
const js_ast = @import("../js_ast.zig");

const fs = @import("../fs.zig");
const resolver = @import("./resolver.zig");
const js_lexer = @import("../js_lexer.zig");
const resolve_path = @import("./resolve_path.zig");
// Assume they're not going to have hundreds of main fields or browser map
// so use an array-backed hash table instead of bucketed
const MainFieldMap = std.StringArrayHashMap(string);
pub const BrowserMap = std.StringArrayHashMap(string);
pub const MacroImportReplacementMap = std.StringArrayHashMap(string);
pub const MacroMap = std.StringArrayHashMapUnmanaged(MacroImportReplacementMap);

const ScriptsMap = std.StringArrayHashMap(string);

pub const PackageJSON = struct {
    pub const LoadFramework = enum {
        none,
        development,
        production,
    };

    pub fn generateHash(package_json: *PackageJSON) void {
        var hashy: [1024]u8 = undefined;
        std.mem.set(u8, &hashy, 0);
        var used: usize = 0;
        std.mem.copy(u8, &hashy, package_json.name);
        used = package_json.name.len;

        hashy[used] = '@';
        used += 1;
        std.mem.copy(u8, hashy[used..], package_json.version);
        used += package_json.version.len;

        package_json.hash = std.hash.Murmur3_32.hash(hashy[0..used]);
    }

    const node_modules_path = std.fs.path.sep_str ++ "node_modules" ++ std.fs.path.sep_str;
    pub fn nameForImport(this: *const PackageJSON, allocator: std.mem.Allocator) !string {
        if (strings.indexOf(this.source.path.text, node_modules_path)) |_| {
            return this.name;
        } else {
            const parent = this.source.path.name.dirWithTrailingSlash();
            if (strings.indexOf(parent, fs.FileSystem.instance.top_level_dir)) |i| {
                const relative_dir = parent[i + fs.FileSystem.instance.top_level_dir.len ..];
                var out_dir = try allocator.alloc(u8, relative_dir.len + 2);
                std.mem.copy(u8, out_dir[2..], relative_dir);
                out_dir[0] = '.';
                out_dir[1] = '/';
                return out_dir;
            }

            return this.name;
        }
    }

    pub const FrameworkRouterPair = struct {
        framework: *options.Framework,
        router: *options.RouteConfig,
        loaded_routes: bool = false,
    };

    name: string = "",
    source: logger.Source,
    main_fields: MainFieldMap,
    module_type: options.ModuleType,
    version: string = "",
    hash: u32 = 0xDEADBEEF,

    scripts: ?*ScriptsMap = null,

    // Present if the "browser" field is present. This field is intended to be
    // used by bundlers and lets you redirect the paths of certain 3rd-party
    // modules that don't work in the browser to other modules that shim that
    // functionality. That way you don't have to rewrite the code for those 3rd-
    // party modules. For example, you might remap the native "util" node module
    // to something like https://www.npmjs.com/package/util so it works in the
    // browser.
    //
    // This field contains a mapping of absolute paths to absolute paths. Mapping
    // to an empty path indicates that the module is disabled. As far as I can
    // tell, the official spec is an abandoned GitHub repo hosted by a user account:
    // https://github.com/defunctzombie/package-browser-field-spec. The npm docs
    // say almost nothing: https://docs.npmjs.com/files/package.json.
    //
    // Note that the non-package "browser" map has to be checked twice to match
    // Webpack's behavior: once before resolution and once after resolution. It
    // leads to some unintuitive failure cases that we must emulate around missing
    // file extensions:
    //
    // * Given the mapping "./no-ext": "./no-ext-browser.js" the query "./no-ext"
    //   should match but the query "./no-ext.js" should NOT match.
    //
    // * Given the mapping "./ext.js": "./ext-browser.js" the query "./ext.js"
    //   should match and the query "./ext" should ALSO match.
    //
    browser_map: BrowserMap,

    exports: ?ExportsMap = null,

    pub inline fn isAppPackage(this: *const PackageJSON) bool {
        return this.hash == 0xDEADBEEF;
    }

    fn loadDefineDefaults(
        env: *options.Env,
        json: *const js_ast.E.Object,
        allocator: std.mem.Allocator,
    ) !void {
        var valid_count: usize = 0;
        for (json.properties.slice()) |prop| {
            if (prop.value.?.data != .e_string) continue;
            valid_count += 1;
        }

        env.defaults.shrinkRetainingCapacity(0);
        env.defaults.ensureTotalCapacity(allocator, valid_count) catch {};

        for (json.properties.slice()) |prop| {
            if (prop.value.?.data != .e_string) continue;
            env.defaults.appendAssumeCapacity(.{
                .key = prop.key.?.data.e_string.string(allocator) catch unreachable,
                .value = prop.value.?.data.e_string.string(allocator) catch unreachable,
            });
        }
    }

    fn loadOverrides(
        framework: *options.Framework,
        json: *const js_ast.E.Object,
        allocator: std.mem.Allocator,
    ) void {
        var valid_count: usize = 0;
        for (json.properties.slice()) |prop| {
            if (prop.value.?.data != .e_string) continue;
            valid_count += 1;
        }

        var buffer = allocator.alloc([]const u8, valid_count * 2) catch unreachable;
        var keys = buffer[0..valid_count];
        var values = buffer[valid_count..];
        var i: usize = 0;
        for (json.properties.slice()) |prop| {
            if (prop.value.?.data != .e_string) continue;
            keys[i] = prop.key.?.data.e_string.string(allocator) catch unreachable;
            values[i] = prop.value.?.data.e_string.string(allocator) catch unreachable;
            i += 1;
        }
        framework.override_modules = Api.StringMap{ .keys = keys, .values = values };
    }

    fn loadDefineExpression(
        env: *options.Env,
        json: *const js_ast.E.Object,
        allocator: std.mem.Allocator,
    ) anyerror!void {
        for (json.properties.slice()) |prop| {
            switch (prop.key.?.data) {
                .e_string => |e_str| {
                    const str = e_str.string(allocator) catch "";

                    if (strings.eqlComptime(str, "defaults")) {
                        switch (prop.value.?.data) {
                            .e_object => |obj| {
                                try loadDefineDefaults(env, obj, allocator);
                            },
                            else => {
                                env.defaults.shrinkRetainingCapacity(0);
                            },
                        }
                    } else if (strings.eqlComptime(str, ".env")) {
                        switch (prop.value.?.data) {
                            .e_string => |value_str| {
                                env.setBehaviorFromPrefix(value_str.string(allocator) catch "");
                            },
                            else => {
                                env.behavior = .disable;
                                env.prefix = "";
                            },
                        }
                    }
                },
                else => continue,
            }
        }
    }

    fn loadFrameworkExpression(
        framework: *options.Framework,
        json: js_ast.Expr,
        allocator: std.mem.Allocator,
        comptime read_define: bool,
    ) bool {
        if (json.asProperty("client")) |client| {
            if (client.expr.asString(allocator)) |str| {
                if (str.len > 0) {
                    framework.client.path = str;
                    framework.client.kind = .client;
                }
            }
        }

        if (json.asProperty("fallback")) |client| {
            if (client.expr.asString(allocator)) |str| {
                if (str.len > 0) {
                    framework.fallback.path = str;
                    framework.fallback.kind = .fallback;
                }
            }
        }

        if (json.asProperty("css")) |css_prop| {
            if (css_prop.expr.asString(allocator)) |str| {
                if (strings.eqlComptime(str, "onimportcss")) {
                    framework.client_css_in_js = .facade_onimportcss;
                } else {
                    framework.client_css_in_js = .facade;
                }
            }
        }

        if (json.asProperty("override")) |override| {
            if (override.expr.data == .e_object) {
                loadOverrides(framework, override.expr.data.e_object, allocator);
            }
        }

        if (comptime read_define) {
            if (json.asProperty("define")) |defines| {
                var skip_fallback = false;
                if (defines.expr.asProperty("client")) |client| {
                    if (client.expr.data == .e_object) {
                        const object = client.expr.data.e_object;
                        framework.client.env = options.Env.init(
                            allocator,
                        );

                        loadDefineExpression(&framework.client.env, object, allocator) catch {};
                        framework.fallback.env = framework.client.env;
                        skip_fallback = true;
                    }
                }

                if (!skip_fallback) {
                    if (defines.expr.asProperty("fallback")) |client| {
                        if (client.expr.data == .e_object) {
                            const object = client.expr.data.e_object;
                            framework.fallback.env = options.Env.init(
                                allocator,
                            );

                            loadDefineExpression(&framework.fallback.env, object, allocator) catch {};
                        }
                    }
                }

                if (defines.expr.asProperty("server")) |server| {
                    if (server.expr.data == .e_object) {
                        const object = server.expr.data.e_object;
                        framework.server.env = options.Env.init(
                            allocator,
                        );

                        loadDefineExpression(&framework.server.env, object, allocator) catch {};
                    }
                }
            }
        }

        if (json.asProperty("server")) |server| {
            if (server.expr.asString(allocator)) |str| {
                if (str.len > 0) {
                    framework.server.path = str;
                    framework.server.kind = .server;
                }
            }
        }

        return framework.client.isEnabled() or framework.server.isEnabled() or framework.fallback.isEnabled();
    }

    pub fn loadFrameworkWithPreference(
        package_json: *const PackageJSON,
        pair: *FrameworkRouterPair,
        json: js_ast.Expr,
        allocator: std.mem.Allocator,
        comptime read_defines: bool,
        comptime load_framework: LoadFramework,
    ) void {
        const framework_object = json.asProperty("framework") orelse return;

        if (framework_object.expr.asProperty("displayName")) |name| {
            if (name.expr.asString(allocator)) |str| {
                if (str.len > 0) {
                    pair.framework.display_name = str;
                }
            }
        }

        if (json.get("version")) |version| {
            if (version.asString(allocator)) |str| {
                if (str.len > 0) {
                    pair.framework.version = str;
                }
            }
        }

        if (framework_object.expr.asProperty("static")) |static_prop| {
            if (static_prop.expr.asString(allocator)) |str| {
                if (str.len > 0) {
                    pair.router.static_dir = str;
                    pair.router.static_dir_enabled = true;
                }
            }
        }

        if (framework_object.expr.asProperty("assetPrefix")) |asset_prefix| {
            if (asset_prefix.expr.asString(allocator)) |_str| {
                const str = std.mem.trimRight(u8, _str, " ");
                if (str.len > 0) {
                    pair.router.asset_prefix_path = str;
                }
            }
        }

        if (!pair.router.routes_enabled) {
            if (framework_object.expr.asProperty("router")) |router| {
                if (router.expr.asProperty("dir")) |route_dir| {
                    switch (route_dir.expr.data) {
                        .e_string => |estr| {
                            const str = estr.string(allocator) catch unreachable;
                            if (str.len > 0) {
                                pair.router.dir = str;
                                pair.router.possible_dirs = &[_]string{};

                                pair.loaded_routes = true;
                            }
                        },
                        .e_array => |array| {
                            var count: usize = 0;
                            const items = array.items.slice();
                            for (items) |item| {
                                count += @boolToInt(item.data == .e_string and item.data.e_string.utf8.len > 0);
                            }
                            switch (count) {
                                0 => {},
                                1 => {
                                    const str = items[0].data.e_string.string(allocator) catch unreachable;
                                    if (str.len > 0) {
                                        pair.router.dir = str;
                                        pair.router.possible_dirs = &[_]string{};

                                        pair.loaded_routes = true;
                                    }
                                },
                                else => {
                                    const list = allocator.alloc(string, count) catch unreachable;

                                    var list_i: usize = 0;
                                    for (items) |item| {
                                        if (item.data == .e_string and item.data.e_string.utf8.len > 0) {
                                            list[list_i] = item.data.e_string.string(allocator) catch unreachable;
                                            list_i += 1;
                                        }
                                    }

                                    pair.router.dir = list[0];
                                    pair.router.possible_dirs = list;

                                    pair.loaded_routes = true;
                                },
                            }
                        },
                        else => {},
                    }
                }

                if (router.expr.asProperty("extensions")) |extensions_expr| {
                    if (extensions_expr.expr.asArray()) |*array| {
                        var valid_count: usize = 0;

                        while (array.next()) |expr| {
                            if (expr.data != .e_string) continue;
                            const e_str: *const js_ast.E.String = expr.data.e_string;
                            if (e_str.utf8.len == 0 or e_str.utf8[0] != '.') continue;
                            valid_count += 1;
                        }

                        if (valid_count > 0) {
                            var extensions = allocator.alloc(string, valid_count) catch unreachable;
                            array.index = 0;
                            var i: usize = 0;

                            // We don't need to allocate the strings because we keep the package.json source string in memory
                            while (array.next()) |expr| {
                                if (expr.data != .e_string) continue;
                                const e_str: *const js_ast.E.String = expr.data.e_string;
                                if (e_str.utf8.len == 0 or e_str.utf8[0] != '.') continue;
                                extensions[i] = e_str.utf8;
                                i += 1;
                            }
                        }
                    }
                }
            }
        }

        switch (comptime load_framework) {
            .development => {
                if (framework_object.expr.asProperty("development")) |env| {
                    if (loadFrameworkExpression(pair.framework, env.expr, allocator, read_defines)) {
                        pair.framework.package = package_json.nameForImport(allocator) catch unreachable;
                        pair.framework.development = true;
                        if (env.expr.asProperty("static")) |static_prop| {
                            if (static_prop.expr.asString(allocator)) |str| {
                                if (str.len > 0) {
                                    pair.router.static_dir = str;
                                    pair.router.static_dir_enabled = true;
                                }
                            }
                        }

                        return;
                    }
                }
            },
            .production => {
                if (framework_object.expr.asProperty("production")) |env| {
                    if (loadFrameworkExpression(pair.framework, env.expr, allocator, read_defines)) {
                        pair.framework.package = package_json.nameForImport(allocator) catch unreachable;
                        pair.framework.development = false;

                        if (env.expr.asProperty("static")) |static_prop| {
                            if (static_prop.expr.asString(allocator)) |str| {
                                if (str.len > 0) {
                                    pair.router.static_dir = str;
                                    pair.router.static_dir_enabled = true;
                                }
                            }
                        }

                        return;
                    }
                }
            },
            else => unreachable,
        }

        if (loadFrameworkExpression(pair.framework, framework_object.expr, allocator, read_defines)) {
            pair.framework.package = package_json.nameForImport(allocator) catch unreachable;
            pair.framework.development = false;
        }
    }

    pub fn parseMacrosJSON(
        allocator: std.mem.Allocator,
        macros: js_ast.Expr,
        log: *logger.Log,
        json_source: *const logger.Source,
    ) MacroMap {
        var macro_map = MacroMap{};
        if (macros.data != .e_object) return macro_map;

        const properties = macros.data.e_object.properties.slice();

        for (properties) |property| {
            const key = property.key.?.asString(allocator) orelse continue;
            if (!resolver.isPackagePath(key)) {
                log.addRangeWarningFmt(
                    json_source,
                    json_source.rangeOfString(property.key.?.loc),
                    allocator,
                    "\"{s}\" is not a package path. \"macros\" remaps package paths to macros. Skipping.",
                    .{key},
                ) catch unreachable;
                continue;
            }

            const value = property.value.?;
            if (value.data != .e_object) {
                log.addWarningFmt(
                    json_source,
                    value.loc,
                    allocator,
                    "Invalid macro remapping in \"{s}\": expected object where the keys are import names and the value is a string path to replace",
                    .{key},
                ) catch unreachable;
                continue;
            }

            const remap_properties = value.data.e_object.properties.slice();
            if (remap_properties.len == 0) continue;

            var map = MacroImportReplacementMap.init(allocator);
            map.ensureUnusedCapacity(remap_properties.len) catch unreachable;
            for (remap_properties) |remap| {
                const import_name = remap.key.?.asString(allocator) orelse continue;
                const remap_value = remap.value.?;
                if (remap_value.data != .e_string or remap_value.data.e_string.utf8.len == 0) {
                    log.addWarningFmt(
                        json_source,
                        remap_value.loc,
                        allocator,
                        "Invalid macro remapping for import \"{s}\": expected string to remap to. e.g. \"graphql\": \"bun-macro-relay\" ",
                        .{import_name},
                    ) catch unreachable;
                    continue;
                }

                const remap_value_str = remap_value.data.e_string.utf8;

                map.putAssumeCapacityNoClobber(import_name, remap_value_str);
            }

            if (map.count() > 0) {
                macro_map.put(allocator, key, map) catch unreachable;
            }
        }

        return macro_map;
    }

    pub fn parse(
        comptime ResolverType: type,
        r: *ResolverType,
        input_path: string,
        dirname_fd: StoredFileDescriptorType,
        comptime generate_hash: bool,
        comptime include_scripts: bool,
    ) ?PackageJSON {

        // TODO: remove this extra copy
        const parts = [_]string{ input_path, "package.json" };
        const package_json_path_ = r.fs.abs(&parts);
        const package_json_path = r.fs.dirname_store.append(@TypeOf(package_json_path_), package_json_path_) catch unreachable;

        const entry = r.caches.fs.readFile(
            r.fs,
            package_json_path,
            dirname_fd,
            false,
            null,
        ) catch |err| {
            if (err != error.IsDir) {
                r.log.addErrorFmt(null, logger.Loc.Empty, r.allocator, "Cannot read file \"{s}\": {s}", .{ r.prettyPath(fs.Path.init(input_path)), @errorName(err) }) catch unreachable;
            }

            return null;
        };

        if (r.debug_logs) |*debug| {
            debug.addNoteFmt("The file \"{s}\" exists", .{package_json_path}) catch unreachable;
        }

        const key_path = fs.Path.init(package_json_path);

        var json_source = logger.Source.initPathString(key_path.text, entry.contents);
        json_source.path.pretty = r.prettyPath(json_source.path);

        const json: js_ast.Expr = (r.caches.json.parseJSON(r.log, json_source, r.allocator) catch |err| {
            if (Environment.isDebug) {
                Output.printError("{s}: JSON parse error: {s}", .{ package_json_path, @errorName(err) });
            }
            return null;
        } orelse return null);

        var package_json = PackageJSON{
            .name = "",
            .version = "",
            .hash = 0xDEADBEEF,
            .source = json_source,
            .module_type = .unknown,
            .browser_map = BrowserMap.init(r.allocator),
            .main_fields = MainFieldMap.init(r.allocator),
        };

        // Note: we tried rewriting this to be fewer loops over all the properties (asProperty loops over each)
        // The end result was: it's not faster! Sometimes, it's slower.
        // It's hard to say why.
        // Feels like a codegen issue.
        // or that looping over every property doesn't really matter because most package.jsons are < 20 properties
        if (json.asProperty("version")) |version_json| {
            if (version_json.expr.asString(r.allocator)) |version_str| {
                if (version_str.len > 0) {
                    package_json.version = r.allocator.dupe(u8, version_str) catch unreachable;
                }
            }
        }

        if (json.asProperty("name")) |version_json| {
            if (version_json.expr.asString(r.allocator)) |version_str| {
                if (version_str.len > 0) {
                    package_json.name = r.allocator.dupe(u8, version_str) catch unreachable;
                }
            }
        }

        if (json.asProperty("type")) |type_json| {
            if (type_json.expr.asString(r.allocator)) |type_str| {
                switch (options.ModuleType.List.get(type_str) orelse options.ModuleType.unknown) {
                    .cjs => {
                        package_json.module_type = .cjs;
                    },
                    .esm => {
                        package_json.module_type = .esm;
                    },
                    .unknown => {
                        r.log.addRangeWarningFmt(
                            &json_source,
                            json_source.rangeOfString(type_json.loc),
                            r.allocator,
                            "\"{s}\" is not a valid value for \"type\" field (must be either \"commonjs\" or \"module\")",
                            .{type_str},
                        ) catch unreachable;
                    },
                }
            } else {
                r.log.addWarning(&json_source, type_json.loc, "The value for \"type\" must be a string") catch unreachable;
            }
        }

        // Read the "main" fields
        for (r.opts.main_fields) |main| {
            if (json.asProperty(main)) |main_json| {
                const expr: js_ast.Expr = main_json.expr;

                if ((expr.asString(r.allocator))) |str| {
                    if (str.len > 0) {
                        package_json.main_fields.put(main, r.allocator.dupe(u8, str) catch unreachable) catch unreachable;
                    }
                }
            }
        }

        // Read the "browser" property, but only when targeting the browser
        if (r.opts.platform.supportsBrowserField()) {
            // We both want the ability to have the option of CJS vs. ESM and the
            // option of having node vs. browser. The way to do this is to use the
            // object literal form of the "browser" field like this:
            //
            //   "main": "dist/index.node.cjs.js",
            //   "module": "dist/index.node.esm.js",
            //   "browser": {
            //     "./dist/index.node.cjs.js": "./dist/index.browser.cjs.js",
            //     "./dist/index.node.esm.js": "./dist/index.browser.esm.js"
            //   },
            //
            if (json.asProperty("browser")) |browser_prop| {
                switch (browser_prop.expr.data) {
                    .e_object => |obj| {
                        // The value is an object

                        // Remap all files in the browser field
                        for (obj.properties.slice()) |*prop| {
                            var _key_str = (prop.key orelse continue).asString(r.allocator) orelse continue;
                            const value: js_ast.Expr = prop.value orelse continue;

                            // Normalize the path so we can compare against it without getting
                            // confused by "./". There is no distinction between package paths and
                            // relative paths for these values because some tools (i.e. Browserify)
                            // don't make such a distinction.
                            //
                            // This leads to weird things like a mapping for "./foo" matching an
                            // import of "foo", but that's actually not a bug. Or arguably it's a
                            // bug in Browserify but we have to replicate this bug because packages
                            // do this in the wild.
                            const key = r.allocator.dupe(u8, r.fs.normalize(_key_str)) catch unreachable;

                            switch (value.data) {
                                .e_string => |str| {
                                    // If this is a string, it's a replacement package
                                    package_json.browser_map.put(key, str.string(r.allocator) catch unreachable) catch unreachable;
                                },
                                .e_boolean => |boolean| {
                                    if (!boolean.value) {
                                        package_json.browser_map.put(key, "") catch unreachable;
                                    }
                                },
                                else => {
                                    r.log.addWarning(&json_source, value.loc, "Each \"browser\" mapping must be a string or boolean") catch unreachable;
                                },
                            }
                        }
                    },
                    else => {},
                }
            }
        }

        if (json.asProperty("exports")) |exports_prop| {
            if (ExportsMap.parse(r.allocator, &json_source, r.log, exports_prop.expr)) |exports_map| {
                package_json.exports = exports_map;
            }
        }

        // used by `bun run`
        if (include_scripts) {
            read_scripts: {
                if (json.asProperty("scripts")) |scripts_prop| {
                    if (scripts_prop.expr.data == .e_object) {
                        const scripts_obj = scripts_prop.expr.data.e_object;

                        var count: usize = 0;
                        for (scripts_obj.properties.slice()) |prop| {
                            const key = prop.key.?.asString(r.allocator) orelse continue;
                            const value = prop.value.?.asString(r.allocator) orelse continue;

                            count += @as(usize, @boolToInt(key.len > 0 and value.len > 0));
                        }

                        if (count == 0) break :read_scripts;
                        var scripts = ScriptsMap.init(r.allocator);
                        scripts.ensureUnusedCapacity(count) catch break :read_scripts;

                        for (scripts_obj.properties.slice()) |prop| {
                            const key = prop.key.?.asString(r.allocator) orelse continue;
                            const value = prop.value.?.asString(r.allocator) orelse continue;

                            if (!(key.len > 0 and value.len > 0)) continue;

                            scripts.putAssumeCapacity(key, value);
                        }

                        package_json.scripts = r.allocator.create(ScriptsMap) catch unreachable;
                        package_json.scripts.?.* = scripts;
                    }
                }
            }
        }

        // TODO: side effects

        if (generate_hash) {
            if (package_json.name.len > 0 and package_json.version.len > 0) {
                package_json.generateHash();
            }
        }

        return package_json;
    }

    pub fn hashModule(this: *const PackageJSON, module: string) u32 {
        var hasher = std.hash.Wyhash.init(0);
        hasher.update(std.mem.asBytes(&this.hash));
        hasher.update(module);

        return @truncate(u32, hasher.final());
    }
};

pub const ExportsMap = struct {
    root: Entry,
    exports_range: logger.Range = logger.Range.None,

    pub fn parse(allocator: std.mem.Allocator, source: *const logger.Source, log: *logger.Log, json: js_ast.Expr) ?ExportsMap {
        var visitor = Visitor{ .allocator = allocator, .source = source, .log = log };

        const root = visitor.visit(json);

        if (root.data == .@"null") {
            return null;
        }

        return ExportsMap{
            .root = root,
            .exports_range = source.rangeOfString(json.loc),
        };
    }

    pub const Visitor = struct {
        allocator: std.mem.Allocator,
        source: *const logger.Source,
        log: *logger.Log,

        pub fn visit(this: Visitor, expr: js_ast.Expr) Entry {
            var first_token: logger.Range = logger.Range.None;

            switch (expr.data) {
                .e_null => {
                    return Entry{ .first_token = js_lexer.rangeOfIdentifier(this.source, expr.loc), .data = .{ .@"null" = void{} } };
                },
                .e_string => |str| {
                    return Entry{
                        .data = .{
                            .string = str.string(this.allocator) catch unreachable,
                        },
                        .first_token = this.source.rangeOfString(expr.loc),
                    };
                },
                .e_array => |e_array| {
                    var array = this.allocator.alloc(Entry, e_array.items.len) catch unreachable;
                    for (e_array.items.slice()) |item, i| {
                        array[i] = this.visit(item);
                    }
                    return Entry{
                        .data = .{
                            .array = array,
                        },
                        .first_token = logger.Range{ .loc = expr.loc, .len = 1 },
                    };
                },
                .e_object => |e_obj| {
                    var map_data = Entry.Data.Map.List{};
                    map_data.ensureTotalCapacity(this.allocator, e_obj.*.properties.len) catch unreachable;
                    map_data.len = map_data.capacity;
                    var expansion_keys = this.allocator.alloc(Entry.Data.Map.MapEntry, e_obj.*.properties.len) catch unreachable;
                    var expansion_key_i: usize = 0;
                    var map_data_slices = map_data.slice();
                    var map_data_keys = map_data_slices.items(.key);
                    var map_data_ranges = map_data_slices.items(.key_range);
                    var map_data_entries = map_data_slices.items(.value);
                    var is_conditional_sugar = false;
                    first_token.loc = expr.loc;
                    first_token.len = 1;
                    for (e_obj.properties.slice()) |prop, i| {
                        const key: string = prop.key.?.data.e_string.string(this.allocator) catch unreachable;
                        const key_range: logger.Range = this.source.rangeOfString(prop.key.?.loc);

                        // If exports is an Object with both a key starting with "." and a key
                        // not starting with ".", throw an Invalid Package Configuration error.
                        var cur_is_conditional_sugar = !strings.startsWithChar(key, '.');
                        if (i == 0) {
                            is_conditional_sugar = cur_is_conditional_sugar;
                        } else if (is_conditional_sugar != cur_is_conditional_sugar) {
                            const prev_key_range = map_data_ranges[i - 1];
                            const prev_key = map_data_keys[i - 1];
                            this.log.addRangeWarningFmtWithNote(
                                this.source,
                                key_range,
                                this.allocator,
                                "This object cannot contain keys that both start with \".\" and don't start with \".\"",
                                .{},
                                "The previous key \"{s}\" is incompatible with the current key \"{s}\"",
                                .{ prev_key, key },
                                prev_key_range,
                            ) catch unreachable;
                            map_data.deinit(this.allocator);
                            this.allocator.free(expansion_keys);
                            return Entry{
                                .data = .{ .invalid = void{} },
                                .first_token = first_token,
                            };
                        }

                        map_data_keys[i] = key;
                        map_data_ranges[i] = key_range;
                        map_data_entries[i] = this.visit(prop.value.?);

                        if (strings.endsWithAnyComptime(key, "/*")) {
                            expansion_keys[expansion_key_i] = Entry.Data.Map.MapEntry{
                                .value = map_data_entries[i],
                                .key = key,
                                .key_range = key_range,
                            };
                            expansion_key_i += 1;
                        }
                    }

                    // this leaks a lil, but it's fine.
                    expansion_keys = expansion_keys[0..expansion_key_i];

                    // Let expansion_keys be the list of keys of matchObj ending in "/" or "*",
                    // sorted by length descending.
                    const LengthSorter: type = strings.NewLengthSorter(Entry.Data.Map.MapEntry, "key");
                    var sorter = LengthSorter{};
                    std.sort.sort(Entry.Data.Map.MapEntry, expansion_keys, sorter, LengthSorter.lessThan);

                    return Entry{
                        .data = .{
                            .map = Entry.Data.Map{
                                .list = map_data,
                                .expansion_keys = expansion_keys,
                            },
                        },
                        .first_token = first_token,
                    };
                },
                .e_boolean => {
                    first_token = js_lexer.rangeOfIdentifier(this.source, expr.loc);
                },
                .e_number => {
                    // TODO: range of number
                    first_token.loc = expr.loc;
                    first_token.len = 1;
                },
                else => {
                    first_token.loc = expr.loc;
                },
            }

            this.log.addRangeWarning(this.source, first_token, "This value must be a string, an object, an array, or null") catch unreachable;
            return Entry{
                .data = .{ .invalid = void{} },
                .first_token = first_token,
            };
        }
    };

    pub const Entry = struct {
        first_token: logger.Range,
        data: Data,

        pub const Data = union(Tag) {
            invalid: void,
            @"null": void,
            boolean: bool,
            @"string": string,
            array: []const Entry,
            map: Map,

            pub const Tag = enum {
                @"null",
                string,
                boolean,
                array,
                map,
                invalid,
            };

            pub const Map = struct {
                // This is not a std.ArrayHashMap because we also store the key_range which is a little weird
                pub const List = std.MultiArrayList(MapEntry);
                expansion_keys: []MapEntry,
                list: List,

                pub const MapEntry = struct {
                    key: string,
                    key_range: logger.Range,
                    value: Entry,
                };
            };
        };

        pub fn keysStartWithDot(this: *const Entry) bool {
            return this.data == .map and this.data.map.list.len > 0 and strings.startsWithChar(this.data.map.list.items(.key)[0], '.');
        }

        pub fn valueForKey(this: *const Entry, key_: string) ?Entry {
            switch (this.data) {
                .map => {
                    var slice = this.data.map.list.slice();
                    const keys = slice.items(.key);
                    for (keys) |key, i| {
                        if (strings.eql(key, key_)) {
                            return slice.items(.value)[i];
                        }
                    }

                    return null;
                },
                else => {
                    return null;
                },
            }
        }
    };
};

pub const ESModule = struct {
    pub const ConditionsMap = std.StringArrayHashMap(void);

    debug_logs: ?*resolver.DebugLogs = null,
    conditions: ConditionsMap,
    allocator: std.mem.Allocator,

    pub const Resolution = struct {
        status: Status = Status.Undefined,
        path: string = "",
        debug: Debug = Debug{},

        pub const Debug = struct {
            // This is the range of the token to use for error messages
            token: logger.Range = logger.Range.None,
            // If the status is "UndefinedNoConditionsMatch", this is the set of
            // conditions that didn't match. This information is used for error messages.
            unmatched_conditions: []string = &[_]string{},
        };
    };

    pub const Status = enum {
        Undefined,
        UndefinedNoConditionsMatch, // A more friendly error message for when no conditions are matched
        Null,
        Exact,
        Inexact, // This means we may need to try CommonJS-style extension suffixes

        // Module specifier is an invalid URL, package name or package subpath specifier.
        InvalidModuleSpecifier,

        // package.json configuration is invalid or contains an invalid configuration.
        InvalidPackageConfiguration,

        // Package exports or imports define a target module for the package that is an invalid type or string target.
        InvalidPackageTarget,

        // Package exports do not define or permit a target subpath in the package for the given module.
        PackagePathNotExported,

        // The package or module requested does not exist.
        ModuleNotFound,

        // The resolved path corresponds to a directory, which is not a supported target for module imports.
        UnsupportedDirectoryImport,

        // When a package path is explicitly set to null, that means it's not exported.
        PackagePathDisabled,

        pub inline fn isUndefined(this: Status) bool {
            return switch (this) {
                .Undefined, .UndefinedNoConditionsMatch => true,
                else => false,
            };
        }
    };

    pub const Package = struct {
        name: string,
        subpath: string,

        pub fn parseName(specifier: string) ?string {
            var slash = strings.indexOfCharNeg(specifier, '/');
            if (!strings.startsWithChar(specifier, '@')) {
                slash = if (slash == -1) @intCast(i32, specifier.len) else slash;
                return specifier[0..@intCast(usize, slash)];
            } else {
                if (slash == -1) return null;

                const slash2 = strings.indexOfChar(specifier[@intCast(usize, slash) + 1 ..], '/') orelse
                    specifier[@intCast(u32, slash + 1)..].len;
                return specifier[0 .. @intCast(usize, slash + 1) + slash2];
            }
        }

        pub fn parse(specifier: string, subpath_buf: []u8) ?Package {
            if (specifier.len == 0) return null;
            var package = Package{ .name = parseName(specifier) orelse return null, .subpath = "" };

            if (strings.startsWith(package.name, ".") or strings.indexAnyComptime(package.name, "\\%") != null)
                return null;

            std.mem.copy(u8, subpath_buf[1..], specifier[package.name.len..]);
            subpath_buf[0] = '.';
            package.subpath = subpath_buf[0 .. specifier[package.name.len..].len + 1];
            return package;
        }
    };

    const ReverseKind = enum { exact, pattern, prefix };
    pub const ReverseResolution = struct {
        subpath: string = "",
        token: logger.Range = logger.Range.None,
    };
    const invalid_percent_chars = [_]string{
        "%2f",
        "%2F",
        "%5c",
        "%5C",
    };

    threadlocal var resolved_path_buf_percent: [bun.MAX_PATH_BYTES]u8 = undefined;
    pub fn resolve(r: *const ESModule, package_url: string, subpath: string, exports: ExportsMap.Entry) Resolution {
        var result = r.resolveExports(package_url, subpath, exports);

        if (result.status != .Exact and result.status != .Inexact) {
            return result;
        }

        // If resolved contains any percent encodings of "/" or "\" ("%2f" and "%5C"
        // respectively), then throw an Invalid Module Specifier error.
        const PercentEncoding = @import("../url.zig").PercentEncoding;
        var fbs = std.io.fixedBufferStream(&resolved_path_buf_percent);
        var writer = fbs.writer();
        const len = PercentEncoding.decode(@TypeOf(&writer), &writer, result.path) catch return Resolution{
            .status = .InvalidModuleSpecifier,
            .path = result.path,
            .debug = result.debug,
        };

        const resolved_path = resolved_path_buf_percent[0..len];

        var found: string = "";
        if (strings.contains(resolved_path, invalid_percent_chars[0])) {
            found = invalid_percent_chars[0];
        } else if (strings.contains(resolved_path, invalid_percent_chars[1])) {
            found = invalid_percent_chars[1];
        } else if (strings.contains(resolved_path, invalid_percent_chars[2])) {
            found = invalid_percent_chars[2];
        } else if (strings.contains(resolved_path, invalid_percent_chars[3])) {
            found = invalid_percent_chars[3];
        }

        if (found.len != 0) {
            return Resolution{ .status = .InvalidModuleSpecifier, .path = result.path, .debug = result.debug };
        }

        // If resolved is a directory, throw an Unsupported Directory Import error.
        if (strings.endsWithAnyComptime(resolved_path, "/\\")) {
            return Resolution{ .status = .UnsupportedDirectoryImport, .path = result.path, .debug = result.debug };
        }

        result.path = resolved_path;
        return result;
    }

    fn resolveExports(
        r: *const ESModule,
        package_url: string,
        subpath: string,
        exports: ExportsMap.Entry,
    ) Resolution {
        if (exports.data == .invalid) {
            if (r.debug_logs) |logs| {
                logs.addNote("Invalid package configuration") catch unreachable;
            }

            return Resolution{ .status = .InvalidPackageConfiguration, .debug = .{ .token = exports.first_token } };
        }

        if (strings.eqlComptime(subpath, ".")) {
            var main_export = ExportsMap.Entry{ .data = .{ .@"null" = void{} }, .first_token = logger.Range.None };
            if (switch (exports.data) {
                .string,
                .array,
                => true,
                .map => !exports.keysStartWithDot(),
                else => false,
            }) {
                main_export = exports;
            } else if (exports.data == .map) {
                if (exports.valueForKey(".")) |value| {
                    main_export = value;
                }
            }

            if (main_export.data != .@"null") {
                const result = r.resolveTarget(package_url, main_export, "", false);
                if (result.status != .Null and result.status != .Undefined) {
                    return result;
                }
            }
        } else if (exports.data == .map and exports.keysStartWithDot()) {
            const result = r.resolveImportsExports(subpath, exports, package_url);
            if (result.status != .Null and result.status != .Undefined) {
                return result;
            }

            if (result.status == .Null) {
                return Resolution{ .status = .PackagePathDisabled, .debug = .{ .token = exports.first_token } };
            }
        }

        if (r.debug_logs) |logs| {
            logs.addNoteFmt("The path \"{s}\" was not exported", .{subpath}) catch unreachable;
        }

        return Resolution{ .status = .PackagePathNotExported, .debug = .{ .token = exports.first_token } };
    }

    fn resolveImportsExports(
        r: *const ESModule,
        match_key: string,
        match_obj: ExportsMap.Entry,
        package_url: string,
    ) Resolution {
        if (r.debug_logs) |logs| {
            logs.addNoteFmt("Checking object path map for \"{s}\"", .{match_key}) catch unreachable;
        }

        if (!strings.endsWithChar(match_key, '.')) {
            if (match_obj.valueForKey(match_key)) |target| {
                if (r.debug_logs) |log| {
                    log.addNoteFmt("Found \"{s}\"", .{match_key}) catch unreachable;
                }

                return r.resolveTarget(package_url, target, "", false);
            }
        }

        if (match_obj.data == .map) {
            const expansion_keys = match_obj.data.map.expansion_keys;
            for (expansion_keys) |expansion| {
                // If expansionKey ends in "*" and matchKey starts with but is not equal to
                // the substring of expansionKey excluding the last "*" character
                if (strings.endsWithChar(expansion.key, '*')) {
                    const substr = expansion.key[0 .. expansion.key.len - 1];
                    if (strings.startsWith(match_key, substr) and !strings.eql(match_key, substr)) {
                        const target = expansion.value;
                        const subpath = match_key[expansion.key.len - 1 ..];
                        if (r.debug_logs) |log| {
                            log.addNoteFmt("The key \"{s}\" matched with \"{s}\" left over", .{ expansion.key, subpath }) catch unreachable;
                        }

                        return r.resolveTarget(package_url, target, subpath, true);
                    }
                }

                if (strings.startsWith(match_key, expansion.key)) {
                    const target = expansion.value;
                    const subpath = match_key[expansion.key.len..];
                    if (r.debug_logs) |log| {
                        log.addNoteFmt("The key \"{s}\" matched with \"{s}\" left over", .{ expansion.key, subpath }) catch unreachable;
                    }

                    var result = r.resolveTarget(package_url, target, subpath, false);
                    result.status = if (result.status == .Exact)
                        // Return the object { resolved, exact: false }.
                        .Inexact
                    else
                        result.status;

                    return result;
                }

                if (r.debug_logs) |log| {
                    log.addNoteFmt("The key \"{s}\" did not match", .{expansion.key}) catch unreachable;
                }
            }
        }

        if (r.debug_logs) |log| {
            log.addNoteFmt("No keys matched \"{s}\"", .{match_key}) catch unreachable;
        }

        return Resolution{
            .status = .Null,
            .debug = .{ .token = match_obj.first_token },
        };
    }

    threadlocal var resolve_target_buf: [bun.MAX_PATH_BYTES]u8 = undefined;
    threadlocal var resolve_target_buf2: [bun.MAX_PATH_BYTES]u8 = undefined;
    fn resolveTarget(
        r: *const ESModule,
        package_url: string,
        target: ExportsMap.Entry,
        subpath: string,
        comptime pattern: bool,
    ) Resolution {
        switch (target.data) {
            .string => |str| {
                if (r.debug_logs) |log| {
                    log.addNoteFmt("Checking path \"{s}\" against target \"{s}\"", .{ subpath, str }) catch unreachable;
                    log.increaseIndent() catch unreachable;
                }
                defer {
                    if (r.debug_logs) |log| {
                        log.decreaseIndent() catch unreachable;
                    }
                }

                // If pattern is false, subpath has non-zero length and target
                // does not end with "/", throw an Invalid Module Specifier error.
                if (comptime !pattern) {
                    if (subpath.len > 0 and !strings.endsWithChar(str, '/')) {
                        if (r.debug_logs) |log| {
                            log.addNoteFmt("The target \"{s}\" is invalid because it doesn't end with a \"/\"", .{str}) catch unreachable;
                        }

                        return Resolution{ .path = str, .status = .InvalidModuleSpecifier, .debug = .{ .token = target.first_token } };
                    }
                }

                if (!strings.startsWith(str, "./")) {
                    if (r.debug_logs) |log| {
                        log.addNoteFmt("The target \"{s}\" is invalid because it doesn't start with a \"./\"", .{str}) catch unreachable;
                    }

                    return Resolution{ .path = str, .status = .InvalidPackageTarget, .debug = .{ .token = target.first_token } };
                }

                // If target split on "/" or "\" contains any ".", ".." or "node_modules"
                // segments after the first segment, throw an Invalid Package Target error.
                if (findInvalidSegment(str)) |invalid| {
                    if (r.debug_logs) |log| {
                        log.addNoteFmt("The target \"{s}\" is invalid because it contains an invalid segment \"{s}\"", .{ str, invalid }) catch unreachable;
                    }

                    return Resolution{ .path = str, .status = .InvalidPackageTarget, .debug = .{ .token = target.first_token } };
                }

                // Let resolvedTarget be the URL resolution of the concatenation of packageURL and target.
                var parts = [_]string{ package_url, str };
                const resolved_target = resolve_path.joinStringBuf(&resolve_target_buf, parts, .auto);

                // If target split on "/" or "\" contains any ".", ".." or "node_modules"
                // segments after the first segment, throw an Invalid Package Target error.
                if (findInvalidSegment(resolved_target)) |invalid| {
                    if (r.debug_logs) |log| {
                        log.addNoteFmt("The target \"{s}\" is invalid because it contains an invalid segment \"{s}\"", .{ str, invalid }) catch unreachable;
                    }

                    return Resolution{ .path = str, .status = .InvalidModuleSpecifier, .debug = .{ .token = target.first_token } };
                }

                if (comptime pattern) {
                    // Return the URL resolution of resolvedTarget with every instance of "*" replaced with subpath.
                    const len = std.mem.replacementSize(u8, resolved_target, "*", subpath);
                    _ = std.mem.replace(u8, resolved_target, "*", subpath, &resolve_target_buf2);
                    const result = resolve_target_buf2[0..len];
                    if (r.debug_logs) |log| {
                        log.addNoteFmt("Subsituted \"{s}\" for \"*\" in \".{s}\" to get \".{s}\" ", .{ subpath, resolved_target, result }) catch unreachable;
                    }

                    return Resolution{ .path = result, .status = .Exact, .debug = .{ .token = target.first_token } };
                } else {
                    var parts2 = [_]string{ package_url, str, subpath };
                    const result = resolve_path.joinStringBuf(&resolve_target_buf2, parts2, .auto);
                    if (r.debug_logs) |log| {
                        log.addNoteFmt("Substituted \"{s}\" for \"*\" in \".{s}\" to get \".{s}\" ", .{ subpath, resolved_target, result }) catch unreachable;
                    }

                    return Resolution{ .path = result, .status = .Exact, .debug = .{ .token = target.first_token } };
                }
            },
            .map => |object| {
                var did_find_map_entry = false;
                var last_map_entry_i: usize = 0;

                const slice = object.list.slice();
                const keys = slice.items(.key);
                for (keys) |key, i| {
                    if (strings.eqlComptime(key, "default") or r.conditions.contains(key)) {
                        if (r.debug_logs) |log| {
                            log.addNoteFmt("The key \"{s}\" matched", .{key}) catch unreachable;
                        }

                        var result = r.resolveTarget(package_url, slice.items(.value)[i], subpath, pattern);
                        if (result.status.isUndefined()) {
                            did_find_map_entry = true;
                            last_map_entry_i = i;
                            continue;
                        }

                        return result;
                    }

                    if (r.debug_logs) |log| {
                        log.addNoteFmt("The key \"{s}\" did not match", .{key}) catch unreachable;
                    }
                }

                if (r.debug_logs) |log| {
                    log.addNoteFmt("No keys matched", .{}) catch unreachable;
                }

                var return_target = target;
                // ALGORITHM DEVIATION: Provide a friendly error message if no conditions matched
                if (keys.len > 0 and !target.keysStartWithDot()) {
                    var last_map_entry = ExportsMap.Entry.Data.Map.MapEntry{
                        .key = keys[last_map_entry_i],
                        .value = slice.items(.value)[last_map_entry_i],
                        // key_range is unused, so we don't need to pull up the array for it.
                        .key_range = undefined,
                    };
                    if (did_find_map_entry and
                        last_map_entry.value.data == .map and
                        last_map_entry.value.data.map.list.len > 0 and
                        !last_map_entry.value.keysStartWithDot())
                    {
                        // If a top-level condition did match but no sub-condition matched,
                        // complain about the sub-condition instead of the top-level condition.
                        // This leads to a less confusing error message. For example:
                        //
                        //   "exports": {
                        //     "node": {
                        //       "require": "./dist/bwip-js-node.js"
                        //     }
                        //   },
                        //
                        // We want the warning to say this:
                        //
                        //   note: None of the conditions provided ("require") match any of the
                        //         currently active conditions ("default", "import", "node")
                        //   14 |       "node": {
                        //      |               ^
                        //
                        // We don't want the warning to say this:
                        //
                        //   note: None of the conditions provided ("browser", "electron", "node")
                        //         match any of the currently active conditions ("default", "import", "node")
                        //   7 |   "exports": {
                        //     |              ^
                        //
                        // More information: https://github.com/evanw/esbuild/issues/1484
                        return_target = last_map_entry.value;
                    }

                    return Resolution{
                        .path = "",
                        .status = .UndefinedNoConditionsMatch,
                        .debug = .{
                            .token = target.first_token,
                            .unmatched_conditions = return_target.data.map.list.items(.key),
                        },
                    };
                }

                return Resolution{
                    .path = "",
                    .status = .UndefinedNoConditionsMatch,
                    .debug = .{ .token = target.first_token },
                };
            },
            .array => |array| {
                if (array.len == 0) {
                    if (r.debug_logs) |log| {
                        log.addNoteFmt("The path \"{s}\" is an empty array", .{subpath}) catch unreachable;
                    }

                    return Resolution{ .path = "", .status = .Null, .debug = .{ .token = target.first_token } };
                }

                var last_exception = Status.Undefined;
                var last_debug = Resolution.Debug{ .token = target.first_token };

                for (array) |targetValue| {
                    // Let resolved be the result, continuing the loop on any Invalid Package Target error.
                    const result = r.resolveTarget(package_url, targetValue, subpath, pattern);
                    if (result.status == .InvalidPackageTarget or result.status == .Null) {
                        last_debug = result.debug;
                        last_exception = result.status;
                    }

                    if (result.status.isUndefined()) {
                        continue;
                    }

                    return result;
                }

                return Resolution{ .path = "", .status = last_exception, .debug = last_debug };
            },
            .@"null" => {
                if (r.debug_logs) |log| {
                    log.addNoteFmt("The path \"{s}\" is null", .{subpath}) catch unreachable;
                }

                return Resolution{ .path = "", .status = .Null, .debug = .{ .token = target.first_token } };
            },
            else => {},
        }

        if (r.debug_logs) |logs| {
            logs.addNoteFmt("Invalid package target for path \"{s}\"", .{subpath}) catch unreachable;
        }

        return Resolution{ .status = .InvalidPackageTarget, .debug = .{ .token = target.first_token } };
    }

    fn resolveExportsReverse(
        r: *const ESModule,
        query: string,
        root: ExportsMap.Entry,
    ) ?ReverseResolution {
        if (root.data == .map and root.keysStartWithDot()) {
            if (r.resolveImportsExportsReverse(query, root)) |res| {
                return res;
            }
        }

        return null;
    }

    fn resolveImportsExportsReverse(
        r: *const ESModule,
        query: string,
        match_obj: ExportsMap.Entry,
    ) ?ReverseResolution {
        if (match_obj.data != .map) return null;
        const map = match_obj.data.map;

        if (!strings.endsWithChar(query, "*")) {
            var slices = map.list.slice();
            var keys = slices.items(.key);
            var values = slices.items(.value);
            for (keys) |key, i| {
                if (r.resolveTargetReverse(query, key, values[i], .exact)) |result| {
                    return result;
                }
            }
        }

        for (map.expansion_keys) |expansion| {
            if (strings.endsWithChar(expansion.key, '*')) {
                if (r.resolveTargetReverse(query, expansion.key, expansion.value, .pattern)) |result| {
                    return result;
                }
            }

            if (r.resolveTargetReverse(query, expansion.key, expansion.value, .reverse)) |result| {
                return result;
            }
        }
    }

    threadlocal var resolve_target_reverse_prefix_buf: [bun.MAX_PATH_BYTES]u8 = undefined;
    threadlocal var resolve_target_reverse_prefix_buf2: [bun.MAX_PATH_BYTES]u8 = undefined;

    fn resolveTargetReverse(
        r: *const ESModule,
        query: string,
        key: string,
        target: ExportsMap.Entry,
        comptime kind: ReverseKind,
    ) ?ReverseResolution {
        switch (target.data) {
            .string => |str| {
                switch (comptime kind) {
                    .exact => {
                        if (strings.eql(query, str)) {
                            return ReverseResolution{ .subpath = str, .token = target.first_token };
                        }
                    },
                    .prefix => {
                        if (strings.startsWith(query, str)) {
                            return ReverseResolution{
                                .subpath = std.fmt.bufPrint(&resolve_target_reverse_prefix_buf, "{s}{s}", .{ key, query[str.len..] }) catch unreachable,
                                .token = target.first_token,
                            };
                        }
                    },
                    .pattern => {
                        const key_without_trailing_star = std.mem.trimRight(u8, key, "*");

                        const star = strings.indexOfChar(str, '*') orelse {
                            // Handle the case of no "*"
                            if (strings.eql(query, str)) {
                                return ReverseResolution{ .subpath = key_without_trailing_star, .token = target.first_token };
                            }
                            return null;
                        };

                        // Only support tracing through a single "*"
                        const prefix = str[0..star];
                        const suffix = str[star + 1 ..];
                        if (strings.startsWith(query, prefix) and !strings.containsChar(suffix, '*')) {
                            const after_prefix = query[prefix.len..];
                            if (strings.endsWith(after_prefix, suffix)) {
                                const star_data = after_prefix[0 .. after_prefix.len - suffix.len];
                                return ReverseResolution{
                                    .subpath = std.fmt.bufPrint(
                                        &resolve_target_reverse_prefix_buf2,
                                        "{s}{s}",
                                        .{
                                            key_without_trailing_star,
                                            star_data,
                                        },
                                    ) catch unreachable,
                                    .token = target.first_token,
                                };
                            }
                        }
                    },
                }
            },
            .map => |map| {
                const slice = map.list.slice();
                const keys = slice.items(.key);
                for (keys) |map_key, i| {
                    if (strings.eqlComptime(map_key, "default") or r.conditions.contains(map_key)) {
                        if (r.resolveTargetReverse(query, key, slice.items(.value)[i], kind)) |result| {
                            return result;
                        }
                    }
                }
            },

            .array => |array| {
                for (array) |target_value| {
                    if (r.resolveTargetReverse(query, key, target_value, kind)) |result| {
                        return result;
                    }
                }
            },

            else => {},
        }

        return null;
    }
};

fn findInvalidSegment(path_: string) ?string {
    var slash = strings.indexAnyComptime(path_, "/\\") orelse return "";
    var path = path_[slash + 1 ..];

    while (path.len > 0) {
        var segment = path;
        if (strings.indexAnyComptime(path, "/\\")) |new_slash| {
            segment = path[0..new_slash];
            path = path[new_slash + 1 ..];
        } else {
            path = "";
        }

        switch (segment.len) {
            1 => {
                if (strings.eqlComptimeIgnoreLen(segment, ".")) return segment;
            },
            2 => {
                if (strings.eqlComptimeIgnoreLen(segment, "..")) return segment;
            },
            "node_modules".len => {
                if (strings.eqlComptimeIgnoreLen(segment, "node_modules")) return segment;
            },
            else => {},
        }
    }

    return null;
}
