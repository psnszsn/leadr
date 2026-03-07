const std = @import("std");
const gobject = @import("gobject");

/// A lightweight wrapper around gobject.WeakRef to make it type-safe.
pub fn WeakRef(comptime T: type) type {
    return struct {
        const Self = @This();

        ref: gobject.WeakRef = std.mem.zeroes(gobject.WeakRef),

        pub const empty: Self = .{};

        pub fn set(self: *Self, v_: ?*T) void {
            if (v_) |v| {
                self.ref.set(v.as(gobject.Object));
            } else {
                self.ref.set(null);
            }
        }

        pub fn get(self: *Self) ?*T {
            return gobject.ext.cast(T, self.ref.get() orelse return null);
        }
    };
}
