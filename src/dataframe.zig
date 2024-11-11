const std = @import("std");
const ArrayList = std.ArrayList;

pub fn Dataframe(comptime T: type) type {
    return struct {
        array: ArrayList(T),
        row_size: usize,

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator, row_size: usize) Self {
            return .{
                .array = ArrayList(T).init(allocator),
                .row_size = row_size,
            };
        }

        pub fn get(self: *Self, row: usize, col: usize) T {
            return self.array.items[(col * self.row_size) + row];
        }

        pub fn deinit(self: *Self) void {
            return self.array.deinit();
        }

        pub fn get_row(self: *Self, row: usize) []const T {
            const row_index = row * self.row_size;
            return self.array.items[row_index .. row_index + self.row_size];
        }

        pub fn get_col(self: *Self, col: usize) []const T {
            const col_size: usize = self.array.items.len / self.row_size;
            const col_out = [col_size]T;
            for (0..col_size) |i| {
                col_out[i] = self.array.items.get(col, i);
            }
            return col_out;
        }
    };
}
