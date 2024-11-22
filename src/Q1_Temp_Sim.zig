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
pub fn simulateTemperatureChange(temp: f64, deltaTime: f64) f64 {
    return temp + utils.GetRandFromNormalDistributionSingle(0, deltaTime);
}

//runs a single monte carlo simulation for Q1, the temperature is changed a total of N times
// N can be said to represent the depth of that simulation
// returns the porpotion and MaxTemperature seen
pub fn simulateQ1(N: i64, deltaTime: f64) Q1Results {
    std.debug.print("performing Q1 simulation\n", .{});
    var count: i64 = 0;
    var maxTemp: f64 = -9999999999999.0;
    var temp: f64 = 0;

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
    const finalPorpotion: f64 = @as(f64, @floatFromInt(aboveZero)) / @as(f64, @floatFromInt(N));
    std.debug.print("Test complete, maxTemp: {}, porpostion: {}\n", .{ maxTemp, aboveZero });

    const result = Q1Results{ .porpotion = finalPorpotion, .maxTemp = maxTemp };
    return result;
}
