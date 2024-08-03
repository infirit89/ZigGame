const std = @import("std");
const li = @import("layerinstance.zig");
const nr = @import("neighbour.zig");

const LayerInstance = li.LayerInstance;
const Neighbour = nr.Neighbour;

pub const Level = struct {
    identifier: []u8,
    iid: []u8,
    worldX: i64,
    worldY: i64,
    width: i64,
    height: i64,
    layerInstances: []*LayerInstance,
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
        level.layerInstances = try allocator.alloc(*LayerInstance, layerSize);
        return level;
    }

    pub fn deinit(self: *Level) void {
        for (self.layerInstances) |layerInstance| {
            std.debug.print("cum cum cum cum cum cum cum\n", .{});
            layerInstance.*.deinit();
        }
        self.allocator.free(self.layerInstances);
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

        level.worldX = levelObject.get("worldX").?.integer;
        level.worldY = levelObject.get("worldY").?.integer;
        level.width = levelObject.get("pxWid").?.integer;
        level.height = levelObject.get("pxHei").?.integer;

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
            const layerInstance = try LayerInstance.parse(
                allocator,
                jsonLayerInstance,
            );
            level.layerInstances[i] = layerInstance;
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
        try writer.print("WorldX: {},\n", .{self.worldX});
        try writer.print("WorldY: {},\n", .{self.worldY});
        try writer.print("Width: {},\n", .{self.width});
        try writer.print("Height: {},\n", .{self.height});

        try writer.writeAll("LayerInstances:");

        for (self.layerInstances, 0..) |value, i| {
            if (i == 0) {
                try writer.writeAll(" [\n");
            }
            try writer.writeAll("{\n");
            try writer.print("{}\n", .{value.*});
            try writer.writeAll("}\n");

            if (i == self.layerInstances.len - 1) {
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
