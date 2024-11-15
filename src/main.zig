const std = @import("std");
const builtin = @import("builtin");
const math = std.math;
const rand = std.Random;
const os = std.os;

const dist = @import("distributions.zig");
const global = @import("global.zig");
const teamData = @import("teamData.zig");
const Q1 = @import("Q1_Temp_Sim.zig");

pub fn main() !void {

    global.Init();    
    try teamData.InitData();    
    
    if (global.IsReleaseMode()){
        std.debug.print("Running in Release mode\n", .{});
    }        
    else 
        std.debug.print("Running in Debug mode\n", .{});

    const args = try std.process.argsAlloc(std.heap.page_allocator);
    var count: c_int = 0;
    for (args, 0..) |arg, i| {
        std.debug.print("arg {}: {s}\n", .{ i, arg });
        count += 1;
    }

    if (count <= 1) {
        std.debug.print("Not enough args to run any function\n", .{});
        std.debug.print("Possible tests to invoke: testPoisson, testNormal, testQ1\n", .{});
        return;
    }

    if (std.mem.eql(u8, args[1], "testPoisson")) {
        std.debug.print("testing poisson distribution functionality\n", .{});
        try Test_Poisson();
        return;
    } 

    if (std.mem.eql(u8, args[1], "testNormal")) {
        std.debug.print("testing normal distribution functinality\n", .{});
        try Test_GetRandFromNormalDistribution();
        return;
    } 

    if (std.mem.eql(u8, args[1], "testQ1")) {
        std.debug.print("testing Q1 functionality\n", .{});
        if (args.len <= 3) {
            std.debug.print("ERROR: You must input, seed, test_cases, test_density\n", .{});
            return;
        }
        // TODO parse input to valid values for function
        return;
    } 

    if (std.mem.eql(u8, args[1], "testDistClasses")) {
        std.debug.print("Testing distribution classes\n", .{});
        try Test_DistributionsClasses();
        return;
    } 

    if (std.mem.eql(u8, args[1], "testTeamData")) {
        std.debug.print("Testing team data\n", .{});
        Test_TeamData();
        return;
    } 

    std.debug.print("You must input desired function to test, select testPoisson, testNormal or testQ1 to test general functions \n", .{});
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
}

fn Test_Q1(seed: f64, MAX_RUNS: c_int, MCS_SIZE: c_int) !void {
    const StdDev = (seed * 4) % 5;
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
        const poisson1 = dist.GetRandFromPoissonDistributionWithSeed(LAMBDA, rando.int(u64));
        const poisson2 = dist.GetRandFromPoissonDistributionWithSeed(LAMBDA, rando.int(u64));

        try writer.print("{d}, {d}\n", .{ poisson1, poisson2 });

        if (global.DEBUG_PRINT)
            std.debug.print("{x},", .{i});
    }

    file.close();

    return;
}

pub fn Test_DistributionsClasses() !void {    
    const currentWD = std.fs.cwd();

    const file = try currentWD.createFile("Data/TestNormalDistClass.csv", .{ .truncate = true });
    const writer = file.writer();
    try writer.print("Value1, Value2\n", .{});

    const MAX_RUNS: c_int = 1000;

    var allocator = std.heap.page_allocator;

    var normDist = try dist.CreateNormalDist(0.0, 1.0, allocator);
    defer allocator.destroy(normDist);

    for (0..MAX_RUNS) |_| {    
        const r1 = normDist.GetRandVal();
        const r2 = normDist.GetRandVal();
        try writer.print("{d}, {d}\n", .{ r1, r2 });        
    }

    file.close();
}

pub fn Test_TeamData() void {
    std.debug.print("Printing all team data...\n\n", .{});
    for (0..teamData.GetTeamCount()) |i| {
        const teamName = teamData.GetTeamName(i);
        const shots = teamData.GetShotCount(i);
        const saves = teamData.GetSavesCount(i);
        const shotsOnTarget = teamData.GetShotsOnTargetCount(i);

        std.debug.print("TeamName={s}, Shots={}, OnTarget={}, Saves={}\n\n", .{teamName, shots, shotsOnTarget, saves});
    }    
}