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
const lib_vec = @import("vec.zig");
const lib_triangle = @import("triangle.zig");
const lib_stl_read = @import("stl_read.zig");

const GPA = std.heap.GeneralPurposeAllocator(.{});
const T_Type = lib_stl_read.T_Type;

/// Return first element in array that is larger than val
fn upper_bound(comptime T: type, arr: []const T, val: T) usize {
    if (arr.len == 0) return 0;
    var first: usize = 0;
    var last = arr.len - 1;
    while (first < last) {
        const mid = first + (last - first) / 2;
        if (arr[mid] > val) {
            last = mid;
        } else {
            first = mid + 1;
        }
    }
    std.debug.assert(first == last);
    return if (arr[first] > val) first else arr.len;
}

pub fn main() !void {
    var gpa = GPA.init;
    defer {
        const gpa_deinit_res = gpa.deinit();
        std.debug.assert(gpa_deinit_res == .ok);
    }

    const ator = gpa.allocator();
    const args = try std.process.argsAlloc(ator);
    defer std.process.argsFree(ator, args);

    var stderr_bw = std.io.bufferedWriter(std.io.getStdErr().writer());
    defer stderr_bw.flush() catch @panic("Failed to flush stderr");
    const stderr_bw_w = stderr_bw.writer();

    var stdout_bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    defer stdout_bw.flush() catch @panic("Failed to flush stdout");
    const stdout_bw_w = stdout_bw.writer();
    _ = stdout_bw_w;

    if (args.len != 4) {
        try stderr_bw_w.print("Expected arguments: /path/to/input_mesh.stl number_of_points /path/to/output.ply\n", .{});
        return;
    }

    const input_mesh_filepath = args[1];
    const num_points = std.fmt.parseInt(u32, args[2], 10) catch {
        try stderr_bw_w.print("Failed to parse number of points: {s}\n", .{args[2]});
        return;
    };
    const output_ply_filepath = args[3];

    const tris = try lib_stl_read.stl_read(ator, input_mesh_filepath);
    defer tris.deinit();
    std.debug.print("Num tris {}\n", .{tris.items.len});

    var tris_areas = try ator.alloc(f32, tris.items.len);
    defer ator.free(tris_areas);
    for (tris.items, 0..) |t, i| tris_areas[i] = t.calc_area();
    // Compute CDF
    for (1..tris.items.len) |i|
        tris_areas[i] = lib_stl_read.T_Type.V_Type.__num_add__(tris_areas[i], tris_areas[i - 1]);
    // Normalize CDF
    for (0..tris.items.len) |i|
        tris_areas[i] = lib_stl_read.T_Type.V_Type.__num_div__(tris_areas[i], tris_areas[tris.items.len - 1]);

    // Create ply
    const output_ply_file = std.fs.cwd().createFile(output_ply_filepath, .{}) catch {
        try stderr_bw_w.print("Failed to create file: {s}\n", .{output_ply_filepath});
        return;
    };
    defer output_ply_file.close();

    const output_ply_w = output_ply_file.writer();
    var output_ply_bw = std.io.bufferedWriter(output_ply_w);
    defer output_ply_bw.flush() catch @panic("Failed to flush output_ply_bw");
    const output_ply_bw_w = output_ply_bw.writer();

    try output_ply_bw_w.print("ply\n", .{});
    try output_ply_bw_w.print("format binary_little_endian 1.0\n", .{});
    try output_ply_bw_w.print("element vertex {d}\n", .{num_points});
    try output_ply_bw_w.print("property float x\n", .{});
    try output_ply_bw_w.print("property float y\n", .{});
    try output_ply_bw_w.print("property float z\n", .{});
    try output_ply_bw_w.print("end_header\n", .{});

    var prng = std.Random.DefaultPrng.init(0);
    const rand = prng.random();
    for (0..num_points) |_| {
        const cdf_y = rand.float(f32);
        const ti = upper_bound(f32, tris_areas, cdf_y);
        std.debug.assert(ti < tris.items.len);
        const t = tris.items[ti];

        const iu: [2]f32 = .{ rand.float(f32), rand.float(f32) };
        const su0 = std.math.sqrt(iu[0]);
        const u = T_Type.V_Type.__num_sub__(T_Type.V_Type.__num_from_int__(1), su0);
        const v = T_Type.V_Type.__num_mul__(iu[1], su0);
        const p = t.at_standard_uv(u, v);

        try output_ply_bw_w.writeInt(u32, @bitCast(p.x()), .little);
        try output_ply_bw_w.writeInt(u32, @bitCast(p.y()), .little);
        try output_ply_bw_w.writeInt(u32, @bitCast(p.z()), .little);
    }
}

test "upper_bound" {
    const N: usize = 1682001; // Arbitrary
    var nums: [N]usize = undefined;
    for (0..N) |i| nums[i] = i;
    for (0..N) |i| {
        const ub = upper_bound(usize, &nums, i);
        try std.testing.expect(ub == (i + 1));
    }
}
