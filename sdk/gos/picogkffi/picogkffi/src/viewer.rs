// Viewer with callbacks for camera control and rendering.
#![allow(dead_code, unused_variables, unused_imports)]
// Implements the same camera math as the Go ViewerEx / PicoPie viewer.py,
// entirely in Rust so Gossamer can use it without C->Gossamer callbacks.

use std::sync::Mutex;
use std::os::raw::c_char;

use crate::{PKVector2, PKVector3, PKVector4, PKBBox3, PKColorFloat, PKMatrix4x4};

// macOS main-thread dispatch (for OpenGL Viewer)
#[cfg(target_os = "macos")]
unsafe extern "C" {
    pub fn dispatch_run_on_main(fn_ptr: unsafe extern "C" fn(*mut std::ffi::c_void) -> *mut std::ffi::c_void,
                             arg: *mut std::ffi::c_void) -> *mut std::ffi::c_void;
}

// Workaround struct for passing args through dispatch
#[repr(C)]
pub struct ViewerCreateArgs {
    pub title: *const c_char,
    pub width: f32,
    pub height: f32,
    pub bg_r: f32, pub bg_g: f32, pub bg_b: f32, pub bg_a: f32,
}

#[cfg(target_os = "macos")]
pub unsafe extern "C" fn dispatch_viewer_create(arg: *mut std::ffi::c_void) -> *mut std::ffi::c_void {
    let args = &*(arg as *const ViewerCreateArgs);
    let size = PKVector2 { x: args.width, y: args.height };
    let v = Viewer_hCreate(
        args.title, &size,
        viewer_info_cb, viewer_update_cb, viewer_key_cb,
        viewer_mouse_move_cb, viewer_mouse_button_cb,
        viewer_scroll_cb, viewer_window_size_cb,
    );
    if !v.is_null() {
        load_ibl_lighting(v);
    }
    v as *mut std::ffi::c_void
}

// Screenshot args
#[repr(C)]
pub struct ScreenshotArgs {
    pub viewer: *mut std::ffi::c_void,
    pub path: *const c_char,
    pub frames: i32,
}

#[cfg(target_os = "macos")]
pub unsafe extern "C" fn dispatch_viewer_screenshot(arg: *mut std::ffi::c_void) -> *mut std::ffi::c_void {
    let args = &*(arg as *const ScreenshotArgs);
    Viewer_RequestScreenShot(args.viewer, args.path);
    Viewer_RequestUpdate(args.viewer);
    // Poll for a few frames to let the screenshot render
    for _ in 0..args.frames {
        if !Viewer_bPoll(args.viewer) { break; }
    }
    std::ptr::null_mut()
}

// Close args
#[repr(C)]
pub struct CloseArgs {
    pub viewer: *mut std::ffi::c_void,
}

#[cfg(target_os = "macos")]
pub unsafe extern "C" fn dispatch_viewer_close(arg: *mut std::ffi::c_void) -> *mut std::ffi::c_void {
    let args = &*(arg as *const CloseArgs);
    Viewer_RequestClose(args.viewer);
    Viewer_Destroy(args.viewer);
    std::ptr::null_mut()
}

// C function pointer types (matching picogk_ffi.h)
pub type PFInfo = unsafe extern "C" fn(*const c_char, bool);
pub type PFUpdate = unsafe extern "C" fn(*mut std::ffi::c_void, *const PKVector2, *mut PKColorFloat, *mut PKMatrix4x4, *mut PKVector3);
pub type PFKeyPressed = unsafe extern "C" fn(*mut std::ffi::c_void, i32, i32, i32, i32);
pub type PFMouseMoved = unsafe extern "C" fn(*mut std::ffi::c_void, *const PKVector2, bool, bool, bool, bool);
pub type PFMouseButton = unsafe extern "C" fn(*mut std::ffi::c_void, i32, i32, i32, *const PKVector2);
pub type PFScrollWheel = unsafe extern "C" fn(*mut std::ffi::c_void, *const PKVector2, *const PKVector2, bool, bool, bool, bool);
pub type PFWindowSize = unsafe extern "C" fn(*mut std::ffi::c_void, *const PKVector2);

