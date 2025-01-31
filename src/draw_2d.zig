const std = @import("std");
const GPA = std.heap.GeneralPurposeAllocator(.{});

pub const Color = struct { rgb: [3]u8 };

pub const Image = struct {
    width: usize,
    height: usize,
    pixels: []u8,
    ator: std.mem.Allocator,
    pub fn init(ator: std.mem.Allocator, width: usize, height: usize) !Image {
        return .{
            .width = width,
            .height = height,
            .pixels = try ator.alloc(u8, width * height * 3),
            .ator = ator,
        };
    }
    pub fn deinit(self: *Image) void {
        self.ator.free(self.pixels);
    }
};

fn pixel_pos(img: *const Image, x: usize, y: usize) usize {
    return 3 * (y * img.width + x);
}

pub fn set_pixel(img: *Image, x: usize, y: usize, color: [3]u8) void {
    for (0..3) |c|
        img.pixels[pixel_pos(img, x, y) + c] = color[c];
}

pub fn get_pixel(img: *const Image, x: usize, y: usize) Color {
    const pos = pixel_pos(img, x, y);
    return .{ .rgb = img.pixels[pos..][0..3].* };
}

pub fn draw_rect(img: *Image, left: usize, top: usize, width: usize, height: usize, color: [3]u8) void {
    for (left..left + width) |x|
        for (top..top + height) |y|
            set_pixel(img, x, y, color);
}

pub fn is_in_circle(x: f32, y: f32, cx: f32, cy: f32, r: f32) bool {
    const xoff = (x - cx);
    const yoff = (y - cy);
    return (xoff * xoff + yoff * yoff) < r * r;
}

pub fn draw_circle(img: *Image, cx: usize, cy: usize, r: usize, color: [3]u8) void {
    const left = cx - r;
    const top = cy - r;
    const width = r * 2;
    const height = width;
    const cx_f: f32 = @floatFromInt(cx);
    const cy_f: f32 = @floatFromInt(cy);
    const r_f: f32 = @floatFromInt(r);
    for (left..left + width) |x| {
        for (top..top + height) |y| {
            const pixel_center_x = @as(f32, @floatFromInt(x)) + 0.5;
            const pixel_center_y = @as(f32, @floatFromInt(y)) + 0.5;
            if (is_in_circle(pixel_center_x, pixel_center_y, cx_f, cy_f, r_f))
                set_pixel(img, x, y, color);
        }
    }
}

pub fn fill(img: *Image, color: [3]u8) void {
    var i: usize = 0;
    while (i < img.width * img.height * 3) {
        img.pixels[i + 0] = color[0];
        img.pixels[i + 1] = color[1];
        img.pixels[i + 2] = color[2];
        i += 3;
    }
}

pub fn write_ppm(img: *const Image, writer: anytype) !void {
    try writer.print("P6 {} {} 255\n", .{ img.width, img.height });
    _ = try writer.write(img.pixels);
}

pub fn main() !void {
    var gpa = GPA.init;
    defer _ = gpa.deinit();

    const ator = gpa.allocator();

    const cwd = std.fs.cwd();

    const file = try cwd.createFile("output.ppm", .{});
    var bw = std.io.bufferedWriter(file.writer());
    defer bw.flush() catch @panic("Failed to flush buffered writer");
    const bww = bw.writer();

    const width = 1920;
    const height = 1080;
    const SSAA_mult = 4;

    var img = try Image.init(ator, width * SSAA_mult, height * SSAA_mult);
    defer img.deinit();

    fill(&img, .{ 0, 0, 0 });
    const rect_left = (width / 2 - height / 2);
    const rect_top = 0;
    const rect_width = height;
    const rect_height = height;
    draw_rect(
        &img,
        rect_left * SSAA_mult,
        rect_top * SSAA_mult,
        rect_width * SSAA_mult,
        rect_height * SSAA_mult,
        .{ 255, 0, 0 },
    );
    const cr = rect_width / 2;
    draw_circle(
        &img,
        SSAA_mult * (rect_left + cr),
        SSAA_mult * (rect_top + cr),
        SSAA_mult * cr,
        .{ 0, 0, 255 },
    );

    var img2 = try Image.init(ator, width, height);
    defer img2.deinit();

    const num_samples_f: f32 = @floatFromInt(SSAA_mult * SSAA_mult);

    for (0..width) |x| {
        for (0..height) |y| {
            var avg_f: [3]f32 = .{ 0, 0, 0 };
            for (0..SSAA_mult) |i| {
                for (0..SSAA_mult) |j| {
                    const p = get_pixel(&img, x * SSAA_mult + i, y * SSAA_mult + j);
                    avg_f[0] += @as(f32, @floatFromInt(p.rgb[0])) / num_samples_f;
                    avg_f[1] += @as(f32, @floatFromInt(p.rgb[1])) / num_samples_f;
                    avg_f[2] += @as(f32, @floatFromInt(p.rgb[2])) / num_samples_f;
                }
            }
            const avg: [3]u8 = .{
                @intFromFloat(@round(avg_f[0])),
                @intFromFloat(@round(avg_f[1])),
                @intFromFloat(@round(avg_f[2])),
            };
            set_pixel(&img2, x, y, avg);
        }
    }

    try write_ppm(&img2, bww);
}
