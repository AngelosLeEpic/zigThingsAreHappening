const std = @import("std");

const TEAM_NAMES = [_][]const u8{ "Boston Red Socks", "Boston Blue Socks", "Boston Green Socks" };
const SHOT_COUNTS = [_]usize{ 5, 6, 1 };
const SHOTS_ON_TARGET_COUNTS = [_]usize{ 1, 2, 1 };
const SAVES_COUNT = [_]usize{ 5, 3, 6 };
const POINTS_COUNT = [_]usize{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

var g_teamNamesHashmap: std.StringHashMap(usize) = undefined;
var g_savePercents: []f64 = undefined;

pub fn InitData() !void {
    g_teamNamesHashmap = std.StringHashMap(usize).init(std.heap.page_allocator);

    var i: usize = 0;
    for (TEAM_NAMES) |name| {
        try g_teamNamesHashmap.put(name, i);
        i += 1;
    }

    g_savePercents = try std.heap.page_allocator.alloc(f64, SAVES_COUNT.len);
    for (0..SAVES_COUNT.len) |j| {
        const savesFloat: f64 = @floatFromInt(SAVES_COUNT[j]);
        const targetFloat: f64 = @floatFromInt(SHOTS_ON_TARGET_COUNTS[j]);
        g_savePercents[j] = savesFloat / targetFloat;
    }
}

pub fn GetTeamCount() usize {
    return TEAM_NAMES.len;
}

pub fn GetTeamIndex(str: []const u8) usize {
    return g_teamNamesHashmap.get(str);
}

pub fn GetTeamName(i: usize) []const u8 {
    return TEAM_NAMES[i];
}

pub fn GetShotCountFromName(str: []const u8) usize {
    return SHOT_COUNTS[GetTeamIndex(str)];
}

pub fn GetShotCount(i: usize) usize {
    return SHOT_COUNTS[i];
}

pub fn GetShotsOnTargetCountFromName(str: []const u8) usize {
    return SHOTS_ON_TARGET_COUNTS[GetTeamIndex(str)];
}

pub fn GetShotsOnTargetCount(i: usize) usize {
    return SHOTS_ON_TARGET_COUNTS[i];
}

pub fn GetSavesCountFromName(str: []const u8) usize {
    return SAVES_COUNT[GetTeamIndex(str)];
}

pub fn GetSavesCount(i: usize) usize {
    return SAVES_COUNT[i];
}

pub fn GetSavesPercentFromName(str: []const u8) usize {
    return g_savePercents[GetTeamIndex(str)];
}

pub fn GetSavesPercent(i: usize) usize {
    return g_savePercents[i];
}
