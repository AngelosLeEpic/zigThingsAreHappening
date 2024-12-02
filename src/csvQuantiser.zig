const std = @import("std");

const Bin = struct { IntervalMin: f32 = 0.0, IntervalMax: f32 = 0.0, Col: std.ArrayList(f32) = undefined };

// Assumes 1D csv
pub fn QuantiseCSV(inputFilePath: []const u8, outputFilePath: []const u8, binCount: usize, intervalMin: f32, intervalMax: f32) !void {
    // Find diff in interval and divide by binCount then add min
    // Create binCount Bins with intervals
    // Read file and put item into correct bin
    // Create new csv with mid interval on x and frequency on y
    // Loop through bins and put into csv
    // Bosh

    const intervalDiff: f32 = intervalMax - intervalMin;
    const binCountf32: f32 = @floatFromInt(binCount);
    const binInterval: f32 = intervalDiff / binCountf32;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    var bins: std.ArrayList(Bin) = std.ArrayList(Bin).init(allocator);

    for (0..binCount) |i| {
        var bin: Bin = Bin{};

        const if32: f32 = @floatFromInt(i);
        const binMin = intervalMin + binInterval * if32;

        bin.IntervalMin = binMin;
        bin.IntervalMax = binMin + binInterval;
        bin.Col = std.ArrayList(f32).init(allocator);

        try bins.append(bin);
    }

    const currentWD = std.fs.cwd();

    const file = try currentWD.readFileAlloc(allocator, inputFilePath, 1024 * 1024);
    defer allocator.free(file);
    var line_iter = std.mem.tokenizeAny(u8, file, "\n");
    _ = line_iter.next();

    while (line_iter.peek() != null) {
        const line = line_iter.next().?;
        const val = try std.fmt.parseFloat(f32, line);
        for (0..binCount) |i| {
            if (val >= bins.items[i].IntervalMin and val < bins.items[i].IntervalMax) {
                try bins.items[i].Col.append(val);
                break;
            }
        }
    }

    const outFile = try currentWD.createFile(outputFilePath, .{ .truncate = true });
    const writer = outFile.writer();

    try writer.print("Val,Freq\n", .{});

    for (0..binCount) |i| {
        const freq = bins.items[i].Col.items.len;
        try writer.print("{d},{}\n", .{ bins.items[i].IntervalMax, freq });
        bins.items[i].Col.deinit();
    }

    bins.deinit();
}

pub fn QuantiseCSV2D(inputFilePath: []const u8, outputFilePathCol1: []const u8, outputFilePathCol2: []const u8,
 binCount: usize, intervalMinCol1: f32, intervalMaxCol1: f32,intervalMinCol2: f32, intervalMaxCol2: f32) !void {
    const intervalDiff1: f32 = intervalMaxCol1 - intervalMinCol1;
    const intervalDiff2: f32 = intervalMaxCol2 - intervalMinCol2;
    const binCountf32: f32 = @floatFromInt(binCount);
    const binInterval1: f32 = intervalDiff1 / binCountf32;
    const binInterval2: f32 = intervalDiff2 / binCountf32;

    std.debug.print("Diff: {}, Inter: {}\n", .{intervalDiff2, binInterval2});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    var bins1: std.ArrayList(Bin) = std.ArrayList(Bin).init(allocator);
    var bins2: std.ArrayList(Bin) = std.ArrayList(Bin).init(allocator);

    std.debug.print("Allocated bins\n", .{});

    for (0..binCount) |i| {        
        const if32: f32 = @floatFromInt(i);

        std.debug.print("Creating bin {}\n", .{i});

        var bin: Bin = Bin{};
        const binMin1 = intervalMinCol1 + binInterval1 * if32;
        bin.IntervalMin = binMin1;
        bin.IntervalMax = binMin1 + binInterval1;
        bin.Col = std.ArrayList(f32).init(allocator);
        try bins1.append(bin);

        var bin2: Bin = Bin{};
        const binMin2 = intervalMinCol2 + binInterval2 * if32;        
        bin2.IntervalMin = binMin2;
        bin2.IntervalMax = binMin2 + binInterval2;
        bin2.Col = std.ArrayList(f32).init(allocator);
        try bins2.append(bin2);

        //std.debug.print("Inter: {}, InterMult: {}, Bin Min 2: {}, MIN: {}, Max: {}\n", .{binInterval2, binInterval2*if32, binMin2, bin2.IntervalMin, bin2.IntervalMax});
        //std.debug.print("Inter: {}, InterMult: {}, Bin Min 2: {}, MIN: {}, Max: {}\n", .{binInterval2, binInterval2*if32, binMin2, bins2.items[i].IntervalMin, bins2.items[i].IntervalMax});
        //std.debug.print("Inter: {}, InterMult: {}, Bin Min 1: {}, MIN: {}, Max: {}\n", .{binInterval1, binInterval1*if32, binMin1, bins1.items[i].IntervalMin, bins1.items[i].IntervalMax});
    }

    std.debug.print("Bins Filled\n", .{});

    const currentWD = std.fs.cwd();

    const file = try currentWD.readFileAlloc(allocator, inputFilePath, 1024 * 1024);
    defer allocator.free(file);
    var line_iter = std.mem.tokenizeAny(u8, file, "\n");
    _ = line_iter.next();

    while (line_iter.peek() != null) {
        const line = line_iter.next().?;
        var splitLine = std.mem.tokenizeAny(u8, line, ",");

        const val1Str = std.mem.trim(u8, splitLine.next().?, &[_]u8{ 13, 10 });
        const val2Str = std.mem.trim(u8, splitLine.next().?, &[_]u8{ 13, 10 });
        //std.debug.print("Strings: [{s}-{s}]\n", .{val1Str, val2Str});

        const val1 = try std.fmt.parseFloat(f32, val1Str);
        const val2 = try std.fmt.parseFloat(f32, val2Str);

        var bin1Active:bool = true;
        var bin2Active:bool = true;
        for (0..binCount) |i| {
            if (!bin1Active and !bin2Active)
                break;

            if (bin1Active and val1 >= bins1.items[i].IntervalMin and val1 < bins1.items[i].IntervalMax) {
                try bins1.items[i].Col.append(val1);
                bin1Active = false;
            }

            //std.debug.print("Checking if {} is between {} and {}\n", .{val2, bins2.items[i].IntervalMin, bins2.items[i].IntervalMax});
            if (bin2Active and val2 >= bins2.items[i].IntervalMin and val2 < bins2.items[i].IntervalMax) {
                try bins2.items[i].Col.append(val2);
                bin2Active = false;
            }
        }
    }

    const outFile1 = try currentWD.createFile(outputFilePathCol1, .{ .truncate = true });
    const writer1 = outFile1.writer();
    const outFile2 = try currentWD.createFile(outputFilePathCol2, .{ .truncate = true });
    const writer2 = outFile2.writer();

    try writer1.print("Val,Freq\n", .{});
    try writer2.print("Val,Freq\n", .{});

    for (0..binCount) |i| {
        const freq = bins1.items[i].Col.items.len;
        try writer1.print("{d},{}\n", .{ bins1.items[i].IntervalMax, freq });
        bins1.items[i].Col.deinit();

        const freq2 = bins2.items[i].Col.items.len;
        try writer2.print("{d},{}\n", .{ bins2.items[i].IntervalMax, freq2 });
        bins2.items[i].Col.deinit();
    }

    bins1.deinit();
    bins2.deinit();
}
