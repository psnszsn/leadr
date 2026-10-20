//! The small gio-unix surface missing from our generated GIO bindings.
const gio = @import("gio");
const glib = @import("glib");
const gobject = @import("gobject");

pub const DesktopAppInfo = opaque {
    pub const Parent = gobject.Object;
    pub const Implements = [_]type{gio.AppInfo};
    pub const Class = opaque {
        pub const Instance = DesktopAppInfo;
    };

    extern fn g_desktop_app_info_get_type() usize;
    pub const getGObjectType = g_desktop_app_info_get_type;
    extern fn g_desktop_app_info_get_filename(self: *DesktopAppInfo) ?[*:0]const u8;
    pub const getFilename = g_desktop_app_info_get_filename;
    extern fn g_desktop_app_info_get_generic_name(self: *DesktopAppInfo) ?[*:0]const u8;
    pub const getGenericName = g_desktop_app_info_get_generic_name;
    extern fn g_desktop_app_info_list_actions(self: *DesktopAppInfo) [*:null]const ?[*:0]const u8;
    pub const listActions = g_desktop_app_info_list_actions;
    extern fn g_desktop_app_info_get_action_name(self: *DesktopAppInfo, action: [*:0]const u8) ?[*:0]u8;
    pub const getActionName = g_desktop_app_info_get_action_name;
    extern fn g_desktop_app_info_launch_action(self: *DesktopAppInfo, action: [*:0]const u8, context: ?*gio.AppLaunchContext) void;
    pub const launchAction = g_desktop_app_info_launch_action;

    pub fn as(self: *DesktopAppInfo, comptime T: type) *T {
        return gobject.ext.as(T, self);
    }
};

// The generated getAll signature incorrectly excludes NULL for an empty catalog.
extern fn g_app_info_get_all() ?*glib.List;
pub const getAll = g_app_info_get_all;
