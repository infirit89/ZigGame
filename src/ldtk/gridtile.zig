const std = @import("std");

pub const GridTile = struct {
    px: Coordinates,
    src: Coordinates,
    f: i64,
    t: i64,
    a: i64,
    pub const Coordinates = struct {
        x: i64,
        y: i64,

        pub fn parse(json: std.json.Value) Coordinates {
            const elems = json.array.items;
            return .{
                .x = elems[0].integer,
                .y = elems[1].integer,
            };
        }

        pub fn format(
            self: Coordinates,
            comptime _: []const u8,
            _: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            try writer.print("X: {}, Y: {}", .{ self.x, self.y });
        }
    };
    pub fn parse(json: std.json.Value) GridTile {
        const jsonGridTileObject = json.object;
        var gridTile: GridTile = undefined;
        gridTile.px = GridTile.Coordinates.parse(
            jsonGridTileObject.get("px").?,
        );
        gridTile.src = GridTile.Coordinates.parse(
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
