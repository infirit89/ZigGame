const std = @import("std");
const rl = @import("raylib");

const img = rl.Image;
const tex2d = rl.Texture2D;

pub fn main() !void {
    rl.initWindow(600, 360, "Test window");
    defer rl.closeWindow();
    const character: img = rl.loadImage("./resources/character.png");
    defer rl.unloadImage(character);
    const characterTex: tex2d = rl.loadTextureFromImage(character);
    defer rl.unloadTexture(characterTex);

    const src: rl.Rectangle = rl.Rectangle.init(1, 6, 15, 22);
    const dest: rl.Rectangle = rl.Rectangle.init(0, 0, 15 * 2, 22 * 2);
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.init(25, 25, 25, 255));

        rl.drawTexturePro(characterTex, src, dest, rl.Vector2.zero(), 0.0, rl.Color.white);
    }
}
