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

pub fn AABB(vec_def: lib_vec.Vec_Def) type {
    return struct {
        const Self = @This();
        const V_Type = lib_vec.Vec(vec_def);
        lower: V_Type,
        upper: V_Type,
        pub fn calc_extent(self: Self) V_Type {
            return self.upper.__sub__(self.lower);
        }
        pub fn calc_center(self: Self) V_Type {
            return self.upper.__add__(self.lower).__div_si__(2);
        }
        pub fn join(self: Self, other: Self) Self {
            return .{
                .lower = self.lower.min(other.lower),
                .upper = self.upper.max(other.upper),
            };
        }
    };
}
