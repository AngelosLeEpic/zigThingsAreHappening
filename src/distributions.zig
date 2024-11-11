const std = @import("std");
const math = std.math;

const global = @import("global.zig");

fn GetRandFromNormalDistribution(p: global.Point, mean: f64, stdDev: f64) global.Point {
    const xI = math.floor(p.x);
    const yI = math.floor(p.x);

    const x: f64 = p.x - xI;
    const y: f64 = p.y - yI;

    // https://en.wikipedia.org/wiki/Box%E2%80%93Muller_transform
    const logVal = math.log(f64, 10, x);
    const mag = stdDev * math.sqrt(-2 * logVal);
    const z0 = mag * math.cos(math.tau * y);
    const z1 = mag * math.sin(math.tau * y);

    if (global.DEBUG_PRINT)
        std.debug.print("RandNorm: x={d}, y={d}\n logVal={d}, mag={d}, z0={d}, z1={d}\n\n", .{ x, y, logVal, mag, z0, z1 });

    return global.Point{
        .x = z0 + mean,
        .y = z1 + mean,
    };
}