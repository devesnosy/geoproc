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
const GPA = std.heap.GeneralPurposeAllocator(.{});

const file_br_lib = @import("file_br.zig");
const File_BR = file_br_lib.File_BR;
const eq_u8 = file_br_lib.eq_u8;
const as_u32_le = file_br_lib.as_u32_le;

const VOX_Size = struct { xyz: [3]u32 };
const VOX_XYZI = struct {
    num_voxels: u32,
    xyzis: []u8,
};
const VOX_Palette = struct { palette: [4 * 256]u8 };

pub fn main() !void {
    var gpa = GPA.init;
    defer _ = gpa.deinit();
    const ator = gpa.allocator();

    const stderr = std.io.getStdErr().writer();

    const args = try std.process.argsAlloc(ator);
    defer std.process.argsFree(ator, args);

    if (args.len != 2) {
        _ = try stderr.write("Expected arguments: /path/to/file.vox\n");
        return;
    }

    const vox_file_path = args[1];

    const cwd = std.fs.cwd();
    const vox_file = try cwd.openFile(vox_file_path, .{ .mode = .read_only });
    defer vox_file.close();

    var file_br = try File_BR.init(vox_file);
    const reader = file_br.reader();

    const header_id = try reader.readInt(u32, .little);
    std.debug.assert(header_id == as_u32_le("VOX "));

    const version_number = try reader.readInt(u32, .little);
    std.debug.print("found vox file version {}\n", .{version_number});

    var num_models: usize = 1;

    var model_sizes = std.ArrayList(VOX_Size).init(ator);
    defer model_sizes.deinit();

    var model_voxels = std.ArrayList(VOX_XYZI).init(ator);
    defer {
        for (model_voxels.items) |mv| ator.free(mv.xyzis);
        model_voxels.deinit();
    }

    var palettes = try std.ArrayList(VOX_Palette).initCapacity(ator, 1);
    defer palettes.deinit();

    while (try vox_file.getPos() < try vox_file.getEndPos()) {
        const chunk_id = try reader.readInt(u32, .little);
        const chunk_content_size = try reader.readInt(u32, .little);
        const chunk_children_size = try reader.readInt(u32, .little);
        _ = chunk_children_size;
        switch (chunk_id) {
            as_u32_le("PACK") => {
                num_models = try reader.readInt(u32, .little);
            },
            as_u32_le("SIZE") => {
                const size_x = try reader.readInt(u32, .little);
                const size_y = try reader.readInt(u32, .little);
                const size_z = try reader.readInt(u32, .little);
                try model_sizes.append(.{ .xyz = .{ size_x, size_y, size_z } });
            },
            as_u32_le("XYZI") => {
                const num_voxels = try reader.readInt(u32, .little);
                const xyzis = try ator.alloc(u8, num_voxels * 4);
                try reader.readNoEof(xyzis);
                try model_voxels.append(.{ .num_voxels = num_voxels, .xyzis = xyzis });
            },
            as_u32_le("RGBA") => {
                var palette: VOX_Palette = undefined;
                try reader.readNoEof(&palette.palette);
                try palettes.append(palette);
            },
            else => {
                try reader.skipBytes(chunk_content_size, .{});
            },
        }
    }

    for (model_voxels.items) |mv| {
        var voxels_dense = try ator.alloc(bool, 256 * 256 * 256);
        defer ator.free(voxels_dense);
        @memset(voxels_dense, false);
        for (0..mv.num_voxels) |i| {
            const x: usize, const y: usize, const z: usize, _ = mv.xyzis[i * 4 ..][0..4].*;
            voxels_dense[x + y * 256 + z * 256 * 256] = true;
        }

        const vertex_indices = try ator.alloc(usize, 257 * 257 * 257);
        @memset(vertex_indices, std.math.maxInt(usize));
        defer ator.free(vertex_indices);
    }
}
