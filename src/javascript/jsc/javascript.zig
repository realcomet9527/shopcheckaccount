const std = @import("std");
const is_bindgen: bool = std.meta.globalOption("bindgen", bool) orelse false;
const StaticExport = @import("./bindings/static_export.zig");
const c_char = StaticExport.c_char;
const bun = @import("../../global.zig");
const string = bun.string;
const Output = bun.Output;
const Global = bun.Global;
const Environment = bun.Environment;
const strings = bun.strings;
const MutableString = bun.MutableString;
const stringZ = bun.stringZ;
const default_allocator = bun.default_allocator;
const StoredFileDescriptorType = bun.StoredFileDescriptorType;
const Arena = @import("../../mimalloc_arena.zig").Arena;
const C = bun.C;
const NetworkThread = @import("http").NetworkThread;

pub fn zigCast(comptime Destination: type, value: anytype) *Destination {
    return @ptrCast(*Destination, @alignCast(@alignOf(*Destination), value));
}
const Allocator = std.mem.Allocator;
const IdentityContext = @import("../../identity_context.zig").IdentityContext;
const Fs = @import("../../fs.zig");
const Resolver = @import("../../resolver/resolver.zig");
const ast = @import("../../import_record.zig");
const NodeModuleBundle = @import("../../node_module_bundle.zig").NodeModuleBundle;
const MacroEntryPoint = @import("../../bundler.zig").MacroEntryPoint;
const logger = @import("../../logger.zig");
const Api = @import("../../api/schema.zig").Api;
const options = @import("../../options.zig");
const Bundler = @import("../../bundler.zig").Bundler;
const ServerEntryPoint = @import("../../bundler.zig").ServerEntryPoint;
const js_printer = @import("../../js_printer.zig");
const js_parser = @import("../../js_parser.zig");
const js_ast = @import("../../js_ast.zig");
const hash_map = @import("../../hash_map.zig");
const http = @import("../../http.zig");
const NodeFallbackModules = @import("../../node_fallbacks.zig");
const ImportKind = ast.ImportKind;
const Analytics = @import("../../analytics/analytics_thread.zig");
const ZigString = @import("../../jsc.zig").ZigString;
const Runtime = @import("../../runtime.zig");
const Router = @import("./api/router.zig");
const ImportRecord = ast.ImportRecord;
const DotEnv = @import("../../env_loader.zig");
const ParseResult = @import("../../bundler.zig").ParseResult;
const PackageJSON = @import("../../resolver/package_json.zig").PackageJSON;
const MacroRemap = @import("../../resolver/package_json.zig").MacroMap;
const WebCore = @import("../../jsc.zig").WebCore;
const Request = WebCore.Request;
const Response = WebCore.Response;
const Headers = WebCore.Headers;
const Fetch = WebCore.Fetch;
const FetchEvent = WebCore.FetchEvent;
const js = @import("../../jsc.zig").C;
const JSC = @import("../../jsc.zig");
const JSError = @import("./base.zig").JSError;
const d = @import("./base.zig").d;
const MarkedArrayBuffer = @import("./base.zig").MarkedArrayBuffer;
const getAllocator = @import("./base.zig").getAllocator;
const JSValue = @import("../../jsc.zig").JSValue;
const NewClass = @import("./base.zig").NewClass;
const Microtask = @import("../../jsc.zig").Microtask;
const JSGlobalObject = @import("../../jsc.zig").JSGlobalObject;
const ExceptionValueRef = @import("../../jsc.zig").ExceptionValueRef;
const JSPrivateDataPtr = @import("../../jsc.zig").JSPrivateDataPtr;
const ZigConsoleClient = @import("../../jsc.zig").ZigConsoleClient;
const Node = @import("../../jsc.zig").Node;
const ZigException = @import("../../jsc.zig").ZigException;
const ZigStackTrace = @import("../../jsc.zig").ZigStackTrace;
const ErrorableResolvedSource = @import("../../jsc.zig").ErrorableResolvedSource;
const ResolvedSource = @import("../../jsc.zig").ResolvedSource;
const JSPromise = @import("../../jsc.zig").JSPromise;
const JSInternalPromise = @import("../../jsc.zig").JSInternalPromise;
const JSModuleLoader = @import("../../jsc.zig").JSModuleLoader;
const JSPromiseRejectionOperation = @import("../../jsc.zig").JSPromiseRejectionOperation;
const Exception = @import("../../jsc.zig").Exception;
const ErrorableZigString = @import("../../jsc.zig").ErrorableZigString;
const ZigGlobalObject = @import("../../jsc.zig").ZigGlobalObject;
const VM = @import("../../jsc.zig").VM;
const JSFunction = @import("../../jsc.zig").JSFunction;
const Config = @import("./config.zig");
const URL = @import("../../query_string_map.zig").URL;
const Transpiler = @import("./api/transpiler.zig");
pub const GlobalClasses = [_]type{
    Request.Class,
    Response.Class,
    Headers.Class,
    EventListenerMixin.addEventListener(VirtualMachine),
    BuildError.Class,
    ResolveError.Class,
    Bun.Class,
    Fetch.Class,
    js_ast.Macro.JSNode.BunJSXCallbackFunction,
    Performance.Class,

    Crypto.Class,
    Crypto.Prototype,

    WebCore.TextEncoder.Constructor.Class,
    WebCore.TextDecoder.Constructor.Class,

    // The last item in this array becomes "process.env"
    Bun.EnvironmentVariables.Class,
};
const UUID = @import("./uuid.zig");
const Blob = @import("../../blob.zig");
pub const Buffer = MarkedArrayBuffer;
const Lock = @import("../../lock.zig").Lock;

pub const Crypto = struct {
    pub const Class = NewClass(void, .{ .name = "crypto" }, .{
        .getRandomValues = .{
            .rfn = getRandomValues,
        },
        .randomUUID = .{
            .rfn = randomUUID,
        },
    }, .{});
    pub const Prototype = NewClass(
        void,
        .{ .name = "Crypto" },
        .{
            .call = .{
                .rfn = call,
            },
        },
        .{},
    );

    pub fn getRandomValues(
        // this
        _: void,
        ctx: js.JSContextRef,
        // function
        _: js.JSObjectRef,
        // thisObject
        _: js.JSObjectRef,
        arguments: []const js.JSValueRef,
        exception: js.ExceptionRef,
    ) js.JSValueRef {
        if (arguments.len == 0) {
            JSError(getAllocator(ctx), "Expected typed array but received nothing", .{}, ctx, exception);
            return JSValue.jsUndefined().asObjectRef();
        }
        var array_buffer = MarkedArrayBuffer.fromJS(ctx.ptr(), JSValue.fromRef(arguments[0]), exception) orelse {
            JSError(getAllocator(ctx), "Expected typed array", .{}, ctx, exception);
            return JSValue.jsUndefined().asObjectRef();
        };
        var slice = array_buffer.slice();
        if (slice.len > 0)
            std.crypto.random.bytes(slice);

        return arguments[0];
    }

    pub fn call(
        // this
        _: void,
        _: js.JSContextRef,
        // function
        _: js.JSObjectRef,
        // thisObject
        _: js.JSObjectRef,
        _: []const js.JSValueRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        return JSValue.jsUndefined().asObjectRef();
    }

    pub fn randomUUID(
        // this
        _: void,
        ctx: js.JSContextRef,
        // function
        _: js.JSObjectRef,
        // thisObject
        _: js.JSObjectRef,
        _: []const js.JSValueRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        var uuid = UUID.init();
        var out: [128]u8 = undefined;
        var str = std.fmt.bufPrint(&out, "{s}", .{uuid}) catch unreachable;
        return ZigString.init(str).toValueGC(ctx.ptr()).asObjectRef();
    }
};

