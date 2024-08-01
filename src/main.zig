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
    __identifier: []u8,
    __type: []u8,
    __cWid: u32,
    __cHei: u32,
    __gridSize: u32,
    __opacity: u32,
    __pxTotalOffsetX: u32,
    __pxTotalOffsetY: u32,
    __tileSetDefUid: u32,
    __tilesetRelPath: []u8,
    gridTiles: []GrindTile,
};

const Level = struct {
    identifier: []u8,
    layerInstances: []LayerInstance,
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
    std.debug.print("{s}\n", .{root.object.get("levels").?.array.items[0].object.get("identifier").?.string});
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
