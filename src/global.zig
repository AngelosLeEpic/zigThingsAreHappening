const std = @import("std");
const math = std.math;
const rand = std.Random;

pub const DEBUG_PRINT: bool = false;

pub const Point = struct { x: f64, y: f64 };

var g_PermaRNG_XOshiro: rand.Xoshiro256 = undefined;
var g_PermaRNG: rand = undefined;

pub fn InitRNG() void {
    const seed: i64 = std.time.milliTimestamp();
    const useed: u64 = @intCast(seed);
    g_PermaRNG_XOshiro = rand.DefaultPrng.init(useed);
    g_PermaRNG = g_PermaRNG_XOshiro.random();
}

pub fn GetTrueRandomU64() u64 {
    return g_PermaRNG.int(u64);
}

pub fn GetTrueRandomF64Norm() f64 {
    return g_PermaRNG.floatNorm(f64);
}