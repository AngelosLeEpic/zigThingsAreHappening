const std = @import("std");
const math = std.math;
const rand = std.Random;
const ArrayList = std.ArrayList;

const utils = @import("distributions.zig");

pub const Q1Results = struct {
    var porpotion = 0;
    var maxTemp: f64 = 0;
};

// Simulates just one change in the temperature for running the monte carlo simulations
pub fn simulateTemperatureChange(temp: f64, deltaTime: f64, seed: f64) f64 {
    return temp + utils.GetRandFromNormalDistribution(seed + 1, seed - 1, 0, deltaTime);
}

//runs a single monte carlo simulation for Q1, the temperature is changed a total of N times
// N can be said to represent the depth of that simulation
// returns the porpotion and MaxTemperature seen
pub fn simulateQ1(N: c_int, deltaTime: f64, seed: f64) Q1Results {
    var count: c_int = 0;
    var maxTemp = -999999.0;
    var temp: f64 = 0;

    var aboveZero = 0;
    seed = seed * std.time.milliTimestamp();
    while (count < N) {
        temp = simulateTemperatureChange(temp, deltaTime, seed * count);
        if (temp > 0) {
            aboveZero += 1;
        }
        if (temp > maxTemp) {
            maxTemp = temp;
        }
        count += 1;
    }

    const out: Q1Results = {
        .porpotion == aboveZero / N;
        .maxTempL == maxTemp;
    };
    return out;
}
