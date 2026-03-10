const std = @import("std");
const gst = @import("gst");
const gst_app = @import("gst_app");
const glib = @import("glib");
const gobject = @import("gobject");

/// GStreamer-based audio capture: records from PulseAudio mic as 16kHz mono f32.
pub const AudioCapture = struct {
    pipeline: *gst.Element,
    appsink: *gst_app.AppSink,

    const pipeline_desc =
        "pulsesrc ! audioconvert ! audioresample ! " ++
        "appsink name=sink caps=audio/x-raw,format=F32LE,rate=16000,channels=1";

    pub fn create() ?AudioCapture {
        gst.init(null, null);

        var err: ?*glib.Error = null;
        const pipeline = gst.parseLaunch(pipeline_desc, &err) orelse {
            if (err) |e| glib.Error.free(e);
            return null;
        };
        if (err) |e| glib.Error.free(e);

        // Get the appsink element by name
        const bin: *gst.Bin = @ptrCast(@alignCast(pipeline));
        const sink_element = bin.getByName("sink") orelse return null;
        const appsink: *gst_app.AppSink = @ptrCast(@alignCast(sink_element));

        return .{
            .pipeline = pipeline,
            .appsink = appsink,
        };
    }

    pub fn start(self: *AudioCapture) void {
        _ = self.pipeline.setState(.playing);
    }

    /// Stops recording and returns all captured audio samples.
    /// Caller must free the returned slice with page_allocator.
    pub fn stop(self: *AudioCapture) ?[]f32 {
        // Send EOS event — pipeline stays PLAYING so appsink can still deliver
        // buffered samples. pullSample will return NULL once EOS reaches the sink.
        _ = self.pipeline.sendEvent(gst.Event.newEos());

        const allocator = std.heap.page_allocator;
        var samples: std.ArrayList(f32) = .empty;

        // Pull all samples until EOS (pullSample returns NULL on EOS).
        // Use tryPullSample with 1s timeout as safety bound.
        while (true) {
            const sample = self.appsink.tryPullSample(1_000_000_000) orelse break;
            defer sample.unref();

            const buffer = sample.getBuffer() orelse continue;
            var map_info: gst.MapInfo = undefined;
            if (buffer.map(&map_info, .{ .read = true }) != 0) {
                defer buffer.unmap(&map_info);
                if (map_info.f_data) |data| {
                    const float_data: [*]const f32 = @ptrCast(@alignCast(data));
                    const n_samples = map_info.f_size / @sizeOf(f32);
                    samples.appendSlice(allocator, float_data[0..n_samples]) catch break;
                }
            }
        }

        // Now safe to tear down
        _ = self.pipeline.setState(.null);

        if (samples.items.len == 0) {
            samples.deinit(allocator);
            return null;
        }
        return samples.toOwnedSlice(allocator) catch null;
    }

    pub fn destroy(self: *AudioCapture) void {
        _ = self.pipeline.setState(.null);
        self.pipeline.as(gst.Object).as(gobject.Object).unref();
    }
};