pub const Bun = struct {
    threadlocal var css_imports_list_strings: [512]ZigString = undefined;
    threadlocal var css_imports_list: [512]Api.StringPointer = undefined;
    threadlocal var css_imports_list_tail: u16 = 0;
    threadlocal var css_imports_buf: std.ArrayList(u8) = undefined;
    threadlocal var css_imports_buf_loaded: bool = false;

    threadlocal var routes_list_strings: [1024]ZigString = undefined;

    pub fn onImportCSS(
        resolve_result: *const Resolver.Result,
        import_record: *ImportRecord,
        origin: URL,
    ) void {
        if (!css_imports_buf_loaded) {
            css_imports_buf = std.ArrayList(u8).initCapacity(
                VirtualMachine.vm.allocator,
                import_record.path.text.len,
            ) catch unreachable;
            css_imports_buf_loaded = true;
        }

        var writer = css_imports_buf.writer();
        const offset = css_imports_buf.items.len;
        css_imports_list[css_imports_list_tail] = .{
            .offset = @truncate(u32, offset),
            .length = 0,
        };
        getPublicPath(resolve_result.path_pair.primary.text, origin, @TypeOf(writer), writer);
        const length = css_imports_buf.items.len - offset;
        css_imports_list[css_imports_list_tail].length = @truncate(u32, length);
        css_imports_list_tail += 1;
    }

    pub fn flushCSSImports() void {
        if (css_imports_buf_loaded) {
            css_imports_buf.clearRetainingCapacity();
            css_imports_list_tail = 0;
        }
    }

    pub fn getCSSImports() []ZigString {
        var i: u16 = 0;
        const tail = css_imports_list_tail;
        while (i < tail) : (i += 1) {
            ZigString.fromStringPointer(css_imports_list[i], css_imports_buf.items, &css_imports_list_strings[i]);
        }
        return css_imports_list_strings[0..tail];
    }

    pub fn inspect(
        // this
        _: void,
        ctx: js.JSContextRef,
        // function
        _: js.JSObjectRef,
        // thisObject
        _: js.JSObjectRef,
        arguments: []const js.JSValueRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        if (arguments.len == 0)
            return ZigString.Empty.toValue(ctx.ptr()).asObjectRef();

        for (arguments) |arg| {
            JSC.C.JSValueProtect(ctx, arg);
        }
        defer {
            for (arguments) |arg| {
                JSC.C.JSValueUnprotect(ctx, arg);
            }
        }

        // very stable memory address
        var array = MutableString.init(getAllocator(ctx), 0) catch unreachable;
        var buffered_writer_ = MutableString.BufferedWriter{ .context = &array };
        var buffered_writer = &buffered_writer_;

        var writer = buffered_writer.writer();
        const Writer = @TypeOf(writer);
        // we buffer this because it'll almost always be < 4096
        // when it's under 4096, we want to avoid the dynamic allocation
        ZigConsoleClient.format(
            .Debug,
            ctx.ptr(),
            @ptrCast([*]const JSValue, arguments.ptr),
            arguments.len,
            Writer,
            Writer,
            writer,
            false,
            false,
            false,
        );

        // when it's a small thing, rely on GC to manage the memory
        if (writer.context.pos < 2048 and array.list.items.len == 0) {
            var slice = writer.context.buffer[0..writer.context.pos];
            if (slice.len == 0) {
                return ZigString.Empty.toValue(ctx.ptr()).asObjectRef();
            }

            var zig_str = ZigString.init(slice).withEncoding();
            return zig_str.toValueGC(ctx.ptr()).asObjectRef();
        }

        // when it's a big thing, we will manage it
        {
            writer.context.flush() catch {};
            var slice = writer.context.context.toOwnedSlice();

            var zig_str = ZigString.init(slice).withEncoding();
            if (!zig_str.isUTF8()) {
                return zig_str.toExternalValue(ctx.ptr()).asObjectRef();
            } else {
                return zig_str.toValueGC(ctx.ptr()).asObjectRef();
            }
        }
    }

    pub fn registerMacro(
        // this
        _: void,
        ctx: js.JSContextRef,
        // function
        _: js.JSObjectRef,
        // thisObject
        _: js.JSObjectRef,
        arguments: []const js.JSValueRef,
        exception: js.ExceptionRef,
    ) js.JSValueRef {
        if (arguments.len != 2 or !js.JSValueIsNumber(ctx, arguments[0])) {
            JSError(getAllocator(ctx), "Internal error registering macros: invalid args", .{}, ctx, exception);
            return js.JSValueMakeUndefined(ctx);
        }
        // TODO: make this faster
        const id = @truncate(i32, @floatToInt(i64, js.JSValueToNumber(ctx, arguments[0], exception)));
        if (id == -1 or id == 0) {
            JSError(getAllocator(ctx), "Internal error registering macros: invalid id", .{}, ctx, exception);
            return js.JSValueMakeUndefined(ctx);
        }

        if (!js.JSValueIsObject(ctx, arguments[1]) or !js.JSObjectIsFunction(ctx, arguments[1])) {
            JSError(getAllocator(ctx), "Macro must be a function. Received: {s}", .{@tagName(js.JSValueGetType(ctx, arguments[1]))}, ctx, exception);
            return js.JSValueMakeUndefined(ctx);
        }

        var get_or_put_result = VirtualMachine.vm.macros.getOrPut(id) catch unreachable;
        if (get_or_put_result.found_existing) {
            js.JSValueUnprotect(ctx, get_or_put_result.value_ptr.*);
        }

        js.JSValueProtect(ctx, arguments[1]);
        get_or_put_result.value_ptr.* = arguments[1];

        return js.JSValueMakeUndefined(ctx);
    }

    pub fn getCWD(
        _: void,
        ctx: js.JSContextRef,
        _: js.JSValueRef,
        _: js.JSStringRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        return ZigString.init(VirtualMachine.vm.bundler.fs.top_level_dir).toValue(ctx.ptr()).asRef();
    }

    pub fn getOrigin(
        _: void,
        ctx: js.JSContextRef,
        _: js.JSValueRef,
        _: js.JSStringRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        return ZigString.init(VirtualMachine.vm.origin.origin).toValue(ctx.ptr()).asRef();
    }

    pub fn enableANSIColors(
        _: void,
        ctx: js.JSContextRef,
        _: js.JSValueRef,
        _: js.JSStringRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        return js.JSValueMakeBoolean(ctx, Output.enable_ansi_colors);
    }
    pub fn getMain(
        _: void,
        ctx: js.JSContextRef,
        _: js.JSValueRef,
        _: js.JSStringRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        return ZigString.init(VirtualMachine.vm.main).toValue(ctx.ptr()).asRef();
    }

    pub fn getAssetPrefix(
        _: void,
        ctx: js.JSContextRef,
        _: js.JSValueRef,
        _: js.JSStringRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        return ZigString.init(VirtualMachine.vm.bundler.options.routes.asset_prefix_path).toValue(ctx.ptr()).asRef();
    }

    pub fn getArgv(
        _: void,
        ctx: js.JSContextRef,
        _: js.JSValueRef,
        _: js.JSStringRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        if (comptime Environment.isWindows) {
            @compileError("argv not supported on windows");
        }

        var argv_list = std.heap.stackFallback(128, getAllocator(ctx));
        var allocator = argv_list.get();
        var argv = allocator.alloc(ZigString, std.os.argv.len) catch unreachable;
        defer if (argv.len > 128) allocator.free(argv);
        for (std.os.argv) |arg, i| {
            argv[i] = ZigString.init(std.mem.span(arg));
        }

        return JSValue.createStringArray(ctx.ptr(), argv.ptr, argv.len, true).asObjectRef();
    }

    pub fn getRoutesDir(
        _: void,
        ctx: js.JSContextRef,
        _: js.JSValueRef,
        _: js.JSStringRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        if (!VirtualMachine.vm.bundler.options.routes.routes_enabled or VirtualMachine.vm.bundler.options.routes.dir.len == 0) {
            return js.JSValueMakeUndefined(ctx);
        }

        return ZigString.init(VirtualMachine.vm.bundler.options.routes.dir).toValue(ctx.ptr()).asRef();
    }

    pub fn getFilePath(ctx: js.JSContextRef, arguments: []const js.JSValueRef, buf: []u8, exception: js.ExceptionRef) ?string {
        if (arguments.len != 1) {
            JSError(getAllocator(ctx), "Expected a file path as a string or an array of strings to be part of a file path.", .{}, ctx, exception);
            return null;
        }

        const value = arguments[0];
        if (js.JSValueIsString(ctx, value)) {
            var out = ZigString.Empty;
            JSValue.toZigString(JSValue.fromRef(value), &out, ctx.ptr());
            var out_slice = out.slice();

            // The dots are kind of unnecessary. They'll be normalized.
            if (out.len == 0 or @ptrToInt(out.ptr) == 0 or std.mem.eql(u8, out_slice, ".") or std.mem.eql(u8, out_slice, "..") or std.mem.eql(u8, out_slice, "../")) {
                JSError(getAllocator(ctx), "Expected a file path as a string or an array of strings to be part of a file path.", .{}, ctx, exception);
                return null;
            }

            var parts = [_]string{out_slice};
            // This does the equivalent of Node's path.normalize(path.join(cwd, out_slice))
            var res = VirtualMachine.vm.bundler.fs.absBuf(&parts, buf);

            return res;
        } else if (js.JSValueIsArray(ctx, value)) {
            var temp_strings_list: [32]string = undefined;
            var temp_strings_list_len: u8 = 0;
            defer {
                for (temp_strings_list[0..temp_strings_list_len]) |_, i| {
                    temp_strings_list[i] = "";
                }
            }

            var iter = JSValue.fromRef(value).arrayIterator(ctx.ptr());
            while (iter.next()) |item| {
                if (temp_strings_list_len >= temp_strings_list.len) {
                    break;
                }

                if (!item.isString()) {
                    JSError(getAllocator(ctx), "Expected a file path as a string or an array of strings to be part of a file path.", .{}, ctx, exception);
                    return null;
                }

                var out = ZigString.Empty;
                JSValue.toZigString(item, &out, ctx.ptr());
                const out_slice = out.slice();

                temp_strings_list[temp_strings_list_len] = out_slice;
                // The dots are kind of unnecessary. They'll be normalized.
                if (out.len == 0 or @ptrToInt(out.ptr) == 0 or std.mem.eql(u8, out_slice, ".") or std.mem.eql(u8, out_slice, "..") or std.mem.eql(u8, out_slice, "../")) {
                    JSError(getAllocator(ctx), "Expected a file path as a string or an array of strings to be part of a file path.", .{}, ctx, exception);
                    return null;
                }
                temp_strings_list_len += 1;
            }

            if (temp_strings_list_len == 0) {
                JSError(getAllocator(ctx), "Expected a file path as a string or an array of strings to be part of a file path.", .{}, ctx, exception);
                return null;
            }

            return VirtualMachine.vm.bundler.fs.absBuf(temp_strings_list[0..temp_strings_list_len], buf);
        } else {
            JSError(getAllocator(ctx), "Expected a file path as a string or an array of strings to be part of a file path.", .{}, ctx, exception);
            return null;
        }
    }

    pub fn getImportedStyles(
        _: void,
        ctx: js.JSContextRef,
        _: js.JSObjectRef,
        _: js.JSObjectRef,
        _: []const js.JSValueRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        defer flushCSSImports();
        const styles = getCSSImports();
        if (styles.len == 0) {
            return js.JSObjectMakeArray(ctx, 0, null, null);
        }

        return JSValue.createStringArray(ctx.ptr(), styles.ptr, styles.len, true).asRef();
    }

    pub fn newPath(
        _: void,
        ctx: js.JSContextRef,
        _: js.JSObjectRef,
        _: js.JSObjectRef,
        args: []const js.JSValueRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        const is_windows = args.len == 1 and JSValue.fromRef(args[0]).toBoolean();
        return Node.Path.create(ctx.ptr(), is_windows).asObjectRef();
    }

    pub fn readFileAsStringCallback(
        ctx: js.JSContextRef,
        buf_z: [:0]const u8,
        exception: js.ExceptionRef,
    ) js.JSValueRef {
        const path = buf_z.ptr[0..buf_z.len];
        var file = std.fs.cwd().openFileZ(buf_z, .{ .mode = .read_only }) catch |err| {
            JSError(getAllocator(ctx), "Opening file {s} for path: \"{s}\"", .{ @errorName(err), path }, ctx, exception);
            return js.JSValueMakeUndefined(ctx);
        };

        defer file.close();

        const stat = file.stat() catch |err| {
            JSError(getAllocator(ctx), "Getting file size {s} for \"{s}\"", .{ @errorName(err), path }, ctx, exception);
            return js.JSValueMakeUndefined(ctx);
        };

        if (stat.kind != .File) {
            JSError(getAllocator(ctx), "Can't read a {s} as a string (\"{s}\")", .{ @tagName(stat.kind), path }, ctx, exception);
            return js.JSValueMakeUndefined(ctx);
        }

        var contents_buf = VirtualMachine.vm.allocator.alloc(u8, stat.size + 2) catch unreachable; // OOM
        defer VirtualMachine.vm.allocator.free(contents_buf);
        const contents_len = file.readAll(contents_buf) catch |err| {
            JSError(getAllocator(ctx), "{s} reading file (\"{s}\")", .{ @errorName(err), path }, ctx, exception);
            return js.JSValueMakeUndefined(ctx);
        };

        contents_buf[contents_len] = 0;

        // Very slow to do it this way. We're copying the string twice.
        // But it's important that this string is garbage collected instead of manually managed.
        // We can't really recycle this one.
        // TODO: use external string
        return js.JSValueMakeString(ctx, js.JSStringCreateWithUTF8CString(contents_buf.ptr));
    }

    pub fn readFileAsBytesCallback(
        ctx: js.JSContextRef,
        buf_z: [:0]const u8,
        exception: js.ExceptionRef,
    ) js.JSValueRef {
        const path = buf_z.ptr[0..buf_z.len];

        var file = std.fs.cwd().openFileZ(buf_z, .{ .mode = .read_only }) catch |err| {
            JSError(getAllocator(ctx), "Opening file {s} for path: \"{s}\"", .{ @errorName(err), path }, ctx, exception);
            return js.JSValueMakeUndefined(ctx);
        };

        defer file.close();

        const stat = file.stat() catch |err| {
            JSError(getAllocator(ctx), "Getting file size {s} for \"{s}\"", .{ @errorName(err), path }, ctx, exception);
            return js.JSValueMakeUndefined(ctx);
        };

        if (stat.kind != .File) {
            JSError(getAllocator(ctx), "Can't read a {s} as a string (\"{s}\")", .{ @tagName(stat.kind), path }, ctx, exception);
            return js.JSValueMakeUndefined(ctx);
        }

        var contents_buf = VirtualMachine.vm.allocator.alloc(u8, stat.size + 2) catch unreachable; // OOM
        errdefer VirtualMachine.vm.allocator.free(contents_buf);
        const contents_len = file.readAll(contents_buf) catch |err| {
            JSError(getAllocator(ctx), "{s} reading file (\"{s}\")", .{ @errorName(err), path }, ctx, exception);
            return js.JSValueMakeUndefined(ctx);
        };

        contents_buf[contents_len] = 0;

        var marked_array_buffer = VirtualMachine.vm.allocator.create(MarkedArrayBuffer) catch unreachable;
        marked_array_buffer.* = MarkedArrayBuffer.fromBytes(
            contents_buf[0..contents_len],
            VirtualMachine.vm.allocator,
            .Uint8Array,
        );

        return marked_array_buffer.toJSObjectRef(ctx, exception);
    }

    pub fn getRouteFiles(
        _: void,
        ctx: js.JSContextRef,
        _: js.JSObjectRef,
        _: js.JSObjectRef,
        _: []const js.JSValueRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        if (VirtualMachine.vm.bundler.router == null) return js.JSValueMakeNull(ctx);

        const router = &VirtualMachine.vm.bundler.router.?;
        const list = router.getPublicPaths() catch unreachable;

        for (routes_list_strings[0..@minimum(list.len, routes_list_strings.len)]) |_, i| {
            routes_list_strings[i] = ZigString.init(list[i]);
        }

        const ref = JSValue.createStringArray(ctx.ptr(), &routes_list_strings, list.len, true).asRef();
        return ref;
    }

    pub fn getRouteNames(
        _: void,
        ctx: js.JSContextRef,
        _: js.JSObjectRef,
        _: js.JSObjectRef,
        _: []const js.JSValueRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        if (VirtualMachine.vm.bundler.router == null) return js.JSValueMakeNull(ctx);

        const router = &VirtualMachine.vm.bundler.router.?;
        const list = router.getNames() catch unreachable;

        for (routes_list_strings[0..@minimum(list.len, routes_list_strings.len)]) |_, i| {
            routes_list_strings[i] = ZigString.init(list[i]);
        }

        const ref = JSValue.createStringArray(ctx.ptr(), &routes_list_strings, list.len, true).asRef();
        return ref;
    }

    pub fn readFileAsBytes(
        _: void,
        ctx: js.JSContextRef,
        _: js.JSObjectRef,
        _: js.JSObjectRef,
        arguments: []const js.JSValueRef,
        exception: js.ExceptionRef,
    ) js.JSValueRef {
        var buf: [bun.MAX_PATH_BYTES]u8 = undefined;
        const path = getFilePath(ctx, arguments, &buf, exception) orelse return null;
        buf[path.len] = 0;

        const buf_z: [:0]const u8 = buf[0..path.len :0];
        const result = readFileAsBytesCallback(ctx, buf_z, exception);
        return result;
    }

    pub fn readFileAsString(
        _: void,
        ctx: js.JSContextRef,
        _: js.JSObjectRef,
        _: js.JSObjectRef,
        arguments: []const js.JSValueRef,
        exception: js.ExceptionRef,
    ) js.JSValueRef {
        var buf: [bun.MAX_PATH_BYTES]u8 = undefined;
        const path = getFilePath(ctx, arguments, &buf, exception) orelse return null;
        buf[path.len] = 0;

        const buf_z: [:0]const u8 = buf[0..path.len :0];
        const result = readFileAsStringCallback(ctx, buf_z, exception);
        return result;
    }

    pub fn getPublicPath(to: string, origin: URL, comptime Writer: type, writer: Writer) void {
        const relative_path = VirtualMachine.vm.bundler.fs.relativeTo(to);
        if (origin.isAbsolute()) {
            if (strings.hasPrefix(relative_path, "..") or strings.hasPrefix(relative_path, "./")) {
                writer.writeAll(origin.origin) catch return;
                writer.writeAll("/abs:") catch return;
                if (std.fs.path.isAbsolute(to)) {
                    writer.writeAll(to) catch return;
                } else {
                    writer.writeAll(VirtualMachine.vm.bundler.fs.abs(&[_]string{to})) catch return;
                }
            } else {
                origin.joinWrite(
                    Writer,
                    writer,
                    VirtualMachine.vm.bundler.options.routes.asset_prefix_path,
                    "",
                    relative_path,
                    "",
                ) catch return;
            }
        } else {
            writer.writeAll(std.mem.trimLeft(u8, relative_path, "/")) catch unreachable;
        }
    }

    pub fn sleepSync(
        _: void,
        ctx: js.JSContextRef,
        _: js.JSObjectRef,
        _: js.JSObjectRef,
        arguments: []const js.JSValueRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        if (js.JSValueIsNumber(ctx, arguments[0])) {
            const seconds = JSValue.fromRef(arguments[0]).asNumber();
            if (seconds > 0 and std.math.isFinite(seconds)) std.time.sleep(@floatToInt(u64, seconds * 1000) * std.time.ns_per_ms);
        }

        return js.JSValueMakeUndefined(ctx);
    }

    pub fn createNodeFS(
        _: void,
        ctx: js.JSContextRef,
        _: js.JSObjectRef,
        _: js.JSObjectRef,
        _: []const js.JSValueRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        return Node.NodeFSBindings.make(
            ctx,
            VirtualMachine.vm.node_fs orelse brk: {
                VirtualMachine.vm.node_fs = bun.default_allocator.create(Node.NodeFS) catch unreachable;
                VirtualMachine.vm.node_fs.?.* = Node.NodeFS{ .async_io = undefined };
                break :brk VirtualMachine.vm.node_fs.?;
            },
        );
    }

    pub fn generateHeapSnapshot(
        _: void,
        ctx: js.JSContextRef,
        _: js.JSObjectRef,
        _: js.JSObjectRef,
        _: []const js.JSValueRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        return ctx.ptr().generateHeapSnapshot().asObjectRef();
    }

    pub fn runGC(
        _: void,
        ctx: js.JSContextRef,
        _: js.JSObjectRef,
        _: js.JSObjectRef,
        arguments: []const js.JSValueRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        Global.mimalloc_cleanup(true);
        return ctx.ptr().vm().runGC(arguments.len > 0 and JSValue.fromRef(arguments[0]).toBoolean()).asRef();
    }

    pub fn shrink(
        _: void,
        ctx: js.JSContextRef,
        _: js.JSObjectRef,
        _: js.JSObjectRef,
        _: []const js.JSValueRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        ctx.ptr().vm().shrinkFootprint();
        return JSValue.jsUndefined().asRef();
    }

    pub fn readAllStdinSync(
        _: void,
        ctx: js.JSContextRef,
        _: js.JSObjectRef,
        _: js.JSObjectRef,
        _: []const js.JSValueRef,
        exception: js.ExceptionRef,
    ) js.JSValueRef {
        var stack = std.heap.stackFallback(2048, getAllocator(ctx));
        var allocator = stack.get();

        var stdin = std.io.getStdIn();
        var result = stdin.readToEndAlloc(allocator, std.math.maxInt(u32)) catch |err| {
            JSError(undefined, "{s} reading stdin", .{@errorName(err)}, ctx, exception);
            return null;
        };
        var out = ZigString.init(result);
        out.detectEncoding();
        return out.toValueGC(ctx.ptr()).asObjectRef();
    }

    var public_path_temp_str: [bun.MAX_PATH_BYTES]u8 = undefined;

    pub fn getPublicPathJS(
        _: void,
        ctx: js.JSContextRef,
        _: js.JSObjectRef,
        _: js.JSObjectRef,
        arguments: []const js.JSValueRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        var zig_str: ZigString = ZigString.Empty;
        JSValue.toZigString(JSValue.fromRef(arguments[0]), &zig_str, ctx.ptr());

        const to = zig_str.slice();

        var stream = std.io.fixedBufferStream(&public_path_temp_str);
        var writer = stream.writer();
        getPublicPath(to, VirtualMachine.vm.origin, @TypeOf(&writer), &writer);
        return ZigString.init(stream.buffer[0..stream.pos]).toValueGC(ctx.ptr()).asObjectRef();
    }

    // pub fn resolvePath(
    //     _: void,
    //     ctx: js.JSContextRef,
    //     _: js.JSObjectRef,
    //     _: js.JSObjectRef,
    //     arguments: []const js.JSValueRef,
    //     _: js.ExceptionRef,
    // ) js.JSValueRef {
    //     if (arguments.len == 0) return ZigString.Empty.toValue(ctx.ptr()).asObjectRef();
    //     var zig_str: ZigString = ZigString.Empty;
    //     JSValue.toZigString(JSValue.fromRef(arguments[0]), &zig_str, ctx.ptr());
    //     var buf: [bun.MAX_PATH_BYTES]u8 = undefined;
    //     var stack = std.heap.stackFallback(32 * @sizeOf(string), VirtualMachine.vm.allocator);
    //     var allocator = stack.get();
    //     var parts = allocator.alloc(string, arguments.len) catch {};
    //     defer allocator.free(parts);

    //     const to = zig_str.slice();
    //     var parts = .{to};
    //     const value = ZigString.init(VirtualMachine.vm.bundler.fs.absBuf(&parts, &buf)).toValueGC(ctx.ptr());
    //     return value.asObjectRef();
    // }

    pub const Class = NewClass(
        void,
        .{
            .name = "Bun",
            .read_only = true,
            .ts = .{
                .module = .{
                    .path = "bun.js/router",
                    .tsdoc = "Filesystem Router supporting dynamic routes, exact routes, catch-all routes, and optional catch-all routes. Implemented in native code and only available with Bun.js.",
                },
            },
        },
        .{
            .match = .{
                .rfn = Router.match,
                .ts = Router.match_type_definition,
            },
            .__debug__doSegfault = .{
                .rfn = Bun.__debug__doSegfault,
            },
            .sleepSync = .{
                .rfn = sleepSync,
            },
            .fetch = .{
                .rfn = Fetch.call,
                .ts = d.ts{},
            },
            .getImportedStyles = .{
                .rfn = Bun.getImportedStyles,
                .ts = d.ts{
                    .name = "getImportedStyles",
                    .@"return" = "string[]",
                },
            },
            .inspect = .{
                .rfn = Bun.inspect,
                .ts = d.ts{
                    .name = "inspect",
                    .@"return" = "string",
                },
            },
            .getRouteFiles = .{
                .rfn = Bun.getRouteFiles,
                .ts = d.ts{
                    .name = "getRouteFiles",
                    .@"return" = "string[]",
                },
            },
            ._Path = .{
                .rfn = Bun.newPath,
                .ts = d.ts{},
            },
            .getRouteNames = .{
                .rfn = Bun.getRouteNames,
                .ts = d.ts{
                    .name = "getRouteNames",
                    .@"return" = "string[]",
                },
            },
            .readFile = .{
                .rfn = Bun.readFileAsString,
                .ts = d.ts{
                    .name = "readFile",
                    .@"return" = "string",
                },
            },
            .readFileBytes = .{
                .rfn = Bun.readFileAsBytes,
                .ts = d.ts{
                    .name = "readFile",
                    .@"return" = "Uint8Array",
                },
            },
            .getPublicPath = .{
                .rfn = Bun.getPublicPathJS,
                .ts = d.ts{
                    .name = "getPublicPath",
                    .@"return" = "string",
                },
            },
            .registerMacro = .{
                .rfn = Bun.registerMacro,
                .ts = d.ts{
                    .name = "registerMacro",
                    .@"return" = "undefined",
                },
            },
            .fs = .{
                .rfn = Bun.createNodeFS,
                .ts = d.ts{},
            },
            .jest = .{
                .rfn = @import("./test/jest.zig").Jest.call,
                .ts = d.ts{},
            },
            .gc = .{
                .rfn = Bun.runGC,
                .ts = d.ts{},
            },
            .generateHeapSnapshot = .{
                .rfn = Bun.generateHeapSnapshot,
                .ts = d.ts{},
            },
            .shrink = .{
                .rfn = Bun.shrink,
                .ts = d.ts{},
            },
            .readAllStdinSync = .{
                .rfn = Bun.readAllStdinSync,
                .ts = d.ts{},
            },
        },
        .{
            .main = .{
                .get = getMain,
                .ts = d.ts{ .name = "main", .@"return" = "string" },
            },
            .cwd = .{
                .get = getCWD,
                .ts = d.ts{ .name = "cwd", .@"return" = "string" },
            },
            .origin = .{
                .get = getOrigin,
                .ts = d.ts{ .name = "origin", .@"return" = "string" },
            },
            .routesDir = .{
                .get = getRoutesDir,
                .ts = d.ts{ .name = "routesDir", .@"return" = "string" },
            },
            .assetPrefix = .{
                .get = getAssetPrefix,
                .ts = d.ts{ .name = "assetPrefix", .@"return" = "string" },
            },
            .argv = .{
                .get = getArgv,
                .ts = d.ts{ .name = "argv", .@"return" = "string[]" },
            },
            .env = .{
                .get = EnvironmentVariables.getter,
            },
            .enableANSIColors = .{
                .get = enableANSIColors,
            },
            .Transpiler = .{
                .get = getTranspilerConstructor,
                .ts = d.ts{ .name = "Transpiler", .@"return" = "Transpiler.prototype" },
            },
            .TOML = .{
                .get = getTOMLObject,
                .ts = d.ts{ .name = "TOML", .@"return" = "TOML.prototype" },
            },
        },
    );

    pub fn getTranspilerConstructor(
        _: void,
        ctx: js.JSContextRef,
        _: js.JSValueRef,
        _: js.JSStringRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        return js.JSObjectMake(ctx, Transpiler.TranspilerConstructor.get().?[0], null);
    }

    pub fn getTOMLObject(
        _: void,
        ctx: js.JSContextRef,
        _: js.JSValueRef,
        _: js.JSStringRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        return js.JSObjectMake(ctx, TOML.Class.get().?[0], null);
    }

    // For testing the segfault handler
    pub fn __debug__doSegfault(
        _: void,
        ctx: js.JSContextRef,
        _: js.JSObjectRef,
        _: js.JSObjectRef,
        _: []const js.JSValueRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        _ = ctx;
        const Reporter = @import("../../report.zig");
        Reporter.globalError(error.SegfaultTest);
    }

    // pub const Lockfile = struct {
    //     const BunLockfile = @import("../../install/install.zig").Lockfile;
    //     pub const Class = NewClass(
    //         void,
    //         .{
    //             .name = "Lockfile",
    //             .read_only = true,
    //         },
    //         .{
    //             . = .{
    //                 .rfn = BunLockfile.load,
    //             },
    //         },
    //         .{},
    //     );

    //     pub const StaticClass = NewClass(
    //         void,
    //         .{
    //             .name = "Lockfile",
    //             .read_only = true,
    //         },
    //         .{
    //             .load = .{
    //                 .rfn = BunLockfile.load,
    //             },
    //         },
    //         .{},
    //     );

    //     pub fn load(
    //         // this
    //         _: void,
    //         ctx: js.JSContextRef,
    //         // function
    //         _: js.JSObjectRef,
    //         // thisObject
    //         _: js.JSObjectRef,
    //         arguments: []const js.JSValueRef,
    //         exception: js.ExceptionRef,
    //     ) js.JSValueRef {
    //         if (arguments.len == 0) {
    //             JSError(undefined, "Expected file path string or buffer", .{}, ctx, exception);
    //             return null;
    //         }

    //         var lockfile: *BunLockfile = getAllocator(ctx).create(BunLockfile) catch return JSValue.jsUndefined().asRef();

    //         var log = logger.Log.init(default_allocator);
    //         var args_slice = @ptrCast([*]const JSValue, arguments.ptr)[0..arguments.len];

    //         var arguments_slice = Node.ArgumentsSlice.init(args_slice);
    //         var path_or_buffer = Node.PathLike.fromJS(ctx, &arguments_slice, exception) orelse {
    //             getAllocator(ctx).destroy(lockfile);
    //             JSError(undefined, "Expected file path string or buffer", .{}, ctx, exception);
    //             return null;
    //         };

    //         const load_from_disk_result = switch (path_or_buffer) {
    //             Node.PathLike.Tag.string => lockfile.loadFromDisk(getAllocator(ctx), &log, path_or_buffer.string),
    //             Node.PathLike.Tag.buffer => lockfile.loadFromBytes(getAllocator(ctx), path_or_buffer.buffer.slice(), &log),
    //             else => {
    //                 getAllocator(ctx).destroy(lockfile);
    //                    JSError(undefined, "Expected file path string or buffer", .{}, ctx, exception);
    //             return null;
    //             }
    //         };

    //         switch (load_from_disk_result) {
    //             .err => |cause| {
    //                 defer getAllocator(ctx).destroy(lockfile);
    //                 switch (cause.step) {
    //                     .open_file => {
    //                         JSError(undefined, "error opening lockfile: {s}", .{
    //                             @errorName(cause.value),
    //                         }, ctx, exception);
    //                         return null;
    //                     },
    //                     .parse_file => {
    //                         JSError(undefined, "error parsing lockfile: {s}", .{
    //                             @errorName(cause.value),
    //                         }, ctx, exception);
    //                         return null;
    //                     },
    //                     .read_file => {
    //                         JSError(undefined, "error reading lockfile: {s}", .{
    //                             @errorName(cause.value),
    //                         }, ctx, exception);
    //                         return null;
    //                     },
    //                 }
    //             },
    //             .ok => {

    //             },
    //         }
    //     }
    // };

    pub const TOML = struct {
        const TOMLParser = @import("../../toml/toml_parser.zig").TOML;
        pub const Class = NewClass(
            void,
            .{
                .name = "TOML",
                .read_only = true,
            },
            .{
                .parse = .{
                    .rfn = TOML.parse,
                },
            },
            .{},
        );

        pub fn parse(
            // this
            _: void,
            ctx: js.JSContextRef,
            // function
            _: js.JSObjectRef,
            // thisObject
            _: js.JSObjectRef,
            arguments: []const js.JSValueRef,
            exception: js.ExceptionRef,
        ) js.JSValueRef {
            var arena = std.heap.ArenaAllocator.init(getAllocator(ctx));
            var allocator = arena.allocator();
            defer arena.deinit();
            var log = logger.Log.init(default_allocator);
            var input_str = ZigString.init("");
            JSValue.fromRef(arguments[0]).toZigString(&input_str, ctx.ptr());
            var needs_deinit = false;
            var input = input_str.slice();
            if (input_str.is16Bit()) {
                input = std.fmt.allocPrint(allocator, "{}", .{input_str}) catch unreachable;
                needs_deinit = true;
            }
            var source = logger.Source.initPathString("input.toml", input);
            var parse_result = TOMLParser.parse(&source, &log, allocator) catch {
                exception.* = log.toJS(ctx.ptr(), default_allocator, "Failed to parse toml").asObjectRef();
                return null;
            };

            // for now...
            var buffer_writer = try js_printer.BufferWriter.init(allocator);
            var writer = js_printer.BufferPrinter.init(buffer_writer);
            _ = js_printer.printJSON(*js_printer.BufferPrinter, &writer, parse_result, &source) catch {
                exception.* = log.toJS(ctx.ptr(), default_allocator, "Failed to print toml").asObjectRef();
                return null;
            };

            var slice = writer.ctx.buffer.toOwnedSliceLeaky();
            var out = ZigString.init(slice);

            const out_value = js.JSValueMakeFromJSONString(ctx, out.toJSStringRef());
            return out_value;
        }
    };

    pub const Timer = struct {
        last_id: i32 = 0,
        warned: bool = false,
        active: u32 = 0,
        timeouts: TimeoutMap = TimeoutMap{},

        const TimeoutMap = std.AutoArrayHashMapUnmanaged(i32, *Timeout);

        pub fn getNextID() callconv(.C) i32 {
            VirtualMachine.vm.timer.last_id += 1;
            return VirtualMachine.vm.timer.last_id;
        }

        pub const Timeout = struct {
            id: i32 = 0,
            callback: JSValue,
            interval: i32 = 0,
            completion: NetworkThread.Completion = undefined,
            repeat: bool = false,
            io_task: ?*TimeoutTask = null,
            cancelled: bool = false,

            pub const TimeoutTask = IOTask(Timeout);

            pub fn run(this: *Timeout, _task: *TimeoutTask) void {
                this.io_task = _task;
                NetworkThread.global.pool.io.?.timeout(
                    *Timeout,
                    this,
                    onCallback,
                    &this.completion,
                    std.time.ns_per_ms * @intCast(
                        u63,
                        @maximum(
                            this.interval,
                            1,
                        ),
                    ),
                );
            }

            pub fn onCallback(this: *Timeout, _: *NetworkThread.Completion, _: NetworkThread.AsyncIO.TimeoutError!void) void {
                this.io_task.?.onFinish();
            }

            pub fn then(this: *Timeout, global: *JSGlobalObject) void {
                if (!this.cancelled) {
                    if (this.repeat) {
                        this.io_task.?.deinit();
                        var task = Timeout.TimeoutTask.createOnJSThread(VirtualMachine.vm.allocator, global, this) catch unreachable;
                        this.io_task = task;
                        task.schedule();
                    }

                    _ = JSC.C.JSObjectCallAsFunction(global.ref(), this.callback.asObjectRef(), null, 0, null, null);

                    if (this.repeat)
                        return;
                }

                this.clear(global);
            }

            pub fn clear(this: *Timeout, global: *JSGlobalObject) void {
                this.cancelled = true;
                JSC.C.JSValueUnprotect(global.ref(), this.callback.asObjectRef());
                _ = VirtualMachine.vm.timer.timeouts.swapRemove(this.id);
                if (this.io_task) |task| {
                    task.deinit();
                }
                VirtualMachine.vm.allocator.destroy(this);
                VirtualMachine.vm.timer.active -|= 1;
                VirtualMachine.vm.active_tasks -|= 1;
            }
        };

        fn set(
            id: i32,
            globalThis: *JSGlobalObject,
            callback: JSValue,
            countdown: JSValue,
            repeat: bool,
        ) !void {
            if (comptime is_bindgen) unreachable;
            var timeout = try VirtualMachine.vm.allocator.create(Timeout);
            js.JSValueProtect(globalThis.ref(), callback.asObjectRef());
            timeout.* = Timeout{ .id = id, .callback = callback, .interval = countdown.toInt32(), .repeat = repeat };
            var task = try Timeout.TimeoutTask.createOnJSThread(VirtualMachine.vm.allocator, globalThis, timeout);
            VirtualMachine.vm.timer.timeouts.put(VirtualMachine.vm.allocator, id, timeout) catch unreachable;
            VirtualMachine.vm.timer.active +|= 1;
            VirtualMachine.vm.active_tasks +|= 1;
            task.schedule();
        }

        pub fn setTimeout(
            globalThis: *JSGlobalObject,
            callback: JSValue,
            countdown: JSValue,
        ) callconv(.C) JSValue {
            if (comptime is_bindgen) unreachable;
            const id = VirtualMachine.vm.timer.last_id;
            VirtualMachine.vm.timer.last_id +%= 1;

            Timer.set(id, globalThis, callback, countdown, false) catch
                return JSValue.jsUndefined();

            return JSValue.jsNumber(@intCast(i32, id));
        }
        pub fn setInterval(
            globalThis: *JSGlobalObject,
            callback: JSValue,
            countdown: JSValue,
        ) callconv(.C) JSValue {
            if (comptime is_bindgen) unreachable;
            const id = VirtualMachine.vm.timer.last_id;
            VirtualMachine.vm.timer.last_id +%= 1;

            Timer.set(id, globalThis, callback, countdown, true) catch
                return JSValue.jsUndefined();

            return JSValue.jsNumber(@intCast(i32, id));
        }

        pub fn clearTimer(id: JSValue, _: *JSGlobalObject) void {
            if (comptime is_bindgen) unreachable;
            var timer: *Timeout = VirtualMachine.vm.timer.timeouts.get(id.toInt32()) orelse return;
            timer.cancelled = true;
        }

        pub fn clearTimeout(
            globalThis: *JSGlobalObject,
            id: JSValue,
        ) callconv(.C) JSValue {
            if (comptime is_bindgen) unreachable;
            Timer.clearTimer(id, globalThis);
            return JSValue.jsUndefined();
        }
        pub fn clearInterval(
            globalThis: *JSGlobalObject,
            id: JSValue,
        ) callconv(.C) JSValue {
            if (comptime is_bindgen) unreachable;
            Timer.clearTimer(id, globalThis);
            return JSValue.jsUndefined();
        }

        const Shimmer = @import("./bindings/shimmer.zig").Shimmer;

        pub const shim = Shimmer("Bun", "Timer", @This());
        pub const name = "Bun__Timer";
        pub const include = "";
        pub const namespace = shim.namespace;

        pub const Export = shim.exportFunctions(.{
            .@"setTimeout" = setTimeout,
            .@"setInterval" = setInterval,
            .@"clearTimeout" = clearTimeout,
            .@"clearInterval" = clearInterval,
            .@"getNextID" = getNextID,
        });

        comptime {
            @export(setTimeout, .{ .name = Export[0].symbol_name });
            @export(setInterval, .{ .name = Export[1].symbol_name });
            @export(clearTimeout, .{ .name = Export[2].symbol_name });
            @export(clearInterval, .{ .name = Export[3].symbol_name });
            @export(getNextID, .{ .name = Export[4].symbol_name });
        }
    };

    /// EnvironmentVariables is runtime defined.
    /// Also, you can't iterate over process.env normally since it only exists at build-time otherwise
    // This is aliased to Bun.env
    pub const EnvironmentVariables = struct {
        pub const Class = NewClass(
            void,
            .{
                .name = "DotEnv",
                .read_only = true,
            },
            .{
                .getProperty = .{
                    .rfn = getProperty,
                },
                .setProperty = .{
                    .rfn = setProperty,
                },
                .deleteProperty = .{
                    .rfn = deleteProperty,
                },
                .convertToType = .{ .rfn = convertToType },
                .hasProperty = .{
                    .rfn = hasProperty,
                },
                .getPropertyNames = .{
                    .rfn = getPropertyNames,
                },
                .toJSON = .{
                    .rfn = toJSON,
                    .name = "toJSON",
                },
            },
            .{},
        );

        pub fn getter(
            _: void,
            ctx: js.JSContextRef,
            _: js.JSValueRef,
            _: js.JSStringRef,
            _: js.ExceptionRef,
        ) js.JSValueRef {
            return js.JSObjectMake(ctx, EnvironmentVariables.Class.get().*, null);
        }

        pub const BooleanString = struct {
            pub const @"true": string = "true";
            pub const @"false": string = "false";
        };

        pub fn getProperty(
            ctx: js.JSContextRef,
            _: js.JSObjectRef,
            propertyName: js.JSStringRef,
            _: js.ExceptionRef,
        ) callconv(.C) js.JSValueRef {
            const len = js.JSStringGetLength(propertyName);
            var ptr = js.JSStringGetCharacters8Ptr(propertyName);
            var name = ptr[0..len];
            if (VirtualMachine.vm.bundler.env.map.get(name)) |value| {
                return ZigString.toRef(value, ctx.ptr());
            }

            if (Output.enable_ansi_colors) {
                // https://github.com/chalk/supports-color/blob/main/index.js
                if (strings.eqlComptime(name, "FORCE_COLOR")) {
                    return ZigString.toRef(BooleanString.@"true", ctx.ptr());
                }
            }

            return js.JSValueMakeUndefined(ctx);
        }

        pub fn toJSON(
            _: void,
            ctx: js.JSContextRef,
            _: js.JSObjectRef,
            _: js.JSObjectRef,
            _: []const js.JSValueRef,
            _: js.ExceptionRef,
        ) js.JSValueRef {
            var map = VirtualMachine.vm.bundler.env.map.map;
            var keys = map.keys();
            var values = map.values();
            const StackFallback = std.heap.StackFallbackAllocator(32 * 2 * @sizeOf(ZigString));
            var stack = StackFallback{
                .buffer = undefined,
                .fallback_allocator = bun.default_allocator,
                .fixed_buffer_allocator = undefined,
            };
            var allocator = stack.get();
            var key_strings_ = allocator.alloc(ZigString, keys.len * 2) catch unreachable;
            var key_strings = key_strings_[0..keys.len];
            var value_strings = key_strings_[keys.len..];

            for (keys) |key, i| {
                key_strings[i] = ZigString.init(key);
                key_strings[i].detectEncoding();
                value_strings[i] = ZigString.init(values[i]);
                value_strings[i].detectEncoding();
            }

            var result = JSValue.fromEntries(ctx.ptr(), key_strings.ptr, value_strings.ptr, keys.len, false).asObjectRef();
            allocator.free(key_strings_);
            return result;
            // }
            // ZigConsoleClient.Formatter.format(this: *Formatter, result: Tag.Result, comptime Writer: type, writer: Writer, value: JSValue, globalThis: *JSGlobalObject, comptime enable_ansi_colors: bool)
        }

        pub fn deleteProperty(
            _: js.JSContextRef,
            _: js.JSObjectRef,
            propertyName: js.JSStringRef,
            _: js.ExceptionRef,
        ) callconv(.C) bool {
            const len = js.JSStringGetLength(propertyName);
            var ptr = js.JSStringGetCharacters8Ptr(propertyName);
            var name = ptr[0..len];
            _ = VirtualMachine.vm.bundler.env.map.map.swapRemove(name);
            return true;
        }

        pub fn setProperty(
            ctx: js.JSContextRef,
            _: js.JSObjectRef,
            propertyName: js.JSStringRef,
            value: js.JSValueRef,
            exception: js.ExceptionRef,
        ) callconv(.C) bool {
            const len = js.JSStringGetLength(propertyName);
            var ptr = js.JSStringGetCharacters8Ptr(propertyName);
            var name = ptr[0..len];
            var val = ZigString.init("");
            JSValue.fromRef(value).toZigString(&val, ctx.ptr());
            if (exception.* != null) return false;
            var result = std.fmt.allocPrint(VirtualMachine.vm.allocator, "{}", .{val}) catch unreachable;
            VirtualMachine.vm.bundler.env.map.put(name, result) catch unreachable;

            return true;
        }

        pub fn hasProperty(
            _: js.JSContextRef,
            _: js.JSObjectRef,
            propertyName: js.JSStringRef,
        ) callconv(.C) bool {
            const len = js.JSStringGetLength(propertyName);
            const ptr = js.JSStringGetCharacters8Ptr(propertyName);
            const name = ptr[0..len];
            return VirtualMachine.vm.bundler.env.map.get(name) != null or (Output.enable_ansi_colors and strings.eqlComptime(name, "FORCE_COLOR"));
        }

        pub fn convertToType(ctx: js.JSContextRef, obj: js.JSObjectRef, kind: js.JSType, exception: js.ExceptionRef) callconv(.C) js.JSValueRef {
            _ = ctx;
            _ = obj;
            _ = kind;
            _ = exception;
            return obj;
        }

        pub fn getPropertyNames(
            _: js.JSContextRef,
            _: js.JSObjectRef,
            props: js.JSPropertyNameAccumulatorRef,
        ) callconv(.C) void {
            var iter = VirtualMachine.vm.bundler.env.map.iter();

            while (iter.next()) |item| {
                const str = item.key_ptr.*;
                js.JSPropertyNameAccumulatorAddName(props, js.JSStringCreateStatic(str.ptr, str.len));
            }
        }
    };
};

