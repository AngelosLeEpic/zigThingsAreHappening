const std = @import("std");
const math = std.math;
const rand = std.Random;

const utils = @import("main.zig");
const dists = @import("distributions.zig");
const teamData: type = @import("teamData.zig");

const MaxShots: i32 = 40;
const MinShots: i32 = 0;

const ShotDistType = dists.DistributionType.NORMAL;
const TargetDistType = dists.DistributionType.NORMAL;
const SavePercentType = dists.DistributionType.NORMAL;

const GameSimResult = enum { TEAM_A_WINS, TEAM_B_WINS, DRAW };
var PointsCount = [_]usize{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

const SimDists = struct {
    var shotDists: dists.Distribution[teamData.GetTeamCount()] = {};
    var targetDists: dists.Distribution[teamData.GetTeamCount()] = {};
    var saveDists: dists.Distribution[teamData.GetTeamCount()] = {};
};

pub fn RunSimulation() !u32[teamData.GetTeamCount()] {
    // Run the presim to generate distributions
    const simData = CalculatePreSim();

    for (0..teamData.GetTeamCount()) |TeamA| {
        for (0..teamData.GetTeamCount()) |TeamB| {
            const result: GameSimResult = SimulateGame(TeamA, TeamB, simData);
            if (result == GameSimResult.TEAM_A_WINS) {
                PointsCount[TeamA] += 3;
            } else if (result == GameSimResult.TEAM_B_WINS) {
                PointsCount[TeamB] += 3;
            } else if (result == GameSimResult.DRAW) {
                PointsCount[TeamA] += 1;
                PointsCount[TeamB] += 1;
            }
        }
    }
    // For every team matchup run the SimulateGame function
    // Based on the GameSimResult start incrementing scores

    // Return the winners of the function in whatever way you feel fits best
}

pub fn CalculatePreSim() !SimDists {
    var Distributions: SimDists = {};
    const gamesPlayed: i32 = 12;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }
    const allocator = gpa.allocator();

    // Given a hardcoded dist type assignment for each stat. Create dist lists based on team data
    for (0..teamData.GetTeamCount()) |x| {
        const shotsMean: f32 = teamData.GetShotCount(x) / gamesPlayed;
        const stdDev: f32 = 2;
        Distributions.shotDists[x] = dists.createNormalDist(shotsMean, stdDev, allocator);
        Distributions.targetDists[x] = dists.createNormalDist(mean, stdDev, allocator);
        Distributions.saveDists[x] = dists.createNormalDist(mean, stdDev, allocator);
    }

    return Distributions;
    // Based on ShotDistType, TargetDistType, etc make and store a Distribution struct of the correct type for every team for every stat
    // e.g. Make a "Distribution[] shotDists" of size teamCount. Use teamdata.zig!!
    // Use team index to access the array

}

pub fn GetGoalsScored(shotsTaken: f64, shotOnTargetPercentage: f64, opponentSavePercentage: f64) i32 {
    var goals: i32 = 0;

    for (0..shotsTaken) |_| {
        if (dists.GetRandFromUnifromDistributionSingle(0, 1) < shotOnTargetPercentage) {
            if (dists.GetRandFromUnifromDistributionSingle(0, 1) < opponentSavePercentage) {
                goals += 1;
            }
        }
    }
    return goals;
}
//Simulate a prem game through stats given,
// Function returns 0 if team A wins
// returns 1 for a draw
// returns 2 if team A loses
// Cry ab it Fiona
pub fn SimulateGame(teamAIndex: i32, teamBIndex: i32, simData: SimDists) GameSimResult {
    // Do as below to randomly generate values from the distributions you made in PreSim
    // Simulate the game, I think you know it better than me
    // Return the result
    const teamAShotsTaken: i32 = simData.shotDists[teamAIndex].getRandVal();
    const teamBShotsTaken: i32 = simData.shotDist[teamBIndex].getRandVal();
    const teamAShotsOnTarget: i32 = simData.TargetDists[teamAIndex].getRandVal(); //Normal distributions : Clamped to the number of shots taken by team in sim (room to clamp further if wacky stats occur):
    const teamBShotsOnTarget: i32 = simData.TargetDists[teamBIndex].getRandVal();
    const teamASavePercentage: f32 = simData.saveDists[teamAIndex].getRandVal(); //Normal distributions : Clamped to -5 to +10 of the teams real life average
    const teamBSavePercentage: f32 = simData.saveDists[teamBIndex].getRandVal();
    const teamAShotOnTargetPercentage: f32 = teamAShotsOnTarget / teamAShotsTaken * 100;
    const teamBShotOnTargetPercentage: f32 = teamBShotsOnTarget / teamBShotsTaken * 100;
    const teamAGoals: i32 = GetGoalsScored(teamAShotsTaken, teamAShotOnTargetPercentage, teamBSavePercentage);
    const teamBGoals: i32 = GetGoalsScored(teamBShotsTaken, teamBShotOnTargetPercentage, teamASavePercentage);

    if (teamAGoals > teamBGoals) {
        return GameSimResult.TEAM_A_WINS;
    }
    if (teamAGoals < teamBGoals) {
        return GameSimResult.TEAM_B_WINS;
    }
    if (teamAGoals == teamBGoals) {
        return GameSimResult.DRAW;
    }
    return void;
}
