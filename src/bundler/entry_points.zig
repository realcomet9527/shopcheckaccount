const logger = @import("../logger.zig");
const std = @import("std");
const bun = @import("../global.zig");
const string = bun.string;
const Fs = @import("../fs.zig");
const js_ast = @import("../js_ast.zig");
const Bundler = @import("../bundler.zig").Bundler;
const strings = bun.strings;
pub const FallbackEntryPoint = struct {
    code_buffer: [8096]u8 = undefined,
    path_buffer: [bun.MAX_PATH_BYTES]u8 = undefined,
    source: logger.Source = undefined,
    built_code: string = "",

    pub fn generate(
        entry: *FallbackEntryPoint,
        input_path: string,
        comptime BundlerType: type,
        bundler: *BundlerType,
    ) !void {
        // This is *extremely* naive.
        // The basic idea here is this:
        // --
        // import * as EntryPoint from 'entry-point';
        // import boot from 'framework';
        // boot(EntryPoint);
        // --
        // We go through the steps of printing the code -- only to then parse/transpile it because
        // we want it to go through the linker and the rest of the transpilation process

        const disable_css_imports = bundler.options.framework.?.client_css_in_js != .auto_onimportcss;

        var code: string = undefined;

        if (disable_css_imports) {
            const fmt =
                \\globalThis.Bun_disableCSSImports = true;
                \\import boot from '{s}';
                \\boot(globalThis.__BUN_DATA__);
            ;

            const args = .{
                input_path,
            };

            const count = std.fmt.count(fmt, args);
            if (count < entry.code_buffer.len) {
                code = try std.fmt.bufPrint(&entry.code_buffer, fmt, args);
            } else {
                code = try std.fmt.allocPrint(bundler.allocator, fmt, args);
            }
        } else {
            const fmt =
                \\import boot from '{s}';
                \\boot(globalThis.__BUN_DATA__);
            ;

            const args = .{
                input_path,
            };

            const count = std.fmt.count(fmt, args);
            if (count < entry.code_buffer.len) {
                code = try std.fmt.bufPrint(&entry.code_buffer, fmt, args);
            } else {
                code = try std.fmt.allocPrint(bundler.allocator, fmt, args);
            }
        }

        entry.source = logger.Source.initPathString(input_path, code);
        entry.source.path.namespace = "fallback-entry";
    }
};

pub const ClientEntryPoint = struct {
    code_buffer: [8096]u8 = undefined,
    path_buffer: [bun.MAX_PATH_BYTES]u8 = undefined,
    source: logger.Source = undefined,

    pub fn isEntryPointPath(extname: string) bool {
        return strings.startsWith("entry.", extname);
    }

    pub fn generateEntryPointPath(outbuffer: []u8, original_path: Fs.PathName) string {
        var joined_base_and_dir_parts = [_]string{ original_path.dir, original_path.base };
        var generated_path = Fs.FileSystem.instance.absBuf(&joined_base_and_dir_parts, outbuffer);

        std.mem.copy(u8, outbuffer[generated_path.len..], ".entry");
        generated_path = outbuffer[0 .. generated_path.len + ".entry".len];
        std.mem.copy(u8, outbuffer[generated_path.len..], original_path.ext);
        return outbuffer[0 .. generated_path.len + original_path.ext.len];
    }

    pub fn decodeEntryPointPath(outbuffer: []u8, original_path: Fs.PathName) string {
        var joined_base_and_dir_parts = [_]string{ original_path.dir, original_path.base };
        var generated_path = Fs.FileSystem.instance.absBuf(&joined_base_and_dir_parts, outbuffer);
        var original_ext = original_path.ext;
        if (strings.indexOf(original_path.ext, "entry")) |entry_i| {
            original_ext = original_path.ext[entry_i + "entry".len ..];
        }

        std.mem.copy(u8, outbuffer[generated_path.len..], original_ext);

        return outbuffer[0 .. generated_path.len + original_ext.len];
    }

    pub fn generate(entry: *ClientEntryPoint, comptime BundlerType: type, bundler: *BundlerType, original_path: Fs.PathName, client: string) !void {

        // This is *extremely* naive.
        // The basic idea here is this:
        // --
        // import * as EntryPoint from 'entry-point';
        // import boot from 'framework';
        // boot(EntryPoint);
        // --
        // We go through the steps of printing the code -- only to then parse/transpile it because
        // we want it to go through the linker and the rest of the transpilation process

        const dir_to_use: string = original_path.dirWithTrailingSlash();
        const disable_css_imports = bundler.options.framework.?.client_css_in_js != .auto_onimportcss;

        var code: string = undefined;

        if (disable_css_imports) {
            code = try std.fmt.bufPrint(
                &entry.code_buffer,
                \\globalThis.Bun_disableCSSImports = true;
                \\import boot from '{s}';
                \\import * as EntryPoint from '{s}{s}';
                \\boot(EntryPoint);
            ,
                .{
                    client,
                    dir_to_use,
                    original_path.filename,
                },
            );
        } else {
            code = try std.fmt.bufPrint(
                &entry.code_buffer,
                \\import boot from '{s}';
                \\if ('setLoaded' in boot) boot.setLoaded(loaded);
                \\import * as EntryPoint from '{s}{s}';
                \\boot(EntryPoint);
            ,
                .{
                    client,
                    dir_to_use,
                    original_path.filename,
                },
            );
        }

        entry.source = logger.Source.initPathString(generateEntryPointPath(&entry.path_buffer, original_path), code);
        entry.source.path.namespace = "client-entry";
    }
};

