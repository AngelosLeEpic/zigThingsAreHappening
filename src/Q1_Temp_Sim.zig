const std = @import("std");
const math = std.math;
const rand = std.Random;
const ArrayList = std.ArrayList;

const utils = @import("distribution.zig");

const Q1Results = struct {
    var temperatures: []f64 = {};
    var maxTemp: f64 = 0;
};

pub fn simulateTemperatureChange(temp: f64, deltaTime: f64) f64 {
    return temp + utils.GetRandFromNormalDistribution(0, deltaTime);
}

pub fn simulateQ1(N: c_int, deltaTime: f64, temperatures: ArrayList(f64)) Q1Results {
    var count: c_int = 0;
    var maxTemp = -999;
    var temp: f64 = 0;
    while (count < N) {
        temp = simulateTemperatureChange(temp, deltaTime);
        temperatures.addOne(temp);
        if (temp > maxTemp) {
            maxTemp = temp;
        }
        count += 1;
    }

    const out: Q1Results = {
        .temperatures == temperatures;
        .maxTempL == maxTemp;
    };
    return out;
}
