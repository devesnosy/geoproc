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

const AABB_Tree = struct {
    const Self = @This();
    root: ?*AABB_Tree_Node,
    ator: std.mem.Allocator,

    pub fn init(ator: std.mem.Allocator) Self {
        return .{ .root = null, .ator = ator };
    }

    pub fn from_points(self: *Self, points: []Vec3f) !void {
        var stack = std.ArrayList(*AABB_Tree_Node).init(self.ator);
        defer stack.deinit();

        var root = try self.ator.create(AABB_Tree_Node);
        root.aabb = undefined;
        root.first = 0;
        root.last = points.len - 1;
        root.left = null;
        root.right = null;

        var ator = &self.ator;

        self.root = root;

        try stack.append(root);
        outer: while (stack.items.len > 0) {
            var node = stack.pop();
            node.aabb = blk: {
                var upper = points[0];
                var lower = upper;
                for (points[1..]) |p| {
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
                if (points[first].at(split_axis) < split_value) {
                    first += 1;
                } else {
                    std.mem.swap(Vec3f, &points[first], &points[last]);
                    last -= 1;
                }
            }
            std.debug.assert(first == last);
            var partition_point = first;
            if (points[partition_point].at(split_axis) < split_value) {
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
    }

    pub fn deinit(self: *Self) !void {
        if (self.root == null) return;
        var stack = std.ArrayList(*AABB_Tree_Node).init(self.ator);
        defer stack.deinit();
        try stack.append(self.root.?);
        while (stack.items.len > 0) {
            var node = stack.pop();
            if (!node.is_leaf()) try stack.appendSlice(&.{ node.left.?, node.right.? });
            self.ator.destroy(node);
        }
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

    var points = try ator.alloc(Vec3f, num_points);
    defer ator.free(points);

    for (0..num_points) |i| {
        points[i] =
            .{
            .components = .{
                rand.float(f32),
                rand.float(f32),
                rand.float(f32),
            },
        };
    }

    var tree = AABB_Tree.init(ator);
    defer tree.deinit() catch {
        std.debug.print("Failed to free tree\n", .{});
    };
    try tree.from_points(points);
}
