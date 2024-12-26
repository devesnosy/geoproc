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
        pub const __num_gt__ = if (is_builtin_num_type) __builtin_num_gt__ else T.__gt__;
        pub const __num_lt__ = if (is_builtin_num_type) __builtin_num_lt__ else T.__lt__;
        pub fn __num_max__(a: T, b: T) T {
            if (__num_gt__(a, b)) return a;
            return b;
        }
        pub fn __num_min__(a: T, b: T) T {
            if (__num_lt__(a, b)) return a;
            return b;
        }
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
        fn __builtin_num_gt__(a: T, b: T) bool {
            return a > b;
        }
        fn __builtin_num_lt__(a: T, b: T) bool {
            return a < b;
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
        pub fn max(self: Self, other: Self) Self {
            return self.binary_op(other, __num_max__);
        }
        pub fn min(self: Self, other: Self) Self {
            return self.binary_op(other, __num_min__);
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
