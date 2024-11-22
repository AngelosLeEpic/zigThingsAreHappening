
const std = @import("std");
const builtin = @import("builtin");
const math = std.math;
const rand = std.Random;

// TODO: RENAME THIS FILE TO UTILS

pub const DEBUG_PRINT: bool = false;

pub const Point = struct { x: f64, y: f64 };

var g_PermaRNG_XOshiro: rand.Xoshiro256 = undefined;
var g_PermaRNG: rand = undefined;

var g_isReleaseMode: bool = undefined;
var g_initialised: bool = false;

pub fn Init() void {

    const releaseMode = builtin.mode;
    g_isReleaseMode = switch (releaseMode) {
        .Debug => false,
        .ReleaseFast => true,
        .ReleaseSafe => true,
        .ReleaseSmall => true
    };

    const seed: i64 = std.time.milliTimestamp();
    const useed: u64 = @intCast(seed);
    g_PermaRNG_XOshiro = rand.DefaultPrng.init(useed);
    g_PermaRNG = g_PermaRNG_XOshiro.random();
}

pub fn IsReleaseMode() bool {
    return g_isReleaseMode;
}

pub fn GetTrueRandomU64() u64 {
    return g_PermaRNG.int(u64);
}

pub fn GetTrueRandomF64Norm() f64 {
    return g_PermaRNG.floatNorm(f64);
}
