const std = @import("std");
const math = std.math;
const rand = std.Random;

const utils = @import("main.zig");

pub fn simulateTemperatureChange(temp: f64, deltaTime: f64) f64 {
    return temp + utils.GetRandFromNormalDistribution(0, deltaTime);
}

const MaxShots : i32 = 40;
const MinShots : i32 = 0;

pub fn getGoalsScored(shotsTaken : i32, shotOnTargetPercentage : i32, opponentSavePercentage : i32 ) i32 {
    var goals : i32 = 0;

    for(0..shotsTaken) |i|{
       
    }

}

pub fn simulateGame(teamAIndex: i32, teamBIndex: i32) GameSimResult {

    var teamAShotsTaken: i32 = dists.shotDists[teamAindex].getRandomValue;              //Normal distributions : Clamped to -5 to +10 of the teams real life average
    var teamBShotsTaken: i32 = dists.shotDists[teamBindex].getRandomValue;
    var teamAShotsOnTarget: i32 = dists.shotOnTargetDists[teamAindex].getRandomValue;   //Normal distributions : Clamped to the number of shots taken by team in sim (room to clamp further if wacky stats occur):
    var teamBShotsOnTarget: i32 = dists.shotOnTargetDists[teamBindex].getRandomValue;
    var teamASavePercentage: f32 = dists.savePercentageDists[teamAindex].getRandomValue; //Normal distributions : Clamped to -5 to +10 of the teams real life average
    var teamBSavePercentage: f32 = dists.savePercentageDists[teamBindex].getRandomValue;
    var teamAShotOnTargetPercentage : f32 = teamAShotsOnTarget / teamAShotsTaken * 100;
    var teamBShotOnTargetPercentage : f32 = teamBShotsOnTarget / teamBShotsTaken * 100;
    var teamAGoals : i32 = 0;
    var teamBGoals : i32 = 0;

  



    return void;
}
