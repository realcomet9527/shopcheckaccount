const Fs = @import("./fs.zig");
const std = @import("std");
usingnamespace @import("global.zig");
const options = @import("./options.zig");
const IndexType = @import("./allocators.zig").IndexType;

const os = std.os;

const Mutex = @import("./lock.zig").Lock;
const Futex = @import("./futex.zig");
const WatchItemIndex = u16;
const NoWatchItem: WatchItemIndex = std.math.maxInt(WatchItemIndex);
const PackageJSON = @import("./resolver/package_json.zig").PackageJSON;

const WATCHER_MAX_LIST = 8096;

pub const INotify = struct {
    pub const IN_CLOEXEC = std.os.O_CLOEXEC;
    pub const IN_NONBLOCK = std.os.O_NONBLOCK;

    pub const IN_ACCESS = 0x00000001;
    pub const IN_MODIFY = 0x00000002;
    pub const IN_ATTRIB = 0x00000004;
    pub const IN_CLOSE_WRITE = 0x00000008;
    pub const IN_CLOSE_NOWRITE = 0x00000010;
    pub const IN_CLOSE = IN_CLOSE_WRITE | IN_CLOSE_NOWRITE;
    pub const IN_OPEN = 0x00000020;
    pub const IN_MOVED_FROM = 0x00000040;
    pub const IN_MOVED_TO = 0x00000080;
    pub const IN_MOVE = IN_MOVED_FROM | IN_MOVED_TO;
    pub const IN_CREATE = 0x00000100;
    pub const IN_DELETE = 0x00000200;
    pub const IN_DELETE_SELF = 0x00000400;
    pub const IN_MOVE_SELF = 0x00000800;
    pub const IN_ALL_EVENTS = 0x00000fff;

    pub const IN_UNMOUNT = 0x00002000;
    pub const IN_Q_OVERFLOW = 0x00004000;
    pub const IN_IGNORED = 0x00008000;

    pub const IN_ONLYDIR = 0x01000000;
    pub const IN_DONT_FOLLOW = 0x02000000;
    pub const IN_EXCL_UNLINK = 0x04000000;
    pub const IN_MASK_ADD = 0x20000000;

    pub const IN_ISDIR = 0x40000000;
    pub const IN_ONESHOT = 0x80000000;

    pub const EventListIndex = c_int;

    pub const INotifyEvent = extern struct {
        watch_descriptor: c_int,
        mask: u32,
        cookie: u32,
        name_len: u32,
    };
    pub var inotify_fd: EventListIndex = 0;
    pub var loaded_inotify = false;

    const EventListBuffer = [@sizeOf([128]INotifyEvent) + (128 * std.fs.MAX_PATH_BYTES)]u8;
    var eventlist: EventListBuffer = undefined;
    var eventlist_ptrs: [128]*const INotifyEvent = undefined;

    var watch_count: std.atomic.Atomic(u32) = std.atomic.Atomic(u32).init(0);

    const watch_file_mask = IN_EXCL_UNLINK | IN_MOVE_SELF | IN_DELETE_SELF | IN_CLOSE_WRITE;
    const watch_dir_mask = IN_EXCL_UNLINK | IN_DELETE | IN_DELETE_SELF | IN_CREATE | IN_MOVE_SELF | IN_ONLYDIR;

    pub fn watchPath(pathname: [:0]const u8) !EventListIndex {
        std.debug.assert(loaded_inotify);
        const old_count = watch_count.fetchAdd(1, .Release);
        defer if (old_count == 0) Futex.wake(&watch_count, 10);
        return std.os.inotify_add_watchZ(inotify_fd, pathname, watch_file_mask);
    }

    pub fn watchDir(pathname: [:0]const u8) !EventListIndex {
        std.debug.assert(loaded_inotify);
        const old_count = watch_count.fetchAdd(1, .Release);
        defer if (old_count == 0) Futex.wake(&watch_count, 10);
        return std.os.inotify_add_watchZ(inotify_fd, pathname, watch_dir_mask);
    }

    pub fn unwatch(wd: EventListIndex) void {
        std.debug.assert(loaded_inotify);
        _ = watch_count.fetchSub(1, .Release);
        std.os.inotify_rm_watch(inotify_fd, wd);
    }

    pub fn init() !void {
        std.debug.assert(!loaded_inotify);
        loaded_inotify = true;

        inotify_fd = try std.os.inotify_init1(IN_CLOEXEC);
    }

    pub fn read() ![]*const INotifyEvent {
        std.debug.assert(loaded_inotify);

        restart: while (true) {
            Futex.wait(&watch_count, 0, null) catch unreachable;
            const rc = std.os.system.read(
                inotify_fd,
                @ptrCast([*]u8, @alignCast(@alignOf([*]u8), &eventlist)),
                @sizeOf(EventListBuffer),
            );

            switch (std.os.errno(rc)) {
                .SUCCESS => {
                    const len = @intCast(usize, rc);

                    if (len == 0) return &[_]*INotifyEvent{};

                    var count: u32 = 0;
                    var i: u32 = 0;
                    while (i < len) : (i += @sizeOf(INotifyEvent)) {
                        const event = @ptrCast(*const INotifyEvent, @alignCast(@alignOf(*const INotifyEvent), eventlist[i..][0..@sizeOf(INotifyEvent)]));
                        if (event.name_len > 0) {
                            i += event.name_len;
                        }

                        eventlist_ptrs[count] = event;
                        count += 1;
                    }

                    return eventlist_ptrs[0..count];
                },
                .AGAIN => continue :restart,
                .INVAL => return error.ShortRead,
                .BADF => return error.INotifyFailedToStart,

                else => unreachable,
            }
        }
        unreachable;
    }

    pub fn stop() void {
        if (inotify_fd != 0) {
            std.os.close(inotify_fd);
            inotify_fd = 0;
        }
    }
};

