const std = @import("std");
const rl = @import("raylib");

const img = rl.Image;
const tex2d = rl.Texture2D;
const vec2 = rl.Vector2;
const rect = rl.Rectangle;

const GridTile = struct {
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
    identifier: []const u8,
    type: []const u8,
    width: i64,
    height: i64,
    gridSize: i64,
    opacity: i64,
    pxTotalOffsetX: i64,
    pxTotalOffsetY: i64,
    tilesetRelativePath: []const u8,
    gridTiles: std.ArrayList(GridTile),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !*LayerInstance {
        var layerInstance = try allocator.create(LayerInstance);
        layerInstance.gridTiles = std.ArrayList(GridTile).init(allocator);
        layerInstance.allocator = allocator;
        return layerInstance;
    }

    pub fn deinit(self: *LayerInstance) void {
        self.gridTiles.deinit();
        self.allocator.destroy(self);
    }
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
    width: i64,
    height: i64,
    layerInstances: ?std.ArrayList(*LayerInstance),
    neighbours: std.ArrayList(Neighbour),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !*Level {
        const level = try allocator.create(Level);
        level.allocator = allocator;
        level.neighbours = std.ArrayList(Neighbour).init(allocator);
        return level;
    }

    pub fn deinit(self: *Level) void {
        if (self.layerInstances) |layerInstances| {
            for (layerInstances.items) |layerInstance| {
                std.debug.print("cum cum cum cum cum cum cum\n", .{});
                layerInstance.*.deinit();
            }
            layerInstances.deinit();
        }

        self.neighbours.deinit();
        self.allocator.destroy(self);
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

        if (self.layerInstances != null) {} else {
            try writer.print("LayerInstances: null,\n", .{});
        }

        try writer.print("Neighbours: [],\n", .{});
    }
};

const World = struct {
    levels: std.StringHashMap(*Level),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !*World {
        const world = try allocator.create(World);
        world.levels = std.StringHashMap(*Level).init(allocator);
        world.allocator = allocator;

        return world;
    }

    pub fn deinit(self: *World) void {
        var it = self.levels.valueIterator();
        while (it.next()) |value| {
            value.*.deinit();
        }

        self.levels.deinit();
        self.allocator.destroy(self);
    }
};

fn readFileAndParseJson(allocator: std.mem.Allocator, path: []const u8) !std.json.Parsed(std.json.Value) {
    const file = try std.fs.cwd().openFile(
        path,
        .{},
    );
    defer file.close();

    const file_size = (try file.stat()).size;
    var buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);
    const bytes_read = try file.readAll(buffer);
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, buffer[0..bytes_read], .{});
    return parsed;
}

pub fn main() !void {
    rl.initWindow(600, 360, "Test window");
    defer rl.closeWindow();
    const characterTex: tex2d = rl.loadTexture("./resources/character.png");
    defer rl.unloadTexture(characterTex);

    const mapDirectory = "./resources/maps/";
    const parsed = try readFileAndParseJson(std.heap.page_allocator, mapDirectory ++ "overworld_test.ldtk");
    defer parsed.deinit();
    const root = parsed.value;
    const levels = root.object.get("levels");
    const world = try World.init(std.heap.page_allocator);
    defer world.deinit();

    for (levels.?.array.items) |item| {
        const levelObject = item.object;
        const iid = levelObject.get("iid").?.string;
        // const layerInstance = levelObject.get("layerInstances") orelse null;
        const externalRelativePath = levelObject.get("externalRelPath");
        var level = try Level.init(std.heap.page_allocator);

        level.identifier = levelObject.get("identifier").?.string;
        level.iid = iid;
        level.worldX = levelObject.get("worldX").?.integer;
        level.worldY = levelObject.get("worldY").?.integer;
        level.width = levelObject.get("pxWid").?.integer;
        level.height = levelObject.get("pxHei").?.integer;
        level.layerInstances = null;

        if (externalRelativePath) |value| {
            std.debug.print("{s}\n", .{value.string});
            level.layerInstances = std.ArrayList(*LayerInstance).init(std.heap.page_allocator);

            const paths = [_][]const u8{ mapDirectory, value.string };
            const levelFilePath = try std.fs.path.join(std.heap.page_allocator, &paths);
            const parsedLayerInstanceData = try readFileAndParseJson(std.heap.page_allocator, levelFilePath);
            defer parsedLayerInstanceData.deinit();
            const layerInstances = parsedLayerInstanceData.value.object.get("layerInstances").?.array;

            for (layerInstances.items) |jsonLayerInstance| {
                const layerInstanceObject = jsonLayerInstance.object;
                var layerInstance = try LayerInstance.init(std.heap.page_allocator);
                layerInstance.identifier = layerInstanceObject.get("__identifier").?.string;
                layerInstance.type = layerInstanceObject.get("__type").?.string;
                layerInstance.width = layerInstanceObject.get("__cWid").?.integer;
                layerInstance.height = layerInstanceObject.get("__cHei").?.integer;
                layerInstance.gridSize = layerInstanceObject.get("__gridSize").?.integer;
                layerInstance.opacity = layerInstanceObject.get("__opacity").?.integer;
                layerInstance.pxTotalOffsetX = layerInstanceObject.get("__pxTotalOffsetX").?.integer;
                layerInstance.pxTotalOffsetY = layerInstanceObject.get("__pxTotalOffsetY").?.integer;
                layerInstance.tilesetRelativePath = layerInstanceObject.get("__tilesetRelPath").?.string;

                try level.layerInstances.?.append(layerInstance);
            }
        }

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
