const std = @import("std");

pub fn readFileAndParseJson(
    allocator: std.mem.Allocator,
    path: []const u8,
) !std.json.Parsed(std.json.Value) {
    const file = try std.fs.cwd().openFile(
        path,
        .{},
    );
    defer file.close();

    const file_size = (try file.stat()).size;
    var buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);
    const bytes_read = try file.readAll(buffer);
    const parsed = try std.json.parseFromSlice(
        std.json.Value,
        allocator,
        buffer[0..bytes_read],
        .{},
    );
    return parsed;
}
