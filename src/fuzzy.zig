//! Ordered-subsequence scoring. Inputs are Unicode case-folded code points.
const std = @import("std");

pub fn score(query: []const u32, target: []const u32, scratch: []i32) ?i32 {
    if (query.len == 0) return 0;
    if (query.len > target.len) return null;
    std.debug.assert(scratch.len >= target.len * 2);
    const missing = std.math.minInt(i32) / 2;
    var previous = scratch[0..target.len];
    var current = scratch[target.len .. target.len * 2];
    @memset(previous, missing);
    for (query, 0..) |q, qi| {
        var best_gap: i32 = missing;
        for (target, 0..) |t, j| {
            if (j > 0) best_gap = @max(best_gap - 1, previous[j - 1] - 1);
            current[j] = missing;
            if (q != t) continue;
            const boundary: i32 = if (j == 0 or separator(target[j - 1])) 12 else 0;
            if (qi == 0) {
                current[j] = 16 + boundary - @as(i32, @intCast(@min(j, 64)));
            } else if (j > 0) {
                const prior = @max(best_gap, previous[j - 1] + 12);
                if (prior > missing / 2) current[j] = prior + 16 + boundary;
            }
        }
        std.mem.swap([]i32, &previous, &current);
    }
    var best: i32 = missing;
    for (previous, 0..) |s, j| best = @max(best, s - @as(i32, @intCast(@min(target.len - j - 1, 32))));
    if (best <= missing / 2) return null;
    return best + @as(i32, if (query.len == target.len) 32 else 0);
}

fn separator(c: u32) bool {
    return c == ' ' or c == '-' or c == '_' or c == '.' or c == '/' or c == '(';
}

test "ordered gaps match; reordered or missing characters do not" {
    var scratch: [64]i32 = undefined;
    try std.testing.expect(score(&.{ 's', 'f', 'i' }, &.{ 's', 'a', 'f', 'a', 'r', 'i' }, &scratch) != null);
    try std.testing.expect(score(&.{ 'f', 's' }, &.{ 's', 'a', 'f', 'a', 'r', 'i' }, &scratch) == null);
    try std.testing.expect(score(&.{'z'}, &.{ 's', 'a', 'f' }, &scratch) == null);
}

test "exact, consecutive and word-start matches rank higher" {
    var scratch: [64]i32 = undefined;
    const q = &[_]u32{ 'f', 'o' };
    const exact = score(q, &.{ 'f', 'o' }, &scratch).?;
    const prefix = score(q, &.{ 'f', 'o', 'o' }, &scratch).?;
    const gaps = score(q, &.{ 'f', 'x', 'o' }, &scratch).?;
    const middle = score(q, &.{ 'x', 'f', 'o' }, &scratch).?;
    try std.testing.expect(exact > prefix and prefix > gaps and prefix > middle);
}

test "Unicode, repeated letters, empty query and long targets" {
    var scratch: [4096]i32 = undefined;
    try std.testing.expect(score(&.{ 0x65e5, 0x8a9e }, &.{ 0x65e5, 0x672c, 0x8a9e }, &scratch) != null);
    try std.testing.expect(score(&.{ 'a', 'a' }, &.{'a'}, &scratch) == null);
    try std.testing.expectEqual(@as(?i32, 0), score(&.{}, &.{}, &scratch));
    var target: [2048]u32 = @splat('x');
    target[2047] = 'z';
    try std.testing.expect(score(&.{'z'}, &target, &scratch) != null);
}
