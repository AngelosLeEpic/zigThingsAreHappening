const std = @import("std");
const math = std.math;
const rand = std.Random;

pub const DEBUG_PRINT: bool = false;

pub const Point = struct { x: f64, y: f64 };

pub fn GetTrueRandomSeed() i64 {
    return std.time.milliTimeStamp();    
}

pub fn GetTrueRandomFloat() f64 {
    var rng = rand.DefaultPrng.init(GetTrueRandomSeed());
    var rando = rng.random();
    return rando.floatNorm(f64);
}