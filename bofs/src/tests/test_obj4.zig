const std = @import("std");
const fmt = std.fmt;
const beacon = @import("bof_api").beacon;

pub export fn go(arg_data: ?[*]u8, arg_len: i32) callconv(.C) u8 {
    const printf = beacon.printf.?;

    var parser = beacon.datap{};

    _ = printf(.output, "--- test_obj4.zig ---\n");

    if (arg_data == null) return 0;

    beacon.dataParse.?(&parser, arg_data, arg_len);
    const len = beacon.dataLength.?(&parser);
    const permissions = beacon.dataExtract.?(&parser, null);
    const path = beacon.dataExtract.?(&parser, null);
    const num = beacon.dataInt.?(&parser);
    const num_short = beacon.dataShort.?(&parser);
    if (arg_len > 0) {
        _ = printf(.output, "arg_len (from go): %d\n", arg_len);
        _ = printf(.output, "Length: (from go): %d\n", len);

        _ = printf(.output, "permissions: (from go): %s\n", permissions);
        _ = printf(.output, "path: (from go): %s\n", path);
        _ = printf(.output, "number (int): (from go): %d\n", num);
        _ = printf(.output, "number (short): (from go): %d\n", num_short);
    }

    return 0;
}
