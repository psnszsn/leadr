pub const ext = @import("ext.zig");
const gstbase = @This();

const std = @import("std");
const compat = @import("compat");
const gst = @import("gst1");
const gobject = @import("gobject2");
const glib = @import("glib2");
const gmodule = @import("gmodule2");
/// This class is for elements that receive buffers in an undesired size.
/// While for example raw video contains one image per buffer, the same is not
/// true for a lot of other formats, especially those that come directly from
/// a file. So if you have undefined buffer sizes and require a specific size,
/// this object is for you.
///
/// An adapter is created with `gstbase.Adapter.new`. It can be freed again with
/// `gobject.Object.unref`.
///
/// The theory of operation is like this: All buffers received are put
/// into the adapter using `gstbase.Adapter.push` and the data is then read back
/// in chunks of the desired size using `gstbase.Adapter.map`/`gstbase.Adapter.unmap`
/// and/or `gstbase.Adapter.copy`. After the data has been processed, it is freed
/// using `gstbase.Adapter.unmap`.
///
/// Other methods such as `gstbase.Adapter.take` and `gstbase.Adapter.takeBuffer`
/// combine `gstbase.Adapter.map` and `gstbase.Adapter.unmap` in one method and are
/// potentially more convenient for some use cases.
///
/// For example, a sink pad's chain function that needs to pass data to a library
/// in 512-byte chunks could be implemented like this:
/// ```
/// static GstFlowReturn
/// sink_pad_chain (GstPad *pad, GstObject *parent, GstBuffer *buffer)
/// {
///   MyElement *this;
///   GstAdapter *adapter;
///   GstFlowReturn ret = GST_FLOW_OK;
///
///   this = MY_ELEMENT (parent);
///
///   adapter = this->adapter;
///
///   // put buffer into adapter
///   gst_adapter_push (adapter, buffer);
///
///   // while we can read out 512 bytes, process them
///   while (gst_adapter_available (adapter) >= 512 && ret == GST_FLOW_OK) {
///     const guint8 *data = gst_adapter_map (adapter, 512);
///     // use flowreturn as an error value
///     ret = my_library_foo (data);
///     gst_adapter_unmap (adapter);
///     gst_adapter_flush (adapter, 512);
///   }
///   return ret;
/// }
/// ```
///
/// For another example, a simple element inside GStreamer that uses `gstbase.Adapter`
/// is the libvisual element.
///
/// An element using `gstbase.Adapter` in its sink pad chain function should ensure that
/// when the FLUSH_STOP event is received, that any queued data is cleared using
/// `gstbase.Adapter.clear`. Data should also be cleared or processed on EOS and
/// when changing state from `GST_STATE_PAUSED` to `GST_STATE_READY`.
///
/// Also check the GST_BUFFER_FLAG_DISCONT flag on the buffer. Some elements might
/// need to clear the adapter after a discontinuity.
///
/// The adapter will keep track of the timestamps of the buffers
/// that were pushed. The last seen timestamp before the current position
/// can be queried with `gstbase.Adapter.prevPts`. This function can
/// optionally return the number of bytes between the start of the buffer that
/// carried the timestamp and the current adapter position. The distance is
/// useful when dealing with, for example, raw audio samples because it allows
/// you to calculate the timestamp of the current adapter position by using the
/// last seen timestamp and the amount of bytes since.  Additionally, the
/// `gstbase.Adapter.prevPtsAtOffset` can be used to determine the last
/// seen timestamp at a particular offset in the adapter.
///
/// The adapter will also keep track of the offset of the buffers
/// (`GST_BUFFER_OFFSET`) that were pushed. The last seen offset before the
/// current position can be queried with `gstbase.Adapter.prevOffset`. This function
/// can optionally return the number of bytes between the start of the buffer
/// that carried the offset and the current adapter position.
///
/// Additionally the adapter also keeps track of the PTS, DTS and buffer offset
/// at the last discontinuity, which can be retrieved with
/// `gstbase.Adapter.ptsAtDiscont`, `gstbase.Adapter.dtsAtDiscont` and
/// `gstbase.Adapter.offsetAtDiscont`. The number of bytes that were consumed
/// since then can be queried with `gstbase.Adapter.distanceFromDiscont`.
///
/// A last thing to note is that while `gstbase.Adapter` is pretty optimized,
/// merging buffers still might be an operation that requires a ``malloc`` and
/// ``memcpy`` operation, and these operations are not the fastest. Because of
/// this, some functions like `gstbase.Adapter.availableFast` are provided to help
/// speed up such cases should you want to. To avoid repeated memory allocations,
/// `gstbase.Adapter.copy` can be used to copy data into a (statically allocated)
/// user provided buffer.
///
/// `gstbase.Adapter` is not MT safe. All operations on an adapter must be serialized by
/// the caller. This is not normally a problem, however, as the normal use case
/// of `gstbase.Adapter` is inside one pad's chain function, in which case access is
/// serialized via the pad's STREAM_LOCK.
///
/// Note that `gstbase.Adapter.push` takes ownership of the buffer passed. Use
/// `gst.Buffer.ref` before pushing it into the adapter if you still want to
/// access the buffer later. The adapter will never modify the data in the
/// buffer pushed in it.
pub const Adapter = opaque {
    pub const Parent = gobject.Object;
    pub const Implements = [_]type{};
    pub const Class = gstbase.AdapterClass;
    pub const virtual_methods = struct {};

    pub const properties = struct {};

    pub const signals = struct {};

    /// Creates a new `gstbase.Adapter`. Free with `gobject.Object.unref`.
    extern fn gst_adapter_new() *gstbase.Adapter;
    pub const new = gst_adapter_new;

    /// Gets the maximum amount of bytes available, that is it returns the maximum
    /// value that can be supplied to `gstbase.Adapter.map` without that function
    /// returning `NULL`.
    ///
    /// Calling `gstbase.Adapter.map` with the amount of bytes returned by this function
    /// may require expensive operations (like copying the data into a temporary
    /// buffer) in some cases.
    extern fn gst_adapter_available(p_adapter: *Adapter) usize;
    pub const available = gst_adapter_available;

    /// Gets the maximum number of bytes that can be retrieved in a single map
    /// operation without merging buffers.
    ///
    /// Calling `gstbase.Adapter.map` with the amount of bytes returned by this function
    /// will never require any expensive operations (like copying the data into a
    /// temporary buffer).
    extern fn gst_adapter_available_fast(p_adapter: *Adapter) usize;
    pub const availableFast = gst_adapter_available_fast;

    /// Removes all buffers from `adapter`.
    extern fn gst_adapter_clear(p_adapter: *Adapter) void;
    pub const clear = gst_adapter_clear;

    /// Copies `size` bytes of data starting at `offset` out of the buffers
    /// contained in `gstbase.Adapter` into an array `dest` provided by the caller.
    ///
    /// The array `dest` should be large enough to contain `size` bytes.
    /// The user should check that the adapter has (`offset` + `size`) bytes
    /// available before calling this function.
    extern fn gst_adapter_copy(p_adapter: *Adapter, p_dest: [*]u8, p_offset: usize, p_size: usize) void;
    pub const copy = gst_adapter_copy;

    /// Similar to gst_adapter_copy, but more suitable for language bindings. `size`
    /// bytes of data starting at `offset` will be copied out of the buffers contained
    /// in `adapter` and into a new `glib.Bytes` structure which is returned. Depending on
    /// the value of the `size` argument an empty `glib.Bytes` structure may be returned.
    extern fn gst_adapter_copy_bytes(p_adapter: *Adapter, p_offset: usize, p_size: usize) *glib.Bytes;
    pub const copyBytes = gst_adapter_copy_bytes;

    /// Get the distance in bytes since the last buffer with the
    /// `GST_BUFFER_FLAG_DISCONT` flag.
    ///
    /// The distance will be reset to 0 for all buffers with
    /// `GST_BUFFER_FLAG_DISCONT` on them, and then calculated for all other
    /// following buffers based on their size.
    extern fn gst_adapter_distance_from_discont(p_adapter: *Adapter) u64;
    pub const distanceFromDiscont = gst_adapter_distance_from_discont;

    /// Get the DTS that was on the last buffer with the GST_BUFFER_FLAG_DISCONT
    /// flag, or GST_CLOCK_TIME_NONE.
    extern fn gst_adapter_dts_at_discont(p_adapter: *Adapter) gst.ClockTime;
    pub const dtsAtDiscont = gst_adapter_dts_at_discont;

    /// Flushes the first `flush` bytes in the `adapter`. The caller must ensure that
    /// at least this many bytes are available.
    ///
    /// See also: `gstbase.Adapter.map`, `gstbase.Adapter.unmap`
    extern fn gst_adapter_flush(p_adapter: *Adapter, p_flush: usize) void;
    pub const flush = gst_adapter_flush;

    /// Returns a `gst.Buffer` containing the first `nbytes` of the `adapter`, but
    /// does not flush them from the adapter. See `gstbase.Adapter.takeBuffer`
    /// for details.
    ///
    /// Caller owns a reference to the returned buffer. `gst.Buffer.unref` after
    /// usage.
    ///
    /// Free-function: gst_buffer_unref
    extern fn gst_adapter_get_buffer(p_adapter: *Adapter, p_nbytes: usize) ?*gst.Buffer;
    pub const getBuffer = gst_adapter_get_buffer;

    /// Returns a `gst.Buffer` containing the first `nbytes` of the `adapter`, but
    /// does not flush them from the adapter. See `gstbase.Adapter.takeBufferFast`
    /// for details.
    ///
    /// Caller owns a reference to the returned buffer. `gst.Buffer.unref` after
    /// usage.
    ///
    /// Free-function: gst_buffer_unref
    extern fn gst_adapter_get_buffer_fast(p_adapter: *Adapter, p_nbytes: usize) ?*gst.Buffer;
    pub const getBufferFast = gst_adapter_get_buffer_fast;

    /// Returns a `gst.BufferList` of buffers containing the first `nbytes` bytes of
    /// the `adapter` but does not flush them from the adapter. See
    /// `gstbase.Adapter.takeBufferList` for details.
    ///
    /// Caller owns the returned list. Call `gst.BufferList.unref` to free
    /// the list after usage.
    extern fn gst_adapter_get_buffer_list(p_adapter: *Adapter, p_nbytes: usize) ?*gst.BufferList;
    pub const getBufferList = gst_adapter_get_buffer_list;

    /// Returns a `glib.List` of buffers containing the first `nbytes` bytes of the
    /// `adapter`, but does not flush them from the adapter. See
    /// `gstbase.Adapter.takeList` for details.
    ///
    /// Caller owns returned list and contained buffers. `gst.Buffer.unref` each
    /// buffer in the list before freeing the list after usage.
    extern fn gst_adapter_get_list(p_adapter: *Adapter, p_nbytes: usize) ?*glib.List;
    pub const getList = gst_adapter_get_list;

    /// Gets the first `size` bytes stored in the `adapter`. The returned pointer is
    /// valid until the next function is called on the adapter.
    ///
    /// Note that setting the returned pointer as the data of a `gst.Buffer` is
    /// incorrect for general-purpose plugins. The reason is that if a downstream
    /// element stores the buffer so that it has access to it outside of the bounds
    /// of its chain function, the buffer will have an invalid data pointer after
    /// your element flushes the bytes. In that case you should use
    /// `gstbase.Adapter.take`, which returns a freshly-allocated buffer that you can set
    /// as `gst.Buffer` memory or the potentially more performant
    /// `gstbase.Adapter.takeBuffer`.
    ///
    /// Returns `NULL` if `size` bytes are not available.
    extern fn gst_adapter_map(p_adapter: *Adapter, p_size: usize) ?[*]const u8;
    pub const map = gst_adapter_map;

    /// Scan for pattern `pattern` with applied mask `mask` in the adapter data,
    /// starting from offset `offset`.
    ///
    /// The bytes in `pattern` and `mask` are interpreted left-to-right, regardless
    /// of endianness.  All four bytes of the pattern must be present in the
    /// adapter for it to match, even if the first or last bytes are masked out.
    ///
    /// It is an error to call this function without making sure that there is
    /// enough data (offset+size bytes) in the adapter.
    ///
    /// This function calls `gstbase.Adapter.maskedScanUint32Peek` passing `NULL`
    /// for value.
    extern fn gst_adapter_masked_scan_uint32(p_adapter: *Adapter, p_mask: u32, p_pattern: u32, p_offset: usize, p_size: usize) isize;
    pub const maskedScanUint32 = gst_adapter_masked_scan_uint32;

    /// Scan for pattern `pattern` with applied mask `mask` in the adapter data,
    /// starting from offset `offset`.  If a match is found, the value that matched
    /// is returned through `value`, otherwise `value` is left untouched.
    ///
    /// The bytes in `pattern` and `mask` are interpreted left-to-right, regardless
    /// of endianness.  All four bytes of the pattern must be present in the
    /// adapter for it to match, even if the first or last bytes are masked out.
    ///
    /// It is an error to call this function without making sure that there is
    /// enough data (offset+size bytes) in the adapter.
    extern fn gst_adapter_masked_scan_uint32_peek(p_adapter: *Adapter, p_mask: u32, p_pattern: u32, p_offset: usize, p_size: usize, p_value: ?*u32) isize;
    pub const maskedScanUint32Peek = gst_adapter_masked_scan_uint32_peek;

    /// Get the offset that was on the last buffer with the GST_BUFFER_FLAG_DISCONT
    /// flag, or GST_BUFFER_OFFSET_NONE.
    extern fn gst_adapter_offset_at_discont(p_adapter: *Adapter) u64;
    pub const offsetAtDiscont = gst_adapter_offset_at_discont;

    /// Get the dts that was before the current byte in the adapter. When
    /// `distance` is given, the amount of bytes between the dts and the current
    /// position is returned.
    ///
    /// The dts is reset to GST_CLOCK_TIME_NONE and the distance is set to 0 when
    /// the adapter is first created or when it is cleared. This also means that before
    /// the first byte with a dts is added to the adapter, the dts
    /// and distance returned are GST_CLOCK_TIME_NONE and 0 respectively.
    extern fn gst_adapter_prev_dts(p_adapter: *Adapter, p_distance: ?*u64) gst.ClockTime;
    pub const prevDts = gst_adapter_prev_dts;

    /// Get the dts that was before the byte at offset `offset` in the adapter. When
    /// `distance` is given, the amount of bytes between the dts and the current
    /// position is returned.
    ///
    /// The dts is reset to GST_CLOCK_TIME_NONE and the distance is set to 0 when
    /// the adapter is first created or when it is cleared. This also means that before
    /// the first byte with a dts is added to the adapter, the dts
    /// and distance returned are GST_CLOCK_TIME_NONE and 0 respectively.
    extern fn gst_adapter_prev_dts_at_offset(p_adapter: *Adapter, p_offset: usize, p_distance: ?*u64) gst.ClockTime;
    pub const prevDtsAtOffset = gst_adapter_prev_dts_at_offset;

    /// Get the offset that was before the current byte in the adapter. When
    /// `distance` is given, the amount of bytes between the offset and the current
    /// position is returned.
    ///
    /// The offset is reset to GST_BUFFER_OFFSET_NONE and the distance is set to 0
    /// when the adapter is first created or when it is cleared. This also means that
    /// before the first byte with an offset is added to the adapter, the offset
    /// and distance returned are GST_BUFFER_OFFSET_NONE and 0 respectively.
    extern fn gst_adapter_prev_offset(p_adapter: *Adapter, p_distance: ?*u64) u64;
    pub const prevOffset = gst_adapter_prev_offset;

    /// Get the pts that was before the current byte in the adapter. When
    /// `distance` is given, the amount of bytes between the pts and the current
    /// position is returned.
    ///
    /// The pts is reset to GST_CLOCK_TIME_NONE and the distance is set to 0 when
    /// the adapter is first created or when it is cleared. This also means that before
    /// the first byte with a pts is added to the adapter, the pts
    /// and distance returned are GST_CLOCK_TIME_NONE and 0 respectively.
    extern fn gst_adapter_prev_pts(p_adapter: *Adapter, p_distance: ?*u64) gst.ClockTime;
    pub const prevPts = gst_adapter_prev_pts;

    /// Get the pts that was before the byte at offset `offset` in the adapter. When
    /// `distance` is given, the amount of bytes between the pts and the current
    /// position is returned.
    ///
    /// The pts is reset to GST_CLOCK_TIME_NONE and the distance is set to 0 when
    /// the adapter is first created or when it is cleared. This also means that before
    /// the first byte with a pts is added to the adapter, the pts
    /// and distance returned are GST_CLOCK_TIME_NONE and 0 respectively.
    extern fn gst_adapter_prev_pts_at_offset(p_adapter: *Adapter, p_offset: usize, p_distance: ?*u64) gst.ClockTime;
    pub const prevPtsAtOffset = gst_adapter_prev_pts_at_offset;

    /// Get the PTS that was on the last buffer with the GST_BUFFER_FLAG_DISCONT
    /// flag, or GST_CLOCK_TIME_NONE.
    extern fn gst_adapter_pts_at_discont(p_adapter: *Adapter) gst.ClockTime;
    pub const ptsAtDiscont = gst_adapter_pts_at_discont;

    /// Adds the data from `buf` to the data stored inside `adapter` and takes
    /// ownership of the buffer.
    extern fn gst_adapter_push(p_adapter: *Adapter, p_buf: *gst.Buffer) void;
    pub const push = gst_adapter_push;

    /// Returns a freshly allocated buffer containing the first `nbytes` bytes of the
    /// `adapter`. The returned bytes will be flushed from the adapter.
    ///
    /// Caller owns returned value. g_free after usage.
    ///
    /// Free-function: g_free
    extern fn gst_adapter_take(p_adapter: *Adapter, p_nbytes: usize) ?[*]u8;
    pub const take = gst_adapter_take;

    /// Returns a `gst.Buffer` containing the first `nbytes` bytes of the
    /// `adapter`. The returned bytes will be flushed from the adapter.
    /// This function is potentially more performant than
    /// `gstbase.Adapter.take` since it can reuse the memory in pushed buffers
    /// by subbuffering or merging. This function will always return a
    /// buffer with a single memory region.
    ///
    /// Note that no assumptions should be made as to whether certain buffer
    /// flags such as the DISCONT flag are set on the returned buffer, or not.
    /// The caller needs to explicitly set or unset flags that should be set or
    /// unset.
    ///
    /// Since 1.6 this will also copy over all GstMeta of the input buffers except
    /// for meta with the `GST_META_FLAG_POOLED` flag or with the "memory" tag.
    ///
    /// Caller owns a reference to the returned buffer. `gst.Buffer.unref` after
    /// usage.
    ///
    /// Free-function: gst_buffer_unref
    extern fn gst_adapter_take_buffer(p_adapter: *Adapter, p_nbytes: usize) ?*gst.Buffer;
    pub const takeBuffer = gst_adapter_take_buffer;

    /// Returns a `gst.Buffer` containing the first `nbytes` of the `adapter`.
    /// The returned bytes will be flushed from the adapter.  This function
    /// is potentially more performant than `gstbase.Adapter.takeBuffer` since
    /// it can reuse the memory in pushed buffers by subbuffering or
    /// merging. Unlike `gstbase.Adapter.takeBuffer`, the returned buffer may
    /// be composed of multiple non-contiguous `gst.Memory` objects, no
    /// copies are made.
    ///
    /// Note that no assumptions should be made as to whether certain buffer
    /// flags such as the DISCONT flag are set on the returned buffer, or not.
    /// The caller needs to explicitly set or unset flags that should be set or
    /// unset.
    ///
    /// This will also copy over all GstMeta of the input buffers except
    /// for meta with the `GST_META_FLAG_POOLED` flag or with the "memory" tag.
    ///
    /// This function can return buffer up to the return value of
    /// `gstbase.Adapter.available` without making copies if possible.
    ///
    /// Caller owns a reference to the returned buffer. `gst.Buffer.unref` after
    /// usage.
    ///
    /// Free-function: gst_buffer_unref
    extern fn gst_adapter_take_buffer_fast(p_adapter: *Adapter, p_nbytes: usize) ?*gst.Buffer;
    pub const takeBufferFast = gst_adapter_take_buffer_fast;

    /// Returns a `gst.BufferList` of buffers containing the first `nbytes` bytes of
    /// the `adapter`. The returned bytes will be flushed from the adapter.
    /// When the caller can deal with individual buffers, this function is more
    /// performant because no memory should be copied.
    ///
    /// Caller owns the returned list. Call `gst.BufferList.unref` to free
    /// the list after usage.
    extern fn gst_adapter_take_buffer_list(p_adapter: *Adapter, p_nbytes: usize) ?*gst.BufferList;
    pub const takeBufferList = gst_adapter_take_buffer_list;

    /// Returns a `glib.List` of buffers containing the first `nbytes` bytes of the
    /// `adapter`. The returned bytes will be flushed from the adapter.
    /// When the caller can deal with individual buffers, this function is more
    /// performant because no memory should be copied.
    ///
    /// Caller owns returned list and contained buffers. `gst.Buffer.unref` each
    /// buffer in the list before freeing the list after usage.
    extern fn gst_adapter_take_list(p_adapter: *Adapter, p_nbytes: usize) ?*glib.List;
    pub const takeList = gst_adapter_take_list;

    /// Releases the memory obtained with the last `gstbase.Adapter.map`.
    extern fn gst_adapter_unmap(p_adapter: *Adapter) void;
    pub const unmap = gst_adapter_unmap;

    extern fn gst_adapter_get_type() usize;
    pub const getGObjectType = gst_adapter_get_type;

    extern fn g_object_ref(p_self: *gstbase.Adapter) void;
    pub const ref = g_object_ref;

    extern fn g_object_unref(p_self: *gstbase.Adapter) void;
    pub const unref = g_object_unref;

    pub fn as(p_instance: *Adapter, comptime P_T: type) *P_T {
        return gobject.ext.as(P_T, p_instance);
    }

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// Manages a set of pads with the purpose of aggregating their buffers.
/// Control is given to the subclass when all pads have data.
///
///  * Base class for mixers and muxers. Subclasses should at least implement
///    the `gstbase.AggregatorClass.signals.aggregate` virtual method.
///
///  * Installs a `gst.PadChainFunction`, a `gst.PadEventFullFunction` and a
///    `gst.PadQueryFunction` to queue all serialized data packets per sink pad.
///    Subclasses should not overwrite those, but instead implement
///    `gstbase.AggregatorClass.signals.sink_event` and `gstbase.AggregatorClass.signals.sink_query` as
///    needed.
///
///  * When data is queued on all pads, the aggregate vmethod is called.
///
///  * One can peek at the data on any given GstAggregatorPad with the
///    `gstbase.AggregatorPad.peekBuffer` method, and remove it from the pad
///    with the gst_aggregator_pad_pop_buffer () method. When a buffer
///    has been taken with pop_buffer (), a new buffer can be queued
///    on that pad.
///
///  * When `gstbase.AggregatorPad.peekBuffer` or `gstbase.AggregatorPad.hasBuffer`
///    are called, a reference is taken to the returned buffer, which stays
///    valid until either:
///
///      - `gstbase.AggregatorPad.popBuffer` is called, in which case the caller
///        is guaranteed that the buffer they receive is the same as the peeked
///        buffer.
///      - `gstbase.AggregatorPad.dropBuffer` is called, in which case the caller
///        is guaranteed that the dropped buffer is the one that was peeked.
///      - the subclass implementation of `gstbase.AggregatorClass.aggregate` returns.
///
///    Subsequent calls to `gstbase.AggregatorPad.peekBuffer` or
///    `gstbase.AggregatorPad.hasBuffer` return / check the same buffer that was
///    returned / checked, until one of the conditions listed above is met.
///
///    Subclasses are only allowed to call these methods from the aggregate
///    thread.
///
///  * If the subclass wishes to push a buffer downstream in its aggregate
///    implementation, it should do so through the
///    `gstbase.Aggregator.finishBuffer` method. This method will take care
///    of sending and ordering mandatory events such as stream start, caps
///    and segment. Buffer lists can also be pushed out with
///    `gstbase.Aggregator.finishBufferList`.
///
///  * Same goes for EOS events, which should not be pushed directly by the
///    subclass, it should instead return GST_FLOW_EOS in its aggregate
///    implementation.
///
///  * Note that the aggregator logic regarding gap event handling is to turn
///    these into gap buffers with matching PTS and duration. It will also
///    flag these buffers with GST_BUFFER_FLAG_GAP and GST_BUFFER_FLAG_DROPPABLE
///    to ease their identification and subsequent processing.
///    In addition, if the gap event was flagged with GST_GAP_FLAG_MISSING_DATA,
///    a custom meta is added to the resulting gap buffer (GstAggregatorMissingDataMeta).
///
///  * Subclasses must use (a subclass of) `gstbase.AggregatorPad` for both their
///    sink and source pads.
///    See `gst.ElementClass.addStaticPadTemplateWithGtype`.
///
/// This class used to live in gst-plugins-bad and was moved to core.
pub const Aggregator = extern struct {
    pub const Parent = gst.Element;
    pub const Implements = [_]type{};
    pub const Class = gstbase.AggregatorClass;
    f_parent: gst.Element,
    /// the aggregator's source pad
    f_srcpad: ?*gst.Pad,
    f_priv: ?*gstbase.AggregatorPrivate,
    f__gst_reserved: [20]*anyopaque,

    pub const virtual_methods = struct {
        /// Mandatory.
        ///                  Called when buffers are queued on all sinkpads. Classes
        ///                  should iterate the GstElement->sinkpads and peek or steal
        ///                  buffers from the `GstAggregatorPads`. If the subclass returns
        ///                  GST_FLOW_EOS, sending of the eos event will be taken care
        ///                  of. Once / if a buffer has been constructed from the
        ///                  aggregated buffers, the subclass should call _finish_buffer.
        pub const aggregate = struct {
            pub fn call(p_class: anytype, p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_timeout: c_int) gst.FlowReturn {
                return gobject.ext.as(Aggregator.Class, p_class).f_aggregate.?(gobject.ext.as(Aggregator, p_aggregator), p_timeout);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_timeout: c_int) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(Aggregator.Class, p_class).f_aggregate = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                  Called when a buffer is received on a sink pad, the task of
        ///                  clipping it and translating it to the current segment falls
        ///                  on the subclass. The function should use the segment of data
        ///                  and the negotiated media type on the pad to perform
        ///                  clipping of input buffer. This function takes ownership of
        ///                  buf and should output a buffer or return NULL in
        ///                  if the buffer should be dropped.
        pub const clip = struct {
            pub fn call(p_class: anytype, p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_aggregator_pad: *gstbase.AggregatorPad, p_buf: *gst.Buffer) *gst.Buffer {
                return gobject.ext.as(Aggregator.Class, p_class).f_clip.?(gobject.ext.as(Aggregator, p_aggregator), p_aggregator_pad, p_buf);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_aggregator_pad: *gstbase.AggregatorPad, p_buf: *gst.Buffer) callconv(.c) *gst.Buffer) void {
                gobject.ext.as(Aggregator.Class, p_class).f_clip = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                  Called when a new pad needs to be created. Allows subclass that
        ///                  don't have a single sink pad template to provide a pad based
        ///                  on the provided information.
        pub const create_new_pad = struct {
            pub fn call(p_class: anytype, p_self: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_templ: *gst.PadTemplate, p_req_name: [*:0]const u8, p_caps: *const gst.Caps) *gstbase.AggregatorPad {
                return gobject.ext.as(Aggregator.Class, p_class).f_create_new_pad.?(gobject.ext.as(Aggregator, p_self), p_templ, p_req_name, p_caps);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_self: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_templ: *gst.PadTemplate, p_req_name: [*:0]const u8, p_caps: *const gst.Caps) callconv(.c) *gstbase.AggregatorPad) void {
                gobject.ext.as(Aggregator.Class, p_class).f_create_new_pad = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                     Allows the subclass to influence the allocation choices.
        ///                     Setup the allocation parameters for allocating output
        ///                     buffers. The passed in query contains the result of the
        ///                     downstream allocation query.
        pub const decide_allocation = struct {
            pub fn call(p_class: anytype, p_self: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_query: *gst.Query) c_int {
                return gobject.ext.as(Aggregator.Class, p_class).f_decide_allocation.?(gobject.ext.as(Aggregator, p_self), p_query);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_self: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_query: *gst.Query) callconv(.c) c_int) void {
                gobject.ext.as(Aggregator.Class, p_class).f_decide_allocation = @ptrCast(p_implementation);
            }
        };

        /// This method will push the provided output buffer downstream. If needed,
        /// mandatory events such as stream-start, caps, and segment events will be
        /// sent before pushing the buffer.
        pub const finish_buffer = struct {
            pub fn call(p_class: anytype, p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buffer: *gst.Buffer) gst.FlowReturn {
                return gobject.ext.as(Aggregator.Class, p_class).f_finish_buffer.?(gobject.ext.as(Aggregator, p_aggregator), p_buffer);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buffer: *gst.Buffer) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(Aggregator.Class, p_class).f_finish_buffer = @ptrCast(p_implementation);
            }
        };

        /// This method will push the provided output buffer list downstream. If needed,
        /// mandatory events such as stream-start, caps, and segment events will be
        /// sent before pushing the buffer.
        pub const finish_buffer_list = struct {
            pub fn call(p_class: anytype, p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_bufferlist: *gst.BufferList) gst.FlowReturn {
                return gobject.ext.as(Aggregator.Class, p_class).f_finish_buffer_list.?(gobject.ext.as(Aggregator, p_aggregator), p_bufferlist);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_bufferlist: *gst.BufferList) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(Aggregator.Class, p_class).f_finish_buffer_list = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                   Fixate and return the src pad caps provided.  The function takes
        ///                   ownership of `caps` and returns a fixated version of
        ///                   `caps`. `caps` is not guaranteed to be writable.
        pub const fixate_src_caps = struct {
            pub fn call(p_class: anytype, p_self: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_caps: *gst.Caps) *gst.Caps {
                return gobject.ext.as(Aggregator.Class, p_class).f_fixate_src_caps.?(gobject.ext.as(Aggregator, p_self), p_caps);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_self: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_caps: *gst.Caps) callconv(.c) *gst.Caps) void {
                gobject.ext.as(Aggregator.Class, p_class).f_fixate_src_caps = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                  Called after a successful flushing seek, once all the flush
        ///                  stops have been received. Flush pad-specific data in
        ///                  `gstbase.AggregatorPad`->flush.
        pub const flush = struct {
            pub fn call(p_class: anytype, p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) gst.FlowReturn {
                return gobject.ext.as(Aggregator.Class, p_class).f_flush.?(gobject.ext.as(Aggregator, p_aggregator));
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(Aggregator.Class, p_class).f_flush = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                  Called when the element needs to know the running time of the next
        ///                  rendered buffer for live pipelines. This causes deadline
        ///                  based aggregation to occur. Defaults to returning
        ///                  GST_CLOCK_TIME_NONE causing the element to wait for buffers
        ///                  on all sink pads before aggregating.
        pub const get_next_time = struct {
            pub fn call(p_class: anytype, p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) gst.ClockTime {
                return gobject.ext.as(Aggregator.Class, p_class).f_get_next_time.?(gobject.ext.as(Aggregator, p_aggregator));
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) callconv(.c) gst.ClockTime) void {
                gobject.ext.as(Aggregator.Class, p_class).f_get_next_time = @ptrCast(p_implementation);
            }
        };

        /// Negotiates src pad caps with downstream elements.
        /// Unmarks GST_PAD_FLAG_NEED_RECONFIGURE in any case. But marks it again
        /// if `gstbase.AggregatorClass.signals.negotiate` fails.
        pub const negotiate = struct {
            pub fn call(p_class: anytype, p_self: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) c_int {
                return gobject.ext.as(Aggregator.Class, p_class).f_negotiate.?(gobject.ext.as(Aggregator, p_self));
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_self: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) callconv(.c) c_int) void {
                gobject.ext.as(Aggregator.Class, p_class).f_negotiate = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                       Notifies subclasses what caps format has been negotiated
        pub const negotiated_src_caps = struct {
            pub fn call(p_class: anytype, p_self: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_caps: *gst.Caps) c_int {
                return gobject.ext.as(Aggregator.Class, p_class).f_negotiated_src_caps.?(gobject.ext.as(Aggregator, p_self), p_caps);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_self: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_caps: *gst.Caps) callconv(.c) c_int) void {
                gobject.ext.as(Aggregator.Class, p_class).f_negotiated_src_caps = @ptrCast(p_implementation);
            }
        };

        /// Use this function to determine what input buffers will be aggregated
        /// to produce the next output buffer. This should only be called from
        /// a `gstbase.Aggregator.signals.samples`-selected handler, and can be used to precisely
        /// control aggregating parameters for a given set of input samples.
        pub const peek_next_sample = struct {
            pub fn call(p_class: anytype, p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_aggregator_pad: *gstbase.AggregatorPad) ?*gst.Sample {
                return gobject.ext.as(Aggregator.Class, p_class).f_peek_next_sample.?(gobject.ext.as(Aggregator, p_aggregator), p_aggregator_pad);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_aggregator_pad: *gstbase.AggregatorPad) callconv(.c) ?*gst.Sample) void {
                gobject.ext.as(Aggregator.Class, p_class).f_peek_next_sample = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                     Allows the subclass to handle the allocation query from upstream.
        pub const propose_allocation = struct {
            pub fn call(p_class: anytype, p_self: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_pad: *gstbase.AggregatorPad, p_decide_query: *gst.Query, p_query: *gst.Query) c_int {
                return gobject.ext.as(Aggregator.Class, p_class).f_propose_allocation.?(gobject.ext.as(Aggregator, p_self), p_pad, p_decide_query, p_query);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_self: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_pad: *gstbase.AggregatorPad, p_decide_query: *gst.Query, p_query: *gst.Query) callconv(.c) c_int) void {
                gobject.ext.as(Aggregator.Class, p_class).f_propose_allocation = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                  Called when an event is received on a sink pad, the subclass
        ///                  should always chain up.
        pub const sink_event = struct {
            pub fn call(p_class: anytype, p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_aggregator_pad: *gstbase.AggregatorPad, p_event: *gst.Event) c_int {
                return gobject.ext.as(Aggregator.Class, p_class).f_sink_event.?(gobject.ext.as(Aggregator, p_aggregator), p_aggregator_pad, p_event);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_aggregator_pad: *gstbase.AggregatorPad, p_event: *gst.Event) callconv(.c) c_int) void {
                gobject.ext.as(Aggregator.Class, p_class).f_sink_event = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                        Called when an event is received on a sink pad before queueing up
        ///                        serialized events. The subclass should always chain up (Since: 1.18).
        pub const sink_event_pre_queue = struct {
            pub fn call(p_class: anytype, p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_aggregator_pad: *gstbase.AggregatorPad, p_event: *gst.Event) gst.FlowReturn {
                return gobject.ext.as(Aggregator.Class, p_class).f_sink_event_pre_queue.?(gobject.ext.as(Aggregator, p_aggregator), p_aggregator_pad, p_event);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_aggregator_pad: *gstbase.AggregatorPad, p_event: *gst.Event) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(Aggregator.Class, p_class).f_sink_event_pre_queue = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                  Called when a query is received on a sink pad, the subclass
        ///                  should always chain up.
        pub const sink_query = struct {
            pub fn call(p_class: anytype, p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_aggregator_pad: *gstbase.AggregatorPad, p_query: *gst.Query) c_int {
                return gobject.ext.as(Aggregator.Class, p_class).f_sink_query.?(gobject.ext.as(Aggregator, p_aggregator), p_aggregator_pad, p_query);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_aggregator_pad: *gstbase.AggregatorPad, p_query: *gst.Query) callconv(.c) c_int) void {
                gobject.ext.as(Aggregator.Class, p_class).f_sink_query = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                        Called when a query is received on a sink pad before queueing up
        ///                        serialized queries. The subclass should always chain up (Since: 1.18).
        pub const sink_query_pre_queue = struct {
            pub fn call(p_class: anytype, p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_aggregator_pad: *gstbase.AggregatorPad, p_query: *gst.Query) c_int {
                return gobject.ext.as(Aggregator.Class, p_class).f_sink_query_pre_queue.?(gobject.ext.as(Aggregator, p_aggregator), p_aggregator_pad, p_query);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_aggregator_pad: *gstbase.AggregatorPad, p_query: *gst.Query) callconv(.c) c_int) void {
                gobject.ext.as(Aggregator.Class, p_class).f_sink_query_pre_queue = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                  Called when the src pad is activated, it will start/stop its
        ///                  pad task right after that call.
        pub const src_activate = struct {
            pub fn call(p_class: anytype, p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_mode: gst.PadMode, p_active: c_int) c_int {
                return gobject.ext.as(Aggregator.Class, p_class).f_src_activate.?(gobject.ext.as(Aggregator, p_aggregator), p_mode, p_active);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_mode: gst.PadMode, p_active: c_int) callconv(.c) c_int) void {
                gobject.ext.as(Aggregator.Class, p_class).f_src_activate = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                  Called when an event is received on the src pad, the subclass
        ///                  should always chain up.
        pub const src_event = struct {
            pub fn call(p_class: anytype, p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_event: *gst.Event) c_int {
                return gobject.ext.as(Aggregator.Class, p_class).f_src_event.?(gobject.ext.as(Aggregator, p_aggregator), p_event);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_event: *gst.Event) callconv(.c) c_int) void {
                gobject.ext.as(Aggregator.Class, p_class).f_src_event = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                  Called when a query is received on the src pad, the subclass
        ///                  should always chain up.
        pub const src_query = struct {
            pub fn call(p_class: anytype, p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_query: *gst.Query) c_int {
                return gobject.ext.as(Aggregator.Class, p_class).f_src_query.?(gobject.ext.as(Aggregator, p_aggregator), p_query);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_query: *gst.Query) callconv(.c) c_int) void {
                gobject.ext.as(Aggregator.Class, p_class).f_src_query = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                  Called when the element goes from READY to PAUSED.
        ///                  The subclass should get ready to process
        ///                  aggregated buffers.
        pub const start = struct {
            pub fn call(p_class: anytype, p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) c_int {
                return gobject.ext.as(Aggregator.Class, p_class).f_start.?(gobject.ext.as(Aggregator, p_aggregator));
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) callconv(.c) c_int) void {
                gobject.ext.as(Aggregator.Class, p_class).f_start = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                  Called when the element goes from PAUSED to READY.
        ///                  The subclass should free all resources and reset its state.
        pub const stop = struct {
            pub fn call(p_class: anytype, p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) c_int {
                return gobject.ext.as(Aggregator.Class, p_class).f_stop.?(gobject.ext.as(Aggregator, p_aggregator));
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_aggregator: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) callconv(.c) c_int) void {
                gobject.ext.as(Aggregator.Class, p_class).f_stop = @ptrCast(p_implementation);
            }
        };

        pub const update_src_caps = struct {
            pub fn call(p_class: anytype, p_self: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_caps: *gst.Caps, p_ret: ?**gst.Caps) gst.FlowReturn {
                return gobject.ext.as(Aggregator.Class, p_class).f_update_src_caps.?(gobject.ext.as(Aggregator, p_self), p_caps, p_ret);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_self: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_caps: *gst.Caps, p_ret: ?**gst.Caps) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(Aggregator.Class, p_class).f_update_src_caps = @ptrCast(p_implementation);
            }
        };
    };

    pub const properties = struct {
        /// Enables the emission of signals such as `gstbase.Aggregator.signals.samples`-selected
        pub const emit_signals = struct {
            pub const name = "emit-signals";

            pub const Type = c_int;
        };

        pub const latency = struct {
            pub const name = "latency";

            pub const Type = u64;
        };

        /// Force minimum upstream latency (in nanoseconds). When sources with a
        /// higher latency are expected to be plugged in dynamically after the
        /// aggregator has started playing, this allows overriding the minimum
        /// latency reported by the initial source(s). This is only taken into
        /// account when larger than the actually reported minimum latency.
        pub const min_upstream_latency = struct {
            pub const name = "min-upstream-latency";

            pub const Type = u64;
        };

        pub const start_time = struct {
            pub const name = "start-time";

            pub const Type = u64;
        };

        pub const start_time_selection = struct {
            pub const name = "start-time-selection";

            pub const Type = gstbase.AggregatorStartTimeSelection;
        };
    };

    pub const signals = struct {
        /// Signals that the `gstbase.Aggregator` subclass has selected the next set
        /// of input samples it will aggregate. Handlers may call
        /// `gstbase.Aggregator.peekNextSample` at that point.
        pub const samples_selected = struct {
            pub const name = "samples-selected";

            pub fn connect(p_instance: anytype, comptime P_Data: type, p_callback: *const fn (@TypeOf(p_instance), p_segment: *gst.Segment, p_pts: u64, p_dts: u64, p_duration: u64, p_info: ?*gst.Structure, P_Data) callconv(.c) void, p_data: P_Data, p_options: gobject.ext.ConnectSignalOptions(P_Data)) c_ulong {
                return gobject.signalConnectClosureById(
                    @ptrCast(@alignCast(gobject.ext.as(Aggregator, p_instance))),
                    gobject.signalLookup("samples-selected", Aggregator.getGObjectType()),
                    glib.quarkFromString(p_options.detail orelse null),
                    gobject.CClosure.new(@ptrCast(p_callback), p_data, @ptrCast(p_options.destroyData)),
                    @intFromBool(p_options.after),
                );
            }
        };
    };

    /// This method will push the provided output buffer downstream. If needed,
    /// mandatory events such as stream-start, caps, and segment events will be
    /// sent before pushing the buffer.
    extern fn gst_aggregator_finish_buffer(p_aggregator: *Aggregator, p_buffer: *gst.Buffer) gst.FlowReturn;
    pub const finishBuffer = gst_aggregator_finish_buffer;

    /// This method will push the provided output buffer list downstream. If needed,
    /// mandatory events such as stream-start, caps, and segment events will be
    /// sent before pushing the buffer.
    extern fn gst_aggregator_finish_buffer_list(p_aggregator: *Aggregator, p_bufferlist: *gst.BufferList) gst.FlowReturn;
    pub const finishBufferList = gst_aggregator_finish_buffer_list;

    /// Lets `gstbase.Aggregator` sub-classes get the memory `allocator`
    /// acquired by the base class and its `params`.
    ///
    /// Unref the `allocator` after use it.
    extern fn gst_aggregator_get_allocator(p_self: *Aggregator, p_allocator: ?**gst.Allocator, p_params: ?*gst.AllocationParams) void;
    pub const getAllocator = gst_aggregator_get_allocator;

    extern fn gst_aggregator_get_buffer_pool(p_self: *Aggregator) ?*gst.BufferPool;
    pub const getBufferPool = gst_aggregator_get_buffer_pool;

    /// Subclasses may use the return value to inform whether they should return
    /// `GST_FLOW_EOS` from their aggregate implementation.
    extern fn gst_aggregator_get_force_live(p_self: *Aggregator) c_int;
    pub const getForceLive = gst_aggregator_get_force_live;

    extern fn gst_aggregator_get_ignore_inactive_pads(p_self: *Aggregator) c_int;
    pub const getIgnoreInactivePads = gst_aggregator_get_ignore_inactive_pads;

    /// Retrieves the latency values reported by `self` in response to the latency
    /// query, or `GST_CLOCK_TIME_NONE` if there is not live source connected and the element
    /// will not wait for the clock.
    ///
    /// Typically only called by subclasses.
    extern fn gst_aggregator_get_latency(p_self: *Aggregator) gst.ClockTime;
    pub const getLatency = gst_aggregator_get_latency;

    /// Negotiates src pad caps with downstream elements.
    /// Unmarks GST_PAD_FLAG_NEED_RECONFIGURE in any case. But marks it again
    /// if `gstbase.AggregatorClass.signals.negotiate` fails.
    extern fn gst_aggregator_negotiate(p_self: *Aggregator) c_int;
    pub const negotiate = gst_aggregator_negotiate;

    /// Use this function to determine what input buffers will be aggregated
    /// to produce the next output buffer. This should only be called from
    /// a `gstbase.Aggregator.signals.samples`-selected handler, and can be used to precisely
    /// control aggregating parameters for a given set of input samples.
    extern fn gst_aggregator_peek_next_sample(p_self: *Aggregator, p_pad: *gstbase.AggregatorPad) ?*gst.Sample;
    pub const peekNextSample = gst_aggregator_peek_next_sample;

    /// This method will push the provided event downstream. If needed, mandatory
    /// events such as stream-start, caps, and segment events will be sent before
    /// pushing the event.
    ///
    /// This API does not allow pushing stream-start, caps, segment and EOS events.
    /// Specific API like `gstbase.Aggregator.setSrcCaps` should be used for these.
    extern fn gst_aggregator_push_src_event(p_aggregator: *Aggregator, p_event: *gst.Event) c_int;
    pub const pushSrcEvent = gst_aggregator_push_src_event;

    /// Subclasses should call this when they have prepared the
    /// buffers they will aggregate for each of their sink pads, but
    /// before using any of the properties of the pads that govern
    /// *how* aggregation should be performed, for example z-index
    /// for video aggregators.
    ///
    /// If `gstbase.Aggregator.updateSegment` is used by the subclass,
    /// it MUST be called before `gstbase.Aggregator.selectedSamples`.
    ///
    /// This function MUST only be called from the `gstbase.AggregatorClass.signals.aggregate``aggregate`
    /// function.
    extern fn gst_aggregator_selected_samples(p_self: *Aggregator, p_pts: gst.ClockTime, p_dts: gst.ClockTime, p_duration: gst.ClockTime, p_info: ?*gst.Structure) void;
    pub const selectedSamples = gst_aggregator_selected_samples;

    /// Subclasses should call this at construction time in order for `self` to
    /// aggregate on a timeout even when no live source is connected.
    extern fn gst_aggregator_set_force_live(p_self: *Aggregator, p_force_live: c_int) void;
    pub const setForceLive = gst_aggregator_set_force_live;

    /// Subclasses should call this when they don't want to time out
    /// waiting for a pad that hasn't yet received any buffers in live
    /// mode.
    ///
    /// `gstbase.Aggregator` will still wait once on each newly-added pad, making
    /// sure upstream has had a fair chance to start up.
    extern fn gst_aggregator_set_ignore_inactive_pads(p_self: *Aggregator, p_ignore: c_int) void;
    pub const setIgnoreInactivePads = gst_aggregator_set_ignore_inactive_pads;

    /// Lets `gstbase.Aggregator` sub-classes tell the baseclass what their internal
    /// latency is. Will also post a LATENCY message on the bus so the pipeline
    /// can reconfigure its global latency if the values changed.
    extern fn gst_aggregator_set_latency(p_self: *Aggregator, p_min_latency: gst.ClockTime, p_max_latency: gst.ClockTime) void;
    pub const setLatency = gst_aggregator_set_latency;

    /// Sets the caps to be used on the src pad.
    extern fn gst_aggregator_set_src_caps(p_self: *Aggregator, p_caps: *gst.Caps) void;
    pub const setSrcCaps = gst_aggregator_set_src_caps;

    /// This is a simple `gstbase.AggregatorClass.signals.get_next_time` implementation that
    /// just looks at the `gst.Segment` on the srcpad of the aggregator and bases
    /// the next time on the running time there.
    ///
    /// This is the desired behaviour in most cases where you have a live source
    /// and you have a dead line based aggregator subclass.
    extern fn gst_aggregator_simple_get_next_time(p_self: *Aggregator) gst.ClockTime;
    pub const simpleGetNextTime = gst_aggregator_simple_get_next_time;

    /// Subclasses should use this to update the segment on their
    /// source pad, instead of directly pushing new segment events
    /// downstream.
    ///
    /// Subclasses MUST call this before `gstbase.Aggregator.selectedSamples`,
    /// if it is used at all.
    extern fn gst_aggregator_update_segment(p_self: *Aggregator, p_segment: *const gst.Segment) void;
    pub const updateSegment = gst_aggregator_update_segment;

    extern fn gst_aggregator_get_type() usize;
    pub const getGObjectType = gst_aggregator_get_type;

    extern fn g_object_ref(p_self: *gstbase.Aggregator) void;
    pub const ref = g_object_ref;

    extern fn g_object_unref(p_self: *gstbase.Aggregator) void;
    pub const unref = g_object_unref;

    pub fn as(p_instance: *Aggregator, comptime P_T: type) *P_T {
        return gobject.ext.as(P_T, p_instance);
    }

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// Pads managed by a `gstbase.Aggregator` subclass.
///
/// This class used to live in gst-plugins-bad and was moved to core.
pub const AggregatorPad = extern struct {
    pub const Parent = gst.Pad;
    pub const Implements = [_]type{};
    pub const Class = gstbase.AggregatorPadClass;
    f_parent: gst.Pad,
    /// last segment received.
    f_segment: gst.Segment,
    f_priv: ?*gstbase.AggregatorPadPrivate,
    f__gst_reserved: [4]*anyopaque,

    pub const virtual_methods = struct {
        /// Optional
        ///               Called when the pad has received a flush stop, this is the place
        ///               to flush any information specific to the pad, it allows for individual
        ///               pads to be flushed while others might not be.
        pub const flush = struct {
            pub fn call(p_class: anytype, p_aggpad: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_aggregator: *gstbase.Aggregator) gst.FlowReturn {
                return gobject.ext.as(AggregatorPad.Class, p_class).f_flush.?(gobject.ext.as(AggregatorPad, p_aggpad), p_aggregator);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_aggpad: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_aggregator: *gstbase.Aggregator) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(AggregatorPad.Class, p_class).f_flush = @ptrCast(p_implementation);
            }
        };

        /// Optional
        ///               Called before input buffers are queued in the pad, return `TRUE`
        ///               if the buffer should be skipped.
        pub const skip_buffer = struct {
            pub fn call(p_class: anytype, p_aggpad: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_aggregator: *gstbase.Aggregator, p_buffer: *gst.Buffer) c_int {
                return gobject.ext.as(AggregatorPad.Class, p_class).f_skip_buffer.?(gobject.ext.as(AggregatorPad, p_aggpad), p_aggregator, p_buffer);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_aggpad: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_aggregator: *gstbase.Aggregator, p_buffer: *gst.Buffer) callconv(.c) c_int) void {
                gobject.ext.as(AggregatorPad.Class, p_class).f_skip_buffer = @ptrCast(p_implementation);
            }
        };
    };

    pub const properties = struct {
        /// Enables the emission of signals such as `gstbase.AggregatorPad.signals.buffer`-consumed
        pub const emit_signals = struct {
            pub const name = "emit-signals";

            pub const Type = c_int;
        };
    };

    pub const signals = struct {
        pub const buffer_consumed = struct {
            pub const name = "buffer-consumed";

            pub fn connect(p_instance: anytype, comptime P_Data: type, p_callback: *const fn (@TypeOf(p_instance), p_object: *gst.Buffer, P_Data) callconv(.c) void, p_data: P_Data, p_options: gobject.ext.ConnectSignalOptions(P_Data)) c_ulong {
                return gobject.signalConnectClosureById(
                    @ptrCast(@alignCast(gobject.ext.as(AggregatorPad, p_instance))),
                    gobject.signalLookup("buffer-consumed", AggregatorPad.getGObjectType()),
                    glib.quarkFromString(p_options.detail orelse null),
                    gobject.CClosure.new(@ptrCast(p_callback), p_data, @ptrCast(p_options.destroyData)),
                    @intFromBool(p_options.after),
                );
            }
        };
    };

    /// Drop the buffer currently queued in `pad`.
    extern fn gst_aggregator_pad_drop_buffer(p_pad: *AggregatorPad) c_int;
    pub const dropBuffer = gst_aggregator_pad_drop_buffer;

    /// This checks if a pad has a buffer available that will be returned by
    /// a call to `gstbase.AggregatorPad.peekBuffer` or
    /// `gstbase.AggregatorPad.popBuffer`.
    extern fn gst_aggregator_pad_has_buffer(p_pad: *AggregatorPad) c_int;
    pub const hasBuffer = gst_aggregator_pad_has_buffer;

    extern fn gst_aggregator_pad_is_eos(p_pad: *AggregatorPad) c_int;
    pub const isEos = gst_aggregator_pad_is_eos;

    /// It is only valid to call this method from `gstbase.AggregatorClass.signals.aggregate``aggregate`
    extern fn gst_aggregator_pad_is_inactive(p_pad: *AggregatorPad) c_int;
    pub const isInactive = gst_aggregator_pad_is_inactive;

    extern fn gst_aggregator_pad_peek_buffer(p_pad: *AggregatorPad) ?*gst.Buffer;
    pub const peekBuffer = gst_aggregator_pad_peek_buffer;

    /// Steal the ref to the buffer currently queued in `pad`.
    extern fn gst_aggregator_pad_pop_buffer(p_pad: *AggregatorPad) ?*gst.Buffer;
    pub const popBuffer = gst_aggregator_pad_pop_buffer;

    extern fn gst_aggregator_pad_get_type() usize;
    pub const getGObjectType = gst_aggregator_pad_get_type;

    extern fn g_object_ref(p_self: *gstbase.AggregatorPad) void;
    pub const ref = g_object_ref;

    extern fn g_object_unref(p_self: *gstbase.AggregatorPad) void;
    pub const unref = g_object_unref;

    pub fn as(p_instance: *AggregatorPad, comptime P_T: type) *P_T {
        return gobject.ext.as(P_T, p_instance);
    }

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// This base class is for parser elements that process data and splits it
/// into separate audio/video/whatever frames.
///
/// It provides for:
///
///   * provides one sink pad and one source pad
///   * handles state changes
///   * can operate in pull mode or push mode
///   * handles seeking in both modes
///   * handles events (SEGMENT/EOS/FLUSH)
///   * handles queries (POSITION/DURATION/SEEKING/FORMAT/CONVERT)
///   * handles flushing
///
/// The purpose of this base class is to provide the basic functionality of
/// a parser and share a lot of rather complex code.
///
/// # Description of the parsing mechanism:
///
/// ## Set-up phase
///
///  * `gstbase.BaseParse` calls `gstbase.BaseParseClass.signals.start` to inform subclass
///    that data processing is about to start now.
///
///  * `gstbase.BaseParse` class calls `gstbase.BaseParseClass.signals.set_sink_caps` to
///    inform the subclass about incoming sinkpad caps. Subclass could
///    already set the srcpad caps accordingly, but this might be delayed
///    until calling `gstbase.BaseParse.finishFrame` with a non-queued frame.
///
///  * At least at this point subclass needs to tell the `gstbase.BaseParse` class
///    how big data chunks it wants to receive (minimum frame size ). It can
///    do this with `gstbase.BaseParse.setMinFrameSize`.
///
///  * `gstbase.BaseParse` class sets up appropriate data passing mode (pull/push)
///    and starts to process the data.
///
/// ## Parsing phase
///
///  * `gstbase.BaseParse` gathers at least min_frame_size bytes of data either
///    by pulling it from upstream or collecting buffers in an internal
///    `gstbase.Adapter`.
///
///  * A buffer of (at least) min_frame_size bytes is passed to subclass
///    with `gstbase.BaseParseClass.signals.handle_frame`. Subclass checks the contents
///    and can optionally return `GST_FLOW_OK` along with an amount of data
///    to be skipped to find a valid frame (which will result in a
///    subsequent DISCONT).  If, otherwise, the buffer does not hold a
///    complete frame, `gstbase.BaseParseClass.signals.handle_frame` can merely return
///    and will be called again when additional data is available.  In push
///    mode this amounts to an additional input buffer (thus minimal
///    additional latency), in pull mode this amounts to some arbitrary
///    reasonable buffer size increase.
///
///    Of course, `gstbase.BaseParse.setMinFrameSize` could also be used if
///    a very specific known amount of additional data is required.  If,
///    however, the buffer holds a complete valid frame, it can pass the
///    size of this frame to `gstbase.BaseParse.finishFrame`.
///
///    If acting as a converter, it can also merely indicate consumed input
///    data while simultaneously providing custom output data.  Note that
///    baseclass performs some processing (such as tracking overall consumed
///    data rate versus duration) for each finished frame, but other state
///    is only updated upon each call to `gstbase.BaseParseClass.signals.handle_frame`
///    (such as tracking upstream input timestamp).
///
///    Subclass is also responsible for setting the buffer metadata
///    (e.g. buffer timestamp and duration, or keyframe if applicable).
///    (although the latter can also be done by `gstbase.BaseParse` if it is
///    appropriately configured, see below).  Frame is provided with
///    timestamp derived from upstream (as much as generally possible),
///    duration obtained from configuration (see below), and offset
///    if meaningful (in pull mode).
///
///    Note that `gstbase.BaseParseClass.signals.handle_frame` might receive any small
///    amount of input data when leftover data is being drained (e.g. at
///    EOS).
///
///  * As part of finish frame processing, just prior to actually pushing
///    the buffer in question, it is passed to
///    `gstbase.BaseParseClass.signals.pre_push_frame` which gives subclass yet one last
///    chance to examine buffer metadata, or to send some custom (tag)
///    events, or to perform custom (segment) filtering.
///
///  * During the parsing process `gstbase.BaseParseClass` will handle both srcpad
///    and sinkpad events. They will be passed to subclass if
///    `gstbase.BaseParseClass.signals.sink_event` or `gstbase.BaseParseClass.signals.src_event`
///    implementations have been provided.
///
/// ## Shutdown phase
///
/// * `gstbase.BaseParse` class calls `gstbase.BaseParseClass.signals.stop` to inform the
///   subclass that data parsing will be stopped.
///
/// Subclass is responsible for providing pad template caps for source and
/// sink pads. The pads need to be named "sink" and "src". It also needs to
/// set the fixed caps on srcpad, when the format is ensured (e.g.  when
/// base class calls subclass' `gstbase.BaseParseClass.signals.set_sink_caps` function).
///
/// This base class uses `GST_FORMAT_DEFAULT` as a meaning of frames. So,
/// subclass conversion routine needs to know that conversion from
/// `GST_FORMAT_TIME` to `GST_FORMAT_DEFAULT` must return the
/// frame number that can be found from the given byte position.
///
/// `gstbase.BaseParse` uses subclasses conversion methods also for seeking (or
/// otherwise uses its own default one, see also below).
///
/// Subclass `start` and `stop` functions will be called to inform the beginning
/// and end of data processing.
///
/// Things that subclass need to take care of:
///
/// * Provide pad templates
/// * Fixate the source pad caps when appropriate
/// * Inform base class how big data chunks should be retrieved. This is
///   done with `gstbase.BaseParse.setMinFrameSize` function.
/// * Examine data chunks passed to subclass with
///   `gstbase.BaseParseClass.signals.handle_frame` and pass proper frame(s) to
///   `gstbase.BaseParse.finishFrame`, and setting src pad caps and timestamps
///   on frame.
/// * Provide conversion functions
/// * Update the duration information with `gstbase.BaseParse.setDuration`
/// * Optionally passthrough using `gstbase.BaseParse.setPassthrough`
/// * Configure various baseparse parameters using
///   `gstbase.BaseParse.setAverageBitrate`, `gstbase.BaseParse.setSyncable`
///   and `gstbase.BaseParse.setFrameRate`.
///
/// * In particular, if subclass is unable to determine a duration, but
///   parsing (or specs) yields a frames per seconds rate, then this can be
///   provided to `gstbase.BaseParse` to enable it to cater for buffer time
///   metadata (which will be taken from upstream as much as
///   possible). Internally keeping track of frame durations and respective
///   sizes that have been pushed provides `gstbase.BaseParse` with an estimated
///   bitrate. A default `gstbase.BaseParseClass.signals.convert` (used if not
///   overridden) will then use these rates to perform obvious conversions.
///   These rates are also used to update (estimated) duration at regular
///   frame intervals.
pub const BaseParse = extern struct {
    pub const Parent = gst.Element;
    pub const Implements = [_]type{};
    pub const Class = gstbase.BaseParseClass;
    /// the parent element.
    f_element: gst.Element,
    f_sinkpad: ?*gst.Pad,
    f_srcpad: ?*gst.Pad,
    f_flags: c_uint,
    f_segment: gst.Segment,
    f__gst_reserved: [20]*anyopaque,
    f_priv: ?*gstbase.BaseParsePrivate,

    pub const virtual_methods = struct {
        /// Optional.
        ///                  Convert between formats.
        pub const convert = struct {
            pub fn call(p_class: anytype, p_parse: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_src_format: gst.Format, p_src_value: i64, p_dest_format: gst.Format, p_dest_value: *i64) c_int {
                return gobject.ext.as(BaseParse.Class, p_class).f_convert.?(gobject.ext.as(BaseParse, p_parse), p_src_format, p_src_value, p_dest_format, p_dest_value);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_parse: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_src_format: gst.Format, p_src_value: i64, p_dest_format: gst.Format, p_dest_value: *i64) callconv(.c) c_int) void {
                gobject.ext.as(BaseParse.Class, p_class).f_convert = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                   Called until it doesn't return GST_FLOW_OK anymore for
        ///                   the first buffers. Can be used by the subclass to detect
        ///                   the stream format.
        pub const detect = struct {
            pub fn call(p_class: anytype, p_parse: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buffer: *gst.Buffer) gst.FlowReturn {
                return gobject.ext.as(BaseParse.Class, p_class).f_detect.?(gobject.ext.as(BaseParse, p_parse), p_buffer);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_parse: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buffer: *gst.Buffer) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(BaseParse.Class, p_class).f_detect = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                  Allows the subclass to do its own sink get caps if needed.
        pub const get_sink_caps = struct {
            pub fn call(p_class: anytype, p_parse: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_filter: *gst.Caps) *gst.Caps {
                return gobject.ext.as(BaseParse.Class, p_class).f_get_sink_caps.?(gobject.ext.as(BaseParse, p_parse), p_filter);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_parse: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_filter: *gst.Caps) callconv(.c) *gst.Caps) void {
                gobject.ext.as(BaseParse.Class, p_class).f_get_sink_caps = @ptrCast(p_implementation);
            }
        };

        /// Parses the input data into valid frames as defined by subclass
        /// which should be passed to `gstbase.BaseParse.finishFrame`.
        /// The frame's input buffer is guaranteed writable,
        /// whereas the input frame ownership is held by caller
        /// (so subclass should make a copy if it needs to hang on).
        /// Input buffer (data) is provided by baseclass with as much
        /// metadata set as possible by baseclass according to upstream
        /// information and/or subclass settings,
        /// though subclass may still set buffer timestamp and duration
        /// if desired.
        pub const handle_frame = struct {
            pub fn call(p_class: anytype, p_parse: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_frame: *gstbase.BaseParseFrame, p_skipsize: *c_int) gst.FlowReturn {
                return gobject.ext.as(BaseParse.Class, p_class).f_handle_frame.?(gobject.ext.as(BaseParse, p_parse), p_frame, p_skipsize);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_parse: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_frame: *gstbase.BaseParseFrame, p_skipsize: *c_int) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(BaseParse.Class, p_class).f_handle_frame = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                   Called just prior to pushing a frame (after any pending
        ///                   events have been sent) to give subclass a chance to perform
        ///                   additional actions at this time (e.g. tag sending) or to
        ///                   decide whether this buffer should be dropped or not
        ///                   (e.g. custom segment clipping).
        pub const pre_push_frame = struct {
            pub fn call(p_class: anytype, p_parse: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_frame: *gstbase.BaseParseFrame) gst.FlowReturn {
                return gobject.ext.as(BaseParse.Class, p_class).f_pre_push_frame.?(gobject.ext.as(BaseParse, p_parse), p_frame);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_parse: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_frame: *gstbase.BaseParseFrame) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(BaseParse.Class, p_class).f_pre_push_frame = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                  Allows the subclass to be notified of the actual caps set.
        pub const set_sink_caps = struct {
            pub fn call(p_class: anytype, p_parse: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_caps: *gst.Caps) c_int {
                return gobject.ext.as(BaseParse.Class, p_class).f_set_sink_caps.?(gobject.ext.as(BaseParse, p_parse), p_caps);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_parse: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_caps: *gst.Caps) callconv(.c) c_int) void {
                gobject.ext.as(BaseParse.Class, p_class).f_set_sink_caps = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                  Event handler on the sink pad. This function should chain
        ///                  up to the parent implementation to let the default handler
        ///                  run.
        pub const sink_event = struct {
            pub fn call(p_class: anytype, p_parse: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_event: *gst.Event) c_int {
                return gobject.ext.as(BaseParse.Class, p_class).f_sink_event.?(gobject.ext.as(BaseParse, p_parse), p_event);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_parse: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_event: *gst.Event) callconv(.c) c_int) void {
                gobject.ext.as(BaseParse.Class, p_class).f_sink_event = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                   Query handler on the sink pad. This function should chain
        ///                   up to the parent implementation to let the default handler
        ///                   run (Since: 1.2)
        pub const sink_query = struct {
            pub fn call(p_class: anytype, p_parse: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_query: *gst.Query) c_int {
                return gobject.ext.as(BaseParse.Class, p_class).f_sink_query.?(gobject.ext.as(BaseParse, p_parse), p_query);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_parse: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_query: *gst.Query) callconv(.c) c_int) void {
                gobject.ext.as(BaseParse.Class, p_class).f_sink_query = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                  Event handler on the source pad. Should chain up to the
        ///                  parent to let the default handler run.
        pub const src_event = struct {
            pub fn call(p_class: anytype, p_parse: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_event: *gst.Event) c_int {
                return gobject.ext.as(BaseParse.Class, p_class).f_src_event.?(gobject.ext.as(BaseParse, p_parse), p_event);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_parse: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_event: *gst.Event) callconv(.c) c_int) void {
                gobject.ext.as(BaseParse.Class, p_class).f_src_event = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                   Query handler on the source pad. Should chain up to the
        ///                   parent to let the default handler run (Since: 1.2)
        pub const src_query = struct {
            pub fn call(p_class: anytype, p_parse: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_query: *gst.Query) c_int {
                return gobject.ext.as(BaseParse.Class, p_class).f_src_query.?(gobject.ext.as(BaseParse, p_parse), p_query);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_parse: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_query: *gst.Query) callconv(.c) c_int) void {
                gobject.ext.as(BaseParse.Class, p_class).f_src_query = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                  Called when the element starts processing.
        ///                  Allows opening external resources.
        pub const start = struct {
            pub fn call(p_class: anytype, p_parse: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) c_int {
                return gobject.ext.as(BaseParse.Class, p_class).f_start.?(gobject.ext.as(BaseParse, p_parse));
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_parse: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) callconv(.c) c_int) void {
                gobject.ext.as(BaseParse.Class, p_class).f_start = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                  Called when the element stops processing.
        ///                  Allows closing external resources.
        pub const stop = struct {
            pub fn call(p_class: anytype, p_parse: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) c_int {
                return gobject.ext.as(BaseParse.Class, p_class).f_stop.?(gobject.ext.as(BaseParse, p_parse));
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_parse: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) callconv(.c) c_int) void {
                gobject.ext.as(BaseParse.Class, p_class).f_stop = @ptrCast(p_implementation);
            }
        };
    };

    pub const properties = struct {
        /// If set to `TRUE`, baseparse will unconditionally force parsing of the
        /// incoming data. This can be required in the rare cases where the incoming
        /// side-data (caps, pts, dts, ...) is not trusted by the user and wants to
        /// force validation and parsing of the incoming data.
        /// If set to `FALSE`, decision of whether to parse the data or not is up to
        /// the implementation (standard behaviour).
        pub const disable_passthrough = struct {
            pub const name = "disable-passthrough";

            pub const Type = c_int;
        };
    };

    pub const signals = struct {};

    /// Adds an entry to the index associating `offset` to `ts`.  It is recommended
    /// to only add keyframe entries.  `force` allows to bypass checks, such as
    /// whether the stream is (upstream) seekable, another entry is already "close"
    /// to the new entry, etc.
    extern fn gst_base_parse_add_index_entry(p_parse: *BaseParse, p_offset: u64, p_ts: gst.ClockTime, p_key: c_int, p_force: c_int) c_int;
    pub const addIndexEntry = gst_base_parse_add_index_entry;

    /// Default implementation of `gstbase.BaseParseClass.signals.convert`.
    extern fn gst_base_parse_convert_default(p_parse: *BaseParse, p_src_format: gst.Format, p_src_value: i64, p_dest_format: gst.Format, p_dest_value: *i64) c_int;
    pub const convertDefault = gst_base_parse_convert_default;

    /// Drains the adapter until it is empty. It decreases the min_frame_size to
    /// match the current adapter size and calls chain method until the adapter
    /// is emptied or chain returns with error.
    extern fn gst_base_parse_drain(p_parse: *BaseParse) void;
    pub const drain = gst_base_parse_drain;

    /// Collects parsed data and pushes it downstream.
    /// Source pad caps must be set when this is called.
    ///
    /// If `frame`'s out_buffer is set, that will be used as subsequent frame data,
    /// and `size` amount will be flushed from the input data. The output_buffer size
    /// can differ from the consumed size indicated by `size`.
    ///
    /// Otherwise, `size` samples will be taken from the input and used for output,
    /// and the output's metadata (timestamps etc) will be taken as (optionally)
    /// set by the subclass on `frame`'s (input) buffer (which is otherwise
    /// ignored for any but the above purpose/information).
    ///
    /// Note that the latter buffer is invalidated by this call, whereas the
    /// caller retains ownership of `frame`.
    extern fn gst_base_parse_finish_frame(p_parse: *BaseParse, p_frame: *gstbase.BaseParseFrame, p_size: c_int) gst.FlowReturn;
    pub const finishFrame = gst_base_parse_finish_frame;

    /// Sets the parser subclass's tags and how they should be merged with any
    /// upstream stream tags. This will override any tags previously-set
    /// with `gstbase.BaseParse.mergeTags`.
    ///
    /// Note that this is provided for convenience, and the subclass is
    /// not required to use this and can still do tag handling on its own.
    extern fn gst_base_parse_merge_tags(p_parse: *BaseParse, p_tags: ?*gst.TagList, p_mode: gst.TagMergeMode) void;
    pub const mergeTags = gst_base_parse_merge_tags;

    /// Pushes the frame's buffer downstream, sends any pending events and
    /// does some timestamp and segment handling. Takes ownership of
    /// frame's buffer, though caller retains ownership of `frame`.
    ///
    /// This must be called with sinkpad STREAM_LOCK held.
    extern fn gst_base_parse_push_frame(p_parse: *BaseParse, p_frame: *gstbase.BaseParseFrame) gst.FlowReturn;
    pub const pushFrame = gst_base_parse_push_frame;

    /// Optionally sets the average bitrate detected in media (if non-zero),
    /// e.g. based on metadata, as it will be posted to the application.
    ///
    /// By default, announced average bitrate is estimated. The average bitrate
    /// is used to estimate the total duration of the stream and to estimate
    /// a seek position, if there's no index and the format is syncable
    /// (see `gstbase.BaseParse.setSyncable`).
    extern fn gst_base_parse_set_average_bitrate(p_parse: *BaseParse, p_bitrate: c_uint) void;
    pub const setAverageBitrate = gst_base_parse_set_average_bitrate;

    /// Sets the duration of the currently playing media. Subclass can use this
    /// when it is able to determine duration and/or notices a change in the media
    /// duration.  Alternatively, if `interval` is non-zero (default), then stream
    /// duration is determined based on estimated bitrate, and updated every `interval`
    /// frames.
    extern fn gst_base_parse_set_duration(p_parse: *BaseParse, p_fmt: gst.Format, p_duration: i64, p_interval: c_int) void;
    pub const setDuration = gst_base_parse_set_duration;

    /// If frames per second is configured, parser can take care of buffer duration
    /// and timestamping.  When performing segment clipping, or seeking to a specific
    /// location, a corresponding decoder might need an initial `lead_in` and a
    /// following `lead_out` number of frames to ensure the desired segment is
    /// entirely filled upon decoding.
    extern fn gst_base_parse_set_frame_rate(p_parse: *BaseParse, p_fps_num: c_uint, p_fps_den: c_uint, p_lead_in: c_uint, p_lead_out: c_uint) void;
    pub const setFrameRate = gst_base_parse_set_frame_rate;

    /// Set if frames carry timing information which the subclass can (generally)
    /// parse and provide.  In particular, intrinsic (rather than estimated) time
    /// can be obtained following a seek.
    extern fn gst_base_parse_set_has_timing_info(p_parse: *BaseParse, p_has_timing: c_int) void;
    pub const setHasTimingInfo = gst_base_parse_set_has_timing_info;

    /// By default, the base class might try to infer PTS from DTS and vice
    /// versa.  While this is generally correct for audio data, it may not
    /// be otherwise. Sub-classes implementing such formats should disable
    /// timestamp inferring.
    extern fn gst_base_parse_set_infer_ts(p_parse: *BaseParse, p_infer_ts: c_int) void;
    pub const setInferTs = gst_base_parse_set_infer_ts;

    /// Sets the minimum and maximum (which may likely be equal) latency introduced
    /// by the parsing process. If there is such a latency, which depends on the
    /// particular parsing of the format, it typically corresponds to 1 frame duration.
    ///
    /// If the provided values changed from previously provided ones, this will
    /// also post a LATENCY message on the bus so the pipeline can reconfigure its
    /// global latency.
    extern fn gst_base_parse_set_latency(p_parse: *BaseParse, p_min_latency: gst.ClockTime, p_max_latency: gst.ClockTime) void;
    pub const setLatency = gst_base_parse_set_latency;

    /// Subclass can use this function to tell the base class that it needs to
    /// be given buffers of at least `min_size` bytes.
    extern fn gst_base_parse_set_min_frame_size(p_parse: *BaseParse, p_min_size: c_uint) void;
    pub const setMinFrameSize = gst_base_parse_set_min_frame_size;

    /// Set if the nature of the format or configuration does not allow (much)
    /// parsing, and the parser should operate in passthrough mode (which only
    /// applies when operating in push mode). That is, incoming buffers are
    /// pushed through unmodified, i.e. no `gstbase.BaseParseClass.signals.handle_frame`
    /// will be invoked, but `gstbase.BaseParseClass.signals.pre_push_frame` will still be
    /// invoked, so subclass can perform as much or as little is appropriate for
    /// passthrough semantics in `gstbase.BaseParseClass.signals.pre_push_frame`.
    extern fn gst_base_parse_set_passthrough(p_parse: *BaseParse, p_passthrough: c_int) void;
    pub const setPassthrough = gst_base_parse_set_passthrough;

    /// By default, the base class will guess PTS timestamps using a simple
    /// interpolation (previous timestamp + duration), which is incorrect for
    /// data streams with reordering, where PTS can go backward. Sub-classes
    /// implementing such formats should disable PTS interpolation.
    extern fn gst_base_parse_set_pts_interpolation(p_parse: *BaseParse, p_pts_interpolate: c_int) void;
    pub const setPtsInterpolation = gst_base_parse_set_pts_interpolation;

    /// Set if frame starts can be identified. This is set by default and
    /// determines whether seeking based on bitrate averages
    /// is possible for a format/stream.
    extern fn gst_base_parse_set_syncable(p_parse: *BaseParse, p_syncable: c_int) void;
    pub const setSyncable = gst_base_parse_set_syncable;

    /// This function should only be called from a `handle_frame` implementation.
    ///
    /// `gstbase.BaseParse` creates initial timestamps for frames by using the last
    /// timestamp seen in the stream before the frame starts.  In certain
    /// cases, the correct timestamps will occur in the stream after the
    /// start of the frame, but before the start of the actual picture data.
    /// This function can be used to set the timestamps based on the offset
    /// into the frame data that the picture starts.
    extern fn gst_base_parse_set_ts_at_offset(p_parse: *BaseParse, p_offset: usize) void;
    pub const setTsAtOffset = gst_base_parse_set_ts_at_offset;

    extern fn gst_base_parse_get_type() usize;
    pub const getGObjectType = gst_base_parse_get_type;

    extern fn g_object_ref(p_self: *gstbase.BaseParse) void;
    pub const ref = g_object_ref;

    extern fn g_object_unref(p_self: *gstbase.BaseParse) void;
    pub const unref = g_object_unref;

    pub fn as(p_instance: *BaseParse, comptime P_T: type) *P_T {
        return gobject.ext.as(P_T, p_instance);
    }

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// `gstbase.BaseSink` is the base class for sink elements in GStreamer, such as
/// xvimagesink or filesink. It is a layer on top of `gst.Element` that provides a
/// simplified interface to plugin writers. `gstbase.BaseSink` handles many details
/// for you, for example: preroll, clock synchronization, state changes,
/// activation in push or pull mode, and queries.
///
/// In most cases, when writing sink elements, there is no need to implement
/// class methods from `gst.Element` or to set functions on pads, because the
/// `gstbase.BaseSink` infrastructure should be sufficient.
///
/// `gstbase.BaseSink` provides support for exactly one sink pad, which should be
/// named "sink". A sink implementation (subclass of `gstbase.BaseSink`) should
/// install a pad template in its class_init function, like so:
/// ```
/// static void
/// my_element_class_init (GstMyElementClass *klass)
/// {
///   GstElementClass *gstelement_class = GST_ELEMENT_CLASS (klass);
///
///   // sinktemplate should be a `gst.StaticPadTemplate` with direction
///   // `GST_PAD_SINK` and name "sink"
///   gst_element_class_add_static_pad_template (gstelement_class, &sinktemplate);
///
///   gst_element_class_set_static_metadata (gstelement_class,
///       "Sink name",
///       "Sink",
///       "My Sink element",
///       "The author <my.sink`my`.email>");
/// }
/// ```
///
/// `gstbase.BaseSink` will handle the prerolling correctly. This means that it will
/// return `GST_STATE_CHANGE_ASYNC` from a state change to PAUSED until the first
/// buffer arrives in this element. The base class will call the
/// `gstbase.BaseSinkClass.signals.preroll` vmethod with this preroll buffer and will then
/// commit the state change to the next asynchronously pending state.
///
/// When the element is set to PLAYING, `gstbase.BaseSink` will synchronise on the
/// clock using the times returned from `gstbase.BaseSinkClass.signals.get_times`. If this
/// function returns `GST_CLOCK_TIME_NONE` for the start time, no synchronisation
/// will be done. Synchronisation can be disabled entirely by setting the object
/// `gstbase.BaseSink.properties.sync` property to `FALSE`.
///
/// After synchronisation the virtual method `gstbase.BaseSinkClass.signals.render` will be
/// called. Subclasses should minimally implement this method.
///
/// Subclasses that synchronise on the clock in the `gstbase.BaseSinkClass.signals.render`
/// method are supported as well. These classes typically receive a buffer in
/// the render method and can then potentially block on the clock while
/// rendering. A typical example is an audiosink.
/// These subclasses can use `gstbase.BaseSink.waitPreroll` to perform the
/// blocking wait.
///
/// Upon receiving the EOS event in the PLAYING state, `gstbase.BaseSink` will wait
/// for the clock to reach the time indicated by the stop time of the last
/// `gstbase.BaseSinkClass.signals.get_times` call before posting an EOS message. When the
/// element receives EOS in PAUSED, preroll completes, the event is queued and an
/// EOS message is posted when going to PLAYING.
///
/// `gstbase.BaseSink` will internally use the `GST_EVENT_SEGMENT` events to schedule
/// synchronisation and clipping of buffers. Buffers that fall completely outside
/// of the current segment are dropped. Buffers that fall partially in the
/// segment are rendered (and prerolled). Subclasses should do any subbuffer
/// clipping themselves when needed.
///
/// `gstbase.BaseSink` will by default report the current playback position in
/// `GST_FORMAT_TIME` based on the current clock time and segment information.
/// If no clock has been set on the element, the query will be forwarded
/// upstream.
///
/// The `gstbase.BaseSinkClass.signals.set_caps` function will be called when the subclass
/// should configure itself to process a specific media type.
///
/// The `gstbase.BaseSinkClass.signals.start` and `gstbase.BaseSinkClass.signals.stop` virtual methods
/// will be called when resources should be allocated. Any
/// `gstbase.BaseSinkClass.signals.preroll`, `gstbase.BaseSinkClass.signals.render` and
/// `gstbase.BaseSinkClass.signals.set_caps` function will be called between the
/// `gstbase.BaseSinkClass.signals.start` and `gstbase.BaseSinkClass.signals.stop` calls.
///
/// The `gstbase.BaseSinkClass.signals.event` virtual method will be called when an event is
/// received by `gstbase.BaseSink`. Normally this method should only be overridden by
/// very specific elements (such as file sinks) which need to handle the
/// newsegment event specially.
///
/// The `gstbase.BaseSinkClass.signals.unlock` method is called when the elements should
/// unblock any blocking operations they perform in the
/// `gstbase.BaseSinkClass.signals.render` method. This is mostly useful when the
/// `gstbase.BaseSinkClass.signals.render` method performs a blocking write on a file
/// descriptor, for example.
///
/// The `gstbase.BaseSink.properties.max`-lateness property affects how the sink deals with
/// buffers that arrive too late in the sink. A buffer arrives too late in the
/// sink when the presentation time (as a combination of the last segment, buffer
/// timestamp and element base_time) plus the duration is before the current
/// time of the clock.
/// If the frame is later than max-lateness, the sink will drop the buffer
/// without calling the render method.
/// This feature is disabled if sync is disabled, the
/// `gstbase.BaseSinkClass.signals.get_times` method does not return a valid start time or
/// max-lateness is set to -1 (the default).
/// Subclasses can use `gstbase.BaseSink.setMaxLateness` to configure the
/// max-lateness value.
///
/// The `gstbase.BaseSink.properties.qos` property will enable the quality-of-service features of
/// the basesink which gather statistics about the real-time performance of the
/// clock synchronisation. For each buffer received in the sink, statistics are
/// gathered and a QOS event is sent upstream with these numbers. This
/// information can then be used by upstream elements to reduce their processing
/// rate, for example.
///
/// The `gstbase.BaseSink.properties.async` property can be used to instruct the sink to never
/// perform an ASYNC state change. This feature is mostly usable when dealing
/// with non-synchronized streams or sparse streams.
pub const BaseSink = extern struct {
    pub const Parent = gst.Element;
    pub const Implements = [_]type{};
    pub const Class = gstbase.BaseSinkClass;
    f_element: gst.Element,
    f_sinkpad: ?*gst.Pad,
    f_pad_mode: gst.PadMode,
    f_offset: u64,
    f_can_activate_pull: c_int,
    f_can_activate_push: c_int,
    f_preroll_lock: glib.Mutex,
    f_preroll_cond: glib.Cond,
    f_eos: c_int,
    f_need_preroll: c_int,
    f_have_preroll: c_int,
    f_playing_async: c_int,
    f_have_newsegment: c_int,
    f_segment: gst.Segment,
    f_clock_id: gst.ClockID,
    f_sync: c_int,
    f_flushing: c_int,
    f_running: c_int,
    f_max_lateness: i64,
    f_priv: ?*gstbase.BaseSinkPrivate,
    f__gst_reserved: [20]*anyopaque,

    pub const virtual_methods = struct {
        /// Subclasses should override this when they can provide an
        ///     alternate method of spawning a thread to drive the pipeline in pull mode.
        ///     Should start or stop the pulling thread, depending on the value of the
        ///     "active" argument. Called after actually activating the sink pad in pull
        ///     mode. The default implementation starts a task on the sink pad.
        pub const activate_pull = struct {
            pub fn call(p_class: anytype, p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_active: c_int) c_int {
                return gobject.ext.as(BaseSink.Class, p_class).f_activate_pull.?(gobject.ext.as(BaseSink, p_sink), p_active);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_active: c_int) callconv(.c) c_int) void {
                gobject.ext.as(BaseSink.Class, p_class).f_activate_pull = @ptrCast(p_implementation);
            }
        };

        /// Override this to handle events arriving on the sink pad
        pub const event = struct {
            pub fn call(p_class: anytype, p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_event: *gst.Event) c_int {
                return gobject.ext.as(BaseSink.Class, p_class).f_event.?(gobject.ext.as(BaseSink, p_sink), p_event);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_event: *gst.Event) callconv(.c) c_int) void {
                gobject.ext.as(BaseSink.Class, p_class).f_event = @ptrCast(p_implementation);
            }
        };

        /// Only useful in pull mode. Implement if you have
        ///     ideas about what should be the default values for the caps you support.
        pub const fixate = struct {
            pub fn call(p_class: anytype, p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_caps: *gst.Caps) *gst.Caps {
                return gobject.ext.as(BaseSink.Class, p_class).f_fixate.?(gobject.ext.as(BaseSink, p_sink), p_caps);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_caps: *gst.Caps) callconv(.c) *gst.Caps) void {
                gobject.ext.as(BaseSink.Class, p_class).f_fixate = @ptrCast(p_implementation);
            }
        };

        /// Called to get sink pad caps from the subclass.
        pub const get_caps = struct {
            pub fn call(p_class: anytype, p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_filter: ?*gst.Caps) *gst.Caps {
                return gobject.ext.as(BaseSink.Class, p_class).f_get_caps.?(gobject.ext.as(BaseSink, p_sink), p_filter);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_filter: ?*gst.Caps) callconv(.c) *gst.Caps) void {
                gobject.ext.as(BaseSink.Class, p_class).f_get_caps = @ptrCast(p_implementation);
            }
        };

        /// Get the start and end times for syncing on this buffer.
        pub const get_times = struct {
            pub fn call(p_class: anytype, p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buffer: *gst.Buffer, p_start: *gst.ClockTime, p_end: *gst.ClockTime) void {
                return gobject.ext.as(BaseSink.Class, p_class).f_get_times.?(gobject.ext.as(BaseSink, p_sink), p_buffer, p_start, p_end);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buffer: *gst.Buffer, p_start: *gst.ClockTime, p_end: *gst.ClockTime) callconv(.c) void) void {
                gobject.ext.as(BaseSink.Class, p_class).f_get_times = @ptrCast(p_implementation);
            }
        };

        /// Called to prepare the buffer for `render` and `preroll`. This
        ///     function is called before synchronisation is performed.
        pub const prepare = struct {
            pub fn call(p_class: anytype, p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buffer: *gst.Buffer) gst.FlowReturn {
                return gobject.ext.as(BaseSink.Class, p_class).f_prepare.?(gobject.ext.as(BaseSink, p_sink), p_buffer);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buffer: *gst.Buffer) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(BaseSink.Class, p_class).f_prepare = @ptrCast(p_implementation);
            }
        };

        /// Called to prepare the buffer list for `render_list`. This
        ///     function is called before synchronisation is performed.
        pub const prepare_list = struct {
            pub fn call(p_class: anytype, p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buffer_list: *gst.BufferList) gst.FlowReturn {
                return gobject.ext.as(BaseSink.Class, p_class).f_prepare_list.?(gobject.ext.as(BaseSink, p_sink), p_buffer_list);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buffer_list: *gst.BufferList) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(BaseSink.Class, p_class).f_prepare_list = @ptrCast(p_implementation);
            }
        };

        /// Called to present the preroll buffer if desired.
        pub const preroll = struct {
            pub fn call(p_class: anytype, p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buffer: *gst.Buffer) gst.FlowReturn {
                return gobject.ext.as(BaseSink.Class, p_class).f_preroll.?(gobject.ext.as(BaseSink, p_sink), p_buffer);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buffer: *gst.Buffer) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(BaseSink.Class, p_class).f_preroll = @ptrCast(p_implementation);
            }
        };

        /// configure the allocation query
        pub const propose_allocation = struct {
            pub fn call(p_class: anytype, p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_query: *gst.Query) c_int {
                return gobject.ext.as(BaseSink.Class, p_class).f_propose_allocation.?(gobject.ext.as(BaseSink, p_sink), p_query);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_query: *gst.Query) callconv(.c) c_int) void {
                gobject.ext.as(BaseSink.Class, p_class).f_propose_allocation = @ptrCast(p_implementation);
            }
        };

        /// perform a `gst.Query` on the element.
        pub const query = struct {
            pub fn call(p_class: anytype, p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_query: *gst.Query) c_int {
                return gobject.ext.as(BaseSink.Class, p_class).f_query.?(gobject.ext.as(BaseSink, p_sink), p_query);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_query: *gst.Query) callconv(.c) c_int) void {
                gobject.ext.as(BaseSink.Class, p_class).f_query = @ptrCast(p_implementation);
            }
        };

        /// Called when a buffer should be presented or output, at the
        ///     correct moment if the `gstbase.BaseSink` has been set to sync to the clock.
        pub const render = struct {
            pub fn call(p_class: anytype, p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buffer: *gst.Buffer) gst.FlowReturn {
                return gobject.ext.as(BaseSink.Class, p_class).f_render.?(gobject.ext.as(BaseSink, p_sink), p_buffer);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buffer: *gst.Buffer) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(BaseSink.Class, p_class).f_render = @ptrCast(p_implementation);
            }
        };

        /// Same as `render` but used with buffer lists instead of
        ///     buffers.
        pub const render_list = struct {
            pub fn call(p_class: anytype, p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buffer_list: *gst.BufferList) gst.FlowReturn {
                return gobject.ext.as(BaseSink.Class, p_class).f_render_list.?(gobject.ext.as(BaseSink, p_sink), p_buffer_list);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buffer_list: *gst.BufferList) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(BaseSink.Class, p_class).f_render_list = @ptrCast(p_implementation);
            }
        };

        /// Notify subclass of changed caps
        pub const set_caps = struct {
            pub fn call(p_class: anytype, p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_caps: *gst.Caps) c_int {
                return gobject.ext.as(BaseSink.Class, p_class).f_set_caps.?(gobject.ext.as(BaseSink, p_sink), p_caps);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_caps: *gst.Caps) callconv(.c) c_int) void {
                gobject.ext.as(BaseSink.Class, p_class).f_set_caps = @ptrCast(p_implementation);
            }
        };

        /// Start processing. Ideal for opening resources in the subclass
        pub const start = struct {
            pub fn call(p_class: anytype, p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) c_int {
                return gobject.ext.as(BaseSink.Class, p_class).f_start.?(gobject.ext.as(BaseSink, p_sink));
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) callconv(.c) c_int) void {
                gobject.ext.as(BaseSink.Class, p_class).f_start = @ptrCast(p_implementation);
            }
        };

        /// Stop processing. Subclasses should use this to close resources.
        pub const stop = struct {
            pub fn call(p_class: anytype, p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) c_int {
                return gobject.ext.as(BaseSink.Class, p_class).f_stop.?(gobject.ext.as(BaseSink, p_sink));
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) callconv(.c) c_int) void {
                gobject.ext.as(BaseSink.Class, p_class).f_stop = @ptrCast(p_implementation);
            }
        };

        /// Unlock any pending access to the resource. Subclasses should
        ///     unblock any blocked function ASAP and call `gstbase.BaseSink.waitPreroll`
        pub const unlock = struct {
            pub fn call(p_class: anytype, p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) c_int {
                return gobject.ext.as(BaseSink.Class, p_class).f_unlock.?(gobject.ext.as(BaseSink, p_sink));
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) callconv(.c) c_int) void {
                gobject.ext.as(BaseSink.Class, p_class).f_unlock = @ptrCast(p_implementation);
            }
        };

        /// Clear the previous unlock request. Subclasses should clear
        ///     any state they set during `gstbase.BaseSinkClass.signals.unlock`, and be ready to
        ///     continue where they left off after `gstbase.BaseSink.waitPreroll`,
        ///     `gstbase.BaseSink.wait` or `gst_wait_sink_wait_clock` return or
        ///     `gstbase.BaseSinkClass.signals.render` is called again.
        pub const unlock_stop = struct {
            pub fn call(p_class: anytype, p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) c_int {
                return gobject.ext.as(BaseSink.Class, p_class).f_unlock_stop.?(gobject.ext.as(BaseSink, p_sink));
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) callconv(.c) c_int) void {
                gobject.ext.as(BaseSink.Class, p_class).f_unlock_stop = @ptrCast(p_implementation);
            }
        };

        /// Override this to implement custom logic to wait for the event
        ///     time (for events like EOS and GAP). Subclasses should always first
        ///     chain up to the default implementation.
        pub const wait_event = struct {
            pub fn call(p_class: anytype, p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_event: *gst.Event) gst.FlowReturn {
                return gobject.ext.as(BaseSink.Class, p_class).f_wait_event.?(gobject.ext.as(BaseSink, p_sink), p_event);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_sink: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_event: *gst.Event) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(BaseSink.Class, p_class).f_wait_event = @ptrCast(p_implementation);
            }
        };
    };

    pub const properties = struct {
        /// If set to `TRUE`, the basesink will perform asynchronous state changes.
        /// When set to `FALSE`, the sink will not signal the parent when it prerolls.
        /// Use this option when dealing with sparse streams or when synchronisation is
        /// not required.
        pub const async = struct {
            pub const name = "async";

            pub const Type = c_int;
        };

        /// The amount of bytes to pull when operating in pull mode.
        pub const blocksize = struct {
            pub const name = "blocksize";

            pub const Type = c_uint;
        };

        /// Enable the last-sample property. If `FALSE`, basesink doesn't keep a
        /// reference to the last buffer arrived and the last-sample property is always
        /// set to `NULL`. This can be useful if you need buffers to be released as soon
        /// as possible, eg. if you're using a buffer pool.
        pub const enable_last_sample = struct {
            pub const name = "enable-last-sample";

            pub const Type = c_int;
        };

        /// The last buffer that arrived in the sink and was used for preroll or for
        /// rendering. This property can be used to generate thumbnails. This property
        /// can be `NULL` when the sink has not yet received a buffer.
        pub const last_sample = struct {
            pub const name = "last-sample";

            pub const Type = ?*gst.Sample;
        };

        /// Control the maximum amount of bits that will be rendered per second.
        /// Setting this property to a value bigger than 0 will make the sink delay
        /// rendering of the buffers when it would exceed to max-bitrate.
        pub const max_bitrate = struct {
            pub const name = "max-bitrate";

            pub const Type = u64;
        };

        pub const max_lateness = struct {
            pub const name = "max-lateness";

            pub const Type = i64;
        };

        /// Maximum amount of time (in nanoseconds) that the pipeline can take
        /// for processing the buffer. This is added to the latency of live
        /// pipelines.
        pub const processing_deadline = struct {
            pub const name = "processing-deadline";

            pub const Type = u64;
        };

        pub const qos = struct {
            pub const name = "qos";

            pub const Type = c_int;
        };

        /// The additional delay between synchronisation and actual rendering of the
        /// media. This property will add additional latency to the device in order to
        /// make other sinks compensate for the delay.
        pub const render_delay = struct {
            pub const name = "render-delay";

            pub const Type = u64;
        };

        /// Various `gstbase.BaseSink` statistics. This property returns a `gst.Structure`
        /// with name `application/x-gst-base-sink-stats` with the following fields:
        ///
        /// - "average-rate"  G_TYPE_DOUBLE   average frame rate
        /// - "dropped" G_TYPE_UINT64   Number of dropped frames
        /// - "rendered" G_TYPE_UINT64   Number of rendered frames
        pub const stats = struct {
            pub const name = "stats";

            pub const Type = ?*gst.Structure;
        };

        pub const sync = struct {
            pub const name = "sync";

            pub const Type = c_int;
        };

        /// The time to insert between buffers. This property can be used to control
        /// the maximum amount of buffers per second to render. Setting this property
        /// to a value bigger than 0 will make the sink create THROTTLE QoS events.
        pub const throttle_time = struct {
            pub const name = "throttle-time";

            pub const Type = u64;
        };

        /// Controls the final synchronisation, a negative value will render the buffer
        /// earlier while a positive value delays playback. This property can be
        /// used to fix synchronisation in bad files.
        pub const ts_offset = struct {
            pub const name = "ts-offset";

            pub const Type = i64;
        };
    };

    pub const signals = struct {};

    /// If the `sink` spawns its own thread for pulling buffers from upstream it
    /// should call this method after it has pulled a buffer. If the element needed
    /// to preroll, this function will perform the preroll and will then block
    /// until the element state is changed.
    ///
    /// This function should be called with the PREROLL_LOCK held.
    extern fn gst_base_sink_do_preroll(p_sink: *BaseSink, p_obj: *gst.MiniObject) gst.FlowReturn;
    pub const doPreroll = gst_base_sink_do_preroll;

    /// Get the number of bytes that the sink will pull when it is operating in pull
    /// mode.
    extern fn gst_base_sink_get_blocksize(p_sink: *BaseSink) c_uint;
    pub const getBlocksize = gst_base_sink_get_blocksize;

    /// Checks if `sink` is currently configured to drop buffers which are outside
    /// the current segment
    extern fn gst_base_sink_get_drop_out_of_segment(p_sink: *BaseSink) c_int;
    pub const getDropOutOfSegment = gst_base_sink_get_drop_out_of_segment;

    /// Get the last sample that arrived in the sink and was used for preroll or for
    /// rendering. This property can be used to generate thumbnails.
    ///
    /// The `gst.Caps` on the sample can be used to determine the type of the buffer.
    ///
    /// Free-function: gst_sample_unref
    extern fn gst_base_sink_get_last_sample(p_sink: *BaseSink) ?*gst.Sample;
    pub const getLastSample = gst_base_sink_get_last_sample;

    /// Get the currently configured latency.
    extern fn gst_base_sink_get_latency(p_sink: *BaseSink) gst.ClockTime;
    pub const getLatency = gst_base_sink_get_latency;

    /// Get the maximum amount of bits per second that the sink will render.
    extern fn gst_base_sink_get_max_bitrate(p_sink: *BaseSink) u64;
    pub const getMaxBitrate = gst_base_sink_get_max_bitrate;

    /// Gets the max lateness value. See `gstbase.BaseSink.setMaxLateness` for
    /// more details.
    extern fn gst_base_sink_get_max_lateness(p_sink: *BaseSink) i64;
    pub const getMaxLateness = gst_base_sink_get_max_lateness;

    /// Get the processing deadline of `sink`. see
    /// `gstbase.BaseSink.setProcessingDeadline` for more information about
    /// the processing deadline.
    extern fn gst_base_sink_get_processing_deadline(p_sink: *BaseSink) gst.ClockTime;
    pub const getProcessingDeadline = gst_base_sink_get_processing_deadline;

    /// Get the render delay of `sink`. see `gstbase.BaseSink.setRenderDelay` for more
    /// information about the render delay.
    extern fn gst_base_sink_get_render_delay(p_sink: *BaseSink) gst.ClockTime;
    pub const getRenderDelay = gst_base_sink_get_render_delay;

    /// Return various `gstbase.BaseSink` statistics. This function returns a `gst.Structure`
    /// with name `application/x-gst-base-sink-stats` with the following fields:
    ///
    /// - "average-rate" G_TYPE_DOUBLE   average frame rate
    /// - "dropped" G_TYPE_UINT64   Number of dropped frames
    /// - "rendered" G_TYPE_UINT64   Number of rendered frames
    extern fn gst_base_sink_get_stats(p_sink: *BaseSink) *gst.Structure;
    pub const getStats = gst_base_sink_get_stats;

    /// Checks if `sink` is currently configured to synchronize against the
    /// clock.
    extern fn gst_base_sink_get_sync(p_sink: *BaseSink) c_int;
    pub const getSync = gst_base_sink_get_sync;

    /// Get the time that will be inserted between frames to control the
    /// maximum buffers per second.
    extern fn gst_base_sink_get_throttle_time(p_sink: *BaseSink) u64;
    pub const getThrottleTime = gst_base_sink_get_throttle_time;

    /// Get the synchronisation offset of `sink`.
    extern fn gst_base_sink_get_ts_offset(p_sink: *BaseSink) gst.ClockTimeDiff;
    pub const getTsOffset = gst_base_sink_get_ts_offset;

    /// Checks if `sink` is currently configured to perform asynchronous state
    /// changes to PAUSED.
    extern fn gst_base_sink_is_async_enabled(p_sink: *BaseSink) c_int;
    pub const isAsyncEnabled = gst_base_sink_is_async_enabled;

    /// Checks if `sink` is currently configured to store the last received sample in
    /// the last-sample property.
    extern fn gst_base_sink_is_last_sample_enabled(p_sink: *BaseSink) c_int;
    pub const isLastSampleEnabled = gst_base_sink_is_last_sample_enabled;

    /// Checks if `sink` is currently configured to send Quality-of-Service events
    /// upstream.
    extern fn gst_base_sink_is_qos_enabled(p_sink: *BaseSink) c_int;
    pub const isQosEnabled = gst_base_sink_is_qos_enabled;

    /// Query the sink for the latency parameters. The latency will be queried from
    /// the upstream elements. `live` will be `TRUE` if `sink` is configured to
    /// synchronize against the clock. `upstream_live` will be `TRUE` if an upstream
    /// element is live.
    ///
    /// If both `live` and `upstream_live` are `TRUE`, the sink will want to compensate
    /// for the latency introduced by the upstream elements by setting the
    /// `min_latency` to a strictly positive value.
    ///
    /// This function is mostly used by subclasses.
    extern fn gst_base_sink_query_latency(p_sink: *BaseSink, p_live: ?*c_int, p_upstream_live: ?*c_int, p_min_latency: ?*gst.ClockTime, p_max_latency: ?*gst.ClockTime) c_int;
    pub const queryLatency = gst_base_sink_query_latency;

    /// Configures `sink` to perform all state changes asynchronously. When async is
    /// disabled, the sink will immediately go to PAUSED instead of waiting for a
    /// preroll buffer. This feature is useful if the sink does not synchronize
    /// against the clock or when it is dealing with sparse streams.
    extern fn gst_base_sink_set_async_enabled(p_sink: *BaseSink, p_enabled: c_int) void;
    pub const setAsyncEnabled = gst_base_sink_set_async_enabled;

    /// Set the number of bytes that the sink will pull when it is operating in pull
    /// mode.
    extern fn gst_base_sink_set_blocksize(p_sink: *BaseSink, p_blocksize: c_uint) void;
    pub const setBlocksize = gst_base_sink_set_blocksize;

    /// Configure `sink` to drop buffers which are outside the current segment
    extern fn gst_base_sink_set_drop_out_of_segment(p_sink: *BaseSink, p_drop_out_of_segment: c_int) void;
    pub const setDropOutOfSegment = gst_base_sink_set_drop_out_of_segment;

    /// Configures `sink` to store the last received sample in the last-sample
    /// property.
    extern fn gst_base_sink_set_last_sample_enabled(p_sink: *BaseSink, p_enabled: c_int) void;
    pub const setLastSampleEnabled = gst_base_sink_set_last_sample_enabled;

    /// Set the maximum amount of bits per second that the sink will render.
    extern fn gst_base_sink_set_max_bitrate(p_sink: *BaseSink, p_max_bitrate: u64) void;
    pub const setMaxBitrate = gst_base_sink_set_max_bitrate;

    /// Sets the new max lateness value to `max_lateness`. This value is
    /// used to decide if a buffer should be dropped or not based on the
    /// buffer timestamp and the current clock time. A value of -1 means
    /// an unlimited time.
    extern fn gst_base_sink_set_max_lateness(p_sink: *BaseSink, p_max_lateness: i64) void;
    pub const setMaxLateness = gst_base_sink_set_max_lateness;

    /// Maximum amount of time (in nanoseconds) that the pipeline can take
    /// for processing the buffer. This is added to the latency of live
    /// pipelines.
    ///
    /// This function is usually called by subclasses.
    extern fn gst_base_sink_set_processing_deadline(p_sink: *BaseSink, p_processing_deadline: gst.ClockTime) void;
    pub const setProcessingDeadline = gst_base_sink_set_processing_deadline;

    /// Configures `sink` to send Quality-of-Service events upstream.
    extern fn gst_base_sink_set_qos_enabled(p_sink: *BaseSink, p_enabled: c_int) void;
    pub const setQosEnabled = gst_base_sink_set_qos_enabled;

    /// Set the render delay in `sink` to `delay`. The render delay is the time
    /// between actual rendering of a buffer and its synchronisation time. Some
    /// devices might delay media rendering which can be compensated for with this
    /// function.
    ///
    /// After calling this function, this sink will report additional latency and
    /// other sinks will adjust their latency to delay the rendering of their media.
    ///
    /// This function is usually called by subclasses.
    extern fn gst_base_sink_set_render_delay(p_sink: *BaseSink, p_delay: gst.ClockTime) void;
    pub const setRenderDelay = gst_base_sink_set_render_delay;

    /// Configures `sink` to synchronize on the clock or not. When
    /// `sync` is `FALSE`, incoming samples will be played as fast as
    /// possible. If `sync` is `TRUE`, the timestamps of the incoming
    /// buffers will be used to schedule the exact render time of its
    /// contents.
    extern fn gst_base_sink_set_sync(p_sink: *BaseSink, p_sync: c_int) void;
    pub const setSync = gst_base_sink_set_sync;

    /// Set the time that will be inserted between rendered buffers. This
    /// can be used to control the maximum buffers per second that the sink
    /// will render.
    extern fn gst_base_sink_set_throttle_time(p_sink: *BaseSink, p_throttle: u64) void;
    pub const setThrottleTime = gst_base_sink_set_throttle_time;

    /// Adjust the synchronisation of `sink` with `offset`. A negative value will
    /// render buffers earlier than their timestamp. A positive value will delay
    /// rendering. This function can be used to fix playback of badly timestamped
    /// buffers.
    extern fn gst_base_sink_set_ts_offset(p_sink: *BaseSink, p_offset: gst.ClockTimeDiff) void;
    pub const setTsOffset = gst_base_sink_set_ts_offset;

    /// This function will wait for preroll to complete and will then block until `time`
    /// is reached. It is usually called by subclasses that use their own internal
    /// synchronisation but want to let some synchronization (like EOS) be handled
    /// by the base class.
    ///
    /// This function should only be called with the PREROLL_LOCK held (like when
    /// receiving an EOS event in the ::event vmethod or when handling buffers in
    /// ::render).
    ///
    /// The `time` argument should be the running_time of when the timeout should happen
    /// and will be adjusted with any latency and offset configured in the sink.
    extern fn gst_base_sink_wait(p_sink: *BaseSink, p_time: gst.ClockTime, p_jitter: ?*gst.ClockTimeDiff) gst.FlowReturn;
    pub const wait = gst_base_sink_wait;

    /// This function will block until `time` is reached. It is usually called by
    /// subclasses that use their own internal synchronisation.
    ///
    /// If `time` is not valid, no synchronisation is done and `GST_CLOCK_BADTIME` is
    /// returned. Likewise, if synchronisation is disabled in the element or there
    /// is no clock, no synchronisation is done and `GST_CLOCK_BADTIME` is returned.
    ///
    /// This function should only be called with the PREROLL_LOCK held, like when
    /// receiving an EOS event in the `gstbase.BaseSinkClass.signals.event` vmethod or when
    /// receiving a buffer in
    /// the `gstbase.BaseSinkClass.signals.render` vmethod.
    ///
    /// The `time` argument should be the running_time of when this method should
    /// return and is not adjusted with any latency or offset configured in the
    /// sink.
    extern fn gst_base_sink_wait_clock(p_sink: *BaseSink, p_time: gst.ClockTime, p_jitter: ?*gst.ClockTimeDiff) gst.ClockReturn;
    pub const waitClock = gst_base_sink_wait_clock;

    /// If the `gstbase.BaseSinkClass.signals.render` method performs its own synchronisation
    /// against the clock it must unblock when going from PLAYING to the PAUSED state
    /// and call this method before continuing to render the remaining data.
    ///
    /// If the `gstbase.BaseSinkClass.signals.render` method can block on something else than
    /// the clock, it must also be ready to unblock immediately on
    /// the `gstbase.BaseSinkClass.signals.unlock` method and cause the
    /// `gstbase.BaseSinkClass.signals.render` method to immediately call this function.
    /// In this case, the subclass must be prepared to continue rendering where it
    /// left off if this function returns `GST_FLOW_OK`.
    ///
    /// This function will block until a state change to PLAYING happens (in which
    /// case this function returns `GST_FLOW_OK`) or the processing must be stopped due
    /// to a state change to READY or a FLUSH event (in which case this function
    /// returns `GST_FLOW_FLUSHING`).
    ///
    /// This function should only be called with the PREROLL_LOCK held, like in the
    /// render function.
    extern fn gst_base_sink_wait_preroll(p_sink: *BaseSink) gst.FlowReturn;
    pub const waitPreroll = gst_base_sink_wait_preroll;

    extern fn gst_base_sink_get_type() usize;
    pub const getGObjectType = gst_base_sink_get_type;

    extern fn g_object_ref(p_self: *gstbase.BaseSink) void;
    pub const ref = g_object_ref;

    extern fn g_object_unref(p_self: *gstbase.BaseSink) void;
    pub const unref = g_object_unref;

    pub fn as(p_instance: *BaseSink, comptime P_T: type) *P_T {
        return gobject.ext.as(P_T, p_instance);
    }

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// This is a generic base class for source elements. The following
/// types of sources are supported:
///
///   * random access sources like files
///   * seekable sources
///   * live sources
///
/// The source can be configured to operate in any `gst.Format` with the
/// `gstbase.BaseSrc.setFormat` method. The currently set format determines
/// the format of the internal `gst.Segment` and any `GST_EVENT_SEGMENT`
/// events. The default format for `gstbase.BaseSrc` is `GST_FORMAT_BYTES`.
///
/// `gstbase.BaseSrc` always supports push mode scheduling. If the following
/// conditions are met, it also supports pull mode scheduling:
///
///   * The format is set to `GST_FORMAT_BYTES` (default).
///   * `gstbase.BaseSrcClass.signals.is_seekable` returns `TRUE`.
///
/// If all the conditions are met for operating in pull mode, `gstbase.BaseSrc` is
/// automatically seekable in push mode as well. The following conditions must
/// be met to make the element seekable in push mode when the format is not
/// `GST_FORMAT_BYTES`:
///
/// * `gstbase.BaseSrcClass.signals.is_seekable` returns `TRUE`.
/// * `gstbase.BaseSrcClass.signals.query` can convert all supported seek formats to the
///   internal format as set with `gstbase.BaseSrc.setFormat`.
/// * `gstbase.BaseSrcClass.signals.do_seek` is implemented, performs the seek and returns
///    `TRUE`.
///
/// When the element does not meet the requirements to operate in pull mode, the
/// offset and length in the `gstbase.BaseSrcClass.signals.create` method should be ignored.
/// It is recommended to subclass `gstbase.PushSrc` instead, in this situation. If the
/// element can operate in pull mode but only with specific offsets and
/// lengths, it is allowed to generate an error when the wrong values are passed
/// to the `gstbase.BaseSrcClass.signals.create` function.
///
/// `gstbase.BaseSrc` has support for live sources. Live sources are sources that when
/// paused discard data, such as audio or video capture devices. A typical live
/// source also produces data at a fixed rate and thus provides a clock to publish
/// this rate.
/// Use `gstbase.BaseSrc.setLive` to activate the live source mode.
///
/// A live source does not produce data in the PAUSED state. This means that the
/// `gstbase.BaseSrcClass.signals.create` method will not be called in PAUSED but only in
/// PLAYING. To signal the pipeline that the element will not produce data, the
/// return value from the READY to PAUSED state will be
/// `GST_STATE_CHANGE_NO_PREROLL`.
///
/// A typical live source will timestamp the buffers it creates with the
/// current running time of the pipeline. This is one reason why a live source
/// can only produce data in the PLAYING state, when the clock is actually
/// distributed and running.
///
/// Live sources that synchronize and block on the clock (an audio source, for
/// example) can use `gstbase.BaseSrc.waitPlaying` when the
/// `gstbase.BaseSrcClass.signals.create` function was interrupted by a state change to
/// PAUSED.
///
/// The `gstbase.BaseSrcClass.signals.get_times` method can be used to implement pseudo-live
/// sources. It only makes sense to implement the `gstbase.BaseSrcClass.signals.get_times`
/// function if the source is a live source. The `gstbase.BaseSrcClass.signals.get_times`
/// function should return timestamps starting from 0, as if it were a non-live
/// source. The base class will make sure that the timestamps are transformed
/// into the current running_time. The base source will then wait for the
/// calculated running_time before pushing out the buffer.
///
/// For live sources, the base class will by default report a latency of 0.
/// For pseudo live sources, the base class will by default measure the difference
/// between the first buffer timestamp and the start time of get_times and will
/// report this value as the latency.
/// Subclasses should override the query function when this behaviour is not
/// acceptable.
///
/// There is only support in `gstbase.BaseSrc` for exactly one source pad, which
/// should be named "src". A source implementation (subclass of `gstbase.BaseSrc`)
/// should install a pad template in its class_init function, like so:
/// ```
/// static void
/// my_element_class_init (GstMyElementClass *klass)
/// {
///   GstElementClass *gstelement_class = GST_ELEMENT_CLASS (klass);
///   // srctemplate should be a `gst.StaticPadTemplate` with direction
///   // `GST_PAD_SRC` and name "src"
///   gst_element_class_add_static_pad_template (gstelement_class, &srctemplate);
///
///   gst_element_class_set_static_metadata (gstelement_class,
///      "Source name",
///      "Source",
///      "My Source element",
///      "The author <my.sink`my`.email>");
/// }
/// ```
///
/// ## Controlled shutdown of live sources in applications
///
/// Applications that record from a live source may want to stop recording
/// in a controlled way, so that the recording is stopped, but the data
/// already in the pipeline is processed to the end (remember that many live
/// sources would go on recording forever otherwise). For that to happen the
/// application needs to make the source stop recording and send an EOS
/// event down the pipeline. The application would then wait for an
/// EOS message posted on the pipeline's bus to know when all data has
/// been processed and the pipeline can safely be stopped.
///
/// An application may send an EOS event to a source element to make it
/// perform the EOS logic (send EOS event downstream or post a
/// `GST_MESSAGE_SEGMENT_DONE` on the bus). This can typically be done
/// with the `gst.Element.sendEvent` function on the element or its parent bin.
///
/// After the EOS has been sent to the element, the application should wait for
/// an EOS message to be posted on the pipeline's bus. Once this EOS message is
/// received, it may safely shut down the entire pipeline.
pub const BaseSrc = extern struct {
    pub const Parent = gst.Element;
    pub const Implements = [_]type{};
    pub const Class = gstbase.BaseSrcClass;
    f_element: gst.Element,
    f_srcpad: ?*gst.Pad,
    f_live_lock: glib.Mutex,
    f_live_cond: glib.Cond,
    f_is_live: c_int,
    f_live_running: c_int,
    f_blocksize: c_uint,
    f_can_activate_push: c_int,
    f_random_access: c_int,
    f_clock_id: gst.ClockID,
    f_segment: gst.Segment,
    f_need_newsegment: c_int,
    f_num_buffers: c_int,
    f_num_buffers_left: c_int,
    f_typefind: c_int,
    f_running: c_int,
    f_pending_seek: ?*gst.Event,
    f_priv: ?*gstbase.BaseSrcPrivate,
    f__gst_reserved: [20]*anyopaque,

    pub const virtual_methods = struct {
        /// Ask the subclass to allocate an output buffer with `offset` and `size`, the default
        /// implementation will use the negotiated allocator.
        pub const alloc = struct {
            pub fn call(p_class: anytype, p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_offset: u64, p_size: c_uint, p_buf: ?**gst.Buffer) gst.FlowReturn {
                return gobject.ext.as(BaseSrc.Class, p_class).f_alloc.?(gobject.ext.as(BaseSrc, p_src), p_offset, p_size, p_buf);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_offset: u64, p_size: c_uint, p_buf: ?**gst.Buffer) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(BaseSrc.Class, p_class).f_alloc = @ptrCast(p_implementation);
            }
        };

        /// Ask the subclass to create a buffer with `offset` and `size`, the default
        /// implementation will call alloc if no allocated `buf` is provided and then call fill.
        pub const create = struct {
            pub fn call(p_class: anytype, p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_offset: u64, p_size: c_uint, p_buf: ?**gst.Buffer) gst.FlowReturn {
                return gobject.ext.as(BaseSrc.Class, p_class).f_create.?(gobject.ext.as(BaseSrc, p_src), p_offset, p_size, p_buf);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_offset: u64, p_size: c_uint, p_buf: ?**gst.Buffer) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(BaseSrc.Class, p_class).f_create = @ptrCast(p_implementation);
            }
        };

        /// configure the allocation query
        pub const decide_allocation = struct {
            pub fn call(p_class: anytype, p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_query: *gst.Query) c_int {
                return gobject.ext.as(BaseSrc.Class, p_class).f_decide_allocation.?(gobject.ext.as(BaseSrc, p_src), p_query);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_query: *gst.Query) callconv(.c) c_int) void {
                gobject.ext.as(BaseSrc.Class, p_class).f_decide_allocation = @ptrCast(p_implementation);
            }
        };

        /// Perform seeking on the resource to the indicated segment.
        pub const do_seek = struct {
            pub fn call(p_class: anytype, p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_segment: *gst.Segment) c_int {
                return gobject.ext.as(BaseSrc.Class, p_class).f_do_seek.?(gobject.ext.as(BaseSrc, p_src), p_segment);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_segment: *gst.Segment) callconv(.c) c_int) void {
                gobject.ext.as(BaseSrc.Class, p_class).f_do_seek = @ptrCast(p_implementation);
            }
        };

        /// Override this to implement custom event handling.
        pub const event = struct {
            pub fn call(p_class: anytype, p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_event: *gst.Event) c_int {
                return gobject.ext.as(BaseSrc.Class, p_class).f_event.?(gobject.ext.as(BaseSrc, p_src), p_event);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_event: *gst.Event) callconv(.c) c_int) void {
                gobject.ext.as(BaseSrc.Class, p_class).f_event = @ptrCast(p_implementation);
            }
        };

        /// Ask the subclass to fill the buffer with data for offset and size. The
        ///   passed buffer is guaranteed to hold the requested amount of bytes.
        pub const fill = struct {
            pub fn call(p_class: anytype, p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_offset: u64, p_size: c_uint, p_buf: *gst.Buffer) gst.FlowReturn {
                return gobject.ext.as(BaseSrc.Class, p_class).f_fill.?(gobject.ext.as(BaseSrc, p_src), p_offset, p_size, p_buf);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_offset: u64, p_size: c_uint, p_buf: *gst.Buffer) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(BaseSrc.Class, p_class).f_fill = @ptrCast(p_implementation);
            }
        };

        /// Called if, in negotiation, caps need fixating.
        pub const fixate = struct {
            pub fn call(p_class: anytype, p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_caps: *gst.Caps) *gst.Caps {
                return gobject.ext.as(BaseSrc.Class, p_class).f_fixate.?(gobject.ext.as(BaseSrc, p_src), p_caps);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_caps: *gst.Caps) callconv(.c) *gst.Caps) void {
                gobject.ext.as(BaseSrc.Class, p_class).f_fixate = @ptrCast(p_implementation);
            }
        };

        /// Called to get the caps to report.
        pub const get_caps = struct {
            pub fn call(p_class: anytype, p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_filter: ?*gst.Caps) *gst.Caps {
                return gobject.ext.as(BaseSrc.Class, p_class).f_get_caps.?(gobject.ext.as(BaseSrc, p_src), p_filter);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_filter: ?*gst.Caps) callconv(.c) *gst.Caps) void {
                gobject.ext.as(BaseSrc.Class, p_class).f_get_caps = @ptrCast(p_implementation);
            }
        };

        /// Get the total size of the resource in the format set by
        /// `gstbase.BaseSrc.setFormat`.
        pub const get_size = struct {
            pub fn call(p_class: anytype, p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_size: *u64) c_int {
                return gobject.ext.as(BaseSrc.Class, p_class).f_get_size.?(gobject.ext.as(BaseSrc, p_src), p_size);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_size: *u64) callconv(.c) c_int) void {
                gobject.ext.as(BaseSrc.Class, p_class).f_get_size = @ptrCast(p_implementation);
            }
        };

        /// Given `buffer`, return `start` and `end` time when it should be pushed
        /// out. The base class will sync on the clock using these times.
        pub const get_times = struct {
            pub fn call(p_class: anytype, p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buffer: *gst.Buffer, p_start: *gst.ClockTime, p_end: *gst.ClockTime) void {
                return gobject.ext.as(BaseSrc.Class, p_class).f_get_times.?(gobject.ext.as(BaseSrc, p_src), p_buffer, p_start, p_end);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buffer: *gst.Buffer, p_start: *gst.ClockTime, p_end: *gst.ClockTime) callconv(.c) void) void {
                gobject.ext.as(BaseSrc.Class, p_class).f_get_times = @ptrCast(p_implementation);
            }
        };

        /// Check if the source can seek
        pub const is_seekable = struct {
            pub fn call(p_class: anytype, p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) c_int {
                return gobject.ext.as(BaseSrc.Class, p_class).f_is_seekable.?(gobject.ext.as(BaseSrc, p_src));
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) callconv(.c) c_int) void {
                gobject.ext.as(BaseSrc.Class, p_class).f_is_seekable = @ptrCast(p_implementation);
            }
        };

        /// Negotiates src pad caps with downstream elements.
        /// Unmarks GST_PAD_FLAG_NEED_RECONFIGURE in any case. But marks it again
        /// if `gstbase.BaseSrcClass.signals.negotiate` fails.
        ///
        /// Do not call this in the `gstbase.BaseSrcClass.signals.fill` vmethod. Call this in
        /// `gstbase.BaseSrcClass.signals.create` or in `gstbase.BaseSrcClass.signals.alloc`, _before_ any
        /// buffer is allocated.
        pub const negotiate = struct {
            pub fn call(p_class: anytype, p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) c_int {
                return gobject.ext.as(BaseSrc.Class, p_class).f_negotiate.?(gobject.ext.as(BaseSrc, p_src));
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) callconv(.c) c_int) void {
                gobject.ext.as(BaseSrc.Class, p_class).f_negotiate = @ptrCast(p_implementation);
            }
        };

        /// Prepare the `gst.Segment` that will be passed to the
        ///   `gstbase.BaseSrcClass.signals.do_seek` vmethod for executing a seek
        ///   request. Sub-classes should override this if they support seeking in
        ///   formats other than the configured native format. By default, it tries to
        ///   convert the seek arguments to the configured native format and prepare a
        ///   segment in that format.
        pub const prepare_seek_segment = struct {
            pub fn call(p_class: anytype, p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_seek: *gst.Event, p_segment: *gst.Segment) c_int {
                return gobject.ext.as(BaseSrc.Class, p_class).f_prepare_seek_segment.?(gobject.ext.as(BaseSrc, p_src), p_seek, p_segment);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_seek: *gst.Event, p_segment: *gst.Segment) callconv(.c) c_int) void {
                gobject.ext.as(BaseSrc.Class, p_class).f_prepare_seek_segment = @ptrCast(p_implementation);
            }
        };

        /// Handle a requested query.
        pub const query = struct {
            pub fn call(p_class: anytype, p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_query: *gst.Query) c_int {
                return gobject.ext.as(BaseSrc.Class, p_class).f_query.?(gobject.ext.as(BaseSrc, p_src), p_query);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_query: *gst.Query) callconv(.c) c_int) void {
                gobject.ext.as(BaseSrc.Class, p_class).f_query = @ptrCast(p_implementation);
            }
        };

        /// Set new caps on the basesrc source pad.
        pub const set_caps = struct {
            pub fn call(p_class: anytype, p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_caps: *gst.Caps) c_int {
                return gobject.ext.as(BaseSrc.Class, p_class).f_set_caps.?(gobject.ext.as(BaseSrc, p_src), p_caps);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_caps: *gst.Caps) callconv(.c) c_int) void {
                gobject.ext.as(BaseSrc.Class, p_class).f_set_caps = @ptrCast(p_implementation);
            }
        };

        /// Start processing. Subclasses should open resources and prepare
        ///    to produce data. Implementation should call `gstbase.BaseSrc.startComplete`
        ///    when the operation completes, either from the current thread or any other
        ///    thread that finishes the start operation asynchronously.
        pub const start = struct {
            pub fn call(p_class: anytype, p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) c_int {
                return gobject.ext.as(BaseSrc.Class, p_class).f_start.?(gobject.ext.as(BaseSrc, p_src));
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) callconv(.c) c_int) void {
                gobject.ext.as(BaseSrc.Class, p_class).f_start = @ptrCast(p_implementation);
            }
        };

        /// Stop processing. Subclasses should use this to close resources.
        pub const stop = struct {
            pub fn call(p_class: anytype, p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) c_int {
                return gobject.ext.as(BaseSrc.Class, p_class).f_stop.?(gobject.ext.as(BaseSrc, p_src));
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) callconv(.c) c_int) void {
                gobject.ext.as(BaseSrc.Class, p_class).f_stop = @ptrCast(p_implementation);
            }
        };

        /// Unlock any pending access to the resource. Subclasses should unblock
        ///    any blocked function ASAP. In particular, any ``create`` function in
        ///    progress should be unblocked and should return GST_FLOW_FLUSHING. Any
        ///    future `gstbase.BaseSrcClass.signals.create` function call should also return
        ///    GST_FLOW_FLUSHING until the `gstbase.BaseSrcClass.signals.unlock_stop` function has
        ///    been called.
        pub const unlock = struct {
            pub fn call(p_class: anytype, p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) c_int {
                return gobject.ext.as(BaseSrc.Class, p_class).f_unlock.?(gobject.ext.as(BaseSrc, p_src));
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) callconv(.c) c_int) void {
                gobject.ext.as(BaseSrc.Class, p_class).f_unlock = @ptrCast(p_implementation);
            }
        };

        /// Clear the previous unlock request. Subclasses should clear any
        ///    state they set during `gstbase.BaseSrcClass.signals.unlock`, such as clearing command
        ///    queues.
        pub const unlock_stop = struct {
            pub fn call(p_class: anytype, p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) c_int {
                return gobject.ext.as(BaseSrc.Class, p_class).f_unlock_stop.?(gobject.ext.as(BaseSrc, p_src));
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) callconv(.c) c_int) void {
                gobject.ext.as(BaseSrc.Class, p_class).f_unlock_stop = @ptrCast(p_implementation);
            }
        };
    };

    pub const properties = struct {
        /// See `gstbase.BaseSrc.setAutomaticEos`
        pub const automatic_eos = struct {
            pub const name = "automatic-eos";

            pub const Type = c_int;
        };

        pub const blocksize = struct {
            pub const name = "blocksize";

            pub const Type = c_uint;
        };

        pub const do_timestamp = struct {
            pub const name = "do-timestamp";

            pub const Type = c_int;
        };

        pub const num_buffers = struct {
            pub const name = "num-buffers";

            pub const Type = c_int;
        };

        pub const typefind = struct {
            pub const name = "typefind";

            pub const Type = c_int;
        };
    };

    pub const signals = struct {};

    /// Lets `gstbase.BaseSrc` sub-classes to know the memory `allocator`
    /// used by the base class and its `params`.
    ///
    /// Unref the `allocator` after usage.
    extern fn gst_base_src_get_allocator(p_src: *BaseSrc, p_allocator: ?**gst.Allocator, p_params: ?*gst.AllocationParams) void;
    pub const getAllocator = gst_base_src_get_allocator;

    /// Get the number of bytes that `src` will push out with each buffer.
    extern fn gst_base_src_get_blocksize(p_src: *BaseSrc) c_uint;
    pub const getBlocksize = gst_base_src_get_blocksize;

    extern fn gst_base_src_get_buffer_pool(p_src: *BaseSrc) ?*gst.BufferPool;
    pub const getBufferPool = gst_base_src_get_buffer_pool;

    /// Query if `src` timestamps outgoing buffers based on the current running_time.
    extern fn gst_base_src_get_do_timestamp(p_src: *BaseSrc) c_int;
    pub const getDoTimestamp = gst_base_src_get_do_timestamp;

    /// Get the current async behaviour of `src`. See also `gstbase.BaseSrc.setAsync`.
    extern fn gst_base_src_is_async(p_src: *BaseSrc) c_int;
    pub const isAsync = gst_base_src_is_async;

    /// Check if an element is in live mode.
    extern fn gst_base_src_is_live(p_src: *BaseSrc) c_int;
    pub const isLive = gst_base_src_is_live;

    /// Negotiates src pad caps with downstream elements.
    /// Unmarks GST_PAD_FLAG_NEED_RECONFIGURE in any case. But marks it again
    /// if `gstbase.BaseSrcClass.signals.negotiate` fails.
    ///
    /// Do not call this in the `gstbase.BaseSrcClass.signals.fill` vmethod. Call this in
    /// `gstbase.BaseSrcClass.signals.create` or in `gstbase.BaseSrcClass.signals.alloc`, _before_ any
    /// buffer is allocated.
    extern fn gst_base_src_negotiate(p_src: *BaseSrc) c_int;
    pub const negotiate = gst_base_src_negotiate;

    /// Prepare a new seamless segment for emission downstream. This function must
    /// only be called by derived sub-classes, and only from the `gstbase.BaseSrcClass.signals.create` function,
    /// as the stream-lock needs to be held.
    ///
    /// The format for the new segment will be the current format of the source, as
    /// configured with `gstbase.BaseSrc.setFormat`
    extern fn gst_base_src_new_seamless_segment(p_src: *BaseSrc, p_start: i64, p_stop: i64, p_time: i64) c_int;
    pub const newSeamlessSegment = gst_base_src_new_seamless_segment;

    /// Prepare a new segment for emission downstream. This function must
    /// only be called by derived sub-classes, and only from the `gstbase.BaseSrcClass.signals.create` function,
    /// as the stream-lock needs to be held.
    ///
    /// The format for the `segment` must be identical with the current format
    /// of the source, as configured with `gstbase.BaseSrc.setFormat`.
    ///
    /// The format of `src` must not be `GST_FORMAT_UNDEFINED` and the format
    /// should be configured via `gstbase.BaseSrc.setFormat` before calling this method.
    extern fn gst_base_src_new_segment(p_src: *BaseSrc, p_segment: *const gst.Segment) c_int;
    pub const newSegment = gst_base_src_new_segment;

    /// Send a new segment downstream. This function must
    /// only be called by derived sub-classes, and only from the `gstbase.BaseSrcClass.signals.create` function,
    /// as the stream-lock needs to be held.
    /// This method also requires that an out caps has been configured, so
    /// `gstbase.BaseSrc.setCaps` needs to have been called before.
    ///
    /// The format for the `segment` must be identical with the current format
    /// of the source, as configured with `gstbase.BaseSrc.setFormat`.
    ///
    /// The format of `src` must not be `GST_FORMAT_UNDEFINED` and the format
    /// should be configured via `gstbase.BaseSrc.setFormat` before calling this method.
    ///
    /// This is a variant of `gstbase.BaseSrc.newSegment` sending the segment right away,
    /// which can be useful to ensure events ordering.
    extern fn gst_base_src_push_segment(p_src: *BaseSrc, p_segment: *const gst.Segment) c_int;
    pub const pushSegment = gst_base_src_push_segment;

    /// Query the source for the latency parameters. `live` will be `TRUE` when `src` is
    /// configured as a live source. `min_latency` and `max_latency` will be set
    /// to the difference between the running time and the timestamp of the first
    /// buffer.
    ///
    /// This function is mostly used by subclasses.
    extern fn gst_base_src_query_latency(p_src: *BaseSrc, p_live: ?*c_int, p_min_latency: ?*gst.ClockTime, p_max_latency: ?*gst.ClockTime) c_int;
    pub const queryLatency = gst_base_src_query_latency;

    /// Configure async behaviour in `src`, no state change will block. The open,
    /// close, start, stop, play and pause virtual methods will be executed in a
    /// different thread and are thus allowed to perform blocking operations. Any
    /// blocking operation should be unblocked with the unlock vmethod.
    extern fn gst_base_src_set_async(p_src: *BaseSrc, p_async: c_int) void;
    pub const setAsync = gst_base_src_set_async;

    /// If `automatic_eos` is `TRUE`, `src` will automatically go EOS if a buffer
    /// after the total size is returned. By default this is `TRUE` but sources
    /// that can't return an authoritative size and only know that they're EOS
    /// when trying to read more should set this to `FALSE`.
    ///
    /// When `src` operates in `GST_FORMAT_TIME`, `gstbase.BaseSrc` will send an EOS
    /// when a buffer outside of the currently configured segment is pushed if
    /// `automatic_eos` is `TRUE`. Since 1.16, if `automatic_eos` is `FALSE` an
    /// EOS will be pushed only when the `gstbase.BaseSrcClass.signals.create` implementation
    /// returns `GST_FLOW_EOS`.
    extern fn gst_base_src_set_automatic_eos(p_src: *BaseSrc, p_automatic_eos: c_int) void;
    pub const setAutomaticEos = gst_base_src_set_automatic_eos;

    /// Set the number of bytes that `src` will push out with each buffer. When
    /// `blocksize` is set to -1, a default length will be used.
    extern fn gst_base_src_set_blocksize(p_src: *BaseSrc, p_blocksize: c_uint) void;
    pub const setBlocksize = gst_base_src_set_blocksize;

    /// Set new caps on the basesrc source pad.
    extern fn gst_base_src_set_caps(p_src: *BaseSrc, p_caps: *gst.Caps) c_int;
    pub const setCaps = gst_base_src_set_caps;

    /// Configure `src` to automatically timestamp outgoing buffers based on the
    /// current running_time of the pipeline. This property is mostly useful for live
    /// sources.
    extern fn gst_base_src_set_do_timestamp(p_src: *BaseSrc, p_timestamp: c_int) void;
    pub const setDoTimestamp = gst_base_src_set_do_timestamp;

    /// If not `dynamic`, size is only updated when needed, such as when trying to
    /// read past current tracked size.  Otherwise, size is checked for upon each
    /// read.
    extern fn gst_base_src_set_dynamic_size(p_src: *BaseSrc, p_dynamic: c_int) void;
    pub const setDynamicSize = gst_base_src_set_dynamic_size;

    /// Sets the default format of the source. This will be the format used
    /// for sending SEGMENT events and for performing seeks.
    ///
    /// If a format of GST_FORMAT_BYTES is set, the element will be able to
    /// operate in pull mode if the `gstbase.BaseSrcClass.signals.is_seekable` returns `TRUE`.
    ///
    /// This function must only be called in states < `GST_STATE_PAUSED`.
    extern fn gst_base_src_set_format(p_src: *BaseSrc, p_format: gst.Format) void;
    pub const setFormat = gst_base_src_set_format;

    /// If the element listens to a live source, `live` should
    /// be set to `TRUE`.
    ///
    /// A live source will not produce data in the PAUSED state and
    /// will therefore not be able to participate in the PREROLL phase
    /// of a pipeline. To signal this fact to the application and the
    /// pipeline, the state change return value of the live source will
    /// be GST_STATE_CHANGE_NO_PREROLL.
    extern fn gst_base_src_set_live(p_src: *BaseSrc, p_live: c_int) void;
    pub const setLive = gst_base_src_set_live;

    /// Complete an asynchronous start operation. When the subclass overrides the
    /// start method, it should call `gstbase.BaseSrc.startComplete` when the start
    /// operation completes either from the same thread or from an asynchronous
    /// helper thread.
    extern fn gst_base_src_start_complete(p_basesrc: *BaseSrc, p_ret: gst.FlowReturn) void;
    pub const startComplete = gst_base_src_start_complete;

    /// Wait until the start operation completes.
    extern fn gst_base_src_start_wait(p_basesrc: *BaseSrc) gst.FlowReturn;
    pub const startWait = gst_base_src_start_wait;

    /// Subclasses can call this from their create virtual method implementation
    /// to submit a buffer list to be pushed out later. This is useful in
    /// cases where the create function wants to produce multiple buffers to be
    /// pushed out in one go in form of a `gst.BufferList`, which can reduce overhead
    /// drastically, especially for packetised inputs (for data streams where
    /// the packetisation/chunking is not important it is usually more efficient
    /// to return larger buffers instead).
    ///
    /// Subclasses that use this function from their create function must return
    /// `GST_FLOW_OK` and no buffer from their create virtual method implementation.
    /// If a buffer is returned after a buffer list has also been submitted via this
    /// function the behaviour is undefined.
    ///
    /// Subclasses must only call this function once per create function call and
    /// subclasses must only call this function when the source operates in push
    /// mode.
    extern fn gst_base_src_submit_buffer_list(p_src: *BaseSrc, p_buffer_list: *gst.BufferList) void;
    pub const submitBufferList = gst_base_src_submit_buffer_list;

    /// If the `gstbase.BaseSrcClass.signals.create` method performs its own synchronisation
    /// against the clock it must unblock when going from PLAYING to the PAUSED state
    /// and call this method before continuing to produce the remaining data.
    ///
    /// This function will block until a state change to PLAYING happens (in which
    /// case this function returns `GST_FLOW_OK`) or the processing must be stopped due
    /// to a state change to READY or a FLUSH event (in which case this function
    /// returns `GST_FLOW_FLUSHING`).
    extern fn gst_base_src_wait_playing(p_src: *BaseSrc) gst.FlowReturn;
    pub const waitPlaying = gst_base_src_wait_playing;

    extern fn gst_base_src_get_type() usize;
    pub const getGObjectType = gst_base_src_get_type;

    extern fn g_object_ref(p_self: *gstbase.BaseSrc) void;
    pub const ref = g_object_ref;

    extern fn g_object_unref(p_self: *gstbase.BaseSrc) void;
    pub const unref = g_object_unref;

    pub fn as(p_instance: *BaseSrc, comptime P_T: type) *P_T {
        return gobject.ext.as(P_T, p_instance);
    }

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// This base class is for filter elements that process data. Elements
/// that are suitable for implementation using `gstbase.BaseTransform` are ones
/// where the size and caps of the output is known entirely from the input
/// caps and buffer sizes. These include elements that directly transform
/// one buffer into another, modify the contents of a buffer in-place, as
/// well as elements that collate multiple input buffers into one output buffer,
/// or that expand one input buffer into multiple output buffers. See below
/// for more concrete use cases.
///
/// It provides for:
///
/// * one sinkpad and one srcpad
/// * Possible formats on sink and source pad implemented
///   with custom transform_caps function. By default uses
///   same format on sink and source.
///
/// * Handles state changes
/// * Does flushing
/// * Push mode
/// * Pull mode if the sub-class transform can operate on arbitrary data
///
/// # Use Cases
///
/// ## Passthrough mode
///
///   * Element has no interest in modifying the buffer. It may want to inspect it,
///     in which case the element should have a transform_ip function. If there
///     is no transform_ip function in passthrough mode, the buffer is pushed
///     intact.
///
///   * The `gstbase.BaseTransformClass.passthrough_on_same_caps` variable
///     will automatically set/unset passthrough based on whether the
///     element negotiates the same caps on both pads.
///
///   * `gstbase.BaseTransformClass.passthrough_on_same_caps` on an element that
///     doesn't implement a transform_caps function is useful for elements that
///     only inspect data (such as level)
///
///   * Example elements
///
///     * Level
///     * Videoscale, audioconvert, videoconvert, audioresample in certain modes.
///
/// ## Modifications in-place - input buffer and output buffer are the same thing.
///
/// * The element must implement a transform_ip function.
/// * Output buffer size must <= input buffer size
/// * If the always_in_place flag is set, non-writable buffers will be copied
///   and passed to the transform_ip function, otherwise a new buffer will be
///   created and the transform function called.
///
/// * Incoming writable buffers will be passed to the transform_ip function
///   immediately.
/// * only implementing transform_ip and not transform implies always_in_place = `TRUE`
///
///   * Example elements:
///     * Volume
///     * Audioconvert in certain modes (signed/unsigned conversion)
///     * videoconvert in certain modes (endianness swapping)
///
/// ## Modifications only to the caps/metadata of a buffer
///
/// * The element does not require writable data, but non-writable buffers
///   should be subbuffered so that the meta-information can be replaced.
///
/// * Elements wishing to operate in this mode should replace the
///   prepare_output_buffer method to create subbuffers of the input buffer
///   and set always_in_place to `TRUE`
///
/// * Example elements
///   * Capsfilter when setting caps on outgoing buffers that have
///     none.
///   * identity when it is going to re-timestamp buffers by
///     datarate.
///
/// ## Normal mode
///   * always_in_place flag is not set, or there is no transform_ip function
///   * Element will receive an input buffer and output buffer to operate on.
///   * Output buffer is allocated by calling the prepare_output_buffer function.
///   * Example elements:
///     * Videoscale, videoconvert, audioconvert when doing
///     scaling/conversions
///
/// ## Special output buffer allocations
///   * Elements which need to do special allocation of their output buffers
///     beyond allocating output buffers via the negotiated allocator or
///     buffer pool should implement the prepare_output_buffer method.
///
///   * Example elements:
///     * efence
///
/// # Sub-class settable flags on GstBaseTransform
///
/// * passthrough
///
///   * Implies that in the current configuration, the sub-class is not interested in modifying the buffers.
///   * Elements which are always in passthrough mode whenever the same caps has been negotiated on both pads can set the class variable passthrough_on_same_caps to have this behaviour automatically.
///
/// * always_in_place
///   * Determines whether a non-writable buffer will be copied before passing
///     to the transform_ip function.
///
///   * Implied `TRUE` if no transform function is implemented.
///   * Implied `FALSE` if ONLY transform function is implemented.
pub const BaseTransform = extern struct {
    pub const Parent = gst.Element;
    pub const Implements = [_]type{};
    pub const Class = gstbase.BaseTransformClass;
    f_element: gst.Element,
    f_sinkpad: ?*gst.Pad,
    f_srcpad: ?*gst.Pad,
    f_have_segment: c_int,
    f_segment: gst.Segment,
    f_queued_buf: ?*gst.Buffer,
    f_priv: ?*gstbase.BaseTransformPrivate,
    f__gst_reserved: [19]*anyopaque,

    pub const virtual_methods = struct {
        /// Optional.
        ///                  Subclasses can override this method to check if `caps` can be
        ///                  handled by the element. The default implementation might not be
        ///                  the most optimal way to check this in all cases.
        pub const accept_caps = struct {
            pub fn call(p_class: anytype, p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_direction: gst.PadDirection, p_caps: *gst.Caps) c_int {
                return gobject.ext.as(BaseTransform.Class, p_class).f_accept_caps.?(gobject.ext.as(BaseTransform, p_trans), p_direction, p_caps);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_direction: gst.PadDirection, p_caps: *gst.Caps) callconv(.c) c_int) void {
                gobject.ext.as(BaseTransform.Class, p_class).f_accept_caps = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                    This method is called right before the base class will
        ///                    start processing. Dynamic properties or other delayed
        ///                    configuration could be performed in this method.
        pub const before_transform = struct {
            pub fn call(p_class: anytype, p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buffer: *gst.Buffer) void {
                return gobject.ext.as(BaseTransform.Class, p_class).f_before_transform.?(gobject.ext.as(BaseTransform, p_trans), p_buffer);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buffer: *gst.Buffer) callconv(.c) void) void {
                gobject.ext.as(BaseTransform.Class, p_class).f_before_transform = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                 Copy the metadata from the input buffer to the output buffer.
        ///                 The default implementation will copy the flags, timestamps and
        ///                 offsets of the buffer.
        pub const copy_metadata = struct {
            pub fn call(p_class: anytype, p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_input: *gst.Buffer, p_outbuf: *gst.Buffer) c_int {
                return gobject.ext.as(BaseTransform.Class, p_class).f_copy_metadata.?(gobject.ext.as(BaseTransform, p_trans), p_input, p_outbuf);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_input: *gst.Buffer, p_outbuf: *gst.Buffer) callconv(.c) c_int) void {
                gobject.ext.as(BaseTransform.Class, p_class).f_copy_metadata = @ptrCast(p_implementation);
            }
        };

        /// Setup the allocation parameters for allocating output
        ///                    buffers. The passed in query contains the result of the
        ///                    downstream allocation query. This function is only called
        ///                    when not operating in passthrough mode. The default
        ///                    implementation will remove all memory dependent metadata.
        ///                    If there is a `filter_meta` method implementation, it will
        ///                    be called for all metadata API in the downstream query,
        ///                    otherwise the metadata API is removed.
        pub const decide_allocation = struct {
            pub fn call(p_class: anytype, p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_query: *gst.Query) c_int {
                return gobject.ext.as(BaseTransform.Class, p_class).f_decide_allocation.?(gobject.ext.as(BaseTransform, p_trans), p_query);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_query: *gst.Query) callconv(.c) c_int) void {
                gobject.ext.as(BaseTransform.Class, p_class).f_decide_allocation = @ptrCast(p_implementation);
            }
        };

        /// Return `TRUE` if the metadata API should be proposed in the
        ///               upstream allocation query. The default implementation is `NULL`
        ///               and will cause all metadata to be removed.
        pub const filter_meta = struct {
            pub fn call(p_class: anytype, p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_query: *gst.Query, p_api: usize, p_params: *const gst.Structure) c_int {
                return gobject.ext.as(BaseTransform.Class, p_class).f_filter_meta.?(gobject.ext.as(BaseTransform, p_trans), p_query, p_api, p_params);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_query: *gst.Query, p_api: usize, p_params: *const gst.Structure) callconv(.c) c_int) void {
                gobject.ext.as(BaseTransform.Class, p_class).f_filter_meta = @ptrCast(p_implementation);
            }
        };

        pub const fixate_caps = struct {
            pub fn call(p_class: anytype, p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_direction: gst.PadDirection, p_caps: *gst.Caps, p_othercaps: *gst.Caps) *gst.Caps {
                return gobject.ext.as(BaseTransform.Class, p_class).f_fixate_caps.?(gobject.ext.as(BaseTransform, p_trans), p_direction, p_caps, p_othercaps);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_direction: gst.PadDirection, p_caps: *gst.Caps, p_othercaps: *gst.Caps) callconv(.c) *gst.Caps) void {
                gobject.ext.as(BaseTransform.Class, p_class).f_fixate_caps = @ptrCast(p_implementation);
            }
        };

        pub const generate_output = struct {
            pub fn call(p_class: anytype, p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_outbuf: **gst.Buffer) gst.FlowReturn {
                return gobject.ext.as(BaseTransform.Class, p_class).f_generate_output.?(gobject.ext.as(BaseTransform, p_trans), p_outbuf);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_outbuf: **gst.Buffer) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(BaseTransform.Class, p_class).f_generate_output = @ptrCast(p_implementation);
            }
        };

        pub const get_unit_size = struct {
            pub fn call(p_class: anytype, p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_caps: *gst.Caps, p_size: *usize) c_int {
                return gobject.ext.as(BaseTransform.Class, p_class).f_get_unit_size.?(gobject.ext.as(BaseTransform, p_trans), p_caps, p_size);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_caps: *gst.Caps, p_size: *usize) callconv(.c) c_int) void {
                gobject.ext.as(BaseTransform.Class, p_class).f_get_unit_size = @ptrCast(p_implementation);
            }
        };

        pub const prepare_output_buffer = struct {
            pub fn call(p_class: anytype, p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_input: *gst.Buffer, p_outbuf: **gst.Buffer) gst.FlowReturn {
                return gobject.ext.as(BaseTransform.Class, p_class).f_prepare_output_buffer.?(gobject.ext.as(BaseTransform, p_trans), p_input, p_outbuf);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_input: *gst.Buffer, p_outbuf: **gst.Buffer) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(BaseTransform.Class, p_class).f_prepare_output_buffer = @ptrCast(p_implementation);
            }
        };

        /// Propose buffer allocation parameters for upstream elements.
        ///                      This function must be implemented if the element reads or
        ///                      writes the buffer content. The query that was passed to
        ///                      the decide_allocation is passed in this method (or `NULL`
        ///                      when the element is in passthrough mode). The default
        ///                      implementation will pass the query downstream when in
        ///                      passthrough mode and will copy all the filtered metadata
        ///                      API in non-passthrough mode.
        pub const propose_allocation = struct {
            pub fn call(p_class: anytype, p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_decide_query: *gst.Query, p_query: *gst.Query) c_int {
                return gobject.ext.as(BaseTransform.Class, p_class).f_propose_allocation.?(gobject.ext.as(BaseTransform, p_trans), p_decide_query, p_query);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_decide_query: *gst.Query, p_query: *gst.Query) callconv(.c) c_int) void {
                gobject.ext.as(BaseTransform.Class, p_class).f_propose_allocation = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                  Handle a requested query. Subclasses that implement this
        ///                  must chain up to the parent if they didn't handle the
        ///                  query
        pub const query = struct {
            pub fn call(p_class: anytype, p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_direction: gst.PadDirection, p_query: *gst.Query) c_int {
                return gobject.ext.as(BaseTransform.Class, p_class).f_query.?(gobject.ext.as(BaseTransform, p_trans), p_direction, p_query);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_direction: gst.PadDirection, p_query: *gst.Query) callconv(.c) c_int) void {
                gobject.ext.as(BaseTransform.Class, p_class).f_query = @ptrCast(p_implementation);
            }
        };

        /// Allows the subclass to be notified of the actual caps set.
        pub const set_caps = struct {
            pub fn call(p_class: anytype, p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_incaps: *gst.Caps, p_outcaps: *gst.Caps) c_int {
                return gobject.ext.as(BaseTransform.Class, p_class).f_set_caps.?(gobject.ext.as(BaseTransform, p_trans), p_incaps, p_outcaps);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_incaps: *gst.Caps, p_outcaps: *gst.Caps) callconv(.c) c_int) void {
                gobject.ext.as(BaseTransform.Class, p_class).f_set_caps = @ptrCast(p_implementation);
            }
        };

        pub const sink_event = struct {
            pub fn call(p_class: anytype, p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_event: *gst.Event) c_int {
                return gobject.ext.as(BaseTransform.Class, p_class).f_sink_event.?(gobject.ext.as(BaseTransform, p_trans), p_event);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_event: *gst.Event) callconv(.c) c_int) void {
                gobject.ext.as(BaseTransform.Class, p_class).f_sink_event = @ptrCast(p_implementation);
            }
        };

        pub const src_event = struct {
            pub fn call(p_class: anytype, p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_event: *gst.Event) c_int {
                return gobject.ext.as(BaseTransform.Class, p_class).f_src_event.?(gobject.ext.as(BaseTransform, p_trans), p_event);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_event: *gst.Event) callconv(.c) c_int) void {
                gobject.ext.as(BaseTransform.Class, p_class).f_src_event = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                  Called when the element starts processing.
        ///                  Allows opening external resources.
        pub const start = struct {
            pub fn call(p_class: anytype, p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) c_int {
                return gobject.ext.as(BaseTransform.Class, p_class).f_start.?(gobject.ext.as(BaseTransform, p_trans));
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) callconv(.c) c_int) void {
                gobject.ext.as(BaseTransform.Class, p_class).f_start = @ptrCast(p_implementation);
            }
        };

        /// Optional.
        ///                  Called when the element stops processing.
        ///                  Allows closing external resources.
        pub const stop = struct {
            pub fn call(p_class: anytype, p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) c_int {
                return gobject.ext.as(BaseTransform.Class, p_class).f_stop.?(gobject.ext.as(BaseTransform, p_trans));
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) callconv(.c) c_int) void {
                gobject.ext.as(BaseTransform.Class, p_class).f_stop = @ptrCast(p_implementation);
            }
        };

        /// Function which accepts a new input buffer and pre-processes it.
        ///                  The default implementation performs caps (re)negotiation, then
        ///                  QoS if needed, and places the input buffer into the `queued_buf`
        ///                  member variable. If the buffer is dropped due to QoS, it returns
        ///                  GST_BASE_TRANSFORM_FLOW_DROPPED. If this input buffer is not
        ///                  contiguous with any previous input buffer, then `is_discont`
        ///                  is set to `TRUE`. (Since: 1.6)
        pub const submit_input_buffer = struct {
            pub fn call(p_class: anytype, p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_is_discont: c_int, p_input: *gst.Buffer) gst.FlowReturn {
                return gobject.ext.as(BaseTransform.Class, p_class).f_submit_input_buffer.?(gobject.ext.as(BaseTransform, p_trans), p_is_discont, p_input);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_is_discont: c_int, p_input: *gst.Buffer) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(BaseTransform.Class, p_class).f_submit_input_buffer = @ptrCast(p_implementation);
            }
        };

        /// Required if the element does not operate in-place.
        ///                  Transforms one incoming buffer to one outgoing buffer.
        ///                  The function is allowed to change size/timestamp/duration
        ///                  of the outgoing buffer.
        pub const transform = struct {
            pub fn call(p_class: anytype, p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_inbuf: *gst.Buffer, p_outbuf: *gst.Buffer) gst.FlowReturn {
                return gobject.ext.as(BaseTransform.Class, p_class).f_transform.?(gobject.ext.as(BaseTransform, p_trans), p_inbuf, p_outbuf);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_inbuf: *gst.Buffer, p_outbuf: *gst.Buffer) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(BaseTransform.Class, p_class).f_transform = @ptrCast(p_implementation);
            }
        };

        /// Optional.  Given the pad in this direction and the given
        ///                  caps, what caps are allowed on the other pad in this
        ///                  element ?
        pub const transform_caps = struct {
            pub fn call(p_class: anytype, p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_direction: gst.PadDirection, p_caps: *gst.Caps, p_filter: *gst.Caps) *gst.Caps {
                return gobject.ext.as(BaseTransform.Class, p_class).f_transform_caps.?(gobject.ext.as(BaseTransform, p_trans), p_direction, p_caps, p_filter);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_direction: gst.PadDirection, p_caps: *gst.Caps, p_filter: *gst.Caps) callconv(.c) *gst.Caps) void {
                gobject.ext.as(BaseTransform.Class, p_class).f_transform_caps = @ptrCast(p_implementation);
            }
        };

        /// Required if the element operates in-place.
        ///                  Transform the incoming buffer in-place.
        pub const transform_ip = struct {
            pub fn call(p_class: anytype, p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buf: *gst.Buffer) gst.FlowReturn {
                return gobject.ext.as(BaseTransform.Class, p_class).f_transform_ip.?(gobject.ext.as(BaseTransform, p_trans), p_buf);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buf: *gst.Buffer) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(BaseTransform.Class, p_class).f_transform_ip = @ptrCast(p_implementation);
            }
        };

        /// Optional. Transform the metadata on the input buffer to the
        ///                  output buffer. By default this method copies all meta without
        ///                  tags. Subclasses can implement this method and return `TRUE` if
        ///                  the metadata is to be copied.
        pub const transform_meta = struct {
            pub fn call(p_class: anytype, p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_outbuf: *gst.Buffer, p_meta: *gst.Meta, p_inbuf: *gst.Buffer) c_int {
                return gobject.ext.as(BaseTransform.Class, p_class).f_transform_meta.?(gobject.ext.as(BaseTransform, p_trans), p_outbuf, p_meta, p_inbuf);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_outbuf: *gst.Buffer, p_meta: *gst.Meta, p_inbuf: *gst.Buffer) callconv(.c) c_int) void {
                gobject.ext.as(BaseTransform.Class, p_class).f_transform_meta = @ptrCast(p_implementation);
            }
        };

        pub const transform_size = struct {
            pub fn call(p_class: anytype, p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_direction: gst.PadDirection, p_caps: *gst.Caps, p_size: usize, p_othercaps: *gst.Caps, p_othersize: *usize) c_int {
                return gobject.ext.as(BaseTransform.Class, p_class).f_transform_size.?(gobject.ext.as(BaseTransform, p_trans), p_direction, p_caps, p_size, p_othercaps, p_othersize);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_trans: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_direction: gst.PadDirection, p_caps: *gst.Caps, p_size: usize, p_othercaps: *gst.Caps, p_othersize: *usize) callconv(.c) c_int) void {
                gobject.ext.as(BaseTransform.Class, p_class).f_transform_size = @ptrCast(p_implementation);
            }
        };
    };

    pub const properties = struct {
        pub const qos = struct {
            pub const name = "qos";

            pub const Type = c_int;
        };
    };

    pub const signals = struct {};

    /// Lets `gstbase.BaseTransform` sub-classes know the memory `allocator`
    /// used by the base class and its `params`.
    ///
    /// Unref the `allocator` after use.
    extern fn gst_base_transform_get_allocator(p_trans: *BaseTransform, p_allocator: ?**gst.Allocator, p_params: ?*gst.AllocationParams) void;
    pub const getAllocator = gst_base_transform_get_allocator;

    extern fn gst_base_transform_get_buffer_pool(p_trans: *BaseTransform) ?*gst.BufferPool;
    pub const getBufferPool = gst_base_transform_get_buffer_pool;

    /// See if `trans` is configured as a in_place transform.
    extern fn gst_base_transform_is_in_place(p_trans: *BaseTransform) c_int;
    pub const isInPlace = gst_base_transform_is_in_place;

    /// See if `trans` is configured as a passthrough transform.
    extern fn gst_base_transform_is_passthrough(p_trans: *BaseTransform) c_int;
    pub const isPassthrough = gst_base_transform_is_passthrough;

    /// Queries if the transform will handle QoS.
    extern fn gst_base_transform_is_qos_enabled(p_trans: *BaseTransform) c_int;
    pub const isQosEnabled = gst_base_transform_is_qos_enabled;

    /// Negotiates src pad caps with downstream elements if the source pad is
    /// marked as needing reconfiguring. Unmarks GST_PAD_FLAG_NEED_RECONFIGURE in
    /// any case. But marks it again if negotiation fails.
    ///
    /// Do not call this in the `gstbase.BaseTransformClass.signals.transform` or
    /// `gstbase.BaseTransformClass.signals.transform_ip` vmethod. Call this in
    /// `gstbase.BaseTransformClass.signals.submit_input_buffer`,
    /// `gstbase.BaseTransformClass.signals.prepare_output_buffer` or in
    /// `gstbase.BaseTransformClass.signals.generate_output` _before_ any output buffer is
    /// allocated.
    ///
    /// It will be default be called when handling an ALLOCATION query or at the
    /// very beginning of the default `gstbase.BaseTransformClass.signals.submit_input_buffer`
    /// implementation.
    extern fn gst_base_transform_reconfigure(p_trans: *BaseTransform) c_int;
    pub const reconfigure = gst_base_transform_reconfigure;

    /// Instructs `trans` to request renegotiation upstream. This function is
    /// typically called after properties on the transform were set that
    /// influence the input format.
    extern fn gst_base_transform_reconfigure_sink(p_trans: *BaseTransform) void;
    pub const reconfigureSink = gst_base_transform_reconfigure_sink;

    /// Instructs `trans` to renegotiate a new downstream transform on the next
    /// buffer. This function is typically called after properties on the transform
    /// were set that influence the output format.
    extern fn gst_base_transform_reconfigure_src(p_trans: *BaseTransform) void;
    pub const reconfigureSrc = gst_base_transform_reconfigure_src;

    /// If `gap_aware` is `FALSE` (the default), output buffers will have the
    /// `GST_BUFFER_FLAG_GAP` flag unset.
    ///
    /// If set to `TRUE`, the element must handle output buffers with this flag set
    /// correctly, i.e. it can assume that the buffer contains neutral data but must
    /// unset the flag if the output is no neutral data.
    ///
    /// MT safe.
    extern fn gst_base_transform_set_gap_aware(p_trans: *BaseTransform, p_gap_aware: c_int) void;
    pub const setGapAware = gst_base_transform_set_gap_aware;

    /// Determines whether a non-writable buffer will be copied before passing
    /// to the transform_ip function.
    ///
    ///   * Always `TRUE` if no transform function is implemented.
    ///   * Always `FALSE` if ONLY transform function is implemented.
    ///
    /// MT safe.
    extern fn gst_base_transform_set_in_place(p_trans: *BaseTransform, p_in_place: c_int) void;
    pub const setInPlace = gst_base_transform_set_in_place;

    /// Set passthrough mode for this filter by default. This is mostly
    /// useful for filters that do not care about negotiation.
    ///
    /// Always `TRUE` for filters which don't implement either a transform
    /// or transform_ip or generate_output method.
    ///
    /// MT safe.
    extern fn gst_base_transform_set_passthrough(p_trans: *BaseTransform, p_passthrough: c_int) void;
    pub const setPassthrough = gst_base_transform_set_passthrough;

    /// If `prefer_passthrough` is `TRUE` (the default), `trans` will check and
    /// prefer passthrough caps from the list of caps returned by the
    /// transform_caps vmethod.
    ///
    /// If set to `FALSE`, the element must order the caps returned from the
    /// transform_caps function in such a way that the preferred format is
    /// first in the list. This can be interesting for transforms that can do
    /// passthrough transforms but prefer to do something else, like a
    /// capsfilter.
    ///
    /// MT safe.
    extern fn gst_base_transform_set_prefer_passthrough(p_trans: *BaseTransform, p_prefer_passthrough: c_int) void;
    pub const setPreferPassthrough = gst_base_transform_set_prefer_passthrough;

    /// Enable or disable QoS handling in the transform.
    ///
    /// MT safe.
    extern fn gst_base_transform_set_qos_enabled(p_trans: *BaseTransform, p_enabled: c_int) void;
    pub const setQosEnabled = gst_base_transform_set_qos_enabled;

    /// Set the QoS parameters in the transform. This function is called internally
    /// when a QOS event is received but subclasses can provide custom information
    /// when needed.
    ///
    /// MT safe.
    extern fn gst_base_transform_update_qos(p_trans: *BaseTransform, p_proportion: f64, p_diff: gst.ClockTimeDiff, p_timestamp: gst.ClockTime) void;
    pub const updateQos = gst_base_transform_update_qos;

    /// Updates the srcpad caps and sends the caps downstream. This function
    /// can be used by subclasses when they have already negotiated their caps
    /// but found a change in them (or computed new information). This way,
    /// they can notify downstream about that change without losing any
    /// buffer.
    extern fn gst_base_transform_update_src_caps(p_trans: *BaseTransform, p_updated_caps: *gst.Caps) c_int;
    pub const updateSrcCaps = gst_base_transform_update_src_caps;

    extern fn gst_base_transform_get_type() usize;
    pub const getGObjectType = gst_base_transform_get_type;

    extern fn g_object_ref(p_self: *gstbase.BaseTransform) void;
    pub const ref = g_object_ref;

    extern fn g_object_unref(p_self: *gstbase.BaseTransform) void;
    pub const unref = g_object_unref;

    pub fn as(p_instance: *BaseTransform, comptime P_T: type) *P_T {
        return gobject.ext.as(P_T, p_instance);
    }

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// Manages a set of pads that operate in collect mode. This means that control
/// is given to the manager of this object when all pads have data.
///
///   * Collectpads are created with `gstbase.CollectPads.new`. A callback should then
///     be installed with gst_collect_pads_set_function ().
///
///   * Pads are added to the collection with `gstbase.CollectPads.addPad`/
///     `gstbase.CollectPads.removePad`. The pad has to be a sinkpad. When added,
///     the chain, event and query functions of the pad are overridden. The
///     element_private of the pad is used to store private information for the
///     collectpads.
///
///   * For each pad, data is queued in the _chain function or by
///     performing a pull_range.
///
///   * When data is queued on all pads in waiting mode, the callback function is called.
///
///   * Data can be dequeued from the pad with the `gstbase.CollectPads.pop` method.
///     One can peek at the data with the `gstbase.CollectPads.peek` function.
///     These functions will return `NULL` if the pad received an EOS event. When all
///     pads return `NULL` from a `gstbase.CollectPads.peek`, the element can emit an EOS
///     event itself.
///
///   * Data can also be dequeued in byte units using the `gstbase.CollectPads.available`,
///     `gstbase.CollectPads.readBuffer` and `gstbase.CollectPads.flush` calls.
///
///   * Elements should call `gstbase.CollectPads.start` and `gstbase.CollectPads.stop` in
///     their state change functions to start and stop the processing of the collectpads.
///     The `gstbase.CollectPads.stop` call should be called before calling the parent
///     element state change function in the PAUSED_TO_READY state change to ensure
///     no pad is blocked and the element can finish streaming.
///
///   * `gstbase.CollectPads.setWaiting` sets a pad to waiting or non-waiting mode.
///     CollectPads element is not waiting for data to be collected on non-waiting pads.
///     Thus these pads may but need not have data when the callback is called.
///     All pads are in waiting mode by default.
pub const CollectPads = extern struct {
    pub const Parent = gst.Object;
    pub const Implements = [_]type{};
    pub const Class = gstbase.CollectPadsClass;
    f_object: gst.Object,
    /// `glib.List` of `gstbase.CollectData` managed
    ///   by this `gstbase.CollectPads`.
    f_data: ?*glib.SList,
    f_stream_lock: glib.RecMutex,
    f_priv: ?*gstbase.CollectPadsPrivate,
    f__gst_reserved: [4]*anyopaque,

    pub const virtual_methods = struct {};

    pub const properties = struct {};

    pub const signals = struct {};

    /// Create a new instance of `gstbase.CollectPads`.
    ///
    /// MT safe.
    extern fn gst_collect_pads_new() *gstbase.CollectPads;
    pub const new = gst_collect_pads_new;

    /// Add a pad to the collection of collect pads. The pad has to be
    /// a sinkpad. The refcount of the pad is incremented. Use
    /// `gstbase.CollectPads.removePad` to remove the pad from the collection
    /// again.
    ///
    /// You specify a size for the returned `gstbase.CollectData` structure
    /// so that you can use it to store additional information.
    ///
    /// You can also specify a `gstbase.CollectDataDestroyNotify` that will be called
    /// just before the `gstbase.CollectData` structure is freed. It is passed the
    /// pointer to the structure and should free any custom memory and resources
    /// allocated for it.
    ///
    /// Keeping a pad locked in waiting state is only relevant when using
    /// the default collection algorithm (providing the oldest buffer).
    /// It ensures a buffer must be available on this pad for a collection
    /// to take place.  This is of typical use to a muxer element where
    /// non-subtitle streams should always be in waiting state,
    /// e.g. to assure that caps information is available on all these streams
    /// when initial headers have to be written.
    ///
    /// The pad will be automatically activated in push mode when `pads` is
    /// started.
    ///
    /// MT safe.
    extern fn gst_collect_pads_add_pad(p_pads: *CollectPads, p_pad: *gst.Pad, p_size: c_uint, p_destroy_notify: gstbase.CollectDataDestroyNotify, p_lock: c_int) ?*gstbase.CollectData;
    pub const addPad = gst_collect_pads_add_pad;

    /// Query how much bytes can be read from each queued buffer. This means
    /// that the result of this call is the maximum number of bytes that can
    /// be read from each of the pads.
    ///
    /// This function should be called with `pads` STREAM_LOCK held, such as
    /// in the callback.
    ///
    /// MT safe.
    extern fn gst_collect_pads_available(p_pads: *CollectPads) c_uint;
    pub const available = gst_collect_pads_available;

    /// Convenience clipping function that converts incoming buffer's timestamp
    /// to running time, or clips the buffer if outside configured segment.
    ///
    /// Since 1.6, this clipping function also sets the DTS parameter of the
    /// GstCollectData structure. This version of the running time DTS can be
    /// negative. G_MININT64 is used to indicate invalid value.
    extern fn gst_collect_pads_clip_running_time(p_pads: *CollectPads, p_cdata: *gstbase.CollectData, p_buf: *gst.Buffer, p_outbuf: ?**gst.Buffer, p_user_data: ?*anyopaque) gst.FlowReturn;
    pub const clipRunningTime = gst_collect_pads_clip_running_time;

    /// Default `gstbase.CollectPads` event handling that elements should always
    /// chain up to to ensure proper operation.  Element might however indicate
    /// event should not be forwarded downstream.
    extern fn gst_collect_pads_event_default(p_pads: *CollectPads, p_data: *gstbase.CollectData, p_event: *gst.Event, p_discard: c_int) c_int;
    pub const eventDefault = gst_collect_pads_event_default;

    /// Flush `size` bytes from the pad `data`.
    ///
    /// This function should be called with `pads` STREAM_LOCK held, such as
    /// in the callback.
    ///
    /// MT safe.
    extern fn gst_collect_pads_flush(p_pads: *CollectPads, p_data: *gstbase.CollectData, p_size: c_uint) c_uint;
    pub const flush = gst_collect_pads_flush;

    /// Peek at the buffer currently queued in `data`. This function
    /// should be called with the `pads` STREAM_LOCK held, such as in the callback
    /// handler.
    ///
    /// MT safe.
    extern fn gst_collect_pads_peek(p_pads: *CollectPads, p_data: *gstbase.CollectData) ?*gst.Buffer;
    pub const peek = gst_collect_pads_peek;

    /// Pop the buffer currently queued in `data`. This function
    /// should be called with the `pads` STREAM_LOCK held, such as in the callback
    /// handler.
    ///
    /// MT safe.
    extern fn gst_collect_pads_pop(p_pads: *CollectPads, p_data: *gstbase.CollectData) ?*gst.Buffer;
    pub const pop = gst_collect_pads_pop;

    /// Default `gstbase.CollectPads` query handling that elements should always
    /// chain up to to ensure proper operation.  Element might however indicate
    /// query should not be forwarded downstream.
    extern fn gst_collect_pads_query_default(p_pads: *CollectPads, p_data: *gstbase.CollectData, p_query: *gst.Query, p_discard: c_int) c_int;
    pub const queryDefault = gst_collect_pads_query_default;

    /// Get a subbuffer of `size` bytes from the given pad `data`.
    ///
    /// This function should be called with `pads` STREAM_LOCK held, such as in the
    /// callback.
    ///
    /// MT safe.
    extern fn gst_collect_pads_read_buffer(p_pads: *CollectPads, p_data: *gstbase.CollectData, p_size: c_uint) ?*gst.Buffer;
    pub const readBuffer = gst_collect_pads_read_buffer;

    /// Remove a pad from the collection of collect pads. This function will also
    /// free the `gstbase.CollectData` and all the resources that were allocated with
    /// `gstbase.CollectPads.addPad`.
    ///
    /// The pad will be deactivated automatically when `pads` is stopped.
    ///
    /// MT safe.
    extern fn gst_collect_pads_remove_pad(p_pads: *CollectPads, p_pad: *gst.Pad) c_int;
    pub const removePad = gst_collect_pads_remove_pad;

    /// Set the callback function and user data that will be called with
    /// the oldest buffer when all pads have been collected, or `NULL` on EOS.
    /// If a buffer is passed, the callback owns a reference and must unref
    /// it.
    ///
    /// MT safe.
    extern fn gst_collect_pads_set_buffer_function(p_pads: *CollectPads, p_func: gstbase.CollectPadsBufferFunction, p_user_data: ?*anyopaque) void;
    pub const setBufferFunction = gst_collect_pads_set_buffer_function;

    /// Install a clipping function that is called right after a buffer is received
    /// on a pad managed by `pads`. See `gstbase.CollectPadsClipFunction` for more info.
    extern fn gst_collect_pads_set_clip_function(p_pads: *CollectPads, p_clipfunc: gstbase.CollectPadsClipFunction, p_user_data: ?*anyopaque) void;
    pub const setClipFunction = gst_collect_pads_set_clip_function;

    /// Set the timestamp comparison function.
    ///
    /// MT safe.
    extern fn gst_collect_pads_set_compare_function(p_pads: *CollectPads, p_func: gstbase.CollectPadsCompareFunction, p_user_data: ?*anyopaque) void;
    pub const setCompareFunction = gst_collect_pads_set_compare_function;

    /// Set the event callback function and user data that will be called when
    /// collectpads has received an event originating from one of the collected
    /// pads.  If the event being processed is a serialized one, this callback is
    /// called with `pads` STREAM_LOCK held, otherwise not.  As this lock should be
    /// held when calling a number of CollectPads functions, it should be acquired
    /// if so (unusually) needed.
    ///
    /// MT safe.
    extern fn gst_collect_pads_set_event_function(p_pads: *CollectPads, p_func: gstbase.CollectPadsEventFunction, p_user_data: ?*anyopaque) void;
    pub const setEventFunction = gst_collect_pads_set_event_function;

    /// Install a flush function that is called when the internal
    /// state of all pads should be flushed as part of flushing seek
    /// handling. See `gstbase.CollectPadsFlushFunction` for more info.
    extern fn gst_collect_pads_set_flush_function(p_pads: *CollectPads, p_func: gstbase.CollectPadsFlushFunction, p_user_data: ?*anyopaque) void;
    pub const setFlushFunction = gst_collect_pads_set_flush_function;

    /// Change the flushing state of all the pads in the collection. No pad
    /// is able to accept anymore data when `flushing` is `TRUE`. Calling this
    /// function with `flushing` `FALSE` makes `pads` accept data again.
    /// Caller must ensure that downstream streaming (thread) is not blocked,
    /// e.g. by sending a FLUSH_START downstream.
    ///
    /// MT safe.
    extern fn gst_collect_pads_set_flushing(p_pads: *CollectPads, p_flushing: c_int) void;
    pub const setFlushing = gst_collect_pads_set_flushing;

    /// CollectPads provides a default collection algorithm that will determine
    /// the oldest buffer available on all of its pads, and then delegate
    /// to a configured callback.
    /// However, if circumstances are more complicated and/or more control
    /// is desired, this sets a callback that will be invoked instead when
    /// all the pads added to the collection have buffers queued.
    /// Evidently, this callback is not compatible with
    /// `gstbase.CollectPads.setBufferFunction` callback.
    /// If this callback is set, the former will be unset.
    ///
    /// MT safe.
    extern fn gst_collect_pads_set_function(p_pads: *CollectPads, p_func: gstbase.CollectPadsFunction, p_user_data: ?*anyopaque) void;
    pub const setFunction = gst_collect_pads_set_function;

    /// Set the query callback function and user data that will be called after
    /// collectpads has received a query originating from one of the collected
    /// pads.  If the query being processed is a serialized one, this callback is
    /// called with `pads` STREAM_LOCK held, otherwise not.  As this lock should be
    /// held when calling a number of CollectPads functions, it should be acquired
    /// if so (unusually) needed.
    ///
    /// MT safe.
    extern fn gst_collect_pads_set_query_function(p_pads: *CollectPads, p_func: gstbase.CollectPadsQueryFunction, p_user_data: ?*anyopaque) void;
    pub const setQueryFunction = gst_collect_pads_set_query_function;

    /// Sets a pad to waiting or non-waiting mode, if at least this pad
    /// has not been created with locked waiting state,
    /// in which case nothing happens.
    ///
    /// This function should be called with `pads` STREAM_LOCK held, such as
    /// in the callback.
    ///
    /// MT safe.
    extern fn gst_collect_pads_set_waiting(p_pads: *CollectPads, p_data: *gstbase.CollectData, p_waiting: c_int) void;
    pub const setWaiting = gst_collect_pads_set_waiting;

    /// Default `gstbase.CollectPads` event handling for the src pad of elements.
    /// Elements can chain up to this to let flushing seek event handling
    /// be done by `gstbase.CollectPads`.
    extern fn gst_collect_pads_src_event_default(p_pads: *CollectPads, p_pad: *gst.Pad, p_event: *gst.Event) c_int;
    pub const srcEventDefault = gst_collect_pads_src_event_default;

    /// Starts the processing of data in the collect_pads.
    ///
    /// MT safe.
    extern fn gst_collect_pads_start(p_pads: *CollectPads) void;
    pub const start = gst_collect_pads_start;

    /// Stops the processing of data in the collect_pads. this function
    /// will also unblock any blocking operations.
    ///
    /// MT safe.
    extern fn gst_collect_pads_stop(p_pads: *CollectPads) void;
    pub const stop = gst_collect_pads_stop;

    /// Get a subbuffer of `size` bytes from the given pad `data`. Flushes the amount
    /// of read bytes.
    ///
    /// This function should be called with `pads` STREAM_LOCK held, such as in the
    /// callback.
    ///
    /// MT safe.
    extern fn gst_collect_pads_take_buffer(p_pads: *CollectPads, p_data: *gstbase.CollectData, p_size: c_uint) ?*gst.Buffer;
    pub const takeBuffer = gst_collect_pads_take_buffer;

    extern fn gst_collect_pads_get_type() usize;
    pub const getGObjectType = gst_collect_pads_get_type;

    extern fn g_object_ref(p_self: *gstbase.CollectPads) void;
    pub const ref = g_object_ref;

    extern fn g_object_unref(p_self: *gstbase.CollectPads) void;
    pub const unref = g_object_unref;

    pub fn as(p_instance: *CollectPads, comptime P_T: type) *P_T {
        return gobject.ext.as(P_T, p_instance);
    }

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// `gstbase.DataQueue` is an object that handles threadsafe queueing of objects. It
/// also provides size-related functionality. This object should be used for
/// any `gst.Element` that wishes to provide some sort of queueing functionality.
pub const DataQueue = extern struct {
    pub const Parent = gobject.Object;
    pub const Implements = [_]type{};
    pub const Class = gstbase.DataQueueClass;
    /// the parent structure
    f_object: gobject.Object,
    f_priv: ?*gstbase.DataQueuePrivate,
    f__gst_reserved: [4]*anyopaque,

    pub const virtual_methods = struct {
        pub const empty = struct {
            pub fn call(p_class: anytype, p_queue: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) void {
                return gobject.ext.as(DataQueue.Class, p_class).f_empty.?(gobject.ext.as(DataQueue, p_queue));
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_queue: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) callconv(.c) void) void {
                gobject.ext.as(DataQueue.Class, p_class).f_empty = @ptrCast(p_implementation);
            }
        };

        pub const full = struct {
            pub fn call(p_class: anytype, p_queue: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) void {
                return gobject.ext.as(DataQueue.Class, p_class).f_full.?(gobject.ext.as(DataQueue, p_queue));
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_queue: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance) callconv(.c) void) void {
                gobject.ext.as(DataQueue.Class, p_class).f_full = @ptrCast(p_implementation);
            }
        };
    };

    pub const properties = struct {
        pub const current_level_bytes = struct {
            pub const name = "current-level-bytes";

            pub const Type = c_uint;
        };

        pub const current_level_time = struct {
            pub const name = "current-level-time";

            pub const Type = u64;
        };

        pub const current_level_visible = struct {
            pub const name = "current-level-visible";

            pub const Type = c_uint;
        };
    };

    pub const signals = struct {
        /// Reports that the queue became empty (empty).
        /// A queue is empty if the total amount of visible items inside it (num-visible, time,
        /// size) is lower than the boundary values which can be set through the GObject
        /// properties.
        pub const empty = struct {
            pub const name = "empty";

            pub fn connect(p_instance: anytype, comptime P_Data: type, p_callback: *const fn (@TypeOf(p_instance), P_Data) callconv(.c) void, p_data: P_Data, p_options: gobject.ext.ConnectSignalOptions(P_Data)) c_ulong {
                return gobject.signalConnectClosureById(
                    @ptrCast(@alignCast(gobject.ext.as(DataQueue, p_instance))),
                    gobject.signalLookup("empty", DataQueue.getGObjectType()),
                    glib.quarkFromString(p_options.detail orelse null),
                    gobject.CClosure.new(@ptrCast(p_callback), p_data, @ptrCast(p_options.destroyData)),
                    @intFromBool(p_options.after),
                );
            }
        };

        /// Reports that the queue became full (full).
        /// A queue is full if the total amount of data inside it (num-visible, time,
        /// size) is higher than the boundary values which can be set through the GObject
        /// properties.
        pub const full = struct {
            pub const name = "full";

            pub fn connect(p_instance: anytype, comptime P_Data: type, p_callback: *const fn (@TypeOf(p_instance), P_Data) callconv(.c) void, p_data: P_Data, p_options: gobject.ext.ConnectSignalOptions(P_Data)) c_ulong {
                return gobject.signalConnectClosureById(
                    @ptrCast(@alignCast(gobject.ext.as(DataQueue, p_instance))),
                    gobject.signalLookup("full", DataQueue.getGObjectType()),
                    glib.quarkFromString(p_options.detail orelse null),
                    gobject.CClosure.new(@ptrCast(p_callback), p_data, @ptrCast(p_options.destroyData)),
                    @intFromBool(p_options.after),
                );
            }
        };
    };

    /// Creates a new `gstbase.DataQueue`. If `fullcallback` or `emptycallback` are supplied, then
    /// the `gstbase.DataQueue` will call the respective callback to signal full or empty condition.
    /// If the callbacks are NULL the `gstbase.DataQueue` will instead emit 'full' and 'empty'
    /// signals.
    extern fn gst_data_queue_new(p_checkfull: gstbase.DataQueueCheckFullFunction, p_fullcallback: gstbase.DataQueueFullCallback, p_emptycallback: gstbase.DataQueueEmptyCallback, p_checkdata: ?*anyopaque) *gstbase.DataQueue;
    pub const new = gst_data_queue_new;

    /// Pop and unref the head-most `gst.MiniObject` with the given `gobject.Type`.
    extern fn gst_data_queue_drop_head(p_queue: *DataQueue, p_type: usize) c_int;
    pub const dropHead = gst_data_queue_drop_head;

    /// Flushes all the contents of the `queue`. Any call to `gstbase.DataQueue.push` and
    /// `gstbase.DataQueue.pop` will be released.
    /// MT safe.
    extern fn gst_data_queue_flush(p_queue: *DataQueue) void;
    pub const flush = gst_data_queue_flush;

    /// Get the current level of the queue.
    extern fn gst_data_queue_get_level(p_queue: *DataQueue, p_level: *gstbase.DataQueueSize) void;
    pub const getLevel = gst_data_queue_get_level;

    /// Queries if there are any items in the `queue`.
    /// MT safe.
    extern fn gst_data_queue_is_empty(p_queue: *DataQueue) c_int;
    pub const isEmpty = gst_data_queue_is_empty;

    /// Queries if `queue` is full. This check will be done using the
    /// `gstbase.DataQueueCheckFullFunction` registered with `queue`.
    /// MT safe.
    extern fn gst_data_queue_is_full(p_queue: *DataQueue) c_int;
    pub const isFull = gst_data_queue_is_full;

    /// Inform the queue that the limits for the fullness check have changed and that
    /// any blocking `gstbase.DataQueue.push` should be unblocked to recheck the limits.
    extern fn gst_data_queue_limits_changed(p_queue: *DataQueue) void;
    pub const limitsChanged = gst_data_queue_limits_changed;

    /// Retrieves the first `item` available on the `queue` without removing it.
    /// If the queue is currently empty, the call will block until at least
    /// one item is available, OR the `queue` is set to the flushing state.
    /// MT safe.
    extern fn gst_data_queue_peek(p_queue: *DataQueue, p_item: **gstbase.DataQueueItem) c_int;
    pub const peek = gst_data_queue_peek;

    /// Retrieves the first `item` available on the `queue`. If the queue is currently
    /// empty, the call will block until at least one item is available, OR the
    /// `queue` is set to the flushing state.
    /// MT safe.
    extern fn gst_data_queue_pop(p_queue: *DataQueue, p_item: **gstbase.DataQueueItem) c_int;
    pub const pop = gst_data_queue_pop;

    /// Pushes a `gstbase.DataQueueItem` (or a structure that begins with the same fields)
    /// on the `queue`. If the `queue` is full, the call will block until space is
    /// available, OR the `queue` is set to flushing state.
    /// MT safe.
    ///
    /// Note that this function has slightly different semantics than `gst.Pad.push`
    /// and `gst.Pad.pushEvent`: this function only takes ownership of `item` and
    /// the `gst.MiniObject` contained in `item` if the push was successful. If `FALSE`
    /// is returned, the caller is responsible for freeing `item` and its contents.
    extern fn gst_data_queue_push(p_queue: *DataQueue, p_item: *gstbase.DataQueueItem) c_int;
    pub const push = gst_data_queue_push;

    /// Pushes a `gstbase.DataQueueItem` (or a structure that begins with the same fields)
    /// on the `queue`. It ignores if the `queue` is full or not and forces the `item`
    /// to be pushed anyway.
    /// MT safe.
    ///
    /// Note that this function has slightly different semantics than `gst.Pad.push`
    /// and `gst.Pad.pushEvent`: this function only takes ownership of `item` and
    /// the `gst.MiniObject` contained in `item` if the push was successful. If `FALSE`
    /// is returned, the caller is responsible for freeing `item` and its contents.
    extern fn gst_data_queue_push_force(p_queue: *DataQueue, p_item: *gstbase.DataQueueItem) c_int;
    pub const pushForce = gst_data_queue_push_force;

    /// Sets the queue to flushing state if `flushing` is `TRUE`. If set to flushing
    /// state, any incoming data on the `queue` will be discarded. Any call currently
    /// blocking on `gstbase.DataQueue.push` or `gstbase.DataQueue.pop` will return straight
    /// away with a return value of `FALSE`. While the `queue` is in flushing state,
    /// all calls to those two functions will return `FALSE`.
    ///
    /// MT Safe.
    extern fn gst_data_queue_set_flushing(p_queue: *DataQueue, p_flushing: c_int) void;
    pub const setFlushing = gst_data_queue_set_flushing;

    extern fn gst_data_queue_get_type() usize;
    pub const getGObjectType = gst_data_queue_get_type;

    extern fn g_object_ref(p_self: *gstbase.DataQueue) void;
    pub const ref = g_object_ref;

    extern fn g_object_unref(p_self: *gstbase.DataQueue) void;
    pub const unref = g_object_unref;

    pub fn as(p_instance: *DataQueue, comptime P_T: type) *P_T {
        return gobject.ext.as(P_T, p_instance);
    }

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// This class is mostly useful for elements that cannot do
/// random access, or at least very slowly. The source usually
/// prefers to push out a fixed size buffer.
///
/// Subclasses usually operate in a format that is different from the
/// default GST_FORMAT_BYTES format of `gstbase.BaseSrc`.
///
/// Classes extending this base class will usually be scheduled
/// in a push based mode. If the peer accepts to operate without
/// offsets and within the limits of the allowed block size, this
/// class can operate in getrange based mode automatically. To make
/// this possible, the subclass should implement and override the
/// SCHEDULING query.
///
/// The subclass should extend the methods from the baseclass in
/// addition to the ::create method.
///
/// Seeking, flushing, scheduling and sync is all handled by this
/// base class.
pub const PushSrc = extern struct {
    pub const Parent = gstbase.BaseSrc;
    pub const Implements = [_]type{};
    pub const Class = gstbase.PushSrcClass;
    f_parent: gstbase.BaseSrc,
    f__gst_reserved: [4]*anyopaque,

    pub const virtual_methods = struct {
        /// Allocate memory for a buffer.
        pub const alloc = struct {
            pub fn call(p_class: anytype, p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buf: ?**gst.Buffer) gst.FlowReturn {
                return gobject.ext.as(PushSrc.Class, p_class).f_alloc.?(gobject.ext.as(PushSrc, p_src), p_buf);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buf: ?**gst.Buffer) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(PushSrc.Class, p_class).f_alloc = @ptrCast(p_implementation);
            }
        };

        /// Ask the subclass to create a buffer, the default implementation will call alloc if
        /// no allocated `buf` is provided and then call fill.
        pub const create = struct {
            pub fn call(p_class: anytype, p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buf: ?**gst.Buffer) gst.FlowReturn {
                return gobject.ext.as(PushSrc.Class, p_class).f_create.?(gobject.ext.as(PushSrc, p_src), p_buf);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buf: ?**gst.Buffer) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(PushSrc.Class, p_class).f_create = @ptrCast(p_implementation);
            }
        };

        /// Ask the subclass to fill the buffer with data.
        pub const fill = struct {
            pub fn call(p_class: anytype, p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buf: *gst.Buffer) gst.FlowReturn {
                return gobject.ext.as(PushSrc.Class, p_class).f_fill.?(gobject.ext.as(PushSrc, p_src), p_buf);
            }

            pub fn implement(p_class: anytype, p_implementation: *const fn (p_src: *@typeInfo(@TypeOf(p_class)).pointer.child.Instance, p_buf: *gst.Buffer) callconv(.c) gst.FlowReturn) void {
                gobject.ext.as(PushSrc.Class, p_class).f_fill = @ptrCast(p_implementation);
            }
        };
    };

    pub const properties = struct {};

    pub const signals = struct {};

    extern fn gst_push_src_get_type() usize;
    pub const getGObjectType = gst_push_src_get_type;

    extern fn g_object_ref(p_self: *gstbase.PushSrc) void;
    pub const ref = g_object_ref;

    extern fn g_object_unref(p_self: *gstbase.PushSrc) void;
    pub const unref = g_object_unref;

    pub fn as(p_instance: *PushSrc, comptime P_T: type) *P_T {
        return gobject.ext.as(P_T, p_instance);
    }

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

