const config = @import("config.zig");

pub const bindings: []const config.Binding = &.{
    .{ .key = 'o', .label = "Open", .action = .{ .group = &.{
        .{ .key = 'f', .label = "Firefox", .action = .{ .command = "firefox" } },
        .{ .key = 't', .label = "Terminal", .action = .{ .command = "ghostty" } },
        .{ .key = 'e', .label = "Editor", .action = .{ .command = "ghostty -e nvim" } },
    } } },
    .{ .key = 'f', .label = "Focus", .action = .{ .group = &.{
        .{ .key = 'b', .label = "Browser", .action = .{ .command = "hyprctl dispatch 'hl.dsp.focus({ window = \"class:firefox\" })'" } },
        .{ .key = 'p', .label = "Ghostty", .action = .{ .command = "hyprctl dispatch 'hl.dsp.focus({ window = \"class:com.mitchellh.ghostty\" })'" } },
    } } },
    .{ .key = 'w', .label = "Window", .action = .{ .sticky = .{
        .bindings = &.{
            .{ .key = 'm', .label = "Focus Left", .action = .{ .command = "hyprctl dispatch 'hl.dsp.focus({ direction = \"l\" })'" } },
            .{ .key = 'n', .label = "Focus Down", .action = .{ .command = "hyprctl dispatch 'hl.dsp.focus({ direction = \"d\" })'" } },
            .{ .key = 'e', .label = "Focus Up", .action = .{ .command = "hyprctl dispatch 'hl.dsp.focus({ direction = \"u\" })'" } },
            .{ .key = 'i', .label = "Focus Right", .action = .{ .command = "hyprctl dispatch 'hl.dsp.focus({ direction = \"r\" })'" } },
        },
        .timeout_ms = 1500,
    } } },
    .{ .key = 'd', .label = "Displace", .action = .{ .sticky = .{
        .bindings = &.{
            .{ .key = 'm', .label = "Move Left", .action = .{ .command = "hyprctl dispatch 'hl.dsp.window.move({ direction = \"l\" })'" } },
            .{ .key = 'n', .label = "Move Down", .action = .{ .command = "hyprctl dispatch 'hl.dsp.window.move({ direction = \"d\" })'" } },
            .{ .key = 'e', .label = "Move Up", .action = .{ .command = "hyprctl dispatch 'hl.dsp.window.move({ direction = \"u\" })'" } },
            .{ .key = 'i', .label = "Move Right", .action = .{ .command = "hyprctl dispatch 'hl.dsp.window.move({ direction = \"r\" })'" } },
        },
        .timeout_ms = 1500,
    } } },
    .{ .key = 'l', .label = "Layout", .action = .{ .group = &.{
        .{ .key = 'f', .label = "Maximize", .action = .{ .command = "hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = \"maximized\", action = \"toggle\" })'" } },
        .{ .key = 'g', .label = "Fullscreen", .action = .{ .command = "hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = \"fullscreen\", action = \"toggle\" })'" } },
        .{ .key = 'c', .label = "Center", .action = .{ .command = "hyprctl dispatch 'hl.dsp.window.center()'" } },
        .{ .key = 'r', .label = "Toggle Float", .action = .{ .command = "hyprctl dispatch 'hl.dsp.window.float({ action = \"toggle\" })'" } },
    } } },
    .{ .key = 's', .label = "Screenshot", .action = .{ .group = &.{
        .{ .key = 's', .label = "Select", .action = .{ .command = "grimblast copy area" } },
        .{ .key = 'w', .label = "Window", .action = .{ .command = "grimblast copy active" } },
        .{ .key = 'm', .label = "Monitor", .action = .{ .command = "grimblast copy output" } },
    } } },
    .{ .key = 'p', .label = "Player", .action = .{ .group = &.{
        .{ .key = 'p', .label = "Play/Pause", .action = .{ .command = "playerctl play-pause" } },
        .{ .key = 'n', .label = "Next", .action = .{ .command = "playerctl next" } },
        .{ .key = 'b', .label = "Previous", .action = .{ .command = "playerctl previous" } },
    } } },
    .{ .key = 'b', .label = "Browser", .action = .{ .command = "hyprctl dispatch 'hl.dsp.focus({ window = \"class:firefox\" })'" } },
    .{ .key = 'g', .label = "Ghostty", .action = .{ .command = "hyprctl dispatch 'hl.dsp.focus({ window = \"class:com.mitchellh.ghostty\" })'" } },
    .{ .key = 'x', .label = "Close Window", .action = .{ .command = "hyprctl dispatch 'hl.dsp.window.close()'" } },
    .{ .key = 'e', .label = "Emoji", .action = .emoji },
    .{ .key = 'v', .label = "Voice", .action = .dictation },
    .{ .key = 'q', .label = "Quit", .action = .quit },
};