pub const OpaqueCallback = fn (current: ?*anyopaque) callconv(.C) void;
pub fn OpaqueWrap(comptime Context: type, comptime Function: fn (this: *Context) void) OpaqueCallback {
    return struct {
        pub fn callback(ctx: ?*anyopaque) callconv(.C) void {
            var context: *Context = @ptrCast(*Context, @alignCast(@alignOf(Context), ctx.?));
            @call(.{}, Function, .{context});
        }
    }.callback;
}

pub const Performance = struct {
    pub const Class = NewClass(
        void,
        .{
            .name = "performance",
            .read_only = true,
        },
        .{
            .now = .{
                .rfn = Performance.now,
            },
        },
        .{},
    );

    pub fn now(
        _: void,
        ctx: js.JSContextRef,
        _: js.JSObjectRef,
        _: js.JSObjectRef,
        _: []const js.JSValueRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        return js.JSValueMakeNumber(
            ctx,
            @floatCast(
                f64,
                @intToFloat(
                    f128,
                    VirtualMachine.vm.origin_timer.read(),
                ) / std.time.ns_per_ms,
            ),
        );
    }
};

const bun_file_import_path = "/node_modules.server.bun";

const FetchTasklet = Fetch.FetchTasklet;
const TaggedPointerUnion = @import("../../tagged_pointer.zig").TaggedPointerUnion;
const WorkPool = @import("../../work_pool.zig");
pub fn ConcurrentPromiseTask(comptime Context: type) type {
    return struct {
        const This = @This();
        ctx: *Context,
        task: WorkPool.Task = .{ .callback = runFromThreadPool },
        event_loop: *VirtualMachine.EventLoop,
        allocator: std.mem.Allocator,
        promise: JSValue,
        globalThis: *JSGlobalObject,

        pub fn createOnJSThread(allocator: std.mem.Allocator, globalThis: *JSGlobalObject, value: *Context) !*This {
            var this = try allocator.create(This);
            this.* = .{
                .event_loop = VirtualMachine.vm.event_loop,
                .ctx = value,
                .allocator = allocator,
                .promise = JSValue.createInternalPromise(globalThis),
                .globalThis = globalThis,
            };
            js.JSValueProtect(globalThis.ref(), this.promise.asObjectRef());
            VirtualMachine.vm.active_tasks +|= 1;
            return this;
        }

        pub fn runFromThreadPool(task: *WorkPool.Task) void {
            var this = @fieldParentPtr(This, "task", task);
            Context.run(this.ctx);
            this.onFinish();
        }

        pub fn runFromJS(this: This) void {
            var promise_value = this.promise;
            var promise = promise_value.asInternalPromise() orelse {
                if (comptime @hasDecl(Context, "deinit")) {
                    @call(.{}, Context.deinit, .{this.ctx});
                }
                return;
            };

            var ctx = this.ctx;

            js.JSValueUnprotect(this.globalThis.ref(), promise_value.asObjectRef());
            ctx.then(promise);
        }

        pub fn schedule(this: *This) void {
            WorkPool.schedule(&this.task);
        }

        pub fn onFinish(this: *This) void {
            this.event_loop.enqueueTaskConcurrent(Task.init(this));
        }

        pub fn deinit(this: *This) void {
            this.allocator.destroy(this);
        }
    };
}

