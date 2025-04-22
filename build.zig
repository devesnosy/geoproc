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

fn create_test(b: *std.Build, test_step: *std.Build.Step, name: []const u8, src: []const u8, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    const exe_test = b.addTest(.{
        .name = name,
        .root_source_file = b.path(src),
        .target = target,
        .optimize = optimize,
    });
    const run_exe_test = b.addRunArtifact(exe_test);
    test_step.dependOn(&run_exe_test.step);
}

fn create_exe(b: *std.Build, test_step: *std.Build.Step, name: []const u8, src: []const u8, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    const exe = b.addExecutable(.{
        .name = name,
        .root_source_file = b.path(src),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);
    create_test(b, test_step, name, src, target, optimize);
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const test_step = b.step("test", "Run unit tests");

    create_exe(b, test_step, "aabb_tree", "src/aabb_tree.zig", target, optimize);
    create_exe(b, test_step, "sample_surface", "src/sample_surface.zig", target, optimize);
    create_exe(b, test_step, "parse_ttf", "src/parse_ttf.zig", target, optimize);
    create_exe(b, test_step, "draw_2d", "src/draw_2d.zig", target, optimize);
}
