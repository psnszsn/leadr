zig-gobject := env("ZIG_GOBJECT", home_directory() / "clonez/zig-gobject")

# Generate zig-gobject bindings and copy to bindings/
bindings:
    cd {{zig-gobject}} && zig build codegen -Dmodules=Gtk4LayerShell-1.0 -Dmodules=Gtk-4.0 -Dmodules=Adw-1
    rm -rf bindings
    cp -r {{zig-gobject}}/zig-out/bindings bindings
