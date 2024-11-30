const std = @import("std");
const builtin = @import("builtin");
const math = std.math;
const rand = std.Random;

const dist = @import("distributions.zig");
const global = @import("global.zig");
// const teamData = @import("teamData.zig");
const Q1 = @import("Q1_Temp_Sim.zig");
const zandas = @import("zandas.zig");
const plot = @import("plot.zig");
const ArrayList = std.ArrayList;
const os = std.os;
const Q2 = @import("Q2_Football_Sim.zig");

pub fn main() !void {
    global.Init();
    // try teamData.InitData();

    if (global.IsReleaseMode()) {
        std.debug.print("Running in Release mode\n", .{});
    } else std.debug.print("Running in Debug mode\n", .{});

    const args = try std.process.argsAlloc(std.heap.page_allocator);
    const count: usize = args.len;

    std.log.debug("going inside testing()", .{});

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

    if (std.mem.eql(u8, args[1], "testPoissonPDF")) {
        std.debug.print("Testing poisson distribution PDF functionality\n", .{});
        try Test_Poisson_PDF();
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

    // if (std.mem.eql(u8, args[1], "testTeamData")) {
    // std.debug.print("Testing team data\n", .{});
    // Test_TeamData();
    // return;
    // }

    if (std.mem.eql(u8, args[1], "testQ2")) {
        std.debug.print("Testing Q2\n", .{});
        try Q2_Test();
    }

    if (std.mem.eql(u8, args[1], "testNormal1D")) {
        std.debug.print("Testing normal 1D\n", .{});
        try Test_Normal_1D();
        return;
    }

    if (std.mem.eql(u8, args[1], "testQuant")) {
        std.debug.print("Testing quantisation\n", .{});
        try Test_CSVQuantiser();
        return;
    }

    if (std.mem.eql(u8, args[1], "testPoisson1D")) {
        std.debug.print("Testing poisson 1D\n", .{});
        try Test_Poisson_1D();
        return;
    }

    if (std.mem.eql(u8, args[1], "testQuantPoisson")) {
        std.debug.print("Testing poisson quantisation\n", .{});
        try Test_CSVQuantiserPoisson();
        return;
    }

    std.debug.print("You must input desired function to test, select testPoisson, testNormal or testQ1 to test general functions \n", .{});
}

fn Test_GetRandFromNormalDistribution() !void {
    std.log.debug("a", .{});
    // writing data
    var rng = rand.DefaultPrng.init(123456789);
    var rando = rng.random();
    var p = global.Point{ .x = rando.floatNorm(f32), .y = rando.floatNorm(f32) };

    const currentWD = std.fs.cwd();

    const file = try currentWD.createFile("Data/TestNormal.csv", .{ .truncate = true });
    defer file.close();
    const writer = file.writer();
    try writer.print("Index,Value\n", .{});

    const MAX_RUNS: c_int = 10_000;
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

    try create_graph_from_csv("TestNormal", "Data/normal_scatter_plot.svg");
}

fn Test_Q1() !void {
    const Q1Allocator = std.heap.page_allocator;
    var Results: ArrayList(Q1.Q1Results) = ArrayList(Q1.Q1Results).init(Q1Allocator);
    const TestDensity: u32 = 1_000_000;
    const N: u32 = 100;
    const StdDev: f32 = 2.3;

    for (0..N) |_| {
        try Results.append(Q1.simulateQ1(TestDensity, StdDev));
    }

    std.debug.print("tests run fine, writting results of Q1\n", .{});

    const currentWD = std.fs.cwd();
    const file = try currentWD.createFile("Data/Q1.csv", .{ .truncate = true });
    defer file.close();
    const writer = file.writer();
    std.debug.print("created file for writting\n", .{});

    try writer.print("Porpotion,MaxTemp\n", .{});

    for (Results.items) |dataOut| {
        // try writer.print("{f32},{f32} \n", .dataOut.porpotion, dataOut.maxTemp);
        try writer.print("{d},{d}\n", .{ dataOut.porpotion, dataOut.maxTemp });
    }
    try create_graph_from_csv("Q1", "Data/q1_scatter_plot.svg");
}

fn Test_Poisson() !void {
    var rng = rand.DefaultPrng.init(123456789);
    var rando = rng.random();

    const LAMBDA: f32 = 1;

    const currentWD = std.fs.cwd();

    const file = try currentWD.createFile("Data/TestPoisson.csv", .{ .truncate = true });
    defer file.close();
    const writer = file.writer();
    try writer.print("Val1,Val2\n", .{});

    const MAX_RUNS: usize = 1_000_000;
    for (0..MAX_RUNS) |i| {
        const poisson1 = dist.GetRandFromPoissonDistributionWithSeed(LAMBDA, rando.int(u64));
        const poisson2 = dist.GetRandFromPoissonDistributionWithSeed(LAMBDA, rando.int(u64));

        try writer.print("{d},{d}\n", .{ poisson1, poisson2 });

        if (global.DEBUG_PRINT)
            std.debug.print("{x},", .{i});
    }

    try create_graph_from_csv("TestPoisson", "Data/poisson_scatter_plot.svg");
}

pub fn Test_DistributionsClasses() !void {
    const currentWD = std.fs.cwd();

    const file = try currentWD.createFile("Data/TestNormalDistClass.csv", .{ .truncate = true });
    defer file.close();
    const writer = file.writer();
    try writer.print("Value1,Value2\n", .{});

    const MAX_RUNS: usize = 1_000_000;

    var allocator = std.heap.page_allocator;

    var normDist = try dist.CreateNormalDist(0.0, 1.0, allocator);
    defer allocator.destroy(normDist);

    for (0..MAX_RUNS) |_| {
        const r1 = normDist.GetRandVal();
        const r2 = normDist.GetRandVal();
        try writer.print("{d},{d}\n", .{ r1, r2 });
    }
}

// pub fn Test_TeamData() void {
//     std.debug.print("Printing all team data...\n\n", .{});
//     for (0..teamData.GetTeamCount()) |i| {
//         const teamName = teamData.GetTeamName(i);
//         const shots = teamData.GetShotCount(i);
//         const saves = teamData.GetSavesCount(i);
//         const shotsOnTarget = teamData.GetShotsOnTargetCount(i);
//
//         std.debug.print("TeamName={s}, Shots={}, OnTarget={}, Saves={}\n\n", .{ teamName, shots, shotsOnTarget, saves });
//     }
// }

pub fn create_graph_from_csv(test_name: []const u8, output_file: []const u8) !void {
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
    var df = try zandas.csv_to_df(file_name.items, allocator);
    defer df.deinit();

    // plotting data

    const x = df.get("Index").?.float.items;
    const y = df.get("Value").?.float.items;

    try plot.scatter_plot(x, y, output_file, allocator);
}

pub fn Q2_Test() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }
    const allocator = gpa.allocator();

    const n_sims: usize = 1000;
    const output = try Q2.run_simulation("Data/database.csv", allocator, n_sims);
    defer {
        for (output.items, 0..) |_, i| {
            allocator.free(output.items[i]);
        }
        output.deinit();
    }

    for (0..20) |i| {
        const string: []const u8 = output.items[i];
        std.debug.print("{s}\n", .{string});
    }
}

