package raytracer

import "core:math"
import "core:math/rand"
import la "core:math/linalg"

Material :: struct {
    scatter: proc(r_in: Ray, rec: ^HitRecord, atten: ^Vec3, scattered: ^Ray, data: rawptr) -> bool,
    data: rawptr,
}

LambertianData :: struct {
    albedo: Vec3
}

lambertian :: proc(r_in: Ray, rec: ^HitRecord, atten: ^Vec3, scattered: ^Ray, data: rawptr) -> bool {
    data := cast(^LambertianData)data
    scattered^ = {rec.p, rec.normal + random_unit_vector()}
    if near_zero(scattered.direction) {
        scattered.direction = rec.normal
    }
    atten^ = data.albedo
    return true
}

MetalData :: struct {
    albedo: Vec3,
    fuzz: f64
}

metal :: proc(r_in: Ray, rec: ^HitRecord, atten: ^Vec3, scattered: ^Ray, data: rawptr) -> bool {
    data := cast(^MetalData)data
    reflected := la.reflect(r_in.direction, rec.normal)
    reflected = la.normalize(reflected) + (data.fuzz * random_unit_vector())
    scattered^ = {rec.p, reflected}
    atten^ = data.albedo
    return la.dot(scattered.direction, rec.normal) > 0
}

DialectricData :: struct {
    ior: f64
}

dialectric :: proc(r_in: Ray, rec: ^HitRecord, atten: ^Vec3, scattered: ^Ray, data: rawptr) -> bool {
    data := cast(^DialectricData)data
    atten^ = {1, 1, 1}
    ior := rec.front ? (1 / data.ior) : data.ior

    unit_dir := la.normalize(r_in.direction)
    cos_theta := min(la.dot(-unit_dir, rec.normal), 1)
    sin_theta := math.sqrt(1 - cos_theta*cos_theta)

    cannot_refract := ior * sin_theta > 1
    direction: Vec3
    if (cannot_refract || reflectance(cos_theta, ior) > rand.float64()) {
        direction = la.reflect(unit_dir, rec.normal)
    } else {
        direction = la.refract(unit_dir, rec.normal, ior)
    }
    scattered^ = {rec.p, direction}
    return true
}

reflectance :: proc(cosine, ior: f64) -> f64 {
    r0 := (1 - ior) / (1 + ior)
    r0 = r0*r0
    return r0 + (1-r0)*math.pow(1 - cosine,5)
}