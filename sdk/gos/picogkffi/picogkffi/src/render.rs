// Software renderer: isometric Lambertian shading to PNG.
// Matches the PicoGK MCP server's RenderToImage tool exactly.

use std::fs::File;
use std::io::BufWriter;

use crate::*;

pub fn render_mesh_to_png(
    mesh_handle: u64,
    path: &str,
    width: u32,
    height: u32,
    bg_r: u8, bg_g: u8, bg_b: u8,
    obj_r: u8, obj_g: u8, obj_b: u8,
) {
    // Get bounding box
    let mut bbox = PKBBox3::default();
    unsafe { Mesh_GetBoundingBox(get_instance(), mesh_handle, &mut bbox) };

    let size_x = bbox.max.x - bbox.min.x;
    let size_y = bbox.max.y - bbox.min.y;
    let size_z = bbox.max.z - bbox.min.z;
    let max_dim = size_x.max(size_y).max(size_z);
    if max_dim < 1e-6 { return; }

    let scale = (width.min(height) as f32) * 0.7 / max_dim;
    let cx = (bbox.min.x + bbox.max.x) * 0.5;
    let cy = (bbox.min.y + bbox.max.y) * 0.5;
    let cz = (bbox.min.z + bbox.max.z) * 0.5;

    // Isometric projection: rotate around Y by 45°, then around X by 30°
    let cos_a = (std::f32::consts::PI / 6.0).cos(); // 30°
    let sin_a = (std::f32::consts::PI / 6.0).sin();
    let cos_b = (std::f32::consts::PI / 4.0).cos(); // 45°
    let sin_b = (std::f32::consts::PI / 4.0).sin();

    // Light direction (upper-front-left), normalized
    let light_dir = {
        let l = [-0.5f32, 0.8, -0.4];
        let len = (l[0]*l[0] + l[1]*l[1] + l[2]*l[2]).sqrt();
        [l[0]/len, l[1]/len, l[2]/len]
    };
    let ambient = 0.35f32;

    let tri_count = unsafe { Mesh_nTriangleCount(get_instance(), mesh_handle) } as usize;

    // Collect triangles with projected positions, depth, and shading
    struct Tri {
        x0: f32, y0: f32, x1: f32, y1: f32, x2: f32, y2: f32,
        depth: f32, r: u8, g: u8, b: u8,
    }

    let mut triangles: Vec<Tri> = Vec::with_capacity(tri_count);

    for i in 0..tri_count as i32 {
        let mut v0 = PKVector3::default();
        let mut v1 = PKVector3::default();
        let mut v2 = PKVector3::default();
        unsafe { Mesh_GetTriangleV(get_instance(), mesh_handle, i, &mut v0, &mut v1, &mut v2) };

        // Face normal
        let e1 = [v1.x - v0.x, v1.y - v0.y, v1.z - v0.z];
        let e2 = [v2.x - v0.x, v2.y - v0.y, v2.z - v0.z];
        let nx = e1[1]*e2[2] - e1[2]*e2[1];
        let ny = e1[2]*e2[0] - e1[0]*e2[2];
        let nz = e1[0]*e2[1] - e1[1]*e2[0];
        let area2 = (nx*nx + ny*ny + nz*nz).sqrt();
        if area2 < 1e-9 { continue; }

        // Back-face culling: check if face points toward camera
        // After Y-rotation: nrx = nx*cosB - nz*sinB, nrz = nx*sinB + nz*cosB
        // After X-rotation: nry = ny*cosA - nrz*sinA
        let nrx = nx * cos_b - nz * sin_b;
        let nrz = nx * sin_b + nz * cos_b;
        let nry = ny * cos_a - nrz * sin_a;
        if nry <= 0.0 { continue; }

        // Lambertian shading
        let nlen = area2;
        let normal = [nx/nlen, ny/nlen, nz/nlen];
        let lambert = (normal[0]*light_dir[0] + normal[1]*light_dir[1] + normal[2]*light_dir[2]).max(0.0);
        let intensity = ambient + (1.0 - ambient) * lambert;

        let r = ((obj_r as f32) * intensity).min(255.0) as u8;
        let g = ((obj_g as f32) * intensity).min(255.0) as u8;
        let b = ((obj_b as f32) * intensity).min(255.0) as u8;

        // Project vertices
        let project = |p: &PKVector3| -> (f32, f32, f32) {
            let sx = p.x - cx;
            let sy = p.y - cy;
            let sz = p.z - cz;
            let rx = sx * cos_b - sz * sin_b;
            let rz = sx * sin_b + sz * cos_b;
            let ry = sy * cos_a - rz * sin_a;
            let depth = sy * sin_a + rz * cos_a;
            (width as f32 / 2.0 + rx * scale, height as f32 / 2.0 - ry * scale, depth)
    };

        let (px0, py0, d0) = project(&v0);
        let (px1, py1, d1) = project(&v1);
        let (px2, py2, d2) = project(&v2);
        let depth = (d0 + d1 + d2) / 3.0;

        triangles.push(Tri { x0: px0, y0: py0, x1: px1, y1: py1, x2: px2, y2: py2, depth, r, g, b });
    }

    // Painter's algorithm: sort far-to-near
    triangles.sort_by(|a, b| b.depth.partial_cmp(&a.depth).unwrap_or(std::cmp::Ordering::Equal));

    // Rasterize to a pixel buffer
    let mut pixels: Vec<u8> = vec![0u8; (width * height * 4) as usize];
    // Fill background
    for px in pixels.chunks_mut(4) {
        px[0] = bg_r; px[1] = bg_g; px[2] = bg_b; px[3] = 255;
    }

    // Simple triangle rasterizer (barycentric)
    for tri in &triangles {
        let min_x = tri.x0.min(tri.x1).min(tri.x2).max(0.0) as u32;
        let max_x = (tri.x0.max(tri.x1).max(tri.x2).min(width as f32 - 1.0)) as u32;
        let min_y = tri.y0.min(tri.y1).min(tri.y2).max(0.0) as u32;
        let max_y = (tri.y0.max(tri.y1).max(tri.y2).min(height as f32 - 1.0)) as u32;

        let area = (tri.x1 - tri.x0) * (tri.y2 - tri.y0) - (tri.x2 - tri.x0) * (tri.y1 - tri.y0);
        if area.abs() < 1e-6 { continue; }

        for y in min_y..=max_y {
            for x in min_x..=max_x {
                let px = x as f32 + 0.5;
                let py = y as f32 + 0.5;
                let w0 = ((tri.x1 - px) * (tri.y2 - py) - (tri.x2 - px) * (tri.y1 - py)) / area;
                let w1 = ((tri.x2 - px) * (tri.y0 - py) - (tri.x0 - px) * (tri.y2 - py)) / area;
                let w2 = 1.0 - w0 - w1;
                if w0 >= 0.0 && w1 >= 0.0 && w2 >= 0.0 {
                    let idx = ((y * width + x) * 4) as usize;
                    pixels[idx] = tri.r;
                    pixels[idx + 1] = tri.g;
                    pixels[idx + 2] = tri.b;
                    pixels[idx + 3] = 255;
            }
        }
    }
    }

    // Write PNG
    if let Ok(file) = File::create(path) {
        let w = BufWriter::new(file);
        let mut encoder = png::Encoder::new(w, width, height);
    
        encoder.set_color(png::ColorType::Rgba);
        encoder.set_depth(png::BitDepth::Eight);
        if let Ok(mut writer) = encoder.write_header() {
            let _ = writer.write_image_data(&pixels);
        }
    }
}

