const std = @import("std");

pub const Point = struct {
    x: i64,
    y: i64,

    pub fn parse(json: std.json.Value) Point {
        const elems = json.array.items;
        return .{
            .x = elems[0].integer,
            .y = elems[1].integer,
        };
    }

    pub fn format(
        self: Point,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("X: {}, Y: {}", .{ self.x, self.y });
    }
};