pub const AdapterClass = opaque {
    pub const Instance = gstbase.Adapter;

    pub fn as(p_instance: *AdapterClass, comptime P_T: type) *P_T {
        return gobject.ext.as(P_T, p_instance);
    }

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// The aggregator base class will handle in a thread-safe way all manners of
/// concurrent flushes, seeks, pad additions and removals, leaving to the
/// subclass the responsibility of clipping buffers, and aggregating buffers in
/// the way the implementor sees fit.
///
/// It will also take care of event ordering (stream-start, segment, eos).
///
/// Basically, a simple implementation will override `aggregate`, and call
/// _finish_buffer from inside that function.
pub const AggregatorClass = extern struct {
    pub const Instance = gstbase.Aggregator;

    f_parent_class: gst.ElementClass,
    /// Optional.
    ///                  Called after a successful flushing seek, once all the flush
    ///                  stops have been received. Flush pad-specific data in
    ///                  `gstbase.AggregatorPad`->flush.
    f_flush: ?*const fn (p_aggregator: *gstbase.Aggregator) callconv(.c) gst.FlowReturn,
    /// Optional.
    ///                  Called when a buffer is received on a sink pad, the task of
    ///                  clipping it and translating it to the current segment falls
    ///                  on the subclass. The function should use the segment of data
    ///                  and the negotiated media type on the pad to perform
    ///                  clipping of input buffer. This function takes ownership of
    ///                  buf and should output a buffer or return NULL in
    ///                  if the buffer should be dropped.
    f_clip: ?*const fn (p_aggregator: *gstbase.Aggregator, p_aggregator_pad: *gstbase.AggregatorPad, p_buf: *gst.Buffer) callconv(.c) *gst.Buffer,
    /// Optional.
    ///                  Called when a subclass calls `gstbase.Aggregator.finishBuffer`
    ///                  from their aggregate function to push out a buffer.
    ///                  Subclasses can override this to modify or decorate buffers
    ///                  before they get pushed out. This function takes ownership
    ///                  of the buffer passed. Subclasses that override this method
    ///                  should always chain up to the parent class virtual method.
    f_finish_buffer: ?*const fn (p_aggregator: *gstbase.Aggregator, p_buffer: *gst.Buffer) callconv(.c) gst.FlowReturn,
    /// Optional.
    ///                  Called when an event is received on a sink pad, the subclass
    ///                  should always chain up.
    f_sink_event: ?*const fn (p_aggregator: *gstbase.Aggregator, p_aggregator_pad: *gstbase.AggregatorPad, p_event: *gst.Event) callconv(.c) c_int,
    /// Optional.
    ///                  Called when a query is received on a sink pad, the subclass
    ///                  should always chain up.
    f_sink_query: ?*const fn (p_aggregator: *gstbase.Aggregator, p_aggregator_pad: *gstbase.AggregatorPad, p_query: *gst.Query) callconv(.c) c_int,
    /// Optional.
    ///                  Called when an event is received on the src pad, the subclass
    ///                  should always chain up.
    f_src_event: ?*const fn (p_aggregator: *gstbase.Aggregator, p_event: *gst.Event) callconv(.c) c_int,
    /// Optional.
    ///                  Called when a query is received on the src pad, the subclass
    ///                  should always chain up.
    f_src_query: ?*const fn (p_aggregator: *gstbase.Aggregator, p_query: *gst.Query) callconv(.c) c_int,
    /// Optional.
    ///                  Called when the src pad is activated, it will start/stop its
    ///                  pad task right after that call.
    f_src_activate: ?*const fn (p_aggregator: *gstbase.Aggregator, p_mode: gst.PadMode, p_active: c_int) callconv(.c) c_int,
    /// Mandatory.
    ///                  Called when buffers are queued on all sinkpads. Classes
    ///                  should iterate the GstElement->sinkpads and peek or steal
    ///                  buffers from the `GstAggregatorPads`. If the subclass returns
    ///                  GST_FLOW_EOS, sending of the eos event will be taken care
    ///                  of. Once / if a buffer has been constructed from the
    ///                  aggregated buffers, the subclass should call _finish_buffer.
    f_aggregate: ?*const fn (p_aggregator: *gstbase.Aggregator, p_timeout: c_int) callconv(.c) gst.FlowReturn,
    /// Optional.
    ///                  Called when the element goes from PAUSED to READY.
    ///                  The subclass should free all resources and reset its state.
    f_stop: ?*const fn (p_aggregator: *gstbase.Aggregator) callconv(.c) c_int,
    /// Optional.
    ///                  Called when the element goes from READY to PAUSED.
    ///                  The subclass should get ready to process
    ///                  aggregated buffers.
    f_start: ?*const fn (p_aggregator: *gstbase.Aggregator) callconv(.c) c_int,
    /// Optional.
    ///                  Called when the element needs to know the running time of the next
    ///                  rendered buffer for live pipelines. This causes deadline
    ///                  based aggregation to occur. Defaults to returning
    ///                  GST_CLOCK_TIME_NONE causing the element to wait for buffers
    ///                  on all sink pads before aggregating.
    f_get_next_time: ?*const fn (p_aggregator: *gstbase.Aggregator) callconv(.c) gst.ClockTime,
    /// Optional.
    ///                  Called when a new pad needs to be created. Allows subclass that
    ///                  don't have a single sink pad template to provide a pad based
    ///                  on the provided information.
    f_create_new_pad: ?*const fn (p_self: *gstbase.Aggregator, p_templ: *gst.PadTemplate, p_req_name: [*:0]const u8, p_caps: *const gst.Caps) callconv(.c) *gstbase.AggregatorPad,
    /// Lets subclasses update the `gst.Caps` representing
    ///                   the src pad caps before usage.  The result should end up
    ///                   in `ret`. Return `GST_AGGREGATOR_FLOW_NEED_DATA` to indicate that the
    ///                   element needs more information (caps, a buffer, etc) to
    ///                   choose the correct caps. Should return ANY caps if the
    ///                   stream has not caps at all.
    f_update_src_caps: ?*const fn (p_self: *gstbase.Aggregator, p_caps: *gst.Caps, p_ret: ?**gst.Caps) callconv(.c) gst.FlowReturn,
    /// Optional.
    ///                   Fixate and return the src pad caps provided.  The function takes
    ///                   ownership of `caps` and returns a fixated version of
    ///                   `caps`. `caps` is not guaranteed to be writable.
    f_fixate_src_caps: ?*const fn (p_self: *gstbase.Aggregator, p_caps: *gst.Caps) callconv(.c) *gst.Caps,
    /// Optional.
    ///                       Notifies subclasses what caps format has been negotiated
    f_negotiated_src_caps: ?*const fn (p_self: *gstbase.Aggregator, p_caps: *gst.Caps) callconv(.c) c_int,
    /// Optional.
    ///                     Allows the subclass to influence the allocation choices.
    ///                     Setup the allocation parameters for allocating output
    ///                     buffers. The passed in query contains the result of the
    ///                     downstream allocation query.
    f_decide_allocation: ?*const fn (p_self: *gstbase.Aggregator, p_query: *gst.Query) callconv(.c) c_int,
    /// Optional.
    ///                     Allows the subclass to handle the allocation query from upstream.
    f_propose_allocation: ?*const fn (p_self: *gstbase.Aggregator, p_pad: *gstbase.AggregatorPad, p_decide_query: *gst.Query, p_query: *gst.Query) callconv(.c) c_int,
    /// Optional.
    ///             Negotiate the caps with the peer (Since: 1.18).
    f_negotiate: ?*const fn (p_self: *gstbase.Aggregator) callconv(.c) c_int,
    /// Optional.
    ///                        Called when an event is received on a sink pad before queueing up
    ///                        serialized events. The subclass should always chain up (Since: 1.18).
    f_sink_event_pre_queue: ?*const fn (p_aggregator: *gstbase.Aggregator, p_aggregator_pad: *gstbase.AggregatorPad, p_event: *gst.Event) callconv(.c) gst.FlowReturn,
    /// Optional.
    ///                        Called when a query is received on a sink pad before queueing up
    ///                        serialized queries. The subclass should always chain up (Since: 1.18).
    f_sink_query_pre_queue: ?*const fn (p_aggregator: *gstbase.Aggregator, p_aggregator_pad: *gstbase.AggregatorPad, p_query: *gst.Query) callconv(.c) c_int,
    f_finish_buffer_list: ?*const fn (p_aggregator: *gstbase.Aggregator, p_bufferlist: *gst.BufferList) callconv(.c) gst.FlowReturn,
    f_peek_next_sample: ?*const fn (p_aggregator: *gstbase.Aggregator, p_aggregator_pad: *gstbase.AggregatorPad) callconv(.c) ?*gst.Sample,
    f__gst_reserved: [15]*anyopaque,

    pub fn as(p_instance: *AggregatorClass, comptime P_T: type) *P_T {
        return gobject.ext.as(P_T, p_instance);
    }

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

pub const AggregatorPadClass = extern struct {
    pub const Instance = gstbase.AggregatorPad;

    f_parent_class: gst.PadClass,
    /// Optional
    ///               Called when the pad has received a flush stop, this is the place
    ///               to flush any information specific to the pad, it allows for individual
    ///               pads to be flushed while others might not be.
    f_flush: ?*const fn (p_aggpad: *gstbase.AggregatorPad, p_aggregator: *gstbase.Aggregator) callconv(.c) gst.FlowReturn,
    /// Optional
    ///               Called before input buffers are queued in the pad, return `TRUE`
    ///               if the buffer should be skipped.
    f_skip_buffer: ?*const fn (p_aggpad: *gstbase.AggregatorPad, p_aggregator: *gstbase.Aggregator, p_buffer: *gst.Buffer) callconv(.c) c_int,
    f__gst_reserved: [20]*anyopaque,

    pub fn as(p_instance: *AggregatorPadClass, comptime P_T: type) *P_T {
        return gobject.ext.as(P_T, p_instance);
    }

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

pub const AggregatorPadPrivate = opaque {
    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

pub const AggregatorPrivate = opaque {
    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// Subclasses can override any of the available virtual methods or not, as
/// needed. At minimum `handle_frame` needs to be overridden.
pub const BaseParseClass = extern struct {
    pub const Instance = gstbase.BaseParse;

    /// the parent class
    f_parent_class: gst.ElementClass,
    /// Optional.
    ///                  Called when the element starts processing.
    ///                  Allows opening external resources.
    f_start: ?*const fn (p_parse: *gstbase.BaseParse) callconv(.c) c_int,
    /// Optional.
    ///                  Called when the element stops processing.
    ///                  Allows closing external resources.
    f_stop: ?*const fn (p_parse: *gstbase.BaseParse) callconv(.c) c_int,
    /// Optional.
    ///                  Allows the subclass to be notified of the actual caps set.
    f_set_sink_caps: ?*const fn (p_parse: *gstbase.BaseParse, p_caps: *gst.Caps) callconv(.c) c_int,
    /// Parses the input data into valid frames as defined by subclass
    ///                  which should be passed to `gstbase.BaseParse.finishFrame`.
    ///                  The frame's input buffer is guaranteed writable,
    ///                  whereas the input frame ownership is held by caller
    ///                  (so subclass should make a copy if it needs to hang on).
    ///                  Input buffer (data) is provided by baseclass with as much
    ///                  metadata set as possible by baseclass according to upstream
    ///                  information and/or subclass settings,
    ///                  though subclass may still set buffer timestamp and duration
    ///                  if desired.
    f_handle_frame: ?*const fn (p_parse: *gstbase.BaseParse, p_frame: *gstbase.BaseParseFrame, p_skipsize: *c_int) callconv(.c) gst.FlowReturn,
    /// Optional.
    ///                   Called just prior to pushing a frame (after any pending
    ///                   events have been sent) to give subclass a chance to perform
    ///                   additional actions at this time (e.g. tag sending) or to
    ///                   decide whether this buffer should be dropped or not
    ///                   (e.g. custom segment clipping).
    f_pre_push_frame: ?*const fn (p_parse: *gstbase.BaseParse, p_frame: *gstbase.BaseParseFrame) callconv(.c) gst.FlowReturn,
    /// Optional.
    ///                  Convert between formats.
    f_convert: ?*const fn (p_parse: *gstbase.BaseParse, p_src_format: gst.Format, p_src_value: i64, p_dest_format: gst.Format, p_dest_value: *i64) callconv(.c) c_int,
    /// Optional.
    ///                  Event handler on the sink pad. This function should chain
    ///                  up to the parent implementation to let the default handler
    ///                  run.
    f_sink_event: ?*const fn (p_parse: *gstbase.BaseParse, p_event: *gst.Event) callconv(.c) c_int,
    /// Optional.
    ///                  Event handler on the source pad. Should chain up to the
    ///                  parent to let the default handler run.
    f_src_event: ?*const fn (p_parse: *gstbase.BaseParse, p_event: *gst.Event) callconv(.c) c_int,
    /// Optional.
    ///                  Allows the subclass to do its own sink get caps if needed.
    f_get_sink_caps: ?*const fn (p_parse: *gstbase.BaseParse, p_filter: *gst.Caps) callconv(.c) *gst.Caps,
    /// Optional.
    ///                   Called until it doesn't return GST_FLOW_OK anymore for
    ///                   the first buffers. Can be used by the subclass to detect
    ///                   the stream format.
    f_detect: ?*const fn (p_parse: *gstbase.BaseParse, p_buffer: *gst.Buffer) callconv(.c) gst.FlowReturn,
    /// Optional.
    ///                   Query handler on the sink pad. This function should chain
    ///                   up to the parent implementation to let the default handler
    ///                   run (Since: 1.2)
    f_sink_query: ?*const fn (p_parse: *gstbase.BaseParse, p_query: *gst.Query) callconv(.c) c_int,
    /// Optional.
    ///                   Query handler on the source pad. Should chain up to the
    ///                   parent to let the default handler run (Since: 1.2)
    f_src_query: ?*const fn (p_parse: *gstbase.BaseParse, p_query: *gst.Query) callconv(.c) c_int,
    f__gst_reserved: [18]*anyopaque,

    pub fn as(p_instance: *BaseParseClass, comptime P_T: type) *P_T {
        return gobject.ext.as(P_T, p_instance);
    }

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// Frame (context) data passed to each frame parsing virtual methods.  In
/// addition to providing the data to be checked for a valid frame or an already
/// identified frame, it conveys additional metadata or control information
/// from and to the subclass w.r.t. the particular frame in question (rather
/// than global parameters).  Some of these may apply to each parsing stage, others
/// only to some a particular one.  These parameters are effectively zeroed at start
/// of each frame's processing, i.e. parsing virtual method invocation sequence.
pub const BaseParseFrame = extern struct {
    /// input data to be parsed for frames.
    f_buffer: ?*gst.Buffer,
    /// output data.
    f_out_buffer: ?*gst.Buffer,
    /// a combination of input and output `gstbase.BaseParseFrameFlags` that
    ///  convey additional context to subclass or allow subclass to tune
    ///  subsequent `gstbase.BaseParse` actions.
    f_flags: c_uint,
    /// media specific offset of input frame
    ///   Note that a converter may have a different one on the frame's buffer.
    f_offset: u64,
    /// subclass can set this to indicates the metadata overhead
    ///   for the given frame, which is then used to enable more accurate bitrate
    ///   computations. If this is -1, it is assumed that this frame should be
    ///   skipped in bitrate calculation.
    f_overhead: c_int,
    f_size: c_int,
    f__gst_reserved_i: [2]c_uint,
    f__gst_reserved_p: [2]*anyopaque,
    f__private_flags: c_uint,

    /// Allocates a new `gstbase.BaseParseFrame`. This function is mainly for bindings,
    /// elements written in C should usually allocate the frame on the stack and
    /// then use `gstbase.BaseParseFrame.init` to initialise it.
    extern fn gst_base_parse_frame_new(p_buffer: *gst.Buffer, p_flags: gstbase.BaseParseFrameFlags, p_overhead: c_int) *gstbase.BaseParseFrame;
    pub const new = gst_base_parse_frame_new;

    /// Copies a `gstbase.BaseParseFrame`.
    extern fn gst_base_parse_frame_copy(p_frame: *BaseParseFrame) *gstbase.BaseParseFrame;
    pub const copy = gst_base_parse_frame_copy;

    /// Frees the provided `frame`.
    extern fn gst_base_parse_frame_free(p_frame: *BaseParseFrame) void;
    pub const free = gst_base_parse_frame_free;

    /// Sets a `gstbase.BaseParseFrame` to initial state.  Currently this means
    /// all public fields are zero-ed and a private flag is set to make
    /// sure `gstbase.BaseParseFrame.free` only frees the contents but not
    /// the actual frame. Use this function to initialise a `gstbase.BaseParseFrame`
    /// allocated on the stack.
    extern fn gst_base_parse_frame_init(p_frame: *BaseParseFrame) void;
    pub const init = gst_base_parse_frame_init;

    extern fn gst_base_parse_frame_get_type() usize;
    pub const getGObjectType = gst_base_parse_frame_get_type;

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

pub const BaseParsePrivate = opaque {
    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// Subclasses can override any of the available virtual methods or not, as
/// needed. At the minimum, the `render` method should be overridden to
/// output/present buffers.
pub const BaseSinkClass = extern struct {
    pub const Instance = gstbase.BaseSink;

    /// Element parent class
    f_parent_class: gst.ElementClass,
    /// Called to get sink pad caps from the subclass
    f_get_caps: ?*const fn (p_sink: *gstbase.BaseSink, p_filter: ?*gst.Caps) callconv(.c) *gst.Caps,
    /// Notify subclass of changed caps
    f_set_caps: ?*const fn (p_sink: *gstbase.BaseSink, p_caps: *gst.Caps) callconv(.c) c_int,
    /// Only useful in pull mode. Implement if you have
    ///     ideas about what should be the default values for the caps you support.
    f_fixate: ?*const fn (p_sink: *gstbase.BaseSink, p_caps: *gst.Caps) callconv(.c) *gst.Caps,
    /// Subclasses should override this when they can provide an
    ///     alternate method of spawning a thread to drive the pipeline in pull mode.
    ///     Should start or stop the pulling thread, depending on the value of the
    ///     "active" argument. Called after actually activating the sink pad in pull
    ///     mode. The default implementation starts a task on the sink pad.
    f_activate_pull: ?*const fn (p_sink: *gstbase.BaseSink, p_active: c_int) callconv(.c) c_int,
    /// Called to get the start and end times for synchronising
    ///     the passed buffer to the clock
    f_get_times: ?*const fn (p_sink: *gstbase.BaseSink, p_buffer: *gst.Buffer, p_start: *gst.ClockTime, p_end: *gst.ClockTime) callconv(.c) void,
    /// configure the allocation query
    f_propose_allocation: ?*const fn (p_sink: *gstbase.BaseSink, p_query: *gst.Query) callconv(.c) c_int,
    /// Start processing. Ideal for opening resources in the subclass
    f_start: ?*const fn (p_sink: *gstbase.BaseSink) callconv(.c) c_int,
    /// Stop processing. Subclasses should use this to close resources.
    f_stop: ?*const fn (p_sink: *gstbase.BaseSink) callconv(.c) c_int,
    /// Unlock any pending access to the resource. Subclasses should
    ///     unblock any blocked function ASAP and call `gstbase.BaseSink.waitPreroll`
    f_unlock: ?*const fn (p_sink: *gstbase.BaseSink) callconv(.c) c_int,
    /// Clear the previous unlock request. Subclasses should clear
    ///     any state they set during `gstbase.BaseSinkClass.signals.unlock`, and be ready to
    ///     continue where they left off after `gstbase.BaseSink.waitPreroll`,
    ///     `gstbase.BaseSink.wait` or `gst_wait_sink_wait_clock` return or
    ///     `gstbase.BaseSinkClass.signals.render` is called again.
    f_unlock_stop: ?*const fn (p_sink: *gstbase.BaseSink) callconv(.c) c_int,
    /// perform a `gst.Query` on the element.
    f_query: ?*const fn (p_sink: *gstbase.BaseSink, p_query: *gst.Query) callconv(.c) c_int,
    /// Override this to handle events arriving on the sink pad
    f_event: ?*const fn (p_sink: *gstbase.BaseSink, p_event: *gst.Event) callconv(.c) c_int,
    /// Override this to implement custom logic to wait for the event
    ///     time (for events like EOS and GAP). Subclasses should always first
    ///     chain up to the default implementation.
    f_wait_event: ?*const fn (p_sink: *gstbase.BaseSink, p_event: *gst.Event) callconv(.c) gst.FlowReturn,
    /// Called to prepare the buffer for `render` and `preroll`. This
    ///     function is called before synchronisation is performed.
    f_prepare: ?*const fn (p_sink: *gstbase.BaseSink, p_buffer: *gst.Buffer) callconv(.c) gst.FlowReturn,
    /// Called to prepare the buffer list for `render_list`. This
    ///     function is called before synchronisation is performed.
    f_prepare_list: ?*const fn (p_sink: *gstbase.BaseSink, p_buffer_list: *gst.BufferList) callconv(.c) gst.FlowReturn,
    /// Called to present the preroll buffer if desired.
    f_preroll: ?*const fn (p_sink: *gstbase.BaseSink, p_buffer: *gst.Buffer) callconv(.c) gst.FlowReturn,
    /// Called when a buffer should be presented or output, at the
    ///     correct moment if the `gstbase.BaseSink` has been set to sync to the clock.
    f_render: ?*const fn (p_sink: *gstbase.BaseSink, p_buffer: *gst.Buffer) callconv(.c) gst.FlowReturn,
    /// Same as `render` but used with buffer lists instead of
    ///     buffers.
    f_render_list: ?*const fn (p_sink: *gstbase.BaseSink, p_buffer_list: *gst.BufferList) callconv(.c) gst.FlowReturn,
    f__gst_reserved: [20]*anyopaque,

    pub fn as(p_instance: *BaseSinkClass, comptime P_T: type) *P_T {
        return gobject.ext.as(P_T, p_instance);
    }

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

pub const BaseSinkPrivate = opaque {
    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// Subclasses can override any of the available virtual methods or not, as
/// needed. At the minimum, the `create` method should be overridden to produce
/// buffers.
pub const BaseSrcClass = extern struct {
    pub const Instance = gstbase.BaseSrc;

    /// Element parent class
    f_parent_class: gst.ElementClass,
    /// Called to get the caps to report
    f_get_caps: ?*const fn (p_src: *gstbase.BaseSrc, p_filter: ?*gst.Caps) callconv(.c) *gst.Caps,
    /// Negotiated the caps with the peer.
    f_negotiate: ?*const fn (p_src: *gstbase.BaseSrc) callconv(.c) c_int,
    /// Called during negotiation if caps need fixating. Implement instead of
    ///   setting a fixate function on the source pad.
    f_fixate: ?*const fn (p_src: *gstbase.BaseSrc, p_caps: *gst.Caps) callconv(.c) *gst.Caps,
    /// Notify subclass of changed output caps
    f_set_caps: ?*const fn (p_src: *gstbase.BaseSrc, p_caps: *gst.Caps) callconv(.c) c_int,
    /// configure the allocation query
    f_decide_allocation: ?*const fn (p_src: *gstbase.BaseSrc, p_query: *gst.Query) callconv(.c) c_int,
    /// Start processing. Subclasses should open resources and prepare
    ///    to produce data. Implementation should call `gstbase.BaseSrc.startComplete`
    ///    when the operation completes, either from the current thread or any other
    ///    thread that finishes the start operation asynchronously.
    f_start: ?*const fn (p_src: *gstbase.BaseSrc) callconv(.c) c_int,
    /// Stop processing. Subclasses should use this to close resources.
    f_stop: ?*const fn (p_src: *gstbase.BaseSrc) callconv(.c) c_int,
    /// Given a buffer, return the start and stop time when it
    ///    should be pushed out. The base class will sync on the clock using
    ///    these times.
    f_get_times: ?*const fn (p_src: *gstbase.BaseSrc, p_buffer: *gst.Buffer, p_start: *gst.ClockTime, p_end: *gst.ClockTime) callconv(.c) void,
    /// Return the total size of the resource, in the format set by
    ///     `gstbase.BaseSrc.setFormat`.
    f_get_size: ?*const fn (p_src: *gstbase.BaseSrc, p_size: *u64) callconv(.c) c_int,
    /// Check if the source can seek
    f_is_seekable: ?*const fn (p_src: *gstbase.BaseSrc) callconv(.c) c_int,
    /// Prepare the `gst.Segment` that will be passed to the
    ///   `gstbase.BaseSrcClass.signals.do_seek` vmethod for executing a seek
    ///   request. Sub-classes should override this if they support seeking in
    ///   formats other than the configured native format. By default, it tries to
    ///   convert the seek arguments to the configured native format and prepare a
    ///   segment in that format.
    f_prepare_seek_segment: ?*const fn (p_src: *gstbase.BaseSrc, p_seek: *gst.Event, p_segment: *gst.Segment) callconv(.c) c_int,
    /// Perform seeking on the resource to the indicated segment.
    f_do_seek: ?*const fn (p_src: *gstbase.BaseSrc, p_segment: *gst.Segment) callconv(.c) c_int,
    /// Unlock any pending access to the resource. Subclasses should unblock
    ///    any blocked function ASAP. In particular, any ``create`` function in
    ///    progress should be unblocked and should return GST_FLOW_FLUSHING. Any
    ///    future `gstbase.BaseSrcClass.signals.create` function call should also return
    ///    GST_FLOW_FLUSHING until the `gstbase.BaseSrcClass.signals.unlock_stop` function has
    ///    been called.
    f_unlock: ?*const fn (p_src: *gstbase.BaseSrc) callconv(.c) c_int,
    /// Clear the previous unlock request. Subclasses should clear any
    ///    state they set during `gstbase.BaseSrcClass.signals.unlock`, such as clearing command
    ///    queues.
    f_unlock_stop: ?*const fn (p_src: *gstbase.BaseSrc) callconv(.c) c_int,
    /// Handle a requested query.
    f_query: ?*const fn (p_src: *gstbase.BaseSrc, p_query: *gst.Query) callconv(.c) c_int,
    /// Override this to implement custom event handling.
    f_event: ?*const fn (p_src: *gstbase.BaseSrc, p_event: *gst.Event) callconv(.c) c_int,
    /// Ask the subclass to create a buffer with offset and size.  When the
    ///   subclass returns GST_FLOW_OK, it MUST return a buffer of the requested size
    ///   unless fewer bytes are available because an EOS condition is near. No
    ///   buffer should be returned when the return value is different from
    ///   GST_FLOW_OK. A return value of GST_FLOW_EOS signifies that the end of
    ///   stream is reached. The default implementation will call
    ///   `gstbase.BaseSrcClass.signals.alloc` and then call `gstbase.BaseSrcClass.signals.fill`.
    f_create: ?*const fn (p_src: *gstbase.BaseSrc, p_offset: u64, p_size: c_uint, p_buf: ?**gst.Buffer) callconv(.c) gst.FlowReturn,
    /// Ask the subclass to allocate a buffer with for offset and size. The
    ///   default implementation will create a new buffer from the negotiated allocator.
    f_alloc: ?*const fn (p_src: *gstbase.BaseSrc, p_offset: u64, p_size: c_uint, p_buf: ?**gst.Buffer) callconv(.c) gst.FlowReturn,
    /// Ask the subclass to fill the buffer with data for offset and size. The
    ///   passed buffer is guaranteed to hold the requested amount of bytes.
    f_fill: ?*const fn (p_src: *gstbase.BaseSrc, p_offset: u64, p_size: c_uint, p_buf: *gst.Buffer) callconv(.c) gst.FlowReturn,
    f__gst_reserved: [20]*anyopaque,

    pub fn as(p_instance: *BaseSrcClass, comptime P_T: type) *P_T {
        return gobject.ext.as(P_T, p_instance);
    }

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

pub const BaseSrcPrivate = opaque {
    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// Subclasses can override any of the available virtual methods or not, as
/// needed. At minimum either `transform` or `transform_ip` need to be overridden.
/// If the element can overwrite the input data with the results (data is of the
/// same type and quantity) it should provide `transform_ip`.
pub const BaseTransformClass = extern struct {
    pub const Instance = gstbase.BaseTransform;

    /// Element parent class
    f_parent_class: gst.ElementClass,
    /// If set to `TRUE`, passthrough mode will be
    ///                            automatically enabled if the caps are the same.
    ///                            Set to `FALSE` by default.
    f_passthrough_on_same_caps: c_int,
    /// If set to `TRUE`, `transform_ip` will be called in
    ///                           passthrough mode. The passed buffer might not be
    ///                           writable. When `FALSE`, neither `transform` nor
    ///                           `transform_ip` will be called in passthrough mode.
    ///                           Set to `TRUE` by default.
    f_transform_ip_on_passthrough: c_int,
    /// Optional.  Given the pad in this direction and the given
    ///                  caps, what caps are allowed on the other pad in this
    ///                  element ?
    f_transform_caps: ?*const fn (p_trans: *gstbase.BaseTransform, p_direction: gst.PadDirection, p_caps: *gst.Caps, p_filter: *gst.Caps) callconv(.c) *gst.Caps,
    /// Optional. Given the pad in this direction and the given
    ///                  caps, fixate the caps on the other pad. The function takes
    ///                  ownership of `othercaps` and returns a fixated version of
    ///                  `othercaps`. `othercaps` is not guaranteed to be writable.
    f_fixate_caps: ?*const fn (p_trans: *gstbase.BaseTransform, p_direction: gst.PadDirection, p_caps: *gst.Caps, p_othercaps: *gst.Caps) callconv(.c) *gst.Caps,
    /// Optional.
    ///                  Subclasses can override this method to check if `caps` can be
    ///                  handled by the element. The default implementation might not be
    ///                  the most optimal way to check this in all cases.
    f_accept_caps: ?*const fn (p_trans: *gstbase.BaseTransform, p_direction: gst.PadDirection, p_caps: *gst.Caps) callconv(.c) c_int,
    /// Allows the subclass to be notified of the actual caps set.
    f_set_caps: ?*const fn (p_trans: *gstbase.BaseTransform, p_incaps: *gst.Caps, p_outcaps: *gst.Caps) callconv(.c) c_int,
    /// Optional.
    ///                  Handle a requested query. Subclasses that implement this
    ///                  must chain up to the parent if they didn't handle the
    ///                  query
    f_query: ?*const fn (p_trans: *gstbase.BaseTransform, p_direction: gst.PadDirection, p_query: *gst.Query) callconv(.c) c_int,
    /// Setup the allocation parameters for allocating output
    ///                    buffers. The passed in query contains the result of the
    ///                    downstream allocation query. This function is only called
    ///                    when not operating in passthrough mode. The default
    ///                    implementation will remove all memory dependent metadata.
    ///                    If there is a `filter_meta` method implementation, it will
    ///                    be called for all metadata API in the downstream query,
    ///                    otherwise the metadata API is removed.
    f_decide_allocation: ?*const fn (p_trans: *gstbase.BaseTransform, p_query: *gst.Query) callconv(.c) c_int,
    /// Return `TRUE` if the metadata API should be proposed in the
    ///               upstream allocation query. The default implementation is `NULL`
    ///               and will cause all metadata to be removed.
    f_filter_meta: ?*const fn (p_trans: *gstbase.BaseTransform, p_query: *gst.Query, p_api: usize, p_params: *const gst.Structure) callconv(.c) c_int,
    /// Propose buffer allocation parameters for upstream elements.
    ///                      This function must be implemented if the element reads or
    ///                      writes the buffer content. The query that was passed to
    ///                      the decide_allocation is passed in this method (or `NULL`
    ///                      when the element is in passthrough mode). The default
    ///                      implementation will pass the query downstream when in
    ///                      passthrough mode and will copy all the filtered metadata
    ///                      API in non-passthrough mode.
    f_propose_allocation: ?*const fn (p_trans: *gstbase.BaseTransform, p_decide_query: *gst.Query, p_query: *gst.Query) callconv(.c) c_int,
    /// Optional. Given the size of a buffer in the given direction
    ///                  with the given caps, calculate the size in bytes of a buffer
    ///                  on the other pad with the given other caps.
    ///                  The default implementation uses get_unit_size and keeps
    ///                  the number of units the same.
    f_transform_size: ?*const fn (p_trans: *gstbase.BaseTransform, p_direction: gst.PadDirection, p_caps: *gst.Caps, p_size: usize, p_othercaps: *gst.Caps, p_othersize: *usize) callconv(.c) c_int,
    /// Required if the transform is not in-place.
    ///                  Get the size in bytes of one unit for the given caps.
    f_get_unit_size: ?*const fn (p_trans: *gstbase.BaseTransform, p_caps: *gst.Caps, p_size: *usize) callconv(.c) c_int,
    /// Optional.
    ///                  Called when the element starts processing.
    ///                  Allows opening external resources.
    f_start: ?*const fn (p_trans: *gstbase.BaseTransform) callconv(.c) c_int,
    /// Optional.
    ///                  Called when the element stops processing.
    ///                  Allows closing external resources.
    f_stop: ?*const fn (p_trans: *gstbase.BaseTransform) callconv(.c) c_int,
    /// Optional.
    ///                  Event handler on the sink pad. The default implementation
    ///                  handles the event and forwards it downstream.
    f_sink_event: ?*const fn (p_trans: *gstbase.BaseTransform, p_event: *gst.Event) callconv(.c) c_int,
    /// Optional.
    ///                  Event handler on the source pad. The default implementation
    ///                  handles the event and forwards it upstream.
    f_src_event: ?*const fn (p_trans: *gstbase.BaseTransform, p_event: *gst.Event) callconv(.c) c_int,
    /// Optional.
    ///                         Subclasses can override this to do their own
    ///                         allocation of output buffers.  Elements that only do
    ///                         analysis can return a subbuffer or even just
    ///                         return a reference to the input buffer (if in
    ///                         passthrough mode). The default implementation will
    ///                         use the negotiated allocator or bufferpool and
    ///                         transform_size to allocate an output buffer or it
    ///                         will return the input buffer in passthrough mode.
    f_prepare_output_buffer: ?*const fn (p_trans: *gstbase.BaseTransform, p_input: *gst.Buffer, p_outbuf: **gst.Buffer) callconv(.c) gst.FlowReturn,
    /// Optional.
    ///                 Copy the metadata from the input buffer to the output buffer.
    ///                 The default implementation will copy the flags, timestamps and
    ///                 offsets of the buffer.
    f_copy_metadata: ?*const fn (p_trans: *gstbase.BaseTransform, p_input: *gst.Buffer, p_outbuf: *gst.Buffer) callconv(.c) c_int,
    /// Optional. Transform the metadata on the input buffer to the
    ///                  output buffer. By default this method copies all meta without
    ///                  tags. Subclasses can implement this method and return `TRUE` if
    ///                  the metadata is to be copied.
    f_transform_meta: ?*const fn (p_trans: *gstbase.BaseTransform, p_outbuf: *gst.Buffer, p_meta: *gst.Meta, p_inbuf: *gst.Buffer) callconv(.c) c_int,
    /// Optional.
    ///                    This method is called right before the base class will
    ///                    start processing. Dynamic properties or other delayed
    ///                    configuration could be performed in this method.
    f_before_transform: ?*const fn (p_trans: *gstbase.BaseTransform, p_buffer: *gst.Buffer) callconv(.c) void,
    /// Required if the element does not operate in-place.
    ///                  Transforms one incoming buffer to one outgoing buffer.
    ///                  The function is allowed to change size/timestamp/duration
    ///                  of the outgoing buffer.
    f_transform: ?*const fn (p_trans: *gstbase.BaseTransform, p_inbuf: *gst.Buffer, p_outbuf: *gst.Buffer) callconv(.c) gst.FlowReturn,
    /// Required if the element operates in-place.
    ///                  Transform the incoming buffer in-place.
    f_transform_ip: ?*const fn (p_trans: *gstbase.BaseTransform, p_buf: *gst.Buffer) callconv(.c) gst.FlowReturn,
    /// Function which accepts a new input buffer and pre-processes it.
    ///                  The default implementation performs caps (re)negotiation, then
    ///                  QoS if needed, and places the input buffer into the `queued_buf`
    ///                  member variable. If the buffer is dropped due to QoS, it returns
    ///                  GST_BASE_TRANSFORM_FLOW_DROPPED. If this input buffer is not
    ///                  contiguous with any previous input buffer, then `is_discont`
    ///                  is set to `TRUE`. (Since: 1.6)
    f_submit_input_buffer: ?*const fn (p_trans: *gstbase.BaseTransform, p_is_discont: c_int, p_input: *gst.Buffer) callconv(.c) gst.FlowReturn,
    /// Called after each new input buffer is submitted repeatedly
    ///                   until it either generates an error or fails to generate an output
    ///                   buffer. The default implementation takes the contents of the
    ///                   `queued_buf` variable, generates an output buffer if needed
    ///                   by calling the class `prepare_output_buffer`, and then
    ///                   calls either `transform` or `transform_ip`. Elements that don't
    ///                   do 1-to-1 transformations of input to output buffers can either
    ///                   return GST_BASE_TRANSFORM_FLOW_DROPPED or simply not generate
    ///                   an output buffer until they are ready to do so. (Since: 1.6)
    f_generate_output: ?*const fn (p_trans: *gstbase.BaseTransform, p_outbuf: **gst.Buffer) callconv(.c) gst.FlowReturn,
    f__gst_reserved: [18]*anyopaque,

    pub fn as(p_instance: *BaseTransformClass, comptime P_T: type) *P_T {
        return gobject.ext.as(P_T, p_instance);
    }

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

pub const BaseTransformPrivate = opaque {
    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// `gstbase.BitReader` provides a bit reader that can read any number of bits
/// from a memory buffer. It provides functions for reading any number of bits
/// into 8, 16, 32 and 64 bit variables.
pub const BitReader = extern struct {
    /// Data from which the bit reader will
    ///   read
    f_data: ?[*]const u8,
    /// Size of `data` in bytes
    f_size: c_uint,
    /// Current byte position
    f_byte: c_uint,
    /// Bit position in the current byte
    f_bit: c_uint,
    f__gst_reserved: [4]*anyopaque,

    /// Create a new `gstbase.BitReader` instance, which will read from `data`.
    ///
    /// Free-function: gst_bit_reader_free
    extern fn gst_bit_reader_new(p_data: [*]const u8, p_size: c_uint) *gstbase.BitReader;
    pub const new = gst_bit_reader_new;

    /// Frees a `gstbase.BitReader` instance, which was previously allocated by
    /// `gstbase.bitReaderNew`.
    extern fn gst_bit_reader_free(p_reader: *BitReader) void;
    pub const free = gst_bit_reader_free;

    /// Read `nbits` bits into `val` and update the current position.
    extern fn gst_bit_reader_get_bits_uint16(p_reader: *BitReader, p_val: *u16, p_nbits: c_uint) c_int;
    pub const getBitsUint16 = gst_bit_reader_get_bits_uint16;

    /// Read `nbits` bits into `val` and update the current position.
    extern fn gst_bit_reader_get_bits_uint32(p_reader: *BitReader, p_val: *u32, p_nbits: c_uint) c_int;
    pub const getBitsUint32 = gst_bit_reader_get_bits_uint32;

    /// Read `nbits` bits into `val` and update the current position.
    extern fn gst_bit_reader_get_bits_uint64(p_reader: *BitReader, p_val: *u64, p_nbits: c_uint) c_int;
    pub const getBitsUint64 = gst_bit_reader_get_bits_uint64;

    /// Read `nbits` bits into `val` and update the current position.
    extern fn gst_bit_reader_get_bits_uint8(p_reader: *BitReader, p_val: *u8, p_nbits: c_uint) c_int;
    pub const getBitsUint8 = gst_bit_reader_get_bits_uint8;

    /// Returns the current position of a `gstbase.BitReader` instance in bits.
    extern fn gst_bit_reader_get_pos(p_reader: *const BitReader) c_uint;
    pub const getPos = gst_bit_reader_get_pos;

    /// Returns the remaining number of bits of a `gstbase.BitReader` instance.
    extern fn gst_bit_reader_get_remaining(p_reader: *const BitReader) c_uint;
    pub const getRemaining = gst_bit_reader_get_remaining;

    /// Returns the total number of bits of a `gstbase.BitReader` instance.
    extern fn gst_bit_reader_get_size(p_reader: *const BitReader) c_uint;
    pub const getSize = gst_bit_reader_get_size;

    /// Initializes a `gstbase.BitReader` instance to read from `data`. This function
    /// can be called on already initialized instances.
    extern fn gst_bit_reader_init(p_reader: *BitReader, p_data: [*]const u8, p_size: c_uint) void;
    pub const init = gst_bit_reader_init;

    /// Read `nbits` bits into `val` but keep the current position.
    extern fn gst_bit_reader_peek_bits_uint16(p_reader: *const BitReader, p_val: *u16, p_nbits: c_uint) c_int;
    pub const peekBitsUint16 = gst_bit_reader_peek_bits_uint16;

    /// Read `nbits` bits into `val` but keep the current position.
    extern fn gst_bit_reader_peek_bits_uint32(p_reader: *const BitReader, p_val: *u32, p_nbits: c_uint) c_int;
    pub const peekBitsUint32 = gst_bit_reader_peek_bits_uint32;

    /// Read `nbits` bits into `val` but keep the current position.
    extern fn gst_bit_reader_peek_bits_uint64(p_reader: *const BitReader, p_val: *u64, p_nbits: c_uint) c_int;
    pub const peekBitsUint64 = gst_bit_reader_peek_bits_uint64;

    /// Read `nbits` bits into `val` but keep the current position.
    extern fn gst_bit_reader_peek_bits_uint8(p_reader: *const BitReader, p_val: *u8, p_nbits: c_uint) c_int;
    pub const peekBitsUint8 = gst_bit_reader_peek_bits_uint8;

    /// Sets the new position of a `gstbase.BitReader` instance to `pos` in bits.
    extern fn gst_bit_reader_set_pos(p_reader: *BitReader, p_pos: c_uint) c_int;
    pub const setPos = gst_bit_reader_set_pos;

    /// Skips `nbits` bits of the `gstbase.BitReader` instance.
    extern fn gst_bit_reader_skip(p_reader: *BitReader, p_nbits: c_uint) c_int;
    pub const skip = gst_bit_reader_skip;

    /// Skips until the next byte.
    extern fn gst_bit_reader_skip_to_byte(p_reader: *BitReader) c_int;
    pub const skipToByte = gst_bit_reader_skip_to_byte;

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// `gstbase.BitWriter` provides a bit writer that can write any number of
/// bits into a memory buffer. It provides functions for writing any
/// number of bits into 8, 16, 32 and 64 bit variables.
pub const BitWriter = extern struct {
    /// Allocated `data` for bit writer to write
    f_data: ?*u8,
    /// Size of written `data` in bits
    f_bit_size: c_uint,
    f_bit_capacity: c_uint,
    f_auto_grow: c_int,
    f_owned: c_int,
    f__gst_reserved: [4]*anyopaque,

    /// Creates a new, empty `gstbase.BitWriter` instance.
    ///
    /// Free-function: gst_bit_writer_free
    extern fn gst_bit_writer_new() *gstbase.BitWriter;
    pub const new = gst_bit_writer_new;

    /// Creates a new `gstbase.BitWriter` instance with the given memory area. If
    /// `initialized` is `TRUE` it is possible to read `size` bits from the
    /// `gstbase.BitWriter` from the beginning.
    ///
    /// Free-function: gst_bit_writer_free
    extern fn gst_bit_writer_new_with_data(p_data: [*]u8, p_size: c_uint, p_initialized: c_int) *gstbase.BitWriter;
    pub const newWithData = gst_bit_writer_new_with_data;

    /// Creates a `gstbase.BitWriter` instance with the given initial data size.
    ///
    /// Free-function: gst_bit_writer_free
    extern fn gst_bit_writer_new_with_size(p_size: u32, p_fixed: c_int) *gstbase.BitWriter;
    pub const newWithSize = gst_bit_writer_new_with_size;

    /// Write trailing bit to align last byte of `data`. `trailing_bit` can
    /// only be 1 or 0.
    extern fn gst_bit_writer_align_bytes(p_bitwriter: *BitWriter, p_trailing_bit: u8) c_int;
    pub const alignBytes = gst_bit_writer_align_bytes;

    /// Frees `bitwriter` and the allocated data inside.
    extern fn gst_bit_writer_free(p_bitwriter: *BitWriter) void;
    pub const free = gst_bit_writer_free;

    /// Frees `bitwriter` without destroying the internal data, which is
    /// returned as `gst.Buffer`.
    ///
    /// Free-function: gst_buffer_unref
    extern fn gst_bit_writer_free_and_get_buffer(p_bitwriter: *BitWriter) *gst.Buffer;
    pub const freeAndGetBuffer = gst_bit_writer_free_and_get_buffer;

    /// Frees `bitwriter` without destroying the internal data, which is
    /// returned.
    ///
    /// Free-function: g_free
    extern fn gst_bit_writer_free_and_get_data(p_bitwriter: *BitWriter) [*]u8;
    pub const freeAndGetData = gst_bit_writer_free_and_get_data;

    /// Get written data pointer
    extern fn gst_bit_writer_get_data(p_bitwriter: *const BitWriter) [*]u8;
    pub const getData = gst_bit_writer_get_data;

    /// Get size of written `data`
    extern fn gst_bit_writer_get_size(p_bitwriter: *const BitWriter) c_uint;
    pub const getSize = gst_bit_writer_get_size;

    /// Initializes `bitwriter` to an empty instance.
    extern fn gst_bit_writer_init(p_bitwriter: *BitWriter) void;
    pub const init = gst_bit_writer_init;

    /// Initializes `bitwriter` with the given memory area `data`. IF
    /// `initialized` is `TRUE` it is possible to read `size` bits from the
    /// `gstbase.BitWriter` from the beginning.
    extern fn gst_bit_writer_init_with_data(p_bitwriter: *BitWriter, p_data: [*]u8, p_size: c_uint, p_initialized: c_int) void;
    pub const initWithData = gst_bit_writer_init_with_data;

    /// Initializes a `gstbase.BitWriter` instance and allocates the given data
    /// `size`.
    extern fn gst_bit_writer_init_with_size(p_bitwriter: *BitWriter, p_size: u32, p_fixed: c_int) void;
    pub const initWithSize = gst_bit_writer_init_with_size;

    /// Write `nbits` bits of `value` to `gstbase.BitWriter`.
    extern fn gst_bit_writer_put_bits_uint16(p_bitwriter: *BitWriter, p_value: u16, p_nbits: c_uint) c_int;
    pub const putBitsUint16 = gst_bit_writer_put_bits_uint16;

    /// Write `nbits` bits of `value` to `gstbase.BitWriter`.
    extern fn gst_bit_writer_put_bits_uint32(p_bitwriter: *BitWriter, p_value: u32, p_nbits: c_uint) c_int;
    pub const putBitsUint32 = gst_bit_writer_put_bits_uint32;

    /// Write `nbits` bits of `value` to `gstbase.BitWriter`.
    extern fn gst_bit_writer_put_bits_uint64(p_bitwriter: *BitWriter, p_value: u64, p_nbits: c_uint) c_int;
    pub const putBitsUint64 = gst_bit_writer_put_bits_uint64;

    /// Write `nbits` bits of `value` to `gstbase.BitWriter`.
    extern fn gst_bit_writer_put_bits_uint8(p_bitwriter: *BitWriter, p_value: u8, p_nbits: c_uint) c_int;
    pub const putBitsUint8 = gst_bit_writer_put_bits_uint8;

    /// Write `nbytes` bytes of `data` to `gstbase.BitWriter`.
    extern fn gst_bit_writer_put_bytes(p_bitwriter: *BitWriter, p_data: [*]const u8, p_nbytes: c_uint) c_int;
    pub const putBytes = gst_bit_writer_put_bytes;

    /// Resets `bitwriter` and frees the data if it's owned by `bitwriter`.
    extern fn gst_bit_writer_reset(p_bitwriter: *BitWriter) void;
    pub const reset = gst_bit_writer_reset;

    /// Resets `bitwriter` and returns the current data as `gst.Buffer`.
    ///
    /// Free-function: gst_buffer_unref
    extern fn gst_bit_writer_reset_and_get_buffer(p_bitwriter: *BitWriter) *gst.Buffer;
    pub const resetAndGetBuffer = gst_bit_writer_reset_and_get_buffer;

    /// Resets `bitwriter` and returns the current data.
    ///
    /// Free-function: g_free
    extern fn gst_bit_writer_reset_and_get_data(p_bitwriter: *BitWriter) [*]u8;
    pub const resetAndGetData = gst_bit_writer_reset_and_get_data;

    extern fn gst_bit_writer_set_pos(p_bitwriter: *BitWriter, p_pos: c_uint) c_int;
    pub const setPos = gst_bit_writer_set_pos;

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// `gstbase.ByteReader` provides a byte reader that can read different integer and
/// floating point types from a memory buffer. It provides functions for reading
/// signed/unsigned, little/big endian integers of 8, 16, 24, 32 and 64 bits
/// and functions for reading little/big endian floating points numbers of
/// 32 and 64 bits. It also provides functions to read NUL-terminated strings
/// in various character encodings.
pub const ByteReader = extern struct {
    /// Data from which the bit reader will
    ///   read
    f_data: ?[*]const u8,
    /// Size of `data` in bytes
    f_size: c_uint,
    /// Current byte position
    f_byte: c_uint,
    f__gst_reserved: [4]*anyopaque,

    /// Create a new `gstbase.ByteReader` instance, which will read from `data`.
    ///
    /// Free-function: gst_byte_reader_free
    extern fn gst_byte_reader_new(p_data: [*]const u8, p_size: c_uint) *gstbase.ByteReader;
    pub const new = gst_byte_reader_new;

    /// Free-function: g_free
    ///
    /// Returns a newly-allocated copy of the current data
    /// position if at least `size` bytes are left and
    /// updates the current position. Free with `glib.free` when no longer needed.
    extern fn gst_byte_reader_dup_data(p_reader: *ByteReader, p_size: c_uint, p_val: *[*]u8) c_int;
    pub const dupData = gst_byte_reader_dup_data;

    /// Free-function: g_free
    ///
    /// Returns a newly-allocated copy of the current data position if there is
    /// a NUL-terminated UTF-16 string in the data (this could be an empty string
    /// as well), and advances the current position.
    ///
    /// No input checking for valid UTF-16 is done. This function is endianness
    /// agnostic - you should not assume the UTF-16 characters are in host
    /// endianness.
    ///
    /// This function will fail if no NUL-terminator was found in in the data.
    ///
    /// Note: there is no peek or get variant of this function to ensure correct
    /// byte alignment of the UTF-16 string.
    extern fn gst_byte_reader_dup_string_utf16(p_reader: *ByteReader, p_str: *[*]u16) c_int;
    pub const dupStringUtf16 = gst_byte_reader_dup_string_utf16;

    /// Free-function: g_free
    ///
    /// Returns a newly-allocated copy of the current data position if there is
    /// a NUL-terminated UTF-32 string in the data (this could be an empty string
    /// as well), and advances the current position.
    ///
    /// No input checking for valid UTF-32 is done. This function is endianness
    /// agnostic - you should not assume the UTF-32 characters are in host
    /// endianness.
    ///
    /// This function will fail if no NUL-terminator was found in in the data.
    ///
    /// Note: there is no peek or get variant of this function to ensure correct
    /// byte alignment of the UTF-32 string.
    extern fn gst_byte_reader_dup_string_utf32(p_reader: *ByteReader, p_str: *[*]u32) c_int;
    pub const dupStringUtf32 = gst_byte_reader_dup_string_utf32;

    /// Free-function: g_free
    ///
    /// FIXME:Reads (copies) a NUL-terminated string in the `gstbase.ByteReader` instance,
    /// advancing the current position to the byte after the string. This will work
    /// for any NUL-terminated string with a character width of 8 bits, so ASCII,
    /// UTF-8, ISO-8859-N etc. No input checking for valid UTF-8 is done.
    ///
    /// This function will fail if no NUL-terminator was found in in the data.
    extern fn gst_byte_reader_dup_string_utf8(p_reader: *ByteReader, p_str: *[*]u8) c_int;
    pub const dupStringUtf8 = gst_byte_reader_dup_string_utf8;

    /// Frees a `gstbase.ByteReader` instance, which was previously allocated by
    /// `gstbase.byteReaderNew`.
    extern fn gst_byte_reader_free(p_reader: *ByteReader) void;
    pub const free = gst_byte_reader_free;

    /// Returns a constant pointer to the current data
    /// position if at least `size` bytes are left and
    /// updates the current position.
    extern fn gst_byte_reader_get_data(p_reader: *ByteReader, p_size: c_uint, p_val: *[*]const u8) c_int;
    pub const getData = gst_byte_reader_get_data;

    /// Read a 32 bit big endian floating point value into `val`
    /// and update the current position.
    extern fn gst_byte_reader_get_float32_be(p_reader: *ByteReader, p_val: *f32) c_int;
    pub const getFloat32Be = gst_byte_reader_get_float32_be;

    /// Read a 32 bit little endian floating point value into `val`
    /// and update the current position.
    extern fn gst_byte_reader_get_float32_le(p_reader: *ByteReader, p_val: *f32) c_int;
    pub const getFloat32Le = gst_byte_reader_get_float32_le;

    /// Read a 64 bit big endian floating point value into `val`
    /// and update the current position.
    extern fn gst_byte_reader_get_float64_be(p_reader: *ByteReader, p_val: *f64) c_int;
    pub const getFloat64Be = gst_byte_reader_get_float64_be;

    /// Read a 64 bit little endian floating point value into `val`
    /// and update the current position.
    extern fn gst_byte_reader_get_float64_le(p_reader: *ByteReader, p_val: *f64) c_int;
    pub const getFloat64Le = gst_byte_reader_get_float64_le;

    /// Read a signed 16 bit big endian integer into `val`
    /// and update the current position.
    extern fn gst_byte_reader_get_int16_be(p_reader: *ByteReader, p_val: *i16) c_int;
    pub const getInt16Be = gst_byte_reader_get_int16_be;

    /// Read a signed 16 bit little endian integer into `val`
    /// and update the current position.
    extern fn gst_byte_reader_get_int16_le(p_reader: *ByteReader, p_val: *i16) c_int;
    pub const getInt16Le = gst_byte_reader_get_int16_le;

    /// Read a signed 24 bit big endian integer into `val`
    /// and update the current position.
    extern fn gst_byte_reader_get_int24_be(p_reader: *ByteReader, p_val: *i32) c_int;
    pub const getInt24Be = gst_byte_reader_get_int24_be;

    /// Read a signed 24 bit little endian integer into `val`
    /// and update the current position.
    extern fn gst_byte_reader_get_int24_le(p_reader: *ByteReader, p_val: *i32) c_int;
    pub const getInt24Le = gst_byte_reader_get_int24_le;

    /// Read a signed 32 bit big endian integer into `val`
    /// and update the current position.
    extern fn gst_byte_reader_get_int32_be(p_reader: *ByteReader, p_val: *i32) c_int;
    pub const getInt32Be = gst_byte_reader_get_int32_be;

    /// Read a signed 32 bit little endian integer into `val`
    /// and update the current position.
    extern fn gst_byte_reader_get_int32_le(p_reader: *ByteReader, p_val: *i32) c_int;
    pub const getInt32Le = gst_byte_reader_get_int32_le;

    /// Read a signed 64 bit big endian integer into `val`
    /// and update the current position.
    extern fn gst_byte_reader_get_int64_be(p_reader: *ByteReader, p_val: *i64) c_int;
    pub const getInt64Be = gst_byte_reader_get_int64_be;

    /// Read a signed 64 bit little endian integer into `val`
    /// and update the current position.
    extern fn gst_byte_reader_get_int64_le(p_reader: *ByteReader, p_val: *i64) c_int;
    pub const getInt64Le = gst_byte_reader_get_int64_le;

    /// Read a signed 8 bit integer into `val` and update the current position.
    extern fn gst_byte_reader_get_int8(p_reader: *ByteReader, p_val: *i8) c_int;
    pub const getInt8 = gst_byte_reader_get_int8;

    /// Returns the current position of a `gstbase.ByteReader` instance in bytes.
    extern fn gst_byte_reader_get_pos(p_reader: *const ByteReader) c_uint;
    pub const getPos = gst_byte_reader_get_pos;

    /// Returns the remaining number of bytes of a `gstbase.ByteReader` instance.
    extern fn gst_byte_reader_get_remaining(p_reader: *const ByteReader) c_uint;
    pub const getRemaining = gst_byte_reader_get_remaining;

    /// Returns the total number of bytes of a `gstbase.ByteReader` instance.
    extern fn gst_byte_reader_get_size(p_reader: *const ByteReader) c_uint;
    pub const getSize = gst_byte_reader_get_size;

    /// Returns a constant pointer to the current data position if there is
    /// a NUL-terminated string in the data (this could be just a NUL terminator),
    /// advancing the current position to the byte after the string. This will work
    /// for any NUL-terminated string with a character width of 8 bits, so ASCII,
    /// UTF-8, ISO-8859-N etc.
    ///
    /// No input checking for valid UTF-8 is done.
    ///
    /// This function will fail if no NUL-terminator was found in in the data.
    extern fn gst_byte_reader_get_string_utf8(p_reader: *ByteReader, p_str: *[*]const u8) c_int;
    pub const getStringUtf8 = gst_byte_reader_get_string_utf8;

    /// Initializes a `gstbase.ByteReader` sub-reader instance to contain `size` bytes of
    /// data from the current position of `reader`. This is useful to read chunked
    /// formats and make sure that one doesn't read beyond the size of the sub-chunk.
    ///
    /// Unlike `gstbase.ByteReader.peekSubReader`, this function also modifies the
    /// position of `reader` and moves it forward by `size` bytes.
    extern fn gst_byte_reader_get_sub_reader(p_reader: *ByteReader, p_sub_reader: *gstbase.ByteReader, p_size: c_uint) c_int;
    pub const getSubReader = gst_byte_reader_get_sub_reader;

    /// Read an unsigned 16 bit big endian integer into `val`
    /// and update the current position.
    extern fn gst_byte_reader_get_uint16_be(p_reader: *ByteReader, p_val: *u16) c_int;
    pub const getUint16Be = gst_byte_reader_get_uint16_be;

    /// Read an unsigned 16 bit little endian integer into `val`
    /// and update the current position.
    extern fn gst_byte_reader_get_uint16_le(p_reader: *ByteReader, p_val: *u16) c_int;
    pub const getUint16Le = gst_byte_reader_get_uint16_le;

    /// Read an unsigned 24 bit big endian integer into `val`
    /// and update the current position.
    extern fn gst_byte_reader_get_uint24_be(p_reader: *ByteReader, p_val: *u32) c_int;
    pub const getUint24Be = gst_byte_reader_get_uint24_be;

    /// Read an unsigned 24 bit little endian integer into `val`
    /// and update the current position.
    extern fn gst_byte_reader_get_uint24_le(p_reader: *ByteReader, p_val: *u32) c_int;
    pub const getUint24Le = gst_byte_reader_get_uint24_le;

    /// Read an unsigned 32 bit big endian integer into `val`
    /// and update the current position.
    extern fn gst_byte_reader_get_uint32_be(p_reader: *ByteReader, p_val: *u32) c_int;
    pub const getUint32Be = gst_byte_reader_get_uint32_be;

    /// Read an unsigned 32 bit little endian integer into `val`
    /// and update the current position.
    extern fn gst_byte_reader_get_uint32_le(p_reader: *ByteReader, p_val: *u32) c_int;
    pub const getUint32Le = gst_byte_reader_get_uint32_le;

    /// Read an unsigned 64 bit big endian integer into `val`
    /// and update the current position.
    extern fn gst_byte_reader_get_uint64_be(p_reader: *ByteReader, p_val: *u64) c_int;
    pub const getUint64Be = gst_byte_reader_get_uint64_be;

    /// Read an unsigned 64 bit little endian integer into `val`
    /// and update the current position.
    extern fn gst_byte_reader_get_uint64_le(p_reader: *ByteReader, p_val: *u64) c_int;
    pub const getUint64Le = gst_byte_reader_get_uint64_le;

    /// Read an unsigned 8 bit integer into `val` and update the current position.
    extern fn gst_byte_reader_get_uint8(p_reader: *ByteReader, p_val: *u8) c_int;
    pub const getUint8 = gst_byte_reader_get_uint8;

    /// Initializes a `gstbase.ByteReader` instance to read from `data`. This function
    /// can be called on already initialized instances.
    extern fn gst_byte_reader_init(p_reader: *ByteReader, p_data: [*]const u8, p_size: c_uint) void;
    pub const init = gst_byte_reader_init;

    /// Scan for pattern `pattern` with applied mask `mask` in the byte reader data,
    /// starting from offset `offset` relative to the current position.
    ///
    /// The bytes in `pattern` and `mask` are interpreted left-to-right, regardless
    /// of endianness.  All four bytes of the pattern must be present in the
    /// byte reader data for it to match, even if the first or last bytes are masked
    /// out.
    ///
    /// It is an error to call this function without making sure that there is
    /// enough data (offset+size bytes) in the byte reader.
    extern fn gst_byte_reader_masked_scan_uint32(p_reader: *const ByteReader, p_mask: u32, p_pattern: u32, p_offset: c_uint, p_size: c_uint) c_uint;
    pub const maskedScanUint32 = gst_byte_reader_masked_scan_uint32;

    /// Scan for pattern `pattern` with applied mask `mask` in the byte reader data,
    /// starting from offset `offset` relative to the current position.
    ///
    /// The bytes in `pattern` and `mask` are interpreted left-to-right, regardless
    /// of endianness.  All four bytes of the pattern must be present in the
    /// byte reader data for it to match, even if the first or last bytes are masked
    /// out.
    ///
    /// It is an error to call this function without making sure that there is
    /// enough data (offset+size bytes) in the byte reader.
    extern fn gst_byte_reader_masked_scan_uint32_peek(p_reader: *const ByteReader, p_mask: u32, p_pattern: u32, p_offset: c_uint, p_size: c_uint, p_value: *u32) c_uint;
    pub const maskedScanUint32Peek = gst_byte_reader_masked_scan_uint32_peek;

    /// Returns a constant pointer to the current data
    /// position if at least `size` bytes are left and
    /// keeps the current position.
    extern fn gst_byte_reader_peek_data(p_reader: *const ByteReader, p_size: c_uint, p_val: *[*]const u8) c_int;
    pub const peekData = gst_byte_reader_peek_data;

    /// Read a 32 bit big endian floating point value into `val`
    /// but keep the current position.
    extern fn gst_byte_reader_peek_float32_be(p_reader: *const ByteReader, p_val: *f32) c_int;
    pub const peekFloat32Be = gst_byte_reader_peek_float32_be;

    /// Read a 32 bit little endian floating point value into `val`
    /// but keep the current position.
    extern fn gst_byte_reader_peek_float32_le(p_reader: *const ByteReader, p_val: *f32) c_int;
    pub const peekFloat32Le = gst_byte_reader_peek_float32_le;

    /// Read a 64 bit big endian floating point value into `val`
    /// but keep the current position.
    extern fn gst_byte_reader_peek_float64_be(p_reader: *const ByteReader, p_val: *f64) c_int;
    pub const peekFloat64Be = gst_byte_reader_peek_float64_be;

    /// Read a 64 bit little endian floating point value into `val`
    /// but keep the current position.
    extern fn gst_byte_reader_peek_float64_le(p_reader: *const ByteReader, p_val: *f64) c_int;
    pub const peekFloat64Le = gst_byte_reader_peek_float64_le;

    /// Read a signed 16 bit big endian integer into `val`
    /// but keep the current position.
    extern fn gst_byte_reader_peek_int16_be(p_reader: *const ByteReader, p_val: *i16) c_int;
    pub const peekInt16Be = gst_byte_reader_peek_int16_be;

    /// Read a signed 16 bit little endian integer into `val`
    /// but keep the current position.
    extern fn gst_byte_reader_peek_int16_le(p_reader: *const ByteReader, p_val: *i16) c_int;
    pub const peekInt16Le = gst_byte_reader_peek_int16_le;

    /// Read a signed 24 bit big endian integer into `val`
    /// but keep the current position.
    extern fn gst_byte_reader_peek_int24_be(p_reader: *const ByteReader, p_val: *i32) c_int;
    pub const peekInt24Be = gst_byte_reader_peek_int24_be;

    /// Read a signed 24 bit little endian integer into `val`
    /// but keep the current position.
    extern fn gst_byte_reader_peek_int24_le(p_reader: *const ByteReader, p_val: *i32) c_int;
    pub const peekInt24Le = gst_byte_reader_peek_int24_le;

    /// Read a signed 32 bit big endian integer into `val`
    /// but keep the current position.
    extern fn gst_byte_reader_peek_int32_be(p_reader: *const ByteReader, p_val: *i32) c_int;
    pub const peekInt32Be = gst_byte_reader_peek_int32_be;

    /// Read a signed 32 bit little endian integer into `val`
    /// but keep the current position.
    extern fn gst_byte_reader_peek_int32_le(p_reader: *const ByteReader, p_val: *i32) c_int;
    pub const peekInt32Le = gst_byte_reader_peek_int32_le;

    /// Read a signed 64 bit big endian integer into `val`
    /// but keep the current position.
    extern fn gst_byte_reader_peek_int64_be(p_reader: *const ByteReader, p_val: *i64) c_int;
    pub const peekInt64Be = gst_byte_reader_peek_int64_be;

    /// Read a signed 64 bit little endian integer into `val`
    /// but keep the current position.
    extern fn gst_byte_reader_peek_int64_le(p_reader: *const ByteReader, p_val: *i64) c_int;
    pub const peekInt64Le = gst_byte_reader_peek_int64_le;

    /// Read a signed 8 bit integer into `val` but keep the current position.
    extern fn gst_byte_reader_peek_int8(p_reader: *const ByteReader, p_val: *i8) c_int;
    pub const peekInt8 = gst_byte_reader_peek_int8;

    /// Returns a constant pointer to the current data position if there is
    /// a NUL-terminated string in the data (this could be just a NUL terminator).
    /// The current position will be maintained. This will work for any
    /// NUL-terminated string with a character width of 8 bits, so ASCII,
    /// UTF-8, ISO-8859-N etc.
    ///
    /// No input checking for valid UTF-8 is done.
    ///
    /// This function will fail if no NUL-terminator was found in in the data.
    extern fn gst_byte_reader_peek_string_utf8(p_reader: *const ByteReader, p_str: *[*]const u8) c_int;
    pub const peekStringUtf8 = gst_byte_reader_peek_string_utf8;

    /// Initializes a `gstbase.ByteReader` sub-reader instance to contain `size` bytes of
    /// data from the current position of `reader`. This is useful to read chunked
    /// formats and make sure that one doesn't read beyond the size of the sub-chunk.
    ///
    /// Unlike `gstbase.ByteReader.getSubReader`, this function does not modify the
    /// current position of `reader`.
    extern fn gst_byte_reader_peek_sub_reader(p_reader: *ByteReader, p_sub_reader: *gstbase.ByteReader, p_size: c_uint) c_int;
    pub const peekSubReader = gst_byte_reader_peek_sub_reader;

    /// Read an unsigned 16 bit big endian integer into `val`
    /// but keep the current position.
    extern fn gst_byte_reader_peek_uint16_be(p_reader: *const ByteReader, p_val: *u16) c_int;
    pub const peekUint16Be = gst_byte_reader_peek_uint16_be;

    /// Read an unsigned 16 bit little endian integer into `val`
    /// but keep the current position.
    extern fn gst_byte_reader_peek_uint16_le(p_reader: *const ByteReader, p_val: *u16) c_int;
    pub const peekUint16Le = gst_byte_reader_peek_uint16_le;

    /// Read an unsigned 24 bit big endian integer into `val`
    /// but keep the current position.
    extern fn gst_byte_reader_peek_uint24_be(p_reader: *const ByteReader, p_val: *u32) c_int;
    pub const peekUint24Be = gst_byte_reader_peek_uint24_be;

    /// Read an unsigned 24 bit little endian integer into `val`
    /// but keep the current position.
    extern fn gst_byte_reader_peek_uint24_le(p_reader: *const ByteReader, p_val: *u32) c_int;
    pub const peekUint24Le = gst_byte_reader_peek_uint24_le;

    /// Read an unsigned 32 bit big endian integer into `val`
    /// but keep the current position.
    extern fn gst_byte_reader_peek_uint32_be(p_reader: *const ByteReader, p_val: *u32) c_int;
    pub const peekUint32Be = gst_byte_reader_peek_uint32_be;

    /// Read an unsigned 32 bit little endian integer into `val`
    /// but keep the current position.
    extern fn gst_byte_reader_peek_uint32_le(p_reader: *const ByteReader, p_val: *u32) c_int;
    pub const peekUint32Le = gst_byte_reader_peek_uint32_le;

    /// Read an unsigned 64 bit big endian integer into `val`
    /// but keep the current position.
    extern fn gst_byte_reader_peek_uint64_be(p_reader: *const ByteReader, p_val: *u64) c_int;
    pub const peekUint64Be = gst_byte_reader_peek_uint64_be;

    /// Read an unsigned 64 bit little endian integer into `val`
    /// but keep the current position.
    extern fn gst_byte_reader_peek_uint64_le(p_reader: *const ByteReader, p_val: *u64) c_int;
    pub const peekUint64Le = gst_byte_reader_peek_uint64_le;

    /// Read an unsigned 8 bit integer into `val` but keep the current position.
    extern fn gst_byte_reader_peek_uint8(p_reader: *const ByteReader, p_val: *u8) c_int;
    pub const peekUint8 = gst_byte_reader_peek_uint8;

    /// Sets the new position of a `gstbase.ByteReader` instance to `pos` in bytes.
    extern fn gst_byte_reader_set_pos(p_reader: *ByteReader, p_pos: c_uint) c_int;
    pub const setPos = gst_byte_reader_set_pos;

    /// Skips `nbytes` bytes of the `gstbase.ByteReader` instance.
    extern fn gst_byte_reader_skip(p_reader: *ByteReader, p_nbytes: c_uint) c_int;
    pub const skip = gst_byte_reader_skip;

    /// Skips a NUL-terminated UTF-16 string in the `gstbase.ByteReader` instance,
    /// advancing the current position to the byte after the string.
    ///
    /// No input checking for valid UTF-16 is done.
    ///
    /// This function will fail if no NUL-terminator was found in in the data.
    extern fn gst_byte_reader_skip_string_utf16(p_reader: *ByteReader) c_int;
    pub const skipStringUtf16 = gst_byte_reader_skip_string_utf16;

    /// Skips a NUL-terminated UTF-32 string in the `gstbase.ByteReader` instance,
    /// advancing the current position to the byte after the string.
    ///
    /// No input checking for valid UTF-32 is done.
    ///
    /// This function will fail if no NUL-terminator was found in in the data.
    extern fn gst_byte_reader_skip_string_utf32(p_reader: *ByteReader) c_int;
    pub const skipStringUtf32 = gst_byte_reader_skip_string_utf32;

    /// Skips a NUL-terminated string in the `gstbase.ByteReader` instance, advancing
    /// the current position to the byte after the string. This will work for
    /// any NUL-terminated string with a character width of 8 bits, so ASCII,
    /// UTF-8, ISO-8859-N etc. No input checking for valid UTF-8 is done.
    ///
    /// This function will fail if no NUL-terminator was found in in the data.
    extern fn gst_byte_reader_skip_string_utf8(p_reader: *ByteReader) c_int;
    pub const skipStringUtf8 = gst_byte_reader_skip_string_utf8;

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// `gstbase.ByteWriter` provides a byte writer and reader that can write/read different
/// integer and floating point types to/from a memory buffer. It provides functions
/// for writing/reading signed/unsigned, little/big endian integers of 8, 16, 24,
/// 32 and 64 bits and functions for reading little/big endian floating points numbers of
/// 32 and 64 bits. It also provides functions to write/read NUL-terminated strings
/// in various character encodings.
pub const ByteWriter = extern struct {
    /// `gstbase.ByteReader` parent
    f_parent: gstbase.ByteReader,
    /// Allocation size of the data
    f_alloc_size: c_uint,
    /// If `TRUE` no reallocations are allowed
    f_fixed: c_int,
    /// If `FALSE` no reallocations are allowed and copies of data are returned
    f_owned: c_int,
    f__gst_reserved: [4]*anyopaque,

    /// Creates a new, empty `gstbase.ByteWriter` instance
    ///
    /// Free-function: gst_byte_writer_free
    extern fn gst_byte_writer_new() *gstbase.ByteWriter;
    pub const new = gst_byte_writer_new;

    /// Creates a new `gstbase.ByteWriter` instance with the given
    /// memory area. If `initialized` is `TRUE` it is possible to
    /// read `size` bytes from the `gstbase.ByteWriter` from the beginning.
    ///
    /// Free-function: gst_byte_writer_free
    extern fn gst_byte_writer_new_with_data(p_data: *u8, p_size: c_uint, p_initialized: c_int) *gstbase.ByteWriter;
    pub const newWithData = gst_byte_writer_new_with_data;

    /// Creates a new `gstbase.ByteWriter` instance with the given
    /// initial data size.
    ///
    /// Free-function: gst_byte_writer_free
    extern fn gst_byte_writer_new_with_size(p_size: c_uint, p_fixed: c_int) *gstbase.ByteWriter;
    pub const newWithSize = gst_byte_writer_new_with_size;

    /// Checks if enough free space from the current write cursor is
    /// available and reallocates if necessary.
    extern fn gst_byte_writer_ensure_free_space(p_writer: *ByteWriter, p_size: c_uint) c_int;
    pub const ensureFreeSpace = gst_byte_writer_ensure_free_space;

    /// Writes `size` bytes containing `value` to `writer`.
    extern fn gst_byte_writer_fill(p_writer: *ByteWriter, p_value: u8, p_size: c_uint) c_int;
    pub const fill = gst_byte_writer_fill;

    /// Frees `writer` and all memory allocated by it.
    extern fn gst_byte_writer_free(p_writer: *ByteWriter) void;
    pub const free = gst_byte_writer_free;

    /// Frees `writer` and all memory allocated by it except
    /// the current data, which is returned as `gst.Buffer`.
    ///
    /// Free-function: gst_buffer_unref
    extern fn gst_byte_writer_free_and_get_buffer(p_writer: *ByteWriter) *gst.Buffer;
    pub const freeAndGetBuffer = gst_byte_writer_free_and_get_buffer;

    /// Frees `writer` and all memory allocated by it except
    /// the current data, which is returned.
    ///
    /// Free-function: g_free
    extern fn gst_byte_writer_free_and_get_data(p_writer: *ByteWriter) *u8;
    pub const freeAndGetData = gst_byte_writer_free_and_get_data;

    /// Returns the remaining size of data that can still be written. If
    /// -1 is returned the remaining size is only limited by system resources.
    extern fn gst_byte_writer_get_remaining(p_writer: *const ByteWriter) c_uint;
    pub const getRemaining = gst_byte_writer_get_remaining;

    /// Initializes `writer` to an empty instance
    extern fn gst_byte_writer_init(p_writer: *ByteWriter) void;
    pub const init = gst_byte_writer_init;

    /// Initializes `writer` with the given
    /// memory area. If `initialized` is `TRUE` it is possible to
    /// read `size` bytes from the `gstbase.ByteWriter` from the beginning.
    extern fn gst_byte_writer_init_with_data(p_writer: *ByteWriter, p_data: [*]u8, p_size: c_uint, p_initialized: c_int) void;
    pub const initWithData = gst_byte_writer_init_with_data;

    /// Initializes `writer` with the given initial data size.
    extern fn gst_byte_writer_init_with_size(p_writer: *ByteWriter, p_size: c_uint, p_fixed: c_int) void;
    pub const initWithSize = gst_byte_writer_init_with_size;

    /// Writes `size` bytes of `data` to `writer`.
    extern fn gst_byte_writer_put_data(p_writer: *ByteWriter, p_data: [*]const u8, p_size: c_uint) c_int;
    pub const putData = gst_byte_writer_put_data;

    /// Writes a big endian 32 bit float to `writer`.
    extern fn gst_byte_writer_put_float32_be(p_writer: *ByteWriter, p_val: f32) c_int;
    pub const putFloat32Be = gst_byte_writer_put_float32_be;

    /// Writes a little endian 32 bit float to `writer`.
    extern fn gst_byte_writer_put_float32_le(p_writer: *ByteWriter, p_val: f32) c_int;
    pub const putFloat32Le = gst_byte_writer_put_float32_le;

    /// Writes a big endian 64 bit float to `writer`.
    extern fn gst_byte_writer_put_float64_be(p_writer: *ByteWriter, p_val: f64) c_int;
    pub const putFloat64Be = gst_byte_writer_put_float64_be;

    /// Writes a little endian 64 bit float to `writer`.
    extern fn gst_byte_writer_put_float64_le(p_writer: *ByteWriter, p_val: f64) c_int;
    pub const putFloat64Le = gst_byte_writer_put_float64_le;

    /// Writes a signed big endian 16 bit integer to `writer`.
    extern fn gst_byte_writer_put_int16_be(p_writer: *ByteWriter, p_val: i16) c_int;
    pub const putInt16Be = gst_byte_writer_put_int16_be;

    /// Writes a signed little endian 16 bit integer to `writer`.
    extern fn gst_byte_writer_put_int16_le(p_writer: *ByteWriter, p_val: i16) c_int;
    pub const putInt16Le = gst_byte_writer_put_int16_le;

    /// Writes a signed big endian 24 bit integer to `writer`.
    extern fn gst_byte_writer_put_int24_be(p_writer: *ByteWriter, p_val: i32) c_int;
    pub const putInt24Be = gst_byte_writer_put_int24_be;

    /// Writes a signed little endian 24 bit integer to `writer`.
    extern fn gst_byte_writer_put_int24_le(p_writer: *ByteWriter, p_val: i32) c_int;
    pub const putInt24Le = gst_byte_writer_put_int24_le;

    /// Writes a signed big endian 32 bit integer to `writer`.
    extern fn gst_byte_writer_put_int32_be(p_writer: *ByteWriter, p_val: i32) c_int;
    pub const putInt32Be = gst_byte_writer_put_int32_be;

    /// Writes a signed little endian 32 bit integer to `writer`.
    extern fn gst_byte_writer_put_int32_le(p_writer: *ByteWriter, p_val: i32) c_int;
    pub const putInt32Le = gst_byte_writer_put_int32_le;

    /// Writes a signed big endian 64 bit integer to `writer`.
    extern fn gst_byte_writer_put_int64_be(p_writer: *ByteWriter, p_val: i64) c_int;
    pub const putInt64Be = gst_byte_writer_put_int64_be;

    /// Writes a signed little endian 64 bit integer to `writer`.
    extern fn gst_byte_writer_put_int64_le(p_writer: *ByteWriter, p_val: i64) c_int;
    pub const putInt64Le = gst_byte_writer_put_int64_le;

    /// Writes a signed 8 bit integer to `writer`.
    extern fn gst_byte_writer_put_int8(p_writer: *ByteWriter, p_val: i8) c_int;
    pub const putInt8 = gst_byte_writer_put_int8;

    /// Writes a NUL-terminated UTF16 string to `writer` (including the terminator).
    extern fn gst_byte_writer_put_string_utf16(p_writer: *ByteWriter, p_data: [*]const u16) c_int;
    pub const putStringUtf16 = gst_byte_writer_put_string_utf16;

    /// Writes a NUL-terminated UTF32 string to `writer` (including the terminator).
    extern fn gst_byte_writer_put_string_utf32(p_writer: *ByteWriter, p_data: [*]const u32) c_int;
    pub const putStringUtf32 = gst_byte_writer_put_string_utf32;

    /// Writes a NUL-terminated UTF8 string to `writer` (including the terminator).
    extern fn gst_byte_writer_put_string_utf8(p_writer: *ByteWriter, p_data: [*:0]const u8) c_int;
    pub const putStringUtf8 = gst_byte_writer_put_string_utf8;

    /// Writes a unsigned big endian 16 bit integer to `writer`.
    extern fn gst_byte_writer_put_uint16_be(p_writer: *ByteWriter, p_val: u16) c_int;
    pub const putUint16Be = gst_byte_writer_put_uint16_be;

    /// Writes a unsigned little endian 16 bit integer to `writer`.
    extern fn gst_byte_writer_put_uint16_le(p_writer: *ByteWriter, p_val: u16) c_int;
    pub const putUint16Le = gst_byte_writer_put_uint16_le;

    /// Writes a unsigned big endian 24 bit integer to `writer`.
    extern fn gst_byte_writer_put_uint24_be(p_writer: *ByteWriter, p_val: u32) c_int;
    pub const putUint24Be = gst_byte_writer_put_uint24_be;

    /// Writes a unsigned little endian 24 bit integer to `writer`.
    extern fn gst_byte_writer_put_uint24_le(p_writer: *ByteWriter, p_val: u32) c_int;
    pub const putUint24Le = gst_byte_writer_put_uint24_le;

    /// Writes a unsigned big endian 32 bit integer to `writer`.
    extern fn gst_byte_writer_put_uint32_be(p_writer: *ByteWriter, p_val: u32) c_int;
    pub const putUint32Be = gst_byte_writer_put_uint32_be;

    /// Writes a unsigned little endian 32 bit integer to `writer`.
    extern fn gst_byte_writer_put_uint32_le(p_writer: *ByteWriter, p_val: u32) c_int;
    pub const putUint32Le = gst_byte_writer_put_uint32_le;

    /// Writes a unsigned big endian 64 bit integer to `writer`.
    extern fn gst_byte_writer_put_uint64_be(p_writer: *ByteWriter, p_val: u64) c_int;
    pub const putUint64Be = gst_byte_writer_put_uint64_be;

    /// Writes a unsigned little endian 64 bit integer to `writer`.
    extern fn gst_byte_writer_put_uint64_le(p_writer: *ByteWriter, p_val: u64) c_int;
    pub const putUint64Le = gst_byte_writer_put_uint64_le;

    /// Writes a unsigned 8 bit integer to `writer`.
    extern fn gst_byte_writer_put_uint8(p_writer: *ByteWriter, p_val: u8) c_int;
    pub const putUint8 = gst_byte_writer_put_uint8;

    /// Resets `writer` and frees the data if it's
    /// owned by `writer`.
    extern fn gst_byte_writer_reset(p_writer: *ByteWriter) void;
    pub const reset = gst_byte_writer_reset;

    /// Resets `writer` and returns the current data as buffer.
    ///
    /// Free-function: gst_buffer_unref
    extern fn gst_byte_writer_reset_and_get_buffer(p_writer: *ByteWriter) *gst.Buffer;
    pub const resetAndGetBuffer = gst_byte_writer_reset_and_get_buffer;

    /// Resets `writer` and returns the current data.
    ///
    /// Free-function: g_free
    extern fn gst_byte_writer_reset_and_get_data(p_writer: *ByteWriter) [*]u8;
    pub const resetAndGetData = gst_byte_writer_reset_and_get_data;

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// Structure used by the collect_pads.
pub const CollectData = extern struct {
    /// owner `gstbase.CollectPads`
    f_collect: ?*gstbase.CollectPads,
    /// `gst.Pad` managed by this data
    f_pad: ?*gst.Pad,
    /// currently queued buffer.
    f_buffer: ?*gst.Buffer,
    /// position in the buffer
    f_pos: c_uint,
    /// last segment received.
    f_segment: gst.Segment,
    f_state: gstbase.CollectPadsStateFlags,
    f_priv: ?*gstbase.CollectDataPrivate,
    anon0: extern union {
        anon0: extern struct {
            f_dts: i64,
        },
        f__gst_reserved: [4]*anyopaque,
    },

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

pub const CollectDataPrivate = opaque {
    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

pub const CollectPadsClass = extern struct {
    pub const Instance = gstbase.CollectPads;

    f_parent_class: gst.ObjectClass,
    f__gst_reserved: [4]*anyopaque,

    pub fn as(p_instance: *CollectPadsClass, comptime P_T: type) *P_T {
        return gobject.ext.as(P_T, p_instance);
    }

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

pub const CollectPadsPrivate = opaque {
    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

pub const DataQueueClass = extern struct {
    pub const Instance = gstbase.DataQueue;

    f_parent_class: gobject.ObjectClass,
    f_empty: ?*const fn (p_queue: *gstbase.DataQueue) callconv(.c) void,
    f_full: ?*const fn (p_queue: *gstbase.DataQueue) callconv(.c) void,
    f__gst_reserved: [4]*anyopaque,

    pub fn as(p_instance: *DataQueueClass, comptime P_T: type) *P_T {
        return gobject.ext.as(P_T, p_instance);
    }

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// Structure used by `gstbase.DataQueue`. You can supply a different structure, as
/// long as the top of the structure is identical to this structure.
pub const DataQueueItem = extern struct {
    /// the `gst.MiniObject` to queue.
    f_object: ?*gst.MiniObject,
    /// the size in bytes of the miniobject.
    f_size: c_uint,
    /// the duration in `gst.ClockTime` of the miniobject. Can not be
    /// `GST_CLOCK_TIME_NONE`.
    f_duration: u64,
    /// `TRUE` if `object` should be considered as a visible object.
    f_visible: c_int,
    /// The `glib.DestroyNotify` function to use to free the `gstbase.DataQueueItem`.
    /// This function should also drop the reference to `object` the owner of the
    /// `gstbase.DataQueueItem` is assumed to hold.
    f_destroy: ?glib.DestroyNotify,
    f__gst_reserved: [4]*anyopaque,

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

pub const DataQueuePrivate = opaque {
    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// Structure describing the size of a queue.
pub const DataQueueSize = extern struct {
    /// number of buffers
    f_visible: c_uint,
    /// number of bytes
    f_bytes: c_uint,
    /// amount of time
    f_time: u64,

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// Utility struct to help handling `gst.FlowReturn` combination. Useful for
/// `gst.Element`<!-- -->s that have multiple source pads and need to combine
/// the different `gst.FlowReturn` for those pads.
///
/// `gstbase.FlowCombiner` works by using the last `gst.FlowReturn` for all `gst.Pad`
/// it has in its list and computes the combined return value and provides
/// it to the caller.
///
/// To add a new pad to the `gstbase.FlowCombiner` use `gstbase.FlowCombiner.addPad`.
/// The new `gst.Pad` is stored with a default value of `GST_FLOW_OK`.
///
/// In case you want a `gst.Pad` to be removed, use `gstbase.FlowCombiner.removePad`.
///
/// Please be aware that this struct isn't thread safe as its designed to be
///  used by demuxers, those usually will have a single thread operating it.
///
/// These functions will take refs on the passed `gst.Pad`<!-- -->s.
///
/// Aside from reducing the user's code size, the main advantage of using this
/// helper struct is to follow the standard rules for `gst.FlowReturn` combination.
/// These rules are:
///
/// * `GST_FLOW_EOS`: only if all returns are EOS too
/// * `GST_FLOW_NOT_LINKED`: only if all returns are NOT_LINKED too
/// * `GST_FLOW_ERROR` or below: if at least one returns an error return
/// * `GST_FLOW_NOT_NEGOTIATED`: if at least one returns a not-negotiated return
/// * `GST_FLOW_FLUSHING`: if at least one returns flushing
/// * `GST_FLOW_OK`: otherwise
///
/// `GST_FLOW_ERROR` or below, GST_FLOW_NOT_NEGOTIATED and GST_FLOW_FLUSHING are
/// returned immediately from the `gstbase.FlowCombiner.updateFlow` function.
pub const FlowCombiner = opaque {
    /// Creates a new `gstbase.FlowCombiner`, use `gstbase.FlowCombiner.free` to free it.
    extern fn gst_flow_combiner_new() *gstbase.FlowCombiner;
    pub const new = gst_flow_combiner_new;

    /// Adds a new `gst.Pad` to the `gstbase.FlowCombiner`.
    extern fn gst_flow_combiner_add_pad(p_combiner: *FlowCombiner, p_pad: *gst.Pad) void;
    pub const addPad = gst_flow_combiner_add_pad;

    /// Removes all pads from a `gstbase.FlowCombiner` and resets it to its initial state.
    extern fn gst_flow_combiner_clear(p_combiner: *FlowCombiner) void;
    pub const clear = gst_flow_combiner_clear;

    /// Frees a `gstbase.FlowCombiner` struct and all its internal data.
    extern fn gst_flow_combiner_free(p_combiner: *FlowCombiner) void;
    pub const free = gst_flow_combiner_free;

    /// Increments the reference count on the `gstbase.FlowCombiner`.
    extern fn gst_flow_combiner_ref(p_combiner: *FlowCombiner) *gstbase.FlowCombiner;
    pub const ref = gst_flow_combiner_ref;

    /// Removes a `gst.Pad` from the `gstbase.FlowCombiner`.
    extern fn gst_flow_combiner_remove_pad(p_combiner: *FlowCombiner, p_pad: *gst.Pad) void;
    pub const removePad = gst_flow_combiner_remove_pad;

    /// Reset flow combiner and all pads to their initial state without removing pads.
    extern fn gst_flow_combiner_reset(p_combiner: *FlowCombiner) void;
    pub const reset = gst_flow_combiner_reset;

    /// Decrements the reference count on the `gstbase.FlowCombiner`.
    extern fn gst_flow_combiner_unref(p_combiner: *FlowCombiner) void;
    pub const unref = gst_flow_combiner_unref;

    /// Computes the combined flow return for the pads in it.
    ///
    /// The `gst.FlowReturn` parameter should be the last flow return update for a pad
    /// in this `gstbase.FlowCombiner`. It will use this value to be able to shortcut some
    /// combinations and avoid looking over all pads again. e.g. The last combined
    /// return is the same as the latest obtained `gst.FlowReturn`.
    extern fn gst_flow_combiner_update_flow(p_combiner: *FlowCombiner, p_fret: gst.FlowReturn) gst.FlowReturn;
    pub const updateFlow = gst_flow_combiner_update_flow;

    /// Sets the provided pad's last flow return to provided value and computes
    /// the combined flow return for the pads in it.
    ///
    /// The `gst.FlowReturn` parameter should be the last flow return update for a pad
    /// in this `gstbase.FlowCombiner`. It will use this value to be able to shortcut some
    /// combinations and avoid looking over all pads again. e.g. The last combined
    /// return is the same as the latest obtained `gst.FlowReturn`.
    extern fn gst_flow_combiner_update_pad_flow(p_combiner: *FlowCombiner, p_pad: *gst.Pad, p_fret: gst.FlowReturn) gst.FlowReturn;
    pub const updatePadFlow = gst_flow_combiner_update_pad_flow;

    extern fn gst_flow_combiner_get_type() usize;
    pub const getGObjectType = gst_flow_combiner_get_type;

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// Subclasses can override any of the available virtual methods or not, as
/// needed. At the minimum, the `fill` method should be overridden to produce
/// buffers.
pub const PushSrcClass = extern struct {
    pub const Instance = gstbase.PushSrc;

    /// Element parent class
    f_parent_class: gstbase.BaseSrcClass,
    /// Ask the subclass to create a buffer. The subclass decides which
    ///          size this buffer should be. Other then that, refer to
    ///          `gstbase.BaseSrc`<!-- -->.`create` for more details. If this method is
    ///          not implemented, `alloc` followed by `fill` will be called.
    f_create: ?*const fn (p_src: *gstbase.PushSrc, p_buf: ?**gst.Buffer) callconv(.c) gst.FlowReturn,
    /// Ask the subclass to allocate a buffer. The subclass decides which
    ///         size this buffer should be. The default implementation will create
    ///         a new buffer from the negotiated allocator.
    f_alloc: ?*const fn (p_src: *gstbase.PushSrc, p_buf: ?**gst.Buffer) callconv(.c) gst.FlowReturn,
    /// Ask the subclass to fill the buffer with data.
    f_fill: ?*const fn (p_src: *gstbase.PushSrc, p_buf: *gst.Buffer) callconv(.c) gst.FlowReturn,
    f__gst_reserved: [4]*anyopaque,

    pub fn as(p_instance: *PushSrcClass, comptime P_T: type) *P_T {
        return gobject.ext.as(P_T, p_instance);
    }

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// `gstbase.QueueArray` is an object that provides standard queue functionality
/// based on an array instead of linked lists. This reduces the overhead
/// caused by memory management by a large factor.
pub const QueueArray = opaque {
    /// Allocates a new `gstbase.QueueArray` object with an initial
    /// queue size of `initial_size`.
    extern fn gst_queue_array_new(p_initial_size: c_uint) *gstbase.QueueArray;
    pub const new = gst_queue_array_new;

    /// Allocates a new `gstbase.QueueArray` object for elements (e.g. structures)
    /// of size `struct_size`, with an initial queue size of `initial_size`.
    extern fn gst_queue_array_new_for_struct(p_struct_size: usize, p_initial_size: c_uint) *gstbase.QueueArray;
    pub const newForStruct = gst_queue_array_new_for_struct;

    /// Clears queue `array` and frees all memory associated to it.
    extern fn gst_queue_array_clear(p_array: *QueueArray) void;
    pub const clear = gst_queue_array_clear;

    /// Drops the queue element at position `idx` from queue `array`.
    extern fn gst_queue_array_drop_element(p_array: *QueueArray, p_idx: c_uint) ?*anyopaque;
    pub const dropElement = gst_queue_array_drop_element;

    /// Drops the queue element at position `idx` from queue `array` and copies the
    /// data of the element or structure that was removed into `p_struct` if
    /// `p_struct` is set (not NULL).
    extern fn gst_queue_array_drop_struct(p_array: *QueueArray, p_idx: c_uint, p_p_struct: ?*anyopaque) c_int;
    pub const dropStruct = gst_queue_array_drop_struct;

    /// Finds an element in the queue `array`, either by comparing every element
    /// with `func` or by looking up `data` if no compare function `func` is provided,
    /// and returning the index of the found element.
    extern fn gst_queue_array_find(p_array: *QueueArray, p_func: ?glib.CompareFunc, p_data: ?*anyopaque) c_uint;
    pub const find = gst_queue_array_find;

    /// Frees queue `array` and all memory associated to it.
    extern fn gst_queue_array_free(p_array: *QueueArray) void;
    pub const free = gst_queue_array_free;

    /// Returns the length of the queue `array`
    extern fn gst_queue_array_get_length(p_array: *QueueArray) c_uint;
    pub const getLength = gst_queue_array_get_length;

    /// Checks if the queue `array` is empty.
    extern fn gst_queue_array_is_empty(p_array: *QueueArray) c_int;
    pub const isEmpty = gst_queue_array_is_empty;

    /// Returns the head of the queue `array` and does not
    /// remove it from the queue.
    extern fn gst_queue_array_peek_head(p_array: *QueueArray) ?*anyopaque;
    pub const peekHead = gst_queue_array_peek_head;

    /// Returns the head of the queue `array` without removing it from the queue.
    extern fn gst_queue_array_peek_head_struct(p_array: *QueueArray) ?*anyopaque;
    pub const peekHeadStruct = gst_queue_array_peek_head_struct;

    /// Returns the item at `idx` in `array`, but does not remove it from the queue.
    extern fn gst_queue_array_peek_nth(p_array: *QueueArray, p_idx: c_uint) ?*anyopaque;
    pub const peekNth = gst_queue_array_peek_nth;

    /// Returns the item at `idx` in `array`, but does not remove it from the queue.
    extern fn gst_queue_array_peek_nth_struct(p_array: *QueueArray, p_idx: c_uint) ?*anyopaque;
    pub const peekNthStruct = gst_queue_array_peek_nth_struct;

    /// Returns the tail of the queue `array`, but does not remove it from the queue.
    extern fn gst_queue_array_peek_tail(p_array: *QueueArray) ?*anyopaque;
    pub const peekTail = gst_queue_array_peek_tail;

    /// Returns the tail of the queue `array`, but does not remove it from the queue.
    extern fn gst_queue_array_peek_tail_struct(p_array: *QueueArray) ?*anyopaque;
    pub const peekTailStruct = gst_queue_array_peek_tail_struct;

    /// Returns and head of the queue `array` and removes
    /// it from the queue.
    extern fn gst_queue_array_pop_head(p_array: *QueueArray) ?*anyopaque;
    pub const popHead = gst_queue_array_pop_head;

    /// Returns the head of the queue `array` and removes it from the queue.
    extern fn gst_queue_array_pop_head_struct(p_array: *QueueArray) ?*anyopaque;
    pub const popHeadStruct = gst_queue_array_pop_head_struct;

    /// Returns the tail of the queue `array` and removes
    /// it from the queue.
    extern fn gst_queue_array_pop_tail(p_array: *QueueArray) ?*anyopaque;
    pub const popTail = gst_queue_array_pop_tail;

    /// Returns the tail of the queue `array` and removes
    /// it from the queue.
    extern fn gst_queue_array_pop_tail_struct(p_array: *QueueArray) ?*anyopaque;
    pub const popTailStruct = gst_queue_array_pop_tail_struct;

    /// Pushes `data` to the queue `array`, finding the correct position
    /// by comparing `data` with each array element using `func`.
    ///
    /// This has a time complexity of O(n), so depending on the size of the queue
    /// and expected access patterns, a different data structure might be better.
    ///
    /// Assumes that the array is already sorted. If it is not, make sure
    /// to call `gstbase.QueueArray.sort` first.
    extern fn gst_queue_array_push_sorted(p_array: *QueueArray, p_data: ?*anyopaque, p_func: glib.CompareDataFunc, p_user_data: ?*anyopaque) void;
    pub const pushSorted = gst_queue_array_push_sorted;

    /// Pushes the element at address `p_struct` into the queue `array`
    /// (copying the contents of a structure of the struct_size specified
    /// when creating the queue into the array), finding the correct position
    /// by comparing the element at `p_struct` with each element in the array using `func`.
    ///
    /// This has a time complexity of O(n), so depending on the size of the queue
    /// and expected access patterns, a different data structure might be better.
    ///
    /// Assumes that the array is already sorted. If it is not, make sure
    /// to call `gstbase.QueueArray.sort` first.
    extern fn gst_queue_array_push_sorted_struct(p_array: *QueueArray, p_p_struct: ?*anyopaque, p_func: glib.CompareDataFunc, p_user_data: ?*anyopaque) void;
    pub const pushSortedStruct = gst_queue_array_push_sorted_struct;

    /// Pushes `data` to the tail of the queue `array`.
    extern fn gst_queue_array_push_tail(p_array: *QueueArray, p_data: ?*anyopaque) void;
    pub const pushTail = gst_queue_array_push_tail;

    extern fn gst_queue_array_push_tail_struct(p_array: *QueueArray, p_p_struct: ?*anyopaque) void;
    pub const pushTailStruct = gst_queue_array_push_tail_struct;

    /// Sets a function to clear an element of `array`.
    ///
    /// The `clear_func` will be called when an element in the array
    /// data segment is removed and when the array is freed and data
    /// segment is deallocated as well. `clear_func` will be passed a
    /// pointer to the element to clear, rather than the element itself.
    ///
    /// Note that in contrast with other uses of `glib.DestroyNotify`
    /// functions, `clear_func` is expected to clear the contents of
    /// the array element it is given, but not free the element itself.
    extern fn gst_queue_array_set_clear_func(p_array: *QueueArray, p_clear_func: glib.DestroyNotify) void;
    pub const setClearFunc = gst_queue_array_set_clear_func;

    /// Sorts the queue `array` by comparing elements against each other using
    /// the provided `compare_func`.
    extern fn gst_queue_array_sort(p_array: *QueueArray, p_compare_func: glib.CompareDataFunc, p_user_data: ?*anyopaque) void;
    pub const sort = gst_queue_array_sort;

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// The opaque `gstbase.TypeFindData` structure.
pub const TypeFindData = opaque {
    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

pub const AggregatorStartTimeSelection = enum(c_int) {
    zero = 0,
    first = 1,
    set = 2,
    _,

    extern fn gst_aggregator_start_time_selection_get_type() usize;
    pub const getGObjectType = gst_aggregator_start_time_selection_get_type;

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// Flags to be used in a `gstbase.BaseParseFrame`.
pub const BaseParseFrameFlags = packed struct(c_uint) {
    new_frame: bool = false,
    no_frame: bool = false,
    clip: bool = false,
    drop: bool = false,
    queue: bool = false,
    _padding5: bool = false,
    _padding6: bool = false,
    _padding7: bool = false,
    _padding8: bool = false,
    _padding9: bool = false,
    _padding10: bool = false,
    _padding11: bool = false,
    _padding12: bool = false,
    _padding13: bool = false,
    _padding14: bool = false,
    _padding15: bool = false,
    _padding16: bool = false,
    _padding17: bool = false,
    _padding18: bool = false,
    _padding19: bool = false,
    _padding20: bool = false,
    _padding21: bool = false,
    _padding22: bool = false,
    _padding23: bool = false,
    _padding24: bool = false,
    _padding25: bool = false,
    _padding26: bool = false,
    _padding27: bool = false,
    _padding28: bool = false,
    _padding29: bool = false,
    _padding30: bool = false,
    _padding31: bool = false,

    pub const flags_none: BaseParseFrameFlags = @bitCast(@as(c_uint, 0));
    pub const flags_new_frame: BaseParseFrameFlags = @bitCast(@as(c_uint, 1));
    pub const flags_no_frame: BaseParseFrameFlags = @bitCast(@as(c_uint, 2));
    pub const flags_clip: BaseParseFrameFlags = @bitCast(@as(c_uint, 4));
    pub const flags_drop: BaseParseFrameFlags = @bitCast(@as(c_uint, 8));
    pub const flags_queue: BaseParseFrameFlags = @bitCast(@as(c_uint, 16));

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// The `gst.Element` flags that a basesrc element may have.
pub const BaseSrcFlags = packed struct(c_uint) {
    _padding0: bool = false,
    _padding1: bool = false,
    _padding2: bool = false,
    _padding3: bool = false,
    _padding4: bool = false,
    _padding5: bool = false,
    _padding6: bool = false,
    _padding7: bool = false,
    _padding8: bool = false,
    _padding9: bool = false,
    _padding10: bool = false,
    _padding11: bool = false,
    _padding12: bool = false,
    _padding13: bool = false,
    starting: bool = false,
    started: bool = false,
    _padding16: bool = false,
    _padding17: bool = false,
    _padding18: bool = false,
    _padding19: bool = false,
    last: bool = false,
    _padding21: bool = false,
    _padding22: bool = false,
    _padding23: bool = false,
    _padding24: bool = false,
    _padding25: bool = false,
    _padding26: bool = false,
    _padding27: bool = false,
    _padding28: bool = false,
    _padding29: bool = false,
    _padding30: bool = false,
    _padding31: bool = false,

    pub const flags_starting: BaseSrcFlags = @bitCast(@as(c_uint, 16384));
    pub const flags_started: BaseSrcFlags = @bitCast(@as(c_uint, 32768));
    pub const flags_last: BaseSrcFlags = @bitCast(@as(c_uint, 1048576));

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

pub const CollectPadsStateFlags = packed struct(c_uint) {
    eos: bool = false,
    flushing: bool = false,
    new_segment: bool = false,
    waiting: bool = false,
    locked: bool = false,
    _padding5: bool = false,
    _padding6: bool = false,
    _padding7: bool = false,
    _padding8: bool = false,
    _padding9: bool = false,
    _padding10: bool = false,
    _padding11: bool = false,
    _padding12: bool = false,
    _padding13: bool = false,
    _padding14: bool = false,
    _padding15: bool = false,
    _padding16: bool = false,
    _padding17: bool = false,
    _padding18: bool = false,
    _padding19: bool = false,
    _padding20: bool = false,
    _padding21: bool = false,
    _padding22: bool = false,
    _padding23: bool = false,
    _padding24: bool = false,
    _padding25: bool = false,
    _padding26: bool = false,
    _padding27: bool = false,
    _padding28: bool = false,
    _padding29: bool = false,
    _padding30: bool = false,
    _padding31: bool = false,

    pub const flags_eos: CollectPadsStateFlags = @bitCast(@as(c_uint, 1));
    pub const flags_flushing: CollectPadsStateFlags = @bitCast(@as(c_uint, 2));
    pub const flags_new_segment: CollectPadsStateFlags = @bitCast(@as(c_uint, 4));
    pub const flags_waiting: CollectPadsStateFlags = @bitCast(@as(c_uint, 8));
    pub const flags_locked: CollectPadsStateFlags = @bitCast(@as(c_uint, 16));

    test {
        @setEvalBranchQuota(100_000);
        std.testing.refAllDecls(@This());
    }
};

/// Tries to find what type of data is flowing from the given source `gst.Pad`.
///
/// Free-function: gst_caps_unref
extern fn gst_type_find_helper(p_src: *gst.Pad, p_size: u64) ?*gst.Caps;
pub const typeFindHelper = gst_type_find_helper;

/// Tries to find what type of data is contained in the given `gst.Buffer`, the
/// assumption being that the buffer represents the beginning of the stream or
/// file.
///
/// All available typefinders will be called on the data in order of rank. If
/// a typefinding function returns a probability of `GST_TYPE_FIND_MAXIMUM`,
/// typefinding is stopped immediately and the found caps will be returned
/// right away. Otherwise, all available typefind functions will the tried,
/// and the caps with the highest probability will be returned, or `NULL` if
/// the content of the buffer could not be identified.
///
/// Free-function: gst_caps_unref
extern fn gst_type_find_helper_for_buffer(p_obj: ?*gst.Object, p_buf: *gst.Buffer, p_prob: ?*gst.TypeFindProbability) ?*gst.Caps;
pub const typeFindHelperForBuffer = gst_type_find_helper_for_buffer;

/// Tries to find if type of media contained in the given `gst.Buffer`, matches
/// `caps` specified, assumption being that the buffer represents the beginning
/// of the stream or file.
///
/// Tries to find what type of data is contained in the given `data`, the
/// assumption being that the data represents the beginning of the stream or
/// file.
///
/// Only the typefinder matching the given caps will be called, if found. The
/// caps with the highest probability will be returned, or `NULL` if the content
/// of the `data` could not be identified.
///
/// Free-function: gst_caps_unref
extern fn gst_type_find_helper_for_buffer_with_caps(p_obj: ?*gst.Object, p_buf: *gst.Buffer, p_caps: *gst.Caps, p_prob: ?*gst.TypeFindProbability) ?*gst.Caps;
pub const typeFindHelperForBufferWithCaps = gst_type_find_helper_for_buffer_with_caps;

/// Tries to find what type of data is contained in the given `gst.Buffer`, the
/// assumption being that the buffer represents the beginning of the stream or
/// file.
///
/// All available typefinders will be called on the data in order of rank. If
/// a typefinding function returns a probability of `GST_TYPE_FIND_MAXIMUM`,
/// typefinding is stopped immediately and the found caps will be returned
/// right away. Otherwise, all available typefind functions will the tried,
/// and the caps with the highest probability will be returned, or `NULL` if
/// the content of the buffer could not be identified.
///
/// When `extension` is not `NULL`, this function will first try the typefind
/// functions for the given extension, which might speed up the typefinding
/// in many cases.
///
/// Free-function: gst_caps_unref
extern fn gst_type_find_helper_for_buffer_with_extension(p_obj: ?*gst.Object, p_buf: *gst.Buffer, p_extension: ?[*:0]const u8, p_prob: ?*gst.TypeFindProbability) ?*gst.Caps;
pub const typeFindHelperForBufferWithExtension = gst_type_find_helper_for_buffer_with_extension;

/// Tries to find what type of data is contained in the given `data`, the
/// assumption being that the data represents the beginning of the stream or
/// file.
///
/// All available typefinders will be called on the data in order of rank. If
/// a typefinding function returns a probability of `GST_TYPE_FIND_MAXIMUM`,
/// typefinding is stopped immediately and the found caps will be returned
/// right away. Otherwise, all available typefind functions will the tried,
/// and the caps with the highest probability will be returned, or `NULL` if
/// the content of `data` could not be identified.
///
/// Free-function: gst_caps_unref
extern fn gst_type_find_helper_for_data(p_obj: ?*gst.Object, p_data: [*]const u8, p_size: usize, p_prob: ?*gst.TypeFindProbability) ?*gst.Caps;
pub const typeFindHelperForData = gst_type_find_helper_for_data;

/// Tries to find if type of media contained in the given `data`, matches the
/// `caps` specified, assumption being that the data represents the beginning
/// of the stream or file.
///
/// Only the typefinder matching the given caps will be called, if found. The
/// caps with the highest probability will be returned, or `NULL` if the content
/// of the `data` could not be identified.
///
/// Free-function: gst_caps_unref
extern fn gst_type_find_helper_for_data_with_caps(p_obj: ?*gst.Object, p_data: [*]const u8, p_size: usize, p_caps: *gst.Caps, p_prob: ?*gst.TypeFindProbability) ?*gst.Caps;
pub const typeFindHelperForDataWithCaps = gst_type_find_helper_for_data_with_caps;

/// Tries to find what type of data is contained in the given `data`, the
/// assumption being that the data represents the beginning of the stream or
/// file.
///
/// All available typefinders will be called on the data in order of rank. If
/// a typefinding function returns a probability of `GST_TYPE_FIND_MAXIMUM`,
/// typefinding is stopped immediately and the found caps will be returned
/// right away. Otherwise, all available typefind functions will the tried,
/// and the caps with the highest probability will be returned, or `NULL` if
/// the content of `data` could not be identified.
///
/// When `extension` is not `NULL`, this function will first try the typefind
/// functions for the given extension, which might speed up the typefinding
/// in many cases.
///
/// Free-function: gst_caps_unref
extern fn gst_type_find_helper_for_data_with_extension(p_obj: ?*gst.Object, p_data: [*]const u8, p_size: usize, p_extension: ?[*:0]const u8, p_prob: ?*gst.TypeFindProbability) ?*gst.Caps;
pub const typeFindHelperForDataWithExtension = gst_type_find_helper_for_data_with_extension;

/// Tries to find the best `gst.Caps` associated with `extension`.
///
/// All available typefinders will be checked against the extension in order
/// of rank. The caps of the first typefinder that can handle `extension` will be
/// returned.
///
/// Free-function: gst_caps_unref
extern fn gst_type_find_helper_for_extension(p_obj: ?*gst.Object, p_extension: [*:0]const u8) ?*gst.Caps;
pub const typeFindHelperForExtension = gst_type_find_helper_for_extension;

/// Utility function to do pull-based typefinding. Unlike `gstbase.typeFindHelper`
/// however, this function will use the specified function `func` to obtain the
/// data needed by the typefind functions, rather than operating on a given
/// source pad. This is useful mostly for elements like tag demuxers which
/// strip off data at the beginning and/or end of a file and want to typefind
/// the stripped data stream before adding their own source pad (the specified
/// callback can then call the upstream peer pad with offsets adjusted for the
/// tag size, for example).
///
/// When `extension` is not `NULL`, this function will first try the typefind
/// functions for the given extension, which might speed up the typefinding
/// in many cases.
///
/// Free-function: gst_caps_unref
extern fn gst_type_find_helper_get_range(p_obj: *gst.Object, p_parent: ?*gst.Object, p_func: gstbase.TypeFindHelperGetRangeFunction, p_size: u64, p_extension: ?[*:0]const u8, p_prob: ?*gst.TypeFindProbability) ?*gst.Caps;
pub const typeFindHelperGetRange = gst_type_find_helper_get_range;

/// Utility function to do pull-based typefinding. Unlike `gstbase.typeFindHelper`
/// however, this function will use the specified function `func` to obtain the
/// data needed by the typefind functions, rather than operating on a given
/// source pad. This is useful mostly for elements like tag demuxers which
/// strip off data at the beginning and/or end of a file and want to typefind
/// the stripped data stream before adding their own source pad (the specified
/// callback can then call the upstream peer pad with offsets adjusted for the
/// tag size, for example).
///
/// When `extension` is not `NULL`, this function will first try the typefind
/// functions for the given extension, which might speed up the typefinding
/// in many cases.
extern fn gst_type_find_helper_get_range_full(p_obj: *gst.Object, p_parent: ?*gst.Object, p_func: gstbase.TypeFindHelperGetRangeFunction, p_size: u64, p_extension: ?[*:0]const u8, p_caps: **gst.Caps, p_prob: ?*gst.TypeFindProbability) gst.FlowReturn;
pub const typeFindHelperGetRangeFull = gst_type_find_helper_get_range_full;

/// Tries to find the best `gst.TypeFindFactory` associated with `caps`.
///
/// The typefinder that can handle `caps` will be returned.
///
/// Free-function: g_list_free
extern fn gst_type_find_list_factories_for_caps(p_obj: ?*gst.Object, p_caps: *gst.Caps) ?*glib.List;
pub const typeFindListFactoriesForCaps = gst_type_find_list_factories_for_caps;

/// A function that will be called when the `gstbase.CollectData` will be freed.
/// It is passed the pointer to the structure and should free any custom
/// memory and resources allocated for it.
pub const CollectDataDestroyNotify = *const fn (p_data: *gstbase.CollectData) callconv(.c) void;

/// A function that will be called when a (considered oldest) buffer can be muxed.
/// If all pads have reached EOS, this function is called with `NULL` `buffer`
/// and `NULL` `data`.
pub const CollectPadsBufferFunction = *const fn (p_pads: *gstbase.CollectPads, p_data: *gstbase.CollectData, p_buffer: *gst.Buffer, p_user_data: ?*anyopaque) callconv(.c) gst.FlowReturn;

/// A function that will be called when `inbuffer` is received on the pad managed
/// by `data` in the collectpad object `pads`.
///
/// The function should use the segment of `data` and the negotiated media type on
/// the pad to perform clipping of `inbuffer`.
///
/// This function takes ownership of `inbuffer` and should output a buffer in
/// `outbuffer` or return `NULL` in `outbuffer` if the buffer should be dropped.
pub const CollectPadsClipFunction = *const fn (p_pads: *gstbase.CollectPads, p_data: *gstbase.CollectData, p_inbuffer: *gst.Buffer, p_outbuffer: **gst.Buffer, p_user_data: ?*anyopaque) callconv(.c) gst.FlowReturn;

/// A function for comparing two timestamps of buffers or newsegments collected on one pad.
pub const CollectPadsCompareFunction = *const fn (p_pads: *gstbase.CollectPads, p_data1: *gstbase.CollectData, p_timestamp1: gst.ClockTime, p_data2: *gstbase.CollectData, p_timestamp2: gst.ClockTime, p_user_data: ?*anyopaque) callconv(.c) c_int;

/// A function that will be called while processing an event. It takes
/// ownership of the event and is responsible for chaining up (to
/// `gstbase.CollectPads.eventDefault`) or dropping events (such typical cases
/// being handled by the default handler).
pub const CollectPadsEventFunction = *const fn (p_pads: *gstbase.CollectPads, p_pad: *gstbase.CollectData, p_event: *gst.Event, p_user_data: ?*anyopaque) callconv(.c) c_int;

/// A function that will be called while processing a flushing seek event.
///
/// The function should flush any internal state of the element and the state of
/// all the pads. It should clear only the state not directly managed by the
/// `pads` object. It is therefore not necessary to call
/// gst_collect_pads_set_flushing nor gst_collect_pads_clear from this function.
pub const CollectPadsFlushFunction = *const fn (p_pads: *gstbase.CollectPads, p_user_data: ?*anyopaque) callconv(.c) void;

/// A function that will be called when all pads have received data.
pub const CollectPadsFunction = *const fn (p_pads: *gstbase.CollectPads, p_user_data: ?*anyopaque) callconv(.c) gst.FlowReturn;

/// A function that will be called while processing a query. It takes
/// ownership of the query and is responsible for chaining up (to
/// events downstream (with `gst.Pad.eventDefault`).
pub const CollectPadsQueryFunction = *const fn (p_pads: *gstbase.CollectPads, p_pad: *gstbase.CollectData, p_query: *gst.Query, p_user_data: ?*anyopaque) callconv(.c) c_int;

/// The prototype of the function used to inform the queue that it should be
/// considered as full.
pub const DataQueueCheckFullFunction = *const fn (p_queue: *gstbase.DataQueue, p_visible: c_uint, p_bytes: c_uint, p_time: u64, p_checkdata: ?*anyopaque) callconv(.c) c_int;

pub const DataQueueEmptyCallback = *const fn (p_queue: *gstbase.DataQueue, p_checkdata: ?*anyopaque) callconv(.c) void;

pub const DataQueueFullCallback = *const fn (p_queue: *gstbase.DataQueue, p_checkdata: ?*anyopaque) callconv(.c) void;

/// This function will be called by `gstbase.typeFindHelperGetRange` when
/// typefinding functions request to peek at the data of a stream at certain
/// offsets. If this function returns GST_FLOW_OK, the result buffer will be
/// stored in `buffer`. The  contents of `buffer` is invalid for any other
/// return value.
///
/// This function is supposed to behave exactly like a `gst.PadGetRangeFunction`.
pub const TypeFindHelperGetRangeFunction = *const fn (p_obj: *gst.Object, p_parent: ?*gst.Object, p_offset: u64, p_length: c_uint, p_buffer: **gst.Buffer) callconv(.c) gst.FlowReturn;

pub const BASE_PARSE_FLAG_DRAINING = 2;
pub const BASE_PARSE_FLAG_LOST_SYNC = 1;
/// The name of the templates for the sink pad.
pub const BASE_TRANSFORM_SINK_NAME = "sink";
/// The name of the templates for the source pad.
pub const BASE_TRANSFORM_SRC_NAME = "src";

test {
    @setEvalBranchQuota(100_000);
    std.testing.refAllDecls(@This());
    std.testing.refAllDecls(ext);
}
