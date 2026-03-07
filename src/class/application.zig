const std = @import("std");
const adw = @import("adw");
const gdk = @import("gdk");
const gio = @import("gio");
const glib = @import("glib");
const gobject = @import("gobject");
const gtk = @import("gtk");

const Common = @import("../class.zig").Common;
const OverlayWindow = @import("overlay_window.zig").OverlayWindow;

pub const Application = extern struct {
    const Self = @This();
    parent_instance: Parent,

    pub const Parent = adw.Application;
    pub const getGObjectType = gobject.ext.defineClass(Self, .{
        .name = "LeadrApplication",
        .classInit = &Class.init,
        .parent_class = &Class.parent,
        .private = .{ .Type = Private, .offset = &Private.offset },
    });

    const Private = struct {
        overlay_window: ?*OverlayWindow = null,
        css_provider: ?*gtk.CssProvider = null,

        pub var offset: c_int = 0;
    };

    pub fn new() *Self {
        return gobject.ext.newInstance(Self, .{
            .@"application-id" = @as(?[*:0]const u8, "com.leadr.gtk"),
            .flags = gio.ApplicationFlags{ .handles_command_line = true },
        });
    }

    fn startup(self: *Self) callconv(.c) void {
        gio.Application.virtual_methods.startup.call(Class.parent, self.as(Parent));

        const priv = private(self);

        // Load CSS
        const css_provider = gtk.CssProvider.new();
        css_provider.loadFromResource("/com/leadr/gtk/style.css");
        gtk.StyleContext.addProviderForDisplay(
            gdk.Display.getDefault().?,
            css_provider.as(gtk.StyleProvider),
            gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        );
        priv.css_provider = css_provider;

        // Create overlay window
        const window = OverlayWindow.new();
        window.as(gtk.Window).setApplication(self.as(gtk.Application));
        priv.overlay_window = window;
    }

    fn activate(self: *Self) callconv(.c) void {
        gio.Application.virtual_methods.activate.call(Class.parent, self.as(Parent));

        const priv = private(self);
        if (priv.overlay_window) |window| {
            window.toggle();
        }
    }

    fn commandLine(
        self: *Self,
        cmdline: *gio.ApplicationCommandLine,
    ) callconv(.c) c_int {
        _ = cmdline;
        // Every invocation (including remote) triggers activate to toggle
        self.as(gio.Application).activate();
        return 0;
    }

    fn dispose(self: *Self) callconv(.c) void {
        const priv = private(self);

        if (priv.overlay_window) |w| {
            w.unref();
            priv.overlay_window = null;
        }

        if (priv.css_provider) |p| {
            p.unref();
            priv.css_provider = null;
        }

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

        fn init(class: *Class) callconv(.c) void {
            gobject.ext.ensureType(OverlayWindow);
            gio.Application.virtual_methods.startup.implement(class, &startup);
            gio.Application.virtual_methods.activate.implement(class, &activate);
            gio.Application.virtual_methods.command_line.implement(class, &commandLine);
            gobject.Object.virtual_methods.dispose.implement(class, &dispose);
            gobject.Object.virtual_methods.finalize.implement(class, &finalize);
        }
    };
};
