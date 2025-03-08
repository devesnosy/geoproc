const std = @import("std");

pub fn eq_u8(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

pub fn as_u32_be(chars: *const [4]u8) u32 {
    return std.mem.readInt(u32, chars, .big);
}

pub fn as_u32_le(chars: *const [4]u8) u32 {
    return std.mem.readInt(u32, chars, .little);
}

pub const File_BR = struct {
    const Buffer_Size = 4096;
    const Buffered_Reader_Type = std.io.BufferedReader(Buffer_Size, std.fs.File.Reader);
    __private_file__: std.fs.File,
    __private_buffered_reader__: Buffered_Reader_Type,
    pub fn init(file: std.fs.File) !File_BR {
        return .{
            .__private_file__ = file,
            .__private_buffered_reader__ = .{ .unbuffered_reader = file.reader() },
        };
    }
    pub fn reader(self: *File_BR) Buffered_Reader_Type.Reader {
        return self.__private_buffered_reader__.reader();
    }
    pub fn seekTo(self: *File_BR, offset: u64) !void {
        try self.__private_file__.seekTo(offset);

        // Clear buffered reader buffer to force getting new data from new file position
        self.__private_buffered_reader__.start = self.__private_buffered_reader__.end;
    }
};
