/// Comptime key binding DSL and runtime navigation state.
pub const Binding = struct {
    key: u21, // Unicode codepoint
    label: []const u8,
    action: Action,
};

pub const Action = union(enum) {
    command: []const u8,
    group: []const Binding,
    sticky: struct { bindings: []const Binding, timeout_ms: c_uint },
    emoji,
    quit,
};

const max_depth = 8;

pub const Navigator = struct {
    stack: [max_depth][]const Binding = undefined,
    depth: u8 = 0,

    pub fn init(root: []const Binding) Navigator {
        var self: Navigator = .{ .depth = 1 };
        self.stack[0] = root;
        return self;
    }

    pub fn current(self: *const Navigator) []const Binding {
        return self.stack[self.depth - 1];
    }

    pub fn push(self: *Navigator, group: []const Binding) void {
        if (self.depth < max_depth) {
            self.stack[self.depth] = group;
            self.depth += 1;
        }
    }

    pub fn pop(self: *Navigator) bool {
        if (self.depth > 1) {
            self.depth -= 1;
            return true;
        }
        return false;
    }

    pub fn reset(self: *Navigator, root: []const Binding) void {
        self.stack[0] = root;
        self.depth = 1;
    }

    pub fn lookup(self: *const Navigator, key: u21) ?*const Binding {
        for (self.current()) |*binding| {
            if (binding.key == key) return binding;
        }
        return null;
    }

    pub fn atRoot(self: *const Navigator) bool {
        return self.depth <= 1;
    }
};
