const std = @import("std");
const glib = @import("glib");
const gobject = @import("gobject");
const gtk = @import("gtk");

const Common = @import("../class.zig").Common;
const config = @import("../config.zig");

/// Shows available keys and their labels for the current group.
pub const Cheatsheet = extern struct {
    const Self = @This();
    parent_instance: Parent,

    pub const Parent = gtk.Box;
    pub const getGObjectType = gobject.ext.defineClass(Self, .{
        .name = "LeadrCheatsheet",
        .instanceInit = &init,
        .classInit = &Class.init,
        .parent_class = &Class.parent,
        .private = .{ .Type = Private, .offset = &Private.offset },
    });

    const Private = struct {
        container: *gtk.Box,

        pub var offset: c_int = 0;
    };

    pub fn new() *Self {
        return gobject.ext.newInstance(Self, .{});
    }

    pub fn updateBindings(self: *Self, bindings: []const config.Binding) void {
        const priv = private(self);
        const container = priv.container;

        // Remove all existing children
        while (container.as(gtk.Widget).getFirstChild()) |child| {
            container.remove(child);
        }

        // Add a row for each binding
        for (bindings) |binding| {
            const row = gtk.Box.new(.horizontal, 8);
            row.as(gtk.Widget).addCssClass("cheatsheet-row");

            // Key badge
            var key_buf: [4]u8 = undefined;
            const key_len = std.unicode.utf8Encode(@intCast(binding.key), &key_buf) catch 0;
            var key_str: [5:0]u8 = undefined;
            @memcpy(key_str[0..key_len], key_buf[0..key_len]);
            key_str[key_len] = 0;
            const badge: *gtk.Label = .new(&key_str);
            badge.as(gtk.Widget).addCssClass("key-badge");
            row.append(badge.as(gtk.Widget));

            // Label
            const label_text = glib.ext.dupeZ(u8, binding.label);
            const label: *gtk.Label = .new(label_text);
            glib.free(@ptrCast(@constCast(label_text)));
            label.as(gtk.Widget).addCssClass("key-label");
            label.as(gtk.Widget).setHalign(.start);
            row.append(label.as(gtk.Widget));

            // Group indicator
            switch (binding.action) {
                .group, .sticky => {
                    const arrow: *gtk.Label = .new("\xe2\x80\xba"); // ›
                    arrow.as(gtk.Widget).addCssClass("group-indicator");
                    row.append(arrow.as(gtk.Widget));
                },
                .command, .quit => {},
            }

            container.append(row.as(gtk.Widget));
        }
    }

    fn init(self: *Self, _: *Class) callconv(.c) void {
        gtk.Widget.initTemplate(self.as(gtk.Widget));
    }

    fn dispose(self: *Self) callconv(.c) void {
        gtk.Widget.disposeTemplate(self.as(gtk.Widget), Self.getGObjectType());
        gobject.Object.virtual_methods.dispose.call(
            Class.parent,
            self.as(Parent),
        );
    }

    fn finalize(self: *Self) callconv(.c) void {
        gobject.Object.virtual_methods.finalize.call(
            Class.parent,
            self.as(Parent),
        );
    }

    const C = Common(Self, Private);
    pub const as = C.as;
    pub const ref = C.ref;
    pub const unref = C.unref;
    const private = C.private;

    pub const Class = extern struct {
        parent_class: Parent.Class,
        var parent: *Parent.Class = undefined;
        pub const Instance = Self;
        pub const as = C.Class.as;

        fn init(class: *Class) callconv(.c) void {
            gtk.Widget.Class.setTemplateFromResource(
                class.as(gtk.Widget.Class),
                "/com/leadr/gtk/ui/cheatsheet.ui",
            );
            C.Class.bindTemplateChildPrivate(class, "container", .{});

            gobject.Object.virtual_methods.dispose.implement(class, &dispose);
            gobject.Object.virtual_methods.finalize.implement(class, &finalize);
        }
    };
};
