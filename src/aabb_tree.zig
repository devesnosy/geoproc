// Copyright 2024- Eyad Ahmed
//
// This file is part of GeoProcZig.
// GeoProcZig is free software:
// you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation,
// either version 3 of the License, or (at your option) any later version.
//
// GeoProcZig is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with GeoProcZig.
// If not, see <https://www.gnu.org/licenses/>.

const std = @import("std");
const lib_aabb = @import("aabb.zig");
const lib_vec = @import("vec.zig");

const GPA = std.heap.GeneralPurposeAllocator(.{});
const vec_def: lib_vec.Vec_Def = .{ .T = f32, .N = 3 };
const Vec3f = lib_vec.Vec(vec_def);
const AABB3f = lib_aabb.AABB(vec_def);

const AABB_Tree_Node = struct {
    const Self = @This();
    aabb: AABB3f,
    first: usize,
    last: usize,
    left: ?*Self,
    right: ?*Self,
    pub fn is_leaf(self: Self) bool {
        return self.left == null and self.right == null;
    }
    pub fn num_prims(self: Self) usize {
        return self.last - self.first + 1;
    }
};

pub fn main() !void {
    var gpa = GPA.init;
    defer {
        const gpa_deinit_res = gpa.deinit();
        std.debug.assert(gpa_deinit_res == .ok);
    }
    const ator = gpa.allocator();

    var prng = std.Random.DefaultPrng.init(0);
    const rand = prng.random();

    const num_points = 1000;

    var points = std.ArrayList(Vec3f).init(ator);
    defer points.deinit();
    try points.ensureUnusedCapacity(num_points);

    for (0..num_points) |_| {
        try points.append(.{
            .components = .{
                rand.float(f32),
                rand.float(f32),
                rand.float(f32),
            },
        });
    }

    var root = try ator.create(AABB_Tree_Node);
    root.aabb = undefined;
    root.first = 0;
    root.last = points.items.len - 1;
    root.left = null;
    root.right = null;

    var stack = std.ArrayList(*AABB_Tree_Node).init(ator);
    defer stack.deinit();

    // Build tree

    try stack.append(root);
    outer: while (stack.items.len > 0) {
        var node = stack.pop();
        node.aabb = blk: {
            var upper = points.items[0];
            var lower = upper;
            for (points.items[1..]) |p| {
                upper = upper.max(p);
                lower = lower.min(p);
            }
            break :blk .{ .upper = upper, .lower = lower };
        };
        if (node.num_prims() < 2) continue;
        const extent = node.aabb.calc_extent();
        const split_axis = blk: {
            var i: usize = 0;
            for (extent.components, 0..) |c, ci| {
                if (Vec3f.__num_gt__(c, extent.at(i))) i = ci;
            }
            break :blk i;
        };
        const split_value = node.aabb.calc_center().at(split_axis);
        var first = node.first;
        var last = node.last;
        while (first < last) {
            if (points.items[first].at(split_axis) < split_value) {
                first += 1;
            } else {
                std.mem.swap(Vec3f, &points.items[first], &points.items[last]);
                last -= 1;
            }
        }
        std.debug.assert(first == last);
        var partition_point = first;
        if (points.items[partition_point].at(split_axis) < split_value) {
            if (partition_point == node.last) continue :outer;
        } else {
            if (partition_point == node.first) continue :outer;
            partition_point -= 1;
        }

        var left = try ator.create(AABB_Tree_Node);
        left.aabb = undefined;
        left.first = node.first;
        left.last = partition_point;
        left.left = null;
        left.right = null;

        var right = try ator.create(AABB_Tree_Node);
        right.aabb = undefined;
        right.first = partition_point + 1;
        right.last = node.last;
        right.left = null;
        right.right = null;

        try stack.appendSlice(&.{ left, right });
        node.left = left;
        node.right = right;
    }

    // Free tree

    try stack.append(root);
    while (stack.items.len > 0) {
        var node = stack.pop();
        if (!node.is_leaf()) try stack.appendSlice(&.{ node.left.?, node.right.? });
        ator.destroy(node);
    }
}
