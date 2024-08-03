const std = @import("std");
const rl = @import("raylib");
const wrld = @import("ldtk/world.zig");
const lvl = @import("ldtk/level.zig");
const nr = @import("ldtk/neighbour.zig");
const li = @import("ldtk/layerinstance.zig");
const gt = @import("ldtk/gridtile.zig");
const utils = @import("ldtk/utils.zig");

const World = wrld.World;
const Level = lvl.Level;
const Neighbour = nr.Neighbour;
const LayerInstance = li.LayerInstance;
const GridTile = gt.GridTile;

const img = rl.Image;
const tex2d = rl.Texture2D;
const vec2 = rl.Vector2;
const rect = rl.Rectangle;

pub fn main() !void {
    rl.initWindow(600, 360, "Test window");
    defer rl.closeWindow();
    const characterTex: tex2d = rl.loadTexture("./resources/character.png");
    defer rl.unloadTexture(characterTex);

    const mapPath = "./resources/maps/overworld_test.ldtk";
    const world = try World.parse(std.heap.page_allocator, mapPath);
    defer world.deinit();

    std.debug.print("{}\n", .{world});

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

        rl.drawTexturePro(
            characterTex,
            src,
            dest,
            rl.Vector2.zero(),
            0.0,
            rl.Color.white,
        );
    }
}
