const std = @import("std");
const math = std.math;
const rand = std.Random;

const global = @import("global.zig");

const DistributionType = enum { NORMAL, POISSON, UNIFORM };

const Distribution = struct {
    // NORMAL
    m_Mean: f64 = 0.0,
    m_StdDev: f64 = 0.0,

    // POISSON
    m_Rate: f64 = 0.0,

    // UNIFORM
    m_IntervalMin: f64 = 0.0,
    m_IntervalMax: f64 = 1.0,

    m_Type: DistributionType,

    pub fn GetRandVal(this: *const Distribution) f64 {
        if (this.m_Type == DistributionType.NORMAL)
            return GetRandFromNormalDistributionSingle(this.m_Mean, this.m_StdDev);

        if (this.m_Type == DistributionType.POISSON)
            return GetRandFromPoissonDistribution(this.m_Rate);

        if (this.m_Type == DistributionType.UNIFORM)
            return GetRandFromUnifromDistributionSingle(this.m_IntervalMin, this.m_IntervalMax);

        return -1;
    }
};

pub fn CreateNormalDist(mean: f64, stdDev: f64, allocator: std.mem.Allocator) !*Distribution {
    var dist = try allocator.create(Distribution);
    dist.m_Mean = mean;
    dist.m_StdDev = stdDev;
    dist.m_Type = DistributionType.NORMAL;
    return dist;
}

pub fn CreatePoissonDist(rate: f64, allocator: std.mem.Allocator) !*Distribution {
    var dist = try allocator.create(Distribution);
    dist.m_Rate = rate;
    dist.m_Type = DistributionType.POISSON;
    return dist;
}

pub fn CreateUniformDist(intervalMin: f64, intervalMax: f64, allocator: std.mem.Allocator) !*Distribution {
    var dist = try allocator.create(Distribution);
    dist.m_IntervalMin = intervalMin;
    dist.m_IntervalMax = intervalMax;
    dist.m_Type = DistributionType.UNIFORM;
    return dist;
}

//======================================================

pub fn GetRandFromUnifromDistributionSingle(min: f64, max: f64) f64 {
    return GetRandFromUnifromDistributionSingleWithSeed(min, max, global.GetTrueRandomU64());
}

pub fn GetRandFromUnifromDistributionSingleWithSeed(min: f64, max: f64, seed: u64) f64 {
    const intervalRange: f64 = max - min;
    var rng = rand.DefaultPrng.init(seed);
    var rando = rng.random();

    const randUnif = rando.floatNorm(f64);
    return randUnif * intervalRange + min;
}

pub fn GetRandFromNormalDistributionSingle(mean: f64, stdDev: f64) f64 {
    return GetRandFromNormalDistributionSingleWithSeed(mean, stdDev, global.GetTrueRandomU64());
}

pub fn GetRandFromNormalDistributionSingleWithSeed(mean: f64, stdDev: f64, seed: u64) f64 {
    var rng = rand.DefaultPrng.init(seed);
    var rando = rng.random();

    var p = global.Point{ .x = rando.floatNorm(f64), .y = rando.floatNorm(f64) };

    const N = 4;
    for (0..N) |_| {
        p = GetRandPointFromNormalDistribution(p, mean, stdDev);
    }

    return p.x;
}

pub fn GetRandsFromNormalDistribution(N: i64, mean: f64, stdDev: f64, seed: u64) std.ArrayList(f64) {
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

pub fn GetRandFromPoissonDistribution(lambda: f64) f64 {
    return GetRandFromPoissonDistributionWithSeed(lambda, global.GetTrueRandomU64());
}

pub fn GetRandFromPoissonDistributionWithSeed(lambda: f64, seed: u64) f64 {
    var rng = rand.DefaultPrng.init(seed);
    var rando = rng.random();
    return -math.log(f64, 10, rando.float(f64)) / lambda;
}

pub fn ConvertRandToPoissonDistribution(lambda: f64, randVal: u64) f64 {
    return -math.log(f64, 10, randVal) / lambda;
}
<<<<<<< HEAD
=======

pub fn RandSuccessChance(chance: f64) bool {
    return global.GetTrueRandomF64Norm() <= chance;
}
>>>>>>> 1b457edf87110566fe91c48dea6bba6a6274847b
