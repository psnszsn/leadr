# leadrgtk — Leader Key Launcher for Wayland

*2026-03-07T14:26:39Z by Showboat 0.6.1*
<!-- showboat-id: d07c9ff0-41c3-4307-9043-b9235d34666f -->

leadrgtk is a keyboard-driven command launcher for Wayland, inspired by Vim's leader key. It displays a layer-shell overlay with a cheatsheet of available key bindings organized in a tree. Press a key to either descend into a group or execute a shell command. Built with Zig, GTK4, libadwaita, and gtk4-layer-shell.

## Project Structure

```bash
find src -name "*.zig" -o -name "*.blp" -o -name "*.css" | sort
```

```output
src/class.zig
src/class/application.zig
src/class/cheatsheet.zig
src/class/key_indicator.zig
src/class/overlay_window.zig
src/config.zig
src/ext.zig
src/ext/actions.zig
src/keys.zig
src/main.zig
src/style.css
src/ui/cheatsheet.blp
src/ui/key-indicator.blp
src/ui/overlay-window.blp
src/weak_ref.zig
```

## Key Binding DSL

Bindings are defined at comptime in Zig — no config files or runtime parsing. Each binding maps a single Unicode key to either a shell command, a nested group of bindings, a sticky group (stays open with a timeout), or quit.

```bash
cat src/keys.zig
```

```output
const config = @import("config.zig");

pub const bindings: []const config.Binding = &.{
    .{ .key = 'o', .label = "Open", .action = .{ .group = &.{
        .{ .key = 'f', .label = "Firefox", .action = .{ .command = "firefox" } },
        .{ .key = 't', .label = "Terminal", .action = .{ .command = "foot" } },
        .{ .key = 'e', .label = "Editor", .action = .{ .command = "code" } },
    } } },
    .{ .key = 'm', .label = "Music", .action = .{ .group = &.{
        .{ .key = 'p', .label = "Play/Pause", .action = .{ .command = "playerctl play-pause" } },
        .{ .key = 'n', .label = "Next", .action = .{ .command = "playerctl next" } },
        .{ .key = 'b', .label = "Previous", .action = .{ .command = "playerctl previous" } },
    } } },
    .{ .key = 'w', .label = "Window", .action = .{ .sticky = .{
        .bindings = &.{
            .{ .key = 'm', .label = "Focus Left", .action = .{ .command = "niri msg action focus-column-left" } },
            .{ .key = 'n', .label = "Focus Down", .action = .{ .command = "niri msg action focus-window-or-workspace-down" } },
            .{ .key = 'e', .label = "Focus Up", .action = .{ .command = "niri msg action focus-window-or-workspace-up" } },
            .{ .key = 'i', .label = "Focus Right", .action = .{ .command = "niri msg action focus-column-right" } },
        },
        .timeout_ms = 1500,
    } } },
    .{ .key = 'q', .label = "Quit", .action = .quit },
};
```

The types behind this DSL are defined in `config.zig` — a `Binding` has a key, label, and an `Action` which is a `command` (shell string), `group` (nested bindings), `sticky` (group that stays open with a timeout), or `quit`.

```bash
sed -n "1,13p" src/config.zig
```

```output
/// Comptime key binding DSL and runtime navigation state.
pub const Binding = struct {
    key: u21, // Unicode codepoint
    label: []const u8,
    action: Action,
};

pub const Action = union(enum) {
    command: []const u8,
    group: []const Binding,
    sticky: struct { bindings: []const Binding, timeout_ms: c_uint },
    quit,
};
```

## Navigator

The `Navigator` is a stack-based tree traversal engine. It tracks which group of bindings is currently active. Pressing a group key pushes a new level; Backspace pops back up; Escape resets to root.

```bash
sed -n "15,61p" src/config.zig
```

```output
const max_depth = 8;

pub const Navigator = struct {
    stack: [max_depth][]const Binding = undefined,
    depth: u8 = 0,

    pub fn init(root: []const Binding) Navigator {
        var self: Navigator = .{ .depth = 1 };
        self.stack[0] = root;
        return self;
    }

    pub fn current(self: *const Navigator) []const Binding {
        return self.stack[self.depth - 1];
    }

    pub fn push(self: *Navigator, group: []const Binding) void {
        if (self.depth < max_depth) {
            self.stack[self.depth] = group;
            self.depth += 1;
        }
    }

    pub fn pop(self: *Navigator) bool {
        if (self.depth > 1) {
            self.depth -= 1;
            return true;
        }
        return false;
    }

    pub fn reset(self: *Navigator, root: []const Binding) void {
        self.stack[0] = root;
        self.depth = 1;
    }

    pub fn lookup(self: *const Navigator, key: u21) ?*const Binding {
        for (self.current()) |*binding| {
            if (binding.key == key) return binding;
        }
        return null;
    }

    pub fn atRoot(self: *const Navigator) bool {
        return self.depth <= 1;
    }
};
```

