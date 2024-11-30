const std = @import("std");
const math = std.math;
const rand = std.Random;
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;

const utils = @import("main.zig");
const dists = @import("distributions.zig");
const zandas = @import("zandas.zig");
const Dataframe = zandas.Dataframe;
const ItemType = zandas.ItemType;
const print = std.debug.print;
const ArenaAllocator = std.heap.ArenaAllocator;

const Maxshots_: i32 = 40;
const Minshots_: i32 = 0;

const shot_DistType = dists.DistributionType.NORMAL;
const TargetDistType = dists.DistributionType.NORMAL;
const SavePercentType = dists.DistributionType.NORMAL;

const GameSimResult = enum { TEAM_A_WINS, TEAM_B_WINS, DRAW };

const TeamSort = struct {
    name: []const u8,
    value: i32,
};

pub fn sort_team(context: void, a: TeamSort, b: TeamSort) bool {
    _ = context;
    return a.value > b.value;
}

const SimDists = struct {
    shotDists: StringHashMap(*dists.Distribution),
    targetDists: StringHashMap(*dists.Distribution),
};

pub fn run_simulation(filename: []const u8, allocator: std.mem.Allocator, n_sims: usize) !ArrayList([]const u8) {
    var df = try zandas.csv_to_df(filename, allocator);
    defer df.deinit();

    var arena = ArenaAllocator.init(allocator);
    defer arena.deinit();

    var points_count = StringHashMap(i32).init(arena.allocator());
    defer points_count.deinit();

    for (df.get("Squad").?.str.items) |team| {
        try points_count.put(try arena.allocator().dupe(u8, team), 0);
    }

    // Run the presim to generate distributions
    const sim_data = try calculate_pre_sim(&df, arena.allocator());
    for (0..n_sims) |_| {
        for (df.get("Squad").?.str.items) |team_a| {
            for (df.get("Squad").?.str.items) |team_b| {
                const result: GameSimResult = simulate_game(&df, team_a, team_b, sim_data);
                if (result == GameSimResult.TEAM_A_WINS) {
                    points_count.getPtr(team_a).?.* += @as(i32, 3);
                } else if (result == GameSimResult.TEAM_B_WINS) {
                    points_count.getPtr(team_b).?.* += @as(i32, 3);
                } else if (result == GameSimResult.DRAW) {
                    points_count.getPtr(team_a).?.* += @as(i32, 1);
                    points_count.getPtr(team_b).?.* += @as(i32, 1);
                }
            }
        }
    }
    var sorted_teams = ArrayList(TeamSort).init(arena.allocator());

    std.log.debug("Teams with ranking values:", .{});
    for (df.get("Squad").?.str.items) |team| {
        try sorted_teams.append(TeamSort{ .name = team, .value = points_count.get(team).? });
        std.log.debug("name = {s}, val = {d}", .{ team, points_count.get(team).? });
    }
    std.sort.insertion(TeamSort, sorted_teams.items, {}, sort_team);

    var teams = ArrayList([]const u8).init(allocator);
    for (sorted_teams.items) |team| {
        try teams.append(try allocator.dupe(u8, team.name));
    }

    return teams;
}

pub fn calculate_pre_sim(df: *Dataframe, allocator: std.mem.Allocator) !SimDists {
    const games_played: f32 = 12;
    var sim_data = SimDists{ .shotDists = StringHashMap(*dists.Distribution).init(allocator), .targetDists = StringHashMap(*dists.Distribution).init(allocator) };
    // Given a hardcoded dist type assignment for each stat. Create dist lists based on team data
    for (df.get("Squad").?.str.items, 0..) |team, index| {
        const shot_count: f32 = df.get("Shots Taken").?.float.items[index];
        const targets_count: f32 = df.get("Shots On Target").?.float.items[index];
        const shots_mean: f32 = shot_count / games_played;
        const targets_mean: f32 = targets_count / games_played;
        const std_dev: f32 = 1;

        try sim_data.shotDists.put(team, try dists.CreateNormalDist(shots_mean, std_dev, allocator));
        try sim_data.targetDists.put(team, try dists.CreateNormalDist(targets_mean, std_dev, allocator));
    }

    return sim_data;

    // Based on shot_DistType, TargetDistType, etc make and store a Distribution struct of the correct type for every team for every stat
    // e.g. Make a "Distribution[] shotDists" of size teamCount. Use teamdata.zig!!
    // Use team index to access the array
    //
    // NOTE: NO DONT USE TEAMDATA.ZIG use a Dataframe!!! - Tom

}

pub fn get_goals_scored(shots_taken: f32, shoton_target_percentage: f32, opponentsave_percentage: f32) i32 {
    var goals: i32 = 0;
    var shots_taken_loop: usize = undefined;
    if (std.math.isInf(shots_taken) or std.math.isNan(shots_taken)) {
        shots_taken_loop = 0;
    } else {
        shots_taken_loop = @intFromFloat(shots_taken);
    }
    for (0..shots_taken_loop) |_| {
        if (dists.RandSuccessChance(shoton_target_percentage)) {
            if (dists.RandSuccessChance(opponentsave_percentage)) {
                goals += 1;
            }
        }
    }
    return goals;
}
//Simulate a prem game through stats given,

pub fn simulate_game(df: *Dataframe, team_a: []const u8, team_b: []const u8, sim_data: SimDists) GameSimResult {
    // Do as below to randomly generate values from the distributions you made in PreSim
    // Simulate the game, I think you know it better than me
    const team_a_saves: f32 = df.get("Saves").?.float.items[df.get_index("Squad", ItemType{ .str = team_a }).?];
    const team_b_saves: f32 = df.get("Saves").?.float.items[df.get_index("Squad", ItemType{ .str = team_b }).?];
    const team_a_shots_taken: f32 = sim_data.shotDists.get(team_a).?.GetRandVal(); //.GetRandVal();
    const team_b_shots_taken: f32 = sim_data.shotDists.get(team_b).?.GetRandVal();
    const team_a_shots_on_target: f32 = sim_data.targetDists.get(team_a).?.GetRandVal(); //Normal distributions : Clamped to the number of shots taken by team in sim (room to clamp further if wacky stats occur):
    const team_b_shots_on_target: f32 = sim_data.targetDists.get(team_b).?.GetRandVal();
    const team_a_save_percentage: f32 = team_a_saves / team_a_shots_on_target; //Normal distributions : Clamped to -5 to +10 of the teams real life average
    const team_b_save_percentage: f32 = team_b_saves / team_b_shots_on_target;
    const team_a_shot_on_target_percentage: f32 = team_a_shots_on_target / team_a_shots_taken * 100;
    const team_b_shot_on_target_percentage: f32 = team_b_shots_on_target / team_b_shots_taken * 100;

    const team_a_Goals: i32 = get_goals_scored(team_a_shots_taken, team_a_shot_on_target_percentage, team_b_save_percentage);
    const team_b_Goals: i32 = get_goals_scored(team_b_shots_taken, team_b_shot_on_target_percentage, team_a_save_percentage);

    if (team_a_Goals > team_b_Goals) {
        return GameSimResult.TEAM_A_WINS;
    }
    if (team_a_Goals < team_b_Goals) {
        return GameSimResult.TEAM_B_WINS;
    }

    return GameSimResult.DRAW;
}
