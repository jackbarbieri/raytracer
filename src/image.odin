package raytracer

import "base:runtime"
import "core:image"
import "core:image/qoi"
import "core:bytes"

@(private="file")
p: int

@(private="file")
pixels: []image.RGB_Pixel

setup_image :: proc() {
    pixels = make([]image.RGB_Pixel, IMG_HEIGHT * IMG_WIDTH)
}

write_color :: proc(i,j: int, color: Vec3) {
    r := linear_to_gamma(color.r)
    g := linear_to_gamma(color.g)
    b := linear_to_gamma(color.b)
    ir := u8(255.999 * r)
    ig := u8(255.999 * g)
    ib := u8(255.999 * b)
    pixels[j * IMG_WIDTH + i] = {ir, ig, ib}
}

save_image :: proc() {
    // replace with the std proc once its here
    image: image.Image = {}
    image.width = IMG_WIDTH
    image.height = IMG_HEIGHT
    image.depth = 8
    image.channels = 3

    s := transmute(runtime.Raw_Slice)pixels
    d := runtime.Raw_Dynamic_Array {
        data = s.data,
        len = s.len * 3,
        cap = s.len * 3,
        allocator = runtime.nil_allocator()
    }
    image.pixels = bytes.Buffer {
        buf = transmute([dynamic]u8)d
    }
    qoi.save_to_file("rt.qoi", &image)
}