pub fn IOTask(comptime Context: type) type {
    return struct {
        const This = @This();
        ctx: *Context,
        task: NetworkThread.Task = .{ .callback = runFromThreadPool },
        event_loop: *VirtualMachine.EventLoop,
        allocator: std.mem.Allocator,
        globalThis: *JSGlobalObject,

        pub fn createOnJSThread(allocator: std.mem.Allocator, globalThis: *JSGlobalObject, value: *Context) !*This {
            var this = try allocator.create(This);
            this.* = .{
                .event_loop = VirtualMachine.vm.event_loop,
                .ctx = value,
                .allocator = allocator,
                .globalThis = globalThis,
            };
            return this;
        }

        pub fn runFromThreadPool(task: *NetworkThread.Task) void {
            var this = @fieldParentPtr(This, "task", task);
            Context.run(this.ctx, this);
        }

        pub fn runFromJS(this: This) void {
            var ctx = this.ctx;
            ctx.then(this.globalThis);
        }

        pub fn schedule(this: *This) void {
            NetworkThread.init() catch return;
            NetworkThread.global.pool.schedule(NetworkThread.Batch.from(&this.task));
        }

        pub fn onFinish(this: *This) void {
            this.event_loop.enqueueTaskConcurrent(Task.init(this));
        }

        pub fn deinit(this: *This) void {
            this.allocator.destroy(this);
        }
    };
}

const AsyncTransformTask = @import("./api/transpiler.zig").TransformTask.AsyncTransformTask;
const BunTimerTimeoutTask = Bun.Timer.Timeout.TimeoutTask;
// const PromiseTask = JSInternalPromise.Completion.PromiseTask;
pub const Task = TaggedPointerUnion(.{
    FetchTasklet,
    Microtask,
    AsyncTransformTask,
    BunTimerTimeoutTask,
    // PromiseTask,
    // TimeoutTasklet,
});

const SourceMap = @import("../../sourcemap/sourcemap.zig");
const MappingList = SourceMap.Mapping.List;

pub const SavedSourceMap = struct {
    // For bun.js, we store the number of mappings and how many bytes the final list is at the beginning of the array
    // The first 8 bytes are the length of the array
    // The second 8 bytes are the number of mappings
    pub const SavedMappings = struct {
        data: [*]u8,

        pub fn vlq(this: SavedMappings) []u8 {
            return this.data[16..this.len()];
        }

        pub inline fn len(this: SavedMappings) usize {
            return @bitCast(u64, this.data[0..8].*);
        }

        pub fn deinit(this: SavedMappings) void {
            default_allocator.free(this.data[0..this.len()]);
        }

        pub fn toMapping(this: SavedMappings, allocator: Allocator, path: string) anyerror!MappingList {
            const result = SourceMap.Mapping.parse(
                allocator,
                this.data[16..this.len()],
                @bitCast(usize, this.data[8..16].*),
                1,
            );
            switch (result) {
                .fail => |fail| {
                    if (Output.enable_ansi_colors_stderr) {
                        try fail.toData(path).writeFormat(
                            Output.errorWriter(),
                            logger.Kind.warn,
                            true,
                            false,
                        );
                    } else {
                        try fail.toData(path).writeFormat(
                            Output.errorWriter(),
                            logger.Kind.warn,
                            false,
                            false,
                        );
                    }

                    return fail.err;
                },
                .success => |success| {
                    return success;
                },
            }
        }
    };

    pub const Value = TaggedPointerUnion(.{ MappingList, SavedMappings });
    pub const HashTable = std.HashMap(u64, *anyopaque, IdentityContext(u64), 80);

    map: HashTable,

    pub fn onSourceMapChunk(this: *SavedSourceMap, chunk: SourceMap.Chunk, source: logger.Source) anyerror!void {
        try this.putMappings(source, chunk.buffer);
    }

    pub const SourceMapHandler = js_printer.SourceMapHandler.For(SavedSourceMap, onSourceMapChunk);

    pub fn putMappings(this: *SavedSourceMap, source: logger.Source, mappings: MutableString) !void {
        var entry = try this.map.getOrPut(std.hash.Wyhash.hash(0, source.path.text));
        if (entry.found_existing) {
            var value = Value.from(entry.value_ptr.*);
            if (value.get(MappingList)) |source_map_| {
                var source_map: *MappingList = source_map_;
                source_map.deinit(default_allocator);
            } else if (value.get(SavedMappings)) |saved_mappings| {
                var saved = SavedMappings{ .data = @ptrCast([*]u8, saved_mappings) };

                saved.deinit();
            }
        }

        entry.value_ptr.* = Value.init(bun.cast(*SavedMappings, mappings.list.items.ptr)).ptr();
    }

    pub fn get(this: *SavedSourceMap, path: string) ?MappingList {
        var mapping = this.map.getEntry(std.hash.Wyhash.hash(0, path)) orelse return null;
        switch (Value.from(mapping.value_ptr.*).tag()) {
            (@field(Value.Tag, @typeName(MappingList))) => {
                return Value.from(mapping.value_ptr.*).as(MappingList).*;
            },
            Value.Tag.SavedMappings => {
                var saved = SavedMappings{ .data = @ptrCast([*]u8, Value.from(mapping.value_ptr.*).as(MappingList)) };
                defer saved.deinit();
                var result = default_allocator.create(MappingList) catch unreachable;
                result.* = saved.toMapping(default_allocator, path) catch {
                    _ = this.map.remove(mapping.key_ptr.*);
                    return null;
                };
                mapping.value_ptr.* = Value.init(result).ptr();
                return result.*;
            },
            else => return null,
        }
    }

    pub fn resolveMapping(
        this: *SavedSourceMap,
        path: []const u8,
        line: i32,
        column: i32,
    ) ?SourceMap.Mapping {
        var mappings = this.get(path) orelse return null;
        return SourceMap.Mapping.find(mappings, line, column);
    }
};

// If you read JavascriptCore/API/JSVirtualMachine.mm - https://github.com/WebKit/WebKit/blob/acff93fb303baa670c055cb24c2bad08691a01a0/Source/JavaScriptCore/API/JSVirtualMachine.mm#L101
// We can see that it's sort of like std.mem.Allocator but for JSGlobalContextRef, to support Automatic Reference Counting
// Its unavailable on Linux

