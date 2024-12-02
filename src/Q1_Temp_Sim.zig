const std = @import("std");
const math = std.math;
const rand = std.Random;
const ArrayList = std.ArrayList;

const utils = @import("distributions.zig");

pub const Q1Results = struct {
    porpotion: f32 = 0.0,
    maxTemp: f32 = 0.0,
};

// Simulates just one change in the temperature for running the monte carlo simulations
pub fn simulateTemperatureChange(temp: f32, deltaTime: f32) f32 {
    return temp + utils.GetRandFromNormalDistributionSingle(0, deltaTime);
}

//runs a single monte carlo simulation for Q1, the temperature is changed a total of N times
// N can be said to represent the depth of that simulation
// returns the porpotion and MaxTemperature seen
pub fn simulateQ1(N: i64, deltaTime: f32) Q1Results {
    var count: i64 = 0;
    var maxTemp: f32 = -9999999999999.0;
    var temp: f32 = 0;

    var aboveZero: i64 = 0;
    while (count < N) {
        temp = simulateTemperatureChange(temp, deltaTime);

        if (temp > 0) {
            aboveZero += 1;
        }
        if (temp > maxTemp) {
            maxTemp = temp;
        }
        count += 1;
    }
    const finalPorpotion: f32 = @as(f32, @floatFromInt(aboveZero)) / @as(f32, @floatFromInt(N));
    std.debug.print("Test complete, maxTemp: {}, porpostion: {}\n", .{ maxTemp, aboveZero });

    const result = Q1Results{ .porpotion = finalPorpotion, .maxTemp = maxTemp };
    return result;
}
