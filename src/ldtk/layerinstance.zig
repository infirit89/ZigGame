const std = @import("std");
const gt = @import("gridtile.zig");
const pt = @import("point.zig");
const et = @import("entity.zig");

const GridTile = gt.GridTile;
const Point = pt.Point;
const Entity = et.Entity;

pub const LayerType = enum {
    Tiles,
    Entities,
    IntGrid,
};

pub const LayerError = error{
    InvalidLayerType,
};

pub const Layer = struct {
    identifier: []u8,
    type: LayerType,
    size: Point,
    gridSize: i64,
    opacity: i64,
    totalOffset: Point,
    tilesetRelativePath: ?[]u8,
    gridTiles: []GridTile,
    entities: std.StringHashMap(Entity),
    allocator: std.mem.Allocator,

    pub fn init(
        allocator: std.mem.Allocator,
        identifier: []const u8,
        layerType: []const u8,
        gridSize: usize,
        entitySize: usize,
    ) !*Layer {
        var layer = try allocator.create(Layer);
        layer.gridTiles = try allocator.alloc(GridTile, gridSize);
        layer.allocator = allocator;
        layer.identifier = try allocator.dupe(u8, identifier);
        layer.entities = std.StringHashMap(Entity).init(allocator);
        try layer.entities.ensureTotalCapacity(@intCast(entitySize));

        layer.type = std.meta.stringToEnum(
            LayerType,
            layerType,
        ) orelse return LayerError.InvalidLayerType;
        return layer;
    }

    pub fn deinit(self: *Layer) void {
        self.allocator.free(self.identifier);
        self.allocator.free(self.gridTiles);
        var it = self.entities.valueIterator();
        while (it.next()) |value| {
            value.*.deinit();
        }
        self.entities.deinit();

        if (self.tilesetRelativePath) |value| {
            self.allocator.free(value);
        }
        self.allocator.destroy(self);
    }

    pub fn parse(allocator: std.mem.Allocator, json: std.json.Value) !*Layer {
        const layerJsonObject = json.object;
        const identifier = layerJsonObject.get("__identifier").?.string;
        const layerType = layerJsonObject.get("__type").?.string;
        const tilesetRelativePath = layerJsonObject.get(
            "__tilesetRelPath",
        ).?;
        const gridTiles = layerJsonObject.get("gridTiles").?.array;
        const entities = layerJsonObject.get("entityInstances").?.array;
        var layer = try Layer.init(
            allocator,
            identifier,
            layerType,
            gridTiles.items.len,
            entities.items.len,
        );

        switch (tilesetRelativePath) {
            .string => |value| layer.tilesetRelativePath = try allocator.dupe(
                u8,
                value,
            ),
            else => {
                layer.tilesetRelativePath = null;
            },
        }

        layer.size = .{
            .x = layerJsonObject.get("__cWid").?.integer,
            .y = layerJsonObject.get("__cHei").?.integer,
        };

        layer.gridSize = layerJsonObject.get("__gridSize").?.integer;
        layer.opacity = layerJsonObject.get("__opacity").?.integer;
        layer.totalOffset = .{
            .x = layerJsonObject.get("__pxTotalOffsetX").?.integer,
            .y = layerJsonObject.get("__pxTotalOffsetY").?.integer,
        };

        for (gridTiles.items, 0..) |jsonGridTile, i| {
            layer.gridTiles[i] = GridTile.parse(jsonGridTile);
        }

        for (entities.items) |value| {
            const entity = try Entity.parse(allocator, value);
            try layer.entities.put(entity.identifier, entity);
        }
        return layer;
    }

    pub fn format(
        self: Layer,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("Identifier: {s}\n", .{self.identifier});
        try writer.print("Type: {s}\n", .{self.type});
        try writer.print("Size: {}\n", .{self.size});
        try writer.print("GridSize: {}\n", .{self.gridSize});
        try writer.print("Opacity: {}\n", .{self.opacity});
        try writer.print("TotalOffset: {}\n", .{
            self.totalOffset,
        });
        try writer.print("TilesetRelativePath: {s}", .{
            self.tilesetRelativePath,
        });
    }
};
