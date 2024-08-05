package raytracer

import "core:math/rand"
import la "core:math/linalg"

Vec3 :: [3]f64

random_on_hemisphere :: #force_inline proc(normal: Vec3) -> Vec3 {
    on_sphere := random_unit_vector()
    if la.dot(on_sphere, normal) > 0 {
        return on_sphere
    } else {
        return -on_sphere
    }
}

random_unit_vector :: #force_inline proc() -> Vec3 {
    in_sphere: Vec3
    for true {
        p := Vec3 {rand.float64(), rand.float64(), rand.float64()} * 2 - {1, 1, 1}
        if la.length2(p) < 1 {
            in_sphere = p
            break
        }
    }
    return la.normalize(in_sphere)
}

random_unit_disk :: #force_inline proc() -> Vec3 {
    for true {
        p := Vec3 {rand.float64(), rand.float64(), 0} * 2 - {1, 1, 0}
        if la.length2(p) < 1 {
            return p
        }
    }
    unreachable()
}

near_zero :: proc(v: Vec3) -> bool {
    s := 1e-8
    return abs(v.x) < s && abs(v.y) < s && abs(v.z) < s
}

random_color :: proc(min := 0., max := 1.) -> Vec3 {
    return {
        rand.float64_uniform(min, max),
        rand.float64_uniform(min, max),
        rand.float64_uniform(min, max)
    }
}