const std = @import("std");

// --- Types from whisper.h (via zig translate-c) ---

pub const WhisperContext = opaque {};
const WhisperState = opaque {};

const whisper_token = i32;

const WhisperAhead = extern struct {
    n_text_layer: c_int = 0,
    n_head: c_int = 0,
};

const WhisperAheads = extern struct {
    n_heads: usize = 0,
    heads: ?[*]const WhisperAhead = null,
};

const WhisperContextParams = extern struct {
    use_gpu: bool = false,
    flash_attn: bool = false,
    gpu_device: c_int = 0,
    dtw_token_timestamps: bool = false,
    dtw_aheads_preset: c_uint = 0,
    dtw_n_top: c_int = 0,
    dtw_aheads: WhisperAheads = std.mem.zeroes(WhisperAheads),
    dtw_mem_size: usize = 0,
};

const WhisperTokenData = extern struct {
    id: whisper_token = 0,
    tid: whisper_token = 0,
    p: f32 = 0,
    plog: f32 = 0,
    pt: f32 = 0,
    ptsum: f32 = 0,
    t0: i64 = 0,
    t1: i64 = 0,
    t_dtw: i64 = 0,
    vlen: f32 = 0,
};

const WhisperGrammarElement = extern struct {
    type: c_uint = 0,
    value: u32 = 0,
};

const WhisperVadParams = extern struct {
    threshold: f32 = 0,
    min_speech_duration_ms: c_int = 0,
    min_silence_duration_ms: c_int = 0,
    max_speech_duration_s: f32 = 0,
    speech_pad_ms: c_int = 0,
    samples_overlap: f32 = 0,
};

const WhisperSamplingStrategy = enum(c_uint) {
    greedy = 0,
    beam_search = 1,
};

const WhisperFullParams = extern struct {
    strategy: WhisperSamplingStrategy = .greedy,
    n_threads: c_int = 0,
    n_max_text_ctx: c_int = 0,
    offset_ms: c_int = 0,
    duration_ms: c_int = 0,
    translate: bool = false,
    no_context: bool = false,
    no_timestamps: bool = false,
    single_segment: bool = false,
    print_special: bool = false,
    print_progress: bool = false,
    print_realtime: bool = false,
    print_timestamps: bool = false,
    token_timestamps: bool = false,
    thold_pt: f32 = 0,
    thold_ptsum: f32 = 0,
    max_len: c_int = 0,
    split_on_word: bool = false,
    max_tokens: c_int = 0,
    debug_mode: bool = false,
    audio_ctx: c_int = 0,
    tdrz_enable: bool = false,
    suppress_regex: ?[*:0]const u8 = null,
    initial_prompt: ?[*:0]const u8 = null,
    carry_initial_prompt: bool = false,
    prompt_tokens: ?[*]const whisper_token = null,
    prompt_n_tokens: c_int = 0,
    language: ?[*:0]const u8 = null,
    detect_language: bool = false,
    suppress_blank: bool = false,
    suppress_nst: bool = false,
    temperature: f32 = 0,
    max_initial_ts: f32 = 0,
    length_penalty: f32 = 0,
    temperature_inc: f32 = 0,
    entropy_thold: f32 = 0,
    logprob_thold: f32 = 0,
    no_speech_thold: f32 = 0,
    greedy: extern struct { best_of: c_int = 0 } = .{},
    beam_search: extern struct { beam_size: c_int = 0, patience: f32 = 0 } = .{},
    new_segment_callback: ?*const fn (?*WhisperContext, ?*WhisperState, c_int, ?*anyopaque) callconv(.c) void = null,
    new_segment_callback_user_data: ?*anyopaque = null,
    progress_callback: ?*const fn (?*WhisperContext, ?*WhisperState, c_int, ?*anyopaque) callconv(.c) void = null,
    progress_callback_user_data: ?*anyopaque = null,
    encoder_begin_callback: ?*const fn (?*WhisperContext, ?*WhisperState, ?*anyopaque) callconv(.c) bool = null,
    encoder_begin_callback_user_data: ?*anyopaque = null,
    abort_callback: ?*const fn (?*anyopaque) callconv(.c) bool = null,
    abort_callback_user_data: ?*anyopaque = null,
    logits_filter_callback: ?*const fn (?*WhisperContext, ?*WhisperState, ?[*]const WhisperTokenData, c_int, ?[*]f32, ?*anyopaque) callconv(.c) void = null,
    logits_filter_callback_user_data: ?*anyopaque = null,
    grammar_rules: ?[*]?[*]const WhisperGrammarElement = null,
    n_grammar_rules: usize = 0,
    i_start_rule: usize = 0,
    grammar_penalty: f32 = 0,
    vad: bool = false,
    vad_model_path: ?[*:0]const u8 = null,
    vad_params: WhisperVadParams = std.mem.zeroes(WhisperVadParams),
};

// --- C externs (direct whisper.h API, no wrapper needed) ---

