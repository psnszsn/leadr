const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // zig-gobject bindings
    const gobject = b.dependency("gobject", .{
        .target = target,
        .optimize = optimize,
    });

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    // Add gobject module imports
    const gobject_imports = .{
        .{ "adw", "adw1" },
        .{ "gdk", "gdk4" },
        .{ "gio", "gio2" },
        .{ "glib", "glib2" },
        .{ "gobject", "gobject2" },
        .{ "gtk", "gtk4" },
        .{ "gtk4_layer_shell", "gtk4layershell1" },
    };
    inline for (gobject_imports) |import_| {
        const name, const module = import_;
        mod.addImport(name, gobject.module(module));
    }

    // System libraries
    mod.linkSystemLibrary("gtk4", .{});
    mod.linkSystemLibrary("libadwaita-1", .{});
    mod.linkSystemLibrary("gtk4-layer-shell-0", .{});

    // --- Blueprint & GResource compilation ---
    const wf = b.addWriteFiles();

    // Compile each .blp → .ui and collect into write-files directory
    const blueprint_names = [_][]const u8{ "overlay-window", "key-indicator", "cheatsheet", "emoji-picker" };
    for (blueprint_names) |name| {
        const bp_compile = b.addSystemCommand(&.{ "blueprint-compiler", "compile", "--output" });
        const ui_file = bp_compile.addOutputFileArg(b.fmt("{s}.ui", .{name}));
        bp_compile.addFileArg(b.path(b.fmt("src/ui/{s}.blp", .{name})));
        _ = wf.addCopyFile(ui_file, b.fmt("{s}.ui", .{name}));
    }

    // Copy CSS into the same directory
    _ = wf.addCopyFile(b.path("src/style.css"), "style.css");

    // Write gresource XML
    const gresource_xml = wf.add("leadr.gresource.xml",
        \\<?xml version="1.0" encoding="UTF-8"?>
        \\<gresources>
        \\  <gresource prefix="/com/leadr/gtk">
        \\    <file compressed="true">style.css</file>
        \\  </gresource>
        \\  <gresource prefix="/com/leadr/gtk/ui">
        \\    <file compressed="true" preprocess="xml-stripblanks">overlay-window.ui</file>
        \\    <file compressed="true" preprocess="xml-stripblanks">key-indicator.ui</file>
        \\    <file compressed="true" preprocess="xml-stripblanks">cheatsheet.ui</file>
        \\    <file compressed="true" preprocess="xml-stripblanks">emoji-picker.ui</file>
        \\  </gresource>
        \\</gresources>
        \\
    );

    // Compile resources to C source
    const compile_res = b.addSystemCommand(&.{
        "glib-compile-resources",
        "--c-name",
        "leadr",
        "--generate-source",
        "--sourcedir",
    });
    compile_res.addDirectoryArg(wf.getDirectory());
    compile_res.addArg("--target");
    const resources_c = compile_res.addOutputFileArg("leadr_resources.c");
    compile_res.addFileArg(gresource_xml);

    // Add generated C resource source to module
    mod.addCSourceFile(.{ .file = resources_c });

    const exe = b.addExecutable(.{
        .name = "leadrgtk",
        .root_module = mod,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run leadrgtk");
    run_step.dependOn(&run_cmd.step);
}
