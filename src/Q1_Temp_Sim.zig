const std = @import("std");
const math = std.math;
const rand = std.Random;
const ArrayList = std.ArrayList;

const utils = @import("distributions.zig");

pub const Q1Results = struct {
    porpotion: f64 = 0.0,
    maxTemp: f64 = 0.0,
};

// Simulates just one change in the temperature for running the monte carlo simulations
pub fn simulateTemperatureChange(temp: f64, deltaTime: f64, seed: f64) f64 {
    return temp + utils.GetRandFromNormalDistributionSingleWithSeed(0, deltaTime, @as(u64, @intFromFloat(seed)));
}

//runs a single monte carlo simulation for Q1, the temperature is changed a total of N times
// N can be said to represent the depth of that simulation
// returns the porpotion and MaxTemperature seen
pub fn simulateQ1(N: i64, deltaTime: f64, seed: i64) Q1Results {
    var count: i64 = 0;
    var maxTemp: f64 = -999999.0;
    var temp: f64 = 0;

    var aboveZero: i64 = 0;
    var floatSeed: f64 = @floatFromInt(seed);
    floatSeed = floatSeed * @as(f64, @floatFromInt(std.time.milliTimestamp()));
    while (count < N) {
        temp = simulateTemperatureChange(temp, deltaTime, floatSeed * @as(f64, @floatFromInt(count)));
        if (temp > 0) {
            aboveZero += 1;
        }
        if (temp > maxTemp) {
            maxTemp = temp;
        }
        count += 1;
    }
    const finalPorpotion: f64 = @as(f64, @floatFromInt(aboveZero)) / @as(f64, @floatFromInt(N));

    const result = Q1Results{ .porpotion = finalPorpotion, .maxTemp = maxTemp };
    return result;
}
