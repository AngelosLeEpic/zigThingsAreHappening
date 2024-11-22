const std = @import("std");
const math = std.math;
const rand = std.Random;

const utils = @import("main.zig");
const dists = @import("distributions.zig");

const MaxShots : i32 = 40;
const MinShots : i32 = 0;

const ShotDistType = dists.DistributionType.NORMAL;
const TargetDistType = dists.DistribtutionType.NORMAL;
const SavePercentType = dists.DistributionType.NORMAL;

const GameSimResult = enum {
    TEAM_A_WINS, TEAM_B_WINS, DRAW
};

pub fn RunSimulation() !void {
    // Run the presim to generate distributions

    // For every team matchup run the SimulateGame function
    // Based on the GameSimResult start incrementing scores

    // Return the winners of the function in whatever way you feel fits best
}

pub fn CalculatePreSim() !void {
    // Given a hardcoded dist type assignment for each stat. Create dist lists based on team data
    // Based on ShotDistType, TargetDistType, etc make and store a Distribution struct of the correct type for every team for every stat
    // e.g. Make a "Distribution[] shotDists" of size teamCount. Use teamdata.zig!!
    // Use team index to access the array
}

pub fn GetGoalsScored(shotsTaken : i32, shotOnTargetPercentage : i32, opponentSavePercentage : i32 ) i32 {
    var goals : i32 = 0;

    for(0..shotsTaken) |i|{
       
    }

}

pub fn SimulateGame(teamAIndex: i32, teamBIndex: i32) GameSimResult {
    
    // Do as below to randomly generate values from the distributions you made in PreSim 
    // Simulate the game, I think you know it better than me
    // Return the result

    var teamAShotsTaken: i32 = dists.shotDists[teamAIndex].getRandomValue;              //Normal distributions : Clamped to -5 to +10 of the teams real life average
    var teamBShotsTaken: i32 = dists.shotDists[teamBIndex].getRandomValue;
    var teamAShotsOnTarget: i32 = dists.shotOnTargetDists[teamAIndex].getRandomValue;   //Normal distributions : Clamped to the number of shots taken by team in sim (room to clamp further if wacky stats occur):
    var teamBShotsOnTarget: i32 = dists.shotOnTargetDists[teamBIndex].getRandomValue;
    var teamASavePercentage: f32 = dists.savePercentageDists[teamAIndex].getRandomValue; //Normal distributions : Clamped to -5 to +10 of the teams real life average
    var teamBSavePercentage: f32 = dists.savePercentageDists[teamBIndex].getRandomValue;
    var teamAShotOnTargetPercentage : f32 = teamAShotsOnTarget / teamAShotsTaken * 100;
    var teamBShotOnTargetPercentage : f32 = teamBShotsOnTarget / teamBShotsTaken * 100;
    var teamAGoals : i32 = 0;
    var teamBGoals : i32 = 0;

    return void;
}
