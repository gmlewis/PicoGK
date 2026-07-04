// SDF (signed distance function) implementations for implicit rendering.
#![allow(dead_code, unused_variables, unused_imports)]
// These are Rust-side SDF callbacks that can be passed directly to
// Voxels_RenderImplicit / Voxels_IntersectImplicit, matching the
// MoonBit picogk_sdf.c approach.

use std::sync::Mutex;

use crate::{PKVector3, PKBBox3, get_instance, VOXELS};

// SDF type enum
pub const SDF_NONE: i32 = 0;
pub const SDF_GYROID_SPHERE: i32 = 1;
pub const SDF_GYROID_GENUS: i32 = 2;
pub const SDF_SUPERELLIPSOID: i32 = 3;
pub const SDF_GYROID: i32 = 4;
pub const SDF_GYROID_SPHERE_OFFSET: i32 = 5;

// Global SDF parameters (set before calling render)
pub struct SdfParams {
    pub sdf_type: i32,
    pub p1: f32, pub p2: f32, pub p3: f32, pub p4: f32, pub p5: f32, pub p6: f32, pub p7: f32,
}

pub static SDF_PARAMS: std::sync::LazyLock<Mutex<SdfParams>> = std::sync::LazyLock::new(|| Mutex::new(SdfParams {
    sdf_type: SDF_NONE, p1: 0.0, p2: 0.0, p3: 0.0, p4: 0.0, p5: 0.0, p6: 0.0, p7: 0.0,
}));

// SDF callback functions (extern "C" so they can be passed as function pointers)

unsafe extern "C" fn sdf_gyroid_sphere(p: *const PKVector3) -> f32 {
    let params = SDF_PARAMS.lock().unwrap();
    let k = params.p3;
    let r = params.p1;
    let wall = params.p2;
    let x = (*p).x;
    let y = (*p).y;
    let z = (*p).z;
    let g = (k * x).sin() * (k * y).cos()
          + (k * y).sin() * (k * z).cos()
          + (k * z).sin() * (k * x).cos();
    let sphere = (x * x + y * y + z * z).sqrt() - r;
    let gyroid_val = g.abs() - wall;
    gyroid_val.max(sphere)
}

unsafe extern "C" fn sdf_gyroid_sphere_offset(p: *const PKVector3) -> f32 {
    let params = SDF_PARAMS.lock().unwrap();
    let k = params.p3;
    let r = params.p1;
    let wall = params.p2;
    let dx = (*p).x - params.p4;
    let dy = (*p).y - params.p5;
    let dz = (*p).z - params.p6;
    let g = (k * dx).sin() * (k * dy).cos()
          + (k * dy).sin() * (k * dz).cos()
          + (k * dz).sin() * (k * dx).cos();
    let sphere = (dx * dx + dy * dy + dz * dz).sqrt() - r;
    let gyroid_val = g.abs() - wall;
    gyroid_val.max(sphere)
}

unsafe extern "C" fn sdf_gyroid_genus(p: *const PKVector3) -> f32 {
    let params = SDF_PARAMS.lock().unwrap();
    let s = params.p1;
    let gap = params.p2;
    let k = params.p3;
    let x = (*p).x / s;
    let y = (*p).y / s;
    let z = (*p).z / s;
    let genus = 2.0 * y * (y * y - 3.0 * x * x) * (1.0 - z * z)
             + (x * x + y * y) * (x * x + y * y)
             - (9.0 * z * z - 1.0) * (1.0 - z * z) - gap;
    let d = (k * (*p).x).sin() * (k * (*p).y).cos()
          + (k * (*p).y).sin() * (k * (*p).z).cos()
          + (k * (*p).z).sin() * (k * (*p).x).cos();
    let gy = d.abs() - 0.5 * 0.6;
    genus.max(gy)
}

unsafe extern "C" fn sdf_superellipsoid(p: *const PKVector3) -> f32 {
    let params = SDF_PARAMS.lock().unwrap();
    let a = params.p1 as f64;
    let c = params.p3 as f64;
    let e1 = params.p4 as f64;
    let e2 = params.p5 as f64;
    let dx = ((*p).x as f64).abs() / a;
    let dy = ((*p).y as f64).abs() / a;
    let dz = ((*p).z as f64).abs() / c;
    let n2 = 2.0 / e2;
    let n1 = 2.0 / e1;
    let xy = dx.powf(n2) + dy.powf(n2);
    let val = xy.powf(e2 / e1) + dz.powf(n1);
    (val - 1.0) as f32
}

unsafe extern "C" fn sdf_gyroid(p: *const PKVector3) -> f32 {
    let params = SDF_PARAMS.lock().unwrap();
    let k = params.p2;
    let wall = params.p1;
    let g = (k * (*p).x).sin() * (k * (*p).y).cos()
          + (k * (*p).y).sin() * (k * (*p).z).cos()
          + (k * (*p).z).sin() * (k * (*p).x).cos();
    g.abs() - wall
}

// Dispatch to the current SDF
pub unsafe extern "C" fn sdf_dispatch(p: *const PKVector3) -> f32 {
    let sdf_type = SDF_PARAMS.lock().unwrap().sdf_type;
    match sdf_type {
        SDF_GYROID_SPHERE => sdf_gyroid_sphere(p),
        SDF_GYROID_GENUS => sdf_gyroid_genus(p),
        SDF_SUPERELLIPSOID => sdf_superellipsoid(p),
        SDF_GYROID => sdf_gyroid(p),
        SDF_GYROID_SPHERE_OFFSET => sdf_gyroid_sphere_offset(p),
        _ => 1e30,
    }
}

// C function pointers for implicit rendering
unsafe extern "C" {
    pub fn Voxels_RenderImplicit(hThis: u64, hVoxels: u64, pBBox: *const PKBBox3, sdf: unsafe extern "C" fn(*const PKVector3) -> f32);
    pub fn Voxels_IntersectImplicit(hThis: u64, hVoxels: u64, sdf: unsafe extern "C" fn(*const PKVector3) -> f32);
}

// Public functions exposed to Gossamer (added to register_module!)
// These are called from the main lib.rs register_module! block.
