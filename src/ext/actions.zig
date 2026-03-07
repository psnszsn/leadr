const std = @import("std");
const gio = @import("gio");
const glib = @import("glib");
const gobject = @import("gobject");
const gtk = @import("gtk");

fn gActionNameIsValid(name: [:0]const u8) bool {
    if (name.len == 0) return false;
    for (name) |c| switch (c) {
        '-', '.', '0'...'9', 'a'...'z', 'A'...'Z' => continue,
        else => return false,
    };
    return true;
}

pub fn Action(comptime T: type) type {
    return struct {
        const Self = @This();
        pub const Callback = *const fn (*gio.SimpleAction, ?*glib.Variant, *T) callconv(.c) void;

        name: [:0]const u8,
        callback: Callback,
        parameter_type: ?*const glib.VariantType,
        state: ?*glib.Variant = null,

        pub fn init(
            comptime name: [:0]const u8,
            callback: Callback,
            parameter_type: ?*const glib.VariantType,
        ) Self {
            comptime if (!gActionNameIsValid(name)) @compileError("invalid action name: " ++ name);
            return .{
                .name = name,
                .callback = callback,
                .parameter_type = parameter_type,
            };
        }
    };
}

pub fn add(comptime T: type, self: *T, act: []const Action(T)) void {
    addToMap(T, self, self.as(gio.ActionMap), act);
}

pub fn addToMap(comptime T: type, self: *T, map: *gio.ActionMap, act: []const Action(T)) void {
    for (act) |entry| {
        const action = if (entry.state) |state|
            gio.SimpleAction.newStateful(entry.name, entry.parameter_type, state)
        else
            gio.SimpleAction.new(entry.name, entry.parameter_type);
        defer action.unref();
        _ = gio.SimpleAction.signals.activate.connect(
            action,
            *T,
            entry.callback,
            self,
            .{},
        );
        map.addAction(action.as(gio.Action));
    }
}
