const std = @import("std");
usingnamespace @import("global.zig");
const sync = @import("sync.zig");
const alloc = @import("alloc.zig");
const expect = std.testing.expect;
const Mutex = sync.Mutex;
const Semaphore = sync.Semaphore;

const path_handler = @import("./resolver/resolve_path.zig");

const allocators = @import("./allocators.zig");
const hash_map = @import("hash_map.zig");

// pub const FilesystemImplementation = @import("fs_impl.zig");

threadlocal var scratch_lookup_buffer: [256]u8 = undefined;

pub const Preallocate = struct {
    pub const Counts = struct {
        pub const dir_entry: usize = 512;
        pub const files: usize = 1024;
    };
};

pub const FileSystem = struct {
    allocator: *std.mem.Allocator,
    top_level_dir: string = "/",
    fs: Implementation,

    dirname_store: *DirnameStore,
    filename_store: *FilenameStore,

    _tmpdir: ?std.fs.Dir = null,

    pub fn tmpdir(fs: *FileSystem) std.fs.Dir {
        if (fs._tmpdir == null) {
            fs._tmpdir = fs.fs.openTmpDir() catch unreachable;
        }

        return fs._tmpdir.?;
    }

    var tmpname_buf: [64]u8 = undefined;
    pub fn tmpname(fs: *const FileSystem, extname: string) !string {
        const int = std.crypto.random.int(u64);
        return try std.fmt.bufPrint(&tmpname_buf, "{x}{s}", .{ int, extname });
    }

    pub var max_fd: FileDescriptorType = 0;

    pub inline fn setMaxFd(fd: anytype) void {
        if (!FeatureFlags.store_file_descriptors) {
            return;
        }

        max_fd = std.math.max(fd, max_fd);
    }

    pub var instance: FileSystem = undefined;

    pub const DirnameStore = allocators.BSSStringList(Preallocate.Counts.dir_entry, 128);
    pub const FilenameStore = allocators.BSSStringList(Preallocate.Counts.files, 64);

    pub const Error = error{
        ENOENT,
        EACCESS,
        INVALID_NAME,
        ENOTDIR,
    };

    pub fn init1(
        allocator: *std.mem.Allocator,
        top_level_dir: ?string,
    ) !*FileSystem {
        var _top_level_dir = top_level_dir orelse (if (isBrowser) "/project/" else try std.process.getCwdAlloc(allocator));

        // Ensure there's a trailing separator in the top level directory
        // This makes path resolution more reliable
        if (!std.fs.path.isSep(_top_level_dir[_top_level_dir.len - 1])) {
            const tld = try allocator.alloc(u8, _top_level_dir.len + 1);
            std.mem.copy(u8, tld, _top_level_dir);
            tld[tld.len - 1] = std.fs.path.sep;
            if (!isBrowser) {
                allocator.free(_top_level_dir);
            }
            _top_level_dir = tld;
        }

        instance = FileSystem{
            .allocator = allocator,
            .top_level_dir = _top_level_dir,
            .fs = Implementation.init(
                allocator,
                _top_level_dir,
            ),
            // .stats = std.StringHashMap(Stat).init(allocator),
            .dirname_store = DirnameStore.init(allocator),
            .filename_store = FilenameStore.init(allocator),
        };

        instance.fs.parent_fs = &instance;
        _ = DirEntry.EntryStore.init(allocator);
        return &instance;
    }

    pub const DirEntry = struct {
        pub const EntryMap = hash_map.StringHashMap(allocators.IndexType);
        pub const EntryStore = allocators.BSSList(Entry, Preallocate.Counts.files);
        dir: string,
        fd: StoredFileDescriptorType = 0,
        data: EntryMap,

        pub fn addEntry(dir: *DirEntry, entry: std.fs.Dir.Entry) !void {
            var _kind: Entry.Kind = undefined;
            switch (entry.kind) {
                .Directory => {
                    _kind = Entry.Kind.dir;
                },
                .SymLink => {
                    // This might be wrong!
                    _kind = Entry.Kind.file;
                },
                .File => {
                    _kind = Entry.Kind.file;
                },
                else => {
                    return;
                },
            }
            // entry.name only lives for the duration of the iteration

            var name: []u8 = undefined;

            switch (_kind) {
                .file => {
                    name = FileSystem.FilenameStore.editableSlice(try FileSystem.FilenameStore.instance.append(@TypeOf(entry.name), entry.name));
                },
                .dir => {
                    // FileSystem.FilenameStore here because it's not an absolute path
                    // it's a path relative to the parent directory
                    // so it's a tiny path like "foo" instead of "/bar/baz/foo"
                    name = FileSystem.FilenameStore.editableSlice(try FileSystem.FilenameStore.instance.append(@TypeOf(entry.name), entry.name));
                },
            }

            for (entry.name) |c, i| {
                name[i] = std.ascii.toLower(c);
            }

            var symlink: []u8 = "";

            if (entry.kind == std.fs.Dir.Entry.Kind.SymLink) {
                symlink = name;
            }
            const index = try EntryStore.instance.append(Entry{
                .base = name,
                .dir = dir.dir,
                .mutex = Mutex.init(),
                // Call "stat" lazily for performance. The "@material-ui/icons" package
                // contains a directory with over 11,000 entries in it and running "stat"
                // for each entry was a big performance issue for that package.
                .need_stat = entry.kind == .SymLink,
                .cache = Entry.Cache{
                    .symlink = symlink,
                    .kind = _kind,
                },
            });

            try dir.data.put(name, index);
        }

        pub fn updateDir(i: *DirEntry, dir: string) void {
            var iter = i.data.iterator();
            i.dir = dir;
            while (iter.next()) |entry| {
                entry.value_ptr.dir = dir;
            }
        }

        pub fn empty(dir: string, allocator: *std.mem.Allocator) DirEntry {
            return DirEntry{ .dir = dir, .data = EntryMap.init(allocator) };
        }

        pub fn init(dir: string, allocator: *std.mem.Allocator) DirEntry {
            return DirEntry{ .dir = dir, .data = EntryMap.init(allocator) };
        }

        pub const Err = struct {
            original_err: anyerror,
            canonical_error: anyerror,
        };

        pub fn deinit(d: *DirEntry) void {
            d.data.allocator.free(d.dir);

            var iter = d.data.iterator();
            while (iter.next()) |file_entry| {
                EntryStore.instance.at(file_entry.value).?.deinit(d.data.allocator);
            }

            d.data.deinit();
        }

        pub fn get(entry: *const DirEntry, _query: string) ?Entry.Lookup {
            if (_query.len == 0) return null;

            var end: usize = 0;
            std.debug.assert(scratch_lookup_buffer.len >= _query.len);
            for (_query) |c, i| {
                scratch_lookup_buffer[i] = std.ascii.toLower(c);
                end = i;
            }
            const query = scratch_lookup_buffer[0 .. end + 1];
            const result_index = entry.data.get(query) orelse return null;
            const result = EntryStore.instance.at(result_index) orelse return null;
            if (!strings.eql(result.base, query)) {
                return Entry.Lookup{ .entry = result, .diff_case = Entry.Lookup.DifferentCase{
                    .dir = entry.dir,
                    .query = _query,
                    .actual = result.base,
                } };
            }

            return Entry.Lookup{ .entry = result, .diff_case = null };
        }

        pub fn getComptimeQuery(entry: *const DirEntry, comptime query_str: anytype) ?Entry.Lookup {
            comptime var query: [query_str.len]u8 = undefined;
            comptime for (query_str) |c, i| {
                query[i] = std.ascii.toLower(c);
            };

            const query_hashed = DirEntry.EntryMap.getHash(&query);

            const result_index = entry.data.getWithHash(&query, query_hashed) orelse return null;
            const result = EntryStore.instance.at(result_index) orelse return null;
            if (!strings.eql(result.base, query)) {
                return Entry.Lookup{ .entry = result, .diff_case = Entry.Lookup.DifferentCase{
                    .dir = entry.dir,
                    .query = &query,
                    .actual = result.base,
                } };
            }

            return Entry.Lookup{ .entry = result, .diff_case = null };
        }
    };

    pub const Entry = struct {
        cache: Cache = Cache{},
        dir: string,
        base: string,
        mutex: Mutex,
        need_stat: bool = true,

        pub const Lookup = struct {
            entry: *Entry,
            diff_case: ?DifferentCase,

            pub const DifferentCase = struct {
                dir: string,
                query: string,
                actual: string,
            };
        };

        pub fn deinit(e: *Entry, allocator: *std.mem.Allocator) void {
            allocator.free(e.base);
            allocator.free(e.dir);
            allocator.free(e.cache.symlink);
            allocator.destroy(e);
        }

        pub const Cache = struct {
            symlink: string = "",
            kind: Kind = Kind.file,
        };

        pub const Kind = enum {
            dir,
            file,
        };

        pub fn kind(entry: *Entry, fs: *Implementation) Kind {
            // entry.mutex.lock();
            // defer entry.mutex.unlock();
            if (entry.need_stat) {
                entry.need_stat = false;
                entry.cache = fs.kind(entry.dir, entry.base) catch unreachable;
            }
            return entry.cache.kind;
        }

        pub fn symlink(entry: *Entry, fs: *Implementation) string {
            // entry.mutex.lock();
            // defer entry.mutex.unlock();
            if (entry.need_stat) {
                entry.need_stat = false;
                entry.cache = fs.kind(entry.dir, entry.base) catch unreachable;
            }
            return entry.cache.symlink;
        }
    };

    // pub fn statBatch(fs: *FileSystemEntry, paths: []string) ![]?Stat {

    // }
    // pub fn stat(fs: *FileSystemEntry, path: string) !Stat {

    // }
    // pub fn readFile(fs: *FileSystemEntry, path: string) ?string {

    // }
    // pub fn readDir(fs: *FileSystemEntry, path: string) ?[]string {

    // }
    pub fn normalize(f: *@This(), str: string) string {
        return @call(.{ .modifier = .always_inline }, path_handler.normalizeString, .{ str, true, .auto });
    }

    pub fn join(f: *@This(), parts: anytype) string {
        return @call(.{ .modifier = .always_inline }, path_handler.joinStringBuf, .{
            &join_buf,
            parts,
            .auto,
        });
    }

    pub fn joinBuf(f: *@This(), parts: anytype, buf: []u8) string {
        return @call(.{ .modifier = .always_inline }, path_handler.joinStringBuf, .{
            buf,
            parts,
            .auto,
        });
    }

    pub fn relative(f: *@This(), from: string, to: string) string {
        return @call(.{ .modifier = .always_inline }, path_handler.relative, .{
            from,
            to,
        });
    }

    pub fn relativeAlloc(f: *@This(), allocator: *std.mem.Allocator, from: string, to: string) string {
        return @call(.{ .modifier = .always_inline }, path_handler.relativeAlloc, .{
            alloc,
            from,
            to,
        });
    }

    pub fn relativeTo(f: *@This(), to: string) string {
        return @call(.{ .modifier = .always_inline }, path_handler.relative, .{
            f.top_level_dir,
            to,
        });
    }

    pub fn relativeFrom(f: *@This(), from: string) string {
        return @call(.{ .modifier = .always_inline }, path_handler.relative, .{
            from,
            f.top_level_dir,
        });
    }

    pub fn relativeToAlloc(f: *@This(), allocator: *std.mem.Allocator, to: string) string {
        return @call(.{ .modifier = .always_inline }, path_handler.relativeAlloc, .{
            allocator,
            f.top_level_dir,
            to,
        });
    }

    pub fn absAlloc(f: *@This(), allocator: *std.mem.Allocator, parts: anytype) !string {
        const joined = path_handler.joinAbsString(
            f.top_level_dir,
            parts,
            .auto,
        );
        return try allocator.dupe(u8, joined);
    }

    pub fn abs(f: *@This(), parts: anytype) string {
        return path_handler.joinAbsString(
            f.top_level_dir,
            parts,
            .auto,
        );
    }

    pub fn absBuf(f: *@This(), parts: anytype, buf: []u8) string {
        return path_handler.joinAbsStringBuf(f.top_level_dir, buf, parts, .auto);
    }

    pub fn joinAlloc(f: *@This(), allocator: *std.mem.Allocator, parts: anytype) !string {
        const joined = f.join(parts);
        return try allocator.dupe(u8, joined);
    }

    threadlocal var realpath_buffer: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    pub fn resolveAlloc(f: *@This(), allocator: *std.mem.Allocator, parts: anytype) !string {
        const joined = f.abs(parts);

        const realpath = f.resolvePath(joined);

        return try allocator.dupe(u8, realpath);
    }

    pub fn resolvePath(f: *@This(), part: string) ![]u8 {
        return try std.fs.realpath(part, (&realpath_buffer).ptr);
    }

    pub const RealFS = struct {
        entries_mutex: Mutex = Mutex.init(),
        entries: *EntriesOption.Map,
        allocator: *std.mem.Allocator,
        limiter: Limiter,
        cwd: string,
        parent_fs: *FileSystem = undefined,
        file_limit: usize = 32,
        file_quota: usize = 32,

        pub var tmpdir_buf: [std.fs.MAX_PATH_BYTES]u8 = undefined;
        pub var tmpdir_path: []const u8 = undefined;
        pub fn openTmpDir(fs: *const RealFS) !std.fs.Dir {
            if (isMac) {
                var tmpdir_base = std.os.getenv("TMPDIR") orelse "/private/tmp";
                tmpdir_path = try std.fs.realpath(tmpdir_base, &tmpdir_buf);
                return try std.fs.openDirAbsolute(tmpdir_path, .{ .access_sub_paths = true, .iterate = true });
            } else {
                @compileError("Implement openTmpDir");
            }
        }

        pub fn needToCloseFiles(rfs: *const RealFS) bool {
            // On Windows, we must always close open file handles
            // Windows locks files
            if (!FeatureFlags.store_file_descriptors) {
                return true;
            }

            // If we're not near the max amount of open files, don't worry about it.
            return !(rfs.file_limit > 254 and rfs.file_limit > (FileSystem.max_fd + 1) * 2);
        }

        // Always try to max out how many files we can keep open
        pub fn adjustUlimit() usize {
            var limit = std.os.getrlimit(.NOFILE) catch return 32;
            if (limit.cur < limit.max) {
                var new_limit = std.mem.zeroes(std.os.rlimit);
                new_limit.cur = limit.max;
                new_limit.max = limit.max;
                std.os.setrlimit(.NOFILE, new_limit) catch return limit.cur;
                return new_limit.cur;
            }
            return limit.cur;
        }

        pub fn init(
            allocator: *std.mem.Allocator,
            cwd: string,
        ) RealFS {
            const file_limit = adjustUlimit();
            return RealFS{
                .entries = EntriesOption.Map.init(allocator),
                .allocator = allocator,
                .cwd = cwd,
                .file_limit = file_limit,
                .file_quota = file_limit,
                .limiter = Limiter.init(allocator, file_limit),
            };
        }

        pub const ModKeyError = error{
            Unusable,
        };
        pub const ModKey = struct {
            inode: std.fs.File.INode = 0,
            size: u64 = 0,
            mtime: i128 = 0,
            mode: std.fs.File.Mode = 0,

            threadlocal var hash_bytes: [32]u8 = undefined;
            threadlocal var hash_name_buf: [1024]u8 = undefined;

            pub fn hashName(
                this: *const ModKey,
                basename: string,
            ) !string {

                // We shouldn't just read the contents of the ModKey into memory
                // The hash should be deterministic across computers and operating systems.
                // inode is non-deterministic across volumes within the same compuiter
                // so if we're not going to do a full content hash, we should use mtime and size.
                // even mtime is debatable.
                var hash_bytes_remain: []u8 = hash_bytes[0..];
                std.mem.writeIntNative(@TypeOf(this.size), hash_bytes_remain[0..@sizeOf(@TypeOf(this.size))], this.size);
                hash_bytes_remain = hash_bytes_remain[@sizeOf(@TypeOf(this.size))..];
                std.mem.writeIntNative(@TypeOf(this.mtime), hash_bytes_remain[0..@sizeOf(@TypeOf(this.mtime))], this.mtime);

                return try std.fmt.bufPrint(
                    &hash_name_buf,
                    "{s}-{x}",
                    .{
                        basename,
                        @truncate(u32, std.hash.Wyhash.hash(1, &hash_bytes)),
                    },
                );
            }

            pub fn generate(fs: *RealFS, path: string, file: std.fs.File) anyerror!ModKey {
                const stat = try file.stat();

                const seconds = @divTrunc(stat.mtime, @as(@TypeOf(stat.mtime), std.time.ns_per_s));

                // We can't detect changes if the file system zeros out the modification time
                if (seconds == 0 and std.time.ns_per_s == 0) {
                    return error.Unusable;
                }

                // Don't generate a modification key if the file is too new
                const now = std.time.nanoTimestamp();
                const now_seconds = @divTrunc(now, std.time.ns_per_s);
                if (seconds > seconds or (seconds == now_seconds and stat.mtime > now)) {
                    return error.Unusable;
                }

                return ModKey{
                    .inode = stat.inode,
                    .size = stat.size,
                    .mtime = stat.mtime,
                    .mode = stat.mode,
                    // .uid = stat.
                };
            }
            pub const SafetyGap = 3;
        };

        pub fn modKeyWithFile(fs: *RealFS, path: string, file: anytype) anyerror!ModKey {
            return try ModKey.generate(fs, path, file);
        }

        pub fn modKey(fs: *RealFS, path: string) anyerror!ModKey {
            fs.limiter.before();
            defer fs.limiter.after();
            var file = try std.fs.openFileAbsolute(path, std.fs.File.OpenFlags{ .read = true });
            defer {
                if (fs.needToCloseFiles()) {
                    file.close();
                }
            }
            return try fs.modKeyWithFile(path, file);
        }

        pub const EntriesOption = union(Tag) {
            entries: DirEntry,
            err: DirEntry.Err,

            pub const Tag = enum {
                entries,
                err,
            };

            // This custom map implementation:
            // - Preallocates a fixed amount of directory name space
            // - Doesn't store directory names which don't exist.
            pub const Map = allocators.BSSMap(EntriesOption, Preallocate.Counts.dir_entry, false, 128);
        };

        // Limit the number of files open simultaneously to avoid ulimit issues
        pub const Limiter = struct {
            semaphore: Semaphore,
            pub fn init(allocator: *std.mem.Allocator, limit: usize) Limiter {
                return Limiter{
                    .semaphore = Semaphore.init(limit),
                    // .counter = std.atomic.Int(u8).init(0),
                    // .lock = std.Thread.Mutex.init(),
                };
            }

            // This will block if the number of open files is already at the limit
            pub fn before(limiter: *Limiter) void {
                limiter.semaphore.wait();
                // var added = limiter.counter.fetchAdd(1);
            }

            pub fn after(limiter: *Limiter) void {
                limiter.semaphore.post();
                // limiter.counter.decr();
                // if (limiter.held) |hold| {
                //     hold.release();
                //     limiter.held = null;
                // }
            }
        };

        pub fn openDir(fs: *RealFS, unsafe_dir_string: string) std.fs.File.OpenError!std.fs.Dir {
            return try std.fs.openDirAbsolute(unsafe_dir_string, std.fs.Dir.OpenDirOptions{ .iterate = true, .access_sub_paths = true, .no_follow = true });
        }

        fn readdir(
            fs: *RealFS,
            _dir: string,
            handle: std.fs.Dir,
        ) !DirEntry {
            fs.limiter.before();
            defer fs.limiter.after();

            var iter: std.fs.Dir.Iterator = handle.iterate();
            var dir = DirEntry.init(_dir, fs.allocator);
            errdefer dir.deinit();

            if (FeatureFlags.store_file_descriptors) {
                FileSystem.setMaxFd(handle.fd);
                dir.fd = handle.fd;
            }

            while (try iter.next()) |_entry| {
                try dir.addEntry(_entry);
            }

            return dir;
        }

        fn readDirectoryError(fs: *RealFS, dir: string, err: anyerror) !*EntriesOption {
            if (FeatureFlags.disable_entry_cache) {
                fs.entries_mutex.lock();
                defer fs.entries_mutex.unlock();
                var get_or_put_result = try fs.entries.getOrPut(dir);
                var opt = try fs.entries.put(&get_or_put_result, EntriesOption{
                    .err = DirEntry.Err{ .original_err = err, .canonical_error = err },
                });

                return opt;
            }

            temp_entries_option = EntriesOption{
                .err = DirEntry.Err{ .original_err = err, .canonical_error = err },
            };
            return &temp_entries_option;
        }

        threadlocal var temp_entries_option: EntriesOption = undefined;

        pub fn readDirectory(fs: *RealFS, _dir: string, _handle: ?std.fs.Dir) !*EntriesOption {
            var dir = _dir;
            var cache_result: ?allocators.Result = null;

            if (FeatureFlags.disable_entry_cache) {
                fs.entries_mutex.lock();
                defer fs.entries_mutex.unlock();

                cache_result = try fs.entries.getOrPut(dir);

                if (cache_result.?.hasCheckedIfExists()) {
                    if (fs.entries.atIndex(cache_result.?.index)) |cached_result| {
                        return cached_result;
                    }
                }
            }

            var handle = _handle orelse try fs.openDir(dir);

            defer {
                if (_handle == null and fs.needToCloseFiles()) {
                    handle.close();
                }
            }

            // if we get this far, it's a real directory, so we can just store the dir name.
            if (_handle == null) {
                dir = try DirnameStore.instance.append(string, _dir);
            }

            // Cache miss: read the directory entries
            var entries = fs.readdir(
                dir,
                handle,
            ) catch |err| {
                return fs.readDirectoryError(dir, err) catch unreachable;
            };

            if (FeatureFlags.disable_entry_cache) {
                fs.entries_mutex.lock();
                defer fs.entries_mutex.unlock();
                const result = EntriesOption{
                    .entries = entries,
                };

                return try fs.entries.put(&cache_result.?, result);
            }

            temp_entries_option = EntriesOption{ .entries = entries };

            return &temp_entries_option;
        }

        fn readFileError(fs: *RealFS, path: string, err: anyerror) void {}

        pub fn readFileWithHandle(
            fs: *RealFS,
            path: string,
            _size: ?usize,
            file: std.fs.File,
            comptime use_shared_buffer: bool,
            shared_buffer: *MutableString,
        ) !File {
            FileSystem.setMaxFd(file.handle);

            if (FeatureFlags.disable_filesystem_cache) {
                _ = std.os.fcntl(file.handle, std.os.F_NOCACHE, 1) catch 0;
            }

            // Skip the extra file.stat() call when possible
            var size = _size orelse (file.getEndPos() catch |err| {
                fs.readFileError(path, err);
                return err;
            });

            var file_contents: []u8 = undefined;

            // When we're serving a JavaScript-like file over HTTP, we do not want to cache the contents in memory
            // This imposes a performance hit because not reading from disk is faster than reading from disk
            // Part of that hit is allocating a temporary buffer to store the file contents in
            // As a mitigation, we can just keep one buffer forever and re-use it for the parsed files
            if (use_shared_buffer) {
                shared_buffer.reset();
                try shared_buffer.growBy(size);
                shared_buffer.list.expandToCapacity();
                // We use pread to ensure if the file handle was open, it doesn't seek from the last position
                var read_count = file.preadAll(shared_buffer.list.items, 0) catch |err| {
                    fs.readFileError(path, err);
                    return err;
                };
                shared_buffer.list.items = shared_buffer.list.items[0..read_count];
                file_contents = shared_buffer.list.items;
            } else {
                // We use pread to ensure if the file handle was open, it doesn't seek from the last position
                var buf = try fs.allocator.alloc(u8, size);
                var read_count = file.preadAll(buf, 0) catch |err| {
                    fs.readFileError(path, err);
                    return err;
                };
                file_contents = buf[0..read_count];
            }

            return File{ .path = Path.init(path), .contents = file_contents };
        }

        pub fn readFile(
            fs: *RealFS,
            path: string,
            _size: ?usize,
        ) !File {
            fs.limiter.before();
            defer fs.limiter.after();
            const file: std.fs.File = std.fs.openFileAbsolute(path, std.fs.File.OpenFlags{ .read = true, .write = false }) catch |err| {
                fs.readFileError(path, err);
                return err;
            };
            defer {
                if (fs.needToCloseFiles()) {
                    file.close();
                }
            }

            return try fs.readFileWithHandle(path, _size, file);
        }

        pub fn kind(fs: *RealFS, _dir: string, base: string) !Entry.Cache {
            var dir = _dir;
            var combo = [2]string{ dir, base };
            var entry_path = path_handler.joinAbsString(fs.cwd, &combo, .auto);

            fs.limiter.before();
            defer fs.limiter.after();

            const file = try std.fs.openFileAbsolute(entry_path, .{ .read = true, .write = false });
            defer {
                if (fs.needToCloseFiles()) {
                    file.close();
                }
            }
            var stat = try file.stat();

            var _kind = stat.kind;
            var cache = Entry.Cache{ .kind = Entry.Kind.file, .symlink = "" };
            var symlink: []const u8 = "";
            if (_kind == .SymLink) {
                // windows has a max filepath of 255 chars
                // we give it a little longer for other platforms
                var out_buffer = std.mem.zeroes([512]u8);
                var out_slice = &out_buffer;
                symlink = entry_path;
                var links_walked: u8 = 0;

                while (links_walked < 255) : (links_walked += 1) {
                    var link: string = try std.os.readlink(symlink, out_slice);

                    if (!std.fs.path.isAbsolute(link)) {
                        combo[0] = dir;
                        combo[1] = link;

                        link = path_handler.joinAbsStringBuf(fs.cwd, out_slice, &combo, .auto);
                    }
                    // TODO: do we need to clean the path?
                    symlink = link;

                    const file2 = std.fs.openFileAbsolute(symlink, std.fs.File.OpenFlags{ .read = true, .write = false }) catch return cache;
                    // These ones we always close
                    defer file2.close();

                    const stat2 = file2.stat() catch return cache;

                    // Re-run "lstat" on the symlink target
                    _kind = stat2.kind;
                    if (_kind != .SymLink) {
                        break;
                    }
                    dir = std.fs.path.dirname(link) orelse return cache;
                }

                if (links_walked > 255) {
                    return cache;
                }
            }

            if (_kind == .Directory) {
                cache.kind = .dir;
            } else {
                cache.kind = .file;
            }
            if (symlink.len > 0) {
                cache.symlink = try fs.allocator.dupe(u8, symlink);
            }

            return cache;
        }

        //     	// Stores the file entries for directories we've listed before
        // entries_mutex: std.Mutex
        // entries      map[string]entriesOrErr

        // // If true, do not use the "entries" cache
        // doNotCacheEntries bool
    };

    pub const Implementation = switch (build_target) {
        .wasi, .native => RealFS,
        .wasm => WasmFS,
    };
};

