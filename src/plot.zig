const std = @import("std");
const plotlib = @import("plotlib");

const rgb = plotlib.rgb;
const Range = plotlib.Range;

const Figure = plotlib.Figure;
const Line = plotlib.Line;
const Scatter = plotlib.Scatter;
const Stem = plotlib.Stem;
const ShapeMarker = plotlib.ShapeMarker;

const SMOOTHING = 0.2;

pub fn line_plot(x_in: []const f32, y: []const f32, file_path: []const u8, allocator: std.mem.Allocator) !void {
    const x: ?[]const f32 = x_in;
    var figure = Figure.init(allocator, .{
        .value_padding = .{
            .x_min = .{ .value = 1.0 },
            .x_max = .{ .value = 1.0 },
        },
        .axis = .{
            .show_y_axis = false,
        },
    });
    defer figure.deinit();
    try figure.addPlot(Line{ .x = x, .y = y, .style = .{
        .color = rgb.BLUE,
        .width = 2.0,
        .smooth = SMOOTHING,
    } });

    var svg = try figure.show();
    defer svg.deinit();

    std.debug.print("line_plot out\n", .{});

    var file = try std.fs.cwd().createFile(file_path, .{});
    defer file.close();

    try svg.writeTo(file.writer());
}

pub fn scatter_plot(x_in: []const f32, y: []const f32, file_path: []const u8, allocator: std.mem.Allocator) !void {
    const x: ?[]const f32 = x_in;
    var figure = Figure.init(allocator, .{
        .value_padding = .{
            .x_min = .{ .value = 1.0 },
            .x_max = .{ .value = 1.0 },
        },
        .axis = .{
            .show_y_axis = false,
        },
    });
    defer figure.deinit();
    try figure.addPlot(Scatter{ .x = x, .y = y, .style = .{ .color = rgb.BLUE, .radius = 1.0, .shape = .circle } });

    var svg = try figure.show();
    defer svg.deinit();

    std.debug.print("scatter_plot out\n", .{});
    var file = try std.fs.cwd().createFile(file_path, .{});
    defer file.close();

    try svg.writeTo(file.writer());
}

pub fn stem_plot(x_in: []const f32, y: []const f32, file_path: []const u8, allocator: std.mem.Allocator) !void {
    const x: ?[]const f32 = x_in;
    var figure = Figure.init(allocator, .{
        .value_padding = .{},
        .axis = .{
            .show_y_axis = false,
        },
    });
    defer figure.deinit();
    try figure.addPlot(Stem{ .x = x, .y = y, .style = .{ .color = rgb.BLUE, .radius = 1.0, .shape = .circle } });

    var svg = try figure.show();
    defer svg.deinit();

    std.debug.print("Stem plot out\n", .{});
    var file = try std.fs.cwd().createFile(file_path, .{});
    defer file.close();

    try svg.writeTo(file.writer());
}