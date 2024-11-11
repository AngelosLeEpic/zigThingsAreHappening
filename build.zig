const std = @import("std");
const Build = @import("std").build;

pub fn build(b: *Build.Builder) void {
    // Set the build mode (debug, release-fast, release-small, etc.)
    const mode = b.standardReleaseOptions();
    
    // Define the executable target
    const exe = b.addExecutable("normal_distribution_program", "src/main.zig");
    
    // Set the build mode (debug or release)
    exe.setBuildMode(mode);

    // Install the executable (copy to the output directory)
    exe.install();
}
