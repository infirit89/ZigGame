const std = @import("std");

pub const Direction = enum {
    w,
    e,
    s,
    n,

    // pub fn parseFromString(str: []const u8) Direction {}
};
pub const Neighbour = struct {
    levelId: []u8,
    direction: Direction,
    allocator: std.mem.Allocator,

    pub fn init(
        allocator: std.mem.Allocator,
        levelId: []const u8,
        direction: []const u8,
    ) !*Neighbour {
        var neighbour = try allocator.create(Neighbour);
        neighbour.levelId = try allocator.dupe(u8, levelId);
        neighbour.direction = std.meta.stringToEnum(Direction, direction).?;
        neighbour.allocator = allocator;
        return neighbour;
    }

    pub fn deinit(self: *Neighbour) void {
        self.allocator.free(self.levelId);
        self.allocator.destroy(self);
    }

    pub fn format(
        self: Neighbour,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("LevelId: {s}\n", .{self.levelId});
        try writer.print("Direction: {}", .{self.direction});
    }
};