unsafe extern "C" {
    pub fn Viewer_hCreate(
        title: *const c_char,
        pSize: *const PKVector2,
        info_cb: PFInfo,
        update_cb: PFUpdate,
        key_cb: PFKeyPressed,
        mouse_move_cb: PFMouseMoved,
        mouse_button_cb: PFMouseButton,
        scroll_cb: PFScrollWheel,
        window_size_cb: PFWindowSize,
    ) -> *mut std::ffi::c_void;
    pub fn Viewer_Destroy(viewer: *mut std::ffi::c_void);
    pub fn Viewer_bIsValid(viewer: *mut std::ffi::c_void) -> bool;
    pub fn Viewer_bPoll(viewer: *mut std::ffi::c_void) -> bool;
    pub fn Viewer_RequestClose(viewer: *mut std::ffi::c_void);
    pub fn Viewer_RequestScreenShot(viewer: *mut std::ffi::c_void, path: *const c_char);
    pub fn Viewer_RequestUpdate(viewer: *mut std::ffi::c_void);
    pub fn Viewer_GetBoundingBox(viewer: *mut std::ffi::c_void, pBBox: *mut PKBBox3);
    pub fn Viewer_AddVoxels(hInstance: u64, viewer: *mut std::ffi::c_void, group: i32, hVoxels: u64);
    pub fn Viewer_AddMesh(hInstance: u64, viewer: *mut std::ffi::c_void, group: i32, hMesh: u64);
    pub fn Viewer_RemoveAllObjects(viewer: *mut std::ffi::c_void);
    pub fn Viewer_SetGroupVisible(viewer: *mut std::ffi::c_void, group: i32, visible: bool);
    pub fn Viewer_SetGroupMaterial(viewer: *mut std::ffi::c_void, group: i32, pColor: *const PKColorFloat, metallic: f32, roughness: f32);
    pub fn Viewer_bLoadLightSetup(viewer: *mut std::ffi::c_void, diffuse: *const c_char, diffuseSize: i32, specular: *const c_char, specularSize: i32) -> bool;
}

// Camera state (matches Go CameraState / PicoPie viewer.py)
pub struct CameraState {
    pub target: [f32; 3],
    pub radius: f32,
    pub azimuth: f32,
    pub elevation: f32,
    pub zoom: f32,
    pub autofit: bool,
    pub drag_button: i32,  // -1 = no drag
    pub mouse_x: f32,
    pub mouse_y: f32,
    pub bg_r: f32, pub bg_g: f32, pub bg_b: f32, pub bg_a: f32,
}

impl Default for CameraState {
    fn default() -> Self {
        Self {
            target: [0.0; 3],
            radius: 10.0,
            azimuth: 0.6,
            elevation: 0.5,
            zoom: 1.0,
            autofit: true,
            drag_button: -1,
            mouse_x: 0.0,
            mouse_y: 0.0,
            bg_r: 0.16, bg_g: 0.16, bg_b: 0.20, bg_a: 1.0,
        }
    }
}

pub static CAM: std::sync::LazyLock<Mutex<CameraState>> = std::sync::LazyLock::new(|| Mutex::new(CameraState::default()));
// Viewer handle stored as usize (Send + Sync safe wrapper for raw pointer)
pub static ACTIVE_VIEWER: std::sync::LazyLock<Mutex<Option<usize>>> = std::sync::LazyLock::new(|| Mutex::new(None));

// Constants (matching Go viewer-ex.go)
pub const FOV_Y: f32 = 35.0 * std::f32::consts::PI / 180.0;
pub const ORBIT_SPEED: f32 = 0.008;
pub const PAN_SCALE: f32 = 0.0015;
pub const ZOOM_MIN: f32 = 0.05;
pub const ZOOM_MAX: f32 = 20.0;
pub const ELEV_CLAMP: f32 = std::f32::consts::PI / 2.0 - 1e-3;

// Vector math helpers
fn cross3(a: &[f32; 3], b: &[f32; 3]) -> [f32; 3] {
    [a[1] * b[2] - a[2] * b[1],
     a[2] * b[0] - a[0] * b[2],
     a[0] * b[1] - a[1] * b[0]]
}

fn normalize3(v: &mut [f32; 3]) {
    let l = (v[0] * v[0] + v[1] * v[1] + v[2] * v[2]).sqrt();
    if l < 1e-12 { *v = [0.0; 3]; return; }
    v[0] /= l; v[1] /= l; v[2] /= l;
}

fn dot3(a: &[f32; 3], b: &[f32; 3]) -> f32 {
    a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
}

fn sub3(a: &[f32; 3], b: &[f32; 3]) -> [f32; 3] {
    [a[0] - b[0], a[1] - b[1], a[2] - b[2]]
}

