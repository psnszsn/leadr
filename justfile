zig-gobject := env("ZIG_GOBJECT", home_directory() / "clonez/zig-gobject")

# Generate zig-gobject bindings and copy to bindings/
bindings:
    cd {{zig-gobject}} && zig build codegen -Dmodules=Gtk4LayerShell-1.0 -Dmodules=Gtk-4.0 -Dmodules=Adw-1 -Dmodules=Gst-1.0 -Dmodules=GstApp-1.0 -Dmodules=GstBase-1.0
    rm -rf bindings
    cp -r {{zig-gobject}}/zig-out/bindings bindings
