const std = @import("std");
const gdk = @import("gdk");
const gio = @import("gio");
const glib = @import("glib");
const gobject = @import("gobject");
const gtk = @import("gtk");

const Common = @import("../class.zig").Common;
const KeyIndicator = @import("key_indicator.zig").KeyIndicator;
const Cheatsheet = @import("cheatsheet.zig").Cheatsheet;
const config = @import("../config.zig");
const keys = @import("../keys.zig");
const layer_shell = @import("gtk4_layer_shell");

/// Layer-shell overlay window containing key indicator and cheatsheet.
pub const OverlayWindow = extern struct {
    const Self = @This();
    parent_instance: Parent,

    pub const Parent = gtk.Window;
    pub const getGObjectType = gobject.ext.defineClass(Self, .{
        .name = "LeadrOverlayWindow",
        .instanceInit = &init,
        .classInit = &Class.init,
        .parent_class = &Class.parent,
        .private = .{ .Type = Private, .offset = &Private.offset },
    });

    const Private = struct {
        navigator: config.Navigator,
        key_indicator: *KeyIndicator,
        cheatsheet: *Cheatsheet,
        sticky_timer: c_uint = 0,
        sticky_timeout_ms: c_uint = 0,

        pub var offset: c_int = 0;
    };

    pub fn new() *Self {
        const self = gobject.ext.newInstance(Self, .{});
        return self;
    }

    pub fn toggle(self: *Self) void {
        const widget = self.as(gtk.Widget);
        if (widget.getVisible() != 0) {
            self.hideOverlay();
        } else {
            self.showOverlay();
        }
    }

    fn showOverlay(self: *Self) void {
        const priv = private(self);
        priv.navigator.reset(keys.bindings);
        priv.key_indicator.setDisplayKey(null);
        priv.cheatsheet.updateBindings(priv.navigator.current());
        self.as(gtk.Widget).setVisible(@intFromBool(true));
        self.as(gtk.Window).present();
    }

    fn hideOverlay(self: *Self) void {
        clearStickyState(self);
        self.as(gtk.Widget).setVisible(@intFromBool(false));
    }

    fn handleKeyPress(self: *Self, keyval: c_uint) void {
        const priv = private(self);

        // Escape: hide and reset
        if (keyval == 0xff1b) { // GDK_KEY_Escape
            self.hideOverlay();
            return;
        }

        // Backspace: go up one level (clears sticky if leaving sticky group)
        if (keyval == 0xff08) { // GDK_KEY_BackSpace
            clearStickyState(self);
            if (!priv.navigator.pop()) {
                self.hideOverlay();
                return;
            }
            priv.key_indicator.setDisplayKey(null);
            priv.cheatsheet.updateBindings(priv.navigator.current());
            return;
        }

        // Convert keyval to unicode
        const unicode: u21 = @intCast(gdk.keyvalToUnicode(keyval));
        if (unicode == 0) return;

        if (priv.navigator.lookup(unicode)) |binding| {
            // Show the pressed key
            var key_buf: [4]u8 = undefined;
            const key_len = std.unicode.utf8Encode(unicode, &key_buf) catch return;
            var key_str: [5:0]u8 = undefined;
            @memcpy(key_str[0..key_len], key_buf[0..key_len]);
            key_str[key_len] = 0;
            priv.key_indicator.setDisplayKey(&key_str);

            switch (binding.action) {
                .group => |group| {
                    priv.navigator.push(group);
                    priv.cheatsheet.updateBindings(priv.navigator.current());
                },
                .sticky => |sticky| {
                    priv.navigator.push(sticky.bindings);
                    priv.sticky_timeout_ms = sticky.timeout_ms;
                    priv.cheatsheet.updateBindings(priv.navigator.current());
                    resetStickyTimer(self);
                },
                .command => |cmd| {
                    if (priv.sticky_timeout_ms != 0) {
                        // In sticky mode: execute but stay open, reset timer
                        spawnCommand(cmd);
                        resetStickyTimer(self);
                    } else {
                        self.hideOverlay();
                        spawnCommand(cmd);
                    }
                },
                .quit => {
                    self.hideOverlay();
                    if (self.as(gtk.Window).getApplication()) |app| {
                        app.as(gio.Application).quit();
                    }
                },
            }
        }
    }

    fn resetStickyTimer(self: *Self) void {
        const priv = private(self);
        if (priv.sticky_timer != 0) {
            _ = glib.Source.remove(priv.sticky_timer);
        }
        priv.sticky_timer = glib.timeoutAdd(priv.sticky_timeout_ms, &onStickyTimeout, self);
    }

    fn clearStickyState(self: *Self) void {
        const priv = private(self);
        if (priv.sticky_timer != 0) {
            _ = glib.Source.remove(priv.sticky_timer);
            priv.sticky_timer = 0;
        }
        priv.sticky_timeout_ms = 0;
    }

    fn onStickyTimeout(ud: ?*anyopaque) callconv(.c) c_int {
        const self: *Self = @ptrCast(@alignCast(ud orelse return 0));
        const priv = private(self);
        priv.sticky_timer = 0;
        self.hideOverlay();
        return 0; // G_SOURCE_REMOVE
    }

    fn spawnCommand(cmd: []const u8) void {
        // Null-terminate the command for C
        var buf: [4096:0]u8 = undefined;
        if (cmd.len >= buf.len) return;
        @memcpy(buf[0..cmd.len], cmd);
        buf[cmd.len] = 0;
        _ = glib.spawnCommandLineAsync(&buf, null);
    }

    fn onKeyPressed(
        _: *gtk.EventControllerKey,
        keyval: c_uint,
        _: c_uint,
        _: gdk.ModifierType,
        self: *Self,
    ) callconv(.c) c_int {
        self.handleKeyPress(keyval);
        return 1; // handled
    }

    fn init(self: *Self, _: *Class) callconv(.c) void {
        gtk.Widget.initTemplate(self.as(gtk.Widget));

        const window = self.as(gtk.Window);

        // Layer shell setup
        if (layer_shell.isSupported() != 0) {
            layer_shell.initForWindow(window);
            layer_shell.setLayer(window, .overlay);
            layer_shell.setKeyboardMode(window, .exclusive);
            layer_shell.setNamespace(window, "leadrgtk");
        }

        // Key event controller
        const key_controller = gtk.EventControllerKey.new();
        _ = gtk.EventControllerKey.signals.key_pressed.connect(
            key_controller,
            *Self,
            &onKeyPressed,
            self,
            .{},
        );
        self.as(gtk.Widget).addController(key_controller.as(gtk.EventController));

        // Navigator state
        const priv = private(self);
        priv.navigator = config.Navigator.init(keys.bindings);
        priv.cheatsheet.updateBindings(priv.navigator.current());
    }

    fn dispose(self: *Self) callconv(.c) void {
        clearStickyState(self);
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
            gobject.ext.ensureType(KeyIndicator);
            gobject.ext.ensureType(Cheatsheet);

            gtk.Widget.Class.setTemplateFromResource(
                class.as(gtk.Widget.Class),
                "/com/leadr/gtk/ui/overlay-window.ui",
            );
            C.Class.bindTemplateChildPrivate(class, "key_indicator", .{});
            C.Class.bindTemplateChildPrivate(class, "cheatsheet", .{});

            gobject.Object.virtual_methods.dispose.implement(class, &dispose);
            gobject.Object.virtual_methods.finalize.implement(class, &finalize);
        }
    };
};

