package raytracer

import "core:math"
import la "core:math/linalg"
import "core:math/rand"
import "core:fmt"
import "core:time"
import "core:thread"
import "base:intrinsics"
import "core:os"

Camera :: struct {
    center: Vec3,
    vp_width, vp_height: f64,
    vp_u, vp_v,
    p_du, p_dv,
    upper_left, p00_loc: Vec3,
    samples: int,
    px_samp_scale: f64,
    max_depth: int,
    vfov: f64,
    lookfrom, lookat, up,
    u, v, w: Vec3,
    defocus_angle, focus_dist: f64,
    dd_u, dd_v: Vec3
}

cam_init :: proc() -> (c: Camera) {
    c.lookfrom = {13,2,3}
    c.lookat = {0,1,0}
    c.up = {0,1,0}
    c.center = c.lookfrom
    c.vfov = 20
    c.defocus_angle = .6
    c.focus_dist = 10

    c.w = la.normalize(c.lookfrom - c.lookat)
    c.u = la.normalize(la.cross(c.up, c.w))
    c.v = la.cross(c.w, c.u)

    theta := math.to_radians(c.vfov)
    h := math.tan(theta/2)
    c.vp_height = 2 * h * c.focus_dist
    c.vp_width = c.vp_height * f64(IMG_WIDTH)/IMG_HEIGHT

    c.vp_u = c.vp_width * c.u
    c.vp_v = c.vp_height * -c.v

    c.p_du = c.vp_u / IMG_WIDTH
    c.p_dv = c.vp_v / IMG_HEIGHT
    c.upper_left = c.center - c.focus_dist * c.w - c.vp_u/2 - c.vp_v / 2
    c.p00_loc = c.upper_left + .5 * (c.p_du + c.p_dv)
    c.samples = 30
    c.max_depth = 10
    c.px_samp_scale = 1.0 / f64(c.samples)

    defocus_radius := c.focus_dist * math.tan(math.to_radians(c.defocus_angle / 2))
    c.dd_u = c.u * defocus_radius
    c.dd_v = c.v * defocus_radius
    return c
}

MULTITHREADED :: true

render :: proc(world: Hittable) {
    c := cam_init()
    setup_image()
    start := time.now()
    if !MULTITHREADED {
        for j in 0..<IMG_HEIGHT {
            fmt.println("remaining:", IMG_HEIGHT - j)
            for i in 0..<IMG_WIDTH {
                px_color := Vec3 {}
                for s in 0..<c.samples {
                    ray := get_ray(i, j, c)
                    px_color += ray_color(ray, c.max_depth, world)
                }
                write_color(i, j, px_color * c.px_samp_scale)
            }
        }
    } else {
        pool: thread.Pool
        thread.pool_init(&pool, context.allocator, os.processor_core_count())
        count := IMG_HEIGHT
        defer thread.pool_destroy(&pool)
        for j in 0..<IMG_HEIGHT {
            data := new(RayColorTaskData, context.temp_allocator)
            data^ = {j, c, world, &count}
            thread.pool_add_task(&pool, context.allocator, ray_color_task, data, j)
        }
        thread.pool_start(&pool)
        thread.pool_finish(&pool)
    }

    end := time.now()
    fmt.printfln("Completed in: %v", time.diff(start, end))
    save_image()
}

RayColorTaskData :: struct {
    j: int,
    c: Camera,
    world: Hittable,
    count: ^int
}

ray_color_task :: proc(t: thread.Task) {
    data := cast(^RayColorTaskData) t.data
    for i in 0..<IMG_WIDTH {
        px_color := Vec3 {}
        for s in 0..<data.c.samples {
            ray := get_ray(i, data.j, data.c)
            px_color += ray_color(ray, data.c.max_depth, data.world)
        }
        write_color(i, data.j, px_color * data.c.px_samp_scale)
    }
    intrinsics.atomic_sub(data.count, 1)
    fmt.println("remaining:", data.count^)
}

ray_color :: proc(r: Ray, depth: int, world: Hittable) -> Vec3 {
    if depth <= 0 {
        return {}
    }
    rec: HitRecord
    if hit(world, r, 0.001, math.INF_F64, &rec) {
        scattered: Ray
        atten: Vec3
        if rec.mat.scatter(r, &rec, &atten, &scattered, rec.mat.data) {
            return atten * ray_color(scattered, depth-1, world)
        }
        return {}
    }
    norm_dir := la.normalize(r.direction)
    a := .5 * (norm_dir.y + 1)
    return (1-a) * Vec3{1,1,1} + a * Vec3{.5, .7, 1}
}

sample_square :: proc() -> Vec3 {
    return {rand.float64() -.5, rand.float64() -.5, 0}
}

get_ray :: proc(i, j: int, c: Camera) -> (r: Ray) {
    offset := sample_square()
    px_samp := c.p00_loc + (f64(i) + offset.x) * c.p_du + (f64(j) + offset.y) * c.p_dv
    r.origin = c.defocus_angle <= 0 ? c.center : dd_sample(c)
    r.direction = px_samp - r.origin
    return r
}

dd_sample :: proc(c: Camera) -> Vec3 {
    p := random_unit_disk()
    return c.center + p.x * c.dd_u + p.y * c.dd_v
}

linear_to_gamma :: #force_inline proc(linear: f64) -> f64 {
    if linear > 0 {
        return math.sqrt(linear)
    }
    return 0
}