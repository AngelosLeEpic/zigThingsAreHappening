const std = @import("std");
const builtin = @import("builtin");
const math = std.math;
const rand = std.Random;

const dist = @import("distributions.zig");
const global = @import("global.zig");
const teamData = @import("teamData.zig");
const Q1 = @import("Q1_Temp_Sim.zig");
const ArrayList = std.ArrayList;
const os = std.os;

pub fn main() !void {
    global.Init();
    try teamData.InitData();

    if (global.IsReleaseMode()) {
        std.debug.print("Running in Release mode\n", .{});
    } else std.debug.print("Running in Debug mode\n", .{});

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
        try Test_Q1();
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
    // writing data
    var rng = rand.DefaultPrng.init(123456789);
    var rando = rng.random();
    var p = global.Point{ .x = rando.floatNorm(f64), .y = rando.floatNorm(f64) };

    const currentWD = std.fs.cwd();

    const file = try currentWD.createFile("Data/TestNormal.csv", .{ .truncate = true });
    defer file.close();
    const writer = file.writer();
    try writer.print("Index,Value\n", .{});

    const MAX_RUNS: c_int = 10000;
    for (0..MAX_RUNS) |i| {
        if (global.DEBUG_PRINT)
            std.debug.print("px={},py={}\n", .{ p.x, p.y });


        p = dist.GetRandPointFromNormalDistribution(p, 0, 1);

        try writer.print("{d},{d}\n", .{ p.x, p.y });
        //try writer.print("{d}, {d}\n", .{ i, p.x });
        //try writer.print("{d}, {d}\n", .{ i, p.y });

        if (global.DEBUG_PRINT)
            std.debug.print("{x},", .{i});
    }

    try create_graph_from_csv("TestNormal");
}

fn Test_Q1() !void {
    const Q1Allocator = std.heap.page_allocator;
    var Results: ArrayList(Q1.Q1Results) = ArrayList(Q1.Q1Results).init(Q1Allocator);
    const TestDensity: u32 = 1000;
    const N: u32 = 100;
    const StdDev: f64 = 2.3;

    for (0..N) |x| {
        std.debug.print("performing test: {}\n", .{x});
        try Results.append(Q1.simulateQ1(TestDensity, StdDev));
    }

    // results stored in arrays, writting results
    // not sure how to write results, should each MCS get its own file? This would result into 1000 csv files
    // but if I keep it all in one file, how will I sort this to seperate each run of the simulation?
    // TODO

    std.debug.print("tests run fine, writting results of Q1\n", .{});

    const currentWD = std.fs.cwd();
    const file = try currentWD.createFile("Data/Q1.csv", .{ .truncate = true });
    defer file.close();
    const writer = file.writer();
    std.debug.print("created file for writting\n", .{});

    try writer.print("Porpotion,MaxTemp\n", .{});

    for (Results.items) |dataOut| {
        // try writer.print("{f64},{f64} \n", .dataOut.porpotion, dataOut.maxTemp);
        try writer.print("{d},{d}\n", .{ dataOut.porpotion, dataOut.maxTemp });
    }
}

fn Test_Poisson() !void {
    var rng = rand.DefaultPrng.init(123456789);
    var rando = rng.random();

    const LAMBDA: f64 = 1;

    const currentWD = std.fs.cwd();

    const file = try currentWD.createFile("Data/TestPoisson.csv", .{ .truncate = true });
    defer file.close();
    const writer = file.writer();
    try writer.print("Val1,Val2\n", .{});

    const MAX_RUNS: c_int = 10000;
    for (0..MAX_RUNS) |i| {
        const poisson1 = dist.GetRandFromPoissonDistributionWithSeed(LAMBDA, rando.int(u64));
        const poisson2 = dist.GetRandFromPoissonDistributionWithSeed(LAMBDA, rando.int(u64));

        try writer.print("{d},{d}\n", .{ poisson1, poisson2 });

        if (global.DEBUG_PRINT)
            std.debug.print("{x},", .{i});
    }

    try create_graph_from_csv("TestPoisson");
}

pub fn Test_DistributionsClasses() !void {
    const currentWD = std.fs.cwd();

    const file = try currentWD.createFile("Data/TestNormalDistClass.csv", .{ .truncate = true });
    defer file.close();
    const writer = file.writer();
    try writer.print("Value1,Value2\n", .{});

    const MAX_RUNS: c_int = 1000;

    var allocator = std.heap.page_allocator;

    var normDist = try dist.CreateNormalDist(0.0, 1.0, allocator);
    defer allocator.destroy(normDist);

    for (0..MAX_RUNS) |_| {
        const r1 = normDist.GetRandVal();
        const r2 = normDist.GetRandVal();
        try writer.print("{d},{d}\n", .{ r1, r2 });
    }
}

pub fn Test_TeamData() void {
    std.debug.print("Printing all team data...\n\n", .{});
    for (0..teamData.GetTeamCount()) |i| {
        const teamName = teamData.GetTeamName(i);
        const shots = teamData.GetShotCount(i);
        const saves = teamData.GetSavesCount(i);
        const shotsOnTarget = teamData.GetShotsOnTargetCount(i);

        std.debug.print("TeamName={s}, Shots={}, OnTarget={}, Saves={}\n\n", .{ teamName, shots, shotsOnTarget, saves });
    }
}

pub fn create_graph_from_csv(test_name: []const u8) !void {
    const zandas = @import("zandas.zig");
    const plot = @import("plot.zig");    

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }
    const allocator = gpa.allocator();

    var file_name = std.ArrayList(u8).init(allocator);
    defer file_name.deinit();
    try file_name.writer().print("Data/{s}.csv", .{test_name});

    // reading data
    var df = try zandas.csv_to_df(f32, file_name.items, allocator);
    defer df.deinit();

    // plotting data

    const x = df.get_col(0).items;
    const y = df.get_col(1).items;

    try plot.scatter_plot(x, y, allocator);
}
