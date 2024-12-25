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

const lib_vec = @import("vec.zig");
const lib_aabb = @import("aabb.zig");

pub fn Triangle(vec_def: lib_vec.Vec_Def) type {
    return struct {
        const T = vec_def.T;
        const N = vec_def.N;
        const Self = @This();
        pub const V_Type = lib_vec.Vec(vec_def);
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
        /// Sample triangle using standard barycentric formula:
        /// u * A + v * B + (1 - u - v) * C
        pub fn at_standard_uv(self: Self, u: T, v: T) V_Type {
            const ca = self.a().__sub__(self.c());
            const cb = self.b().__sub__(self.c());
            // Simplified from the standard formula
            return ca.__mul_s__(u).__add__(cb.__mul_s__(v)).__add__(self.c());
        }
        pub fn calc_aabb(self: Self) lib_aabb.AABB(vec_def) {
            return .{
                .lower = self.a().min(self.b()).min(self.c()),
                .upper = self.a().max(self.b()).max(self.c()),
            };
        }
    };
}
