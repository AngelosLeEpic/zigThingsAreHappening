const std = @import("std");
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;

const DataframeErrors = error{
    arrayLengthMismatch,
};

const ColumnType = enum {
    bool,
    float,
    str,
};

const Column = union(ColumnType) {
    bool: ArrayList(bool),
    float: ArrayList(f64),
    str: ArrayList([]const u8),
};

pub const Dataframe = struct {
    allocator: std.mem.Allocator,
    data: StringHashMap(Column),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .data = StringHashMap(Column).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        var iter = self.data.valueIterator();
        while (iter.next()) |col| {
            switch (col.*) {
                .bool => col.bool.deinit(),
                .float => col.float.deinit(),
                .str => col.str.deinit(),
            }
        }
        return self.data.deinit();
    }

    pub fn get(self: *Self, name: []const u8) ?*Column {
        return self.data.getPtr(name);
    }

    pub fn add(self: *Self, comptime col_type: ColumnType, name: []const u8) !void {
        switch (col_type) {
            .bool => {
                try self.data.put(name, Column{ .bool = ArrayList(bool).init(self.allocator) });
            },
            .float => {
                try self.data.put(name, Column{ .float = ArrayList(f64).init(self.allocator) });
            },
            .str => {
                try self.data.put(name, Column{ .str = ArrayList([]const u8).init(self.allocator) });
            },
        }
    }
};

pub fn testing() !void {
    var df = Dataframe.init(std.heap.page_allocator);
    defer df.deinit();
    const f_64_array = [_]f64{ 3.5, 2.6, 8.7 };
    const str_array = [_][]const u8{ "a", "b", "c" };

    try df.add(ColumnType.float, "test_float_col");
    try df.get("test_float_col").?.float.appendSlice(&f_64_array);
    const float_col = df.get("test_float_col").?.float.items;
    std.debug.print("array of f64: {any}\n", .{float_col});

    try df.add(ColumnType.str, "test_str_col");
    try df.get("test_str_col").?.str.appendSlice(&str_array);
    const str_col = df.get("test_str_col").?.str.items;
    std.debug.print("array of str: {any}\n", .{str_col});
}

// pub fn csv_to_df(comptime T: type, csv_filename: []const u8, allocator: std.mem.Allocator) !Dataframe(T) {
//     const fs = std.fs.cwd();
//     const file = try fs.readFileAlloc(allocator, csv_filename, 1024 * 1024 * 1024);
//     defer allocator.free(file);
//     var line_iter = std.mem.tokenizeAny(u8, file, "\n");
//
//     const col_names = line_iter.next().?;
//     var col_names_split = std.mem.tokenizeAny(u8, col_names, ",");
//
//     var row_size: usize = 0;
//     while (col_names_split.next()) |_| {
//         row_size += 1;
//     }
//
//     col_names_split.reset();
//
//     var df = Dataframe(T).init(allocator);
//     // var col_types = ArrayList(T).init(allocator);
//     // defer col_types.deinit();
//     //
//     var first_line_items = std.mem.tokenizeAny(u8, line_iter.next().?, ",");
//
//     while (first_line_items.next()) |first_line_iter_item| {
//         const col_name_iter_item = col_names_split.next().?;
//         try df.add_col(&[_]T{try std.fmt.parseFloat(T, first_line_iter_item)}, col_name_iter_item);
//     }
//
//     while (line_iter.next()) |line| {
//         var line_items = std.mem.tokenizeAny(u8, line, ",");
//         var index: usize = 0;
//
//         var send_array = ArrayList(T).init(allocator);
//         defer send_array.deinit();
//
//         while (line_items.next()) |item| {
//             try send_array.append(try std.fmt.parseFloat(T, item));
//             index += 1;
//         }
//         try df.add_row(send_array.items);
//     }
//     return df;
// }
