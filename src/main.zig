const std = @import("std");
const builtin = @import("builtin");
const math = std.math;
const rand = std.Random;

const dist = @import("distributions.zig");
const global = @import("global.zig");
const Q1 = @import("Q1_Temp_Sim.zig");
const zandas = @import("zandas.zig");
const plot = @import("plot.zig");
const ArrayList = std.ArrayList;
const os = std.os;
const Q2 = @import("Q2_Football_Sim.zig");

pub const std_options = .{ .log_level = .info };

pub fn main() !void {
    global.Init();

    if (global.IsReleaseMode()) {
        std.log.info("Running in Release mode", .{});
    } else std.log.info("Running in Debug mode", .{});

    const args = try std.process.argsAlloc(std.heap.page_allocator);
    const count: usize = args.len;

    if (count <= 1) {
        std.log.info("Not enough args to run any function", .{});
        std.log.info("Possible tests to invoke: testPoisson, testPoissonPDF, testPoisson1D, testQuantPoisson, testNormal, testNormal1D, testQ1, testQ2, testDistClasses, testQuant", .{});
        return;
    }

    if (std.mem.eql(u8, args[1], "testPoisson")) {
        std.log.info("testing poisson distribution functionality", .{});
        try Test_Poisson();
        return;
    }

    if (std.mem.eql(u8, args[1], "testPoissonPDF")) {
        std.log.info("Testing poisson distribution PDF functionality", .{});
        try Test_Poisson_PDF();
        return;
    }

    if (std.mem.eql(u8, args[1], "testNormal")) {
        std.log.info("testing normal distribution functinality", .{});
        try Test_GetRandFromNormalDistribution();
        return;
    }

    if (std.mem.eql(u8, args[1], "testQ1")) {
        try Test_Q1();
        return;
    }

    if (std.mem.eql(u8, args[1], "testDistClasses")) {
        std.log.info("Testing distribution classes", .{});
        try Test_DistributionsClasses();
        return;
    }

    if (std.mem.eql(u8, args[1], "testQ2")) {
        std.log.info("Testing Q2", .{});
        try Q2_Test();
        return;
    }

    if (std.mem.eql(u8, args[1], "testNormal1D")) {
        std.log.info("Testing normal 1D", .{});
        try Test_Normal_1D();
        return;
    }

    if (std.mem.eql(u8, args[1], "testQuant")) {
        std.log.info("Testing quantisation", .{});
        try Test_CSVQuantiser();
        return;
    }

    if (std.mem.eql(u8, args[1], "testQuant2D")) {
        std.debug.print("Testing quantisation 2D\n", .{});
        try Test_CSVQuantiser2D();
        return;
    }

    if (std.mem.eql(u8, args[1], "testPoisson1D")) {
        std.log.info("Testing poisson 1D", .{});
        try Test_Poisson_1D();
        return;
    }

    if (std.mem.eql(u8, args[1], "testQuantPoisson")) {
        std.log.info("Testing poisson quantisation", .{});
        try Test_CSVQuantiserPoisson();
        return;
    }

    std.log.info("You must input desired function to test: testPoisson, testPoissonPDF, testPoisson1D, testQuantPoisson, testNormal, testNormal1D, testQ1, testQ2, testDistClasses, testQuant", .{});
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

    const MAX_RUNS: usize = 10_000;
    for (0..MAX_RUNS) |i| {
        std.log.debug("px={},py={}", .{ p.x, p.y });

        p = dist.GetRandPointFromNormalDistribution(p, 0, 1);

        try writer.print("{d},{d}\n", .{ p.x, p.y });

        std.log.debug("{x},", .{i});
    }

    try create_graph_from_csv("TestNormal", "Data/normal_scatter_plot.svg", "Index", "Value");
}

