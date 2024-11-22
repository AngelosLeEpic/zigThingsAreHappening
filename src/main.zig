const std = @import("std");
const math = std.math;
const rand = std.Random;

const dist = @import("distributions.zig");
const global = @import("global.zig");

pub fn main() !void {
    try Test_GetRandFromNormalDistribution();
}

fn Test_GetRandFromNormalDistribution() !void {
    // writing data
    var rng = rand.DefaultPrng.init(123456789);
    var rando = rng.random();
    var p = global.Point{ .x = rando.floatNorm(f64), .y = rando.floatNorm(f64) };

    const currentWD = std.fs.cwd();

    const file = try currentWD.createFile("Data/TestNormal.csv", .{ .truncate = true });
    const writer = file.writer();
    try writer.print("Index,Value\n", .{});

    const MAX_RUNS: c_int = 10000;
    for (0..MAX_RUNS) |i| {
        if (global.DEBUG_PRINT)
            std.debug.print("px={},py={}\n", .{ p.x, p.y });

        p = dist.GetRandFromNormalDistribution(p, 0, 1);

        try writer.print("{d},{d}\n", .{ p.x, p.y });
        //try writer.print("{d}, {d}\n", .{ i, p.x });
        //try writer.print("{d}, {d}\n", .{ i, p.y });

        if (global.DEBUG_PRINT)
            std.debug.print("{x},", .{i});
    }

    file.close();

    // reading data
    const zandas = @import("zandas.zig");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }
    const allocator = gpa.allocator();

    var df = try zandas.csv_to_df("Data/TestNormal.csv", allocator);
    defer df.deinit();
    const row = try df.get_row(0);
    defer row.deinit();
    std.debug.print("csv_data: {any}\n", .{row.items});
    std.debug.print("csv_data: {any}\n", .{df.get(0, 0)});

    return;
}
