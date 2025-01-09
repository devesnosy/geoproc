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

pub fn Mat(comptime T: type, comptime NRows: usize, comptime NCols: usize) type {
    return struct {
        const Self = @This();
        const Row_Type = lib_vec.Vec(.{ .T = T, .N = NCols });
        rows: [NRows]Row_Type,

        pub fn transform_vec(self: Self, v: Row_Type) Row_Type {
            var result: Row_Type = undefined;
            for (0..NRows) |i| result[i] = self.rows[i].dot(v);
            return result;
        }
    };
}
