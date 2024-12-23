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

const GPA = std.heap.GeneralPurposeAllocator;

pub const Vec_Def = struct { T: type, N: usize };

pub fn Vec(vec_def: Vec_Def) type {
    return struct {
        const T = vec_def.T;
        const N = vec_def.N;
        const Self = @This();
        const T_Info = @typeInfo(T);
        const is_builtin_num_type = switch (T_Info) {
            .int, .float, .comptime_int, .comptime_float => true,
            else => false,
        };
        pub const __num_add__ = if (is_builtin_num_type) __builtin_num_add__ else T.__add__;
        pub const __num_sub__ = if (is_builtin_num_type) __builtin_num_sub__ else T.__sub__;
        pub const __num_mul__ = if (is_builtin_num_type) __builtin_num_mul__ else T.__mul__;
        pub const __num_div__ = if (is_builtin_num_type) __builtin_num_div__ else T.__div__;
        pub const __num_from_int__ = switch (T_Info) {
            .int, .comptime_int => __builtin_int_from_int__,
            .float, .comptime_float => __builtin_float_from_int__,
            else => T.__from_int__,
        };
        components: [N]T,
        fn __builtin_num_add__(a: T, b: T) T {
            return a + b;
        }
        fn __builtin_num_sub__(a: T, b: T) T {
            return a - b;
        }
        fn __builtin_num_mul__(a: T, b: T) T {
            return a * b;
        }
        fn __builtin_num_div__(a: T, b: T) T {
            return a / b;
        }
        fn __builtin_float_from_int__(val: i32) T {
            return @floatFromInt(val);
        }
        fn __builtin_int_from_int__(val: i32) T {
            return val;
        }
        pub fn binary_op(self: Self, other: Self, op: fn (T, T) T) Self {
            var result: Self = .{ .components = undefined };
            for (0..N) |i| result.components[i] = op(self.components[i], other.components[i]);
            return result;
        }
        pub fn binary_scalar_op(self: Self, other: T, op: fn (T, T) T) Self {
            var result: Self = .{ .components = undefined };
            for (0..N) |i| result.components[i] = op(self.components[i], other);
            return result;
        }
        pub fn unary_op(self: Self, op: fn (T) T) Self {
            var result: Self = .{ .components = undefined };
            for (0..N) |i| result.components[i] = op(self.components[i]);
            return result;
        }
        pub fn reduce(self: Self, op: fn (T, T) T) T {
            var result: T = self.components[0];
            for (1..N) |i| result = op(result, self.components[i]);
            return result;
        }
        pub fn __add__(self: Self, other: Self) Self {
            return self.binary_op(other, __num_add__);
        }
        pub fn __sub__(self: Self, other: Self) Self {
            return self.binary_op(other, __num_sub__);
        }
        pub fn __mul__(self: Self, other: Self) Self {
            return self.binary_op(other, __num_mul__);
        }
        pub fn __div__(self: Self, other: Self) Self {
            return self.binary_op(other, __num_div__);
        }
        pub fn sum(self: Self) T {
            return self.reduce(__num_add__);
        }
        pub fn dot(self: Self, other: Self) T {
            return self.binary_op(other, __num_mul__).sum();
        }
        pub fn __mul_s__(self: Self, other: T) Self {
            return self.binary_scalar_op(other, __num_mul__);
        }
        pub fn __mul_si__(self: Self, other: i32) Self {
            return self.__mul_s__(__num_from_int__(other));
        }
        pub fn __div_s__(self: Self, other: T) Self {
            return self.binary_scalar_op(other, __num_div__);
        }
        pub fn __div_si__(self: Self, other: T) Self {
            return self.__div_s__(__num_from_int__(other));
        }
        const CP_Type = switch (N) {
            2 => T,
            3 => Self,
            else => @compileError("Cross product is only implemented for 2D and 3D"),
        };
        fn cross_inner(a: T, b: T, c: T, d: T) T {
            return __num_sub__(__num_mul__(a, b), __num_mul__(c, d));
        }
        fn cross_2d(self: Self, other: Self) T {
            return cross_inner(self.x(), other.y(), self.y(), other.x());
        }
        fn cross_3d(self: Self, other: Self) Self {
            return .{
                .components = .{
                    cross_inner(self.y(), other.z(), self.z(), other.y()),
                    cross_inner(self.z(), other.x(), self.x(), other.z()),
                    self.cross_2d(other),
                },
            };
        }
        pub fn cross(self: Self, other: Self) CP_Type {
            if (CP_Type == T) return self.cross_2d(other);
            return self.cross_3d(other);
        }
        pub fn x(self: Self) T {
            return self.components[0];
        }
        pub fn y(self: Self) T {
            return self.components[1];
        }
        pub fn z(self: Self) T {
            return self.components[2];
        }
        pub fn calc_mag(self: Self) T {
            return std.math.sqrt(self.dot(self));
        }
    };
}

