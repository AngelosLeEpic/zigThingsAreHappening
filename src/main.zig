const std = @import("std");
const math = std.math;
const rand = std.Random;

const dist = @import("distributions.zig");
const global = @import("global.zig");

pub fn main() !void {
    try Test_Poisson();
}

fn Test_GetRandFromNormalDistribution() !void {
    var rng = rand.DefaultPrng.init(123456789);
    var rando = rng.random();
    var p = global.Point{ .x = rando.floatNorm(f64), .y = rando.floatNorm(f64) };

    const currentWD = std.fs.cwd();

    const file = try currentWD.createFile("Data/TestNormal.csv", .{ .truncate = true });
    const writer = file.writer();
    try writer.print("Index, Value\n", .{});

    const MAX_RUNS: c_int = 10000;
    for (0..MAX_RUNS) |i| {
        if (global.DEBUG_PRINT)
            std.debug.print("px={}, py={}\n", .{ p.x, p.y });
    
        p = dist.GetRandPointFromNormalDistribution(p, 0, 1);

        try writer.print("{d}, {d}\n", .{ p.x, p.y });
        //try writer.print("{d}, {d}\n", .{ i, p.x });
        //try writer.print("{d}, {d}\n", .{ i, p.y });

        if (global.DEBUG_PRINT)
            std.debug.print("{x},", .{i});
    }

    file.close();
 
    return;
}

fn Test_Poisson() !void {
    var rng = rand.DefaultPrng.init(123456789);
    var rando = rng.random();

    const LAMBDA: f64 = 1;    

    const currentWD = std.fs.cwd();

    const file = try currentWD.createFile("Data/TestPoisson.csv", .{ .truncate = true });
    const writer = file.writer();
    try writer.print("Val1, Val2\n", .{});

    const MAX_RUNS: c_int = 10000;
    for (0..MAX_RUNS) |i| {        
    
        const poisson1 = dist.ConvertRandToPoissonDistribution(LAMBDA, rando.float(f64));
        const poisson2 = dist.ConvertRandToPoissonDistribution(LAMBDA, rando.float(f64));

        try writer.print("{d}, {d}\n", .{ poisson1, poisson2 });

        if (global.DEBUG_PRINT)
            std.debug.print("{x},", .{i});
    }

    file.close();
 
    return;
}
