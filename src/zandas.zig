const std = @import("std");
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const eql = std.mem.eql;
const tokenizeAny = std.mem.tokenizeAny;
const parseFloat = std.fmt.parseFloat;
const trim = std.mem.trim;
const ArenaAllocator = std.heap.ArenaAllocator;

const DataframeErrors = error{
    arrayLengthMismatch,
};

pub const ColumnType = enum {
    float,
    bool,
    str,
};

pub const ItemType = union(ColumnType) {
    float: f32,
    bool: bool,
    str: []const u8,
};

pub const Column = union(ColumnType) {
    float: ArrayList(f32),
    bool: ArrayList(bool),
    str: ArrayList([]const u8),
};

pub const Dataframe = struct {
    data: StringHashMap(Column),
    arena: *ArenaAllocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !Self {
        const arena = try allocator.create(ArenaAllocator);
        errdefer allocator.destroy(arena);
        arena.* = ArenaAllocator.init(allocator);

        return .{
            .arena = arena,
            .data = StringHashMap(Column).init(arena.allocator()),
        };
    }

    pub fn deinit(self: *Self) void {
        const allocator = self.arena.child_allocator;
        self.arena.deinit();
        allocator.destroy(self.arena);
    }

    pub fn get_index(self: *Self, col_name: []const u8, value: ItemType) ?usize {
        const col = self.get(col_name).?;
        switch (col.*) {
            .float => {
                for (col.float.items, 0..) |item, index| {
                    if (item == value.float) return index;
                } else return null;
            },
            .bool => {
                for (col.bool.items, 0..) |item, index| {
                    if (item == value.bool) return index;
                } else return null;
            },
            .str => {
                for (col.str.items, 0..) |item, index| {
                    if (std.mem.eql(u8, item, value.str)) return index;
                } else return null;
            },
        }
    }

    pub fn get(self: *Self, name: []const u8) ?*Column {
        return self.data.getPtr(name);
    }

    pub fn add(self: *Self, comptime col_type: ColumnType, name: []const u8) !void {
        switch (col_type) {
            .bool => {
                try self.data.put(try self.arena.allocator().dupe(u8, name), Column{ .bool = ArrayList(bool).init(self.arena.allocator()) });
            },
            .float => {
                try self.data.put(try self.arena.allocator().dupe(u8, name), Column{ .float = ArrayList(f32).init(self.arena.allocator()) });
            },
            .str => {
                try self.data.put(try self.arena.allocator().dupe(u8, name), Column{ .str = ArrayList([]const u8).init(self.arena.allocator()) });
            },
        }
    }
};

pub fn csv_to_df(filename: []const u8, allocator: std.mem.Allocator) !Dataframe {
    const fs = std.fs.cwd();
    const file = try fs.readFileAlloc(allocator, filename, 1024 * 1024 * 1024);
    defer allocator.free(file);
    var line_iter = tokenizeAny(u8, file, "\n");

    var df = try Dataframe.init(allocator);

    const col_names = line_iter.next().?;
    var col_names_split = tokenizeAny(u8, col_names, ",");
    var names = ArrayList([]const u8).init(allocator);
    defer names.deinit();
    while (col_names_split.next()) |name| {
        try names.append(trim(u8, name, &[_]u8{ 13, 10 }));
    }

    var first_line_items = tokenizeAny(u8, line_iter.peek().?, ",");

    for (names.items) |name| {
        if (first_line_items.next()) |string| {
            const trimed_string = trim(u8, string, &[_]u8{ 13, 10 });

            if (parseFloat(f32, trimed_string)) |_| {
                try df.add(ColumnType.float, name);
            } else |_| {
                if (eql(u8, trimed_string, "true") or eql(u8, trimed_string, "false")) {
                    try df.add(ColumnType.bool, name);
                } else {
                    try df.add(ColumnType.str, name);
                }
            }
        } else {
            break;
        }
    }
    col_names_split.reset();
    col_names_split.reset();

    while (line_iter.next()) |line| {
        var line_items = std.mem.tokenizeAny(u8, line, ",");

        for (names.items) |name| {
            if (line_items.next()) |string| {
                const trimed_string = trim(u8, string, &[_]u8{ 13, 10 });

                var col = df.get(name).?;
                switch (col.*) {
                    .float => try col.float.append(try parseFloat(f32, trimed_string)),
                    .bool => {
                        if (eql(u8, trimed_string, "true")) {
                            try col.bool.append(true);
                        } else {
                            try col.bool.append(false);
                        }
                    },
                    .str => try col.str.append(try df.arena.allocator().dupe(u8, trimed_string)),
                }
            } else {
                break;
            }
        }
        col_names_split.reset();
    }
    return df;
}
