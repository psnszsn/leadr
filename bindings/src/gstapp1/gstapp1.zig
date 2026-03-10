pub const ext = @import("ext.zig");
const gstapp = @This();

const std = @import("std");
const compat = @import("compat");
const gstbase = @import("gstbase1");
const gst = @import("gst1");
const gobject = @import("gobject2");
const glib = @import("glib2");
const gmodule = @import("gmodule2");
/// Appsink is a sink plugin that supports many different methods for making
/// the application get a handle on the GStreamer data in a pipeline. Unlike
/// most GStreamer elements, Appsink provides external API functions.
///
/// appsink can be used by linking to the gstappsink.h header file to access the
/// methods or by using the appsink action signals and properties.
///
/// The normal way of retrieving samples from appsink is by using the
/// `gstapp.AppSink.pullSample` and `gstapp.AppSink.pullPreroll` methods.
/// These methods block until a sample becomes available in the sink or when the
/// sink is shut down or reaches EOS. There are also timed variants of these
/// methods, `gstapp.AppSink.tryPullSample` and `gstapp.AppSink.tryPullPreroll`,
/// which accept a timeout parameter to limit the amount of time to wait.
///
/// Appsink will internally use a queue to collect buffers from the streaming
/// thread. If the application is not pulling samples fast enough, this queue
/// will consume a lot of memory over time. The "max-buffers", "max-time" and "max-bytes"
/// properties can be used to limit the queue size. The "drop" property controls whether the
/// streaming thread blocks or if older buffers are dropped when the maximum
/// queue size is reached. Note that blocking the streaming thread can negatively
/// affect real-time performance and should be avoided.
///
/// If a blocking behaviour is not desirable, setting the "emit-signals" property
/// to `TRUE` will make appsink emit the "new-sample" and "new-preroll" signals
/// when a sample can be pulled without blocking.
///
/// The "caps" property on appsink can be used to control the formats that
/// appsink can receive. This property can contain non-fixed caps, the format of
/// the pulled samples can be obtained by getting the sample caps.
///
/// If one of the pull-preroll or pull-sample methods return `NULL`, the appsink
/// is stopped or in the EOS state. You can check for the EOS state with the
/// "eos" property or with the `gstapp.AppSink.isEos` method.
///
/// The eos signal can also be used to be informed when the EOS state is reached
/// to avoid polling.
pub const AppSink = extern struct {
    pub const Parent = gstbase.BaseSink;
    pub const Implements = [_]type{gst.URIHandler};
    pub const Class = gstapp.AppSinkClass;
    f_basesink: gstbase.BaseSink,
    f_priv: ?*gstapp.AppSinkPrivate,
    f__gst_reserved: [4]*anyopaque,

    pub const virtual_methods = struct {
        pub const eos = struct {
            pub fn call(p_class: anytype, p_appsink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) void {
                return gobject.ext.as(AppSink.Class, p_class).f_eos.?(gobject.ext.as(AppSink, p_appsink));
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_appsink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) callconv(.c) void) void {
                gobject.ext.as(AppSink.Class, p_class).f_eos = @ptrCast(p_implementation);
            }
        };

        pub const new_preroll = struct {
            pub fn call(p_class: anytype, p_appsink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) gst.FlowReturn {
                return gobject.ext.as(AppSink.Class, p_class).f_new_preroll.?(gobject.ext.as(AppSink, p_appsink));
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_appsink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(AppSink.Class, p_class).f_new_preroll = @ptrCast(p_implementation);
            }
        };

        pub const new_sample = struct {
            pub fn call(p_class: anytype, p_appsink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) gst.FlowReturn {
                return gobject.ext.as(AppSink.Class, p_class).f_new_sample.?(gobject.ext.as(AppSink, p_appsink));
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_appsink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(AppSink.Class, p_class).f_new_sample = @ptrCast(p_implementation);
            }
        };

        /// Get the last preroll sample in `appsink`. This was the sample that caused the
        /// appsink to preroll in the PAUSED state.
        ///
        /// This function is typically used when dealing with a pipeline in the PAUSED
        /// state. Calling this function after doing a seek will give the sample right
        /// after the seek position.
        ///
        /// Calling this function will clear the internal reference to the preroll
        /// buffer.
        ///
        /// Note that the preroll sample will also be returned as the first sample
        /// when calling `gstapp.AppSink.pullSample`.
        ///
        /// If an EOS event was received before any buffers, this function returns
        /// `NULL`. Use gst_app_sink_is_eos () to check for the EOS condition.
        ///
        /// This function blocks until a preroll sample or EOS is received or the appsink
        /// element is set to the READY/NULL state.
        pub const pull_preroll = struct {
            pub fn call(p_class: anytype, p_appsink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) ?*gst.Sample {
                return gobject.ext.as(AppSink.Class, p_class).f_pull_preroll.?(gobject.ext.as(AppSink, p_appsink));
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_appsink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) callconv(.c) ?*gst.Sample) void {
                gobject.ext.as(AppSink.Class, p_class).f_pull_preroll = @ptrCast(p_implementation);
            }
        };

        /// This function blocks until a sample or EOS becomes available or the appsink
        /// element is set to the READY/NULL state.
        ///
        /// This function will only return samples when the appsink is in the PLAYING
        /// state. All rendered buffers will be put in a queue so that the application
        /// can pull samples at its own rate. Note that when the application does not
        /// pull samples fast enough, the queued buffers could consume a lot of memory,
        /// especially when dealing with raw video frames.
        ///
        /// If an EOS event was received before any buffers, this function returns
        /// `NULL`. Use gst_app_sink_is_eos () to check for the EOS condition.
        pub const pull_sample = struct {
            pub fn call(p_class: anytype, p_appsink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) ?*gst.Sample {
                return gobject.ext.as(AppSink.Class, p_class).f_pull_sample.?(gobject.ext.as(AppSink, p_appsink));
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_appsink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) callconv(.c) ?*gst.Sample) void {
                gobject.ext.as(AppSink.Class, p_class).f_pull_sample = @ptrCast(p_implementation);
            }
        };

        /// This function blocks until a sample or an event or EOS becomes available or the appsink
        /// element is set to the READY/NULL state or the timeout expires.
        ///
        /// This function will only return samples when the appsink is in the PLAYING
        /// state. All rendered buffers and events will be put in a queue so that the application
        /// can pull them at its own rate. Note that when the application does not
        /// pull samples fast enough, the queued buffers could consume a lot of memory,
        /// especially when dealing with raw video frames.
        /// Events can be pulled when the appsink is in the READY, PAUSED or PLAYING state.
        ///
        /// This function will only pull serialized events, excluding
        /// the EOS event for which this functions returns
        /// `NULL`. Use `gstapp.AppSink.isEos` to check for the EOS condition.
        ///
        /// This method is a variant of `gstapp.AppSink.tryPullSample` that can be used
        /// to handle incoming events events as well as samples.
        ///
        /// Note that future releases may extend this API to return other object types
        /// so make sure that your code is checking for the actual type it is handling.
        pub const try_pull_object = struct {
            pub fn call(p_class: anytype, p_appsink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_timeout: gst.ClockTime) ?*gst.MiniObject {
                return gobject.ext.as(AppSink.Class, p_class).f_try_pull_object.?(gobject.ext.as(AppSink, p_appsink), p_timeout);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_appsink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_timeout: gst.ClockTime) callconv(.c) ?*gst.MiniObject) void {
                gobject.ext.as(AppSink.Class, p_class).f_try_pull_object = @ptrCast(p_implementation);
            }
        };

        /// Get the last preroll sample in `appsink`. This was the sample that caused the
        /// appsink to preroll in the PAUSED state.
        ///
        /// This function is typically used when dealing with a pipeline in the PAUSED
        /// state. Calling this function after doing a seek will give the sample right
        /// after the seek position.
        ///
        /// Calling this function will clear the internal reference to the preroll
        /// buffer.
        ///
        /// Note that the preroll sample will also be returned as the first sample
        /// when calling `gstapp.AppSink.pullSample`.
        ///
        /// If an EOS event was received before any buffers or the timeout expires,
        /// this function returns `NULL`. Use gst_app_sink_is_eos () to check for the EOS
        /// condition.
        ///
        /// This function blocks until a preroll sample or EOS is received, the appsink
        /// element is set to the READY/NULL state, or the timeout expires.
        pub const try_pull_preroll = struct {
            pub fn call(p_class: anytype, p_appsink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_timeout: gst.ClockTime) ?*gst.Sample {
                return gobject.ext.as(AppSink.Class, p_class).f_try_pull_preroll.?(gobject.ext.as(AppSink, p_appsink), p_timeout);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_appsink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_timeout: gst.ClockTime) callconv(.c) ?*gst.Sample) void {
                gobject.ext.as(AppSink.Class, p_class).f_try_pull_preroll = @ptrCast(p_implementation);
            }
        };

        /// This function blocks until a sample or EOS becomes available or the appsink
        /// element is set to the READY/NULL state or the timeout expires.
        ///
        /// This function will only return samples when the appsink is in the PLAYING
        /// state. All rendered buffers will be put in a queue so that the application
        /// can pull samples at its own rate. Note that when the application does not
        /// pull samples fast enough, the queued buffers could consume a lot of memory,
        /// especially when dealing with raw video frames.
        ///
        /// If an EOS event was received before any buffers or the timeout expires,
        /// this function returns `NULL`. Use gst_app_sink_is_eos () to check for the EOS
        /// condition.
        pub const try_pull_sample = struct {
            pub fn call(p_class: anytype, p_appsink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_timeout: gst.ClockTime) ?*gst.Sample {
                return gobject.ext.as(AppSink.Class, p_class).f_try_pull_sample.?(gobject.ext.as(AppSink, p_appsink), p_timeout);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_appsink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_timeout: gst.ClockTime) callconv(.c) ?*gst.Sample) void {
                gobject.ext.as(AppSink.Class, p_class).f_try_pull_sample = @ptrCast(p_implementation);
            }
        };
    };

    pub const properties = struct {
        pub const buffer_list = struct {
            pub const name = "buffer-list";

            pub const Type = c_int;
        };

        pub const caps = struct {
            pub const name = "caps";

            pub const Type = ?*gst.Caps;
        };

        pub const drop = struct {
            pub const name = "drop";

            pub const Type = c_int;
        };

        pub const emit_signals = struct {
            pub const name = "emit-signals";

            pub const Type = c_int;
        };

        pub const eos = struct {
            pub const name = "eos";

            pub const Type = c_int;
        };

        /// Maximum amount of buffers in the queue (0 = unlimited).
        pub const max_buffers = struct {
            pub const name = "max-buffers";

            pub const Type = c_uint;
        };

        /// Maximum amount of bytes in the queue (0 = unlimited)
        pub const max_bytes = struct {
            pub const name = "max-bytes";

            pub const Type = u64;
        };

        /// Maximum total duration of data in the queue (0 = unlimited)
        pub const max_time = struct {
            pub const name = "max-time";

            pub const Type = u64;
        };

        /// Wait for all buffers to be processed after receiving an EOS.
        ///
        /// In cases where it is uncertain if an `appsink` will have a consumer for its buffers
        /// when it receives an EOS, set to `FALSE` to ensure that the `appsink` will not hang.
        pub const wait_on_eos = struct {
            pub const name = "wait-on-eos";

            pub const Type = c_int;
        };
    };

    pub const signals = struct {
        /// Signal that the end-of-stream has been reached. This signal is emitted from
        /// the streaming thread.
        pub const eos = struct {
            pub const name = "eos";

            pub fn connect(p_instance: anytype, comptime P_Data: type, p_callback: *const fn (@TypeOf(p_instance), P_Data) callconv(.c) void, p_data: P_Data, p_options: gobject.ext.ConnectSignalOptions(P_Data)) c_ulong {
                return gobject.signalConnectClosureById(
                    @ptrCast(@alignCast(gobject.ext.as(AppSink, p_instance))),
                    gobject.signalLookup("eos", AppSink.getGObjectType()),
                    glib.quarkFromString(p_options.detail orelse null),
                    gobject.CClosure.new(@ptrCast(p_callback), p_data, @ptrCast(p_options.destroyData)),
                    @intFromBool(p_options.after),
                );
            }
        };

        /// Signal that a new preroll sample is available.
        ///
        /// This signal is emitted from the streaming thread and only when the
        /// "emit-signals" property is `TRUE`.
        ///
        /// The new preroll sample can be retrieved with the "pull-preroll" action
        /// signal or `gstapp.AppSink.pullPreroll` either from this signal callback
        /// or from any other thread.
        ///
        /// Note that this signal is only emitted when the "emit-signals" property is
        /// set to `TRUE`, which it is not by default for performance reasons.
        pub const new_preroll = struct {
            pub const name = "new-preroll";

            pub fn connect(p_instance: anytype, comptime P_Data: type, p_callback: *const fn (@TypeOf(p_instance), P_Data) callconv(.c) gst.FlowReturn, p_data: P_Data, p_options: gobject.ext.ConnectSignalOptions(P_Data)) c_ulong {
                return gobject.signalConnectClosureById(
                    @ptrCast(@alignCast(gobject.ext.as(AppSink, p_instance))),
                    gobject.signalLookup("new-preroll", AppSink.getGObjectType()),
                    glib.quarkFromString(p_options.detail orelse null),
                    gobject.CClosure.new(@ptrCast(p_callback), p_data, @ptrCast(p_options.destroyData)),
                    @intFromBool(p_options.after),
                );
            }
        };

        /// Signal that a new sample is available.
        ///
        /// This signal is emitted from the streaming thread and only when the
        /// "emit-signals" property is `TRUE`.
        ///
        /// The new sample can be retrieved with the "pull-sample" action
        /// signal or `gstapp.AppSink.pullSample` either from this signal callback
        /// or from any other thread.
        ///
        /// Note that this signal is only emitted when the "emit-signals" property is
        /// set to `TRUE`, which it is not by default for performance reasons.
        pub const new_sample = struct {
            pub const name = "new-sample";

            pub fn connect(p_instance: anytype, comptime P_Data: type, p_callback: *const fn (@TypeOf(p_instance), P_Data) callconv(.c) gst.FlowReturn, p_data: P_Data, p_options: gobject.ext.ConnectSignalOptions(P_Data)) c_ulong {
                return gobject.signalConnectClosureById(
                    @ptrCast(@alignCast(gobject.ext.as(AppSink, p_instance))),
                    gobject.signalLookup("new-sample", AppSink.getGObjectType()),
                    glib.quarkFromString(p_options.detail orelse null),
                    gobject.CClosure.new(@ptrCast(p_callback), p_data, @ptrCast(p_options.destroyData)),
                    @intFromBool(p_options.after),
                );
            }
        };

        /// Signal that a new downstream serialized event is available.
        ///
        /// This signal is emitted from the streaming thread and only when the
        /// "emit-signals" property is `TRUE`.
        ///
        /// The new event can be retrieved with the "try-pull-object" action
        /// signal or `gstapp.AppSink.pullObject` either from this signal callback
        /// or from any other thread.
        ///
        /// EOS will not be notified using this signal, use `gstapp.AppSink.signals.eos` instead.
        /// EOS cannot be pulled either, use `gstapp.AppSink.isEos` to check for it.
        ///
        /// Note that this signal is only emitted when the "emit-signals" property is
        /// set to `TRUE`, which it is not by default for performance reasons.
        ///
        /// The callback should return `TRUE` if the event has been handled, which will
        /// skip basesink handling of the event, `FALSE` otherwise.
        pub const new_serialized_event = struct {
            pub const name = "new-serialized-event";

            pub fn connect(p_instance: anytype, comptime P_Data: type, p_callback: *const fn (@TypeOf(p_instance), P_Data) callconv(.c) c_int, p_data: P_Data, p_options: gobject.ext.ConnectSignalOptions(P_Data)) c_ulong {
                return gobject.signalConnectClosureById(
                    @ptrCast(@alignCast(gobject.ext.as(AppSink, p_instance))),
                    gobject.signalLookup("new-serialized-event", AppSink.getGObjectType()),
                    glib.quarkFromString(p_options.detail orelse null),
                    gobject.CClosure.new(@ptrCast(p_callback), p_data, @ptrCast(p_options.destroyData)),
                    @intFromBool(p_options.after),
                );
            }
        };

        /// Signal that a new propose_allocation query is available.
        ///
        /// This signal is emitted from the streaming thread and only when the
        /// "emit-signals" property is `TRUE`.
        pub const propose_allocation = struct {
            pub const name = "propose-allocation";

            pub fn connect(p_instance: anytype, comptime P_Data: type, p_callback: *const fn (@TypeOf(p_instance), p_query: *gst.Query, P_Data) callconv(.c) c_int, p_data: P_Data, p_options: gobject.ext.ConnectSignalOptions(P_Data)) c_ulong {
                return gobject.signalConnectClosureById(
                    @ptrCast(@alignCast(gobject.ext.as(AppSink, p_instance))),
                    gobject.signalLookup("propose-allocation", AppSink.getGObjectType()),
                    glib.quarkFromString(p_options.detail orelse null),
                    gobject.CClosure.new(@ptrCast(p_callback), p_data, @ptrCast(p_options.destroyData)),
                    @intFromBool(p_options.after),
                );
            }
        };

        /// Get the last preroll sample in `appsink`. This was the sample that caused the
        /// appsink to preroll in the PAUSED state.
        ///
        /// This function is typically used when dealing with a pipeline in the PAUSED
        /// state. Calling this function after doing a seek will give the sample right
        /// after the seek position.
        ///
        /// Calling this function will clear the internal reference to the preroll
        /// buffer.
        ///
        /// Note that the preroll sample will also be returned as the first sample
        /// when calling `gstapp.AppSink.pullSample` or the "pull-sample" action signal.
        ///
        /// If an EOS event was received before any buffers, this function returns
        /// `NULL`. Use gst_app_sink_is_eos () to check for the EOS condition.
        ///
        /// This function blocks until a preroll sample or EOS is received or the appsink
        /// element is set to the READY/NULL state.
        pub const pull_preroll = struct {
            pub const name = "pull-preroll";

            pub fn connect(p_instance: anytype, comptime P_Data: type, p_callback: *const fn (@TypeOf(p_instance), P_Data) callconv(.c) ?*gst.Sample, p_data: P_Data, p_options: gobject.ext.ConnectSignalOptions(P_Data)) c_ulong {
                return gobject.signalConnectClosureById(
                    @ptrCast(@alignCast(gobject.ext.as(AppSink, p_instance))),
                    gobject.signalLookup("pull-preroll", AppSink.getGObjectType()),
                    glib.quarkFromString(p_options.detail orelse null),
                    gobject.CClosure.new(@ptrCast(p_callback), p_data, @ptrCast(p_options.destroyData)),
                    @intFromBool(p_options.after),
                );
            }
        };

        /// This function blocks until a sample or EOS becomes available or the appsink
        /// element is set to the READY/NULL state.
        ///
        /// This function will only return samples when the appsink is in the PLAYING
        /// state. All rendered samples will be put in a queue so that the application
        /// can pull samples at its own rate.
        ///
        /// Note that when the application does not pull samples fast enough, the
        /// queued samples could consume a lot of memory, especially when dealing with
        /// raw video frames. It's possible to control the behaviour of the queue with
        /// the "drop" and "max-buffers" / "max-bytes" / "max-time" set of properties.
        ///
        /// If an EOS event was received before any buffers, this function returns
        /// `NULL`. Use gst_app_sink_is_eos () to check for the EOS condition.
        pub const pull_sample = struct {
            pub const name = "pull-sample";

            pub fn connect(p_instance: anytype, comptime P_Data: type, p_callback: *const fn (@TypeOf(p_instance), P_Data) callconv(.c) ?*gst.Sample, p_data: P_Data, p_options: gobject.ext.ConnectSignalOptions(P_Data)) c_ulong {
                return gobject.signalConnectClosureById(
                    @ptrCast(@alignCast(gobject.ext.as(AppSink, p_instance))),
                    gobject.signalLookup("pull-sample", AppSink.getGObjectType()),
                    glib.quarkFromString(p_options.detail orelse null),
                    gobject.CClosure.new(@ptrCast(p_callback), p_data, @ptrCast(p_options.destroyData)),
                    @intFromBool(p_options.after),
                );
            }
        };

        /// This function blocks until a sample or an event becomes available or the appsink
        /// element is set to the READY/NULL state or the timeout expires.
        ///
        /// This function will only return samples when the appsink is in the PLAYING
        /// state. All rendered samples and events will be put in a queue so that the application
        /// can pull them at its own rate.
        /// Events can be pulled when the appsink is in the READY, PAUSED or PLAYING state.
        ///
        /// Note that when the application does not pull samples fast enough, the
        /// queued samples could consume a lot of memory, especially when dealing with
        /// raw video frames. It's possible to control the behaviour of the queue with
        /// the "drop" and "max-buffers" / "max-bytes" / "max-time" set of properties.
        ///
        /// This function will only pull serialized events, excluding
        /// the EOS event for which this functions returns
        /// `NULL`. Use `gstapp.AppSink.isEos` to check for the EOS condition.
        ///
        /// This signal is a variant of `gstapp.AppSink.signals.@"try"`-pull-sample: that can be used
        /// to handle incoming events as well as samples.
        ///
        /// Note that future releases may extend this API to return other object types
        /// so make sure that your code is checking for the actual type it is handling.
        pub const try_pull_object = struct {
            pub const name = "try-pull-object";

            pub fn connect(p_instance: anytype, comptime P_Data: type, p_callback: *const fn (@TypeOf(p_instance), p_timeout: u64, P_Data) callconv(.c) ?*gst.MiniObject, p_data: P_Data, p_options: gobject.ext.ConnectSignalOptions(P_Data)) c_ulong {
                return gobject.signalConnectClosureById(
                    @ptrCast(@alignCast(gobject.ext.as(AppSink, p_instance))),
                    gobject.signalLookup("try-pull-object", AppSink.getGObjectType()),
                    glib.quarkFromString(p_options.detail orelse null),
                    gobject.CClosure.new(@ptrCast(p_callback), p_data, @ptrCast(p_options.destroyData)),
                    @intFromBool(p_options.after),
                );
            }
        };

        /// Get the last preroll sample in `appsink`. This was the sample that caused the
        /// appsink to preroll in the PAUSED state.
        ///
        /// This function is typically used when dealing with a pipeline in the PAUSED
        /// state. Calling this function after doing a seek will give the sample right
        /// after the seek position.
        ///
        /// Calling this function will clear the internal reference to the preroll
        /// buffer.
        ///
        /// Note that the preroll sample will also be returned as the first sample
        /// when calling `gstapp.AppSink.pullSample` or the "pull-sample" action signal.
        ///
        /// If an EOS event was received before any buffers or the timeout expires,
        /// this function returns `NULL`. Use gst_app_sink_is_eos () to check for the EOS
        /// condition.
        ///
        /// This function blocks until a preroll sample or EOS is received, the appsink
        /// element is set to the READY/NULL state, or the timeout expires.
        pub const try_pull_preroll = struct {
            pub const name = "try-pull-preroll";

            pub fn connect(p_instance: anytype, comptime P_Data: type, p_callback: *const fn (@TypeOf(p_instance), p_timeout: u64, P_Data) callconv(.c) ?*gst.Sample, p_data: P_Data, p_options: gobject.ext.ConnectSignalOptions(P_Data)) c_ulong {
                return gobject.signalConnectClosureById(
                    @ptrCast(@alignCast(gobject.ext.as(AppSink, p_instance))),
                    gobject.signalLookup("try-pull-preroll", AppSink.getGObjectType()),
                    glib.quarkFromString(p_options.detail orelse null),
                    gobject.CClosure.new(@ptrCast(p_callback), p_data, @ptrCast(p_options.destroyData)),
                    @intFromBool(p_options.after),
                );
            }
        };

        /// This function blocks until a sample or EOS becomes available or the appsink
        /// element is set to the READY/NULL state or the timeout expires.
        ///
        /// This function will only return samples when the appsink is in the PLAYING
        /// state. All rendered samples will be put in a queue so that the application
        /// can pull samples at its own rate.
        ///
        /// Note that when the application does not pull samples fast enough, the
        /// queued samples could consume a lot of memory, especially when dealing with
        /// raw video frames. It's possible to control the behaviour of the queue with
        /// the "drop" and "max-buffers" / "max-bytes" / "max-time" set of properties.
        ///
        /// If an EOS event was received before any buffers or the timeout expires,
        /// this function returns `NULL`. Use gst_app_sink_is_eos () to check
        /// for the EOS condition.
        pub const try_pull_sample = struct {
            pub const name = "try-pull-sample";

            pub fn connect(p_instance: anytype, comptime P_Data: type, p_callback: *const fn (@TypeOf(p_instance), p_timeout: u64, P_Data) callconv(.c) ?*gst.Sample, p_data: P_Data, p_options: gobject.ext.ConnectSignalOptions(P_Data)) c_ulong {
                return gobject.signalConnectClosureById(
                    @ptrCast(@alignCast(gobject.ext.as(AppSink, p_instance))),
                    gobject.signalLookup("try-pull-sample", AppSink.getGObjectType()),
                    glib.quarkFromString(p_options.detail orelse null),
                    gobject.CClosure.new(@ptrCast(p_callback), p_data, @ptrCast(p_options.destroyData)),
                    @intFromBool(p_options.after),
                );
            }
        };
    };

    /// Check if `appsink` supports buffer lists.
    extern fn gst_app_sink_get_buffer_list_support(p_appsink: *AppSink) c_int;
    pub const getBufferListSupport = gst_app_sink_get_buffer_list_support;

    /// Get the configured caps on `appsink`.
    extern fn gst_app_sink_get_caps(p_appsink: *AppSink) ?*gst.Caps;
    pub const getCaps = gst_app_sink_get_caps;

    /// Check if `appsink` will drop old buffers when the maximum amount of queued
    /// data is reached (meaning max buffers, time or bytes limit, whichever is hit first).
    extern fn gst_app_sink_get_drop(p_appsink: *AppSink) c_int;
    pub const getDrop = gst_app_sink_get_drop;

    /// Check if appsink will emit the "new-preroll" and "new-sample" signals.
    extern fn gst_app_sink_get_emit_signals(p_appsink: *AppSink) c_int;
    pub const getEmitSignals = gst_app_sink_get_emit_signals;

    /// Get the maximum amount of buffers that can be queued in `appsink`.
    extern fn gst_app_sink_get_max_buffers(p_appsink: *AppSink) c_uint;
    pub const getMaxBuffers = gst_app_sink_get_max_buffers;

    /// Get the maximum total size, in bytes, that can be queued in `appsink`.
    extern fn gst_app_sink_get_max_bytes(p_appsink: *AppSink) u64;
    pub const getMaxBytes = gst_app_sink_get_max_bytes;

    /// Get the maximum total duration that can be queued in `appsink`.
    extern fn gst_app_sink_get_max_time(p_appsink: *AppSink) gst.ClockTime;
    pub const getMaxTime = gst_app_sink_get_max_time;

    /// Check if `appsink` will wait for all buffers to be consumed when an EOS is
    /// received.
    extern fn gst_app_sink_get_wait_on_eos(p_appsink: *AppSink) c_int;
    pub const getWaitOnEos = gst_app_sink_get_wait_on_eos;

    /// Check if `appsink` is EOS, which is when no more samples can be pulled because
    /// an EOS event was received.
    ///
    /// This function also returns `TRUE` when the appsink is not in the PAUSED or
    /// PLAYING state.
    extern fn gst_app_sink_is_eos(p_appsink: *AppSink) c_int;
    pub const isEos = gst_app_sink_is_eos;

    /// This function blocks until a sample or an event becomes available or the appsink
    /// element is set to the READY/NULL state.
    ///
    /// This function will only return samples when the appsink is in the PLAYING
    /// state. All rendered buffers and events will be put in a queue so that the application
    /// can pull them at its own rate. Note that when the application does not
    /// pull samples fast enough, the queued buffers could consume a lot of memory,
    /// especially when dealing with raw video frames.
    /// Events can be pulled when the appsink is in the READY, PAUSED or PLAYING state.
    ///
    /// This function will only pull serialized events, excluding
    /// the EOS event for which this functions returns
    /// `NULL`. Use `gstapp.AppSink.isEos` to check for the EOS condition.
    ///
    /// This method is a variant of `gstapp.AppSink.pullSample` that can be used
    /// to handle incoming events events as well as samples.
    ///
    /// Note that future releases may extend this API to return other object types
    /// so make sure that your code is checking for the actual type it is handling.
    extern fn gst_app_sink_pull_object(p_appsink: *AppSink) ?*gst.MiniObject;
    pub const pullObject = gst_app_sink_pull_object;

    /// Get the last preroll sample in `appsink`. This was the sample that caused the
    /// appsink to preroll in the PAUSED state.
    ///
    /// This function is typically used when dealing with a pipeline in the PAUSED
    /// state. Calling this function after doing a seek will give the sample right
    /// after the seek position.
    ///
    /// Calling this function will clear the internal reference to the preroll
    /// buffer.
    ///
    /// Note that the preroll sample will also be returned as the first sample
    /// when calling `gstapp.AppSink.pullSample`.
    ///
    /// If an EOS event was received before any buffers, this function returns
    /// `NULL`. Use gst_app_sink_is_eos () to check for the EOS condition.
    ///
    /// This function blocks until a preroll sample or EOS is received or the appsink
    /// element is set to the READY/NULL state.
    extern fn gst_app_sink_pull_preroll(p_appsink: *AppSink) ?*gst.Sample;
    pub const pullPreroll = gst_app_sink_pull_preroll;

    /// This function blocks until a sample or EOS becomes available or the appsink
    /// element is set to the READY/NULL state.
    ///
    /// This function will only return samples when the appsink is in the PLAYING
    /// state. All rendered buffers will be put in a queue so that the application
    /// can pull samples at its own rate. Note that when the application does not
    /// pull samples fast enough, the queued buffers could consume a lot of memory,
    /// especially when dealing with raw video frames.
    ///
    /// If an EOS event was received before any buffers, this function returns
    /// `NULL`. Use gst_app_sink_is_eos () to check for the EOS condition.
    extern fn gst_app_sink_pull_sample(p_appsink: *AppSink) ?*gst.Sample;
    pub const pullSample = gst_app_sink_pull_sample;

    /// Instruct `appsink` to enable or disable buffer list support.
    ///
    /// For backwards-compatibility reasons applications need to opt in
    /// to indicate that they will be able to handle buffer lists.
    extern fn gst_app_sink_set_buffer_list_support(p_appsink: *AppSink, p_enable_lists: c_int) void;
    pub const setBufferListSupport = gst_app_sink_set_buffer_list_support;

    /// Set callbacks which will be executed for each new preroll, new sample and eos.
    /// This is an alternative to using the signals, it has lower overhead and is thus
    /// less expensive, but also less flexible.
    ///
    /// If callbacks are installed, no signals will be emitted for performance
    /// reasons.
    ///
    /// Before 1.16.3 it was not possible to change the callbacks in a thread-safe
    /// way.
    extern fn gst_app_sink_set_callbacks(p_appsink: *AppSink, p_callbacks: *gstapp.AppSinkCallbacks, p_user_data: ?*anyopaque, p_notify: glib.DestroyNotify) void;
    pub const setCallbacks = gst_app_sink_set_callbacks;

    /// Set the capabilities on the appsink element.  This function takes
    /// a copy of the caps structure. After calling this method, the sink will only
    /// accept caps that match `caps`. If `caps` is non-fixed, or incomplete,
    /// you must check the caps on the samples to get the actual used caps.
    extern fn gst_app_sink_set_caps(p_appsink: *AppSink, p_caps: ?*const gst.Caps) void;
    pub const setCaps = gst_app_sink_set_caps;

    /// Instruct `appsink` to drop old buffers when the maximum amount of queued
    /// data is reached, that is, when any configured limit is hit (max-buffers, max-time or max-bytes).
    extern fn gst_app_sink_set_drop(p_appsink: *AppSink, p_drop: c_int) void;
    pub const setDrop = gst_app_sink_set_drop;

    /// Make appsink emit the "new-preroll" and "new-sample" signals. This option is
    /// by default disabled because signal emission is expensive and unneeded when
    /// the application prefers to operate in pull mode.
    extern fn gst_app_sink_set_emit_signals(p_appsink: *AppSink, p_emit: c_int) void;
    pub const setEmitSignals = gst_app_sink_set_emit_signals;

    /// Set the maximum amount of buffers that can be queued in `appsink`. After this
    /// amount of buffers are queued in appsink, any more buffers will block upstream
    /// elements until a sample is pulled from `appsink`, unless 'drop' is set, in which
    /// case new buffers will be discarded.
    extern fn gst_app_sink_set_max_buffers(p_appsink: *AppSink, p_max: c_uint) void;
    pub const setMaxBuffers = gst_app_sink_set_max_buffers;

    /// Set the maximum total size that can be queued in `appsink`. After this
    /// amount of buffers are queued in appsink, any more buffers will block upstream
    /// elements until a sample is pulled from `appsink`, unless 'drop' is set, in which
    /// case new buffers will be discarded.
    extern fn gst_app_sink_set_max_bytes(p_appsink: *AppSink, p_max: u64) void;
    pub const setMaxBytes = gst_app_sink_set_max_bytes;

    /// Set the maximum total duration that can be queued in `appsink`. After this
    /// amount of buffers are queued in appsink, any more buffers will block upstream
    /// elements until a sample is pulled from `appsink`, unless 'drop' is set, in which
    /// case new buffers will be discarded.
    extern fn gst_app_sink_set_max_time(p_appsink: *AppSink, p_max: gst.ClockTime) void;
    pub const setMaxTime = gst_app_sink_set_max_time;

    /// Instruct `appsink` to wait for all buffers to be consumed when an EOS is received.
    extern fn gst_app_sink_set_wait_on_eos(p_appsink: *AppSink, p_wait: c_int) void;
    pub const setWaitOnEos = gst_app_sink_set_wait_on_eos;

    /// This function blocks until a sample or an event or EOS becomes available or the appsink
    /// element is set to the READY/NULL state or the timeout expires.
    ///
    /// This function will only return samples when the appsink is in the PLAYING
    /// state. All rendered buffers and events will be put in a queue so that the application
    /// can pull them at its own rate. Note that when the application does not
    /// pull samples fast enough, the queued buffers could consume a lot of memory,
    /// especially when dealing with raw video frames.
    /// Events can be pulled when the appsink is in the READY, PAUSED or PLAYING state.
    ///
    /// This function will only pull serialized events, excluding
    /// the EOS event for which this functions returns
    /// `NULL`. Use `gstapp.AppSink.isEos` to check for the EOS condition.
    ///
    /// This method is a variant of `gstapp.AppSink.tryPullSample` that can be used
    /// to handle incoming events events as well as samples.
    ///
    /// Note that future releases may extend this API to return other object types
    /// so make sure that your code is checking for the actual type it is handling.
    extern fn gst_app_sink_try_pull_object(p_appsink: *AppSink, p_timeout: gst.ClockTime) ?*gst.MiniObject;
    pub const tryPullObject = gst_app_sink_try_pull_object;

    /// Get the last preroll sample in `appsink`. This was the sample that caused the
    /// appsink to preroll in the PAUSED state.
    ///
    /// This function is typically used when dealing with a pipeline in the PAUSED
    /// state. Calling this function after doing a seek will give the sample right
    /// after the seek position.
    ///
    /// Calling this function will clear the internal reference to the preroll
    /// buffer.
    ///
    /// Note that the preroll sample will also be returned as the first sample
    /// when calling `gstapp.AppSink.pullSample`.
    ///
    /// If an EOS event was received before any buffers or the timeout expires,
    /// this function returns `NULL`. Use gst_app_sink_is_eos () to check for the EOS
    /// condition.
    ///
    /// This function blocks until a preroll sample or EOS is received, the appsink
    /// element is set to the READY/NULL state, or the timeout expires.
    extern fn gst_app_sink_try_pull_preroll(p_appsink: *AppSink, p_timeout: gst.ClockTime) ?*gst.Sample;
    pub const tryPullPreroll = gst_app_sink_try_pull_preroll;

    /// This function blocks until a sample or EOS becomes available or the appsink
    /// element is set to the READY/NULL state or the timeout expires.
    ///
    /// This function will only return samples when the appsink is in the PLAYING
    /// state. All rendered buffers will be put in a queue so that the application
    /// can pull samples at its own rate. Note that when the application does not
    /// pull samples fast enough, the queued buffers could consume a lot of memory,
    /// especially when dealing with raw video frames.
    ///
    /// If an EOS event was received before any buffers or the timeout expires,
    /// this function returns `NULL`. Use gst_app_sink_is_eos () to check for the EOS
    /// condition.
    extern fn gst_app_sink_try_pull_sample(p_appsink: *AppSink, p_timeout: gst.ClockTime) ?*gst.Sample;
    pub const tryPullSample = gst_app_sink_try_pull_sample;

    extern fn gst_app_sink_get_type() usize;
    pub const getGObjectType = gst_app_sink_get_type;

    extern fn g_object_ref(p_self: *gstapp.AppSink) void;
    pub const ref = g_object_ref;

    extern fn g_object_unref(p_self: *gstapp.AppSink) void;
    pub const unref = g_object_unref;

    pub fn as(p_instance: *AppSink, comptime P_T: type) *P_T {
        return gobject.ext.as(P_T, p_instance);
    }

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// The appsrc element can be used by applications to insert data into a
/// GStreamer pipeline. Unlike most GStreamer elements, appsrc provides
/// external API functions.
///
/// appsrc can be used by linking with the libgstapp library to access the
/// methods directly or by using the appsrc action signals.
///
/// Before operating appsrc, the caps property must be set to fixed caps
/// describing the format of the data that will be pushed with appsrc. An
/// exception to this is when pushing buffers with unknown caps, in which case no
/// caps should be set. This is typically true of file-like sources that push raw
/// byte buffers. If you don't want to explicitly set the caps, you can use
/// gst_app_src_push_sample. This method gets the caps associated with the
/// sample and sets them on the appsrc replacing any previously set caps (if
/// different from sample's caps).
///
/// The main way of handing data to the appsrc element is by calling the
/// `gstapp.AppSrc.pushBuffer` method or by emitting the push-buffer action signal.
/// This will put the buffer onto a queue from which appsrc will read from in its
/// streaming thread. It is important to note that data transport will not happen
/// from the thread that performed the push-buffer call.
///
/// The "max-bytes", "max-buffers" and "max-time" properties control how much
/// data can be queued in appsrc before appsrc considers the queue full. A
/// filled internal queue will always signal the "enough-data" signal, which
/// signals the application that it should stop pushing data into appsrc. The
/// "block" property will cause appsrc to block the push-buffer method until
/// free data becomes available again.
///
/// When the internal queue is running out of data, the "need-data" signal is
/// emitted, which signals the application that it should start pushing more data
/// into appsrc.
///
/// In addition to the "need-data" and "enough-data" signals, appsrc can emit the
/// "seek-data" signal when the "stream-mode" property is set to "seekable" or
/// "random-access". The signal argument will contain the new desired position in
/// the stream expressed in the unit set with the "format" property. After
/// receiving the seek-data signal, the application should push-buffers from the
/// new position.
///
/// These signals allow the application to operate the appsrc in two different
/// ways:
///
/// The push mode, in which the application repeatedly calls the push-buffer/push-sample
/// method with a new buffer/sample. Optionally, the queue size in the appsrc
/// can be controlled with the enough-data and need-data signals by respectively
/// stopping/starting the push-buffer/push-sample calls. This is a typical
/// mode of operation for the stream-type "stream" and "seekable". Use this
/// mode when implementing various network protocols or hardware devices.
///
/// The pull mode, in which the need-data signal triggers the next push-buffer call.
/// This mode is typically used in the "random-access" stream-type. Use this
/// mode for file access or other randomly accessible sources. In this mode, a
/// buffer of exactly the amount of bytes given by the need-data signal should be
/// pushed into appsrc.
///
/// In all modes, the size property on appsrc should contain the total stream
/// size in bytes. Setting this property is mandatory in the random-access mode.
/// For the stream and seekable modes, setting this property is optional but
/// recommended.
///
/// When the application has finished pushing data into appsrc, it should call
/// `gstapp.AppSrc.endOfStream` or emit the end-of-stream action signal. After
/// this call, no more buffers can be pushed into appsrc until a flushing seek
/// occurs or the state of the appsrc has gone through READY.
pub const AppSrc = extern struct {
    pub const Parent = gstbase.BaseSrc;
    pub const Implements = [_]type{gst.URIHandler};
    pub const Class = gstapp.AppSrcClass;
    f_basesrc: gstbase.BaseSrc,
    f_priv: ?*gstapp.AppSrcPrivate,
    f__gst_reserved: [4]*anyopaque,

    pub const virtual_methods = struct {
        /// Indicates to the appsrc element that the last buffer queued in the
        /// element is the last buffer of the stream.
        pub const end_of_stream = struct {
            pub fn call(p_class: anytype, p_appsrc: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) gst.FlowReturn {
                return gobject.ext.as(AppSrc.Class, p_class).f_end_of_stream.?(gobject.ext.as(AppSrc, p_appsrc));
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_appsrc: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(AppSrc.Class, p_class).f_end_of_stream = @ptrCast(p_implementation);
            }
        };

        pub const enough_data = struct {
            pub fn call(p_class: anytype, p_appsrc: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) void {
                return gobject.ext.as(AppSrc.Class, p_class).f_enough_data.?(gobject.ext.as(AppSrc, p_appsrc));
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_appsrc: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) callconv(.c) void) void {
                gobject.ext.as(AppSrc.Class, p_class).f_enough_data = @ptrCast(p_implementation);
            }
        };

        pub const need_data = struct {
            pub fn call(p_class: anytype, p_appsrc: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_length: c_uint) void {
                return gobject.ext.as(AppSrc.Class, p_class).f_need_data.?(gobject.ext.as(AppSrc, p_appsrc), p_length);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_appsrc: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_length: c_uint) callconv(.c) void) void {
                gobject.ext.as(AppSrc.Class, p_class).f_need_data = @ptrCast(p_implementation);
            }
        };

        /// Adds a buffer to the queue of buffers that the appsrc element will
        /// push to its source pad.  This function takes ownership of the buffer.
        ///
        /// When the block property is TRUE, this function can block until free
        /// space becomes available in the queue.
        pub const push_buffer = struct {
            pub fn call(p_class: anytype, p_appsrc: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buffer: *gst.Buffer) gst.FlowReturn {
                return gobject.ext.as(AppSrc.Class, p_class).f_push_buffer.?(gobject.ext.as(AppSrc, p_appsrc), p_buffer);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_appsrc: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buffer: *gst.Buffer) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(AppSrc.Class, p_class).f_push_buffer = @ptrCast(p_implementation);
            }
        };

        /// Adds a buffer list to the queue of buffers and buffer lists that the
        /// appsrc element will push to its source pad.  This function takes ownership
        /// of `buffer_list`.
        ///
        /// When the block property is TRUE, this function can block until free
        /// space becomes available in the queue.
        pub const push_buffer_list = struct {
            pub fn call(p_class: anytype, p_appsrc: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buffer_list: *gst.BufferList) gst.FlowReturn {
                return gobject.ext.as(AppSrc.Class, p_class).f_push_buffer_list.?(gobject.ext.as(AppSrc, p_appsrc), p_buffer_list);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_appsrc: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buffer_list: *gst.BufferList) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(AppSrc.Class, p_class).f_push_buffer_list = @ptrCast(p_implementation);
            }
        };

        /// Extract a buffer from the provided sample and adds it to the queue of
        /// buffers that the appsrc element will push to its source pad. Any
        /// previous caps that were set on appsrc will be replaced by the caps
        /// associated with the sample if not equal.
        ///
        /// This function does not take ownership of the
        /// sample so the sample needs to be unreffed after calling this function.
        ///
        /// When the block property is TRUE, this function can block until free
        /// space becomes available in the queue.
        pub const push_sample = struct {
            pub fn call(p_class: anytype, p_appsrc: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_sample: *gst.Sample) gst.FlowReturn {
                return gobject.ext.as(AppSrc.Class, p_class).f_push_sample.?(gobject.ext.as(AppSrc, p_appsrc), p_sample);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_appsrc: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_sample: *gst.Sample) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(AppSrc.Class, p_class).f_push_sample = @ptrCast(p_implementation);
            }
        };

        pub const seek_data = struct {
            pub fn call(p_class: anytype, p_appsrc: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_offset: u64) c_int {
                return gobject.ext.as(AppSrc.Class, p_class).f_seek_data.?(gobject.ext.as(AppSrc, p_appsrc), p_offset);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_appsrc: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_offset: u64) callconv(.c) c_int) void {
                gobject.ext.as(AppSrc.Class, p_class).f_seek_data = @ptrCast(p_implementation);
            }
        };
    };

    pub const properties = struct {
        /// When max-bytes are queued and after the enough-data signal has been emitted,
        /// block any further push-buffer calls until the amount of queued bytes drops
        /// below the max-bytes limit.
        pub const block = struct {
            pub const name = "block";

            pub const Type = c_int;
        };

        /// The GstCaps that will negotiated downstream and will be put
        /// on outgoing buffers.
        pub const caps = struct {
            pub const name = "caps";

            pub const Type = ?*gst.Caps;
        };

        /// The number of currently queued buffers inside appsrc.
        pub const current_level_buffers = struct {
            pub const name = "current-level-buffers";

            pub const Type = u64;
        };

        /// The number of currently queued bytes inside appsrc.
        pub const current_level_bytes = struct {
            pub const name = "current-level-bytes";

            pub const Type = u64;
        };

        /// The amount of currently queued time inside appsrc.
        pub const current_level_time = struct {
            pub const name = "current-level-time";

            pub const Type = u64;
        };

        /// The total duration in nanoseconds of the data stream. If the total duration is known, it
        /// is recommended to configure it with this property.
        pub const duration = struct {
            pub const name = "duration";

            pub const Type = u64;
        };

        /// Make appsrc emit the "need-data", "enough-data" and "seek-data" signals.
        /// This option is by default enabled for backwards compatibility reasons but
        /// can disabled when needed because signal emission is expensive.
        pub const emit_signals = struct {
            pub const name = "emit-signals";

            pub const Type = c_int;
        };

        /// The format to use for segment events. When the source is producing
        /// timestamped buffers this property should be set to GST_FORMAT_TIME.
        pub const format = struct {
            pub const name = "format";

            pub const Type = gst.Format;
        };

        /// When enabled, appsrc will check GstSegment in GstSample which was
        /// pushed via `gstapp.AppSrc.pushSample` or "push-sample" signal action.
        /// If a GstSegment is changed, corresponding segment event will be followed
        /// by next data flow.
        ///
        /// FIXME: currently only GST_FORMAT_TIME format is supported and therefore
        /// GstAppSrc::format should be time. However, possibly `gstapp.AppSrc` can support
        /// other formats.
        pub const handle_segment_change = struct {
            pub const name = "handle-segment-change";

            pub const Type = c_int;
        };

        /// Instruct the source to behave like a live source. This includes that it
        /// will only push out buffers in the PLAYING state.
        pub const is_live = struct {
            pub const name = "is-live";

            pub const Type = c_int;
        };

        /// When set to any other value than GST_APP_LEAKY_TYPE_NONE then the appsrc
        /// will drop any buffers that are pushed into it once its internal queue is
        /// full. The selected type defines whether to drop the oldest or new
        /// buffers.
        pub const leaky_type = struct {
            pub const name = "leaky-type";

            pub const Type = gstapp.AppLeakyType;
        };

        /// The maximum amount of buffers that can be queued internally.
        /// After the maximum amount of buffers are queued, appsrc will emit the
        /// "enough-data" signal.
        pub const max_buffers = struct {
            pub const name = "max-buffers";

            pub const Type = u64;
        };

        /// The maximum amount of bytes that can be queued internally.
        /// After the maximum amount of bytes are queued, appsrc will emit the
        /// "enough-data" signal.
        pub const max_bytes = struct {
            pub const name = "max-bytes";

            pub const Type = u64;
        };

        pub const max_latency = struct {
            pub const name = "max-latency";

            pub const Type = i64;
        };

        /// The maximum amount of time that can be queued internally.
        /// After the maximum amount of time are queued, appsrc will emit the
        /// "enough-data" signal.
        pub const max_time = struct {
            pub const name = "max-time";

            pub const Type = u64;
        };

        /// The minimum latency of the source. A value of -1 will use the default
        /// latency calculations of `gstbase.BaseSrc`.
        pub const min_latency = struct {
            pub const name = "min-latency";

            pub const Type = i64;
        };

        /// Make appsrc emit the "need-data" signal when the amount of bytes in the
        /// queue drops below this percentage of max-bytes.
        pub const min_percent = struct {
            pub const name = "min-percent";

            pub const Type = c_uint;
        };

        /// The total size in bytes of the data stream. If the total size is known, it
        /// is recommended to configure it with this property.
        pub const size = struct {
            pub const name = "size";

            pub const Type = i64;
        };

        /// The type of stream that this source is producing.  For seekable streams the
        /// application should connect to the seek-data signal.
        pub const stream_type = struct {
            pub const name = "stream-type";

            pub const Type = gstapp.AppStreamType;
        };
    };

    pub const signals = struct {
        /// Notify `appsrc` that no more buffer are available.
        pub const end_of_stream = struct {
            pub const name = "end-of-stream";

            pub fn connect(p_instance: anytype, comptime P_Data: type, p_callback: *const fn (@TypeOf(p_instance), P_Data) callconv(.c) gst.FlowReturn, p_data: P_Data, p_options: gobject.ext.ConnectSignalOptions(P_Data)) c_ulong {
                return gobject.signalConnectClosureById(
                    @ptrCast(@alignCast(gobject.ext.as(AppSrc, p_instance))),
                    gobject.signalLookup("end-of-stream", AppSrc.getGObjectType()),
                    glib.quarkFromString(p_options.detail orelse null),
                    gobject.CClosure.new(@ptrCast(p_callback), p_data, @ptrCast(p_options.destroyData)),
                    @intFromBool(p_options.after),
                );
            }
        };

        /// Signal that the source has enough data. It is recommended that the
        /// application stops calling push-buffer until the need-data signal is
        /// emitted again to avoid excessive buffer queueing.
        pub const enough_data = struct {
            pub const name = "enough-data";

            pub fn connect(p_instance: anytype, comptime P_Data: type, p_callback: *const fn (@TypeOf(p_instance), P_Data) callconv(.c) void, p_data: P_Data, p_options: gobject.ext.ConnectSignalOptions(P_Data)) c_ulong {
                return gobject.signalConnectClosureById(
                    @ptrCast(@alignCast(gobject.ext.as(AppSrc, p_instance))),
                    gobject.signalLookup("enough-data", AppSrc.getGObjectType()),
                    glib.quarkFromString(p_options.detail orelse null),
                    gobject.CClosure.new(@ptrCast(p_callback), p_data, @ptrCast(p_options.destroyData)),
                    @intFromBool(p_options.after),
                );
            }
        };

        /// Signal that the source needs more data. In the callback or from another
        /// thread you should call push-buffer or end-of-stream.
        ///
        /// `length` is just a hint and when it is set to -1, any number of bytes can be
        /// pushed into `appsrc`.
        ///
        /// You can call push-buffer multiple times until the enough-data signal is
        /// fired.
        pub const need_data = struct {
            pub const name = "need-data";

            pub fn connect(p_instance: anytype, comptime P_Data: type, p_callback: *const fn (@TypeOf(p_instance), p_length: c_uint, P_Data) callconv(.c) void, p_data: P_Data, p_options: gobject.ext.ConnectSignalOptions(P_Data)) c_ulong {
                return gobject.signalConnectClosureById(
                    @ptrCast(@alignCast(gobject.ext.as(AppSrc, p_instance))),
                    gobject.signalLookup("need-data", AppSrc.getGObjectType()),
                    glib.quarkFromString(p_options.detail orelse null),
                    gobject.CClosure.new(@ptrCast(p_callback), p_data, @ptrCast(p_options.destroyData)),
                    @intFromBool(p_options.after),
                );
            }
        };

        /// Adds a buffer to the queue of buffers that the appsrc element will
        /// push to its source pad.
        ///
        /// This function does not take ownership of the buffer, but it takes a
        /// reference so the buffer can be unreffed at any time after calling this
        /// function.
        ///
        /// When the block property is TRUE, this function can block until free space
        /// becomes available in the queue.
        pub const push_buffer = struct {
            pub const name = "push-buffer";

            pub fn connect(p_instance: anytype, comptime P_Data: type, p_callback: *const fn (@TypeOf(p_instance), p_buffer: *gst.Buffer, P_Data) callconv(.c) gst.FlowReturn, p_data: P_Data, p_options: gobject.ext.ConnectSignalOptions(P_Data)) c_ulong {
                return gobject.signalConnectClosureById(
                    @ptrCast(@alignCast(gobject.ext.as(AppSrc, p_instance))),
                    gobject.signalLookup("push-buffer", AppSrc.getGObjectType()),
                    glib.quarkFromString(p_options.detail orelse null),
                    gobject.CClosure.new(@ptrCast(p_callback), p_data, @ptrCast(p_options.destroyData)),
                    @intFromBool(p_options.after),
                );
            }
        };

        /// Adds a buffer list to the queue of buffers and buffer lists that the
        /// appsrc element will push to its source pad.
        ///
        /// This function does not take ownership of the buffer list, but it takes a
        /// reference so the buffer list can be unreffed at any time after calling
        /// this function.
        ///
        /// When the block property is TRUE, this function can block until free space
        /// becomes available in the queue.
        pub const push_buffer_list = struct {
            pub const name = "push-buffer-list";

            pub fn connect(p_instance: anytype, comptime P_Data: type, p_callback: *const fn (@TypeOf(p_instance), p_buffer_list: *gst.BufferList, P_Data) callconv(.c) gst.FlowReturn, p_data: P_Data, p_options: gobject.ext.ConnectSignalOptions(P_Data)) c_ulong {
                return gobject.signalConnectClosureById(
                    @ptrCast(@alignCast(gobject.ext.as(AppSrc, p_instance))),
                    gobject.signalLookup("push-buffer-list", AppSrc.getGObjectType()),
                    glib.quarkFromString(p_options.detail orelse null),
                    gobject.CClosure.new(@ptrCast(p_callback), p_data, @ptrCast(p_options.destroyData)),
                    @intFromBool(p_options.after),
                );
            }
        };

        /// Extract a buffer from the provided sample and adds the extracted buffer
        /// to the queue of buffers that the appsrc element will
        /// push to its source pad. This function set the appsrc caps based on the caps
        /// in the sample and reset the caps if they change.
        /// Only the caps and the buffer of the provided sample are used and not
        /// for example the segment in the sample.
        ///
        /// This function does not take ownership of the sample, but it takes a
        /// reference so the sample can be unreffed at any time after calling this
        /// function.
        ///
        /// When the block property is TRUE, this function can block until free space
        /// becomes available in the queue.
        pub const push_sample = struct {
            pub const name = "push-sample";

            pub fn connect(p_instance: anytype, comptime P_Data: type, p_callback: *const fn (@TypeOf(p_instance), p_sample: *gst.Sample, P_Data) callconv(.c) gst.FlowReturn, p_data: P_Data, p_options: gobject.ext.ConnectSignalOptions(P_Data)) c_ulong {
                return gobject.signalConnectClosureById(
                    @ptrCast(@alignCast(gobject.ext.as(AppSrc, p_instance))),
                    gobject.signalLookup("push-sample", AppSrc.getGObjectType()),
                    glib.quarkFromString(p_options.detail orelse null),
                    gobject.CClosure.new(@ptrCast(p_callback), p_data, @ptrCast(p_options.destroyData)),
                    @intFromBool(p_options.after),
                );
            }
        };

        /// Seek to the given offset. The next push-buffer should produce buffers from
        /// the new `offset`.
        /// This callback is only called for seekable stream types.
        pub const seek_data = struct {
            pub const name = "seek-data";

            pub fn connect(p_instance: anytype, comptime P_Data: type, p_callback: *const fn (@TypeOf(p_instance), p_offset: u64, P_Data) callconv(.c) c_int, p_data: P_Data, p_options: gobject.ext.ConnectSignalOptions(P_Data)) c_ulong {
                return gobject.signalConnectClosureById(
                    @ptrCast(@alignCast(gobject.ext.as(AppSrc, p_instance))),
                    gobject.signalLookup("seek-data", AppSrc.getGObjectType()),
                    glib.quarkFromString(p_options.detail orelse null),
                    gobject.CClosure.new(@ptrCast(p_callback), p_data, @ptrCast(p_options.destroyData)),
                    @intFromBool(p_options.after),
                );
            }
        };
    };

    /// Indicates to the appsrc element that the last buffer queued in the
    /// element is the last buffer of the stream.
    extern fn gst_app_src_end_of_stream(p_appsrc: *AppSrc) gst.FlowReturn;
    pub const endOfStream = gst_app_src_end_of_stream;

    /// Get the configured caps on `appsrc`.
    extern fn gst_app_src_get_caps(p_appsrc: *AppSrc) ?*gst.Caps;
    pub const getCaps = gst_app_src_get_caps;

    /// Get the number of currently queued buffers inside `appsrc`.
    extern fn gst_app_src_get_current_level_buffers(p_appsrc: *AppSrc) u64;
    pub const getCurrentLevelBuffers = gst_app_src_get_current_level_buffers;

    /// Get the number of currently queued bytes inside `appsrc`.
    extern fn gst_app_src_get_current_level_bytes(p_appsrc: *AppSrc) u64;
    pub const getCurrentLevelBytes = gst_app_src_get_current_level_bytes;

    /// Get the amount of currently queued time inside `appsrc`.
    extern fn gst_app_src_get_current_level_time(p_appsrc: *AppSrc) gst.ClockTime;
    pub const getCurrentLevelTime = gst_app_src_get_current_level_time;

    /// Get the duration of the stream in nanoseconds. A value of GST_CLOCK_TIME_NONE means that the duration is
    /// not known.
    extern fn gst_app_src_get_duration(p_appsrc: *AppSrc) gst.ClockTime;
    pub const getDuration = gst_app_src_get_duration;

    /// Check if appsrc will emit the "new-preroll" and "new-buffer" signals.
    extern fn gst_app_src_get_emit_signals(p_appsrc: *AppSrc) c_int;
    pub const getEmitSignals = gst_app_src_get_emit_signals;

    /// Retrieve the min and max latencies in `min` and `max` respectively.
    extern fn gst_app_src_get_latency(p_appsrc: *AppSrc, p_min: *u64, p_max: *u64) void;
    pub const getLatency = gst_app_src_get_latency;

    /// Returns the currently set `gstapp.AppLeakyType`. See `gstapp.AppSrc.setLeakyType`
    /// for more details.
    extern fn gst_app_src_get_leaky_type(p_appsrc: *AppSrc) gstapp.AppLeakyType;
    pub const getLeakyType = gst_app_src_get_leaky_type;

    /// Get the maximum amount of buffers that can be queued in `appsrc`.
    extern fn gst_app_src_get_max_buffers(p_appsrc: *AppSrc) u64;
    pub const getMaxBuffers = gst_app_src_get_max_buffers;

    /// Get the maximum amount of bytes that can be queued in `appsrc`.
    extern fn gst_app_src_get_max_bytes(p_appsrc: *AppSrc) u64;
    pub const getMaxBytes = gst_app_src_get_max_bytes;

    /// Get the maximum amount of time that can be queued in `appsrc`.
    extern fn gst_app_src_get_max_time(p_appsrc: *AppSrc) gst.ClockTime;
    pub const getMaxTime = gst_app_src_get_max_time;

    /// Get the size of the stream in bytes. A value of -1 means that the size is
    /// not known.
    extern fn gst_app_src_get_size(p_appsrc: *AppSrc) i64;
    pub const getSize = gst_app_src_get_size;

    /// Get the stream type. Control the stream type of `appsrc`
    /// with `gstapp.AppSrc.setStreamType`.
    extern fn gst_app_src_get_stream_type(p_appsrc: *AppSrc) gstapp.AppStreamType;
    pub const getStreamType = gst_app_src_get_stream_type;

    /// Adds a buffer to the queue of buffers that the appsrc element will
    /// push to its source pad.  This function takes ownership of the buffer.
    ///
    /// When the block property is TRUE, this function can block until free
    /// space becomes available in the queue.
    extern fn gst_app_src_push_buffer(p_appsrc: *AppSrc, p_buffer: *gst.Buffer) gst.FlowReturn;
    pub const pushBuffer = gst_app_src_push_buffer;

    /// Adds a buffer list to the queue of buffers and buffer lists that the
    /// appsrc element will push to its source pad.  This function takes ownership
    /// of `buffer_list`.
    ///
    /// When the block property is TRUE, this function can block until free
    /// space becomes available in the queue.
    extern fn gst_app_src_push_buffer_list(p_appsrc: *AppSrc, p_buffer_list: *gst.BufferList) gst.FlowReturn;
    pub const pushBufferList = gst_app_src_push_buffer_list;

    /// Extract a buffer from the provided sample and adds it to the queue of
    /// buffers that the appsrc element will push to its source pad. Any
    /// previous caps that were set on appsrc will be replaced by the caps
    /// associated with the sample if not equal.
    ///
    /// This function does not take ownership of the
    /// sample so the sample needs to be unreffed after calling this function.
    ///
    /// When the block property is TRUE, this function can block until free
    /// space becomes available in the queue.
    extern fn gst_app_src_push_sample(p_appsrc: *AppSrc, p_sample: *gst.Sample) gst.FlowReturn;
    pub const pushSample = gst_app_src_push_sample;

    /// Set callbacks which will be executed when data is needed, enough data has
    /// been collected or when a seek should be performed.
    /// This is an alternative to using the signals, it has lower overhead and is thus
    /// less expensive, but also less flexible.
    ///
    /// If callbacks are installed, no signals will be emitted for performance
    /// reasons.
    ///
    /// Before 1.16.3 it was not possible to change the callbacks in a thread-safe
    /// way.
    extern fn gst_app_src_set_callbacks(p_appsrc: *AppSrc, p_callbacks: *gstapp.AppSrcCallbacks, p_user_data: ?*anyopaque, p_notify: glib.DestroyNotify) void;
    pub const setCallbacks = gst_app_src_set_callbacks;

    /// Set the capabilities on the appsrc element.  This function takes
    /// a copy of the caps structure. After calling this method, the source will
    /// only produce caps that match `caps`. `caps` must be fixed and the caps on the
    /// buffers must match the caps or left NULL.
    extern fn gst_app_src_set_caps(p_appsrc: *AppSrc, p_caps: ?*const gst.Caps) void;
    pub const setCaps = gst_app_src_set_caps;

    /// Set the duration of the stream in nanoseconds. A value of GST_CLOCK_TIME_NONE means that the duration is
    /// not known.
    extern fn gst_app_src_set_duration(p_appsrc: *AppSrc, p_duration: gst.ClockTime) void;
    pub const setDuration = gst_app_src_set_duration;

    /// Make appsrc emit the "new-preroll" and "new-buffer" signals. This option is
    /// by default disabled because signal emission is expensive and unneeded when
    /// the application prefers to operate in pull mode.
    extern fn gst_app_src_set_emit_signals(p_appsrc: *AppSrc, p_emit: c_int) void;
    pub const setEmitSignals = gst_app_src_set_emit_signals;

    /// Configure the `min` and `max` latency in `src`. If `min` is set to -1, the
    /// default latency calculations for pseudo-live sources will be used.
    extern fn gst_app_src_set_latency(p_appsrc: *AppSrc, p_min: u64, p_max: u64) void;
    pub const setLatency = gst_app_src_set_latency;

    /// When set to any other value than GST_APP_LEAKY_TYPE_NONE then the appsrc
    /// will drop any buffers that are pushed into it once its internal queue is
    /// full. The selected type defines whether to drop the oldest or new
    /// buffers.
    extern fn gst_app_src_set_leaky_type(p_appsrc: *AppSrc, p_leaky: gstapp.AppLeakyType) void;
    pub const setLeakyType = gst_app_src_set_leaky_type;

    /// Set the maximum amount of buffers that can be queued in `appsrc`.
    /// After the maximum amount of buffers are queued, `appsrc` will emit the
    /// "enough-data" signal.
    extern fn gst_app_src_set_max_buffers(p_appsrc: *AppSrc, p_max: u64) void;
    pub const setMaxBuffers = gst_app_src_set_max_buffers;

    /// Set the maximum amount of bytes that can be queued in `appsrc`.
    /// After the maximum amount of bytes are queued, `appsrc` will emit the
    /// "enough-data" signal.
    extern fn gst_app_src_set_max_bytes(p_appsrc: *AppSrc, p_max: u64) void;
    pub const setMaxBytes = gst_app_src_set_max_bytes;

    /// Set the maximum amount of time that can be queued in `appsrc`.
    /// After the maximum amount of time are queued, `appsrc` will emit the
    /// "enough-data" signal.
    extern fn gst_app_src_set_max_time(p_appsrc: *AppSrc, p_max: gst.ClockTime) void;
    pub const setMaxTime = gst_app_src_set_max_time;

    /// Set the size of the stream in bytes. A value of -1 means that the size is
    /// not known.
    extern fn gst_app_src_set_size(p_appsrc: *AppSrc, p_size: i64) void;
    pub const setSize = gst_app_src_set_size;

    /// Set the stream type on `appsrc`. For seekable streams, the "seek" signal must
    /// be connected to.
    ///
    /// A stream_type stream
    extern fn gst_app_src_set_stream_type(p_appsrc: *AppSrc, p_type: gstapp.AppStreamType) void;
    pub const setStreamType = gst_app_src_set_stream_type;

    extern fn gst_app_src_get_type() usize;
    pub const getGObjectType = gst_app_src_get_type;

    extern fn g_object_ref(p_self: *gstapp.AppSrc) void;
    pub const ref = g_object_ref;

    extern fn g_object_unref(p_self: *gstapp.AppSrc) void;
    pub const unref = g_object_unref;

    pub fn as(p_instance: *AppSrc, comptime P_T: type) *P_T {
        return gobject.ext.as(P_T, p_instance);
    }

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// A set of callbacks that can be installed on the appsink with
/// `gstapp.AppSink.setCallbacks`.
pub const AppSinkCallbacks = extern struct {
    /// Called when the end-of-stream has been reached. This callback
    ///       is called from the streaming thread.
    f_eos: ?*const fn (p_appsink: *gstapp.AppSink, p_user_data: ?*anyopaque) callconv(.c) void,
    /// Called when a new preroll sample is available.
    ///       This callback is called from the streaming thread.
    ///       The new preroll sample can be retrieved with
    ///       `gstapp.AppSink.pullPreroll` either from this callback
    ///       or from any other thread.
    f_new_preroll: ?*const fn (p_appsink: *gstapp.AppSink, p_user_data: ?*anyopaque) callconv(.c) gst.FlowReturn,
    /// Called when a new sample is available.
    ///       This callback is called from the streaming thread.
    ///       The new sample can be retrieved with
    ///       `gstapp.AppSink.pullSample` either from this callback
    ///       or from any other thread.
    f_new_sample: ?*const fn (p_appsink: *gstapp.AppSink, p_user_data: ?*anyopaque) callconv(.c) gst.FlowReturn,
    /// Called when a new event is available.
    ///       This callback is called from the streaming thread.
    ///       The new event can be retrieved with
    ///       `gst_app_sink_pull_event` either from this callback
    ///       or from any other thread.
    ///       The callback should return `TRUE` if the event has been handled,
    ///       `FALSE` otherwise.
    ///       Since: 1.20
    f_new_event: ?*const fn (p_appsink: *gstapp.AppSink, p_user_data: ?*anyopaque) callconv(.c) c_int,
    /// Called when the propose_allocation query is available.
    ///       This callback is called from the streaming thread.
    ///       The allocation query can be retrieved with
    ///       `gst_app_sink_propose_allocation` either from this callback
    ///       or from any other thread.
    ///       Since: 1.24
    f_propose_allocation: ?*const fn (p_appsink: *gstapp.AppSink, p_query: *gst.Query, p_user_data: ?*anyopaque) callconv(.c) c_int,
    f__gst_reserved: [2]*anyopaque,

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

pub const AppSinkClass = extern struct {
    pub const Instance = gstapp.AppSink;

    f_basesink_class: gstbase.BaseSinkClass,
    f_eos: ?*const fn (p_appsink: *gstapp.AppSink) callconv(.c) void,
    f_new_preroll: ?*const fn (p_appsink: *gstapp.AppSink) callconv(.c) gst.FlowReturn,
    f_new_sample: ?*const fn (p_appsink: *gstapp.AppSink) callconv(.c) gst.FlowReturn,
    f_pull_preroll: ?*const fn (p_appsink: *gstapp.AppSink) callconv(.c) ?*gst.Sample,
    f_pull_sample: ?*const fn (p_appsink: *gstapp.AppSink) callconv(.c) ?*gst.Sample,
    f_try_pull_preroll: ?*const fn (p_appsink: *gstapp.AppSink, p_timeout: gst.ClockTime) callconv(.c) ?*gst.Sample,
    f_try_pull_sample: ?*const fn (p_appsink: *gstapp.AppSink, p_timeout: gst.ClockTime) callconv(.c) ?*gst.Sample,
    f_try_pull_object: ?*const fn (p_appsink: *gstapp.AppSink, p_timeout: gst.ClockTime) callconv(.c) ?*gst.MiniObject,
    f__gst_reserved: [1]*anyopaque,

    pub fn as(p_instance: *AppSinkClass, comptime P_T: type) *P_T {
        return gobject.ext.as(P_T, p_instance);
    }

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

pub const AppSinkPrivate = opaque {
    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// A set of callbacks that can be installed on the appsrc with
/// `gstapp.AppSrc.setCallbacks`.
pub const AppSrcCallbacks = extern struct {
    /// Called when the appsrc needs more data. A buffer or EOS should be
    ///    pushed to appsrc from this thread or another thread. `length` is just a hint
    ///    and when it is set to -1, any number of bytes can be pushed into `appsrc`.
    f_need_data: ?*const fn (p_src: *gstapp.AppSrc, p_length: c_uint, p_user_data: ?*anyopaque) callconv(.c) void,
    /// Called when appsrc has enough data. It is recommended that the
    ///    application stops calling push-buffer until the need_data callback is
    ///    emitted again to avoid excessive buffer queueing.
    f_enough_data: ?*const fn (p_src: *gstapp.AppSrc, p_user_data: ?*anyopaque) callconv(.c) void,
    /// Called when a seek should be performed to the offset.
    ///    The next push-buffer should produce buffers from the new `offset`.
    ///    This callback is only called for seekable stream types.
    f_seek_data: ?*const fn (p_src: *gstapp.AppSrc, p_offset: u64, p_user_data: ?*anyopaque) callconv(.c) c_int,
    f__gst_reserved: [4]*anyopaque,

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

pub const AppSrcClass = extern struct {
    pub const Instance = gstapp.AppSrc;

    f_basesrc_class: gstbase.BaseSrcClass,
    f_need_data: ?*const fn (p_appsrc: *gstapp.AppSrc, p_length: c_uint) callconv(.c) void,
    f_enough_data: ?*const fn (p_appsrc: *gstapp.AppSrc) callconv(.c) void,
    f_seek_data: ?*const fn (p_appsrc: *gstapp.AppSrc, p_offset: u64) callconv(.c) c_int,
    f_push_buffer: ?*const fn (p_appsrc: *gstapp.AppSrc, p_buffer: *gst.Buffer) callconv(.c) gst.FlowReturn,
    f_end_of_stream: ?*const fn (p_appsrc: *gstapp.AppSrc) callconv(.c) gst.FlowReturn,
    f_push_sample: ?*const fn (p_appsrc: *gstapp.AppSrc, p_sample: *gst.Sample) callconv(.c) gst.FlowReturn,
    f_push_buffer_list: ?*const fn (p_appsrc: *gstapp.AppSrc, p_buffer_list: *gst.BufferList) callconv(.c) gst.FlowReturn,
    f__gst_reserved: [2]*anyopaque,

    pub fn as(p_instance: *AppSrcClass, comptime P_T: type) *P_T {
        return gobject.ext.as(P_T, p_instance);
    }

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

pub const AppSrcPrivate = opaque {
    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// Buffer dropping scheme to avoid the element's internal queue to block when
/// full.
pub const AppLeakyType = enum(c_int) {
    none = 0,
    upstream = 1,
    downstream = 2,
    _,

    extern fn gst_app_leaky_type_get_type() usize;
    pub const getGObjectType = gst_app_leaky_type_get_type;

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// The stream type.
pub const AppStreamType = enum(c_int) {
    stream = 0,
    seekable = 1,
    random_access = 2,
    _,

    extern fn gst_app_stream_type_get_type() usize;
    pub const getGObjectType = gst_app_stream_type_get_type;

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

test {
    @setEvalBranchQuota(100_000);
    std.testing.refAllDecls(@This());
    std.testing.refAllDecls(ext);
}