// JavaScriptCore expects 1 VM per thread
// However, there can be many JSGlobalObject
// We currently assume a 1:1 correspondence between the two.
// This is technically innacurate
pub const VirtualMachine = struct {
    global: *JSGlobalObject,
    allocator: std.mem.Allocator,
    node_modules: ?*NodeModuleBundle = null,
    bundler: Bundler,
    watcher: ?*http.Watcher = null,
    console: *ZigConsoleClient,
    log: *logger.Log,
    event_listeners: EventListenerMixin.Map,
    main: string = "",
    process: js.JSObjectRef = null,
    blobs: ?*Blob.Group = null,
    flush_list: std.ArrayList(string),
    entry_point: ServerEntryPoint = undefined,
    origin: URL = URL{},
    node_fs: ?*Node.NodeFS = null,
    has_loaded_node_modules: bool = false,
    timer: Bun.Timer = Bun.Timer{},

    arena: *Arena = undefined,
    has_loaded: bool = false,

    transpiled_count: usize = 0,
    resolved_count: usize = 0,
    had_errors: bool = false,

    macros: MacroMap,
    macro_entry_points: std.AutoArrayHashMap(i32, *MacroEntryPoint),
    macro_mode: bool = false,

    has_any_macro_remappings: bool = false,
    is_from_devserver: bool = false,
    has_enabled_macro_mode: bool = false,
    argv: []const []const u8 = &[_][]const u8{"bun"},

    origin_timer: std.time.Timer = undefined,
    active_tasks: usize = 0,

    macro_event_loop: EventLoop = EventLoop{},
    regular_event_loop: EventLoop = EventLoop{},
    event_loop: *EventLoop = undefined,

    source_mappings: SavedSourceMap = undefined,

    pub inline fn eventLoop(this: *VirtualMachine) *EventLoop {
        return this.event_loop;
    }

    pub const EventLoop = struct {
        ready_tasks_count: std.atomic.Atomic(u32) = std.atomic.Atomic(u32).init(0),
        pending_tasks_count: std.atomic.Atomic(u32) = std.atomic.Atomic(u32).init(0),
        io_tasks_count: std.atomic.Atomic(u32) = std.atomic.Atomic(u32).init(0),
        tasks: Queue = undefined,
        concurrent_tasks: Queue = undefined,
        concurrent_lock: Lock = Lock.init(),
        global: *JSGlobalObject = undefined,
        virtual_machine: *VirtualMachine = undefined,
        pub const Queue = std.fifo.LinearFifo(Task, .Dynamic);

        pub fn tickWithCount(this: *EventLoop) u32 {
            var finished: u32 = 0;
            var global = this.global;
            var vm_ = this.virtual_machine;
            while (this.tasks.readItem()) |task| {
                switch (task.tag()) {
                    .Microtask => {
                        var micro: *Microtask = task.as(Microtask);
                        micro.run(global);
                        finished += 1;
                    },
                    .FetchTasklet => {
                        var fetch_task: *Fetch.FetchTasklet = task.get(Fetch.FetchTasklet).?;
                        fetch_task.onDone();
                        finished += 1;
                        vm_.active_tasks -|= 1;
                    },
                    @field(Task.Tag, @typeName(AsyncTransformTask)) => {
                        var transform_task: *AsyncTransformTask = task.get(AsyncTransformTask).?;
                        transform_task.*.runFromJS();
                        transform_task.deinit();
                        finished += 1;
                        vm_.active_tasks -|= 1;
                    },
                    @field(Task.Tag, @typeName(BunTimerTimeoutTask)) => {
                        var transform_task: *BunTimerTimeoutTask = task.get(BunTimerTimeoutTask).?;
                        transform_task.*.runFromJS();
                        finished += 1;
                    },
                    else => unreachable,
                }
            }

            if (finished > 0) {
                _ = this.pending_tasks_count.fetchSub(finished, .Monotonic);
            }

            return finished;
        }

        pub fn tickConcurrent(this: *EventLoop) void {
            if (this.ready_tasks_count.load(.Monotonic) > 0) {
                this.concurrent_lock.lock();
                defer this.concurrent_lock.unlock();
                const add: u32 = @truncate(u32, this.concurrent_tasks.readableLength());

                // TODO: optimzie
                this.tasks.ensureUnusedCapacity(add) catch unreachable;

                {
                    @fence(.SeqCst);
                    while (this.concurrent_tasks.readItem()) |task| {
                        this.tasks.writeItemAssumeCapacity(task);
                    }
                }

                _ = this.pending_tasks_count.fetchAdd(add, .Monotonic);
                _ = this.ready_tasks_count.fetchSub(add, .Monotonic);
            }
        }
        pub fn tick(this: *EventLoop) void {
            this.tickConcurrent();

            while (this.tickWithCount() > 0) {}
        }

        pub fn waitForTasks(this: *EventLoop) void {
            this.tickConcurrent();

            while (this.pending_tasks_count.load(.Monotonic) > 0) {
                while (this.tickWithCount() > 0) {}
            }
        }

        pub fn enqueueTask(this: *EventLoop, task: Task) void {
            _ = this.pending_tasks_count.fetchAdd(1, .Monotonic);
            this.tasks.writeItem(task) catch unreachable;
        }

        pub fn enqueueTaskConcurrent(this: *EventLoop, task: Task) void {
            this.concurrent_lock.lock();
            defer this.concurrent_lock.unlock();
            this.concurrent_tasks.writeItem(task) catch unreachable;
            _ = this.ready_tasks_count.fetchAdd(1, .Monotonic);
        }
    };

    pub inline fn enqueueTask(this: *VirtualMachine, task: Task) void {
        this.eventLoop().enqueueTask(task);
    }

    pub inline fn enqueueTaskConcurrent(this: *VirtualMachine, task: Task) void {
        this.eventLoop().enqueueTaskConcurrent(task);
    }

    pub fn tick(this: *VirtualMachine) void {
        this.eventLoop().tickConcurrent();

        while (this.eventLoop().tickWithCount() > 0) {}
    }

    pub fn waitForTasks(this: *VirtualMachine) void {
        this.eventLoop().waitForTasks();
    }

    pub const MacroMap = std.AutoArrayHashMap(i32, js.JSObjectRef);

    pub threadlocal var vm_loaded = false;
    pub threadlocal var vm: *VirtualMachine = undefined;

    pub fn enableMacroMode(this: *VirtualMachine) void {
        if (!this.has_enabled_macro_mode) {
            this.has_enabled_macro_mode = true;
            this.macro_event_loop.tasks = EventLoop.Queue.init(default_allocator);
            this.macro_event_loop.global = this.global;
            this.macro_event_loop.virtual_machine = this;
            this.macro_event_loop.concurrent_tasks = EventLoop.Queue.init(default_allocator);
        }

        this.bundler.options.platform = .bun_macro;
        this.bundler.resolver.caches.fs.is_macro_mode = true;
        this.macro_mode = true;
        this.event_loop = &this.macro_event_loop;
        Analytics.Features.macros = true;
    }

    pub fn disableMacroMode(this: *VirtualMachine) void {
        this.bundler.options.platform = .bun;
        this.bundler.resolver.caches.fs.is_macro_mode = false;
        this.macro_mode = false;
        this.event_loop = &this.regular_event_loop;
    }

    pub fn getAPIGlobals() []js.JSClassRef {
        if (is_bindgen)
            return &[_]js.JSClassRef{};
        var classes = default_allocator.alloc(js.JSClassRef, GlobalClasses.len) catch return &[_]js.JSClassRef{};
        inline for (GlobalClasses) |Class, i| {
            classes[i] = Class.get().*;
        }

        return classes;
    }

    pub fn init(
        allocator: std.mem.Allocator,
        _args: Api.TransformOptions,
        existing_bundle: ?*NodeModuleBundle,
        _log: ?*logger.Log,
        env_loader: ?*DotEnv.Loader,
    ) !*VirtualMachine {
        var log: *logger.Log = undefined;
        if (_log) |__log| {
            log = __log;
        } else {
            log = try allocator.create(logger.Log);
            log.* = logger.Log.init(allocator);
        }

        VirtualMachine.vm = try allocator.create(VirtualMachine);
        var console = try allocator.create(ZigConsoleClient);
        console.* = ZigConsoleClient.init(Output.errorWriter(), Output.writer());
        const bundler = try Bundler.init(
            allocator,
            log,
            try Config.configureTransformOptionsForBunVM(allocator, _args),
            existing_bundle,
            env_loader,
        );

        VirtualMachine.vm.* = VirtualMachine{
            .global = undefined,
            .allocator = allocator,
            .entry_point = ServerEntryPoint{},
            .event_listeners = EventListenerMixin.Map.init(allocator),
            .bundler = bundler,
            .console = console,
            .node_modules = bundler.options.node_modules_bundle,
            .log = log,
            .flush_list = std.ArrayList(string).init(allocator),
            .blobs = if (_args.serve orelse false) try Blob.Group.init(allocator) else null,
            .origin = bundler.options.origin,
            .source_mappings = SavedSourceMap{ .map = SavedSourceMap.HashTable.init(allocator) },
            .macros = MacroMap.init(allocator),
            .macro_entry_points = @TypeOf(VirtualMachine.vm.macro_entry_points).init(allocator),
            .origin_timer = std.time.Timer.start() catch @panic("Please don't mess with timers."),
        };

        VirtualMachine.vm.regular_event_loop.tasks = EventLoop.Queue.init(
            default_allocator,
        );
        VirtualMachine.vm.regular_event_loop.concurrent_tasks = EventLoop.Queue.init(default_allocator);
        VirtualMachine.vm.event_loop = &VirtualMachine.vm.regular_event_loop;

        vm.bundler.macro_context = null;

        VirtualMachine.vm.bundler.configureLinker();
        try VirtualMachine.vm.bundler.configureFramework(false);

        vm.bundler.macro_context = js_ast.Macro.MacroContext.init(&vm.bundler);

        if (_args.serve orelse false) {
            VirtualMachine.vm.bundler.linker.onImportCSS = Bun.onImportCSS;
        }

        var global_classes: [GlobalClasses.len]js.JSClassRef = undefined;
        inline for (GlobalClasses) |Class, i| {
            global_classes[i] = Class.get().*;
        }
        VirtualMachine.vm.global = ZigGlobalObject.create(
            &global_classes,
            @intCast(i32, global_classes.len),
            vm.console,
        );
        VirtualMachine.vm.regular_event_loop.global = VirtualMachine.vm.global;
        VirtualMachine.vm.regular_event_loop.virtual_machine = VirtualMachine.vm;
        VirtualMachine.vm_loaded = true;

        if (source_code_printer == null) {
            var writer = try js_printer.BufferWriter.init(allocator);
            source_code_printer = allocator.create(js_printer.BufferPrinter) catch unreachable;
            source_code_printer.?.* = js_printer.BufferPrinter.init(writer);
            source_code_printer.?.ctx.append_null_byte = false;
        }

        return VirtualMachine.vm;
    }

    // dynamic import
    // pub fn import(global: *JSGlobalObject, specifier: ZigString, source: ZigString) callconv(.C) ErrorableZigString {

    // }

    threadlocal var source_code_printer: ?*js_printer.BufferPrinter = null;

    pub fn preflush(this: *VirtualMachine) void {
        // We flush on the next tick so that if there were any errors you can still see them
        this.blobs.?.temporary.reset() catch {};
    }

    pub fn flush(this: *VirtualMachine) void {
        this.had_errors = false;
        for (this.flush_list.items) |item| {
            this.allocator.free(item);
        }
        this.flush_list.shrinkRetainingCapacity(0);
        this.transpiled_count = 0;
        this.resolved_count = 0;
    }

    inline fn _fetch(
        _: *JSGlobalObject,
        _specifier: string,
        _: string,
        log: *logger.Log,
        comptime disable_transpilying: bool,
    ) !ResolvedSource {
        std.debug.assert(VirtualMachine.vm_loaded);
        var jsc_vm = vm;

        if (jsc_vm.node_modules != null and strings.eqlComptime(_specifier, bun_file_import_path)) {
            // We kind of need an abstraction around this.
            // Basically we should subclass JSC::SourceCode with:
            // - hash
            // - file descriptor for source input
            // - file path + file descriptor for bytecode caching
            // - separate bundles for server build vs browser build OR at least separate sections
            const code = try jsc_vm.node_modules.?.readCodeAsStringSlow(jsc_vm.allocator);

            return ResolvedSource{
                .allocator = null,
                .source_code = ZigString.init(code),
                .specifier = ZigString.init(bun_file_import_path),
                .source_url = ZigString.init(bun_file_import_path[1..]),
                .hash = 0, // TODO
            };
        } else if (jsc_vm.node_modules == null and strings.eqlComptime(_specifier, Runtime.Runtime.Imports.Name)) {
            return ResolvedSource{
                .allocator = null,
                .source_code = ZigString.init(Runtime.Runtime.sourceContent(false)),
                .specifier = ZigString.init(Runtime.Runtime.Imports.Name),
                .source_url = ZigString.init(Runtime.Runtime.Imports.Name),
                .hash = Runtime.Runtime.versionHash(),
            };
            // This is all complicated because the imports have to be linked and we want to run the printer on it
            // so it consistently handles bundled imports
            // we can't take the shortcut of just directly importing the file, sadly.
        } else if (strings.eqlComptime(_specifier, main_file_name)) {
            if (comptime disable_transpilying) {
                return ResolvedSource{
                    .allocator = null,
                    .source_code = ZigString.init(jsc_vm.entry_point.source.contents),
                    .specifier = ZigString.init(std.mem.span(main_file_name)),
                    .source_url = ZigString.init(std.mem.span(main_file_name)),
                    .hash = 0,
                };
            }
            defer jsc_vm.transpiled_count += 1;

            var bundler = &jsc_vm.bundler;
            var old = jsc_vm.bundler.log;
            jsc_vm.bundler.log = log;
            jsc_vm.bundler.linker.log = log;
            jsc_vm.bundler.resolver.log = log;
            defer {
                jsc_vm.bundler.log = old;
                jsc_vm.bundler.linker.log = old;
                jsc_vm.bundler.resolver.log = old;
            }

            var jsx = bundler.options.jsx;
            jsx.parse = false;
            var opts = js_parser.Parser.Options.init(jsx, .js);
            opts.enable_bundling = false;
            opts.transform_require_to_import = true;
            opts.can_import_from_bundle = bundler.options.node_modules_bundle != null;
            opts.features.hot_module_reloading = false;
            opts.features.react_fast_refresh = false;
            opts.filepath_hash_for_hmr = 0;
            opts.warn_about_unbundled_modules = false;
            opts.macro_context = &jsc_vm.bundler.macro_context.?;
            const main_ast = (bundler.resolver.caches.js.parse(jsc_vm.allocator, opts, bundler.options.define, bundler.log, &jsc_vm.entry_point.source) catch null) orelse {
                return error.ParseError;
            };
            var parse_result = ParseResult{ .source = jsc_vm.entry_point.source, .ast = main_ast, .loader = .js, .input_fd = null };
            var file_path = Fs.Path.init(bundler.fs.top_level_dir);
            file_path.name.dir = bundler.fs.top_level_dir;
            file_path.name.base = "bun:main";
            try bundler.linker.link(
                file_path,
                &parse_result,
                jsc_vm.origin,
                .absolute_path,
                false,
            );
            var printer = source_code_printer.?.*;
            var written: usize = undefined;
            printer.ctx.reset();
            {
                defer source_code_printer.?.* = printer;
                written = try jsc_vm.bundler.printWithSourceMap(
                    parse_result,
                    @TypeOf(&printer),
                    &printer,
                    .esm_ascii,
                    SavedSourceMap.SourceMapHandler.init(&jsc_vm.source_mappings),
                );
            }

            if (written == 0) {
                return error.PrintingErrorWriteFailed;
            }

            return ResolvedSource{
                .allocator = null,
                .source_code = ZigString.init(jsc_vm.allocator.dupe(u8, printer.ctx.written) catch unreachable),
                .specifier = ZigString.init(std.mem.span(main_file_name)),
                .source_url = ZigString.init(std.mem.span(main_file_name)),
                .hash = 0,
            };
        } else if (_specifier.len > js_ast.Macro.namespaceWithColon.len and
            strings.eqlComptimeIgnoreLen(_specifier[0..js_ast.Macro.namespaceWithColon.len], js_ast.Macro.namespaceWithColon))
        {
            if (comptime !disable_transpilying) {
                if (jsc_vm.macro_entry_points.get(MacroEntryPoint.generateIDFromSpecifier(_specifier))) |entry| {
                    return ResolvedSource{
                        .allocator = null,
                        .source_code = ZigString.init(entry.source.contents),
                        .specifier = ZigString.init(_specifier),
                        .source_url = ZigString.init(_specifier),
                        .hash = 0,
                    };
                }
            }
        } else if (strings.eqlComptime(_specifier, "node:fs")) {
            return ResolvedSource{
                .allocator = null,
                .source_code = ZigString.init(@embedFile("fs.exports.js")),
                .specifier = ZigString.init("node:fs"),
                .source_url = ZigString.init("node:fs"),
                .hash = 0,
            };
        } else if (strings.eqlComptime(_specifier, "node:path")) {
            return ResolvedSource{
                .allocator = null,
                .source_code = ZigString.init(Node.Path.code),
                .specifier = ZigString.init("node:path"),
                .source_url = ZigString.init("node:path"),
                .hash = 0,
            };
        }

        const specifier = normalizeSpecifier(_specifier);

        std.debug.assert(std.fs.path.isAbsolute(specifier)); // if this crashes, it means the resolver was skipped.

        const path = Fs.Path.init(specifier);
        const loader = jsc_vm.bundler.options.loaders.get(path.name.ext) orelse .file;

        switch (loader) {
            .js, .jsx, .ts, .tsx, .json, .toml => {
                jsc_vm.transpiled_count += 1;
                jsc_vm.bundler.resetStore();
                const hash = http.Watcher.getHash(path.text);

                var allocator = if (jsc_vm.has_loaded) jsc_vm.arena.allocator() else jsc_vm.allocator;

                var fd: ?StoredFileDescriptorType = null;
                var package_json: ?*PackageJSON = null;

                if (jsc_vm.watcher) |watcher| {
                    if (watcher.indexOf(hash)) |index| {
                        const _fd = watcher.watchlist.items(.fd)[index];
                        fd = if (_fd > 0) _fd else null;
                        package_json = watcher.watchlist.items(.package_json)[index];
                    }
                }

                var old = jsc_vm.bundler.log;
                jsc_vm.bundler.log = log;
                jsc_vm.bundler.linker.log = log;
                jsc_vm.bundler.resolver.log = log;

                defer {
                    jsc_vm.bundler.log = old;
                    jsc_vm.bundler.linker.log = old;
                    jsc_vm.bundler.resolver.log = old;
                }

                // this should be a cheap lookup because 24 bytes == 8 * 3 so it's read 3 machine words
                const is_node_override = specifier.len > "/bun-vfs/node_modules/".len and strings.eqlComptimeIgnoreLen(specifier[0.."/bun-vfs/node_modules/".len], "/bun-vfs/node_modules/");

                const macro_remappings = if (jsc_vm.macro_mode or !jsc_vm.has_any_macro_remappings or is_node_override)
                    MacroRemap{}
                else
                    jsc_vm.bundler.options.macro_remap;

                var fallback_source: logger.Source = undefined;

                var parse_options = Bundler.ParseOptions{
                    .allocator = allocator,
                    .path = path,
                    .loader = loader,
                    .dirname_fd = 0,
                    .file_descriptor = fd,
                    .file_hash = hash,
                    .macro_remappings = macro_remappings,
                    .jsx = jsc_vm.bundler.options.jsx,
                };

                if (is_node_override) {
                    if (NodeFallbackModules.contentsFromPath(specifier)) |code| {
                        const fallback_path = Fs.Path.initWithNamespace(specifier, "node");
                        fallback_source = logger.Source{ .path = fallback_path, .contents = code, .key_path = fallback_path };
                        parse_options.virtual_source = &fallback_source;
                    }
                }

                var parse_result = jsc_vm.bundler.parseMaybeReturnFileOnly(
                    parse_options,
                    null,
                    disable_transpilying,
                ) orelse {
                    return error.ParseError;
                };

                if (comptime disable_transpilying) {
                    return ResolvedSource{
                        .allocator = null,
                        .source_code = ZigString.init(parse_result.source.contents),
                        .specifier = ZigString.init(specifier),
                        .source_url = ZigString.init(path.text),
                        .hash = 0,
                    };
                }

                const start_count = jsc_vm.bundler.linker.import_counter;
                // We _must_ link because:
                // - node_modules bundle won't be properly
                try jsc_vm.bundler.linker.link(
                    path,
                    &parse_result,
                    jsc_vm.origin,
                    .absolute_path,
                    false,
                );

                if (!jsc_vm.macro_mode)
                    jsc_vm.resolved_count += jsc_vm.bundler.linker.import_counter - start_count;
                jsc_vm.bundler.linker.import_counter = 0;

                var printer = source_code_printer.?.*;
                var written: usize = undefined;
                printer.ctx.reset();
                {
                    defer source_code_printer.?.* = printer;
                    written = try jsc_vm.bundler.printWithSourceMap(
                        parse_result,
                        @TypeOf(&printer),
                        &printer,
                        .esm_ascii,
                        SavedSourceMap.SourceMapHandler.init(&jsc_vm.source_mappings),
                    );
                }

                if (written == 0) {
                    return error.PrintingErrorWriteFailed;
                }

                return ResolvedSource{
                    .allocator = if (jsc_vm.has_loaded) &jsc_vm.allocator else null,
                    .source_code = ZigString.init(jsc_vm.allocator.dupe(u8, printer.ctx.written) catch unreachable),
                    .specifier = ZigString.init(specifier),
                    .source_url = ZigString.init(path.text),
                    .hash = 0,
                };
            },
            // .wasm => {
            //     jsc_vm.transpiled_count += 1;
            //     var fd: ?StoredFileDescriptorType = null;

            //     var allocator = if (jsc_vm.has_loaded) jsc_vm.arena.allocator() else jsc_vm.allocator;

            //     const hash = http.Watcher.getHash(path.text);
            //     if (jsc_vm.watcher) |watcher| {
            //         if (watcher.indexOf(hash)) |index| {
            //             const _fd = watcher.watchlist.items(.fd)[index];
            //             fd = if (_fd > 0) _fd else null;
            //         }
            //     }

            //     var parse_options = Bundler.ParseOptions{
            //         .allocator = allocator,
            //         .path = path,
            //         .loader = loader,
            //         .dirname_fd = 0,
            //         .file_descriptor = fd,
            //         .file_hash = hash,
            //         .macro_remappings = MacroRemap{},
            //         .jsx = jsc_vm.bundler.options.jsx,
            //     };

            //     var parse_result = jsc_vm.bundler.parse(
            //         parse_options,
            //         null,
            //     ) orelse {
            //         return error.ParseError;
            //     };

            //     return ResolvedSource{
            //         .allocator = if (jsc_vm.has_loaded) &jsc_vm.allocator else null,
            //         .source_code = ZigString.init(jsc_vm.allocator.dupe(u8, parse_result.source.contents) catch unreachable),
            //         .specifier = ZigString.init(specifier),
            //         .source_url = ZigString.init(path.text),
            //         .hash = 0,
            //         .tag = ResolvedSource.Tag.wasm,
            //     };
            // },
            else => {
                return ResolvedSource{
                    .allocator = &vm.allocator,
                    .source_code = ZigString.init(try strings.quotedAlloc(jsc_vm.allocator, path.pretty)),
                    .specifier = ZigString.init(path.text),
                    .source_url = ZigString.init(path.text),
                    .hash = 0,
                };
            },
        }
    }
    pub const ResolveFunctionResult = struct {
        result: ?Resolver.Result,
        path: string,
    };

    fn _resolve(ret: *ResolveFunctionResult, _: *JSGlobalObject, specifier: string, source: string) !void {
        std.debug.assert(VirtualMachine.vm_loaded);
        // macOS threadlocal vars are very slow
        // we won't change threads in this function
        // so we can copy it here
        var jsc_vm = vm;

        if (jsc_vm.node_modules == null and strings.eqlComptime(std.fs.path.basename(specifier), Runtime.Runtime.Imports.alt_name)) {
            ret.path = Runtime.Runtime.Imports.Name;
            return;
        } else if (jsc_vm.node_modules != null and strings.eqlComptime(specifier, bun_file_import_path)) {
            ret.path = bun_file_import_path;
            return;
        } else if (strings.eqlComptime(specifier, main_file_name)) {
            ret.result = null;
            ret.path = jsc_vm.entry_point.source.path.text;
            return;
        } else if (specifier.len > js_ast.Macro.namespaceWithColon.len and strings.eqlComptimeIgnoreLen(specifier[0..js_ast.Macro.namespaceWithColon.len], js_ast.Macro.namespaceWithColon)) {
            ret.result = null;
            ret.path = specifier;
            return;
        } else if (specifier.len > "/bun-vfs/node_modules/".len and strings.eqlComptimeIgnoreLen(specifier[0.."/bun-vfs/node_modules/".len], "/bun-vfs/node_modules/")) {
            ret.result = null;
            ret.path = specifier;
            return;
        } else if (strings.eqlComptime(specifier, "node:fs")) {
            ret.result = null;
            ret.path = "node:fs";
            return;
        }
        if (strings.eqlComptime(specifier, "node:path")) {
            ret.result = null;
            ret.path = "node:path";
            return;
        }

        const is_special_source = strings.eqlComptime(source, main_file_name) or js_ast.Macro.isMacroPath(source);

        const result = try jsc_vm.bundler.resolver.resolve(
            if (!is_special_source) Fs.PathName.init(source).dirWithTrailingSlash() else jsc_vm.bundler.fs.top_level_dir,
            specifier,
            .stmt,
        );

        if (!jsc_vm.macro_mode) {
            jsc_vm.has_any_macro_remappings = jsc_vm.has_any_macro_remappings or jsc_vm.bundler.options.macro_remap.count() > 0;
        }
        ret.result = result;
        const result_path = result.pathConst() orelse return error.ModuleNotFound;
        jsc_vm.resolved_count += 1;

        if (jsc_vm.node_modules != null and !strings.eqlComptime(result_path.namespace, "node") and result.isLikelyNodeModule()) {
            const node_modules_bundle = jsc_vm.node_modules.?;

            node_module_checker: {
                const package_json = result.package_json orelse brk: {
                    if (jsc_vm.bundler.resolver.packageJSONForResolvedNodeModule(&result)) |pkg| {
                        break :brk pkg;
                    } else {
                        break :node_module_checker;
                    }
                };

                if (node_modules_bundle.getPackageIDByName(package_json.name)) |possible_pkg_ids| {
                    const pkg_id: u32 = brk: {
                        for (possible_pkg_ids) |pkg_id| {
                            const pkg = node_modules_bundle.bundle.packages[pkg_id];
                            if (pkg.hash == package_json.hash) {
                                break :brk pkg_id;
                            }
                        }
                        break :node_module_checker;
                    };

                    const package = &node_modules_bundle.bundle.packages[pkg_id];

                    if (Environment.isDebug) {
                        std.debug.assert(strings.eql(node_modules_bundle.str(package.name), package_json.name));
                    }

                    const package_relative_path = jsc_vm.bundler.fs.relative(
                        package_json.source.path.name.dirWithTrailingSlash(),
                        result_path.text,
                    );

                    if (node_modules_bundle.findModuleIDInPackage(package, package_relative_path) == null) break :node_module_checker;

                    ret.path = bun_file_import_path;
                    return;
                }
            }
        }

        ret.path = result_path.text;
    }
    pub fn queueMicrotaskToEventLoop(
        _: *JSGlobalObject,
        microtask: *Microtask,
    ) void {
        std.debug.assert(VirtualMachine.vm_loaded);

        vm.enqueueTask(Task.init(microtask));
    }
    pub fn resolve(res: *ErrorableZigString, global: *JSGlobalObject, specifier: ZigString, source: ZigString) void {
        var result = ResolveFunctionResult{ .path = "", .result = null };

        _resolve(&result, global, specifier.slice(), source.slice()) catch |err| {
            // This should almost always just apply to dynamic imports

            const printed = ResolveError.fmt(
                vm.allocator,
                specifier.slice(),
                source.slice(),
                err,
            ) catch unreachable;
            const msg = logger.Msg{
                .data = logger.rangeData(
                    null,
                    logger.Range.None,
                    printed,
                ),
                .metadata = .{
                    // import_kind is wrong probably
                    .resolve = .{ .specifier = logger.BabyString.in(printed, specifier.slice()), .import_kind = .stmt },
                },
            };

            {
                res.* = ErrorableZigString.err(err, @ptrCast(*anyopaque, ResolveError.create(global, vm.allocator, msg, source.slice())));
            }

            return;
        };

        res.* = ErrorableZigString.ok(ZigString.init(result.path));
    }
    pub fn normalizeSpecifier(slice_: string) string {
        var vm_ = VirtualMachine.vm;

        var slice = slice_;
        if (slice.len == 0) return slice;
        var was_http = false;
        if (strings.hasPrefix(slice, "https://")) {
            slice = slice["https://".len..];
            was_http = true;
        }

        if (strings.hasPrefix(slice, "http://")) {
            slice = slice["http://".len..];
            was_http = true;
        }

        if (strings.hasPrefix(slice, vm_.origin.host)) {
            slice = slice[vm_.origin.host.len..];
        } else if (was_http) {
            if (strings.indexOfChar(slice, '/')) |i| {
                slice = slice[i..];
            }
        }

        if (vm_.origin.path.len > 1) {
            if (strings.hasPrefix(slice, vm_.origin.path)) {
                slice = slice[vm_.origin.path.len..];
            }
        }

        if (vm_.bundler.options.routes.asset_prefix_path.len > 0) {
            if (strings.hasPrefix(slice, vm_.bundler.options.routes.asset_prefix_path)) {
                slice = slice[vm_.bundler.options.routes.asset_prefix_path.len..];
            }
        }

        return slice;
    }

    // This double prints
    pub fn promiseRejectionTracker(_: *JSGlobalObject, _: *JSPromise, _: JSPromiseRejectionOperation) callconv(.C) JSValue {
        // VirtualMachine.vm.defaultErrorHandler(promise.result(global.vm()), null);
        return JSValue.jsUndefined();
    }

    const main_file_name: string = "bun:main";
    pub threadlocal var errors_stack: [256]*anyopaque = undefined;
    pub fn fetch(ret: *ErrorableResolvedSource, global: *JSGlobalObject, specifier: ZigString, source: ZigString) callconv(.C) void {
        var log = logger.Log.init(vm.bundler.allocator);
        const spec = specifier.slice();
        const result = _fetch(global, spec, source.slice(), &log, false) catch |err| {
            processFetchLog(global, specifier, source, &log, ret, err);
            return;
        };

        if (log.errors > 0) {
            processFetchLog(global, specifier, source, &log, ret, error.LinkError);
            return;
        }

        if (log.warnings > 0) {
            var writer = Output.errorWriter();
            if (Output.enable_ansi_colors) {
                for (log.msgs.items) |msg| {
                    if (msg.kind == .warn) {
                        msg.writeFormat(writer, true) catch {};
                    }
                }
            } else {
                for (log.msgs.items) |msg| {
                    if (msg.kind == .warn) {
                        msg.writeFormat(writer, false) catch {};
                    }
                }
            }
        }

        ret.result.value = result;

        if (vm.blobs) |blobs| {
            const specifier_blob = brk: {
                if (strings.hasPrefix(spec, VirtualMachine.vm.bundler.fs.top_level_dir)) {
                    break :brk spec[VirtualMachine.vm.bundler.fs.top_level_dir.len..];
                }
                break :brk spec;
            };

            if (vm.has_loaded) {
                blobs.temporary.put(specifier_blob, .{ .ptr = result.source_code.ptr, .len = result.source_code.len }) catch {};
            } else {
                blobs.persistent.put(specifier_blob, .{ .ptr = result.source_code.ptr, .len = result.source_code.len }) catch {};
            }
        }

        ret.success = true;
    }

    fn processFetchLog(globalThis: *JSGlobalObject, specifier: ZigString, referrer: ZigString, log: *logger.Log, ret: *ErrorableResolvedSource, err: anyerror) void {
        switch (log.msgs.items.len) {
            0 => {
                const msg = logger.Msg{
                    .data = logger.rangeData(null, logger.Range.None, std.fmt.allocPrint(vm.allocator, "{s} while building {s}", .{ @errorName(err), specifier.slice() }) catch unreachable),
                };
                {
                    ret.* = ErrorableResolvedSource.err(err, @ptrCast(*anyopaque, BuildError.create(globalThis, vm.bundler.allocator, msg)));
                }
                return;
            },

            1 => {
                const msg = log.msgs.items[0];
                ret.* = ErrorableResolvedSource.err(err, switch (msg.metadata) {
                    .build => BuildError.create(globalThis, vm.bundler.allocator, msg).?,
                    .resolve => ResolveError.create(
                        globalThis,
                        vm.bundler.allocator,
                        msg,
                        referrer.slice(),
                    ).?,
                });
                return;
            },
            else => {
                var errors = errors_stack[0..@minimum(log.msgs.items.len, errors_stack.len)];

                for (log.msgs.items) |msg, i| {
                    errors[i] = switch (msg.metadata) {
                        .build => BuildError.create(globalThis, vm.bundler.allocator, msg).?,
                        .resolve => ResolveError.create(
                            globalThis,
                            vm.bundler.allocator,
                            msg,
                            referrer.slice(),
                        ).?,
                    };
                }

                ret.* = ErrorableResolvedSource.err(
                    err,
                    globalThis.createAggregateError(
                        errors.ptr,
                        @intCast(u16, errors.len),
                        &ZigString.init(
                            std.fmt.allocPrint(vm.bundler.allocator, "{d} errors building \"{s}\"", .{
                                errors.len,
                                specifier.slice(),
                            }) catch unreachable,
                        ),
                    ).asVoid(),
                );
            },
        }
    }

    // TODO:
    pub fn deinit(_: *VirtualMachine) void {}

    pub const ExceptionList = std.ArrayList(Api.JsException);

    pub fn printException(
        this: *VirtualMachine,
        exception: *Exception,
        exception_list: ?*ExceptionList,
        comptime Writer: type,
        writer: Writer,
    ) void {
        if (Output.enable_ansi_colors) {
            this.printErrorlikeObject(exception.value(), exception, exception_list, Writer, writer, true);
        } else {
            this.printErrorlikeObject(exception.value(), exception, exception_list, Writer, writer, false);
        }
    }

    pub fn defaultErrorHandler(this: *VirtualMachine, result: JSValue, exception_list: ?*ExceptionList) void {
        if (result.isException(this.global.vm())) {
            var exception = @ptrCast(*Exception, result.asVoid());

            this.printException(
                exception,
                exception_list,
                @TypeOf(Output.errorWriter()),
                Output.errorWriter(),
            );
        } else if (Output.enable_ansi_colors) {
            this.printErrorlikeObject(result, null, exception_list, @TypeOf(Output.errorWriter()), Output.errorWriter(), true);
        } else {
            this.printErrorlikeObject(result, null, exception_list, @TypeOf(Output.errorWriter()), Output.errorWriter(), false);
        }
    }

    pub fn clearEntryPoint(
        this: *VirtualMachine,
    ) void {
        if (this.main.len == 0) {
            return;
        }

        var str = ZigString.init(main_file_name);
        this.global.deleteModuleRegistryEntry(&str);
    }

    pub fn loadEntryPoint(this: *VirtualMachine, entry_path: string) !*JSInternalPromise {
        try this.entry_point.generate(@TypeOf(this.bundler), &this.bundler, Fs.PathName.init(entry_path), main_file_name);
        this.main = entry_path;

        var promise: *JSInternalPromise = undefined;
        // We first import the node_modules bundle. This prevents any potential TDZ issues.
        // The contents of the node_modules bundle are lazy, so hopefully this should be pretty quick.
        if (this.node_modules != null and !this.has_loaded_node_modules) {
            this.has_loaded_node_modules = true;
            promise = JSModuleLoader.loadAndEvaluateModule(this.global, &ZigString.init(std.mem.span(bun_file_import_path)));

            this.tick();

            while (promise.status(this.global.vm()) == JSPromise.Status.Pending) {
                this.tick();
            }

            if (promise.status(this.global.vm()) == JSPromise.Status.Rejected) {
                return promise;
            }

            _ = promise.result(this.global.vm());
        }

        promise = JSModuleLoader.loadAndEvaluateModule(this.global, &ZigString.init(std.mem.span(main_file_name)));

        this.tick();

        while (promise.status(this.global.vm()) == JSPromise.Status.Pending) {
            this.tick();
        }

        return promise;
    }

    pub fn loadMacroEntryPoint(this: *VirtualMachine, entry_path: string, function_name: string, specifier: string, hash: i32) !*JSInternalPromise {
        var entry_point_entry = try this.macro_entry_points.getOrPut(hash);

        if (!entry_point_entry.found_existing) {
            var macro_entry_pointer: *MacroEntryPoint = this.allocator.create(MacroEntryPoint) catch unreachable;
            entry_point_entry.value_ptr.* = macro_entry_pointer;
            try macro_entry_pointer.generate(&this.bundler, Fs.PathName.init(entry_path), function_name, hash, specifier);
        }
        var entry_point = entry_point_entry.value_ptr.*;

        var loader = MacroEntryPointLoader{
            .path = entry_point.source.path.text,
        };

        this.runWithAPILock(MacroEntryPointLoader, &loader, MacroEntryPointLoader.load);
        return loader.promise;
    }

    /// A subtlelty of JavaScriptCore:
    /// JavaScriptCore has many release asserts that check an API lock is currently held
    /// We cannot hold it from Zig code because it relies on C++ ARIA to automatically release the lock
    /// and it is not safe to copy the lock itself
    /// So we have to wrap entry points to & from JavaScript with an API lock that calls out to C++
    pub inline fn runWithAPILock(this: *VirtualMachine, comptime Context: type, ctx: *Context, comptime function: fn (ctx: *Context) void) void {
        this.global.vm().holdAPILock(ctx, OpaqueWrap(Context, function));
    }

    const MacroEntryPointLoader = struct {
        path: string,
        promise: *JSInternalPromise = undefined,
        pub fn load(this: *MacroEntryPointLoader) void {
            this.promise = vm._loadMacroEntryPoint(this.path);
        }
    };

    pub inline fn _loadMacroEntryPoint(this: *VirtualMachine, entry_path: string) *JSInternalPromise {
        var promise: *JSInternalPromise = undefined;

        promise = JSModuleLoader.loadAndEvaluateModule(this.global, &ZigString.init(entry_path));

        this.tick();

        while (promise.status(this.global.vm()) == JSPromise.Status.Pending) {
            this.tick();
        }

        return promise;
    }

    // When the Error-like object is one of our own, it's best to rely on the object directly instead of serializing it to a ZigException.
    // This is for:
    // - BuildError
    // - ResolveError
    // If there were multiple errors, it could be contained in an AggregateError.
    // In that case, this function becomes recursive.
    // In all other cases, we will convert it to a ZigException.
    const errors_property = ZigString.init("errors");
    pub fn printErrorlikeObject(
        this: *VirtualMachine,
        value: JSValue,
        exception: ?*Exception,
        exception_list: ?*ExceptionList,
        comptime Writer: type,
        writer: Writer,
        comptime allow_ansi_color: bool,
    ) void {
        if (comptime JSC.is_bindgen) {
            return;
        }

        var was_internal = false;

        defer {
            if (was_internal) {
                if (exception) |exception_| {
                    var holder = ZigException.Holder.init();
                    var zig_exception: *ZigException = holder.zigException();
                    exception_.getStackTrace(&zig_exception.stack);
                    if (zig_exception.stack.frames_len > 0) {
                        if (allow_ansi_color) {
                            printStackTrace(Writer, writer, zig_exception.stack, true) catch {};
                        } else {
                            printStackTrace(Writer, writer, zig_exception.stack, false) catch {};
                        }
                    }

                    if (exception_list) |list| {
                        zig_exception.addToErrorList(list) catch {};
                    }
                }
            }
        }

        if (value.isAggregateError(this.global)) {
            const AggregateErrorIterator = struct {
                writer: Writer,
                current_exception_list: ?*ExceptionList = null,

                pub fn iteratorWithColor(_vm: [*c]VM, globalObject: [*c]JSGlobalObject, ctx: ?*anyopaque, nextValue: JSValue) callconv(.C) void {
                    iterator(_vm, globalObject, nextValue, ctx.?, true);
                }
                pub fn iteratorWithOutColor(_vm: [*c]VM, globalObject: [*c]JSGlobalObject, ctx: ?*anyopaque, nextValue: JSValue) callconv(.C) void {
                    iterator(_vm, globalObject, nextValue, ctx.?, false);
                }
                inline fn iterator(_: [*c]VM, _: [*c]JSGlobalObject, nextValue: JSValue, ctx: ?*anyopaque, comptime color: bool) void {
                    var this_ = @intToPtr(*@This(), @ptrToInt(ctx));
                    VirtualMachine.vm.printErrorlikeObject(nextValue, null, this_.current_exception_list, Writer, this_.writer, color);
                }
            };
            var iter = AggregateErrorIterator{ .writer = writer, .current_exception_list = exception_list };
            if (comptime allow_ansi_color) {
                value.getErrorsProperty(this.global).forEach(this.global, &iter, AggregateErrorIterator.iteratorWithColor);
            } else {
                value.getErrorsProperty(this.global).forEach(this.global, &iter, AggregateErrorIterator.iteratorWithOutColor);
            }
            return;
        }

        if (js.JSValueIsObject(this.global.ref(), value.asRef())) {
            if (js.JSObjectGetPrivate(value.asRef())) |priv| {
                was_internal = this.printErrorFromMaybePrivateData(
                    priv,
                    exception_list,
                    Writer,
                    writer,
                    allow_ansi_color,
                );
                return;
            }
        }

        was_internal = this.printErrorFromMaybePrivateData(
            value.asRef(),
            exception_list,
            Writer,
            writer,
            allow_ansi_color,
        );
    }

    pub fn printErrorFromMaybePrivateData(
        this: *VirtualMachine,
        value: ?*anyopaque,
        exception_list: ?*ExceptionList,
        comptime Writer: type,
        writer: Writer,
        comptime allow_ansi_color: bool,
    ) bool {
        const private_data_ptr = JSPrivateDataPtr.from(value);

        switch (private_data_ptr.tag()) {
            .BuildError => {
                defer Output.flush();
                var build_error = private_data_ptr.as(BuildError);
                if (!build_error.logged) {
                    build_error.msg.writeFormat(writer, allow_ansi_color) catch {};
                    writer.writeAll("\n") catch {};
                    build_error.logged = true;
                }
                this.had_errors = this.had_errors or build_error.msg.kind == .err;
                if (exception_list != null) {
                    this.log.addMsg(
                        build_error.msg,
                    ) catch {};
                }
                return true;
            },
            .ResolveError => {
                defer Output.flush();
                var resolve_error = private_data_ptr.as(ResolveError);
                if (!resolve_error.logged) {
                    resolve_error.msg.writeFormat(writer, allow_ansi_color) catch {};
                    resolve_error.logged = true;
                }

                this.had_errors = this.had_errors or resolve_error.msg.kind == .err;

                if (exception_list != null) {
                    this.log.addMsg(
                        resolve_error.msg,
                    ) catch {};
                }
                return true;
            },
            else => {
                this.printErrorInstance(
                    @intToEnum(JSValue, @intCast(i64, (@ptrToInt(value)))),
                    exception_list,
                    Writer,
                    writer,
                    allow_ansi_color,
                ) catch |err| {
                    if (comptime Environment.isDebug) {
                        // yo dawg
                        Output.printErrorln("Error while printing Error-like object: {s}", .{@errorName(err)});
                        Output.flush();
                    }
                };
                return false;
            },
        }
    }

    pub fn printStackTrace(comptime Writer: type, writer: Writer, trace: ZigStackTrace, comptime allow_ansi_colors: bool) !void {
        const stack = trace.frames();
        if (stack.len > 0) {
            var i: i16 = 0;
            const origin: ?*const URL = if (vm.is_from_devserver) &vm.origin else null;
            const dir = vm.bundler.fs.top_level_dir;

            while (i < stack.len) : (i += 1) {
                const frame = stack[@intCast(usize, i)];
                const file = frame.source_url.slice();
                const func = frame.function_name.slice();
                if (file.len == 0 and func.len == 0) continue;

                const has_name = std.fmt.count("{any}", .{frame.nameFormatter(
                    false,
                )}) > 0;

                if (has_name) {
                    try writer.print(
                        comptime Output.prettyFmt(
                            "<r>      <d>at <r>{any}<d> (<r>{any}<d>)<r>\n",
                            allow_ansi_colors,
                        ),
                        .{
                            frame.nameFormatter(
                                allow_ansi_colors,
                            ),
                            frame.sourceURLFormatter(
                                dir,
                                origin,
                                allow_ansi_colors,
                            ),
                        },
                    );
                } else {
                    try writer.print(
                        comptime Output.prettyFmt(
                            "<r>      <d>at <r>{any}\n",
                            allow_ansi_colors,
                        ),
                        .{
                            frame.sourceURLFormatter(
                                dir,
                                origin,
                                allow_ansi_colors,
                            ),
                        },
                    );
                }
            }
        }
    }

    fn remapZigException(
        this: *VirtualMachine,
        exception: *ZigException,
        error_instance: JSValue,
        exception_list: ?*ExceptionList,
    ) !void {
        error_instance.toZigException(this.global, exception);
        if (exception_list) |list| {
            try exception.addToErrorList(list);
        }

        var frames: []JSC.ZigStackFrame = exception.stack.frames_ptr[0..exception.stack.frames_len];
        if (frames.len == 0) return;

        var top = &frames[0];
        if (this.source_mappings.resolveMapping(
            top.source_url.slice(),
            @maximum(top.position.line, 0),
            @maximum(top.position.column_stop, 0),
        )) |mapping| {
            var log = logger.Log.init(default_allocator);
            var original_source = _fetch(this.global, top.source_url.slice(), "", &log, true) catch return;
            const code = original_source.source_code.slice();
            top.position.line = mapping.original.lines;
            top.position.column_start = mapping.original.columns;
            top.position.expression_start = mapping.original.columns;
            if (strings.getLinesInText(
                code,
                @intCast(u32, top.position.line),
                JSC.ZigException.Holder.source_lines_count,
            )) |lines| {
                var source_lines = exception.stack.source_lines_ptr[0..JSC.ZigException.Holder.source_lines_count];
                var source_line_numbers = exception.stack.source_lines_numbers[0..JSC.ZigException.Holder.source_lines_count];
                std.mem.set(ZigString, source_lines, ZigString.Empty);
                std.mem.set(i32, source_line_numbers, 0);

                var lines_ = lines[0..@minimum(lines.len, source_lines.len)];
                for (lines_) |line, j| {
                    source_lines[(lines_.len - 1) - j] = ZigString.init(line);
                    source_line_numbers[j] = top.position.line - @intCast(i32, j) + 1;
                }

                exception.stack.source_lines_len = @intCast(u8, lines_.len);
            }
        }

        if (frames.len > 1) {
            for (frames[1..]) |*frame| {
                if (frame.position.isInvalid()) continue;
                if (this.source_mappings.resolveMapping(
                    frame.source_url.slice(),
                    @maximum(frame.position.line, 0),
                    @maximum(frame.position.column_start, 0),
                )) |mapping| {
                    frame.position.line = mapping.original.lines;
                    frame.position.column_start = mapping.original.columns;
                }
            }
        }
    }

    pub fn printErrorInstance(this: *VirtualMachine, error_instance: JSValue, exception_list: ?*ExceptionList, comptime Writer: type, writer: Writer, comptime allow_ansi_color: bool) !void {
        var exception_holder = ZigException.Holder.init();
        var exception = exception_holder.zigException();
        try this.remapZigException(exception, error_instance, exception_list);
        this.had_errors = true;

        var line_numbers = exception.stack.source_lines_numbers[0..exception.stack.source_lines_len];
        var max_line: i32 = -1;
        for (line_numbers) |line| max_line = @maximum(max_line, line);
        const max_line_number_pad = std.fmt.count("{d}", .{max_line});

        var source_lines = exception.stack.sourceLineIterator();
        var last_pad: u64 = 0;
        while (source_lines.untilLast()) |source| {
            const int_size = std.fmt.count("{d}", .{source.line});
            const pad = max_line_number_pad - int_size;
            last_pad = pad;
            writer.writeByteNTimes(' ', pad) catch unreachable;
            writer.print(
                comptime Output.prettyFmt("<r><d>{d} | <r>{s}\n", allow_ansi_color),
                .{
                    source.line,
                    std.mem.trim(u8, source.text, "\n"),
                },
            ) catch unreachable;
        }

        var name = exception.name;
        if (strings.eqlComptime(exception.name.slice(), "Error")) {
            name = ZigString.init("error");
        }

        const message = exception.message;
        var did_print_name = false;
        if (source_lines.next()) |source| {
            if (source.text.len > 0 and exception.stack.frames()[0].position.isInvalid()) {
                defer did_print_name = true;
                var text = std.mem.trim(u8, source.text, "\n");

                writer.print(
                    comptime Output.prettyFmt(
                        "<r><d>- |<r> {s}\n",
                        allow_ansi_color,
                    ),
                    .{
                        text,
                    },
                ) catch unreachable;

                if (name.len > 0 and message.len > 0) {
                    writer.print(comptime Output.prettyFmt(" <r><red>{}<r><d>:<r> <b>{}<r>\n", allow_ansi_color), .{
                        name,
                        message,
                    }) catch unreachable;
                } else if (name.len > 0) {
                    writer.print(comptime Output.prettyFmt(" <r><b>{}<r>\n", allow_ansi_color), .{name}) catch unreachable;
                } else if (message.len > 0) {
                    writer.print(comptime Output.prettyFmt(" <r><b>{}<r>\n", allow_ansi_color), .{message}) catch unreachable;
                }
            } else if (source.text.len > 0) {
                defer did_print_name = true;
                const int_size = std.fmt.count("{d}", .{source.line});
                const pad = max_line_number_pad - int_size;
                writer.writeByteNTimes(' ', pad) catch unreachable;
                const top = exception.stack.frames()[0];
                var remainder = std.mem.trim(u8, source.text, "\n");
                if (@intCast(usize, top.position.column_stop) > remainder.len) {
                    writer.print(
                        comptime Output.prettyFmt(
                            "<r><d>{d} |<r> {s}\n",
                            allow_ansi_color,
                        ),
                        .{ source.line, remainder },
                    ) catch unreachable;
                } else {
                    const prefix = remainder[0..@intCast(usize, top.position.column_start)];
                    const underline = remainder[@intCast(usize, top.position.column_start)..@intCast(usize, top.position.column_stop)];
                    const suffix = remainder[@intCast(usize, top.position.column_stop)..];

                    writer.print(
                        comptime Output.prettyFmt(
                            "<r><d>{d} |<r> {s}<red>{s}<r>{s}<r>\n<r>",
                            allow_ansi_color,
                        ),
                        .{
                            source.line,
                            prefix,
                            underline,
                            suffix,
                        },
                    ) catch unreachable;
                    var first_non_whitespace = @intCast(u32, top.position.column_start);
                    while (first_non_whitespace < source.text.len and source.text[first_non_whitespace] == ' ') {
                        first_non_whitespace += 1;
                    }
                    const indent = @intCast(usize, pad) + " | ".len + first_non_whitespace + 1;

                    writer.writeByteNTimes(' ', indent) catch unreachable;
                    writer.print(comptime Output.prettyFmt(
                        "<red><b>^<r>\n",
                        allow_ansi_color,
                    ), .{}) catch unreachable;
                }

                if (name.len > 0 and message.len > 0) {
                    writer.print(comptime Output.prettyFmt(" <r><red>{s}<r><d>:<r> <b>{s}<r>\n", allow_ansi_color), .{
                        name,
                        message,
                    }) catch unreachable;
                } else if (name.len > 0) {
                    writer.print(comptime Output.prettyFmt(" <r><b>{s}<r>\n", allow_ansi_color), .{name}) catch unreachable;
                } else if (message.len > 0) {
                    writer.print(comptime Output.prettyFmt(" <r><b>{s}<r>\n", allow_ansi_color), .{message}) catch unreachable;
                }
            }
        }

        if (!did_print_name) {
            if (name.len > 0 and message.len > 0) {
                writer.print(comptime Output.prettyFmt("<r><red>{s}<r><d>:<r> <b>{s}<r>\n", true), .{
                    name,
                    message,
                }) catch unreachable;
            } else if (name.len > 0) {
                writer.print(comptime Output.prettyFmt("<r>{s}<r>\n", true), .{name}) catch unreachable;
            } else if (message.len > 0) {
                writer.print(comptime Output.prettyFmt("<r>{s}<r>\n", true), .{name}) catch unreachable;
            }
        }

        var add_extra_line = false;

        const Show = struct {
            system_code: bool = false,
            syscall: bool = false,
            errno: bool = false,
            path: bool = false,
        };

        var show = Show{
            .system_code = exception.system_code.len > 0 and !strings.eql(exception.system_code.slice(), name.slice()),
            .syscall = exception.syscall.len > 0,
            .errno = exception.errno < 0,
            .path = exception.path.len > 0,
        };

        if (show.path) {
            if (show.syscall) {
                writer.writeAll("  ") catch unreachable;
            } else if (show.errno) {
                writer.writeAll(" ") catch unreachable;
            }
            writer.print(comptime Output.prettyFmt(" path<d>: <r><cyan>\"{s}\"<r>\n", allow_ansi_color), .{exception.path}) catch unreachable;
        }

        if (show.system_code) {
            if (show.syscall) {
                writer.writeAll("  ") catch unreachable;
            } else if (show.errno) {
                writer.writeAll(" ") catch unreachable;
            }
            writer.print(comptime Output.prettyFmt(" code<d>: <r><cyan>\"{s}\"<r>\n", allow_ansi_color), .{exception.system_code}) catch unreachable;
            add_extra_line = true;
        }

        if (show.syscall) {
            writer.print(comptime Output.prettyFmt("syscall<d>: <r><cyan>\"{s}\"<r>\n", allow_ansi_color), .{exception.syscall}) catch unreachable;
            add_extra_line = true;
        }

        if (show.errno) {
            if (show.syscall) {
                writer.writeAll("  ") catch unreachable;
            }
            writer.print(comptime Output.prettyFmt("errno<d>: <r><yellow>{d}<r>\n", allow_ansi_color), .{exception.errno}) catch unreachable;
            add_extra_line = true;
        }

        if (add_extra_line) writer.writeAll("\n") catch unreachable;

        try printStackTrace(@TypeOf(writer), writer, exception.stack, allow_ansi_color);
    }
};