pub fn Triangle(vec_def: Vec_Def) type {
    return struct {
        const T = vec_def.T;
        const N = vec_def.N;
        const Self = @This();
        pub const V_Type = Vec(vec_def);
        vertices: [3]V_Type,

        pub fn a(self: Self) V_Type {
            return self.vertices[0];
        }
        pub fn b(self: Self) V_Type {
            return self.vertices[1];
        }
        pub fn c(self: Self) V_Type {
            return self.vertices[2];
        }
        pub fn calc_area(self: Self) T {
            const ab = self.b().__sub__(self.a());
            const ac = self.c().__sub__(self.a());
            return V_Type.__num_div__(ab.cross(ac).calc_mag(), V_Type.__num_from_int__(2));
        }
    };
}

pub fn AABB(vec_def: Vec_Def) type {
    return struct {
        const T = vec_def.T;
        const N = vec_def.N;
        lower: Vec(vec_def),
        upper: Vec(vec_def),
    };
}

pub fn Mat(comptime T: type, comptime NRows: usize, comptime NCols: usize) type {
    return struct {
        rows: [NRows]Vec(.{ .T = T, .N = NCols }),
    };
}

fn read_token(reader: anytype, token: *std.ArrayList(u8)) !void {
    token.clearRetainingCapacity();
    // Skip leading whitespace
    while (true) {
        const c = try reader.readByte();
        if (std.ascii.isWhitespace(c)) continue;
        try token.append(c);
        break;
    }
    // Read until whitespace
    while (true) {
        const c = try reader.readByte();
        if (std.ascii.isWhitespace(c)) break;
        try token.append(c);
    }
}

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
    return if (arr[first] > val) first else arr.len;
}

pub fn main() !void {
    var gpa = GPA(.{}).init;
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

    const cwd = std.fs.cwd();
    const input_mesh_file = cwd.openFile(input_mesh_filepath, .{ .mode = .read_only }) catch {
        try stderr_bw_w.print("Failed to open file: {s}\n", .{input_mesh_filepath});
        return;
    };
    defer input_mesh_file.close();

    const input_mesh_r = input_mesh_file.reader();
    var input_mesh_br = std.io.bufferedReader(input_mesh_r);
    var input_mesh_br_r = input_mesh_br.reader();

    try input_mesh_r.skipBytes(80, .{});
    const num_tris = @as(u64, try input_mesh_r.readInt(u32, .little));
    const expected_binary_size = num_tris * 50 + 84;
    const file_size = try input_mesh_file.getEndPos();

    const vec_def: Vec_Def = .{ .T = f32, .N = 3 };
    const T_Type = Triangle(vec_def);
    var tris = std.ArrayList(T_Type).init(ator);
    defer tris.deinit();

    if (expected_binary_size == file_size) {
        std.debug.print("Binary\n", .{});
        std.debug.print("TODO: Implement binary .stl reader\n", .{});
    } else {
        std.debug.print("ASCII\n", .{});
        try input_mesh_file.seekTo(0);
        // Recreate buffered reader after seeking file, otherwise it will read from the old position
        input_mesh_br = std.io.bufferedReader(input_mesh_r);
        input_mesh_br_r = input_mesh_br.reader();

        var token = std.ArrayList(u8).init(ator);
        defer token.deinit();

        outer: while (true) {
            read_token(input_mesh_br_r, &token) catch break :outer;
            if (std.mem.eql(u8, token.items, "loop")) {
                var t: T_Type = .{ .vertices = undefined };
                for (0..3) |vi| {
                    // read "vertex"
                    read_token(input_mesh_br_r, &token) catch break :outer;
                    for (0..3) |ci| {
                        read_token(input_mesh_br_r, &token) catch break :outer;
                        const c = try std.fmt.parseFloat(f32, token.items);
                        t.vertices[vi].components[ci] = c;
                    }
                }
                try tris.append(t);
            }
        }
    }

    std.debug.print("Num tris {}\n", .{tris.items.len});

    var tris_areas = try ator.alloc(f32, tris.items.len);
    defer ator.free(tris_areas);
    for (tris.items, 0..) |t, i| tris_areas[i] = t.calc_area();
    // Compute CDF
    for (1..tris.items.len) |i|
        tris_areas[i] = T_Type.V_Type.__num_add__(tris_areas[i], tris_areas[i - 1]);
    // Normalize CDF
    for (0..tris.items.len) |i|
        tris_areas[i] = T_Type.V_Type.__num_div__(tris_areas[i], tris_areas[tris.items.len - 1]);

    // Create ply
    const output_ply_file = cwd.createFile(output_ply_filepath, .{}) catch {
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

        const ca = t.a().__sub__(t.c());
        const cb = t.b().__sub__(t.c());
        const p = ca.__mul_s__(u).__add__(cb.__mul_s__(v)).__add__(t.c());

        try output_ply_bw_w.writeInt(u32, @bitCast(p.x()), .little);
        try output_ply_bw_w.writeInt(u32, @bitCast(p.y()), .little);
        try output_ply_bw_w.writeInt(u32, @bitCast(p.z()), .little);
    }
}
