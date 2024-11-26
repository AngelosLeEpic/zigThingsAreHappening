const std = @import("std");

const Bin = struct {
    IntervalMin: f64 = 0.0,
    IntervalMax: f64 = 0.0,
    Col: std.ArrayList(f64) = undefined
};

// Assumes 1D csv
pub fn QuantiseCSV(inputFilePath: []const u8, outputFilePath: []const u8, binCount: usize, intervalMin: f64, intervalMax: f64) !void {    
    // Find diff in interval and divide by binCount then add min
    // Create binCount Bins with intervals
    // Read file and put item into correct bin
    // Create new csv with mid interval on x and frequency on y
    // Loop through bins and put into csv
    // Bosh

    const intervalDiff: f64 = intervalMax - intervalMin;
    const binCountF64: f64 = @floatFromInt(binCount);
    const binInterval: f64 = intervalDiff / binCountF64;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    var bins: std.ArrayList(Bin) = std.ArrayList(Bin).init(allocator);    

    for (0..binCount) |i| {
        var bin: Bin = Bin{};

        const iF64: f64 = @floatFromInt(i);
        const binMin = intervalMin + binInterval * iF64;
        
        bin.IntervalMin = binMin;
        bin.IntervalMax = binMin + binInterval;
        bin.Col = std.ArrayList(f64).init(allocator);
        
        try bins.append(bin);
    }

    const currentWD = std.fs.cwd();

    const file = try currentWD.readFileAlloc(allocator, inputFilePath, 1024 * 1024);
    defer allocator.free(file);
    var line_iter = std.mem.tokenizeAny(u8, file, "\n");
    _ = line_iter.next();

    while (line_iter.peek() != null){
        const line = line_iter.next().?;
        const val = try std.fmt.parseFloat(f64, line);
        for (0..binCount) |i| {
            if (val >= bins.items[i].IntervalMin and val < bins.items[i].IntervalMax) {
                try bins.items[i].Col.append(val);
                break;
            }
        }
    }

    const outFile = try currentWD.createFile(outputFilePath, .{ .truncate=true});
    const writer = outFile.writer();
    
    try writer.print("Val,Freq\n", .{});

    for (0..binCount) |i| {
        const freq = bins.items[i].Col.items.len;
        try writer.print("{d},{}\n", .{bins.items[i].IntervalMax, freq});
        bins.items[i].Col.deinit();
    }    

    bins.deinit();
}