const std = @import("std");
const Math = std.math;

pub fn main() void {
    const rng = std.rand.DefaultPrng.init(123456789);
    var p: point = point{ .x = rng.nextf64 % 1, .y = rng.nextf64 % 1 };

    while (true) {
        std.debug.print("{}\n{}\n", .{ p.x, p.y });
        p = GetRandFromNormalDistribution(p, 0, 1);
    }

    return;
}

const point = struct {
    var x: f64 = 0;
    var y: f64 = 0;
};

fn GetRandFromNormalDistribution(p: point, mean: f64, stdDev: f64) point {
    const x: f64 = p.x % 1;
    const y: f64 = p.y % 1;

    // https://en.wikipedia.org/wiki/Box%E2%80%93Muller_transform
    const z0 = std.math.sqrt(-2 * std.math.log(x)) * std.math.cos(2 * std.math.pi * y);
    const z1 = std.math.sqrt(-2 * std.math.log(x)) * std.math.sin(2 * std.math.pi * y);

    return point{
        .x = z0 * stdDev + mean,
        .y = z1 * stdDev + mean,
    };
}