// Convert a TGA file to PNG format. Removes the TGA file after conversion.
pub fn convert_tga_to_png(tga_path: &str, png_path: &str) {
    convert_tga_to_png_keep(tga_path, png_path, false)
}

// Convert a TGA file to PNG format. If keep_tga is true, the TGA file is kept.
pub fn convert_tga_to_png_keep(tga_path: &str, png_path: &str, keep_tga: bool) {
    let data = match std::fs::read(tga_path) { Ok(d) => d, Err(_) => return };
    if data.len() < 18 { return; }

    let id_len = data[0] as usize;
    let color_map_type = data[1];
    let image_type = data[2];
    let width = (data[12] as usize) | ((data[13] as usize) << 8);
    let height = (data[14] as usize) | ((data[15] as usize) << 8);
    let bpp = data[16] as usize;
    let descriptor = data[17];

    let mut offset = 18 + id_len;
    if color_map_type == 1 {
        let map_len = (data[5] as usize) | ((data[6] as usize) << 8);
        let map_entry_size = data[7] as usize;
        offset += map_len * (map_entry_size / 8);
    }

    if image_type != 2 { return; } // Only uncompressed true-color

    let pixel_data = &data[offset..];
    let stride = width * (bpp / 8);
    let top_origin = (descriptor & 0x20) != 0;

    let mut pixels: Vec<u8> = vec![0u8; width * height * 4];

    for y in 0..height {
        let row_offset = y * stride;
        if row_offset + stride > pixel_data.len() { break; }
        let dst_y = if top_origin { y } else { height - 1 - y };
        for x in 0..width {
            let src_idx = row_offset + x * (bpp / 8);
            let dst_idx = (dst_y * width + x) * 4;
            if bpp == 32 {
                pixels[dst_idx]     = pixel_data[src_idx + 2]; // R
                pixels[dst_idx + 1] = pixel_data[src_idx + 1]; // G
                pixels[dst_idx + 2] = pixel_data[src_idx + 0]; // B
                pixels[dst_idx + 3] = pixel_data[src_idx + 3]; // A
            } else if bpp == 24 {
                pixels[dst_idx]     = pixel_data[src_idx + 2]; // R
                pixels[dst_idx + 1] = pixel_data[src_idx + 1]; // G
                pixels[dst_idx + 2] = pixel_data[src_idx + 0]; // B
                pixels[dst_idx + 3] = 255;                     // A
            }
        }
    }

    if let Ok(file) = std::fs::File::create(png_path) {
        let w = std::io::BufWriter::new(file);
        let mut encoder = png::Encoder::new(w, width as u32, height as u32);
        encoder.set_color(png::ColorType::Rgba);
        encoder.set_depth(png::BitDepth::Eight);
        if let Ok(mut writer) = encoder.write_header() {
            let _ = writer.write_image_data(&pixels);
        }
    }
    if !keep_tga {
        let _ = std::fs::remove_file(tga_path);
    }
}

