const std = @import("std");
const glib = @import("glib");
const gobject = @import("gobject");
const gtk = @import("gtk");

const ext = @import("ext.zig");
pub const Application = @import("class/application.zig").Application;
pub const OverlayWindow = @import("class/overlay_window.zig").OverlayWindow;
pub const KeyIndicator = @import("class/key_indicator.zig").KeyIndicator;
pub const Cheatsheet = @import("class/cheatsheet.zig").Cheatsheet;
pub const EmojiPicker = @import("class/emoji_picker.zig").EmojiPicker;

/// Common methods for all GObject classes we create.
pub fn Common(
    comptime Self: type,
    comptime Private: ?type,
) type {
    return struct {
        pub fn as(self: *Self, comptime T: type) *T {
            return gobject.ext.as(T, self);
        }

        pub fn ref(self: *Self) *Self {
            return @ptrCast(@alignCast(gobject.Object.ref(self.as(gobject.Object))));
        }

        pub fn refSink(self: *Self) *Self {
            return @ptrCast(@alignCast(gobject.Object.refSink(self.as(gobject.Object))));
        }

        pub fn unref(self: *Self) void {
            gobject.Object.unref(self.as(gobject.Object));
        }

        pub const private = if (Private) |P| (struct {
            fn private(self: *Self) *P {
                return gobject.ext.impl_helpers.getPrivate(
                    self,
                    P,
                    P.offset,
                );
            }
        }).private else {};

        pub fn getClass(self: *Self) ?*Self.Class {
            const type_instance: *gobject.TypeInstance = @ptrCast(self);
            return @ptrCast(type_instance.f_g_class orelse return null);
        }

        pub fn privateShallowFieldAccessor(
            comptime name: []const u8,
        ) gobject.ext.Accessor(
            Self,
            @FieldType(Private.?, name),
        ) {
            return gobject.ext.privateFieldAccessor(
                Self,
                Private.?,
                &Private.?.offset,
                name,
            );
        }

        pub fn privateBoxedFieldAccessor(
            comptime name: []const u8,
        ) gobject.ext.Accessor(
            Self,
            @FieldType(Private.?, name),
        ) {
            return .{
                .getter = &struct {
                    fn get(self: *Self, value: *gobject.Value) void {
                        gobject.ext.Value.set(
                            value,
                            @field(private(self), name),
                        );
                    }
                }.get,
                .setter = &struct {
                    fn set(self: *Self, value: *const gobject.Value) void {
                        const priv = private(self);
                        if (@field(priv, name)) |v| {
                            ext.boxedFree(
                                @typeInfo(@TypeOf(v)).pointer.child,
                                v,
                            );
                        }

                        const T = @TypeOf(@field(priv, name));
                        @field(
                            priv,
                            name,
                        ) = gobject.ext.Value.dup(value, T);
                    }
                }.set,
            };
        }

        pub fn privateObjFieldAccessor(
            comptime name: []const u8,
        ) gobject.ext.Accessor(
            Self,
            @FieldType(Private.?, name),
        ) {
            return .{
                .getter = &struct {
                    fn get(self: *Self, value: *gobject.Value) void {
                        gobject.ext.Value.set(
                            value,
                            @field(private(self), name),
                        );
                    }
                }.get,
                .setter = &struct {
                    fn set(self: *Self, value: *const gobject.Value) void {
                        const priv = private(self);
                        if (@field(priv, name)) |v| v.unref();

                        const T = @TypeOf(@field(priv, name));
                        @field(
                            priv,
                            name,
                        ) = gobject.ext.Value.dup(value, T);
                    }
                }.set,
            };
        }

        pub fn privateStringFieldAccessor(
            comptime name: []const u8,
        ) gobject.ext.Accessor(
            Self,
            @FieldType(Private.?, name),
        ) {
            const S = struct {
                fn getter(self: *Self) ?[:0]const u8 {
                    return @field(private(self), name);
                }

                fn setter(self: *Self, value: ?[:0]const u8) void {
                    const priv = private(self);
                    if (@field(priv, name)) |v| {
                        glib.free(@ptrCast(@constCast(v)));
                    }
                    @field(priv, name) = value;
                }
            };

            return gobject.ext.typedAccessor(
                Self,
                ?[:0]const u8,
                .{
                    .getter = S.getter,
                    .getter_transfer = .none,
                    .setter = S.setter,
                    .setter_transfer = .full,
                },
            );
        }

        pub const Class = struct {
            pub fn as(class: *Self.Class, comptime T: type) *T {
                return gobject.ext.as(T, class);
            }

            pub const bindTemplateChildPrivate = if (Private) |P| (struct {
                pub fn bindTemplateChildPrivate(
                    class: *Self.Class,
                    comptime name: [:0]const u8,
                    comptime options: gtk.ext.BindTemplateChildOptions,
                ) void {
                    gtk.ext.impl_helpers.bindTemplateChildPrivate(
                        class,
                        name,
                        P,
                        P.offset,
                        options,
                    );
                }
            }).bindTemplateChildPrivate else {};

            pub fn bindTemplateCallback(
                class: *Self.Class,
                comptime name: [:0]const u8,
                comptime func: anytype,
            ) void {
                {
                    const ptr_ti = @typeInfo(@TypeOf(func));
                    if (ptr_ti != .pointer) {
                        @compileError("bound function must be a pointer type");
                    }
                    if (ptr_ti.pointer.size != .one) {
                        @compileError("bound function must be a pointer to a function");
                    }

                    const func_ti = @typeInfo(ptr_ti.pointer.child);
                    if (func_ti != .@"fn") {
                        @compileError("bound function must be a function pointer");
                    }
                    if (func_ti.@"fn".return_type == bool) {
                        @compileError("bound function must return c_int instead of bool");
                    }
                }

                gtk.Widget.Class.bindTemplateCallbackFull(
                    class.as(gtk.Widget.Class),
                    name,
                    @ptrCast(func),
                );
            }
        };
    };
}
