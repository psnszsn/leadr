const std = @import("std");
const gdk = @import("gdk");
const gio = @import("gio");
const glib = @import("glib");
const gobject = @import("gobject");
const gtk = @import("gtk");
const layer_shell = @import("gtk4_layer_shell");
const Common = @import("../class.zig").Common;
const desktop = @import("../desktop_app_info.zig");
const fuzzy = @import("../fuzzy.zig");
const Mode = @import("../mode.zig").Mode;
const Application = @import("application.zig").Application;
const alloc = std.heap.c_allocator;

pub const FuzzyMode = extern struct {
    const Self = @This();
    parent_instance: Parent,
    pub const Parent = gtk.Window;
    pub const getGObjectType = gobject.ext.defineClass(Self, .{
        .name = "LeadrFuzzyMode",
        .instanceInit = &init,
        .classInit = &Class.init,
        .parent_class = &Class.parent,
        .private = .{ .Type = Private, .offset = &Private.offset },
    });

    const Item = struct {
        source: union(enum) { application: *desktop.DesktopAppInfo, mode: Mode },
        fields: [3][]u32,
        count: u64,

        fn id(item: Item) [*:0]const u8 {
            return switch (item.source) {
                .application => |info| info.as(gio.AppInfo).getId().?,
                .mode => |mode| mode.id(),
            };
        }

        fn title(item: Item) [*:0]const u8 {
            return switch (item.source) {
                .application => |info| info.as(gio.AppInfo).getDisplayName(),
                .mode => |mode| mode.title(),
            };
        }

        fn description(item: Item) [*:0]const u8 {
            return switch (item.source) {
                .application => |info| info.getGenericName() orelse "",
                .mode => |mode| mode.description(),
            };
        }

        fn icon(item: Item) *gtk.Image {
            return switch (item.source) {
                .application => |info| if (info.as(gio.AppInfo).getIcon()) |i| gtk.Image.newFromGicon(i) else gtk.Image.newFromIconName("application-x-executable"),
                .mode => |mode| gtk.Image.newFromIconName(mode.icon()),
            };
        }

        fn actionCount(item: Item) usize {
            var count: usize = 1;
            switch (item.source) {
                .application => |info| {
                    const actions = info.listActions();
                    while (actions[count - 1] != null) : (count += 1) {}
                },
                .mode => {},
            }
            return count;
        }

        fn actionName(item: Item, index: usize) [*:0]u8 {
            return switch (item.source) {
                .application => |info| if (index == 0) glib.strdup("Open") else info.getActionName(info.listActions()[index - 1].?) orelse glib.strdup("Open"),
                .mode => glib.strdup("Switch to mode"),
            };
        }
    };
    const Result = struct {
        item: usize,
        score: i32,
        field: usize = 0,
        action: usize = 0, // 0 = Open; remaining indices refer to Desktop Actions.
    };
    const Private = struct {
        query_entry: *gtk.Entry,
        heading: *gtk.Label,
        results_list: *gtk.ListBox,
        scroller: *gtk.ScrolledWindow,
        status_label: *gtk.Label,
        empty_label: *gtk.Label,
        items: std.ArrayList(Item),
        results: std.ArrayList(Result),
        scratch: std.ArrayList(i32),
        history: ?*glib.KeyFile = null,
        history_path: ?[*:0]u8 = null,
        subject: ?usize = null,
        subject_query: ?[*:0]u8 = null,
        subject_row: c_int = 0,
        pub var offset: c_int = 0;
    };

    fn init(self: *Self, _: *Class) callconv(.c) void {
        gtk.Widget.initTemplate(self.as(gtk.Widget));
        const priv = private(self);
        priv.items = .empty;
        priv.results = .empty;
        priv.scratch = .empty;
        if (layer_shell.isSupported() != 0) {
            const window = self.as(gtk.Window);
            layer_shell.initForWindow(window);
            layer_shell.setLayer(window, .overlay);
            layer_shell.setKeyboardMode(window, .exclusive);
            layer_shell.setNamespace(window, "leadrgtk-fuzzy");
        }
        const controller = gtk.EventControllerKey.new();
        controller.as(gtk.EventController).setPropagationPhase(.capture);
        _ = gtk.EventControllerKey.signals.key_pressed.connect(controller, *Self, &onKeyPressed, self, .{});
        self.as(gtk.Widget).addController(controller.as(gtk.EventController));
        _ = gtk.Editable.signals.changed.connect(priv.query_entry.as(gtk.Editable), *Self, &onChanged, self, .{});
        _ = gtk.Entry.signals.activate.connect(priv.query_entry, *Self, &onActivate, self, .{});
        _ = gtk.ListBox.signals.row_activated.connect(priv.results_list, *Self, &onRowActivated, self, .{});
        const empty = gtk.Label.new("No matching items");
        priv.empty_label = empty;
        priv.results_list.setPlaceholder(empty.as(gtk.Widget));

        const dir = glib.strconcat(glib.getUserCacheDir(), "/leadr", @as(?[*:0]const u8, null));
        defer glib.free(dir);
        priv.history_path = glib.strconcat(dir, "/catalog.ini", @as(?[*:0]const u8, null));
        priv.history = glib.KeyFile.new();
        if (priv.history.?.loadFromFile(priv.history_path.?, .{}, null) == 0) {
            // Keep choices learned by the earlier desktop-only catalog.
            const legacy = glib.strconcat(dir, "/applications.ini", @as(?[*:0]const u8, null));
            defer glib.free(legacy);
            _ = priv.history.?.loadFromFile(legacy, .{}, null);
        }
    }

    pub fn present(self: *Self) void {
        const priv = private(self);
        priv.subject = null;
        if (priv.subject_query) |q| glib.free(q);
        priv.subject_query = null;
        priv.heading.setLabel("Fuzzy Mode");
        priv.query_entry.setPlaceholderText("Search apps and modes…");
        self.clearItems();
        inline for (std.meta.tags(Mode)) |mode| {
            _ = self.appendItem(.{ .mode = mode });
        }
        // GIO supplies XDG precedence, localization, Hidden/NoDisplay,
        // OnlyShowIn/NotShowIn and TryExec handling. Never enumerate PATH.
        const list = desktop.getAll();
        defer if (list) |head| head.free();
        var node = list;
        while (node) |link| : (node = link.f_next) {
            const obj: *gobject.Object = @ptrCast(@alignCast(link.f_data orelse continue));
            defer obj.unref();
            const info = gobject.ext.cast(desktop.DesktopAppInfo, obj) orelse continue;
            const app = info.as(gio.AppInfo);
            const filename = info.getFilename() orelse continue;
            if (!std.mem.endsWith(u8, std.mem.span(filename), ".desktop") or app.shouldShow() == 0) continue;
            if (app.getId() == null) continue;
            if (self.appendItem(.{ .application = info })) _ = obj.ref();
        }
        priv.query_entry.as(gtk.Editable).setText("");
        self.refresh();
        self.as(gtk.Window).present();
        _ = priv.query_entry.as(gtk.Widget).grabFocus();
    }

    fn appendItem(self: *Self, source: @FieldType(Item, "source")) bool {
        const priv = private(self);
        var item = Item{ .source = source, .fields = undefined, .count = 0 };
        item.fields = .{ normalize(item.title()), normalize(item.description()), normalize(item.id()) };
        var key: [65:0]u8 = undefined;
        hashKey(std.mem.span(item.id()), &key);
        item.count = priv.history.?.getUint64(&key, "count", null);
        priv.items.append(alloc, item) catch {
            for (item.fields) |field| glib.free(field.ptr);
            return false;
        };
        return true;
    }

    fn normalize(text: [*:0]const u8) []u32 {
        const folded = glib.utf8Casefold(text, -1);
        defer glib.free(folded);
        var length: c_long = 0;
        const data: [*]u32 = @ptrCast(glib.utf8ToUcs4Fast(folded, -1, &length));
        return data[0..@intCast(length)];
    }

    fn hashKey(text: []const u8, out: *[65:0]u8) void {
        const hex = glib.computeChecksumForData(.sha256, text.ptr, text.len).?;
        defer glib.free(hex);
        @memcpy(out[0..64], hex[0..64]);
        out[64] = 0;
    }

    fn queryKey(self: *Self, out: *[65:0]u8) void {
        const priv = private(self);
        const text = priv.subject_query orelse priv.query_entry.as(gtk.Editable).getText();
        const folded = glib.utf8Casefold(text, -1);
        defer glib.free(folded);
        hashKey(std.mem.span(folded), out);
    }

    fn scoreField(self: *Self, query: []const u32, field: []const u32) ?i32 {
        const priv = private(self);
        priv.scratch.resize(alloc, field.len * 2) catch return null;
        return fuzzy.score(query, field, priv.scratch.items);
    }

    fn refresh(self: *Self) void {
        const priv = private(self);
        const query = normalize(priv.query_entry.as(gtk.Editable).getText());
        defer glib.free(query.ptr);
        priv.results.clearRetainingCapacity();
        var qkey: [65:0]u8 = undefined;
        self.queryKey(&qkey);
        const preferred = priv.history.?.getString(&qkey, "selected", null);
        defer if (preferred) |s| glib.free(s);

        for (priv.items.items, 0..) |item, i| {
            if (priv.subject) |subject| {
                if (i != subject) continue;
                for (0..item.actionCount()) |a| {
                    const name = item.actionName(a);
                    defer glib.free(name);
                    const field = normalize(name);
                    defer glib.free(field.ptr);
                    const score = self.scoreField(query, field) orelse continue;
                    priv.results.append(alloc, .{ .item = i, .action = a, .score = score }) catch break;
                }
            } else {
                var best: ?i32 = null;
                var matched: usize = 0;
                for (item.fields, 0..) |field, f| {
                    if (self.scoreField(query, field)) |score| {
                        if (best == null or score > best.?) {
                            best = score;
                            matched = f;
                        }
                    }
                }
                var score = best orelse continue;
                // Exact-query choices are learned; frequency only breaks close ties.
                if (query.len > 0) {
                    if (preferred) |id| {
                        if (std.mem.eql(u8, std.mem.span(id), std.mem.span(item.id()))) score += 1000;
                    }
                }
                score += @intCast(@min(item.count, @as(u64, if (query.len == 0) 1000000 else 16)));
                priv.results.append(alloc, .{ .item = i, .score = score, .field = matched }) catch break;
            }
        }
        std.mem.sort(Result, priv.results.items, self, lessThan);
        self.render();
    }

    fn lessThan(self: *Self, a: Result, b: Result) bool {
        if (a.score != b.score) return a.score > b.score;
        if (private(self).subject != null) return a.action < b.action;
        const items = private(self).items.items;
        const an = std.mem.span(items[a.item].title());
        const bn = std.mem.span(items[b.item].title());
        const order = std.mem.order(u8, an, bn);
        if (order != .eq) return order == .lt;
        return std.mem.lessThan(u8, std.mem.span(items[a.item].id()), std.mem.span(items[b.item].id()));
    }

    fn render(self: *Self) void {
        const priv = private(self);
        const query = normalize(priv.query_entry.as(gtk.Editable).getText());
        defer glib.free(query.ptr);
        // removeAll also removes the placeholder; only discard result rows.
        while (priv.results_list.getRowAtIndex(0)) |row| {
            priv.results_list.remove(row.as(gtk.Widget));
        }
        priv.empty_label.setLabel(if (priv.subject != null) "No matching actions" else "No matching items");
        for (priv.results.items) |result| {
            const item = priv.items.items[result.item];
            const row = gtk.Box.new(.horizontal, 12);
            const icon = item.icon();
            icon.setPixelSize(32);
            row.append(icon.as(gtk.Widget));
            const labels = gtk.Box.new(.vertical, 2);
            labels.as(gtk.Widget).setHexpand(1);
            const action = if (priv.subject != null) item.actionName(result.action) else null;
            defer if (action) |s| glib.free(s);
            const title = gtk.Label.new(action orelse item.title());
            if (priv.subject != null or result.field == 0) highlight(title, action orelse item.title(), query);
            title.setXalign(0);
            title.setEllipsize(.end);
            labels.append(title.as(gtk.Widget));
            const detail_text = if (result.field == 1 or (item.source == .mode and result.field == 0)) item.description() else item.id();
            const detail = gtk.Label.new(detail_text);
            if (priv.subject == null and result.field != 0) highlight(detail, detail_text, query);
            detail.setXalign(0);
            detail.setEllipsize(.middle);
            detail.as(gtk.Widget).addCssClass("dim-label");
            labels.append(detail.as(gtk.Widget));
            row.append(labels.as(gtk.Widget));
            priv.results_list.append(row.as(gtk.Widget));
        }
        priv.results_list.selectRow(priv.results_list.getRowAtIndex(0));
        priv.scroller.getVadjustment().setValue(0);
        priv.status_label.setLabel(if (priv.subject != null)
            "Enter → Run action · Shift+Tab / Esc → Results"
        else if (priv.items.items.len == 0)
            "No items found."
        else if (priv.results.items.len == 0)
            "No matching items."
        else
            "↑ ↓ → Select · Enter → Open · Tab → Actions · Esc → Close");
    }

    fn highlight(label: *gtk.Label, text: [*:0]const u8, query: []const u32) void {
        if (query.len == 0) return;
        const markup = glib.String.new(null);
        defer _ = markup.free(1);
        var iterator = (std.unicode.Utf8View.init(std.mem.span(text)) catch return).iterator();
        var matched: usize = 0;
        while (iterator.nextCodepointSlice()) |bytes| {
            var character: [5:0]u8 = @splat(0);
            @memcpy(character[0..bytes.len], bytes);
            const folded = normalize(&character);
            defer glib.free(folded.ptr);
            const before = matched;
            for (folded) |c| {
                if (matched < query.len and query[matched] == c) matched += 1;
            }
            const escaped = glib.markupEscapeText(&character, @intCast(bytes.len));
            defer glib.free(escaped);
            if (matched > before) _ = markup.append("<b>");
            _ = markup.append(escaped);
            if (matched > before) _ = markup.append("</b>");
        }
        label.setMarkup(markup.f_str.?);
    }

    fn selected(self: *Self) ?Result {
        const priv = private(self);
        const row = priv.results_list.getSelectedRow() orelse return null;
        const index: usize = @intCast(row.getIndex());
        if (index >= priv.results.items.len) return null;
        return priv.results.items[index];
    }

    fn showActions(self: *Self) void {
        const priv = private(self);
        if (priv.subject != null) return;
        const result = self.selected() orelse return;
        priv.subject = result.item;
        priv.subject_row = priv.results_list.getSelectedRow().?.getIndex();
        priv.subject_query = glib.strdup(priv.query_entry.as(gtk.Editable).getText());
        priv.heading.setLabel(priv.items.items[result.item].title());
        priv.query_entry.setPlaceholderText("Search actions…");
        priv.query_entry.as(gtk.Editable).setText("");
        self.refresh();
        _ = priv.query_entry.as(gtk.Widget).grabFocus();
    }

    fn showResults(self: *Self) void {
        const priv = private(self);
        priv.subject = null;
        const query = priv.subject_query;
        priv.subject_query = null;
        defer if (query) |q| glib.free(q);
        priv.heading.setLabel("Fuzzy Mode");
        priv.query_entry.setPlaceholderText("Search apps and modes…");
        priv.query_entry.as(gtk.Editable).setText(query orelse "");
        self.refresh();
        priv.results_list.selectRow(priv.results_list.getRowAtIndex(priv.subject_row));
        _ = priv.query_entry.as(gtk.Widget).grabFocus();
    }

    fn activateSelected(self: *Self) void {
        const priv = private(self);
        const result = self.selected() orelse return;
        const item = priv.items.items[result.item];
        if (item.source == .mode) {
            const application = self.as(gtk.Window).getApplication() orelse return;
            const app = gobject.ext.cast(Application, application) orelse return;
            // Remember before switching: selecting Fuzzy Mode rebuilds the catalog.
            self.remember(result.item);
            self.as(gtk.Widget).setVisible(0);
            app.showMode(item.source.mode);
            return;
        }
        const app = item.source.application;
        const context = self.as(gtk.Widget).getDisplay().getAppLaunchContext();
        defer context.as(gobject.Object).unref();
        self.as(gtk.Widget).setVisible(0);
        if (result.action == 0) {
            var err: ?*glib.Error = null;
            if (app.as(gio.AppInfo).launch(null, context.as(gio.AppLaunchContext), &err) == 0) {
                self.as(gtk.Window).present();
                _ = priv.query_entry.as(gtk.Widget).grabFocus();
                priv.status_label.setLabel(if (err) |e| e.f_message orelse "Could not launch this application." else "Could not launch this application.");
                if (err) |e| e.free();
                return;
            }
        } else {
            app.launchAction(app.listActions()[result.action - 1].?, context.as(gio.AppLaunchContext));
        }
        self.remember(result.item);
    }

    fn remember(self: *Self, index: usize) void {
        const priv = private(self);
        var key: [65:0]u8 = undefined;
        const id = priv.items.items[index].id();
        hashKey(std.mem.span(id), &key);
        priv.items.items[index].count +|= 1;
        priv.history.?.setUint64(&key, "count", priv.items.items[index].count);
        self.queryKey(&key);
        priv.history.?.setString(&key, "selected", id);
        const dir = glib.strconcat(glib.getUserCacheDir(), "/leadr", @as(?[*:0]const u8, null));
        defer glib.free(dir);
        if (glib.mkdirWithParents(dir, 0o700) == 0) _ = priv.history.?.saveToFile(priv.history_path.?, null);
    }

    fn onKeyPressed(controller: *gtk.EventControllerKey, key: c_uint, _: c_uint, mods: gdk.ModifierType, self: *Self) callconv(.c) c_int {
        const priv = private(self);
        if (key == 0xff1b) {
            if (priv.subject != null) self.showResults() else self.as(gtk.Widget).setVisible(0);
            return 1;
        }
        if (key == 0xff09 or key == 0xfe20) {
            if (priv.subject != null) self.showResults() else if (!mods.shift_mask) self.showActions();
            return 1;
        }
        const down = key == 0xff54 or (mods.control_mask and key == 'n');
        const up = key == 0xff52 or (mods.control_mask and key == 'p');
        if (down or up) {
            if (priv.results.items.len == 0) return 1;
            const current = if (priv.results_list.getSelectedRow()) |row| row.getIndex() else 0;
            const next = std.math.clamp(current + @as(c_int, if (down) 1 else -1), 0, @as(c_int, @intCast(priv.results.items.len - 1)));
            if (priv.results_list.getRowAtIndex(next)) |row| {
                priv.results_list.selectRow(row);
                // GTK scrolls a focused row into view; restore query focus so
                // subsequent typing and Backspace continue editing the query.
                _ = row.as(gtk.Widget).grabFocus();
                _ = priv.query_entry.as(gtk.Widget).grabFocus();
            }
            return 1;
        }
        // Entry handles ordinary editing, paste, Unicode and IME commits.
        if (key == 0xff08 or gdk.keyvalToUnicode(key) != 0) {
            const entry = priv.query_entry.as(gtk.Widget);
            const focus = self.as(gtk.Window).getFocus();
            if (focus == null or (focus.? != entry and focus.?.isAncestor(entry) == 0)) {
                _ = entry.grabFocus();
                return controller.forward(entry);
            }
        }
        return 0;
    }

    fn onChanged(_: *gtk.Editable, self: *Self) callconv(.c) void {
        self.refresh();
    }
    fn onActivate(_: *gtk.Entry, self: *Self) callconv(.c) void {
        self.activateSelected();
    }
    fn onRowActivated(_: *gtk.ListBox, row: *gtk.ListBoxRow, self: *Self) callconv(.c) void {
        private(self).results_list.selectRow(row);
        self.activateSelected();
    }

    fn clearItems(self: *Self) void {
        const priv = private(self);
        priv.results.clearRetainingCapacity();
        for (priv.items.items) |item| {
            switch (item.source) {
                .application => |info| info.as(gobject.Object).unref(),
                .mode => {},
            }
            for (item.fields) |field| glib.free(field.ptr);
        }
        priv.items.clearRetainingCapacity();
    }

    fn dispose(self: *Self) callconv(.c) void {
        self.clearItems();
        gtk.Widget.disposeTemplate(self.as(gtk.Widget), Self.getGObjectType());
        gobject.Object.virtual_methods.dispose.call(Class.parent, self.as(Parent));
    }

    fn finalize(self: *Self) callconv(.c) void {
        const priv = private(self);
        priv.items.deinit(alloc);
        priv.results.deinit(alloc);
        priv.scratch.deinit(alloc);
        if (priv.history) |h| h.unref();
        if (priv.history_path) |p| glib.free(p);
        if (priv.subject_query) |q| glib.free(q);
        gobject.Object.virtual_methods.finalize.call(Class.parent, self.as(Parent));
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
            gtk.Widget.Class.setTemplateFromResource(class.as(gtk.Widget.Class), "/com/leadr/gtk/ui/fuzzy_mode.ui");
            inline for (.{ "query_entry", "heading", "results_list", "scroller", "status_label" }) |child| C.Class.bindTemplateChildPrivate(class, child, .{});
            gobject.Object.virtual_methods.dispose.implement(class, &dispose);
            gobject.Object.virtual_methods.finalize.implement(class, &finalize);
        }
    };
};
