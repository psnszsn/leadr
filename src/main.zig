const std = @import("std");
const gio = @import("gio");
const Application = @import("class/application.zig").Application;

pub fn main() u8 {
    const app = Application.new();
    defer app.unref();
    return @intCast(app.as(gio.Application).run(0, null));
}
