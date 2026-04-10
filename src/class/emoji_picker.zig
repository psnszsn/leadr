const std = @import("std");
const gdk = @import("gdk");
const glib = @import("glib");
const gobject = @import("gobject");
const gtk = @import("gtk");

const Common = @import("../class.zig").Common;
const EmojiData = @import("../emoji_data.zig");
const layer_shell = @import("gtk4_layer_shell");

pub const EmojiPicker = extern struct {
    const Self = @This();
    parent_instance: Parent,

    pub const Parent = gtk.Window;
    pub const getGObjectType = gobject.ext.defineClass(Self, .{
        .name = "LeadrEmojiPicker",
        .instanceInit = &init,
        .classInit = &Class.init,
        .parent_class = &Class.parent,
        .private = .{ .Type = Private, .offset = &Private.offset },
    });

    const Private = struct {
        search_entry: *gtk.SearchEntry,
        emoji_flow: *gtk.FlowBox,
        preview_glyph: *gtk.Label,
        preview_name: *gtk.Label,
        emoji_data: ?EmojiData.EmojiList = null,

        pub var offset: c_int = 0;
    };

    fn init(self: *Self, _: *Class) callconv(.c) void {
        gtk.Widget.initTemplate(self.as(gtk.Widget));

        const window = self.as(gtk.Window);
        const priv = private(self);

        // Layer shell setup
        if (layer_shell.isSupported() != 0) {
            layer_shell.initForWindow(window);
            layer_shell.setLayer(window, .overlay);
            layer_shell.setKeyboardMode(window, .exclusive);
            layer_shell.setNamespace(window, "leadrgtk-emoji");
        }

        // Key event controller for Escape
        const key_controller = gtk.EventControllerKey.new();
        _ = gtk.EventControllerKey.signals.key_pressed.connect(
            key_controller,
            *Self,
            &onKeyPressed,
            self,
            .{},
        );
        self.as(gtk.Widget).addController(key_controller.as(gtk.EventController));

        // Load emoji data
        const emoji_list = EmojiData.EmojiList.load(std.heap.page_allocator) catch {
            return;
        };
        priv.emoji_data = emoji_list;

        // Populate FlowBox
        for (emoji_list.emojis, 0..) |emoji, i| {
            const label: *gtk.Label = .new(emoji.glyph);
            label.as(gtk.Widget).addCssClass("emoji-cell");
            // Store index as widget name for retrieval
            var name_buf: [16:0]u8 = undefined;
            const name_slice = std.fmt.bufPrint(&name_buf, "{d}", .{i}) catch continue;
            name_buf[name_slice.len] = 0;
            label.as(gtk.Widget).setName(&name_buf);
            // Set tooltip to emoji name for accessibility and search
            label.as(gtk.Widget).setTooltipText(emoji.name);
            priv.emoji_flow.insert(label.as(gtk.Widget), -1);
        }

        // Connect search filtering
        _ = gtk.SearchEntry.signals.search_changed.connect(
            priv.search_entry,
            *Self,
            &onSearchChanged,
            self,
            .{},
        );

        // Connect child activation (click)
        _ = gtk.FlowBox.signals.child_activated.connect(
            priv.emoji_flow,
            *Self,
            &onChildActivated,
            self,
            .{},
        );

        // Set filter function
        priv.emoji_flow.setFilterFunc(
            &filterFunc,
            self,
            null,
        );

        // Selection changed (keyboard navigation)
        _ = gtk.FlowBox.signals.selected_children_changed.connect(
            priv.emoji_flow,
            *Self,
            &onSelectionChanged,
            self,
            .{},
        );

        // Motion controller for hover preview
        const motion = gtk.EventControllerMotion.new();
        _ = gtk.EventControllerMotion.signals.motion.connect(
            motion,
            *Self,
            &onMotion,
            self,
            .{},
        );
        priv.emoji_flow.as(gtk.Widget).addController(motion.as(gtk.EventController));
    }

    pub fn grabSearchFocus(self: *Self) void {
        const priv = private(self);
        _ = priv.search_entry.as(gtk.Widget).grabFocus();
    }

    fn onKeyPressed(
        _: *gtk.EventControllerKey,
        keyval: c_uint,
        _: c_uint,
        modifiers: gdk.ModifierType,
        self: *Self,
    ) callconv(.c) c_int {
        if (keyval == 0xff1b) { // GDK_KEY_Escape
            self.as(gtk.Widget).setVisible(@intFromBool(false));
            return 1;
        }

        const ctrl = modifiers.control_mask;

        // Ctrl+N → move selection down, Ctrl+P → move selection up
        if (ctrl) {
            const priv = private(self);
            if (keyval == 'n') {
                _ = priv.emoji_flow.as(gtk.Widget).childFocus(.tab_forward);
                return 1;
            }
            if (keyval == 'p') {
                _ = priv.emoji_flow.as(gtk.Widget).childFocus(.tab_backward);
                return 1;
            }
        }

        // Enter → activate selected emoji
        if (keyval == 0xff0d) { // GDK_KEY_Return
            const priv = private(self);
            const selected = priv.emoji_flow.getSelectedChildren();
            const child: *gtk.FlowBoxChild = @ptrCast(@alignCast(selected.f_data orelse return 0));
            onChildActivated(priv.emoji_flow, child, self);
            return 1;
        }

        // Any printable key without Ctrl → focus search entry
        if (!ctrl) {
            const priv = private(self);
            const search_widget = priv.search_entry.as(gtk.Widget);
            if (search_widget.hasFocus() == 0) {
                _ = search_widget.grabFocus();
                // If it's a printable character, let it propagate to the now-focused entry
            }
        }

        return 0;
    }

    fn onSelectionChanged(
        flow: *gtk.FlowBox,
        self: *Self,
    ) callconv(.c) void {
        const selected = flow.getSelectedChildren();
        const child: *gtk.FlowBoxChild = @ptrCast(@alignCast(selected.f_data orelse return));
        updatePreview(self, child);
    }

    fn updatePreview(self: *Self, child: *gtk.FlowBoxChild) void {
        const priv = private(self);
        const widget = child.as(gtk.Widget);
        const first_child = widget.getFirstChild() orelse return;
        const name_ptr: [*:0]const u8 = first_child.getName();
        const name_slice = std.mem.span(name_ptr);
        const idx = std.fmt.parseInt(usize, name_slice, 10) catch return;
        const emoji_data = priv.emoji_data orelse return;
        if (idx >= emoji_data.emojis.len) return;
        priv.preview_glyph.setLabel(emoji_data.emojis[idx].glyph);
        priv.preview_name.setLabel(emoji_data.emojis[idx].name);
    }

    fn onMotion(
        _: *gtk.EventControllerMotion,
        x: f64,
        y: f64,
        self: *Self,
    ) callconv(.c) void {
        const priv = private(self);
        const child = priv.emoji_flow.getChildAtPos(@intFromFloat(x), @intFromFloat(y)) orelse return;
        updatePreview(self, child);
    }

    fn onSearchChanged(
        _: *gtk.SearchEntry,
        self: *Self,
    ) callconv(.c) void {
        const priv = private(self);
        priv.emoji_flow.invalidateFilter();
    }

    fn filterFunc(child: *gtk.FlowBoxChild, ud: ?*anyopaque) callconv(.c) c_int {
        const self: *Self = @ptrCast(@alignCast(ud orelse return 1));
        const priv = private(self);

        const search: [*:0]const u8 = priv.search_entry.as(gtk.Editable).getText();
        // Empty search shows all
        if (search[0] == 0) return 1;

        // Get the tooltip text (emoji name) from the child's first widget
        const widget = child.as(gtk.Widget);
        const first_child = widget.getFirstChild() orelse return 0;
        const tooltip: [*:0]const u8 = first_child.getTooltipText() orelse return 0;

        // Case-insensitive substring match
        const search_slice = std.mem.span(search);
        const tooltip_slice = std.mem.span(tooltip);

        // Simple case-insensitive contains
        if (search_slice.len > tooltip_slice.len) return 0;
        var i: usize = 0;
        while (i + search_slice.len <= tooltip_slice.len) : (i += 1) {
            if (matchIgnoreCase(tooltip_slice[i .. i + search_slice.len], search_slice)) return 1;
        }
        return 0;
    }

    fn matchIgnoreCase(a: []const u8, b: []const u8) bool {
        if (a.len != b.len) return false;
        for (a, b) |ca, cb| {
            if (toLower(ca) != toLower(cb)) return false;
        }
        return true;
    }

    fn toLower(c: u8) u8 {
        return if (c >= 'A' and c <= 'Z') c + 32 else c;
    }

    fn onChildActivated(
        _: *gtk.FlowBox,
        child: *gtk.FlowBoxChild,
        self: *Self,
    ) callconv(.c) void {
        const priv = private(self);
        const emoji_data = priv.emoji_data orelse return;

        // Get index from widget name
        const widget = child.as(gtk.Widget);
        const first_child = widget.getFirstChild() orelse return;
        const name_ptr: [*:0]const u8 = first_child.getName();
        const name_slice = std.mem.span(name_ptr);

        const idx = std.fmt.parseInt(usize, name_slice, 10) catch return;
        if (idx >= emoji_data.emojis.len) return;

        const glyph = emoji_data.emojis[idx].glyph;

        // Copy to clipboard
        const display = gdk.Display.getDefault() orelse return;
        const clipboard = display.getClipboard();
        clipboard.setText(glyph);

        // Hide picker
        self.as(gtk.Widget).setVisible(@intFromBool(false));
    }

    fn dispose(self: *Self) callconv(.c) void {
        gtk.Widget.disposeTemplate(self.as(gtk.Widget), Self.getGObjectType());
        gobject.Object.virtual_methods.dispose.call(
            Class.parent,
            self.as(Parent),
        );
    }

    fn finalize(self: *Self) callconv(.c) void {
        const priv = private(self);
        if (priv.emoji_data) |*data| {
            data.deinit();
            priv.emoji_data = null;
        }
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
                "/com/leadr/gtk/ui/emoji-picker.ui",
            );
            C.Class.bindTemplateChildPrivate(class, "search_entry", .{});
            C.Class.bindTemplateChildPrivate(class, "emoji_flow", .{});
            C.Class.bindTemplateChildPrivate(class, "preview_glyph", .{});
            C.Class.bindTemplateChildPrivate(class, "preview_name", .{});

            gobject.Object.virtual_methods.dispose.implement(class, &dispose);
            gobject.Object.virtual_methods.finalize.implement(class, &finalize);
        }
    };
};
