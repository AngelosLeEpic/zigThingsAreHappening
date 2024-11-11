const std = @import("std");
const math = std.math;
const rand = std.Random;

const dist = @import("distributions.zig");
const global = @import("global.zig");
const Q1 = @import("Q1_Temp_Sim.zig");
const os = std.os;
pub fn main() !void {
    //const print = std.debug.print;

    //var args = std.process.args();

    //args.skip(); // skip the programme name argument, we don't care about it

    const stdout = std.io.getStdOut().writer();
    const args = try std.process.argsAlloc(std.heap.page_allocator);

    for (args, 0..) |arg, i| {
        try stdout.print("arg {}: {s}\n", .{ i, arg });
    }

    //print("{i}\n", argv);
    //print("string: {s}", argc[0]);

    //if (argc. <= 3) {
    //    print("You must input a valid test for me to run, please select:\n", null);
    //    print("testPoisson, seed, TestAmount\n", null);
    //    print("testNormal, seed, TestAmount\n", null);
    //    print("testQ1, seed, TestAmount, TestDensity\n", null);
    //}
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

fn Test_Q1() !void {
    const MAX_RUNS = 1000;
    const MCS_SIZE = 100;
    const StdDev = 0.153214;
    var MAX_TEMPS: [MAX_RUNS]f64 = undefined;

    const aloc = std.heap.page_allocator;

    const RUNS: [MAX_RUNS]std.ArrayList(f64) = undefined;
    // allocate memory for arrays
    for (RUNS) |run| {
        run = try aloc.alloc(f64, MCS_SIZE);
    }
    defer aloc.free(RUNS); // not sure how to free the memory so I put this here tom pls fix ;(

    // begin testing
    var count = 0;
    for (RUNS) |run| {
        const result = Q1.simulateQ1(MCS_SIZE, StdDev, run);
        MAX_TEMPS[count] = result.maxTemp;
        count += 1;
    }
    // results stored in arrays, writting results
    // not sure how to write results, should each MCS get its own file? This would result into 1000 csv files
    // but if I keep it all in one file, how will I sort this to seperate each run of the simulation?
    // TODO
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
