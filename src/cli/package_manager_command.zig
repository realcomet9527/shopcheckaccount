const Command = @import("../cli.zig").Command;
const PackageManager = @import("../install/install.zig").PackageManager;
const ComamndLineArguments = PackageManager.CommandLineArguments;
const std = @import("std");
const strings = @import("strings");
const Global = @import("../global.zig").Global;
const Output = @import("../global.zig").Output;
const Fs = @import("../fs.zig");
const Path = @import("../resolver/resolve_path.zig");

pub const PackageManagerCommand = struct {
    pub fn printHelp(_: std.mem.Allocator) void {}
    pub fn printHash(ctx: Command.Context, lockfile_: []const u8) !void {
        @setCold(true);
        var lockfile_buffer: [std.fs.MAX_PATH_BYTES]u8 = undefined;
        @memcpy(&lockfile_buffer, lockfile_.ptr, lockfile_.len);
        lockfile_buffer[lockfile_.len] = 0;
        var lockfile = lockfile_buffer[0..lockfile_.len :0];
        var pm = try PackageManager.init(ctx, null, &PackageManager.install_params);

        const load_lockfile = pm.lockfile.loadFromDisk(ctx.allocator, ctx.log, lockfile);
        if (load_lockfile == .not_found) {
            if (pm.options.log_level != .silent)
                Output.prettyError("Lockfile not found", .{});
            Global.exit(1);
        }

        if (load_lockfile == .err) {
            if (pm.options.log_level != .silent)
                Output.prettyError("Error loading lockfile: {s}", .{@errorName(load_lockfile.err.value)});
            Global.exit(1);
        }

        Output.flush();
        Output.disableBuffering();
        try Output.writer().print("{}", .{load_lockfile.ok.fmtMetaHash()});
        Output.enableBuffering();
        Global.exit(0);
    }

    pub fn exec(ctx: Command.Context) !void {
        var args = try std.process.argsAlloc(ctx.allocator);
        args = args[1..];

        var pm = try PackageManager.init(ctx, null, &PackageManager.install_params);

        var first: []const u8 = if (pm.options.positionals.len > 0) pm.options.positionals[0] else "";
        if (strings.eqlComptime(first, "pm")) {
            if (pm.options.positionals.len > 1) {
                pm.options.positionals = pm.options.positionals[1..];
            } else {
                return;
            }
        }

        first = pm.options.positionals[0];

        if (pm.options.global) {
            try pm.setupGlobalDir(&ctx);
        }

        if (strings.eqlComptime(first, "bin")) {
            var output_path = Path.joinAbs(Fs.FileSystem.instance.top_level_dir, .auto, std.mem.span(pm.options.bin_path));
            Output.prettyln("{s}", .{output_path});
            if (Output.stdout_descriptor_type == .terminal) {
                Output.prettyln("\n", .{});
            }

            if (pm.options.global) {
                warner: {
                    if (Output.enable_ansi_colors_stderr) {
                        if (std.os.getenvZ("PATH")) |path| {
                            var path_splitter = std.mem.split(u8, path, ":");
                            while (path_splitter.next()) |entry| {
                                if (strings.eql(entry, output_path)) {
                                    break :warner;
                                }
                            }

                            Output.prettyErrorln("\n<r><yellow>warn<r>: not in $PATH\n", .{});
                        }
                    }
                }
            }

            Output.flush();
            return;
        } else if (strings.eqlComptime(first, "hash")) {
            const load_lockfile = pm.lockfile.loadFromDisk(ctx.allocator, ctx.log, "bun.lockb");
            if (load_lockfile == .not_found) {
                if (pm.options.log_level != .silent)
                    Output.prettyError("Lockfile not found", .{});
                Global.exit(1);
            }

            if (load_lockfile == .err) {
                if (pm.options.log_level != .silent)
                    Output.prettyError("Error loading lockfile: {s}", .{@errorName(load_lockfile.err.value)});
                Global.exit(1);
            }

            _ = try pm.lockfile.hasMetaHashChanged(false);

            Output.flush();
            Output.disableBuffering();
            try Output.writer().print("{}", .{load_lockfile.ok.fmtMetaHash()});
            Output.enableBuffering();
            Global.exit(0);
        } else if (strings.eqlComptime(first, "hash-print")) {
            const load_lockfile = pm.lockfile.loadFromDisk(ctx.allocator, ctx.log, "bun.lockb");
            if (load_lockfile == .not_found) {
                if (pm.options.log_level != .silent)
                    Output.prettyError("Lockfile not found", .{});
                Global.exit(1);
            }

            if (load_lockfile == .err) {
                if (pm.options.log_level != .silent)
                    Output.prettyError("Error loading lockfile: {s}", .{@errorName(load_lockfile.err.value)});
                Global.exit(1);
            }

            Output.flush();
            Output.disableBuffering();
            try Output.writer().print("{}", .{load_lockfile.ok.fmtMetaHash()});
            Output.enableBuffering();
            Global.exit(0);
        } else if (strings.eqlComptime(first, "hash-string")) {
            const load_lockfile = pm.lockfile.loadFromDisk(ctx.allocator, ctx.log, "bun.lockb");
            if (load_lockfile == .not_found) {
                if (pm.options.log_level != .silent)
                    Output.prettyError("Lockfile not found", .{});
                Global.exit(1);
            }

            if (load_lockfile == .err) {
                if (pm.options.log_level != .silent)
                    Output.prettyError("Error loading lockfile: {s}", .{@errorName(load_lockfile.err.value)});
                Global.exit(1);
            }

            _ = try pm.lockfile.hasMetaHashChanged(true);
            Global.exit(0);
        }
    }
};
