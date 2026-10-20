/// Built-in modes share one registry for catalog metadata and navigation.
pub const Mode = enum {
    leader,
    fuzzy,
    emoji,
    dictation,

    pub fn id(self: Mode) [:0]const u8 {
        return switch (self) {
            .leader => "leadr:mode:leader",
            .fuzzy => "leadr:mode:fuzzy",
            .emoji => "leadr:mode:emoji",
            .dictation => "leadr:mode:dictation",
        };
    }

    pub fn title(self: Mode) [:0]const u8 {
        return switch (self) {
            .leader => "Leader Mode",
            .fuzzy => "Fuzzy Mode",
            .emoji => "Emoji Mode",
            .dictation => "Dictation Mode",
        };
    }

    pub fn description(self: Mode) [:0]const u8 {
        return switch (self) {
            .leader => "Mode · Keyboard bindings and combos",
            .fuzzy => "Mode · Search apps and modes",
            .emoji => "Mode · Emoji picker",
            .dictation => "Mode · Talk, voice transcription",
        };
    }

    pub fn icon(self: Mode) [:0]const u8 {
        return switch (self) {
            .leader => "input-keyboard-symbolic",
            .fuzzy => "system-search-symbolic",
            .emoji => "face-smile-symbolic",
            .dictation => "audio-input-microphone-symbolic",
        };
    }
};
