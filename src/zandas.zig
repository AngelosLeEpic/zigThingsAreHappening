const std = @import("std");
const ArrayList = std.ArrayList;

const DataframeErrors = error{
    arrayLengthMismatch,
};

pub fn Dataframe(comptime T: type) type {
    const Column = struct { name: []const u8, data: ArrayList(T) };
    return struct {
        allocator: std.mem.Allocator,
        data: ArrayList(Column),

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .allocator = allocator,
                .data = ArrayList(Column).init(allocator),
            };
        }

        pub fn get(self: *Self, row: usize, col: usize) T {
            return self.data.items[col].data.items[row];
        }

        pub fn deinit(self: *Self) void {
            for (self.data.items) |col| {
                col.data.deinit();
            }
            return self.data.deinit();
        }

        pub fn get_row(self: *Self, row: usize) ArrayList(T) {
            var return_row = ArrayList(T).init(self.allocator);
            for (0..self.data.items.len) |i| {
                try return_row.append(self.data.items[i].data.items[row]);
            }
            return return_row;
        }

        pub fn get_col(self: *Self, col: usize) ArrayList(T) {
            return self.data.items[col].data;
        }

        pub fn add_row(self: *Self, array: []const T) !void {
            if (array.len != self.data.items.len) {
                std.debug.print("array lenght: {d}, self.data.items length: {d}\n", .{ array.len, self.data.items.len });
                return DataframeErrors.arrayLengthMismatch;
            }
            for (0..self.data.items.len) |i| {
                try self.data.items[i].data.append(array[i]);
            }
        }

        pub fn add_col(self: *Self, array: []const T, col_name: []const u8) !void {
            var column = ArrayList(T).init(self.allocator);
            defer column.deinit();

            try column.appendSlice(array);
            try self.data.append(Column{
                .name = col_name,
                .data = ArrayList(T).init(self.allocator),
            });
        }
    };
}

pub fn csv_to_df(comptime T: type, csv_filename: []const u8, allocator: std.mem.Allocator) !Dataframe(T) {
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

    var df = Dataframe(T).init(allocator);
    // var col_types = ArrayList(T).init(allocator);
    // defer col_types.deinit();
    //
    var first_line_items = std.mem.tokenizeAny(u8, line_iter.next().?, ",");

    while (first_line_items.next()) |first_line_iter_item| {
        const col_name_iter_item = col_names_split.next().?;
        try df.add_col(&[_]T{try std.fmt.parseFloat(T, first_line_iter_item)}, col_name_iter_item);
    }

    while (line_iter.next()) |line| {
        var line_items = std.mem.tokenizeAny(u8, line, ",");
        var index: usize = 0;

        var send_array = ArrayList(T).init(allocator);
        defer send_array.deinit();

        while (line_items.next()) |item| {
            try send_array.append(try std.fmt.parseFloat(T, item));
            index += 1;
        }
        try df.add_row(send_array.items);
    }
    return df;
}