## GObject Architecture

Every UI concept is a GObject subclass following Ghostty's conventions. The `Common(Self, Private)` mixin provides `as`/`ref`/`unref`/`private` helpers. All classes use blueprint templates for declarative UI, with `initTemplate()` in instance init and `disposeTemplate()` in dispose.

### Application

`LeadrApplication` extends `adw.Application`. It uses GApplication's single-instance mechanism — the first invocation becomes the daemon, and subsequent invocations send `activate` via D-Bus to toggle the overlay.

```bash
cat src/main.zig
```

```output
const std = @import("std");
const gio = @import("gio");
const Application = @import("class/application.zig").Application;

pub fn main() u8 {
    const app = Application.new();
    defer app.unref();
    return @intCast(app.as(gio.Application).run(0, null));
}
```

```bash
sed -n '38,76p' src/class/application.zig
```

```output
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
```

### Overlay Window

`LeadrOverlayWindow` is the core widget. It configures gtk4-layer-shell to float as an overlay with exclusive keyboard focus. Key presses are handled by an `EventControllerKey` — Escape hides, Backspace goes up, and letter keys navigate or execute commands. Sticky groups keep the overlay open after executing a command, auto-hiding after a configurable timeout.

```bash
cat src/ui/overlay-window.blp
```

```output
using Gtk 4.0;

template $LeadrOverlayWindow: Window {
  decorated: false;
  default-width: 600;
  default-height: 200;

  styles ["leadr-overlay"]

  Box {
    orientation: horizontal;
    halign: center;
    valign: center;
    hexpand: true;
    vexpand: true;
    spacing: 24;

    $LeadrKeyIndicator key_indicator {}
    $LeadrCheatsheet cheatsheet {}
  }
}
```

```bash
sed -n '67,155p' src/class/overlay_window.zig
```

```output
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
```

### Key Indicator & Cheatsheet

The key indicator is a large rounded box showing the current key glyph (or a bullet at root). The cheatsheet dynamically rebuilds rows of `[key badge] [label]` for each binding in the current group, with a `›` suffix for groups and sticky groups.

```bash
cat src/ui/key-indicator.blp && echo '---' && cat src/ui/cheatsheet.blp
```

```output
using Gtk 4.0;

template $LeadrKeyIndicator: Box {
  orientation: vertical;
  halign: center;
  valign: center;

  styles ["key-indicator"]

  Label label {
    label: "●";
  }
}
---
using Gtk 4.0;

template $LeadrCheatsheet: Box {
  orientation: vertical;
  spacing: 0;

  styles ["cheatsheet"]

  Box container {
    orientation: vertical;
    spacing: 4;
  }
}
```

## Layer Shell Integration

On Wayland, the overlay uses gtk4-layer-shell to position itself on the overlay layer with exclusive keyboard grab. Bindings are generated from GIR introspection data using zig-gobject (`just bindings`).

```bash
sed -n '182,188p' src/class/overlay_window.zig
```

```output
        // Layer shell setup
        if (layer_shell.isSupported() != 0) {
            layer_shell.initForWindow(window);
            layer_shell.setLayer(window, .overlay);
            layer_shell.setKeyboardMode(window, .exclusive);
            layer_shell.setNamespace(window, "leadrgtk");
        }
```

## Styling

```bash
cat src/style.css
```

```output
.leadr-overlay {
    background: transparent;
}

.key-indicator {
    background: alpha(@window_bg_color, 0.85);
    border-radius: 24px;
    padding: 32px;
    min-width: 160px;
    min-height: 160px;
}

.key-indicator label {
    font-size: 48px;
    font-weight: bold;
    color: @window_fg_color;
}

.cheatsheet {
    background: alpha(@window_bg_color, 0.85);
    border-radius: 16px;
    padding: 16px;
    margin-left: 24px;
}

.cheatsheet-row {
    padding: 4px 8px;
}

.key-badge {
    background: alpha(@accent_color, 0.3);
    border-radius: 6px;
    padding: 4px 10px;
    font-weight: bold;
    font-family: monospace;
    min-width: 24px;
}

.key-label {
    margin-left: 12px;
}

.group-indicator {
    opacity: 0.6;
    margin-left: 4px;
}
```

## Build System

The build compiles blueprint templates to GTK UI XML, bundles them with CSS into a GResource, and compiles everything into a single self-contained executable.

```bash
zig build 2>&1 && echo 'Build succeeded' && file zig-out/bin/leadrgtk && ls -lh zig-out/bin/leadrgtk
```

```output
Build succeeded
zig-out/bin/leadrgtk: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-x86_64.so.1, with debug_info, not stripped
-rwxr-xr-x  1 vlad vlad  9.8M Mar  7 18:18 zig-out/bin/leadrgtk
```

## Usage

The first invocation starts the daemon. Subsequent invocations toggle the overlay via D-Bus (GApplication single-instance). Bind `leadrgtk` to a key in your window manager to use it as a leader key launcher.
