const std = @import("std");
const rl = @import("raylib");
const wrld = @import("ldtk/world.zig");
const lvl = @import("ldtk/level.zig");
const nr = @import("ldtk/neighbour.zig");
const li = @import("ldtk/layerinstance.zig");
const gt = @import("ldtk/gridtile.zig");
const utils = @import("ldtk/utils.zig");
const pt = @import("ldtk/point.zig");

const World = wrld.World;
const Level = lvl.Level;
const Neighbour = nr.Neighbour;
const GridTile = gt.GridTile;
const LayerType = li.LayerType;
const Point = pt.Point;

const img = rl.Image;
const tex2d = rl.Texture2D;
const vec2 = rl.Vector2;
const rect = rl.Rectangle;

pub fn main() !void {
    rl.initWindow(600, 360, "Test window");
    defer rl.closeWindow();
    const characterTex: tex2d = rl.loadTexture("./resources/character.png");
    defer rl.unloadTexture(characterTex);
    const overworld: tex2d = rl.loadTexture("./resources/Overworld.png");
    defer rl.unloadTexture(overworld);

    const mapPath = "./resources/maps/overworld_test.ldtk";
    const world = try World.parse(std.heap.page_allocator, mapPath);
    defer world.deinit();

    std.debug.print("{}\n", .{world});
    var colliders: std.ArrayList(rect) = undefined;
    defer colliders.deinit();

    const firstLevel = world.levels.get("32bd3de0-4ce0-11ef-9d65-4f44af904a9c");
    var spawnPoint: Point = undefined;
    for (firstLevel.?.layers) |flLayer| {
        switch (flLayer.type) {
            .Entities => {
                const playerSpawnPoint = flLayer.entities.get("Player").?;
                spawnPoint = playerSpawnPoint.worldPos;
            },
            .IntGrid => {
                colliders = std.ArrayList(rect).init(std.heap.page_allocator);

                var size: i64 = 0;
                var x: i64 = 0;
                var y: i64 = 0;
                var i: usize = 0;
                while (i < flLayer.intGrid.len) {
                    defer i += 1;
                    const value = flLayer.intGrid[i];
                    const index: i64 = @intCast(i);
                    if (value == 1) {
                        if (size == 0) {
                            x = @mod(index, flLayer.gridSize);
                            y = @divFloor(index, flLayer.gridSize);
                        }
                        size += 1;
                        if (@mod(size, flLayer.gridSize) == 0) {
                            const collider = rect.init(
                                @floatFromInt(x),
                                @floatFromInt(y * 32),
                                @floatFromInt(size * 32),
                                32.0,
                            );
                            try colliders.append(collider);
                            size = 0;
                        }
                    } else if (value == 0) {
                        if (size > 0) {
                            const collider = rect.init(
                                @floatFromInt(x * 32),
                                @floatFromInt(y * 32),
                                @floatFromInt(size * 32),
                                32.0,
                            );
                            try colliders.append(collider);
                            size = 0;
                        }
                    }
                }
            },
            else => {},
        }
    }

    var dest: rl.Rectangle = rect.init(
        @floatFromInt(spawnPoint.x * 2),
        @floatFromInt(spawnPoint.y * 2),
        15 * 2,
        22 * 2,
    );
    var camera: rl.Camera2D = .{
        .zoom = 1.5,
        .offset = rl.Vector2.init(600 * 0.5, 360 * 0.5),
        .target = rl.Vector2.init(dest.x + 20, dest.y + 20),
        .rotation = 0.0,
    };
    var playerCollider: rect = rect.init(
        dest.x,
        dest.y * 5,
        dest.width - 5,
        dest.height * 0.2,
    );
    const src: rl.Rectangle = rl.Rectangle.init(1, 6, 15, 22);
    var velocity: vec2 = vec2.zero();
    var rotation: f32 = 0.0;
    var speed: vec2 = vec2.init(1, 1);
    while (!rl.windowShouldClose()) {
        velocity = vec2.zero();
        if (rl.isKeyDown(.key_a)) {
            velocity.x -= speed.x;
        } else if (rl.isKeyDown(.key_d)) {
            velocity.x += speed.x;
        }

        if (rl.isKeyDown(.key_w)) {
            velocity.y -= speed.y;
        } else if (rl.isKeyDown(.key_s)) {
            velocity.y += speed.y;
        }
        camera.target = vec2.init(dest.x + 20.0, dest.y + 20.0);
        if (rl.isKeyDown(.key_r)) {
            rotation += 1;
        }
        const drag = 0.03;
        velocity = velocity.normalize();
        velocity = velocity.scale(rl.getFrameTime() * 100.0).scale(1 - drag);
        // const prevX = dest.x;
        // const prevY = dest.y;
        dest.x += velocity.x;
        dest.y += velocity.y;
        playerCollider.x = dest.x;
        playerCollider.y = dest.y + dest.height * 0.8;

        rl.beginDrawing();
        defer rl.endDrawing();
        camera.begin();
        defer camera.end();

        rl.clearBackground(rl.Color.init(25, 25, 25, 255));

        var it = world.levels.iterator();
        while (it.next()) |value| {
            const level = value.value_ptr.*;
            const layers = level.layers;
            var i: usize = layers.len - 1;
            while (true) : (i -= 1) {
                const layer = layers[i];
                for (layer.gridTiles) |gridTile| {
                    const tileDest = rect.init(
                        @floatFromInt(gridTile.px.x * 2 + level.pos.x * 2),
                        @floatFromInt(gridTile.px.y * 2 + level.pos.y * 2),
                        @floatFromInt(layer.size.x * 2),
                        @floatFromInt(layer.size.y * 2),
                    );

                    const tileSrc = rect.init(
                        @floatFromInt(gridTile.src.x),
                        @floatFromInt(gridTile.src.y),
                        @floatFromInt(layer.size.x),
                        @floatFromInt(layer.size.y),
                    );

                    rl.drawTexturePro(
                        overworld,
                        tileSrc,
                        tileDest,
                        vec2.zero(),
                        0.0,
                        rl.Color.white,
                    );
                }

                if (i == 0)
                    break;
            }
        }

        // rl.drawRectangleRec(playerCollider, rl.Color.dark_green);
        // for (colliders.items) |collider| {
        //     rl.drawRectangleRec(collider, rl.Color.green);
        // }
        for (colliders.items) |collider| {
            if (collider.checkCollision(playerCollider)) {
                const collisionRect = collider.getCollision(playerCollider);
                if (collisionRect.height >= collisionRect.width) {
                    if (collisionRect.x <= playerCollider.x + playerCollider.width * 0.5) {
                        dest.x += collisionRect.width;
                    } else {
                        dest.x -= collisionRect.width;
                    }
                    speed.x = 0;
                } else {
                    if (collisionRect.y <= playerCollider.y + playerCollider.height * 0.5) {
                        dest.y += collisionRect.height;
                    } else {
                        dest.y -= collisionRect.height;
                    }
                    speed.y = 0;
                }
                // rl.drawRectangleRec(collisionRect, rl.Color.red);
                break;
            } else {
                speed = vec2.init(1, 1);
            }
        }
        rl.drawTexturePro(
            characterTex,
            src,
            dest,
            vec2.zero(),
            rotation,
            rl.Color.white,
        );
    }
}
