const std = @import("std");
const rl = @import("raylib");
const wrld = @import("ldtk/world.zig");
const pt = @import("ldtk/point.zig");
const tsc = @import("testscene.zig");
const pl = @import("player.zig");

const World = wrld.World;
const Point = pt.Point;
const TestScene = tsc.TestScene;
const Player = pl.Player;

const img = rl.Image;
const tex2d = rl.Texture2D;
const vec2 = rl.Vector2;
const rect = rl.Rectangle;

pub fn main() !void {
    rl.initWindow(600, 360, "Test window");
    defer rl.closeWindow();

    var testScene = try TestScene.init(std.heap.page_allocator);
    var scene = testScene.scene();
    while (!rl.windowShouldClose()) {
        try scene.update();
        try scene.draw();
    }
}