const DarwinWatcher = struct {
    pub const EventListIndex = u32;

    const KEvent = std.c.Kevent;
    // Internal
    pub var changelist: [128]KEvent = undefined;

    // Everything being watched
    pub var eventlist: [WATCHER_MAX_LIST]KEvent = undefined;
    pub var eventlist_index: EventListIndex = 0;

    pub var fd: i32 = 0;

    pub fn init() !void {
        std.debug.assert(fd == 0);

        fd = try std.os.kqueue();
        if (fd == 0) return error.KQueueError;
    }

    pub fn stop() void {
        if (fd != 0) {
            std.os.close(fd);
        }

        fd = 0;
    }
};

const PlatformWatcher = if (Environment.isMac)
    DarwinWatcher
else if (Environment.isLinux)
    INotify
else
    void;

pub const WatchItem = struct {
    file_path: string,
    // filepath hash for quick comparison
    hash: u32,
    eventlist_index: PlatformWatcher.EventListIndex,
    loader: options.Loader,
    fd: StoredFileDescriptorType,
    count: u32,
    parent_hash: u32,
    kind: Kind,
    package_json: ?*PackageJSON,

    pub const Kind = enum { file, directory };
};

pub const WatchEvent = struct {
    index: WatchItemIndex,
    op: Op,

    const KEvent = std.c.Kevent;

    pub const Sorter = void;

    pub fn sortByIndex(context: Sorter, event: WatchEvent, rhs: WatchEvent) bool {
        return event.index < rhs.index;
    }

    pub fn merge(this: *WatchEvent, other: WatchEvent) void {
        this.op = Op{
            .delete = this.op.delete or other.op.delete,
            .metadata = this.op.metadata or other.op.metadata,
            .rename = this.op.rename or other.op.rename,
            .write = this.op.write or other.op.write,
        };
    }

    pub fn fromKEvent(this: *WatchEvent, kevent: KEvent) void {
        this.* =
            WatchEvent{
            .op = Op{
                .delete = (kevent.fflags & std.os.NOTE_DELETE) > 0,
                .metadata = (kevent.fflags & std.os.NOTE_ATTRIB) > 0,
                .rename = (kevent.fflags & std.os.NOTE_RENAME) > 0,
                .write = (kevent.fflags & std.os.NOTE_WRITE) > 0,
            },
            .index = @truncate(WatchItemIndex, kevent.udata),
        };
    }

    pub fn fromINotify(this: *WatchEvent, event: INotify.INotifyEvent, index: WatchItemIndex) void {
        this.* = WatchEvent{
            .op = Op{
                .delete = (event.mask & INotify.IN_DELETE_SELF) > 0 or (event.mask & INotify.IN_DELETE) > 0,
                .metadata = false,
                .rename = (event.mask & INotify.IN_MOVE_SELF) > 0,
                .write = (event.mask & INotify.IN_MODIFY) > 0 or (event.mask & INotify.IN_MOVE) > 0,
            },
            .index = index,
        };
    }

    pub const Op = packed struct {
        delete: bool = false,
        metadata: bool = false,
        rename: bool = false,
        write: bool = false,
    };
};

