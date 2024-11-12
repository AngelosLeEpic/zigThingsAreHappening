const std = @import("std");

const TEAM_NAMES = .{ "Boston Red Socks", "Boston Blue Socks", "Boston Green Socks"};
const SHOT_COUNTS = .{ 5, 6, 1};
const SHOTS_ON_TARGET_COUNTS = .{ 1, 2, 1};
const SAVES_COUNT = .{5, 3, 6};

var g_teamNamesHashmap = std.StringHashMap(i32).init(std.heap.page_allocator);
var g_savePercents: []f64 = undefined;

pub fn InitData() void {
    for (0..TEAM_NAMES.len) |i| {
        g_teamNamesHashmap.put(TEAM_NAMES[i], i);
    }    

    g_savePercents = [SAVES_COUNT.len]f64;
    for (0..SAVES_COUNT.len) |i| {
        const shotsOnTargetFloat:f64 = @floatFromInt(SHOTS_ON_TARGET_COUNTS[i]);
        g_savePercents[i] = SAVES_COUNT[i] / shotsOnTargetFloat;
    }
}

pub fn GetTeamIndex(str: []const u8) i32 {
    return g_teamNamesHashmap.get(str);
}

pub fn GetTeamName(i: i32) []const u8 {
    return TEAM_NAMES[i];
}

pub fn GetShotCountFromName(str: []const u8) i32 {
    return SHOT_COUNTS[GetTeamIndex(str)];
}

pub fn GetShotCount(i: i32) i32 {
    return SHOT_COUNTS[i];
}

pub fn GetShotsOnTargetCountFromName(str: []const u8) i32 {
    return SHOTS_ON_TARGET_COUNTS[GetTeamIndex(str)];
}

pub fn GetShotsOnTargetCount(i: i32) i32 {
    return SHOTS_ON_TARGET_COUNTS[i];
}

pub fn GetSavesCountFromName(str: []const u8) i32 {
    return SAVES_COUNT[GetTeamIndex(str)];
}

pub fn GetSavesCount(i: i32) i32 {
    return SAVES_COUNT[i];
}

pub fn GetSavesPercentFromName(str: []const u8) i32 {
    return g_savePercents[GetTeamIndex(str)];
}

pub fn GetSavesPercent(i: i32) i32 {
    return g_savePercents[i];
}