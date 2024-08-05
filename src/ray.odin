package raytracer

import la "core:math/linalg"

Ray :: struct {
    origin: [3]f64,
    direction: [3]f64
}


ray_at :: proc(ray: Ray, t: f64) -> [3]f64 {
    return ray.origin + t * ray.direction
}