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

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_vec = b.addStaticLibrary(.{
        .name = "vec",
        .root_source_file = b.path("src/vec.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib_vec);

    const lib_triangle = b.addStaticLibrary(.{
        .name = "triangle",
        .root_source_file = b.path("src/triangle.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib_triangle);

    const lib_aabb = b.addStaticLibrary(.{
        .name = "aabb",
        .root_source_file = b.path("src/aabb.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib_aabb);

    const lib_mat = b.addStaticLibrary(.{
        .name = "mat",
        .root_source_file = b.path("src/mat.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib_mat);

    const exe = b.addExecutable(.{
        .name = "sample_surface",
        .root_source_file = b.path("src/sample_surface.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/vec.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/sample_surface.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}
