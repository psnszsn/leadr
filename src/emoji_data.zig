const std = @import("std");
const glib = @import("glib");

pub const Emoji = struct {
    glyph: [:0]const u8,
    name: [:0]const u8,
};

pub const EmojiList = struct {
    emojis: []Emoji,
    allocator: std.mem.Allocator,

    const dict_path: [*:0]const u8 = "/usr/share/speech-dispatcher/locale/en/emojis.dic";

    pub fn load(allocator: std.mem.Allocator) !EmojiList {
        var contents: [*]u8 = undefined;
        var length: usize = 0;
        if (glib.fileGetContents(dict_path, &contents, &length, null) == 0) {
            return error.FileNotFound;
        }
        defer glib.free(@ptrCast(contents));

        const content: []const u8 = contents[0..length];

        var emojis: std.ArrayList(Emoji) = .empty;
        errdefer {
            for (emojis.items) |e| {
                allocator.free(e.glyph);
                allocator.free(e.name);
            }
            emojis.deinit(allocator);
        }

        var lines = std.mem.splitSequence(u8, content, "\r\n");
        while (lines.next()) |line| {
            if (line.len == 0) continue;
            if (line[0] == '#') continue;
            if (std.mem.startsWith(u8, line, "symbols:")) continue;

            // Tab-separated: glyph\tname\tnone
            var fields = std.mem.splitScalar(u8, line, '\t');
            const glyph_raw = fields.next() orelse continue;
            const name_raw = fields.next() orelse continue;

            if (glyph_raw.len == 0) continue;

            // Skip skin tone variants
            if (std.mem.indexOf(u8, name_raw, "skin tone") != null) continue;

            // Keep only 4-byte UTF-8 sequences (U+10000+), which covers virtually all emojis
            // and excludes currency symbols, arrows, and other BMP symbols
            if (glyph_raw[0] < 0xF0) continue;

            const glyph = try allocator.dupeZ(u8, glyph_raw);
            errdefer allocator.free(glyph);
            const name = try allocator.dupeZ(u8, name_raw);
            errdefer allocator.free(name);

            try emojis.append(allocator, .{ .glyph = glyph, .name = name });
        }

        return .{
            .emojis = try emojis.toOwnedSlice(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *EmojiList) void {
        for (self.emojis) |e| {
            self.allocator.free(e.glyph);
            self.allocator.free(e.name);
        }
        self.allocator.free(self.emojis);
        self.emojis = &.{};
    }
};