fn mat4mul(a: &[f32; 16], b: &[f32; 16]) -> [f32; 16] {
    let mut r = [0.0f32; 16];
    for i in 0..4 {
        for j in 0..4 {
            let mut s = 0.0;
            for k in 0..4 { s += a[i * 4 + k] * b[k * 4 + j]; }
            r[i * 4 + j] = s;
        }
    }
    r
}

fn look_at(eye: &[f32; 3], target: &[f32; 3], up: &[f32; 3]) -> [f32; 16] {
    let mut z = sub3(eye, target);
    normalize3(&mut z);
    let mut x = cross3(up, &z);
    normalize3(&mut x);
    let y = cross3(&z, &x);
    [
        x[0], y[0], z[0], 0.0,
        x[1], y[1], z[1], 0.0,
        x[2], y[2], z[2], 0.0,
        -dot3(&x, eye), -dot3(&y, eye), -dot3(&z, eye), 1.0,
    ]
}

fn perspective(fovy: f32, aspect: f32, near_z: f32, far_z: f32) -> [f32; 16] {
    let ys = 1.0 / (fovy * 0.5).tan();
    let xs = ys / aspect.max(1e-6);
    [
        xs, 0.0, 0.0, 0.0,
        0.0, ys, 0.0, 0.0,
        0.0, 0.0, far_z / (near_z - far_z), -1.0,
        0.0, 0.0, near_z * far_z / (near_z - far_z), 1.0,
    ]
}

fn camera_basis(cam: &CameraState) -> ([f32; 3], [f32; 3], [f32; 3]) {
    let ce = cam.elevation.cos();
    let se = cam.elevation.sin();
    let ca = cam.azimuth.cos();
    let sa = cam.azimuth.sin();
    let d = [ce * ca, ce * sa, se];
    let up = [0.0, 0.0, 1.0];
    let mut right = cross3(&up, &d);
    normalize3(&mut right);
    let up_cam = cross3(&d, &right);
    (d, right, up_cam)
}

fn camera_distance(cam: &CameraState) -> f32 {
    cam.radius / (FOV_Y / 2.0).sin() * 1.1 * cam.zoom
}

// C callbacks

pub unsafe extern "C" fn viewer_info_cb(_msg: *const c_char, _fatal: bool) {}

pub unsafe extern "C" fn viewer_update_cb(
    _viewer: *mut std::ffi::c_void,
    vp: *const PKVector2,
    bg: *mut PKColorFloat,
    mvp: *mut PKMatrix4x4,
    eye: *mut PKVector3,
) {
    let mut cam = CAM.lock().unwrap();

    if !bg.is_null() {
        (*bg).r = cam.bg_r;
        (*bg).g = cam.bg_g;
        (*bg).b = cam.bg_b;
        (*bg).a = cam.bg_a;
    }

    // Autofit from scene bounding box
    if cam.autofit {
        if let Some(viewer) = *ACTIVE_VIEWER.lock().unwrap() {
            let viewer_ptr = viewer as *mut std::ffi::c_void;
            let mut box_ = PKBBox3::default();
            Viewer_GetBoundingBox(viewer_ptr, &mut box_);
            let lo = [box_.min.x, box_.min.y, box_.min.z];
            let hi = [box_.max.x, box_.max.y, box_.max.z];
            if hi[0] >= lo[0] && hi[1] >= lo[1] && hi[2] >= lo[2] {
                cam.target[0] = (lo[0] + hi[0]) * 0.5;
                cam.target[1] = (lo[1] + hi[1]) * 0.5;
                cam.target[2] = (lo[2] + hi[2]) * 0.5;
                let dx = hi[0] - lo[0];
                let dy = hi[1] - lo[1];
                let dz = hi[2] - lo[2];
                let diag = (dx * dx + dy * dy + dz * dz).sqrt();
                if diag > 1e-3 {
                    cam.radius = diag * 0.5;
                }
            }
        }
    }

    let aspect = if !vp.is_null() && (*vp).y > 0.0 {
        (*vp).x / (*vp).y.max(1e-6)
    } else {
        1.0
    };

    let dist = camera_distance(&cam);
    let (d, right, up_cam) = camera_basis(&cam);
    let eye_pos = [
        cam.target[0] + d[0] * dist,
        cam.target[1] + d[1] * dist,
        cam.target[2] + d[2] * dist,
    ];
    let near_z = (dist * 0.01).max(0.01);
    let far_z = dist * 10.0 + 1000.0;
    let v = look_at(&eye_pos, &cam.target, &[0.0, 0.0, 1.0]);
    let p = perspective(FOV_Y, aspect, near_z, far_z);
    let mvp_result = mat4mul(&v, &p);

    if !mvp.is_null() {
        (*mvp).vec1 = PKVector4 { x: mvp_result[0], y: mvp_result[1], z: mvp_result[2], w: mvp_result[3] };
        (*mvp).vec2 = PKVector4 { x: mvp_result[4], y: mvp_result[5], z: mvp_result[6], w: mvp_result[7] };
        (*mvp).vec3 = PKVector4 { x: mvp_result[8], y: mvp_result[9], z: mvp_result[10], w: mvp_result[11] };
        (*mvp).vec4 = PKVector4 { x: mvp_result[12], y: mvp_result[13], z: mvp_result[14], w: mvp_result[15] };
    }

    if !eye.is_null() {
        (*eye).x = eye_pos[0];
        (*eye).y = eye_pos[1];
        (*eye).z = eye_pos[2];
    }
}

