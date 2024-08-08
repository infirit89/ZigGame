pub const Scene = struct {
    ptr: *anyopaque,
    updateFn: *const fn (ptr: *anyopaque) anyerror!void,
    drawFn: *const fn (ptr: *anyopaque) anyerror!void,

    pub fn init(ptr: anytype) Scene {
        const T = @TypeOf(ptr);
        const ptrInfo = @typeInfo(T);

        const gen = struct {
            pub fn update(pointer: *anyopaque) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                return ptrInfo.Pointer.child.update(self);
            }

            pub fn draw(pointer: *anyopaque) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                return ptrInfo.Pointer.child.draw(self);
            }
        };

        return Scene{
            .ptr = ptr,
            .updateFn = gen.update,
            .drawFn = gen.draw,
        };
    }

    pub fn update(self: Scene) !void {
        return self.updateFn(self.ptr);
    }

    pub fn draw(self: Scene) !void {
        return self.drawFn(self.ptr);
    }
};
