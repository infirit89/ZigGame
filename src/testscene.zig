const std = @import("std");
const sc = @import("scene.zig");
const pl = @import("player.zig");
const wrld = @import("ldtk/world.zig");
const rl = @import("raylib");
const pt = @import("ldtk/point.zig");

const Scene = sc.Scene;
const Player = pl.Player;
const World = wrld.World;
const Camera2D = rl.Camera2D;
const Rect = rl.Rectangle;
const Tex2D = rl.Texture2D;
const Point = pt.Point;
const Vec2 = rl.Vector2;

pub const TestScene = struct {
    player: Player,
    world: *World,
    camera: Camera2D,
    colliders: std.ArrayList(Rect),
    overworldTexture: Tex2D,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !*TestScene {
        var testScene = try allocator.create(TestScene);
        testScene.overworldTexture = rl.loadTexture(
            "./resources/Overworld.png",
        );

        const mapPath = "./resources/maps/overworld_test.ldtk";
        testScene.world = try World.parse(allocator, mapPath);

        const firstLevel =
            testScene.world.levels.get(
            "32bd3de0-4ce0-11ef-9d65-4f44af904a9c",
        );
        var spawnPoint: Point = undefined;
        for (firstLevel.?.layers) |flLayer| {
            switch (flLayer.type) {
                .Entities => {
                    const playerSpawnPoint = flLayer.entities.get("Player").?;
                    spawnPoint = playerSpawnPoint.worldPos;
                },
                .IntGrid => {
                    testScene.colliders =
                        std.ArrayList(Rect).init(allocator);

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
                                const collider = Rect.init(
                                    @floatFromInt(x),
                                    @floatFromInt(y * 32),
                                    @floatFromInt(size * 32),
                                    32.0,
                                );
                                try testScene.colliders.append(collider);
                                size = 0;
                            }
                        } else if (value == 0) {
                            if (size > 0) {
                                const collider = Rect.init(
                                    @floatFromInt(x * 32),
                                    @floatFromInt(y * 32),
                                    @floatFromInt(size * 32),
                                    32.0,
                                );
                                try testScene.colliders.append(collider);
                                size = 0;
                            }
                        }
                    }
                },
                else => {},
            }
        }

        testScene.player = Player.init(
            @floatFromInt(spawnPoint.x * 2),
            @floatFromInt(spawnPoint.y * 2),
        );
        testScene.camera = .{
            .zoom = 1.5,
            .offset = rl.Vector2.init(600 * 0.5, 360 * 0.5),
            .target = rl.Vector2.init(0, 0),
            .rotation = 0.0,
        };

        return testScene;
    }

    pub fn deinit(self: *TestScene) void {
        rl.unloadTexture(self.overworldTexture);
        self.world.deinit();
        self.colliders.deinit();
        self.player.deinit();
        self.allocator.destroy(self);
    }

    pub fn update(self: *TestScene) !void {
        self.player.update();
        self.camera.target = Vec2.init(
            self.player.drawDestRect.x + 20,
            self.player.drawDestRect.y + 20,
        );
        // rl.drawRectangleRec(playerCollider, rl.Color.dark_green);
        // for (colliders.items) |collider| {
        //     rl.drawRectangleRec(collider, rl.Color.green);
        // }
        for (self.colliders.items) |collider| {
            if (collider.checkCollision(self.player.collider)) {
                const collisionRect = collider.getCollision(
                    self.player.collider,
                );
                if (collisionRect.height >= collisionRect.width) {
                    if (collisionRect.x <= self.player.collider.x + self.player.collider.width * 0.5) {
                        self.player.drawDestRect.x += collisionRect.width;
                    } else {
                        self.player.drawDestRect.x -= collisionRect.width;
                    }
                    self.player.speed.x = 0;
                } else {
                    if (collisionRect.y <= self.player.collider.y + self.player.collider.height * 0.5) {
                        self.player.drawDestRect.y += collisionRect.height;
                    } else {
                        self.player.drawDestRect.y -= collisionRect.height;
                    }
                    self.player.speed.y = 0;
                }
                // rl.drawRectangleRec(collisionRect, rl.Color.red);
                break;
            } else {
                self.player.speed = Vec2.init(1, 1);
            }
        }
    }

    pub fn draw(self: *TestScene) !void {
        rl.beginDrawing();
        defer rl.endDrawing();
        self.camera.begin();
        defer self.camera.end();

        rl.clearBackground(rl.Color.init(25, 25, 25, 255));

        var it = self.world.levels.iterator();
        while (it.next()) |value| {
            const level = value.value_ptr.*;
            const layers = level.layers;
            var i: usize = layers.len - 1;
            while (true) : (i -= 1) {
                const layer = layers[i];
                for (layer.gridTiles) |gridTile| {
                    const tileDest = Rect.init(
                        @floatFromInt(gridTile.px.x * 2 + level.pos.x * 2),
                        @floatFromInt(gridTile.px.y * 2 + level.pos.y * 2),
                        @floatFromInt(layer.size.x * 2),
                        @floatFromInt(layer.size.y * 2),
                    );

                    const tileSrc = Rect.init(
                        @floatFromInt(gridTile.src.x),
                        @floatFromInt(gridTile.src.y),
                        @floatFromInt(layer.size.x),
                        @floatFromInt(layer.size.y),
                    );

                    rl.drawTexturePro(
                        self.overworldTexture,
                        tileSrc,
                        tileDest,
                        Vec2.zero(),
                        0.0,
                        rl.Color.white,
                    );
                }

                if (i == 0)
                    break;
            }
        }

        self.player.draw();
    }

    pub fn scene(self: *TestScene) Scene {
        return Scene.init(self);
    }
};
