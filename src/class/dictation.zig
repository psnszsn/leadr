const std = @import("std");
const gdk = @import("gdk");
const glib = @import("glib");
const gobject = @import("gobject");
const gtk = @import("gtk");

const Common = @import("../class.zig").Common;
const AudioCapture = @import("../audio_capture.zig").AudioCapture;
const whisper = @import("../whisper.zig");
const layer_shell = @import("gtk4_layer_shell");

pub const Dictation = extern struct {
    const Self = @This();
    parent_instance: Parent,

    pub const Parent = gtk.Window;
    pub const getGObjectType = gobject.ext.defineClass(Self, .{
        .name = "LeadrDictation",
        .instanceInit = &init,
        .classInit = &Class.init,
        .parent_class = &Class.parent,
        .private = .{ .Type = Private, .offset = &Private.offset },
    });

    const Private = struct {
        status_label: *gtk.Label,
        text_view: *gtk.TextView,
        audio: ?AudioCapture = null,
        whisper_ctx: ?*whisper.WhisperContext = null,
        recording: bool = false,
        transcribing: bool = false,

        pub var offset: c_int = 0;
    };

    const model_path: [*:0]const u8 = blk: {
        const home = "/home/vlad"; // resolved at comptime for simplicity
        break :blk home ++ "/.local/share/leadrgtk/ggml-base.en.bin";
    };

    fn init(self: *Self, _: *Class) callconv(.c) void {
        gtk.Widget.initTemplate(self.as(gtk.Widget));

        const window = self.as(gtk.Window);

        // Layer shell setup
        if (layer_shell.isSupported() != 0) {
            layer_shell.initForWindow(window);
            layer_shell.setLayer(window, .overlay);
            layer_shell.setKeyboardMode(window, .exclusive);
            layer_shell.setNamespace(window, "leadrgtk-dictation");
        }

        // Key event controllers
        const key_controller = gtk.EventControllerKey.new();
        _ = gtk.EventControllerKey.signals.key_pressed.connect(
            key_controller,
            *Self,
            &onKeyPressed,
            self,
            .{},
        );
        _ = gtk.EventControllerKey.signals.key_released.connect(
            key_controller,
            *Self,
            &onKeyReleased,
            self,
            .{},
        );
        self.as(gtk.Widget).addController(key_controller.as(gtk.EventController));
    }

    fn onKeyPressed(
        _: *gtk.EventControllerKey,
        keyval: c_uint,
        _: c_uint,
        _: gdk.ModifierType,
        self: *Self,
    ) callconv(.c) c_int {
        // Escape: hide
        if (keyval == 0xff1b) {
            self.as(gtk.Widget).setVisible(@intFromBool(false));
            return 1;
        }

        // Enter: type text into focused window
        if (keyval == 0xff0d) {
            copyAndHide(self);
            return 1;
        }

        // v press: start new recording
        if (keyval == 'v') {
            const priv = private(self);
            if (!priv.recording and !priv.transcribing) {
                startRecording(self);
            }
            return 1;
        }

        return 0;
    }

    fn onKeyReleased(
        _: *gtk.EventControllerKey,
        keyval: c_uint,
        _: c_uint,
        _: gdk.ModifierType,
        self: *Self,
    ) callconv(.c) void {
        // v release: stop recording and transcribe
        if (keyval == 'v') {
            const priv = private(self);
            if (priv.recording) {
                stopAndTranscribe(self);
            }
        }
    }

    fn startRecording(self: *Self) void {
        const priv = private(self);
        priv.audio = AudioCapture.create();
        if (priv.audio) |*audio| {
            audio.start();
            priv.recording = true;
            priv.status_label.setLabel("Recording…");
        } else {
            priv.status_label.setLabel("Failed to start recording");
        }
    }

    fn stopAndTranscribe(self: *Self) void {
        const priv = private(self);
        priv.recording = false;

        var audio = priv.audio orelse return;
        const ctx = priv.whisper_ctx orelse {
            audio.destroy();
            priv.audio = null;
            priv.status_label.setLabel("Whisper model not loaded");
            return;
        };

        priv.transcribing = true;
        priv.status_label.setLabel("Processing…");

        // Move audio capture to background thread for drain + transcribe
        const thread_data = std.heap.page_allocator.create(TranscribeData) catch {
            audio.destroy();
            priv.audio = null;
            priv.transcribing = false;
            priv.status_label.setLabel("Out of memory");
            return;
        };
        thread_data.* = .{
            .ctx = ctx,
            .audio = audio,
            .self = self,
        };
        priv.audio = null;

        _ = std.Thread.spawn(.{}, transcribeThread, .{thread_data}) catch {
            std.heap.page_allocator.destroy(thread_data);
            priv.transcribing = false;
            priv.status_label.setLabel("Failed to start transcription");
            return;
        };
    }

    const TranscribeData = struct {
        ctx: *whisper.WhisperContext,
        audio: AudioCapture,
        self: *Self,
    };

    const TranscribeResult = struct {
        self: *Self,
        text: ?[:0]const u8,
    };

    fn transcribeThread(data: *TranscribeData) void {
        var audio = data.audio;

        // Stop pipeline and drain samples (blocking — runs in background thread)
        const samples = audio.stop();
        audio.destroy();

        var text: ?[:0]const u8 = null;
        if (samples) |s| {
            text = whisper.transcribe(data.ctx, s);
            std.heap.page_allocator.free(s);
        }

        // Post result back to the main GTK thread
        const result = std.heap.page_allocator.create(TranscribeResult) catch return;
        result.* = .{ .self = data.self, .text = text };
        _ = glib.idleAdd(&onTranscribeComplete, result);

        std.heap.page_allocator.destroy(data);
    }

    fn onTranscribeComplete(ud: ?*anyopaque) callconv(.c) c_int {
        const result: *TranscribeResult = @ptrCast(@alignCast(ud orelse return 0));
        const self = result.self;
        const priv = private(self);

        priv.transcribing = false;

        if (result.text) |text| {
            // Set text in the TextView
            const buffer = priv.text_view.getBuffer();
            buffer.setText(text, @intCast(text.len));
            priv.status_label.setLabel("Press Enter to copy, Escape to cancel");
        } else {
            priv.status_label.setLabel("No speech detected. Hold Space to try again.");
        }

        std.heap.page_allocator.destroy(result);
        return 0; // G_SOURCE_REMOVE
    }

    fn copyAndHide(self: *Self) void {
        const priv = private(self);
        const buffer = priv.text_view.getBuffer();

        var start: gtk.TextIter = undefined;
        var end: gtk.TextIter = undefined;
        buffer.getBounds(&start, &end);
        const text: [*:0]const u8 = buffer.getText(&start, &end, 0);

        if (text[0] == 0) return;

        // Hide first so the previous window regains focus
        self.as(gtk.Widget).setVisible(@intFromBool(false));

        // Type text into the focused window via wtype after a short delay
        const slice = std.mem.span(text);
        var cmd_buf: [8192:0]u8 = undefined;
        const cmd = std.fmt.bufPrint(&cmd_buf, "sh -c 'sleep 0.15 && wtype \"{s}\"'", .{slice}) catch return;
        cmd_buf[cmd.len] = 0;
        _ = glib.spawnCommandLineAsync(&cmd_buf, null);
    }

    pub fn present(self: *Self) void {
        const priv = private(self);

        // Lazy-load whisper model on first show
        if (priv.whisper_ctx == null) {
            priv.whisper_ctx = whisper.initFromFile(model_path);
        }

        // Reset state
        priv.transcribing = false;
        const buffer = priv.text_view.getBuffer();
        var start: gtk.TextIter = undefined;
        var end: gtk.TextIter = undefined;
        buffer.getBounds(&start, &end);
        buffer.delete(&start, &end);

        self.as(gtk.Widget).setVisible(@intFromBool(true));
        self.as(gtk.Window).present();

        // Start recording immediately (user is holding v)
        startRecording(self);
    }

    fn dispose(self: *Self) callconv(.c) void {
        const priv = private(self);
        if (priv.audio) |*audio| {
            audio.destroy();
            priv.audio = null;
        }
        gtk.Widget.disposeTemplate(self.as(gtk.Widget), Self.getGObjectType());
        gobject.Object.virtual_methods.dispose.call(
            Class.parent,
            self.as(Parent),
        );
    }

    fn finalize(self: *Self) callconv(.c) void {
        const priv = private(self);
        if (priv.whisper_ctx) |ctx| {
            whisper.free(ctx);
            priv.whisper_ctx = null;
        }
        gobject.Object.virtual_methods.finalize.call(
            Class.parent,
            self.as(Parent),
        );
    }

    const C = Common(Self, Private);
    pub const as = C.as;
    pub const ref = C.ref;
    pub const unref = C.unref;
    const private = C.private;

    pub const Class = extern struct {
        parent_class: Parent.Class,
        var parent: *Parent.Class = undefined;
        pub const Instance = Self;
        pub const as = C.Class.as;

        fn init(class: *Class) callconv(.c) void {
            gtk.Widget.Class.setTemplateFromResource(
                class.as(gtk.Widget.Class),
                "/com/leadr/gtk/ui/dictation.ui",
            );
            C.Class.bindTemplateChildPrivate(class, "status_label", .{});
            C.Class.bindTemplateChildPrivate(class, "text_view", .{});

            gobject.Object.virtual_methods.dispose.implement(class, &dispose);
            gobject.Object.virtual_methods.finalize.implement(class, &finalize);
        }
    };
};
