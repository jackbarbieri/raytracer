package raytracer

import "core:math/linalg"

Hittable :: union {
    Sphere,
    [dynamic]Hittable
}

HitRecord :: struct {
    p: Vec3,
    normal: Vec3,
    t: f64,
    front: bool,
    mat: Material,
    mat_data: rawptr
}

set_face_normal :: proc(rec: ^HitRecord, r: Ray, out_norm: Vec3) {
    rec.front = linalg.dot(r.direction, out_norm) < 0
    rec.normal = rec.front ? out_norm : -out_norm
}

hit :: proc(obj: Hittable, r: Ray, tmin, tmax: f64, rec: ^HitRecord) -> bool {
    switch o in obj {
        case Sphere:
            return hit_sphere(o, r, tmin, tmax, rec)
        case [dynamic]Hittable:
            return hit_list(o, r, tmin, tmax, rec)
    }
    unreachable()
}

hit_list :: proc (objects: [dynamic]Hittable, r: Ray, tmin, tmax: f64, rec: ^HitRecord) -> bool {
    temp_rec: HitRecord
    hit_anything: bool
    closest := tmax
    for o in objects {
        if hit(o, r, tmin, closest, &temp_rec) {
            hit_anything = true
            closest = temp_rec.t
            rec^ = temp_rec
        }
    }
    return hit_anything
}