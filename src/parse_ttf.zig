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
const as_u32_be = file_br_lib.as_u32_be;

const Platform_ID_Unicode = 0;

const Fixed = packed struct(u32) { fract: u16, int: i16 };
const FWORD = i16;
const UFWORD = u16;
const F2DOT14 = packed struct(u16) { fract: u14, int: i2 };
const LONGDATETIME = i64;
const Tag = union { chars: [4]u8, val: u32 };
const Offset8 = u8;
const Offset16 = u16;
const Offset24 = u24;
const Offset32 = u32;
const Version16Dot16 = packed struct(u32) { minor: u16, major: u16 };

pub fn main() !void {
    var gpa = GPA.init;
    const ator = gpa.allocator();
    defer _ = gpa.deinit();

    // const stdin = std.io.getStdIn();
    // const stdout = std.io.getStdOut();
    // const stdout_writer = stdout.writer();
    const stderr = std.io.getStdErr();

    const args = try std.process.argsAlloc(ator);
    defer std.process.argsFree(ator, args);

    if (args.len != 2) {
        try stderr.writeAll("Expected arguments: /path/to/font.ttf\n");
        return error.Invalid_Number_Of_Arguments;
    }

    const font_path = args[1];

    const cwd = std.fs.cwd();
    const file = try cwd.openFile(font_path, .{ .mode = .read_only });
    defer file.close();
    var file_br = try File_BR.init(file);
    const reader = file_br.reader();
    const sfnt_version = try reader.readInt(u32, .big);
    if (sfnt_version != 0x00010000 and sfnt_version != 0x4F54544F)
        return error.Invalid_SFnt_Version;
    const num_tables = try reader.readInt(u16, .big);
    _ = try reader.readInt(u16, .big); // Search Range
    _ = try reader.readInt(u16, .big); // Entry Selector
    _ = try reader.readInt(u16, .big); // Range Shift
    var cmap_table_offset_opt: ?Offset32 = null;
    for (0..num_tables) |_| {
        const tag = try reader.readInt(u32, .big);
        _ = try reader.readInt(u32, .big); // Checksum
        const offset = try reader.readInt(Offset32, .big); // Offset
        _ = try reader.readInt(u32, .big); // Length
        switch (tag) {
            as_u32_be("cmap") => cmap_table_offset_opt = offset,
            else => {},
        }
    }
    if (cmap_table_offset_opt == null) return error.CMap_Not_Found;

    try file_br.seekTo(cmap_table_offset_opt.?);
    _ = try reader.readInt(u16, .big); // Version
    const num_encoding_tables = try reader.readInt(u16, .big);
    var unicode_subtable_offset_opt: ?Offset32 = null;
    _ = &unicode_subtable_offset_opt;
    for (0..num_encoding_tables) |_| {
        const platform_id = try reader.readInt(u16, .big);
        _ = try reader.readInt(u16, .big); // Encoding ID
        const offset_from_cmap = try reader.readInt(Offset32, .big);
        if (platform_id == Platform_ID_Unicode) unicode_subtable_offset_opt = offset_from_cmap + cmap_table_offset_opt.?;
    }
    if (unicode_subtable_offset_opt == null) return error.Unicode_Subtable_Not_Found;

    try file_br.seekTo(unicode_subtable_offset_opt.?);
    const cmap_subtable_format = try reader.readInt(u16, .big);

    if (cmap_subtable_format != 4) return error.Only_CMap_Subtable_Format_4_Is_Supported_For_Now;

    const cmap_subtable_length = try reader.readInt(u16, .big);
    _ = try reader.readInt(u16, .big); // Language

    const segment_count = try reader.readInt(u16, .big) / 2;

    _ = try reader.readInt(u16, .big); // Search Range
    _ = try reader.readInt(u16, .big); // Entry Selector
    _ = try reader.readInt(u16, .big); // Range Shift

    var end_codes = try ator.alloc(u16, segment_count);
    defer ator.free(end_codes);
    for (0..segment_count) |i| {
        end_codes[i] = try reader.readInt(u16, .big);
    }

    _ = try reader.readInt(u16, .big); // Padding

    var start_codes = try ator.alloc(u16, segment_count);
    defer ator.free(start_codes);
    for (0..segment_count) |i| {
        start_codes[i] = try reader.readInt(u16, .big);
    }

    var id_deltas = try ator.alloc(i16, segment_count);
    defer ator.free(id_deltas);
    for (0..segment_count) |i| {
        id_deltas[i] = try reader.readInt(i16, .big);
    }

    var id_range_offsets = try ator.alloc(u16, segment_count);
    defer ator.free(id_range_offsets);
    for (0..segment_count) |i| {
        id_range_offsets[i] = try reader.readInt(u16, .big);
    }

    const glyph_ids_num_bytes = cmap_subtable_length - 8 * (segment_count + 2);
    const glyph_ids_num_items = glyph_ids_num_bytes / 2;
    var glyph_ids = try ator.alloc(u16, glyph_ids_num_items);
    defer ator.free(glyph_ids);

    for (0..glyph_ids_num_items) |i| {
        glyph_ids[i] = try reader.readInt(u16, .big);
    }

    const code_point = 'a';
    var segment_index_opt: ?usize = null;
    for (0..segment_count) |i| {
        if (code_point >= start_codes[i] and code_point <= end_codes[i]) segment_index_opt = i;
    }
    if (segment_index_opt == null) return error.Failed_To_Find_Segment;

    var glyph_id: usize = 0;

    const si = segment_index_opt.?;
    const id_range_offset = id_range_offsets[si];
    if (id_range_offset == 0) {} else {
        const @"offset_from_id_offset's_location_in_file" = id_range_offsets[si] + code_point - start_codes[si];
        _ = @"offset_from_id_offset's_location_in_file";
    }

    _ = &glyph_id;
    // TODO
}