const GetterFn = fn (
    this: anytype,
    ctx: js.JSContextRef,
    thisObject: js.JSValueRef,
    prop: js.JSStringRef,
    exception: js.ExceptionRef,
) js.JSValueRef;
const SetterFn = fn (
    this: anytype,
    ctx: js.JSContextRef,
    thisObject: js.JSValueRef,
    prop: js.JSStringRef,
    value: js.JSValueRef,
    exception: js.ExceptionRef,
) js.JSValueRef;

const JSProp = struct {
    get: ?GetterFn = null,
    set: ?SetterFn = null,
    ro: bool = false,
};

pub const EventListenerMixin = struct {
    threadlocal var event_listener_names_buf: [128]u8 = undefined;
    pub const List = std.ArrayList(js.JSObjectRef);
    pub const Map = std.AutoHashMap(EventListenerMixin.EventType, EventListenerMixin.List);

    pub const EventType = enum {
        fetch,
        err,

        const SizeMatcher = strings.ExactSizeMatcher(8);

        pub fn match(str: string) ?EventType {
            return switch (SizeMatcher.match(str)) {
                SizeMatcher.case("fetch") => EventType.fetch,
                SizeMatcher.case("error") => EventType.err,
                else => null,
            };
        }
    };

    pub fn emitFetchEvent(
        vm: *VirtualMachine,
        request_context: *http.RequestContext,
        comptime CtxType: type,
        ctx: *CtxType,
        comptime onError: fn (ctx: *CtxType, err: anyerror, value: JSValue, request_ctx: *http.RequestContext) anyerror!void,
    ) !void {
        if (comptime JSC.is_bindgen) unreachable;
        defer {
            if (request_context.has_called_done) request_context.arena.deinit();
        }
        var listeners = vm.event_listeners.get(EventType.fetch) orelse (return onError(ctx, error.NoListeners, JSValue.jsUndefined(), request_context) catch {});
        if (listeners.items.len == 0) return onError(ctx, error.NoListeners, JSValue.jsUndefined(), request_context) catch {};
        const FetchEventRejectionHandler = struct {
            pub fn onRejection(_ctx: *anyopaque, err: anyerror, fetch_event: *FetchEvent, value: JSValue) void {
                onError(
                    @intToPtr(*CtxType, @ptrToInt(_ctx)),
                    err,
                    value,
                    fetch_event.request_context,
                ) catch {};
            }
        };

        // Rely on JS finalizer
        var fetch_event = try vm.allocator.create(FetchEvent);

        fetch_event.* = FetchEvent{
            .request_context = request_context,
            .request = Request{ .request_context = request_context },
            .onPromiseRejectionCtx = @as(*anyopaque, ctx),
            .onPromiseRejectionHandler = FetchEventRejectionHandler.onRejection,
        };

        var fetch_args: [1]js.JSObjectRef = undefined;
        for (listeners.items) |listener_ref| {
            fetch_args[0] = FetchEvent.Class.make(vm.global.ref(), fetch_event);

            var result = js.JSObjectCallAsFunctionReturnValue(vm.global.ref(), listener_ref, null, 1, &fetch_args);
            var promise = JSPromise.resolvedPromise(vm.global, result);
            vm.waitForTasks();

            if (fetch_event.rejected) return;

            if (promise.status(vm.global.vm()) == .Rejected) {
                onError(ctx, error.JSError, promise.result(vm.global.vm()), fetch_event.request_context) catch {};
                return;
            } else {
                _ = promise.result(vm.global.vm());
            }

            vm.waitForTasks();

            if (fetch_event.request_context.has_called_done) {
                break;
            }
        }

        if (!fetch_event.request_context.has_called_done) {
            onError(ctx, error.FetchHandlerRespondWithNeverCalled, JSValue.jsUndefined(), fetch_event.request_context) catch {};
            return;
        }
    }

    pub fn addEventListener(
        comptime Struct: type,
    ) type {
        const Handler = struct {
            pub fn addListener(
                ctx: js.JSContextRef,
                _: js.JSObjectRef,
                _: js.JSObjectRef,
                argumentCount: usize,
                _arguments: [*c]const js.JSValueRef,
                _: js.ExceptionRef,
            ) callconv(.C) js.JSValueRef {
                const arguments = _arguments[0..argumentCount];
                if (arguments.len == 0 or arguments.len == 1 or !js.JSValueIsString(ctx, arguments[0]) or !js.JSValueIsObject(ctx, arguments[arguments.len - 1]) or !js.JSObjectIsFunction(ctx, arguments[arguments.len - 1])) {
                    return js.JSValueMakeUndefined(ctx);
                }

                const name_len = js.JSStringGetLength(arguments[0]);
                if (name_len > event_listener_names_buf.len) {
                    return js.JSValueMakeUndefined(ctx);
                }

                const name_used_len = js.JSStringGetUTF8CString(arguments[0], &event_listener_names_buf, event_listener_names_buf.len);
                const name = event_listener_names_buf[0 .. name_used_len - 1];
                const event = EventType.match(name) orelse return js.JSValueMakeUndefined(ctx);
                var entry = VirtualMachine.vm.event_listeners.getOrPut(event) catch unreachable;

                if (!entry.found_existing) {
                    entry.value_ptr.* = List.initCapacity(VirtualMachine.vm.allocator, 1) catch unreachable;
                }

                var callback = arguments[arguments.len - 1];
                js.JSValueProtect(ctx, callback);
                entry.value_ptr.append(callback) catch unreachable;

                return js.JSValueMakeUndefined(ctx);
            }
        };

        return NewClass(
            Struct,
            .{
                .name = "addEventListener",
                .read_only = true,
            },
            .{
                .@"callAsFunction" = .{
                    .rfn = Handler.addListener,
                    .ts = d.ts{},
                },
            },
            .{},
        );
    }
};

