const w32 = @import("bof_launcher_win32");
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var cmd_args_iter = try std.process.argsWithAllocator(allocator);
    defer cmd_args_iter.deinit();

    _ = cmd_args_iter.skip(); // skip program name

    const shellcode_file = cmd_args_iter.next() orelse {
        try usage();
        return;
    };

    const file = try std.fs.cwd().openFile(shellcode_file, .{});
    defer file.close();

    const file_stat = try file.stat();
    const file_data = try allocator.alloc(u8, @intCast(file_stat.size));
    defer allocator.free(file_data);

    var file_reader = file.reader(&.{});
    try file_reader.interface.readSliceAll(file_data);

    if (@import("builtin").os.tag == .windows) {
        w32.init();

        // Extract .text section from input executable.
        const parser = try std.coff.Coff.init(file_data, false);
        const text_header = parser.getSectionByName(".text") orelse unreachable;
        const text_data = parser.getSectionData(text_header);

        const addr = w32.VirtualAlloc(
            null,
            text_data.len,
            w32.MEM_COMMIT | w32.MEM_RESERVE,
            w32.PAGE_READWRITE,
        );
        defer _ = w32.VirtualFree(addr, 0, w32.MEM_RELEASE);

        const section = @as([*]u8, @ptrCast(addr))[0..text_data.len];

        @memcpy(section, text_data);

        var old_protection: w32.DWORD = 0;
        if (w32.VirtualProtect(
            section.ptr,
            section.len,
            w32.PAGE_EXECUTE_READ,
            &old_protection,
        ) == w32.FALSE) return error.VirtualProtectFailed;

        _ = w32.FlushInstructionCache(w32.GetCurrentProcess(), section.ptr, section.len);

        @as(*const fn () callconv(.c) void, @ptrCast(section.ptr))();
    } else {
        const img = try std.posix.mmap(
            null,
            file_data.len,
            std.posix.PROT.READ | std.posix.PROT.EXEC | std.posix.PROT.WRITE,
            .{ .TYPE = .PRIVATE, .ANONYMOUS = true },
            -1,
            0,
        );
        @memcpy(img, file_data);

        @as(*const fn () callconv(.c) void, @ptrCast(img))();
    }
}

fn usage() !void {
    var stdout_writer = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_writer.interface;
    try stdout.print(
        \\
        \\ USAGE:
        \\      shellcode_launcher <shellcode_exe_file>
        \\
    , .{});
    try stdout.flush();
}
