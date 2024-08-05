package raytracer

import "base:runtime"
import "core:fmt"
import "core:math"
import "core:math/rand"
import la "core:math/linalg"

IMG_WIDTH :: 1280
IMG_HEIGHT :: 720

VP_HEIGHT :: 2.0
VP_WIDTH :: VP_HEIGHT * f64(IMG_WIDTH)/IMG_HEIGHT

main :: proc() {
    world: [dynamic]Hittable
    ground: Material = {
        lambertian,
        &LambertianData{
            {.5, .5, .5}
        }
    }
    for a in -11..<11 {
        for b in -11..<11 {
            choose_mat := rand.float64()
            center := Vec3{f64(a) + .9 * rand.float64(), .2, f64(b) + .9 * rand.float64()}
            if la.length(center - {4, .2, 0}) > .9 {
                mat: Material
                if choose_mat < .8 {
                    data := new(LambertianData, context.temp_allocator)
                    data.albedo = random_color() * random_color()
                    mat.scatter = lambertian
                    mat.data = data
                } else if choose_mat < .95 {
                    data := new(MetalData, context.temp_allocator)
                    data.albedo = random_color(.5)
                    data.fuzz = rand.float64() * .5
                    mat.scatter = metal
                    mat.data = data
                } else {
                    data := new(DialectricData, context.temp_allocator)
                    data.ior = 1.5
                    mat.scatter = dialectric
                    mat.data = data
                }
                append(&world, Sphere{center, .2, mat})
            }
        }
    }
    append(&world, Sphere{{0, -1000, 0}, 1000, ground})
    mat1 := Material {
        dialectric,
        &DialectricData{1.5}
    }
    append(&world, Sphere{{0, 1, 0}, 1, mat1})
    mat2 := Material {
        lambertian,
        &LambertianData{{.4, .2, .1}}
    }
    append(&world, Sphere{{-4, 1, 0}, 1, mat2})
    mat3 := Material {
        metal,
        &MetalData{{.7, .6, .5}, 0}
    }
    append(&world, Sphere{{4, 1, 0}, 1, mat3})
    render(world)
}