pub const ResolveError = struct {
    msg: logger.Msg,
    allocator: std.mem.Allocator,
    referrer: ?Fs.Path = null,
    logged: bool = false,

    pub fn fmt(allocator: std.mem.Allocator, specifier: string, referrer: string, err: anyerror) !string {
        switch (err) {
            error.ModuleNotFound => {
                if (Resolver.isPackagePath(specifier)) {
                    return try std.fmt.allocPrint(allocator, "Cannot find package \"{s}\" from \"{s}\"", .{ specifier, referrer });
                } else {
                    return try std.fmt.allocPrint(allocator, "Cannot find module \"{s}\" from \"{s}\"", .{ specifier, referrer });
                }
            },
            else => {
                if (Resolver.isPackagePath(specifier)) {
                    return try std.fmt.allocPrint(allocator, "{s} while resolving package \"{s}\" from \"{s}\"", .{ @errorName(err), specifier, referrer });
                } else {
                    return try std.fmt.allocPrint(allocator, "{s} while resolving \"{s}\" from \"{s}\"", .{ @errorName(err), specifier, referrer });
                }
            },
        }
    }

    pub fn toStringFn(this: *ResolveError, ctx: js.JSContextRef) js.JSValueRef {
        var text = std.fmt.allocPrint(default_allocator, "ResolveError: {s}", .{this.msg.data.text}) catch return null;
        var str = ZigString.init(text);
        str.setOutputEncoding();
        if (str.isUTF8()) {
            const out = str.toValueGC(ctx.ptr());
            default_allocator.free(text);
            return out.asObjectRef();
        }

        return str.toExternalValue(ctx.ptr()).asObjectRef();
    }

    pub fn toString(
        // this
        this: *ResolveError,
        ctx: js.JSContextRef,
        // function
        _: js.JSObjectRef,
        // thisObject
        _: js.JSObjectRef,
        _: []const js.JSValueRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        return this.toStringFn(ctx);
    }

    pub fn convertToType(ctx: js.JSContextRef, obj: js.JSObjectRef, kind: js.JSType, _: js.ExceptionRef) callconv(.C) js.JSValueRef {
        switch (kind) {
            js.JSType.kJSTypeString => {
                if (js.JSObjectGetPrivate(obj)) |priv| {
                    if (JSPrivateDataPtr.from(priv).is(ResolveError)) {
                        var this = JSPrivateDataPtr.from(priv).as(ResolveError);
                        return this.toStringFn(ctx);
                    }
                }
            },
            else => {},
        }

        return obj;
    }

    pub const Class = NewClass(
        ResolveError,
        .{
            .name = "ResolveError",
            .read_only = true,
        },
        .{
            .toString = .{ .rfn = toString },
            .convertToType = .{ .rfn = convertToType },
        },
        .{
            .@"referrer" = .{
                .@"get" = getReferrer,
                .ro = true,
                .ts = d.ts{ .@"return" = "string" },
            },
            .@"message" = .{
                .@"get" = getMessage,
                .ro = true,
                .ts = d.ts{ .@"return" = "string" },
            },
            .@"name" = .{
                .@"get" = getName,
                .ro = true,
                .ts = d.ts{ .@"return" = "string" },
            },
            .@"specifier" = .{
                .@"get" = getSpecifier,
                .ro = true,
                .ts = d.ts{ .@"return" = "string" },
            },
            .@"importKind" = .{
                .@"get" = getImportKind,
                .ro = true,
                .ts = d.ts{ .@"return" = "string" },
            },
            .@"position" = .{
                .@"get" = getPosition,
                .ro = true,
                .ts = d.ts{ .@"return" = "string" },
            },
        },
    );

    pub fn create(
        globalThis: *JSGlobalObject,
        allocator: std.mem.Allocator,
        msg: logger.Msg,
        referrer: string,
    ) js.JSObjectRef {
        var resolve_error = allocator.create(ResolveError) catch unreachable;
        resolve_error.* = ResolveError{
            .msg = msg,
            .allocator = allocator,
            .referrer = Fs.Path.init(referrer),
        };
        var ref = Class.make(globalThis.ref(), resolve_error);
        js.JSValueProtect(globalThis.ref(), ref);
        return ref;
    }

    pub fn getPosition(
        this: *ResolveError,
        ctx: js.JSContextRef,
        _: js.JSObjectRef,
        _: js.JSStringRef,
        exception: js.ExceptionRef,
    ) js.JSValueRef {
        return BuildError.generatePositionObject(this.msg, ctx, exception);
    }

    pub fn getMessage(
        this: *ResolveError,
        ctx: js.JSContextRef,
        _: js.JSObjectRef,
        _: js.JSStringRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        return ZigString.init(this.msg.data.text).toValue(ctx.ptr()).asRef();
    }

    pub fn getSpecifier(
        this: *ResolveError,
        ctx: js.JSContextRef,
        _: js.JSObjectRef,
        _: js.JSStringRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        return ZigString.init(this.msg.metadata.resolve.specifier.slice(this.msg.data.text)).toValue(ctx.ptr()).asRef();
    }

    pub fn getImportKind(
        this: *ResolveError,
        ctx: js.JSContextRef,
        _: js.JSObjectRef,
        _: js.JSStringRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        return ZigString.init(@tagName(this.msg.metadata.resolve.import_kind)).toValue(ctx.ptr()).asRef();
    }

    pub fn getReferrer(
        this: *ResolveError,
        ctx: js.JSContextRef,
        _: js.JSObjectRef,
        _: js.JSStringRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        if (this.referrer) |referrer| {
            return ZigString.init(referrer.text).toValue(ctx.ptr()).asRef();
        } else {
            return js.JSValueMakeNull(ctx);
        }
    }

    const BuildErrorName = "ResolveError";
    pub fn getName(
        _: *ResolveError,
        ctx: js.JSContextRef,
        _: js.JSObjectRef,
        _: js.JSStringRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        return ZigString.init(BuildErrorName).toValue(ctx.ptr()).asRef();
    }
};

