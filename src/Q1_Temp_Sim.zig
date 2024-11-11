const std = @import("std");
const math = std.math;
const rand = std.Random;
const ArrayList = std.ArrayList;

const utils = @import("main.zig");

const Q1Results = struct {
    var x: []f64 = {};
    var maxTemp: f64 = 0;
};

pub fn simulateTemperatureChange(temp: f64, deltaTime: f64) f64 {
    return temp + utils.GetRandFromNormalDistribution(0, deltaTime);
}

pub fn simulateQ1(N:c_int, deltaTime: f64) Q1Results {
    var count: c_int = 0;
    var temp: f64 = 0.0;
    
    const allocator = std.heap.page_allocator;

    var list = ArrayList(f64).init(allocator);

    while(count < N){
        temp = simulateTemperatureChange(temp, deltaTime);
        count += 1;

    }
} 