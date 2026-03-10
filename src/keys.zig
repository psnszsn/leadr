const config = @import("config.zig");

pub const bindings: []const config.Binding = &.{
    .{ .key = 'o', .label = "Open", .action = .{ .group = &.{
        .{ .key = 'f', .label = "Firefox", .action = .{ .command = "firefox" } },
        .{ .key = 't', .label = "Terminal", .action = .{ .command = "ghostty" } },
        .{ .key = 'e', .label = "Editor", .action = .{ .command = "ghostty -e nvim" } },
    } } },
    .{ .key = 'f', .label = "Focus", .action = .{ .group = &.{
        .{ .key = 'b', .label = "Browser", .action = .{ .command =
            \\sh -c 'niri msg -j windows | jq "map(select(.app_id==\"Firefox\")) | first | .id" | xargs niri msg action focus-window --id'
        } },
        .{ .key = 'p', .label = "Ghostty", .action = .{ .command =
            \\sh -c 'niri msg -j windows | jq "[.[] | select(.app_id==\"com.mitchellh.ghostty\" and (.is_focused | not))] | sort_by(.focus_timestamp.secs, .focus_timestamp.nanos) | reverse | first | .id // empty" | xargs -r niri msg action focus-window --id'
        } },
    } } },
    .{ .key = 'w', .label = "Window", .action = .{ .sticky = .{
        .bindings = &.{
            .{ .key = 'm', .label = "Focus Left", .action = .{ .command = "niri msg action focus-column-or-monitor-left" } },
            .{ .key = 'n', .label = "Focus Down", .action = .{ .command = "niri msg action focus-window-or-workspace-down" } },
            .{ .key = 'e', .label = "Focus Up", .action = .{ .command = "niri msg action focus-window-or-workspace-up" } },
            .{ .key = 'i', .label = "Focus Right", .action = .{ .command = "niri msg action focus-column-or-monitor-right" } },
        },
        .timeout_ms = 1500,
    } } },
    .{ .key = 'd', .label = "Displace", .action = .{ .sticky = .{
        .bindings = &.{
            .{ .key = 'm', .label = "Move Left", .action = .{ .command = "niri msg action move-column-left" } },
            .{ .key = 'n', .label = "Move Down", .action = .{ .command = "niri msg action move-window-down-or-to-workspace-down" } },
            .{ .key = 'e', .label = "Move Up", .action = .{ .command = "niri msg action move-window-up-or-to-workspace-up" } },
            .{ .key = 'i', .label = "Move Right", .action = .{ .command = "niri msg action move-column-right" } },
        },
        .timeout_ms = 1500,
    } } },
    .{ .key = 'l', .label = "Layout", .action = .{ .group = &.{
        .{ .key = 'f', .label = "Maximize", .action = .{ .command = "niri msg action maximize-column" } },
        .{ .key = 'g', .label = "Fullscreen", .action = .{ .command = "niri msg action fullscreen-window" } },
        .{ .key = 'c', .label = "Center", .action = .{ .command = "niri msg action center-column" } },
        .{ .key = 'r', .label = "Preset Width", .action = .{ .command = "niri msg action switch-preset-column-width" } },
    } } },
    .{ .key = 's', .label = "Screenshot", .action = .{ .group = &.{
        .{ .key = 's', .label = "Select", .action = .{ .command = "niri msg action screenshot" } },
        .{ .key = 'w', .label = "Window", .action = .{ .command = "niri msg action screenshot-window" } },
        .{ .key = 'm', .label = "Monitor", .action = .{ .command = "niri msg action screenshot-screen" } },
    } } },
    .{ .key = 'p', .label = "Player", .action = .{ .group = &.{
        .{ .key = 'p', .label = "Play/Pause", .action = .{ .command = "playerctl play-pause" } },
        .{ .key = 'n', .label = "Next", .action = .{ .command = "playerctl next" } },
        .{ .key = 'b', .label = "Previous", .action = .{ .command = "playerctl previous" } },
    } } },
    .{ .key = 'x', .label = "Close Window", .action = .{ .command = "niri msg action close-window" } },
    .{ .key = 'e', .label = "Emoji", .action = .emoji },
    .{ .key = 'v', .label = "Voice", .action = .dictation },
    .{ .key = 'q', .label = "Quit", .action = .quit },
};
