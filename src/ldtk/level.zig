const std = @import("std");
const li = @import("layerinstance.zig");
const nr = @import("neighbour.zig");
const pt = @import("point.zig");

const Layer = li.Layer;
const Neighbour = nr.Neighbour;
const Point = pt.Point;

pub const Level = struct {
    identifier: []u8,
    iid: []u8,
    pos: Point,
    size: Point,
    layers: []*Layer,
    neighbours: []*Neighbour,
    allocator: std.mem.Allocator,

    pub fn init(
        allocator: std.mem.Allocator,
        identifier: []const u8,
        iid: []const u8,
        neighbourSize: usize,
        layerSize: usize,
    ) !*Level {
        const level = try allocator.create(Level);
        level.allocator = allocator;
        level.identifier = try allocator.dupe(u8, identifier);
        level.iid = try allocator.dupe(u8, iid);
        level.neighbours = try allocator.alloc(*Neighbour, neighbourSize);
        level.layers = try allocator.alloc(*Layer, layerSize);
        return level;
    }

    pub fn deinit(self: *Level) void {
        for (self.layers) |layerInstance| {
            std.debug.print("cum cum cum cum cum cum cum\n", .{});
            layerInstance.*.deinit();
        }
        self.allocator.free(self.layers);
        self.allocator.free(self.identifier);
        self.allocator.free(self.iid);

        for (self.neighbours) |neighbour| {
            neighbour.*.deinit();
        }
        self.allocator.free(self.neighbours);
        self.allocator.destroy(self);
    }

    pub fn parse(allocator: std.mem.Allocator, json: std.json.Value) !*Level {
        const levelObject = json.object;
        const iid = levelObject.get("iid").?.string;

        const neighbours = levelObject.get("__neighbours").?.array;
        const layerInstances = levelObject.get("layerInstances").?.array;

        var level = try Level.init(
            allocator,
            levelObject.get("identifier").?.string,
            iid,
            neighbours.items.len,
            layerInstances.items.len,
        );

        level.pos = .{
            .x = levelObject.get("worldX").?.integer,
            .y = levelObject.get("worldY").?.integer,
        };

        level.size = .{
            .x = levelObject.get("pxWid").?.integer,
            .y = levelObject.get("pxHei").?.integer,
        };

        for (neighbours.items, 0..) |jsonNeigbour, i| {
            const neighbourObject = jsonNeigbour.object;
            const neighbour = try Neighbour.init(
                allocator,
                neighbourObject.get("levelIid").?.string,
                neighbourObject.get("dir").?.string,
            );
            level.neighbours[i] = neighbour;
        }

        for (layerInstances.items, 0..) |jsonLayerInstance, i| {
            const layerInstance = try Layer.parse(
                allocator,
                jsonLayerInstance,
            );
            level.layers[i] = layerInstance;
        }
        return level;
    }

    pub fn format(
        self: Level,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        try writer.print("Identifier: {s},\n", .{self.identifier});
        try writer.print("Iid: {s},\n", .{self.iid});
        try writer.print("Position: {},\n", .{self.pos});
        try writer.print("Size: {},\n", .{self.size});

        try writer.writeAll("LayerInstances:");

        for (self.layers, 0..) |value, i| {
            if (i == 0) {
                try writer.writeAll(" [\n");
            }
            try writer.writeAll("{\n");
            try writer.print("{}\n", .{value.*});
            try writer.writeAll("}\n");

            if (i == self.layers.len - 1) {
                try writer.writeAll("]\n");
            }
        }

        try writer.writeAll("Neighbours:");
        if (self.neighbours.len == 0) {
            try writer.writeAll(" []");
            return;
        }

        for (self.neighbours, 0..) |value, i| {
            if (i == 0) {
                try writer.writeAll(" [\n");
            }
            try writer.writeAll("{\n");
            try writer.print("{}\n", .{value.*});
            try writer.writeAll("}\n");

            if (i == self.neighbours.len - 1) {
                try writer.writeAll("]\n");
            }
        }
    }
};
