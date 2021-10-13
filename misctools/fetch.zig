const std = @import("std");
usingnamespace @import("../src/global.zig");
const clap = @import("../src/deps/zig-clap/clap.zig");

const HTTPClient = @import("../src/http_client.zig");
const URL = @import("../src/query_string_map.zig").URL;
const Headers = @import("../src/javascript/jsc/webcore/response.zig").Headers;
const Method = @import("../src/http/method.zig").Method;
const ColonListType = @import("../src/cli/colon_list_type.zig").ColonListType;
const HeadersTuple = ColonListType(string, noop_resolver);
const path_handler = @import("../src/resolver/resolve_path.zig");

fn noop_resolver(in: string) !string {
    return in;
}

const VERSION = "0.0.0";

const params = [_]clap.Param(clap.Help){
    clap.parseParam("-v, --verbose              Show headers & status code") catch unreachable,
    clap.parseParam("-H, --header <STR>...      Add a header") catch unreachable,
    clap.parseParam("-r, --max-redirects <STR>  Maximum number of redirects to follow (default: 128)") catch unreachable,
    clap.parseParam("-b, --body <STR>           HTTP request body as a string") catch unreachable,
    clap.parseParam("-f, --file <STR>           File path to load as body") catch unreachable,
    clap.parseParam("--no-gzip                  Disable gzip") catch unreachable,
    clap.parseParam("--no-deflate               Disable deflate") catch unreachable,
    clap.parseParam("--no-compression           Disable gzip & deflate") catch unreachable,
    clap.parseParam("--version                  Print the version and exit") catch unreachable,
    clap.parseParam("<POS>...                          ") catch unreachable,
};

const MethodNames = std.ComptimeStringMap(Method, .{
    .{ "GET", Method.GET },
    .{ "get", Method.GET },

    .{ "POST", Method.POST },
    .{ "post", Method.POST },

    .{ "PUT", Method.PUT },
    .{ "put", Method.PUT },

    .{ "PATCH", Method.PATCH },
    .{ "patch", Method.PATCH },

    .{ "OPTIONS", Method.OPTIONS },
    .{ "options", Method.OPTIONS },

    .{ "HEAD", Method.HEAD },
    .{ "head", Method.HEAD },
});

var file_path_buf: [std.fs.MAX_PATH_BYTES + 1]u8 = undefined;
var cwd_buf: [std.fs.MAX_PATH_BYTES + 1]u8 = undefined;

pub const Arguments = struct {
    url: URL,
    method: Method,
    verbose: bool = false,
    headers: Headers.Entries,
    headers_buf: string,
    body: string = "",

    pub fn parse(allocator: *std.mem.Allocator) !Arguments {
        var diag = clap.Diagnostic{};

        var args = clap.parse(clap.Help, &params, .{
            .diagnostic = &diag,
            .allocator = allocator,
        }) catch |err| {
            // Report useful error and exit
            diag.report(Output.errorWriter(), err) catch {};
            return err;
        };

        var positionals = args.positionals();
        var raw_args: std.ArrayListUnmanaged(string) = undefined;

        if (positionals.len > 0) {
            raw_args = .{ .capacity = positionals.len, .items = @intToPtr([*][]const u8, @ptrToInt(positionals.ptr))[0..positionals.len] };
        } else {
            raw_args = .{};
        }

        if (args.flag("--version")) {
            try Output.writer().writeAll(VERSION);
            std.os.exit(0);
        }

        var method = Method.GET;
        var url: URL = .{};
        var body_string: string = args.option("--body") orelse "";

        if (args.option("--file")) |file_path| {
            if (file_path.len > 0) {
                var cwd = try std.process.getCwd(&cwd_buf);
                var parts = [_]string{std.mem.span(file_path)};
                var absolute_path = path_handler.joinAbsStringBuf(cwd, &file_path_buf, &parts, .auto);
                file_path_buf[absolute_path.len] = 0;
                file_path_buf[absolute_path.len + 1] = 0;
                var absolute_path_len = absolute_path.len;
                var absolute_path_ = file_path_buf[0..absolute_path_len :0];

                var body_file = std.fs.openFileAbsoluteZ(absolute_path_, .{ .read = true }) catch |err| {
                    Output.printErrorln("<r><red>{s}<r> opening file {s}", .{ @errorName(err), absolute_path });
                    Output.flush();
                    std.os.exit(1);
                };

                var file_contents = body_file.readToEndAlloc(allocator, try body_file.getEndPos()) catch |err| {
                    Output.printErrorln("<r><red>{s}<r> reading file {s}", .{ @errorName(err), absolute_path });
                    Output.flush();
                    std.os.exit(1);
                };
                body_string = file_contents;
            }
        }

        {
            var raw_arg_i: usize = 0;
            while (raw_arg_i < raw_args.items.len) : (raw_arg_i += 1) {
                const arg = raw_args.items[raw_arg_i];
                if (MethodNames.get(std.mem.span(arg))) |method_| {
                    method = method_;
                    _ = raw_args.swapRemove(raw_arg_i);
                }
            }

            if (raw_args.items.len == 0) {
                Output.prettyErrorln("<r><red>error<r><d>:<r> <b>Missing URL<r>\n\nExample:\n<r><b>fetch GET https://example.com<r>\n\n<b>fetch example.com/foo<r>\n\n", .{});
                Output.flush();
                std.os.exit(1);
            }

            const url_position = raw_args.items.len - 1;
            url = URL.parse(raw_args.swapRemove(url_position));
            if (!url.isAbsolute()) {
                Output.prettyErrorln("<r><red>error<r><d>:<r> <b>Invalid URL<r>\n\nExample:\n<r><b>fetch GET https://example.com<r>\n\n<b>fetch example.com/foo<r>\n\n", .{});
                Output.flush();
                std.os.exit(1);
            }
        }

        return Arguments{
            .url = url,
            .method = method,
            .verbose = args.flag("--verbose"),
            .headers = .{},
            .headers_buf = "",
            .body = body_string,
        };
    }
};

pub fn main() anyerror!void {
    var stdout_ = std.io.getStdOut();
    var stderr_ = std.io.getStdErr();
    var output_source = Output.Source.init(stdout_, stderr_);
    Output.Source.set(&output_source);
    defer Output.flush();

    var args = try Arguments.parse(default_allocator);
    var client = HTTPClient.init(default_allocator, args.method, args.url, args.headers, args.headers_buf);
    client.verbose = args.verbose;
    client.disable_shutdown = true;
    var body_out_str = try MutableString.init(default_allocator, 1024);
    var response = try client.send(args.body, &body_out_str);

    Output.flush();
    Output.disableBuffering();
    try Output.writer().writeAll(body_out_str.list.items);
    Output.enableBuffering();
    switch (response.status_code) {
        200, 302 => {},
        else => {
            if (!client.verbose) {
                // Output.flush();

                // Output.prettyErrorln("Response: {}", .{response});
            }
        },
    }
}
