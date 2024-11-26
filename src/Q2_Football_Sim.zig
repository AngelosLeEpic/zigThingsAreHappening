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
var PointsCount = [_]i32{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

const TeamSort = struct {
    name: []const u8,
    value: i32,
};

pub fn sort_team(context: void, a: TeamSort, b: TeamSort) bool {
    _ = context;
    return a.value < b.value;
}

const SimDists = struct {
    shotDists: ArrayList(*dists.Distribution),
    targetDists: ArrayList(*dists.Distribution),
};

///References: https://en.wikipedia.org/wiki/Quicksort
pub fn sort(A: []i32, lo: usize, hi: usize) void {
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

pub fn RunSimulation(nSims: usize) !ArrayList([]const u8) {
    // Run the presim to generate distributions
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }

    const Q2Allocator = std.heap.page_allocator;
    var simData: SimDists = SimDists{ .shotDists = ArrayList(*dists.Distribution).init(Q2Allocator), .targetDists = ArrayList(*dists.Distribution).init(Q2Allocator) };

    simData = try CalculatePreSim();
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
    for (0..teamData.GetTeamCount()) |i| {
        Q2Allocator.destroy(simData.shotDists.items[i]);
        Q2Allocator.destroy(simData.targetDists.items[i]);
    }

    var sortedTeams = ArrayList(TeamSort).init(Q2Allocator);
    for (0..teamData.GetTeamCount()) |i| {
        try sortedTeams.append(TeamSort{ .name = teamData.GetTeamName(i), .value = PointsCount[i] });
    }
    std.debug.print("{any}\n", .{sortedTeams.items});
    std.sort.insertion(TeamSort, sortedTeams.items, {}, sort_team);
    std.debug.print("{any}\n", .{sortedTeams.items});
    std.debug.print("works?{d}\n", .{sortedTeams.items.len});

    var teams = ArrayList([]const u8).init(Q2Allocator);
    for (sortedTeams.items) |team| {
        try teams.append(team.name);
    }

    return teams;
}

pub fn CalculatePreSim() !SimDists {
    const gamesPlayed: f64 = 12;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }

    const Q2Allocator = std.heap.page_allocator;
    var simData: SimDists = SimDists{ .shotDists = ArrayList(*dists.Distribution).init(Q2Allocator), .targetDists = ArrayList(*dists.Distribution).init(Q2Allocator) };
    // Given a hardcoded dist type assignment for each stat. Create dist lists based on team data
    for (0..teamData.GetTeamCount()) |x| {
        const shotCount: f64 = @floatFromInt(teamData.GetShotCount(x));
        const targetsCount: f64 = @floatFromInt(teamData.GetShotsOnTargetCount(x));
        const shotsMean: f64 = shotCount / gamesPlayed;
        const targetsMean: f64 = targetsCount / gamesPlayed;
        const stdDev: f64 = 1;

        try simData.shotDists.append(try dists.CreateNormalDist(shotsMean, stdDev, Q2Allocator));
        try simData.targetDists.append(try dists.CreateNormalDist(targetsMean, stdDev, Q2Allocator));
    }

    return simData;
    // Based on ShotDistType, TargetDistType, etc make and store a Distribution struct of the correct type for every team for every stat
    // e.g. Make a "Distribution[] shotDists" of size teamCount. Use teamdata.zig!!
    // Use team index to access the array

}

pub fn GetGoalsScored(shotsTaken: f64, shotOnTargetPercentage: f64, opponentSavePercentage: f64) i32 {
    var goals: i32 = 0;
    const shotsTakenLoop: usize = @intFromFloat(shotsTaken);
    for (0..shotsTakenLoop) |_| {
        if (dists.RandSuccessChance(shotOnTargetPercentage)) {
            if (dists.RandSuccessChance(opponentSavePercentage)) {
                goals += 1;
            }
        }
    }
    return goals;
}
//Simulate a prem game through stats given,

pub fn SimulateGame(teamAIndex: usize, teamBIndex: usize, simData: SimDists) GameSimResult {
    // Do as below to randomly generate values from the distributions you made in PreSim
    // Simulate the game, I think you know it better than me
    // Return the result
    const teamASaves: f64 = @floatFromInt(teamData.GetSavesCount(teamAIndex));
    const teamBSaves: f64 = @floatFromInt(teamData.GetSavesCount(teamBIndex));
    const teamAShotsTaken: f64 = simData.shotDists.items[teamAIndex].GetRandVal();
    const teamBShotsTaken: f64 = simData.shotDists.items[teamBIndex].GetRandVal();
    const teamAShotsOnTarget: f64 = simData.targetDists.items[teamAIndex].GetRandVal(); //Normal distributions : Clamped to the number of shots taken by team in sim (room to clamp further if wacky stats occur):
    const teamBShotsOnTarget: f64 = simData.targetDists.items[teamBIndex].GetRandVal();
    const teamASavePercentage: f64 = teamASaves / teamAShotsOnTarget; //Normal distributions : Clamped to -5 to +10 of the teams real life average
    const teamBSavePercentage: f64 = teamBSaves / teamBShotsOnTarget;
    const teamAShotOnTargetPercentage: f64 = teamAShotsOnTarget / teamAShotsTaken * 100;
    const teamBShotOnTargetPercentage: f64 = teamBShotsOnTarget / teamBShotsTaken * 100;

    const teamAGoals: i32 = GetGoalsScored(teamAShotsTaken, teamAShotOnTargetPercentage, teamBSavePercentage);
    const teamBGoals: i32 = GetGoalsScored(teamBShotsTaken, teamBShotOnTargetPercentage, teamASavePercentage);

    if (teamAGoals > teamBGoals) {
        return GameSimResult.TEAM_A_WINS;
    }
    if (teamAGoals < teamBGoals) {
        return GameSimResult.TEAM_B_WINS;
    }

    return GameSimResult.DRAW;
}
