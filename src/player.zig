const rl = @import("raylib");

const rect = rl.Rectangle;
const vec2 = rl.Vector2;
const tex2d = rl.Texture2D;

pub const Player = struct {
    collider: rect,
    drawDestRect: rect,
    drawSrcRect: rect,
    speed: vec2 = vec2.init(1, 1),
    characterTexture: tex2d,

    pub fn init(x: f32, y: f32) Player {
        const dest: rl.Rectangle = rect.init(
            x,
            y,
            15 * 2,
            22 * 2,
        );
        return Player{
            .drawDestRect = dest,
            .collider = rect.init(
                x,
                y,
                dest.width - 5.0,
                dest.height * 0.2,
            ),
            .drawSrcRect = rect.init(1, 6, 15, 22),
            .characterTexture = rl.loadTexture(
                "./resources/character.png",
            ),
        };
    }

    pub fn deinit(self: *Player) void {
        rl.unloadTexture(self.characterTexture);
    }

    pub fn update(self: *Player) void {
        var velocity = vec2.zero();
        if (rl.isKeyDown(.key_a)) {
            velocity.x -= self.speed.x;
        } else if (rl.isKeyDown(.key_d)) {
            velocity.x += self.speed.x;
        }

        if (rl.isKeyDown(.key_w)) {
            velocity.y -= self.speed.y;
        } else if (rl.isKeyDown(.key_s)) {
            velocity.y += self.speed.y;
        }
        const drag = 0.03;
        velocity = velocity.normalize();
        velocity = velocity.scale(rl.getFrameTime() * 100.0).scale(1 - drag);
        // const prevX = dest.x;
        // const prevY = dest.y;
        self.drawDestRect.x += velocity.x;
        self.drawDestRect.y += velocity.y;
        self.collider.x = self.drawDestRect.x;
        self.collider.y = self.drawDestRect.y + self.drawDestRect.height * 0.8;
    }

    pub fn draw(self: *const Player) void {
        rl.drawTexturePro(
            self.characterTexture,
            self.drawSrcRect,
            self.drawDestRect,
            vec2.zero(),
            0.0,
            rl.Color.white,
        );
    }
};
