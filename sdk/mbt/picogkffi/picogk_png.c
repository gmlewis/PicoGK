#include "picogk_ffi.h"
// PNG writer using stb_image_write.
// Converts raw pixel data (RGB or RGBA) to a PNG file.
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"
#include <stdlib.h>
#include <string.h>

// Write raw pixel data as a PNG file.
// pixels: raw BGR(A) data from TGA (we'll convert to RGB(A)).
// bytes_per_pixel: 3 (BGR) or 4 (BGRA)
// top_origin: if true, the first row is the top; if false, bottom-first.
// Returns 0 on success, -1 on error.
int picogk_write_png(const char* path, int width, int height,
                     const unsigned char* pixels, int stride,
                     int bytes_per_pixel, int top_origin) {
    // Allocate a buffer for the converted RGB/RGBA data
    int channels = bytes_per_pixel;
    size_t buf_size = (size_t)width * height * channels;
    unsigned char* converted = (unsigned char*)malloc(buf_size);
    if (!converted) return -1;

    for (int y = 0; y < height; y++) {
        // TGA is bottom-first by default (top_origin == 0 means bottom-first)
        int src_y = top_origin ? y : (height - 1 - y);
        for (int x = 0; x < width; x++) {
            const unsigned char* src = pixels + src_y * stride + x * bytes_per_pixel;
            unsigned char* dst = converted + (size_t)y * width * channels + x * channels;
            if (channels == 3) {
                // TGA stores as BGR, convert to RGB
                dst[0] = src[2]; // R
                dst[1] = src[1]; // G
                dst[2] = src[0]; // B
            } else {
                // TGA stores as BGRA, convert to RGBA
                dst[0] = src[2]; // R
                dst[1] = src[1]; // G
                dst[2] = src[0]; // B
                dst[3] = src[3]; // A
            }
        }
    }

    int result = stbi_write_png(path, width, height, channels,
                               converted, width * channels);
    free(converted);
    return result ? 0 : -1;
}

// Take a screenshot from the viewer, convert TGA to PNG, and delete the TGA.
// Returns 0 on success, -1 on error.
// This is a convenience function that reads the TGA file, converts it to PNG,
// and removes the TGA file.
int picogk_screenshot_png(void* viewer, const char* png_path, int frames) {
    // Pump warm-up frames to ensure the scene is fully rendered
    for (int i = 0; i < frames; i++) {
        Viewer_RequestUpdate(viewer);
        Viewer_bPoll(viewer);
    }
    // First, request the screenshot as TGA
    char tga_path[4096];
    snprintf(tga_path, sizeof(tga_path), "%s.tga", png_path);
    Viewer_RequestScreenShot(viewer, tga_path);
    // Poll frames to let the screenshot complete
    for (int i = 0; i < frames; i++) {
        Viewer_RequestUpdate(viewer);
        Viewer_bPoll(viewer);
    }
    // Read the TGA file
    FILE* f = fopen(tga_path, "rb");
    if (!f) return -1;
    fseek(f, 0, SEEK_END);
    long file_size = ftell(f);
    fseek(f, 0, SEEK_SET);
    unsigned char* tga_data = (unsigned char*)malloc(file_size);
    if (!tga_data) { fclose(f); return -1; }
    size_t read = fread(tga_data, 1, file_size, f);
    fclose(f);
    if ((long)read != file_size) { free(tga_data); return -1; }

    // Parse TGA header
    if (file_size < 18) { free(tga_data); return -1; }
    int id_len = tga_data[0];
    int color_map_type = tga_data[1];
    int image_type = tga_data[2];
    int width = tga_data[12] | (tga_data[13] << 8);
    int height = tga_data[14] | (tga_data[15] << 8);
    int bpp = tga_data[16];
    int descriptor = tga_data[17];
    if (image_type != 2) { free(tga_data); return -1; }
    int offset = 18 + id_len;
    if (color_map_type == 1) {
        int map_len = tga_data[5] | (tga_data[6] << 8);
        int map_entry_size = tga_data[7];
        offset += map_len * (map_entry_size / 8);
    }
    int bytes_per_pixel = bpp / 8;
    int stride = width * bytes_per_pixel;
    int top_origin = (descriptor & 0x20) != 0;
    const unsigned char* pixels = tga_data + offset;

    int result = picogk_write_png(png_path, width, height, pixels,
                                  stride, bytes_per_pixel, top_origin);
    free(tga_data);
    // Remove the TGA file
    remove(tga_path);
    return result;
}

// Write a Z-slice SDF array to a grayscale PNG.
// SDF values <= 0 are inside (solid) -> dark; > 0 are outside -> light.
// Returns 0 on success, -1 on error.
int picogk_write_slice_png(const char* path, const float* sdf,
                            int width, int height) {
    if (!sdf || width <= 0 || height <= 0) return -1;

    // Find SDF range for normalization
    float min_val = 1e30f, max_val = -1e30f;
    int n = width * height;
    for (int i = 0; i < n; i++) {
        if (sdf[i] < min_val) min_val = sdf[i];
        if (sdf[i] > max_val) max_val = sdf[i];
    }
    if (max_val - min_val < 1e-6f) max_val = min_val + 1e-6f;

    // Build RGB pixel data
    unsigned char* pixels = (unsigned char*)malloc((size_t)n * 3);
    if (!pixels) return -1;
    for (int i = 0; i < n; i++) {
        float v = sdf[i];
        unsigned char g;
        if (v <= 0) {
            g = 40;  // inside: dark
        } else {
            float t = v / (max_val + 1e-6f);
            if (t > 1) t = 1;
            g = (unsigned char)(40 + t * 200);
        }
        pixels[i * 3] = g;      // R
        pixels[i * 3 + 1] = g;   // G
        pixels[i * 3 + 2] = g;   // B
    }

    int result = stbi_write_png(path, width, height, 3, pixels, width * 3);
    free(pixels);
    return result ? 0 : -1;
}