pub fn create_stem_graph_from_csv(csv_path: []const u8, output_file: []const u8) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }
    const allocator = gpa.allocator();

    var file_name = std.ArrayList(u8).init(allocator);
    defer file_name.deinit();
    try file_name.writer().print("{s}", .{csv_path});

    // reading data
    var df = try zandas.csv_to_df(file_name.items, allocator);
    defer df.deinit();

    // plotting data

    const x = df.get("Val").?.float.items;
    const y = df.get("Freq").?.float.items;

    try plot.stem_plot(x, y, output_file, allocator);
}

// X - Lambda
// Y - PoissonVal(X)
pub fn Test_Poisson_PDF() !void {
    const currentWD = std.fs.cwd();

    const file = try currentWD.createFile("Data/TestPoissonPDF.csv", .{ .truncate = true });
    defer file.close();
    const writer = file.writer();
    try writer.print("Lambda,Val\n", .{});

    const LAMBDA_COUNT: i32 = 100;
    const MAX_RUNS: i32 = 100;
    for (1..LAMBDA_COUNT) |lambda| {
        const lambdaf32: f32 = @floatFromInt(lambda);
        for (0..MAX_RUNS) |_| {
            const poisson = dist.GetRandFromPoissonDistribution(lambdaf32);
            try writer.print("{d},{d}\n", .{ lambdaf32, poisson });
        }
    }

    try create_graph_from_csv("TestPoissonPDF", "Data/PoissonPDF_Scatter.svg");
}

pub fn Test_Normal_1D() !void {
    var rng = rand.DefaultPrng.init(global.GetTrueRandomU64());
    var rando = rng.random();
    var p = global.Point{ .x = rando.floatNorm(f32), .y = rando.floatNorm(f32) };

    const currentWD = std.fs.cwd();

    const file = try currentWD.createFile("Data/TestNormal1D.csv", .{ .truncate = true });
    defer file.close();
    const writer = file.writer();
    try writer.print("Value\n", .{});

    const MAX_RUNS: c_int = 5000;
    for (0..MAX_RUNS) |_| {
        p = dist.GetRandPointFromNormalDistribution(p, 0, 1);
        try writer.print("{d}\n", .{p.x});
        try writer.print("{d}\n", .{p.y});
    }
}

pub fn Test_Poisson_1D() !void {
    const LAMBDA: f32 = 5;

    const currentWD = std.fs.cwd();

    const file = try currentWD.createFile("Data/TestPoisson1D.csv", .{ .truncate = true });
    defer file.close();
    const writer = file.writer();
    try writer.print("Val\n", .{});

    const MAX_RUNS: c_int = 10000;
    for (0..MAX_RUNS) |_| {
        const poisson = dist.GetRandFromPoissonDistribution(LAMBDA);

        try writer.print("{d}\n", .{poisson});
    }
}

pub fn Test_CSVQuantiser() !void {
    const quant = @import("csvQuantiser.zig");
    try quant.QuantiseCSV("Data/TestNormal1D.csv", "Data/TestNormal1DQuant.csv", 100, -4.0, 4.0);
    try create_stem_graph_from_csv("Data/TestNormal1DQuant.csv", "Data/Normal1DQuant.svg");
}

pub fn Test_CSVQuantiserPoisson() !void {
    const quant = @import("csvQuantiser.zig");
    try quant.QuantiseCSV("Data/TestPoisson1D.csv", "Data/TestPoisson1DQuant.csv", 100, 0.1, 2.0);
    try create_stem_graph_from_csv("Data/TestPoisson1DQuant.csv", "Data/Poisson1DQuant.svg");
}
