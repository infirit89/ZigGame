const std = @import("std");
const lvl = @import("level.zig");
const utils = @import("utils.zig");

const Level = lvl.Level;

pub const World = struct {
    levels: std.StringArrayHashMap(*Level),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !*World {
        const world = try allocator.create(World);
        world.levels = std.StringArrayHashMap(*Level).init(allocator);
        world.allocator = allocator;

        return world;
    }

    pub fn deinit(self: *World) void {
        var it = self.levels.iterator();
        while (it.next()) |value| {
            value.value_ptr.*.deinit();
        }

        self.levels.deinit();
        self.allocator.destroy(self);
    }

    pub fn parse(allocator: std.mem.Allocator, path: []const u8) !*World {
        const parsed = try utils.readFileAndParseJson(
            allocator,
            path,
        );
        defer parsed.deinit();
        const root = parsed.value;
        const levels = root.object.get("levels");
        const world = try World.init(allocator);
        const externalLevels = root.object.get("externalLevels").?.bool;
        for (levels.?.array.items) |item| {
            const levelObject = item.object;
            var level: *Level = undefined;
            if (externalLevels) {
                const externalRelativePath = levelObject.get("externalRelPath").?.string;

                const mapDirectory = std.fs.path.dirname(path);
                const paths = [_][]const u8{ mapDirectory.?, externalRelativePath };
                const levelFilePath = try std.fs.path.join(
                    allocator,
                    &paths,
                );
                const levelData = try utils.readFileAndParseJson(
                    std.heap.page_allocator,
                    levelFilePath,
                );
                defer levelData.deinit();
                level = try Level.parse(allocator, levelData.value);
            } else {} // TODO: load from the levels array
            try world.levels.put(level.iid, level);
        }
        return world;
    }

    // pub fn format(
    //     self: World,
    //     comptime _: []const u8,
    //     _: std.fmt.FormatOptions,
    //     writer: anytype,
    // ) !void {
    //     var it = self.levels.iterator();
    //     while (it.next()) |value| {
    //         try writer.print("{}", .{value.value_ptr.*.*.layerInstances});
    //     }
    // }
};
