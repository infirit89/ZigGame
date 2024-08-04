const std = @import("std");
const pt = @import("point.zig");

const Point = pt.Point;

pub const Entity = struct {
    identifier: []u8,
    gridPos: Point,
    size: Point,
    px: Point,
    worldPos: Point,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, identifier: []const u8) !Entity {
        var entity: Entity = undefined;
        entity.identifier = try allocator.dupe(u8, identifier);
        entity.allocator = allocator;
        return entity;
    }

    pub fn deinit(self: *const Entity) void {
        self.allocator.free(self.identifier);
    }

    pub fn parse(allocator: std.mem.Allocator, json: std.json.Value) !Entity {
        const entityObject = json.object;
        const identifier = entityObject.get("__identifier").?.string;
        var entity = try Entity.init(allocator, identifier);

        entity.gridPos = Point.parse(entityObject.get("__grid").?);
        entity.size = .{
            .x = entityObject.get("width").?.integer,
            .y = entityObject.get("height").?.integer,
        };

        entity.px = Point.parse(entityObject.get("px").?);
        entity.worldPos = .{
            .x = entityObject.get("__worldX").?.integer,
            .y = entityObject.get("__worldY").?.integer,
        };

        return entity;
    }
};