pub const Watchlist = std.MultiArrayList(WatchItem);

// This implementation only works on macOS, for now.
// The Internet seems to suggest basically always using FSEvents instead of kqueue
// It seems like the main concern is max open file descriptors
// Since we adjust the ulimit already, I think we can avoid that.
pub fn NewWatcher(comptime ContextType: type) type {
    return struct {
        const Watcher = @This();

        watchlist: Watchlist,
        watched_count: usize = 0,
        mutex: Mutex,

        platform: PlatformWatcher = PlatformWatcher{},

        // User-facing
        watch_events: [128]WatchEvent = undefined,

        fs: *Fs.FileSystem,
        // this is what kqueue knows about
        fd: StoredFileDescriptorType,
        ctx: ContextType,
        allocator: *std.mem.Allocator,
        watchloop_handle: ?std.Thread.Id = null,
        cwd: string,

        pub const HashType = u32;

        var evict_list: [WATCHER_MAX_LIST]WatchItemIndex = undefined;

        pub fn getHash(filepath: string) HashType {
            return @truncate(HashType, std.hash.Wyhash.hash(0, filepath));
        }

        pub fn init(ctx: ContextType, fs: *Fs.FileSystem, allocator: *std.mem.Allocator) !*Watcher {
            var watcher = try allocator.create(Watcher);
            try PlatformWatcher.init();

            watcher.* = Watcher{
                .fs = fs,
                .fd = 0,
                .allocator = allocator,
                .watched_count = 0,
                .ctx = ctx,
                .watchlist = Watchlist{},
                .mutex = Mutex.init(),
                .cwd = fs.top_level_dir,
            };

            return watcher;
        }

        pub fn start(this: *Watcher) !void {
            std.debug.assert(this.watchloop_handle == null);
            var thread = try std.Thread.spawn(.{}, Watcher.watchLoop, .{this});
            thread.setName("File Watcher") catch {};
        }

        // This must only be called from the watcher thread
        pub fn watchLoop(this: *Watcher) !void {
            this.watchloop_handle = std.Thread.getCurrentId();
            var stdout = std.io.getStdOut();
            var stderr = std.io.getStdErr();
            var output_source = Output.Source.init(stdout, stderr);
            Output.Source.set(&output_source);

            defer Output.flush();
            if (FeatureFlags.verbose_watcher) Output.prettyln("Watcher started", .{});

            this._watchLoop() catch |err| {
                Output.prettyErrorln("<r>Watcher crashed: <red><b>{s}<r>", .{@errorName(err)});

                this.watchloop_handle = null;
                PlatformWatcher.stop();
                return;
            };
        }

        var evict_list_i: WatchItemIndex = 0;
        pub fn removeAtIndex(this: *Watcher, index: WatchItemIndex, hash: HashType, parents: []HashType, comptime kind: WatchItem.Kind) void {
            std.debug.assert(index != NoWatchItem);

            evict_list[evict_list_i] = index;
            evict_list_i += 1;

            if (comptime kind == .directory) {
                for (parents) |parent, i| {
                    if (parent == hash) {
                        evict_list[evict_list_i] = @truncate(WatchItemIndex, parent);
                        evict_list_i += 1;
                    }
                }
            }
        }

        pub fn flushEvictions(this: *Watcher) void {
            if (evict_list_i == 0) return;
            this.mutex.lock();
            defer this.mutex.unlock();
            defer evict_list_i = 0;

            // swapRemove messes up the order
            // But, it only messes up the order if any elements in the list appear after the item being removed
            // So if we just sort the list by the biggest index first, that should be fine
            std.sort.sort(
                WatchItemIndex,
                evict_list[0..evict_list_i],
                {},
                comptime std.sort.desc(WatchItemIndex),
            );

            var slice = this.watchlist.slice();
            var fds = slice.items(.fd);
            var event_list_ids = slice.items(.eventlist_index);
            var last_item = NoWatchItem;

            for (evict_list[0..evict_list_i]) |item, i| {
                // catch duplicates, since the list is sorted, duplicates will appear right after each other
                if (item == last_item) continue;

                // close the file descriptors here. this should automatically remove it from being watched too.
                std.os.close(fds[item]);

                // if (Environment.isLinux) {
                //     INotify.unwatch(event_list_ids[item]);
                // }

                last_item = item;
            }

            last_item = NoWatchItem;
            // This is split into two passes because reading the slice while modified is potentially unsafe.
            for (evict_list[0..evict_list_i]) |item, i| {
                if (item == last_item) continue;
                this.watchlist.swapRemove(item);
                last_item = item;
            }
        }

        fn _watchLoop(this: *Watcher) !void {
            const time = std.time;

            if (Environment.isMac) {
                std.debug.assert(DarwinWatcher.fd > 0);
                const KEvent = std.c.Kevent;

                var changelist_array: [1]KEvent = std.mem.zeroes([1]KEvent);
                var changelist = &changelist_array;
                while (true) {
                    defer Output.flush();

                    _ = std.os.system.kevent(
                        DarwinWatcher.fd,
                        @as([*]KEvent, changelist),
                        0,
                        @as([*]KEvent, changelist),
                        1,

                        null,
                    );

                    var watchevents = this.watch_events[0..1];
                    for (changelist) |event, i| {
                        watchevents[i].fromKEvent(event);
                    }

                    this.ctx.onFileUpdate(watchevents, this.watchlist);
                }
            } else if (Environment.isLinux) {
                restart: while (true) {
                    defer Output.flush();

                    var events = try INotify.read();
                    // TODO: is this thread safe?
                    const eventlist_index = this.watchlist.items(.eventlist_index);
                    var remaining_events = events.len;

                    while (remaining_events > 0) {
                        const slice = events[0..std.math.min(remaining_events, this.watch_events.len)];
                        var watchevents = this.watch_events[0..slice.len];
                        var watch_event_id: u32 = 0;
                        for (slice) |event| {
                            watchevents[watch_event_id].fromINotify(
                                event.*,
                                @intCast(
                                    WatchItemIndex,
                                    std.mem.indexOfScalar(
                                        INotify.EventListIndex,
                                        eventlist_index,
                                        event.watch_descriptor,
                                    ) orelse continue,
                                ),
                            );

                            watch_event_id += 1;
                        }

                        var all_events = watchevents[0..watch_event_id];
                        std.sort.sort(WatchEvent, all_events, void{}, WatchEvent.sortByIndex);

                        var last_event_index: usize = 0;
                        var last_event_id: INotify.EventListIndex = std.math.maxInt(INotify.EventListIndex);
                        for (all_events) |event, i| {
                            if (event.index == last_event_id) {
                                all_events[last_event_index].merge(event);
                                continue;
                            }
                            last_event_index = i;
                            last_event_id = event.index;
                        }
                        if (all_events.len == 0) continue :restart;
                        this.ctx.onFileUpdate(all_events[0 .. last_event_index + 1], this.watchlist);
                        remaining_events -= slice.len;
                    }
                }
            }
        }

        pub fn indexOf(this: *Watcher, hash: HashType) ?usize {
            for (this.watchlist.items(.hash)) |other, i| {
                if (hash == other) {
                    return i;
                }
            }
            return null;
        }

        pub fn addFile(
            this: *Watcher,
            fd: StoredFileDescriptorType,
            file_path: string,
            hash: HashType,
            loader: options.Loader,
            dir_fd: StoredFileDescriptorType,
            package_json: ?*PackageJSON,
            comptime copy_file_path: bool,
        ) !void {
            if (this.indexOf(hash) != null) {
                return;
            }

            try this.appendFile(fd, file_path, hash, loader, dir_fd, package_json, copy_file_path);
        }

        fn appendFileAssumeCapacity(
            this: *Watcher,
            fd: StoredFileDescriptorType,
            file_path: string,
            hash: HashType,
            loader: options.Loader,
            parent_hash: HashType,
            package_json: ?*PackageJSON,
            comptime copy_file_path: bool,
        ) !void {
            var index: PlatformWatcher.EventListIndex = undefined;
            const watchlist_id = this.watchlist.len;

            const file_path_: string = if (comptime copy_file_path)
                std.mem.span(try this.allocator.dupeZ(u8, file_path))
            else
                file_path;

            if (comptime Environment.isMac) {
                const KEvent = std.c.Kevent;
                index = DarwinWatcher.eventlist_index;

                // https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/kqueue.2.html
                var event = std.mem.zeroes(KEvent);

                event.flags = os.EV_ADD | os.EV_CLEAR | os.EV_ENABLE;
                // we want to know about the vnode
                event.filter = std.os.EVFILT_VNODE;

                event.fflags = std.os.NOTE_WRITE | std.os.NOTE_RENAME | std.os.NOTE_DELETE;

                // id
                event.ident = @intCast(usize, fd);

                DarwinWatcher.eventlist_index += 1;

                // Store the hash for fast filtering later
                event.udata = @intCast(usize, watchlist_id);
                DarwinWatcher.eventlist[index] = event;

                // This took a lot of work to figure out the right permutation
                // Basically:
                // - We register the event here.
                // our while(true) loop above receives notification of changes to any of the events created here.
                _ = std.os.system.kevent(
                    DarwinWatcher.fd,
                    DarwinWatcher.eventlist[index .. index + 1].ptr,
                    1,
                    DarwinWatcher.eventlist[index .. index + 1].ptr,
                    0,
                    null,
                );
            } else if (comptime Environment.isLinux) {
                // var file_path_to_use_ = std.mem.trimRight(u8, file_path_, "/");
                // var buf: [std.fs.MAX_PATH_BYTES+1]u8 = undefined;
                // std.mem.copy(u8, &buf, file_path_to_use_);
                // buf[file_path_to_use_.len] = 0;
                var buf = file_path_.ptr;
                var slice: [:0]const u8 = buf[0..file_path_.len :0];
                index = try INotify.watchPath(slice);
            }

            this.watchlist.appendAssumeCapacity(.{
                .file_path = std.mem.span(file_path_),
                .fd = fd,
                .hash = hash,
                .count = 0,
                .eventlist_index = index,
                .loader = loader,
                .parent_hash = parent_hash,
                .package_json = package_json,
                .kind = .file,
            });
        }

        fn appendDirectoryAssumeCapacity(
            this: *Watcher,
            fd_: StoredFileDescriptorType,
            file_path: string,
            hash: HashType,
            comptime copy_file_path: bool,
        ) !WatchItemIndex {
            const fd = brk: {
                if (fd_ > 0) break :brk fd_;

                const dir = try std.fs.openDirAbsolute(file_path, .{ .iterate = true });
                break :brk @truncate(StoredFileDescriptorType, dir.fd);
            };

            const parent_hash = Watcher.getHash(Fs.PathName.init(file_path).dirWithTrailingSlash());
            var index: PlatformWatcher.EventListIndex = undefined;
            const file_path_ptr = @intToPtr([*]const u8, @ptrToInt(file_path.ptr));
            const file_path_len = file_path.len;

            const file_path_: string = if (comptime copy_file_path)
                std.mem.span(try this.allocator.dupeZ(u8, file_path))
            else
                file_path;

            const watchlist_id = this.watchlist.len;

            if (Environment.isMac) {
                index = DarwinWatcher.eventlist_index;
                const KEvent = std.c.Kevent;

                // https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/kqueue.2.html
                var event = std.mem.zeroes(KEvent);

                event.flags = os.EV_ADD | os.EV_CLEAR | os.EV_ENABLE;
                // we want to know about the vnode
                event.filter = std.os.EVFILT_VNODE;

                // monitor:
                // - Write
                // - Rename
                // - Delete
                event.fflags = std.os.NOTE_WRITE | std.os.NOTE_RENAME | std.os.NOTE_DELETE;

                // id
                event.ident = @intCast(usize, fd);

                DarwinWatcher.eventlist_index += 1;
                // Store the hash for fast filtering later
                event.udata = @intCast(usize, watchlist_id);
                DarwinWatcher.eventlist[index] = event;

                // This took a lot of work to figure out the right permutation
                // Basically:
                // - We register the event here.
                // our while(true) loop above receives notification of changes to any of the events created here.
                _ = std.os.system.kevent(
                    DarwinWatcher.fd,
                    DarwinWatcher.eventlist[index .. index + 1].ptr,
                    1,
                    DarwinWatcher.eventlist[index .. index + 1].ptr,
                    0,
                    null,
                );
            } else if (Environment.isLinux) {
                var file_path_to_use_ = std.mem.trimRight(u8, file_path_, "/");
                var buf: [std.fs.MAX_PATH_BYTES + 1]u8 = undefined;
                std.mem.copy(u8, &buf, file_path_to_use_);
                buf[file_path_to_use_.len] = 0;
                var slice: [:0]u8 = buf[0..file_path_to_use_.len :0];
                index = try INotify.watchDir(slice);
            }

            this.watchlist.appendAssumeCapacity(.{
                .file_path = file_path_,
                .fd = fd,
                .hash = hash,
                .count = 0,
                .eventlist_index = index,
                .loader = options.Loader.file,
                .parent_hash = parent_hash,
                .kind = .directory,
                .package_json = null,
            });
            return @truncate(WatchItemIndex, this.watchlist.len - 1);
        }

        pub inline fn isEligibleDirectory(this: *Watcher, dir: string) bool {
            return strings.indexOf(dir, this.fs.top_level_dir) != null and strings.indexOf(dir, "node_modules") == null;
        }

        pub fn addDirectory(
            this: *Watcher,
            fd: StoredFileDescriptorType,
            file_path: string,
            hash: HashType,
            comptime copy_file_path: bool,
        ) !void {
            if (this.indexOf(hash) != null) {
                return;
            }

            this.mutex.lock();
            defer this.mutex.unlock();

            try this.watchlist.ensureUnusedCapacity(this.allocator, 1);

            _ = try this.appendDirectoryAssumeCapacity(fd, file_path, hash, copy_file_path);
        }

        pub fn appendFile(
            this: *Watcher,
            fd: StoredFileDescriptorType,
            file_path: string,
            hash: HashType,
            loader: options.Loader,
            dir_fd: StoredFileDescriptorType,
            package_json: ?*PackageJSON,
            comptime copy_file_path: bool,
        ) !void {
            this.mutex.lock();
            defer this.mutex.unlock();
            std.debug.assert(file_path.len > 1);
            const pathname = Fs.PathName.init(file_path);

            const parent_dir = pathname.dirWithTrailingSlash();
            var parent_dir_hash: HashType = Watcher.getHash(parent_dir);

            var parent_watch_item: ?WatchItemIndex = null;
            const autowatch_parent_dir = (comptime FeatureFlags.watch_directories) and this.isEligibleDirectory(parent_dir);
            if (autowatch_parent_dir) {
                var watchlist_slice = this.watchlist.slice();

                if (dir_fd > 0) {
                    var fds = watchlist_slice.items(.fd);
                    if (std.mem.indexOfScalar(StoredFileDescriptorType, fds, dir_fd)) |i| {
                        parent_watch_item = @truncate(WatchItemIndex, i);
                    }
                }

                if (parent_watch_item == null) {
                    const hashes = watchlist_slice.items(.hash);
                    if (std.mem.indexOfScalar(HashType, hashes, parent_dir_hash)) |i| {
                        parent_watch_item = @truncate(WatchItemIndex, i);
                    }
                }
            }
            try this.watchlist.ensureUnusedCapacity(this.allocator, 1 + @intCast(usize, @boolToInt(parent_watch_item == null)));

            if (autowatch_parent_dir) {
                parent_watch_item = parent_watch_item orelse try this.appendDirectoryAssumeCapacity(dir_fd, parent_dir, parent_dir_hash, copy_file_path);
            }

            try this.appendFileAssumeCapacity(
                fd,
                file_path,
                hash,
                loader,
                parent_dir_hash,
                package_json,
                copy_file_path,
            );

            if (comptime FeatureFlags.verbose_watcher) {
                if (strings.indexOf(file_path, this.cwd)) |i| {
                    Output.prettyln("<r><d>Added <b>./{s}<r><d> to watch list.<r>", .{file_path[i + this.cwd.len ..]});
                } else {
                    Output.prettyln("<r><d>Added <b>{s}<r><d> to watch list.<r>", .{file_path});
                }
            }
        }
    };
}
