# GObject Architecture Rules for Zig GTK Projects

Rules derived from the [Ghostty GTK rewrite](https://mitchellh.com/writing/ghostty-gtk-rewrite),
PRs [#7961](https://github.com/ghostty-org/ghostty/pull/7961) and
[#8235](https://github.com/ghostty-org/ghostty/pull/8235), and the
Ghostty source code.

---

## 1. Every UI concept is a GObject

Every major concept (window, surface, tab, dialog, overlay, config wrapper)
**must** be a GObject or Widget subclass. Never pair a plain Zig struct
alongside a GTK widget to manage "your" state — that creates two independent
lifetimes and an entire class of use-after-free / double-free bugs.

If you need to expose application-domain data to GTK (e.g. a config struct),
wrap it in a reference-counted GObject (`gobject.Object` subclass) so its
lifetime is managed by the same system as the widgets that consume it.

---

## 2. Canonical class layout

Every custom class follows this exact skeleton:

```zig
pub const MyWidget = extern struct {
    const Self = @This();

    // --- MANDATORY first field: parent instance ---
    parent_instance: Parent,

    // --- Type aliases ---
    pub const Parent = gtk.Box; // or adw.ApplicationWindow, gobject.Object, etc.
    pub const getGObjectType = gobject.ext.defineClass(Self, .{
        .name = "MyWidget",            // GType name, globally unique
        .instanceInit = &init,         // per-instance init (optional for non-widget pure GObjects)
        .classInit = &Class.init,      // per-class init (required)
        .parent_class = &Class.parent, // back-pointer set by GObject
        .private = .{ .Type = Private, .offset = &Private.offset },
    });

    // --- Properties (§4), Signals (§5) nested here ---
    pub const properties = struct { ... };
    pub const signals = struct { ... };

    // --- Private data struct ---
    const Private = struct {
        // all mutable instance state lives here
        pub var offset: c_int = 0; // required by GObject type system
    };

    // --- Public API ---
    pub fn new(...) *Self { ... }

    // --- Instance init (callconv(.c)) ---
    fn init(self: *Self, _: *Class) callconv(.c) void { ... }

    // --- Lifecycle: dispose & finalize (§6) ---
    fn dispose(self: *Self) callconv(.c) void { ... }
    fn finalize(self: *Self) callconv(.c) void { ... }

    // --- Common mixin (§3) ---
    const C = Common(Self, Private);
    pub const as = C.as;
    pub const ref = C.ref;
    pub const unref = C.unref;
    const private = C.private;

    // --- Class struct ---
    pub const Class = extern struct {
        parent_class: Parent.Class,
        var parent: *Parent.Class = undefined;
        pub const Instance = Self;

        fn init(class: *Class) callconv(.c) void { ... }

        pub const as = C.Class.as;
        pub const bindTemplateChildPrivate = C.Class.bindTemplateChildPrivate;
        pub const bindTemplateCallback = C.Class.bindTemplateCallback;
    };
};
```

**Rules:**
- The struct **must** be `extern struct` for C ABI compatibility.
- `parent_instance` **must** be the first field.
- The `Class` struct **must** also be `extern struct` with `parent_class` as
  first field.
- The GType name (`.name`) **must** be globally unique across the process.

---

## 3. Common mixin

Create a `Common(Self, Private)` helper (see Ghostty's `class.zig`) that
provides:

| Method | Purpose |
|---|---|
| `as(self, T)` | Safe upcast to any parent type or interface (compile-time checked) |
| `ref(self)` | Increment reference count, return typed pointer |
| `unref(self)` | Decrement reference count |
| `refSink(self)` | Sink floating reference or increment ref count |
| `private(self)` | Access the `Private` struct via GObject private-data offset |
| `getClass(self)` | Retrieve the class struct from an instance |

Also provide `Class.as`, `Class.bindTemplateChildPrivate`, and
`Class.bindTemplateCallback` through the mixin.

Re-export only what each class needs:
```zig
const C = Common(Self, Private);
pub const as = C.as;
pub const ref = C.ref;
pub const unref = C.unref;
const private = C.private;   // note: NOT pub
```

---

## 4. Properties

Define properties in a nested `pub const properties` struct. Each property is
its own sub-struct containing `name` and `impl`.

Choose the correct accessor based on the data type:

| Data type | Accessor | Memory semantics |
|---|---|---|
| Primitives (`bool`, `c_int`, enums) | `privateShallowFieldAccessor` | Shallow copy |
| Reference-counted GObjects (`?*Config`) | `privateObjFieldAccessor` | Read: takes ref. Write: unrefs old, refs new |
| Boxed types (heap structs) | `privateBoxedFieldAccessor` | Read: allocates copy. Write: frees old, copies new |
| Strings (`?[:0]const u8`) | `privateStringFieldAccessor` | Read: copies via glib. Write: frees old via `glib.free`, stores copy |
| Computed / read-only | `gobject.ext.typedAccessor` with custom getter | No field access; getter computes the value |

Register all properties in `Class.init`:
```zig
gobject.ext.registerProperties(class, &.{
    properties.config.impl,
    properties.title.impl,
});
```

Manually notify observers after programmatic changes:
```zig
self.as(gobject.Object).notifyByPspec(properties.title.impl.param_spec);
```

For batch updates, freeze/thaw notifications:
```zig
self.as(gobject.Object).freezeNotify();
defer self.as(gobject.Object).thawNotify();
```

---

## 5. Signals

Define signals in a nested `pub const signals` struct:

```zig
pub const signals = struct {
    pub const @"close-request" = struct {
        pub const name = "close-request";
        pub const connect = impl.connect;
        const impl = gobject.ext.defineSignal(
            name,
            Self,
            &.{},        // parameter types
            void,         // return type
        );
    };
};
```

**Rules:**
- Register every signal in `Class.init`:
  ```zig
  signals.@"close-request".impl.register(.{});
  ```
- Emit with:
  ```zig
  signals.@"close-request".impl.emit(self, null, .{}, null);
  ```
- Connect with typed user data:
  ```zig
  _ = MyWidget.signals.@"close-request".connect(widget, *Handler, callback, handler, .{});
  ```
- Use `.detail` for property-change filtering:
  ```zig
  .{ .detail = "error" }
  ```

---

## 6. Lifecycle: dispose and finalize

Implement **both** `dispose` and `finalize` as overrides of
`gobject.Object.virtual_methods` in `Class.init`:

```zig
gobject.Object.virtual_methods.dispose.implement(class, &dispose);
gobject.Object.virtual_methods.finalize.implement(class, &finalize);
```

### dispose — break reference cycles

Called potentially multiple times. Must be idempotent.

```zig
fn dispose(self: *Self) callconv(.c) void {
    const priv = self.private();

    // 1. Unref all owned GObject references, set to null
    if (priv.config) |v| { v.unref(); priv.config = null; }

    // 2. Clear weak references
    priv.some_weak_ref.set(null);

    // 3. Remove event sources / timers
    if (priv.timer) |t| { _ = glib.Source.remove(t); priv.timer = null; }

    // 4. For widget classes: dispose the template
    gtk.Widget.disposeTemplate(self.as(gtk.Widget), getGObjectType());

    // 5. ALWAYS chain to parent
    gobject.Object.virtual_methods.dispose.call(Class.parent, self.as(Parent));
}
```

### finalize — free non-GObject memory

Called exactly once, right before the memory is freed.

```zig
fn finalize(self: *Self) callconv(.c) void {
    const priv = self.private();

    // Free glib-allocated strings
    if (priv.title) |v| { glib.free(@ptrCast(@constCast(v))); }

    // Free boxed types
    if (priv.size) |v| { ext.boxedFree(Size, v); }

    // Free Zig allocator memory
    if (priv.core_thing) |v| { v.deinit(); alloc.destroy(v); }

    // Deinit Zig containers
    priv.list.deinit(alloc);

    // ALWAYS chain to parent
    gobject.Object.virtual_methods.finalize.call(Class.parent, self.as(Parent));
}
```

**Critical rules:**
- **dispose**: unref GObjects, clear weak refs, remove sources. Null out
  everything you unref (idempotency). Dispose the template if it's a widget.
- **finalize**: free all non-GObject allocations (strings, boxed, Zig heap).
- **Always chain** to the parent at the end of both.
- **Clear weak refs in dispose**, not finalize. Failing to do so causes
  undefined memory access when the target disposes later.

---

## 7. Instance initialization

```zig
fn init(self: *Self, _: *Class) callconv(.c) void {
    // For widget classes: init template FIRST
    gtk.Widget.initTemplate(self.as(gtk.Widget));

    // Then set up actions, initial state, etc.
    self.initActionMap();
}
```

- `initTemplate` **must** be the first call for widget classes — template
  children are not available until after this.
- Do **not** set properties that trigger notifications here — the object
  is not fully constructed yet. Set private fields directly and call
  `notifyByPspec` from the `new()` function instead.

---

## 8. Class initialization

`Class.init` runs once per type and **must**:

1. `gobject.ext.ensureType(DependentType)` for any custom types used in the
   template.
2. `setTemplateFromResource` if the class uses a Blueprint/UI file.
3. `bindTemplateChildPrivate` for each template child bound to private data.
4. `bindTemplateCallback` for each template callback.
5. `gobject.ext.registerProperties` with all properties.
6. Register all signals via `signals.X.impl.register(.{})`.
7. Implement virtual methods (`dispose`, `finalize`, and any parent virtuals).

Order matters: types must be ensured before the template references them.

---

## 9. Calling conventions

All functions called by the GObject/GTK runtime **must** use `callconv(.c)`:
- `init`, `dispose`, `finalize`
- `Class.init`
- Signal handlers / callbacks
- Template callbacks
- Action callbacks

**Never return `bool`** from template callbacks — return `c_int` instead.
Zig `bool` is one byte; GLib `gboolean` is `c_int`. ABI mismatch causes
subtle corruption.

---

## 10. Casting

- **Safe upcast** (compile-time checked): `self.as(gtk.Widget)` via the
  `Common` mixin.
- **Unsafe downcast** (runtime): `gobject.ext.cast(MyWidget, obj)` — returns
  optional, must be checked.
- **Ancestor lookup**: `ext.getAncestor(Window, self.as(gtk.Widget))` to walk
  the widget tree.

Never use `@ptrCast` for GObject hierarchy traversal — use the typed helpers.

---

## 11. Weak references

Use a typed `WeakRef(T)` wrapper around `gobject.WeakRef`:

```zig
const WeakRef = @import("weak_ref.zig").WeakRef;

// In Private:
dialog: WeakRef(SomeDialog) = .empty,

// Set (does NOT take a strong reference):
priv.dialog.set(the_dialog);

// Get (takes a strong reference, caller must unref or let it drop):
if (priv.dialog.get()) |d| { ... }

// MUST clear in dispose:
priv.dialog.set(null);
```

---

## 12. Actions

Use typed `Action(Self)` structs registered via `ext.actions`:

```zig
fn initActionMap(self: *Self) void {
    const s_param = glib.ext.VariantType.newFor([:0]const u8);
    defer s_param.free();

    const actions = [_]ext.actions.Action(Self){
        .init("do-thing", actionDoThing, null),
        .init("do-other", actionDoOther, s_param),
    };

    // For widgets implementing ActionMap (Application, Window):
    ext.actions.add(Self, self, &actions);

    // For plain widgets (Tab, Surface):
    _ = ext.actions.addAsGroup(Self, self, "group-name", &actions);
}
```

Action callbacks always have the signature:
```zig
fn actionDoThing(
    _: *gio.SimpleAction,
    _: ?*glib.Variant,
    self: *Self,
) callconv(.c) void { ... }
```

Action names use kebab-case and must match `[a-zA-Z0-9.-]+` (no underscores).

---

## 13. Blueprint UI files

- Use [Blueprint](https://jwestman.pages.gitlab.gnome.org/blueprint-compiler/)
  `.blp` files for declarative UI, compiled to `.ui` XML at build time.
- Organize under `ui/{major}.{minor}/{name}.blp` keyed by minimum Adwaita
  version.
- Reference custom types with `$GhosttyMyWidget` syntax.
- Bind properties with `bind` expressions; connect signals with `=> $callback()`.
- Register the compiled resource in `Class.init` via
  `setTemplateFromResource(gresource.blueprint(...))`.

---

## 14. Memory management principles

1. **Unified lifetime model.** All UI objects are GObjects with reference
   counting. No separate Zig-side lifetime tracking for widgets.
2. **Ref what you store, unref what you release.** When storing a GObject
   pointer in private data, call `.ref()`. When clearing it, call `.unref()`
   then set to `null`.
3. **Strings go through glib.** Strings stored in private data that are
   accessed through properties must be allocated with `glib.ext.dupeZ` and
   freed with `glib.free(@ptrCast(@constCast(v)))`.
4. **Boxed types use `boxedCopy`/`boxedFree`.** For non-GObject heap structs
   exposed as properties.
5. **errdefer on construction.** Always `errdefer self.unref()` after
   `newInstance` in `new()` functions.
6. **Don't hold Config references.** Config objects are large. Copy what you
   need into a `DerivedConfig` struct instead of holding a ref to the full
   config GObject.

---

## 15. Valgrind compliance

Run every feature through Valgrind. Zig's safety guarantees stop at C API
boundaries. Complex C libraries (GTK, GLib) transfer or blur object lifetime
at their C interface — Valgrind is the only reliable way to catch:
- Use-after-free across C boundaries
- Leaks from forgotten unrefs
- Undefined access from improperly cleared weak refs

---

## 16. Virtual method overrides

Override parent virtual methods in `Class.init`:

```zig
gio.Application.virtual_methods.activate.implement(class, &activate);
gio.Application.virtual_methods.startup.implement(class, &startup);
```

Call the parent implementation when chaining:

```zig
gio.Application.virtual_methods.activate.call(Class.parent, self.as(Parent));
```

Define custom virtual methods using the `Common.defineVirtualMethod` helper
when your class needs to be subclassed.

---

## 17. File organization

```
src/
├── class.zig              # Common() mixin and re-exports of all classes
├── ext.zig                # Zig-friendly GTK/GLib helpers
├── weak_ref.zig           # Type-safe WeakRef(T)
├── class/
│   ├── application.zig    # Top-level GApplication subclass
│   ├── window.zig         # Window subclass
│   ├── surface.zig        # Main content widget
│   ├── tab.zig            # Tab container
│   ├── config.zig         # Config GObject wrapper
│   └── ...                # One file per GObject class
├── ext/
│   ├── actions.zig        # Typed action helpers
│   └── ...                # Other extension modules
├── build/
│   ├── blueprint.zig      # Blueprint compilation
│   └── gresource.zig      # Resource compilation
└── ui/
    └── {major}.{minor}/
        └── {name}.blp     # Blueprint UI definitions
```

One GObject class per file. The file name matches the class name in
snake_case. All classes are re-exported from `class.zig`.

---

## Summary checklist for every new GObject class

- [ ] `extern struct` with `parent_instance` as first field
- [ ] `Parent` type alias
- [ ] `getGObjectType` via `gobject.ext.defineClass`
- [ ] `Private` struct with `pub var offset: c_int = 0`
- [ ] `Common(Self, Private)` mixin applied
- [ ] `Class` as `extern struct` with `parent_class` first, `var parent`, `pub const Instance = Self`
- [ ] Properties registered in `Class.init`
- [ ] Signals registered in `Class.init`
- [ ] `dispose` implemented: unrefs GObjects, clears weak refs, disposes template, chains to parent
- [ ] `finalize` implemented: frees strings/boxed/Zig heap memory, chains to parent
- [ ] All callbacks use `callconv(.c)`
- [ ] No `bool` returns from C-facing functions (use `c_int`)
- [ ] Template initialized first in `init` for widget classes
- [ ] Dependent types ensured before template in `Class.init`