pub const BuildError = struct {
    msg: logger.Msg,
    // resolve_result: Resolver.Result,
    allocator: std.mem.Allocator,
    logged: bool = false,

    pub const Class = NewClass(
        BuildError,
        .{ .name = "BuildError", .read_only = true, .ts = .{
            .class = .{
                .name = "BuildError",
            },
        } },
        .{
            .convertToType = .{ .rfn = convertToType },
            .toString = .{ .rfn = toString },
        },
        .{
            .@"message" = .{
                .@"get" = getMessage,
                .ro = true,
            },
            .@"name" = .{
                .@"get" = getName,
                .ro = true,
            },
            // This is called "position" instead of "location" because "location" may be confused with Location.
            .@"position" = .{
                .@"get" = getPosition,
                .ro = true,
            },
        },
    );

    pub fn toStringFn(this: *BuildError, ctx: js.JSContextRef) js.JSValueRef {
        var text = std.fmt.allocPrint(default_allocator, "BuildError: {s}", .{this.msg.data.text}) catch return null;
        var str = ZigString.init(text);
        str.setOutputEncoding();
        if (str.isUTF8()) {
            const out = str.toValueGC(ctx.ptr());
            default_allocator.free(text);
            return out.asObjectRef();
        }

        return str.toExternalValue(ctx.ptr()).asObjectRef();
    }

    pub fn toString(
        // this
        this: *BuildError,
        ctx: js.JSContextRef,
        // function
        _: js.JSObjectRef,
        // thisObject
        _: js.JSObjectRef,
        _: []const js.JSValueRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        return this.toStringFn(ctx);
    }

    pub fn convertToType(ctx: js.JSContextRef, obj: js.JSObjectRef, kind: js.JSType, _: js.ExceptionRef) callconv(.C) js.JSValueRef {
        switch (kind) {
            js.JSType.kJSTypeString => {
                if (js.JSObjectGetPrivate(obj)) |priv| {
                    if (JSPrivateDataPtr.from(priv).is(BuildError)) {
                        var this = JSPrivateDataPtr.from(priv).as(BuildError);
                        return this.toStringFn(ctx);
                    }
                }
            },
            else => {},
        }

        return obj;
    }

    pub fn create(
        globalThis: *JSGlobalObject,
        allocator: std.mem.Allocator,
        msg: logger.Msg,
        // resolve_result: *const Resolver.Result,
    ) js.JSObjectRef {
        var build_error = allocator.create(BuildError) catch unreachable;
        build_error.* = BuildError{
            .msg = msg,
            // .resolve_result = resolve_result.*,
            .allocator = allocator,
        };

        var ref = Class.make(globalThis.ref(), build_error);
        js.JSValueProtect(globalThis.ref(), ref);
        return ref;
    }

    pub fn getPosition(
        this: *BuildError,
        ctx: js.JSContextRef,
        _: js.JSObjectRef,
        _: js.JSStringRef,
        exception: js.ExceptionRef,
    ) js.JSValueRef {
        return generatePositionObject(this.msg, ctx, exception);
    }

    pub const PositionProperties = struct {
        const _file = ZigString.init("file");
        var file_ptr: js.JSStringRef = null;
        pub fn file() js.JSStringRef {
            if (file_ptr == null) {
                file_ptr = _file.toJSStringRef();
            }
            return file_ptr.?;
        }
        const _namespace = ZigString.init("namespace");
        var namespace_ptr: js.JSStringRef = null;
        pub fn namespace() js.JSStringRef {
            if (namespace_ptr == null) {
                namespace_ptr = _namespace.toJSStringRef();
            }
            return namespace_ptr.?;
        }
        const _line = ZigString.init("line");
        var line_ptr: js.JSStringRef = null;
        pub fn line() js.JSStringRef {
            if (line_ptr == null) {
                line_ptr = _line.toJSStringRef();
            }
            return line_ptr.?;
        }
        const _column = ZigString.init("column");
        var column_ptr: js.JSStringRef = null;
        pub fn column() js.JSStringRef {
            if (column_ptr == null) {
                column_ptr = _column.toJSStringRef();
            }
            return column_ptr.?;
        }
        const _length = ZigString.init("length");
        var length_ptr: js.JSStringRef = null;
        pub fn length() js.JSStringRef {
            if (length_ptr == null) {
                length_ptr = _length.toJSStringRef();
            }
            return length_ptr.?;
        }
        const _lineText = ZigString.init("lineText");
        var lineText_ptr: js.JSStringRef = null;
        pub fn lineText() js.JSStringRef {
            if (lineText_ptr == null) {
                lineText_ptr = _lineText.toJSStringRef();
            }
            return lineText_ptr.?;
        }
        const _offset = ZigString.init("offset");
        var offset_ptr: js.JSStringRef = null;
        pub fn offset() js.JSStringRef {
            if (offset_ptr == null) {
                offset_ptr = _offset.toJSStringRef();
            }
            return offset_ptr.?;
        }
    };

    pub fn generatePositionObject(msg: logger.Msg, ctx: js.JSContextRef, exception: ExceptionValueRef) js.JSValueRef {
        if (msg.data.location) |location| {
            const ref = js.JSObjectMake(ctx, null, null);
            js.JSObjectSetProperty(
                ctx,
                ref,
                PositionProperties.lineText(),
                ZigString.init(location.line_text orelse "").toJSStringRef(),
                0,
                exception,
            );
            js.JSObjectSetProperty(
                ctx,
                ref,
                PositionProperties.file(),
                ZigString.init(location.file).toJSStringRef(),
                0,
                exception,
            );
            js.JSObjectSetProperty(
                ctx,
                ref,
                PositionProperties.namespace(),
                ZigString.init(location.namespace).toJSStringRef(),
                0,
                exception,
            );
            js.JSObjectSetProperty(
                ctx,
                ref,
                PositionProperties.line(),
                js.JSValueMakeNumber(ctx, @intToFloat(f64, location.line)),
                0,
                exception,
            );
            js.JSObjectSetProperty(
                ctx,
                ref,
                PositionProperties.column(),
                js.JSValueMakeNumber(ctx, @intToFloat(f64, location.column)),
                0,
                exception,
            );
            js.JSObjectSetProperty(
                ctx,
                ref,
                PositionProperties.length(),
                js.JSValueMakeNumber(ctx, @intToFloat(f64, location.length)),
                0,
                exception,
            );
            js.JSObjectSetProperty(
                ctx,
                ref,
                PositionProperties.offset(),
                js.JSValueMakeNumber(ctx, @intToFloat(f64, location.offset)),
                0,
                exception,
            );
            return ref;
        }

        return js.JSValueMakeNull(ctx);
    }

    pub fn getMessage(
        this: *BuildError,
        ctx: js.JSContextRef,
        _: js.JSObjectRef,
        _: js.JSStringRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        return ZigString.init(this.msg.data.text).toValue(ctx.ptr()).asRef();
    }

    const BuildErrorName = "BuildError";
    pub fn getName(
        _: *BuildError,
        ctx: js.JSContextRef,
        _: js.JSObjectRef,
        _: js.JSStringRef,
        _: js.ExceptionRef,
    ) js.JSValueRef {
        return ZigString.init(BuildErrorName).toValue(ctx.ptr()).asRef();
    }
};

pub const JSPrivateDataTag = JSPrivateDataPtr.Tag;
