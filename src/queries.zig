const std = @import("std");
const lib_vec = @import("vec.zig");
const lib_aabb = @import("aabb.zig");

pub fn Ray(vec_def: lib_vec.Vec_Def) type {
    return struct {
        const T = vec_def.T;
        const N = vec_def.N;
        const Self = @This();
        pub const V_Type = lib_vec.Vec(vec_def);

        origin: V_Type,
        direction: V_Type,
    };
}

pub fn Queries(vec_def: lib_vec.Vec_Def) type {
    const T = vec_def.T;
    const N = vec_def.N;
    const V_Type = lib_vec.Vec(vec_def);
    return struct {
        pub fn does_intersect_aabb(ray: Ray(vec_def), aabb: lib_aabb.AABB(vec_def)) bool {
            var upper_bound: T = V_Type.__num_from_int__(1682001); // Arbitrary large number
            var lower_bound: T = V_Type.__num_from_int__(0);
            for (0..N) |i| {
                if (V_Type.__num_eq__(ray.direction.at(i), V_Type.__num_from_int__(0))) {
                    if (V_Type.__num_gt__(ray.origin.at(i), aabb.upper.at(i)) or V_Type.__num_lt__(ray.origin.at(i), aabb.lower.at(i))) return false;
                } else {
                    var ub = V_Type.__num_div__(V_Type.__num_sub__(aabb.upper.at(i), ray.origin.at(i)), ray.direction.at(i));
                    var lb = V_Type.__num_div__(V_Type.__num_sub__(aabb.lower.at(i), ray.origin.at(i)), ray.direction.at(i));
                    if (V_Type.__num_lt__(ray.direction.at(i), V_Type.__num_from_int__(0))) {
                        std.mem.swap(T, &ub, &lb);
                    }
                    upper_bound = V_Type.__num_min__(upper_bound, ub);
                    lower_bound = V_Type.__num_max__(lower_bound, lb);
                    if (V_Type.__num_lt__(upper_bound, lower_bound)) return false;
                }
            }
            return true;
        }
    };
}

test "ray AABB intersection" {
    const vec_def: lib_vec.Vec_Def = .{ .T = f32, .N = 3 };
    const AABB = lib_aabb.AABB(vec_def);
    const V_Type = lib_vec.Vec(vec_def);
    const R_Type = Ray(vec_def);
    const Q_Type = Queries(vec_def);
    const aabb1: AABB = .{ .lower = V_Type.init(.{ 0, 0, 0 }), .upper = V_Type.init(.{ 1, 1, 1 }) };
    const ray1: R_Type = .{ .origin = V_Type.init(.{ 0.5, 0.5, 0.5 }), .direction = V_Type.init(.{ 1, 1, 1 }) };
    try std.testing.expect(Q_Type.does_intersect_aabb(ray1, aabb1));
}
