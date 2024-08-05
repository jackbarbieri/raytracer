package raytracer

import "core:math"
import la "core:math/linalg"

Sphere :: struct {
    center: Vec3,
    radius: f64,
    material: Material
}

hit_sphere :: proc(s: Sphere, r: Ray, tmin, tmax: f64, rec: ^HitRecord) -> bool {
    oc := s.center - r.origin
    a := la.length2(r.direction)
    h := la.dot(r.direction, oc)
    c := la.length2(oc) - s.radius * s.radius
    discriminant := h*h - a * c
    if discriminant < 0 {
        return false
    }

    sqrtd := math.sqrt(discriminant)

    root := (h - sqrtd) / a
    if root <= tmin || tmax <= root {
        root = (h + sqrtd) / a
        if root <= tmin || tmax <= root {
            return false
        }
    }
    rec.t = root
    rec.p = ray_at(r, rec.t)
    out_norm := (rec.p - s.center) / s.radius
    set_face_normal(rec, r, out_norm)
    rec.mat = s.material
    return true
}