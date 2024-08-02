const std = @import("std");
const rl = @import("raylib");

const img = rl.Image;
const tex2d = rl.Texture2D;
const vec2 = rl.Vector2;
const rect = rl.Rectangle;

const GrindTile = struct {
    px: Coordinates,
    src: Coordinates,
    f: u32,
    t: u32,
    d: []u32,
    a: u32,
    const Coordinates = struct {
        x: u32,
        y: u32,
    };
};
const LayerInstance = struct {
    identifier: []u8,
    type: []u8,
    Width: u32,
    Height: u32,
    gridSize: u32,
    opacity: u32,
    pxTotalOffsetX: u32,
    pxTotalOffsetY: u32,
    tileSetDefUid: u32,
    tilesetRelativePath: []u8,
    gridTiles: []GrindTile,
};

const Direction = enum {
    West,
    East,
    South,
    North,
};
const Neighbour = struct {
    levelId: []u8,
    direction: Direction,
};
const Level = struct {
    identifier: []const u8,
    iid: []const u8,
    worldX: i64,
    worldY: i64,
    Width: i64,
    Height: i64,
    layerInstances: ?[]LayerInstance,
    externalRelativePath: ?[]const u8,
    neighbours: []Neighbour,

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
        try writer.print("Width: {},\n", .{self.Width});
        try writer.print("Height: {},\n", .{self.Height});

        if (self.layerInstances != null) {
            unreachable;
        } else {
            try writer.print("LayerInstances: null,\n", .{});
        }

        if (self.externalRelativePath != null) {
            try writer.print("ExternalRelativePath: {s},\n", .{self.externalRelativePath.?});
        } else {
            try writer.print("ExternalRelativePath: null,\n", .{});
        }

        try writer.print("Neighbours: [],\n", .{});
    }
};

const World = struct {
    levels: std.StringHashMap(Level),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !*World {
        const world = try allocator.create(World);
        world.levels = std.StringHashMap(Level).init(allocator);
        world.allocator = allocator;

        return world;
    }

    pub fn deinit(self: *World) void {
        self.levels.deinit();
        self.allocator.destroy(self);
    }
};

pub fn main() !void {
    rl.initWindow(600, 360, "Test window");
    defer rl.closeWindow();
    const characterTex: tex2d = rl.loadTexture("./resources/character.png");
    defer rl.unloadTexture(characterTex);

    const file = try std.fs.cwd().openFile(
        "./resources/maps/overworld_test.ldtk",
        .{},
    );
    defer file.close();

    const file_size = (try file.stat()).size;
    var buffer = try std.heap.page_allocator.alloc(u8, file_size);
    defer std.heap.page_allocator.free(buffer);
    const bytes_read = try file.readAll(buffer);
    std.debug.print("{s}\n", .{buffer[0..bytes_read]});
    const parsed = try std.json.parseFromSlice(std.json.Value, std.heap.page_allocator, buffer[0..bytes_read], .{});
    defer parsed.deinit();
    const root = parsed.value;
    const levels = root.object.get("levels");
    const world = try World.init(std.heap.page_allocator);
    defer world.deinit();

    for (levels.?.array.items) |item| {
        const levelObject = item.object;
        const iid = levelObject.get("iid").?.string;
        // const layerInstance = levelObject.get("layerInstances") orelse null;
        const externalRelativePath = levelObject.get("externalRelPath") orelse null;
        const level: Level = .{
            .identifier = levelObject.get("identifier").?.string,
            .iid = iid,
            .worldX = levelObject.get("worldX").?.integer,
            .worldY = levelObject.get("worldY").?.integer,
            .Width = levelObject.get("pxWid").?.integer,
            .Height = levelObject.get("pxHei").?.integer,
            .layerInstances = null,
            .externalRelativePath = if (externalRelativePath != null) externalRelativePath.?.string else null,
            .neighbours = &[0]Neighbour{},
        };
        try world.levels.put(level.iid, level);
    }

    var it = world.levels.valueIterator();
    while (it.next()) |value| {
        std.debug.print("{s}\n", .{value.*});
    }

    const camera: rl.Camera2D = .{
        .zoom = 1.5,
        .offset = rl.Vector2.init(600 * 0.5, 360 * 0.5),
        .target = rl.Vector2.init(20, 20),
        .rotation = 0.0,
    };
    const src: rl.Rectangle = rl.Rectangle.init(1, 6, 15, 22);
    var dest: rl.Rectangle = rl.Rectangle.init(0, 0, 15 * 2, 22 * 2);
    var velocity: vec2 = vec2.zero();
    while (!rl.windowShouldClose()) {
        velocity = vec2.zero();
        if (rl.isKeyDown(.key_a)) {
            velocity.x -= 1.0;
        } else if (rl.isKeyDown(.key_d)) {
            velocity.x += 1.0;
        }

        if (rl.isKeyDown(.key_w)) {
            velocity.y -= 1.0;
        } else if (rl.isKeyDown(.key_s)) {
            velocity.y += 1.0;
        }
        const drag = 0.03;
        velocity = velocity.normalize();
        velocity = velocity.scale(rl.getFrameTime() * 100.0).scale(1 - drag);
        dest.x += velocity.x;
        dest.y += velocity.y;
        rl.beginDrawing();
        defer rl.endDrawing();
        camera.begin();
        defer camera.end();

        rl.clearBackground(rl.Color.init(25, 25, 25, 255));

        rl.drawTexturePro(characterTex, src, dest, rl.Vector2.zero(), 0.0, rl.Color.white);
    }
}