pub const Directory = struct { path: Path, contents: []string };
pub const File = struct { path: Path, contents: string };

pub const PathName = struct {
    base: string,
    dir: string,
    ext: string,

    // For readability, the names of certain automatically-generated symbols are
    // derived from the file name. For example, instead of the CommonJS wrapper for
    // a file being called something like "require273" it can be called something
    // like "require_react" instead. This function generates the part of these
    // identifiers that's specific to the file path. It can take both an absolute
    // path (OS-specific) and a path in the source code (OS-independent).
    //
    // Note that these generated names do not at all relate to the correctness of
    // the code as far as avoiding symbol name collisions. These names still go
    // through the renaming logic that all other symbols go through to avoid name
    // collisions.
    pub fn nonUniqueNameString(self: *const PathName, allocator: *std.mem.Allocator) !string {
        if (strings.eqlComptime(self.base, "index")) {
            if (self.dir.len > 0) {
                return MutableString.ensureValidIdentifier(PathName.init(self.dir).dir, allocator);
            }
        }

        return MutableString.ensureValidIdentifier(self.base, allocator);
    }

    pub fn dirWithTrailingSlash(this: *const PathName) string {
        // The three strings basically always point to the same underlying ptr
        // so if dir does not have a trailing slash, but is spaced one apart from the basename
        // we can assume there is a trailing slash there
        // so we extend the original slice's length by one
        return if (this.dir.len == 0) "./" else this.dir.ptr[0 .. this.dir.len + @intCast(
            usize,
            @boolToInt(
                this.dir[this.dir.len - 1] != std.fs.path.sep_posix and (@ptrToInt(this.dir.ptr) + this.dir.len + 1) == @ptrToInt(this.base.ptr),
            ),
        )];
    }

    pub fn init(_path: string) PathName {
        var path = _path;
        var base = path;
        var ext = path;
        var dir = path;
        var is_absolute = true;

        var _i = strings.lastIndexOfChar(path, '/');
        while (_i) |i| {
            // Stop if we found a non-trailing slash
            if (i + 1 != path.len) {
                base = path[i + 1 ..];
                dir = path[0..i];
                is_absolute = false;
                break;
            }

            // Ignore trailing slashes
            path = path[0..i];

            _i = strings.lastIndexOfChar(path, '/');
        }

        // Strip off the extension
        var _dot = strings.lastIndexOfChar(base, '.');
        if (_dot) |dot| {
            ext = base[dot..];
            base = base[0..dot];
        }

        if (is_absolute) {
            dir = &([_]u8{});
        }

        return PathName{
            .dir = dir,
            .base = base,
            .ext = ext,
        };
    }
};

