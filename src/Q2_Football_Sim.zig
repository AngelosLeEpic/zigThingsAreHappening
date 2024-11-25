const std = @import("std");
const math = std.math;
const rand = std.Random;
const ArrayList = std.ArrayList;

const utils = @import("main.zig");
const dists = @import("distributions.zig");
const teamData: type = @import("teamData.zig");
const print = std.debug.print;

const MaxShots: i32 = 40;
const MinShots: i32 = 0;

const ShotDistType = dists.DistributionType.NORMAL;
const TargetDistType = dists.DistributionType.NORMAL;
const SavePercentType = dists.DistributionType.NORMAL;

const GameSimResult = enum { TEAM_A_WINS, TEAM_B_WINS, DRAW };
var PointsCount = []i32{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

 
const SimDists = struct {
     shotDists: ArrayList(dists.Distribution),
     targetDists: ArrayList(dists.Distribution),
   
};

///References: https://en.wikipedia.org/wiki/Quicksort
pub fn sort(A: []i32, lo: usize, hi: usize) []i32 {
    if (lo < hi) {
        const p = partition(A, lo, hi);
        sort(A, lo, @min(p, p -% 1));
        sort(A, p + 1, hi);
    }
}

pub fn partition(A: []i32, lo: usize, hi: usize) usize {
    //Pivot can be chosen otherwise, for example try picking the first or random
    //and check in which way that affects the performance of the sorting
    const pivot = A[hi];
    var i = lo;
    var j = lo;
    while (j < hi) : (j += 1) {
        if (A[j] < pivot) {
            std.mem.swap(i32, &A[i], &A[j]);
            i = i + 1;
        }
    }
    std.mem.swap(i32, &A[i], &A[hi]);
    return i;
}

pub fn RunSimulation(nSims: i32) ![teamData.GetTeamCount()][]u8 {
    // Run the presim to generate distributions
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }
   
   const Q2Allocator = std.heap.page_allocator;
   var simData: SimDists = SimDists{
         .shotDists = ArrayList(dists.Distribution).init(Q2Allocator),
         .targetDists= ArrayList(dists.Distribution).init(Q2Allocator)
    };

    simData = CalculatePreSim();
    for (0..nSims) |_| {
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
    }
    var sortedPointsCount: [teamData.GetTeamCount()]i32 = {};
    var sortedTeams: [teamData.GetTeamCount()][]u8 = {};
    for (0..teamData.GetTeamCount()) |i| {
        sortedPointsCount[i] = PointsCount[i];
    }
    sortedPointsCount = sort(sortedPointsCount, 1, 20);
    for (0..teamData.GetTeamCount()) |i| {
        for (i..teamData.GetTeamCount()) |j| {
            if (sortedPointsCount[i] == PointsCount[j]) {
                sortedTeams[i] = teamData.TEAM_NAMES[j];
                break;
            }
        }
    }

    return sortedTeams;
    // For every team matchup run the SimulateGame function
    // Based on the GameSimResult start incrementing scores

    // Return the winners of the function in whatever way you feel fits best
}

pub fn CalculatePreSim() !SimDists {
    const gamesPlayed: i32 = 12;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }
    const allocator = gpa.allocator();
    const Q2Allocator = std.heap.page_allocator;
    var simData: SimDists = SimDists{
         .shotDists = ArrayList(dists.Distribution).init(Q2Allocator),
         .targetDists= ArrayList(dists.Distribution).init(Q2Allocator)
    };
    // Given a hardcoded dist type assignment for each stat. Create dist lists based on team data
    for (0..teamData.GetTeamCount()) |x| {
        const shotsMean: f32 = teamData.GetShotCount(x) / gamesPlayed;
        const targetsMean: f32 = teamData.GetShotsOnTargetCount(x) / gamesPlayed;
        const stdDev: f32 = 2;

        simData.shotDists.append(dists.CreateNormalDist(shotsMean, stdDev, allocator));
        simData.targetDists.append(dists.CreateNormalDist(targetsMean, stdDev, allocator));
    }

    return simData;
    // Based on ShotDistType, TargetDistType, etc make and store a Distribution struct of the correct type for every team for every stat
    // e.g. Make a "Distribution[] shotDists" of size teamCount. Use teamdata.zig!!
    // Use team index to access the array

}

pub fn GetGoalsScored(shotsTaken: f64, shotOnTargetPercentage: f64, opponentSavePercentage: f64) i32 {
    var goals: i32 = 0;

    for (0..shotsTaken) |_| {
        if (dists.RandSuccessChance(shotOnTargetPercentage)) {
            if (dists.RandSuccessChance(opponentSavePercentage)) {
                goals += 1;
            }
        }
    }
    return goals;
}
//Simulate a prem game through stats given,

pub fn SimulateGame(teamAIndex: i32, teamBIndex: i32, simData: *SimDists) GameSimResult {
    // Do as below to randomly generate values from the distributions you made in PreSim
    // Simulate the game, I think you know it better than me
    // Return the result
    const teamAShotsTaken: i32 = simData.shotDists[teamAIndex].getRandVal();
    const teamBShotsTaken: i32 = simData.shotDists[teamBIndex].getRandVal();
    const teamAShotsOnTarget: i32 = simData.targetDists[teamAIndex].getRandVal(); //Normal distributions : Clamped to the number of shots taken by team in sim (room to clamp further if wacky stats occur):
    const teamBShotsOnTarget: i32 = simData.targetDists[teamBIndex].getRandVal();
    const teamASavePercentage: f32 = teamData.GetSavesCount(teamAIndex) / teamAShotsOnTarget; //Normal distributions : Clamped to -5 to +10 of the teams real life average
    const teamBSavePercentage: f32 = teamData.GetSavesCount(teamBIndex) / teamBShotsOnTarget;
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