pub const ServerEntryPoint = struct {
    code_buffer: [bun.MAX_PATH_BYTES * 2 + 500]u8 = undefined,
    output_code_buffer: [bun.MAX_PATH_BYTES * 8 + 500]u8 = undefined,
    source: logger.Source = undefined,

    pub fn generate(
        entry: *ServerEntryPoint,
        comptime BundlerType: type,
        _: *BundlerType,
        original_path: Fs.PathName,
        name: string,
    ) !void {

        // This is *extremely* naive.
        // The basic idea here is this:
        // --
        // import * as EntryPoint from 'entry-point';
        // import boot from 'framework';
        // boot(EntryPoint);
        // --
        // We go through the steps of printing the code -- only to then parse/transpile it because
        // we want it to go through the linker and the rest of the transpilation process

        const dir_to_use: string = original_path.dirWithTrailingSlash();
        const code = try std.fmt.bufPrint(
            &entry.code_buffer,
            \\//Auto-generated file
            \\import * as start from '{s}{s}';
            \\export * from '{s}{s}';
            \\var entryNamespace = start;
            \\if ('default' in start && "__internalIsCommonJSNamespace" in globalThis && __internalIsCommonJSNamespace(start)) {{
            \\  entryNamespace = start.default();
            \\}}
            \\if(typeof entryNamespace?.default?.fetch === 'function') Bun.startServer(entryNamespace.default.fetch);
            \\if(typeof entryNamespace?.default?.cli === 'function') Bun.startServer(entryNamespace.default.cli);
        ,
            .{
                dir_to_use,
                original_path.filename,
                dir_to_use,
                original_path.filename,
            },
        );

        entry.source = logger.Source.initPathString(name, code);
        entry.source.path.text = name;
        entry.source.path.namespace = "server-entry";
    }
};

// This is not very fast. The idea is: we want to generate a unique entry point
// per macro function export that registers the macro Registering the macro
// happens in VirtualMachine We "register" it which just marks the JSValue as
// protected. This is mostly a workaround for being unable to call ESM exported
// functions from C++. When that is resolved, we should remove this.
pub const MacroEntryPoint = struct {
    code_buffer: [bun.MAX_PATH_BYTES * 2 + 500]u8 = undefined,
    output_code_buffer: [bun.MAX_PATH_BYTES * 8 + 500]u8 = undefined,
    source: logger.Source = undefined,

    pub fn generateID(entry_path: string, function_name: string, buf: []u8, len: *u32) i32 {
        var hasher = std.hash.Wyhash.init(0);
        hasher.update(js_ast.Macro.namespaceWithColon);
        hasher.update(entry_path);
        hasher.update(function_name);
        const truncated_u32 = @truncate(u32, hasher.final());

        const specifier = std.fmt.bufPrint(buf, js_ast.Macro.namespaceWithColon ++ "//{x}.js", .{truncated_u32}) catch unreachable;
        len.* = @truncate(u32, specifier.len);

        return generateIDFromSpecifier(specifier);
    }

    pub fn generateIDFromSpecifier(specifier: string) i32 {
        return @bitCast(i32, @truncate(u32, std.hash.Wyhash.hash(0, specifier)));
    }

    pub fn generate(
        entry: *MacroEntryPoint,
        _: *Bundler,
        import_path: Fs.PathName,
        function_name: string,
        macro_id: i32,
        macro_label_: string,
    ) !void {
        const dir_to_use: string = import_path.dirWithTrailingSlash();
        std.mem.copy(u8, entry.code_buffer[0..macro_label_.len], macro_label_);
        const macro_label = entry.code_buffer[0..macro_label_.len];

        const code = try std.fmt.bufPrint(
            entry.code_buffer[macro_label.len..],
            \\//Auto-generated file
            \\var Macros;
            \\try {{
            \\  Macros = await import('{s}{s}');
            \\}} catch (err) {{
            \\   console.error("Error importing macro");
            \\   throw err;
            \\}}
            \\if (!('{s}' in Macros)) {{
            \\  throw new Error("Macro '{s}' not found in '{s}{s}'");
            \\}}
            \\
            \\Bun.registerMacro({d}, Macros['{s}']);
        ,
            .{
                dir_to_use,
                import_path.filename,
                function_name,
                function_name,
                dir_to_use,
                import_path.filename,
                macro_id,
                function_name,
            },
        );

        entry.source = logger.Source.initPathString(macro_label, code);
        entry.source.path.text = macro_label;
        entry.source.path.namespace = js_ast.Macro.namespace;
    }
};