extern fn whisper_context_default_params() WhisperContextParams;
extern fn whisper_init_from_file_with_params(path_model: [*:0]const u8, params: WhisperContextParams) ?*WhisperContext;
extern fn whisper_full_default_params(strategy: WhisperSamplingStrategy) WhisperFullParams;
extern fn whisper_full(ctx: *WhisperContext, params: WhisperFullParams, samples: [*]const f32, n_samples: c_int) c_int;
extern fn whisper_full_n_segments(ctx: *WhisperContext) c_int;
extern fn whisper_full_get_segment_text(ctx: *WhisperContext, i_segment: c_int) ?[*:0]const u8;
extern fn whisper_free(ctx: *WhisperContext) void;

// --- Public API ---

pub fn initFromFile(path: [*:0]const u8) ?*WhisperContext {
    var params = whisper_context_default_params();
    params.use_gpu = false;
    return whisper_init_from_file_with_params(path, params);
}

/// Run whisper transcription on audio samples. Returns concatenated segment texts.
/// Caller must free the result with page_allocator.
pub fn transcribe(ctx: *WhisperContext, samples: []const f32) ?[:0]const u8 {
    const params = whisper_full_default_params(.greedy);

    const rc = whisper_full(ctx, params, samples.ptr, @intCast(samples.len));
    if (rc != 0) return null;

    const n_segments = whisper_full_n_segments(ctx);
    if (n_segments <= 0) return null;

    const allocator = std.heap.page_allocator;
    var result: std.ArrayList(u8) = .empty;

    var i: c_int = 0;
    while (i < n_segments) : (i += 1) {
        if (whisper_full_get_segment_text(ctx, i)) |text| {
            const slice = std.mem.span(text);
            result.appendSlice(allocator, slice) catch return null;
        }
    }

    // Null-terminate
    result.append(allocator, 0) catch return null;
    const owned = result.toOwnedSlice(allocator) catch return null;
    if (owned.len == 0) return null;
    return owned[0 .. owned.len - 1 :0];
}

pub fn free(ctx: *WhisperContext) void {
    whisper_free(ctx);
}

// --- Tests ---

comptime {
    // Sizes must match C sizeof() — verified with gcc offsetof().
    std.debug.assert(@sizeOf(WhisperContextParams) == 48);
    std.debug.assert(@sizeOf(WhisperFullParams) == 304);
}

test "WhisperContextParams layout matches C" {
    const expect = std.testing.expectEqual;
    try expect(0, @offsetOf(WhisperContextParams, "use_gpu"));
    try expect(1, @offsetOf(WhisperContextParams, "flash_attn"));
    try expect(4, @offsetOf(WhisperContextParams, "gpu_device"));
    try expect(8, @offsetOf(WhisperContextParams, "dtw_token_timestamps"));
    try expect(12, @offsetOf(WhisperContextParams, "dtw_aheads_preset"));
    try expect(16, @offsetOf(WhisperContextParams, "dtw_n_top"));
    try expect(24, @offsetOf(WhisperContextParams, "dtw_aheads"));
    try expect(40, @offsetOf(WhisperContextParams, "dtw_mem_size"));
}

test "WhisperFullParams layout matches C" {
    const expect = std.testing.expectEqual;
    try expect(0, @offsetOf(WhisperFullParams, "strategy"));
    try expect(4, @offsetOf(WhisperFullParams, "n_threads"));
    try expect(20, @offsetOf(WhisperFullParams, "translate"));
    try expect(21, @offsetOf(WhisperFullParams, "no_context"));
    try expect(23, @offsetOf(WhisperFullParams, "single_segment"));
    try expect(24, @offsetOf(WhisperFullParams, "print_special"));
    try expect(28, @offsetOf(WhisperFullParams, "token_timestamps"));
    try expect(32, @offsetOf(WhisperFullParams, "thold_pt"));
    try expect(40, @offsetOf(WhisperFullParams, "max_len"));
    try expect(44, @offsetOf(WhisperFullParams, "split_on_word"));
    try expect(48, @offsetOf(WhisperFullParams, "max_tokens"));
    try expect(52, @offsetOf(WhisperFullParams, "debug_mode"));
    try expect(56, @offsetOf(WhisperFullParams, "audio_ctx"));
    try expect(60, @offsetOf(WhisperFullParams, "tdrz_enable"));
    try expect(64, @offsetOf(WhisperFullParams, "suppress_regex"));
    try expect(72, @offsetOf(WhisperFullParams, "initial_prompt"));
    try expect(88, @offsetOf(WhisperFullParams, "prompt_tokens"));
    try expect(104, @offsetOf(WhisperFullParams, "language"));
    try expect(113, @offsetOf(WhisperFullParams, "suppress_blank"));
    try expect(116, @offsetOf(WhisperFullParams, "temperature"));
    try expect(144, @offsetOf(WhisperFullParams, "greedy"));
    try expect(148, @offsetOf(WhisperFullParams, "beam_search"));
    try expect(160, @offsetOf(WhisperFullParams, "new_segment_callback"));
    try expect(240, @offsetOf(WhisperFullParams, "grammar_rules"));
    try expect(268, @offsetOf(WhisperFullParams, "vad"));
    try expect(272, @offsetOf(WhisperFullParams, "vad_model_path"));
    try expect(280, @offsetOf(WhisperFullParams, "vad_params"));
}
