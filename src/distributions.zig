const std = @import("std");
const math = std.math;
const rand = std.Random;

const global = @import("global.zig"); 

const Distribution = struct {
    m_GetRandValFn: fn(*const anyopaque) f64,
    m_DistRef: anyopaque
};

const PoissonDist = struct {
    m_Rate: f64,

    pub fn GetRandVal(self: *const PoissonDist) f64 {
        return GetRandFromPoissonDistribution(self.m_Rate);
    }
};

const NormalDist = struct {
    m_Mean: f64,
    m_StdDev: f64,

    pub fn GetRandVal(self: *const NormalDist) f64 {
        return GetRandFromNormalDistributionSingle(self.m_Mean, self.m_StdDev);
    }
};

pub fn CreatePoissonDist(rate:f64) Distribution {
    var pois: PoissonDist = .{rate};
    const dist: Distribution = .{ pois.GetRandVal(), &pois};
    return dist;
}

pub fn CreateNormalDist(mean:f64, stdDev:f64) Distribution {
    var norm: NormalDist = .{mean, stdDev};
    const dist: Distribution = .{ norm.GetRandVal(), &norm};
    return dist;
}

//======================================================

pub fn GetRandFromNormalDistributionSingle(mean: f64, stdDev: f64) f64 {
    return GetRandFromNormalDistributionSingleWithSeed(mean, stdDev, global.GetTrueRandomSeed());
}

pub fn GetRandFromNormalDistributionSingleWithSeed(mean: f64, stdDev: f64, seed: c_int) f64 {
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

pub fn GetRandFromPoissonDistribution(lambda: f64) f64 {
    return GetRandFromPoissonDistribution(lambda, global.GetTrueRandomSeed());
}

pub fn GetRandFromPoissonDistributionWithSeed(lambda: f64, seed: c_int) f64 {
    var rng = rand.DefaultPrng.init(seed);
    var rando = rng.random();
    return -math.log(f64, 10, rando.float(f64)) / lambda;
}

pub fn ConvertRandToPoissonDistribution(lambda: f64, randVal: f64) f64 {
    return -math.log(f64, 10, randVal) / lambda;
}