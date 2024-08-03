const std = @import("std");
const gt = @import("gridtile.zig");

const GridTile = gt.GridTile;

pub const LayerInstance = struct {
    identifier: []u8,
    type: []u8,
    width: i64,
    height: i64,
    gridSize: i64,
    opacity: i64,
    pxTotalOffsetX: i64,
    pxTotalOffsetY: i64,
    tilesetRelativePath: []u8,
    gridTiles: []GridTile,
    allocator: std.mem.Allocator,

    pub fn init(
        allocator: std.mem.Allocator,
        identifier: []const u8,
        liType: []const u8,
        tilesetRelativePath: []const u8,
        gridSize: usize,
    ) !*LayerInstance {
        var layerInstance = try allocator.create(LayerInstance);
        layerInstance.gridTiles = try allocator.alloc(GridTile, gridSize);
        layerInstance.allocator = allocator;
        layerInstance.identifier = try allocator.dupe(u8, identifier);
        layerInstance.type = try allocator.dupe(u8, liType);
        layerInstance.tilesetRelativePath = try allocator.dupe(
            u8,
            tilesetRelativePath,
        );
        return layerInstance;
    }

    pub fn deinit(self: *LayerInstance) void {
        self.allocator.free(self.gridTiles);
        self.allocator.free(self.identifier);
        self.allocator.free(self.type);
        self.allocator.free(self.tilesetRelativePath);
        self.allocator.destroy(self);
    }

    pub fn parse(allocator: std.mem.Allocator, json: std.json.Value) !*LayerInstance {
        const layerInstanceObject = json.object;
        const identifier = layerInstanceObject.get("__identifier").?.string;
        const liType = layerInstanceObject.get("__type").?.string;
        const tilesetRelativePath = layerInstanceObject.get("__tilesetRelPath").?.string;
        const gridTiles = layerInstanceObject.get("gridTiles").?.array;
        var layerInstance = try LayerInstance.init(
            allocator,
            identifier,
            liType,
            tilesetRelativePath,
            gridTiles.items.len,
        );
        layerInstance.width = layerInstanceObject.get("__cWid").?.integer;
        layerInstance.height = layerInstanceObject.get("__cHei").?.integer;
        layerInstance.gridSize = layerInstanceObject.get("__gridSize").?.integer;
        layerInstance.opacity = layerInstanceObject.get("__opacity").?.integer;
        layerInstance.pxTotalOffsetX = layerInstanceObject.get("__pxTotalOffsetX").?.integer;
        layerInstance.pxTotalOffsetY = layerInstanceObject.get("__pxTotalOffsetY").?.integer;

        for (gridTiles.items, 0..) |jsonGridTile, i| {
            layerInstance.gridTiles[i] = GridTile.parse(jsonGridTile);
        }
        return layerInstance;
    }

    pub fn format(
        self: LayerInstance,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("Identifier: {s}\n", .{self.identifier});
        try writer.print("Type: {s}\n", .{self.type});
        try writer.print("Width: {}\n", .{self.width});
        try writer.print("Height: {}\n", .{self.height});
        try writer.print("GridSize: {}\n", .{self.gridSize});
        try writer.print("Opacity: {}\n", .{self.opacity});
        try writer.print("TotalOffset: {} {}\n", .{
            self.pxTotalOffsetX,
            self.pxTotalOffsetY,
        });
        try writer.print("TilesetRelativePath: {s}", .{
            self.tilesetRelativePath,
        });
    }
};