threadlocal var normalize_buf: [1024]u8 = undefined;
threadlocal var join_buf: [1024]u8 = undefined;

pub const Path = struct {
    pretty: string,
    text: string,
    namespace: string = "unspecified",
    name: PathName,
    is_disabled: bool = false,

    pub fn jsonStringify(self: *const @This(), options: anytype, writer: anytype) !void {
        return try std.json.stringify(self.text, options, writer);
    }

    pub fn generateKey(p: *Path, allocator: *std.mem.Allocator) !string {
        return try std.fmt.allocPrint(allocator, "{s}://{s}", .{ p.namespace, p.text });
    }

    pub fn init(text: string) Path {
        return Path{ .pretty = text, .text = text, .namespace = "file", .name = PathName.init(text) };
    }

    pub fn initWithPretty(text: string, pretty: string) Path {
        return Path{ .pretty = pretty, .text = text, .namespace = "file", .name = PathName.init(text) };
    }

    pub fn initWithNamespace(text: string, namespace: string) Path {
        return Path{ .pretty = text, .text = text, .namespace = namespace, .name = PathName.init(text) };
    }

    pub fn isBefore(a: *Path, b: Path) bool {
        return a.namespace > b.namespace ||
            (a.namespace == b.namespace and (a.text < b.text ||
            (a.text == b.text and (a.flags < b.flags ||
            (a.flags == b.flags)))));
    }
};

test "PathName.init" {
    var file = "/root/directory/file.ext".*;
    const res = PathName.init(
        &file,
    );

    try std.testing.expectEqualStrings(res.dir, "/root/directory");
    try std.testing.expectEqualStrings(res.base, "file");
    try std.testing.expectEqualStrings(res.ext, ".ext");
}

test {}
