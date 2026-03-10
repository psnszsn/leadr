const std = @import("std");

/// Compiles whisper.cpp as a static library from the whisper.cpp dependency.
pub fn addWhisper(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    const dep = b.dependency("whisper.cpp", .{});

    _ = optimize;
    const mod = b.createModule(.{
        .target = target,
        .optimize = .ReleaseFast,
        .link_libc = true,
    });

    // Include paths
    mod.addIncludePath(dep.path("ggml/include"));
    mod.addIncludePath(dep.path("include"));
    mod.addIncludePath(dep.path("ggml/src"));
    mod.addIncludePath(dep.path("ggml/src/ggml-cpu"));
    mod.addIncludePath(dep.path("src"));

    // Flag sets
    // -fno-sanitize=undefined: ggml does NULL pointer arithmetic (NULL + offset)
    // to calculate buffer sizes, which is C UB that Zig's debug UBSAN traps.
    const base_c: []const []const u8 = &.{
        "-DNDEBUG",
        "-D_GNU_SOURCE",
        "-D_XOPEN_SOURCE=600",
        "-DGGML_USE_CPU",
        "-DGGML_VERSION=\"0.9.7\"",
        "-DGGML_COMMIT=\"\"",
        "-DWHISPER_VERSION=\"1.8.3\"",
        "-pthread",
        "-fno-sanitize=undefined",
    };

    const base_cpp: []const []const u8 = &.{
        "-DNDEBUG",
        "-D_GNU_SOURCE",
        "-D_XOPEN_SOURCE=600",
        "-DGGML_USE_CPU",
        "-DGGML_VERSION=\"0.9.7\"",
        "-DGGML_COMMIT=\"\"",
        "-DWHISPER_VERSION=\"1.8.3\"",
        "-pthread",
        "-std=c++17",
        "-fno-sanitize=undefined",
    };

    const cpu_c: []const []const u8 = &.{
        "-DNDEBUG",
        "-D_GNU_SOURCE",
        "-D_XOPEN_SOURCE=600",
        "-DGGML_USE_CPU",
        "-DGGML_VERSION=\"0.9.7\"",
        "-DGGML_COMMIT=\"\"",
        "-pthread",
        "-fno-sanitize=undefined",
        "-mavx",
        "-mavx2",
        "-mfma",
        "-mf16c",
        "-msse4.2",
        "-DGGML_AVX",
        "-DGGML_AVX2",
        "-DGGML_FMA",
        "-DGGML_F16C",
        "-DGGML_SSE42",
    };

    const cpu_cpp: []const []const u8 = &.{
        "-DNDEBUG",
        "-D_GNU_SOURCE",
        "-D_XOPEN_SOURCE=600",
        "-DGGML_USE_CPU",
        "-DGGML_VERSION=\"0.9.7\"",
        "-DGGML_COMMIT=\"\"",
        "-pthread",
        "-std=c++17",
        "-fno-sanitize=undefined",
        "-mavx",
        "-mavx2",
        "-mfma",
        "-mf16c",
        "-msse4.2",
        "-DGGML_AVX",
        "-DGGML_AVX2",
        "-DGGML_FMA",
        "-DGGML_F16C",
        "-DGGML_SSE42",
    };

    // --- ggml-base C sources ---
    for ([_][]const u8{
        "ggml/src/ggml.c",
        "ggml/src/ggml-alloc.c",
        "ggml/src/ggml-quants.c",
    }) |src| {
        mod.addCSourceFile(.{ .file = dep.path(src), .flags = base_c });
    }

    // --- ggml-base C++ sources ---
    for ([_][]const u8{
        "ggml/src/ggml.cpp",
        "ggml/src/ggml-backend.cpp",
        "ggml/src/ggml-opt.cpp",
        "ggml/src/ggml-threading.cpp",
        "ggml/src/gguf.cpp",
    }) |src| {
        mod.addCSourceFile(.{ .file = dep.path(src), .flags = base_cpp });
    }

    // --- ggml backend registry ---
    for ([_][]const u8{
        "ggml/src/ggml-backend-dl.cpp",
        "ggml/src/ggml-backend-reg.cpp",
    }) |src| {
        mod.addCSourceFile(.{ .file = dep.path(src), .flags = base_cpp });
    }

    // --- ggml-cpu C sources (with SIMD) ---
    for ([_][]const u8{
        "ggml/src/ggml-cpu/ggml-cpu.c",
        "ggml/src/ggml-cpu/quants.c",
        "ggml/src/ggml-cpu/arch/x86/quants.c",
    }) |src| {
        mod.addCSourceFile(.{ .file = dep.path(src), .flags = cpu_c });
    }

    // --- ggml-cpu C++ sources (with SIMD) ---
    for ([_][]const u8{
        "ggml/src/ggml-cpu/ggml-cpu.cpp",
        "ggml/src/ggml-cpu/repack.cpp",
        "ggml/src/ggml-cpu/hbm.cpp",
        "ggml/src/ggml-cpu/traits.cpp",
        "ggml/src/ggml-cpu/amx/amx.cpp",
        "ggml/src/ggml-cpu/amx/mmq.cpp",
        "ggml/src/ggml-cpu/binary-ops.cpp",
        "ggml/src/ggml-cpu/unary-ops.cpp",
        "ggml/src/ggml-cpu/vec.cpp",
        "ggml/src/ggml-cpu/ops.cpp",
        "ggml/src/ggml-cpu/arch/x86/repack.cpp",
    }) |src| {
        mod.addCSourceFile(.{ .file = dep.path(src), .flags = cpu_cpp });
    }

    // --- CPU feature detection ---
    mod.addCSourceFile(.{
        .file = dep.path("ggml/src/ggml-cpu/arch/x86/cpu-feats.cpp"),
        .flags = base_cpp,
    });

    // --- whisper.cpp source ---
    mod.addCSourceFile(.{
        .file = dep.path("src/whisper.cpp"),
        .flags = base_cpp,
    });

    mod.linkSystemLibrary("c++", .{});

    const lib = b.addLibrary(.{
        .name = "whisper",
        .root_module = mod,
        .linkage = .static,
    });

    return lib;
}
