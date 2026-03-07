const config = @import("config.zig");

pub const bindings: []const config.Binding = &.{
    .{ .key = 'o', .label = "Open", .action = .{ .group = &.{
        .{ .key = 'f', .label = "Firefox", .action = .{ .command = "firefox" } },
        .{ .key = 't', .label = "Terminal", .action = .{ .command = "foot" } },
        .{ .key = 'e', .label = "Editor", .action = .{ .command = "ghostty -e nvim" } },
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