fn Test_Q1() !void {
    const Q1Allocator = std.heap.page_allocator;
    var Results: ArrayList(Q1.Q1Results) = ArrayList(Q1.Q1Results).init(Q1Allocator);
    const TestDensity: u32 = 10000;
    const N: u32 = 10000;
    const StdDev: f32 = 2.3;

    for (0..N) |i| {
        std.debug.print("Running simulation {}\n", .{i});
        try Results.append(Q1.simulateQ1(TestDensity, StdDev));
    }

    std.log.debug("tests run fine, writting results of Q1", .{});

    const currentWD = std.fs.cwd();
    const file = try currentWD.createFile("Data/Q1.csv", .{ .truncate = true });
    defer file.close();
    const writer = file.writer();
    std.log.debug("created file for writting", .{});

    try writer.print("Porpotion,MaxTemp\n", .{});

    for (Results.items) |dataOut| {
        // try writer.print("{f32},{f32} \n", .dataOut.porpotion, dataOut.maxTemp);
        try writer.print("{d},{d}\n", .{ dataOut.porpotion, dataOut.maxTemp });
    }
    try create_graph_from_csv("Q1", "Data/q1_scatter_plot.svg", "Porpotion", "MaxTemp");
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

    const MAX_RUNS: usize = 10_000;
    for (0..MAX_RUNS) |i| {
        const poisson1 = dist.GetRandFromPoissonDistributionWithSeed(LAMBDA, rando.int(u64));
        const poisson2 = dist.GetRandFromPoissonDistributionWithSeed(LAMBDA, rando.int(u64));

        try writer.print("{d},{d}\n", .{ poisson1, poisson2 });

        std.log.debug("{x},", .{i});
    }

    try create_graph_from_csv("TestPoisson", "Data/poisson_scatter_plot.svg", "Val1", "Val2");
}

pub fn Test_DistributionsClasses() !void {
    const currentWD = std.fs.cwd();

    const file = try currentWD.createFile("Data/TestNormalDistClass.csv", .{ .truncate = true });
    defer file.close();
    const writer = file.writer();
    try writer.print("Value1,Value2\n", .{});

    const MAX_RUNS: usize = 10_000;

    var allocator = std.heap.page_allocator;

    var normDist = try dist.CreateNormalDist(0.0, 1.0, allocator);
    defer allocator.destroy(normDist);

    for (0..MAX_RUNS) |_| {
        const r1 = normDist.GetRandVal();
        const r2 = normDist.GetRandVal();
        try writer.print("{d},{d}\n", .{ r1, r2 });
    }
}

pub fn create_graph_from_csv(test_name: []const u8, output_file: []const u8, col_1: []const u8, col_2: []const u8) !void {
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

    const x = df.get(col_1).?.float.items;
    const y = df.get(col_2).?.float.items;

    try plot.scatter_plot(x, y, output_file, allocator);
}

pub fn Q2_Test() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }
    const allocator = gpa.allocator();

    const n_sims: usize = 1_000;
    const output = try Q2.run_simulation("Data/database.csv", allocator, n_sims);
    defer {
        for (output.items, 0..) |_, i| {
            allocator.free(output.items[i]);
        }
        output.deinit();
    }

    const out_file = std.io.getStdOut();
    for (0..20) |i| {
        const team: []const u8 = output.items[i];
        const rank = i + 1;
        try out_file.writer().print("Position: {d}:\t{s}\n", .{ rank, team });
    }
}

pub fn create_stem_graph_from_csv(csv_path: []const u8, output_file: []const u8, col_1: []const u8, col_2: []const u8) !void {
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

    const x = df.get(col_1).?.float.items;
    const y = df.get(col_2).?.float.items;

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

    try create_graph_from_csv("TestPoissonPDF", "Data/PoissonPDF_Scatter.svg", "Lambda", "Val");
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

    const MAX_RUNS: usize = 10_000;
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

    const MAX_RUNS: usize = 10_000;
    for (0..MAX_RUNS) |_| {
        const poisson = dist.GetRandFromPoissonDistribution(LAMBDA);

        try writer.print("{d}\n", .{poisson});
    }
}

pub fn Test_CSVQuantiser() !void {
    const quant = @import("csvQuantiser.zig");
    try quant.QuantiseCSV("Data/TestNormal1D.csv", "Data/TestNormal1DQuant.csv", 100, -4.0, 4.0);
    try create_stem_graph_from_csv("Data/TestNormal1DQuant.csv", "Data/Normal1DQuant.svg", "Val", "Freq");
}

pub fn Test_CSVQuantiserPoisson() !void {
    const quant = @import("csvQuantiser.zig");
    try quant.QuantiseCSV("Data/TestPoisson1D.csv", "Data/TestPoisson1DQuant.csv", 100, 0.1, 2.0);
    try create_stem_graph_from_csv("Data/TestPoisson1DQuant.csv", "Data/Poisson1DQuant.svg", "Val", "Freq");
}

pub fn Test_CSVQuantiser2D() !void {
    const quant = @import("csvQuantiser.zig");
    try quant.QuantiseCSV2D("Data/Q1.csv", "Data/P_Quant.csv", "Data/TMax_Quant.csv", 1000, 0.0, 1.0, 0.0, 2000.0);
    try create_stem_graph_from_csv("Data/P_Quant.csv", "Data/P.svg", "Val", "Freq");
    try create_stem_graph_from_csv("Data/TMax_Quant.csv", "Data/TMax.svg", "Val", "Freq");
}