pub unsafe extern "C" fn viewer_key_cb(_viewer: *mut std::ffi::c_void, _key: i32, _scancode: i32, _action: i32, _mods: i32) {}

pub unsafe extern "C" fn viewer_mouse_move_cb(_viewer: *mut std::ffi::c_void, pos: *const PKVector2, _shift: bool, _ctrl: bool, _alt: bool, _sup: bool) {
    let mut cam = CAM.lock().unwrap();
    if cam.drag_button >= 0 {
        let dx = (*pos).x - cam.mouse_x;
        let dy = (*pos).y - cam.mouse_y;
        if cam.drag_button == 0 {
            cam.azimuth -= dx * ORBIT_SPEED;
            cam.elevation += dy * ORBIT_SPEED;
            if cam.elevation > ELEV_CLAMP { cam.elevation = ELEV_CLAMP; }
            if cam.elevation < -ELEV_CLAMP { cam.elevation = -ELEV_CLAMP; }
        } else if cam.drag_button == 1 {
            let (_, right, up_cam) = camera_basis(&cam);
            let dist = camera_distance(&cam);
            cam.target[0] -= (right[0] * dx + up_cam[0] * dy) * PAN_SCALE * dist;
            cam.target[1] -= (right[1] * dx + up_cam[1] * dy) * PAN_SCALE * dist;
            cam.target[2] -= (right[2] * dx + up_cam[2] * dy) * PAN_SCALE * dist;
        }
    }
    cam.mouse_x = (*pos).x;
    cam.mouse_y = (*pos).y;
}

pub unsafe extern "C" fn viewer_mouse_button_cb(_viewer: *mut std::ffi::c_void, button: i32, action: i32, _mods: i32, pos: *const PKVector2) {
    let mut cam = CAM.lock().unwrap();
    if action == 1 {
        cam.drag_button = button;
        cam.mouse_x = (*pos).x;
        cam.mouse_y = (*pos).y;
    } else {
        cam.drag_button = -1;
    }
}

pub unsafe extern "C" fn viewer_scroll_cb(_viewer: *mut std::ffi::c_void, offset: *const PKVector2, _pos: *const PKVector2, _shift: bool, _ctrl: bool, _alt: bool, _sup: bool) {
    let mut cam = CAM.lock().unwrap();
    let factor = 1.0 + (*offset).y * 0.1;
    cam.zoom *= factor;
    if cam.zoom < ZOOM_MIN { cam.zoom = ZOOM_MIN; }
    if cam.zoom > ZOOM_MAX { cam.zoom = ZOOM_MAX; }
}

pub unsafe extern "C" fn viewer_window_size_cb(_viewer: *mut std::ffi::c_void, _size: *const PKVector2) {}

// Helper: load IBL lighting from _assets directory or PICOGK_ASSETS env var
pub fn load_ibl_lighting(viewer: *mut std::ffi::c_void) -> bool {
    let base = std::env::var("PICOGK_ASSETS").unwrap_or_else(|_| "_assets".to_string());
    let diffuse_path = format!("{}/Diffuse.dds", base);
    let specular_path = format!("{}/Specular.dds", base);
    let diffuse = match std::fs::read(&diffuse_path) { Ok(d) => d, Err(_) => return false };
    let specular = match std::fs::read(&specular_path) { Ok(s) => s, Err(_) => return false };
    if diffuse.is_empty() || specular.is_empty() { return false; }
    unsafe {
        Viewer_bLoadLightSetup(
            viewer,
            diffuse.as_ptr() as *const c_char,
            diffuse.len() as i32,
            specular.as_ptr() as *const c_char,
            specular.len() as i32,
        )
    }
}

