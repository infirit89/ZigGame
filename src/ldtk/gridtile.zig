const std = @import("std");
const pt = @import("point.zig");

const Point = pt.Point;

pub const GridTile = struct {
    px: Point,
    src: Point,
    f: i64,
    t: i64,
    a: i64,
    pub fn parse(json: std.json.Value) GridTile {
        const jsonGridTileObject = json.object;
        var gridTile: GridTile = undefined;
        gridTile.px = Point.parse(
            jsonGridTileObject.get("px").?,
        );
        gridTile.src = Point.parse(
            jsonGridTileObject.get("src").?,
        );
        gridTile.f = jsonGridTileObject.get("f").?.integer;
        gridTile.t = jsonGridTileObject.get("t").?.integer;
        gridTile.a = jsonGridTileObject.get("a").?.integer;
        return gridTile;
    }

    pub fn format(
        self: GridTile,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("Px: {}\n", .{self.px});
        try writer.print("Src: {}\n", .{self.src});
        try writer.print("F: {}\n", .{self.f});
        try writer.print("T: {}\n", .{self.t});
        try writer.print("A: {}", .{self.a});
    }
};
