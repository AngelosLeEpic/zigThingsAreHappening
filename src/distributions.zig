const std = @import("std");
const math = std.math;
const rand = std.Random;

const global = @import("global.zig"); 

pub fn GetRandFromNormalDistributionSingle(mean: f64, stdDev: f64, seed: c_int) f64 {
    var rng = rand.DefaultPrng.init(seed);
    var rando = rng.random();

    var p = global.Point{ .x = rando.floatNorm(f64), .y = rando.floatNorm(f64) };

    const N = 4;
    for (0..N) |_| {            
        p = GetRandPointFromNormalDistribution(p, mean, stdDev);    
    }
 
    return p.x;
}

pub fn GetRandsFromNormalDistribution(N: c_int, mean: f64, stdDev: f64, seed: c_int) std.ArrayList(f64) {
    var rng = rand.DefaultPrng.init(seed);
    var rando = rng.random();

    var p = global.Point{ .x = rando.floatNorm(f64), .y = rando.floatNorm(f64) };

    var result: std.ArrayList(f64) = std.ArrayList(f64).init(std.testing.allocator);

    const Ndiv2 = N / 2;
    for (0..Ndiv2) |_| {            
        p = GetRandPointFromNormalDistribution(p, mean, stdDev);    
        result.append(p.x);
        result.append(p.y);
    }
 
    return result;
}

// https://en.wikipedia.org/wiki/Box%E2%80%93Muller_transform
pub fn GetRandPointFromNormalDistribution(p: global.Point, mean: f64, stdDev: f64) global.Point {
    const xI = math.floor(p.x);
    const yI = math.floor(p.x);

    const x: f64 = p.x - xI;
    const y: f64 = p.y - yI;
    
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

pub fn GetRandFromPoissonDistribution(lambda: f64, seed: c_int) f64 {
    var rng = rand.DefaultPrng.init(seed);
    var rando = rng.random();
    return -math.log(f64, 10, rando.float(f64)) / lambda;
}

pub fn ConvertRandToPoissonDistribution(lambda: f64, randVal: f64) f64 {
    return -math.log(f64, 10, randVal) / lambda;
}