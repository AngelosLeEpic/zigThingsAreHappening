const std = @import("std");
const math = std.math;
const rand = std.Random;

const utils = @import("main.zig");

pub fn simulateTemperatureChange(temp: f64, deltaTime: f64) f64 {
    return temp + utils.GetRandFromNormalDistribution(0, deltaTime);
}
