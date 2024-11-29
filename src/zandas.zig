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

const ColumnType = enum {
    float,
    bool,
    str,
};

const Column = union(ColumnType) {
    float: ArrayList(f64),
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

    pub fn idx(self: *Self, index: usize) ?*Column {
        var iter = self.data.keyIterator();
        var count: usize = 0;
        while (iter.next()) |name| {
            if (count == index) {
                return self.data.getPtr(name.*);
            }
            count += 1;
        }
        return null;
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
                try self.data.put(try self.arena.allocator().dupe(u8, name), Column{ .float = ArrayList(f64).init(self.arena.allocator()) });
            },
            .str => {
                try self.data.put(try self.arena.allocator().dupe(u8, name), Column{ .str = ArrayList([]const u8).init(self.arena.allocator()) });
            },
        }
    }
};

test "test dataframe for errors" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }
    var df = try Dataframe.init(allocator);
    defer df.deinit();
    const f_64_array = [_]f64{ 3.5, 2.6, 8.7 };
    const str_array = [_][]const u8{ "a", "b", "c" };

    try df.add(ColumnType.float, "test_float_col");
    try df.get("test_float_col").?.float.appendSlice(&f_64_array);
    const float_col = df.get("test_float_col").?.float.items;
    std.log.debug("array of f64: {any}", .{float_col});

    try df.add(ColumnType.str, "test_str_col");
    try df.get("test_str_col").?.str.appendSlice(&str_array);
    const str_col = df.get("test_str_col").?.str.items;
    std.log.debug("array of str: {any}", .{str_col});

    var df_s = try csv_to_df("Data/database.csv", allocator);
    defer df_s.deinit();

    var iter = df_s.data.iterator();
    while (iter.next()) |i| {
        const val = i.value_ptr;
        switch (val.*) {
            .float => std.log.debug("name: {s}, vals?: {any}", .{ i.key_ptr.*, i.value_ptr.float.items }),
            .bool => std.log.debug("name: {s}, vals?: {any}", .{ i.key_ptr.*, i.value_ptr.bool.items }),
            .str => std.log.debug("name: {s}, vals?: {any}", .{ i.key_ptr.*, i.value_ptr.str.items }),
        }
    }
}

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

            std.log.debug("FIRST ITEM {s}", .{trimed_string});
            if (parseFloat(f64, trimed_string)) |_| {
                std.log.debug("making float column! the name is: {s}", .{name});
                try df.add(ColumnType.float, name);
            } else |_| {
                if (eql(u8, trimed_string, "true") or eql(u8, trimed_string, "false")) {
                    try df.add(ColumnType.bool, name);
                    std.log.debug("making bool column! the name is: {s}", .{name});
                } else {
                    try df.add(ColumnType.str, name);
                    std.log.debug("making str column! the name is: {s}", .{name});
                }
            }
        } else {
            break;
        }
    }
    col_names_split.reset();
    while (col_names_split.next()) |name| {
        std.log.debug("column name: {s}", .{name});
    }
    col_names_split.reset();

    var keyiter = df.data.keyIterator();
    var valiter = df.data.valueIterator();
    while (keyiter.next()) |key| {
        const val = valiter.next().?;
        switch (val.*) {
            .float => std.log.debug("name: {s}, vals?: {any}", .{ key.*, val.float.items }),
            .bool => std.log.debug("name: {s}, vals?: {any}", .{ key.*, val.bool.items }),
            .str => std.log.debug("name: {s}, vals?: {any}", .{ key.*, val.str.items }),
        }
    }

    while (line_iter.next()) |line| {
        var line_items = std.mem.tokenizeAny(u8, line, ",");

        for (names.items) |name| {
            if (line_items.next()) |string| {
                const trimed_string = trim(u8, string, &[_]u8{ 13, 10 });

                var col = df.get(name).?;
                switch (col.*) {
                    .float => try col.float.append(try parseFloat(f64, trimed_string)),
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
