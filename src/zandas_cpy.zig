const std = @import("std");
const ArrayList = std.ArrayList;

const DataTypes = union(enum) {
    float: f64,
    boolean: bool,
    str: []const u8,
};

const Column = struct { name: []const u8, data: ArrayList(DataTypes) };

const DataframeErrors = error{
    arrayLengthMismatch,
};

const Dataframe = struct {
    allocator: std.mem.Allocator,
    data: ArrayList(Column),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .data = ArrayList(Column).init(allocator),
        };
    }

    pub fn get(self: *Self, row: usize, col: usize) DataTypes {
        return self.data.items[col].data.items[row];
    }

    pub fn deinit(self: *Self) void {
        for (self.data.items) |col| {
            col.data.deinit();
        }
        return self.data.deinit();
    }

    pub fn get_row(self: *Self, row: usize) !ArrayList(DataTypes) {
        var return_row = ArrayList(DataTypes).init(self.allocator);
        for (0..self.data.items.len) |i| {
            try return_row.append(self.data.items[i].data.items[row]);
        }
        return return_row;
    }

    pub fn get_col(self: *Self, col: usize) ArrayList(DataTypes) {
        return self.data.items[col].data;
    }

    pub fn add_row(self: *Self, array: []const DataTypes) !void {
        if (array.len != self.data.items.len) {
            return DataframeErrors.arrayLengthMismatch;
        }
        for (0..self.data.items.len) |i| {
            try self.data.items[i].data.append(array[i]);
        }
    }

    pub fn add_col(self: *Self, array: []const DataTypes, col_name: []const u8) !void {
        var column = ArrayList(DataTypes).init(self.allocator);
        defer column.deinit();

        try column.appendSlice(array);
        try self.data.append(Column{
            .name = col_name,
            .data = ArrayList(DataTypes).init(self.allocator),
        });
    }
};

pub fn csv_to_df(comptime csv_filename: []const u8, allocator: std.mem.Allocator) !Dataframe {
    const fs = std.fs.cwd();
    const file = try fs.readFileAlloc(allocator, csv_filename, 1024 * 1024);
    defer allocator.free(file);
    var line_iter = std.mem.tokenizeAny(u8, file, "\n");

    const col_names = line_iter.next().?;
    var col_names_split = std.mem.tokenizeAny(u8, col_names, ",");

    var row_size: usize = 0;
    while (col_names_split.next()) |_| {
        row_size += 1;
    }

    col_names_split.reset();

    var df = Dataframe.init(allocator);
    var col_types = ArrayList(DataTypes).init(allocator);
    defer col_types.deinit();

    var first_line_items = std.mem.tokenizeAny(u8, line_iter.next().?, ",");

    while (first_line_items.next()) |first_line_iter_item| {
        const col_name_iter_item = col_names_split.next().?;

        if (std.fmt.parseFloat(f64, first_line_iter_item)) |value| {
            try col_types.append(DataTypes{ .float = value });
            try df.add_col(&[_]DataTypes{DataTypes{ .float = value }}, col_name_iter_item);
        } else |_| {
            if (std.mem.eql(u8, first_line_iter_item, "True")) {
                try col_types.append(DataTypes{ .boolean = true });
                try df.add_col(&[_]DataTypes{DataTypes{ .boolean = true }}, col_name_iter_item);
            } else if (std.mem.eql(u8, first_line_iter_item, "False")) {
                try col_types.append(DataTypes{ .boolean = false });
                try df.add_col(&[_]DataTypes{DataTypes{ .boolean = false }}, col_name_iter_item);
            } else {
                try col_types.append(DataTypes{ .str = first_line_iter_item });
                try df.add_col(&[_]DataTypes{DataTypes{ .str = first_line_iter_item }}, col_name_iter_item);
            }
        }
    }

    while (line_iter.next()) |line| {
        var line_items = std.mem.tokenizeAny(u8, line, ",");
        var index: usize = 0;

        var send_array = ArrayList(DataTypes).init(allocator);
        defer send_array.deinit();

        while (line_items.next()) |item| {
            switch (col_types.items[index]) {
                .float => try send_array.append(DataTypes{ .float = try std.fmt.parseFloat(f64, item) }),
                .boolean => {
                    if (std.mem.eql(u8, item, "True")) {
                        try send_array.append(DataTypes{ .boolean = true });
                    } else if (std.mem.eql(u8, item, "False")) {
                        try send_array.append(DataTypes{ .boolean = false });
                    }
                },
                .str => try send_array.append(DataTypes{ .str = item }),
            }
            index += 1;
        }
        try df.add_row(send_array.items);
    }
    return df;
}
