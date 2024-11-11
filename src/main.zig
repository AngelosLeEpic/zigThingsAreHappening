const std = @import("std");
const math = std.math;
const rand = std.Random;

const Point = struct { x: f64, y: f64 };

pub fn main() !void {
    var rng = rand.DefaultPrng.init(123456789);
    var rando = rng.random();
    var p = Point{ .x = rando.floatNorm(f64), .y = rando.floatNorm(f64) };

    const currentWD = std.fs.cwd();
    // std.debug.print("CWD: {}\n", .{currentWD.p});

    const file = try currentWD.createFile("Data/TestNormal.csv", .{ .truncate = true });
    const writer = file.writer();
    try writer.print("Index, Value\n", .{});

    const MAX_RUNS: c_int = 10000;
    for (0..MAX_RUNS) |i| {
        //std.debug.print("px={}, py={}\n", .{ p.x, p.y });
        p = GetRandFromNormalDistribution(p, 0, 1);

        try writer.print("{d}, {d}\n", .{ p.x, p.y });
        //try writer.print("{d}, {d}\n", .{ i, p.x });
        //try writer.print("{d}, {d}\n", .{ i, p.y });

        std.debug.print("{x}\n", .{i});
    }

    file.close();

    return;
}

fn GetRandFromNormalDistribution(p: Point, mean: f64, stdDev: f64) Point {
    const xI = math.floor(p.x);
    const yI = math.floor(p.x);

    const x: f64 = p.x - xI;
    const y: f64 = p.y - yI;

    // https://en.wikipedia.org/wiki/Box%E2%80%93Muller_transform
    const logVal = math.log(f64, 10, x);
    const mag = stdDev * math.sqrt(-2 * logVal);
    const z0 = mag * math.cos(math.tau * y);
    const z1 = mag * math.sin(math.tau * y);

    //std.debug.print("RandNorm: x={d}, y={d}\n logVal={d}, mag={d}, z0={d}, z1={d}\n\n", .{ x, y, logVal, mag, z0, z1 });

    return Point{
        .x = z0 + mean,
        .y = z1 + mean,
    };
}
