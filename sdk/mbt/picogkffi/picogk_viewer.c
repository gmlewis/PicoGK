// Viewer with callbacks for camera control and rendering.
// This implements the same camera math as the Go ViewerEx / PicoPie viewer.py,
// but entirely in C so MoonBit can use it without C->MoonBit callbacks.

#include "picogk_ffi.h"
#include <math.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

// Camera state (matches Go CameraState / PicoPie viewer.py)
typedef struct {
    float target[3];
    float radius;
    float azimuth;
    float elevation;
    float zoom;
    int autofit;

    int drag_button;  // -1 = no drag
    float mouse_x, mouse_y;

    float bg_r, bg_g, bg_b, bg_a;

    char pending_screenshot[4096];
} CameraState;

static CameraState g_cam;
static void* g_active_viewer = NULL;

// Constants (matching Go viewer-ex.go)
static const float fovY = 35.0f * (float)M_PI / 180.0f;
static const float orbitSpeed = 0.008f;
static const float panScale = 0.0015f;
static const float zoomMin = 0.05f;
static const float zoomMax = 20.0f;
static const float elevClamp = (float)M_PI / 2.0f - 1e-3f;
static const float up[3] = {0, 0, 1};

// --- Vector math helpers ---
static void cross3(float r[3], const float a[3], const float b[3]) {
    r[0] = a[1]*b[2] - a[2]*b[1];
    r[1] = a[2]*b[0] - a[0]*b[2];
    r[2] = a[0]*b[1] - a[1]*b[0];
}

static float norm3(const float v[3]) {
    return sqrtf(v[0]*v[0] + v[1]*v[1] + v[2]*v[2]);
}

static void normalize3(float v[3]) {
    float l = norm3(v);
    if (l < 1e-12f) { v[0] = v[1] = v[2] = 0; return; }
    v[0] /= l; v[1] /= l; v[2] /= l;
}

static float dot3(const float a[3], const float b[3]) {
    return a[0]*b[0] + a[1]*b[1] + a[2]*b[2];
}

static void sub3(float r[3], const float a[3], const float b[3]) {
    r[0] = a[0] - b[0]; r[1] = a[1] - b[1]; r[2] = a[2] - b[2];
}

// 4x4 matrix multiplication (row-major, System.Numerics convention)
static void mat4mul(float r[16], const float a[16], const float b[16]) {
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            float s = 0;
            for (int k = 0; k < 4; k++) s += a[i*4+k] * b[k*4+j];
            r[i*4+j] = s;
        }
    }
}

static void lookAt(float m[16], const float eye[3], const float target[3], const float upV[3]) {
    float z[3], x[3], y[3];
    sub3(z, eye, target);
    normalize3(z);
    cross3(x, upV, z);
    normalize3(x);
    cross3(y, z, x);
    m[0] = x[0]; m[1] = y[0]; m[2] = z[0]; m[3] = 0;
    m[4] = x[1]; m[5] = y[1]; m[6] = z[1]; m[7] = 0;
    m[8] = x[2]; m[9] = y[2]; m[10] = z[2]; m[11] = 0;
    m[12] = -dot3(x, eye); m[13] = -dot3(y, eye); m[14] = -dot3(z, eye); m[15] = 1;
}

static void perspective(float m[16], float fovy, float aspect, float nearZ, float farZ) {
    float ys = 1.0f / tanf(fovy * 0.5f);
    float xs = ys / aspect;
    if (aspect < 1e-6f) xs = ys / 1e-6f;
    m[0] = xs; m[1] = 0; m[2] = 0; m[3] = 0;
    m[4] = 0; m[5] = ys; m[6] = 0; m[7] = 0;
    m[8] = 0; m[9] = 0; m[10] = farZ / (nearZ - farZ); m[11] = -1;
    m[12] = 0; m[13] = 0; m[14] = nearZ * farZ / (nearZ - farZ); m[15] = 1;
}

static void cameraBasis(float d[3], float right[3], float upCam[3]) {
    float ce = cosf(g_cam.elevation);
    float se = sinf(g_cam.elevation);
    float ca = cosf(g_cam.azimuth);
    float sa = sinf(g_cam.azimuth);
    d[0] = ce * ca; d[1] = ce * sa; d[2] = se;
    cross3(right, up, d);
    normalize3(right);
    cross3(upCam, d, right);
}

static float cameraDistance() {
    return g_cam.radius / sinf(fovY / 2.0f) * 1.1f * g_cam.zoom;
}

// --- Callbacks ---

static void mbt_info_cb(const char* msg, bool fatal) {
    (void)msg; (void)fatal;
}

static void mbt_update_cb(void* viewer, const PKVector2* vp,
                           PKColorFloat* bg, PKMatrix4x4* mvp, PKVector3* eye) {
    (void)viewer;
    // Set background (matching Go goUpdateCb)
    if (bg) {
        bg->R = g_cam.bg_r;
        bg->G = g_cam.bg_g;
        bg->B = g_cam.bg_b;
        bg->A = g_cam.bg_a;
    }

    // Autofit: compute target and radius from the scene bounding box.
    // Go's goUpdateCb keeps autofit on every frame (cam.Autofit stays true).
    if (g_cam.autofit) {
        PKBBox3 box;
        Viewer_GetBoundingBox(g_active_viewer, &box);
        float lo[3] = {box.vecMin.X, box.vecMin.Y, box.vecMin.Z};
        float hi[3] = {box.vecMax.X, box.vecMax.Y, box.vecMax.Z};
        if (hi[0] >= lo[0] && hi[1] >= lo[1] && hi[2] >= lo[2]) {
            g_cam.target[0] = (lo[0] + hi[0]) * 0.5f;
            g_cam.target[1] = (lo[1] + hi[1]) * 0.5f;
            g_cam.target[2] = (lo[2] + hi[2]) * 0.5f;
            float dx = hi[0] - lo[0], dy = hi[1] - lo[1], dz = hi[2] - lo[2];
            float diag = sqrtf(dx*dx + dy*dy + dz*dz);
            if (diag < 1e-3f) diag = 1e-3f;
            g_cam.radius = diag * 0.5f;
        }
        // Do NOT clear autofit — Go keeps it on every frame
    }

    float aspect = 1.0f;
    if (vp && vp->Y > 0.0f) {
        aspect = vp->X / (vp->Y > 1e-6f ? vp->Y : 1e-6f);
    }

    float dist = cameraDistance();
    float d[3], right[3], upCam[3];
    cameraBasis(d, right, upCam);
    float eyePos[3] = {
        g_cam.target[0] + d[0] * dist,
        g_cam.target[1] + d[1] * dist,
        g_cam.target[2] + d[2] * dist,
    };
    float nearZ = dist * 0.01f;
    if (nearZ < 0.01f) nearZ = 0.01f;
    float farZ = dist * 10.0f + 1000.0f;
    if (farZ < nearZ + 1e-3f) farZ = nearZ + 1e-3f;

    float v[16], p[16];
    lookAt(v, eyePos, g_cam.target, up);
    perspective(p, fovY, aspect, nearZ, farZ);
    float mvpResult[16];
    mat4mul(mvpResult, v, p);

    // Copy to output
    mvp->vec1.X = mvpResult[0]; mvp->vec1.Y = mvpResult[1]; mvp->vec1.Z = mvpResult[2]; mvp->vec1.W = mvpResult[3];
    mvp->vec2.X = mvpResult[4]; mvp->vec2.Y = mvpResult[5]; mvp->vec2.Z = mvpResult[6]; mvp->vec2.W = mvpResult[7];
    mvp->vec3.X = mvpResult[8]; mvp->vec3.Y = mvpResult[9]; mvp->vec3.Z = mvpResult[10]; mvp->vec3.W = mvpResult[11];
    mvp->vec4.X = mvpResult[12]; mvp->vec4.Y = mvpResult[13]; mvp->vec4.Z = mvpResult[14]; mvp->vec4.W = mvpResult[15];

    eye->X = eyePos[0]; eye->Y = eyePos[1]; eye->Z = eyePos[2];
}

static void mbt_key_cb(void* viewer, int32_t key, int32_t scancode, int32_t action, int32_t mods) {
    (void)viewer; (void)key; (void)scancode; (void)action; (void)mods;
}

static void mbt_mouse_move_cb(void* viewer, const PKVector2* pos, bool shift, bool ctrl, bool alt, bool sup) {
    (void)viewer; (void)shift; (void)ctrl; (void)alt; (void)sup;
    if (g_cam.drag_button >= 0) {
        float dx = pos->X - g_cam.mouse_x;
        float dy = pos->Y - g_cam.mouse_y;
        if (g_cam.drag_button == 0) {
            // Left: orbit
            g_cam.azimuth -= dx * orbitSpeed;
            g_cam.elevation += dy * orbitSpeed;
            if (g_cam.elevation > elevClamp) g_cam.elevation = elevClamp;
            if (g_cam.elevation < -elevClamp) g_cam.elevation = -elevClamp;
        } else if (g_cam.drag_button == 1) {
            // Right: pan
            float d[3], right[3], upCam[3];
            cameraBasis(d, right, upCam);
            float dist = cameraDistance();
            g_cam.target[0] -= (right[0] * dx + upCam[0] * dy) * panScale * dist;
            g_cam.target[1] -= (right[1] * dx + upCam[1] * dy) * panScale * dist;
            g_cam.target[2] -= (right[2] * dx + upCam[2] * dy) * panScale * dist;
        }
    }
    g_cam.mouse_x = pos->X;
    g_cam.mouse_y = pos->Y;
}

static void mbt_mouse_button_cb(void* viewer, int32_t button, int32_t action, int32_t mods, const PKVector2* pos) {
    (void)viewer; (void)mods;
    if (action == 1) {  // press
        g_cam.drag_button = button;
        g_cam.mouse_x = pos->X;
        g_cam.mouse_y = pos->Y;
    } else {  // release
        g_cam.drag_button = -1;
    }
}

static void mbt_scroll_cb(void* viewer, const PKVector2* offset, const PKVector2* pos, bool shift, bool ctrl, bool alt, bool sup) {
    (void)viewer; (void)pos; (void)shift; (void)ctrl; (void)alt; (void)sup;
    // Zoom
    float factor = 1.0f + offset->Y * 0.1f;
    g_cam.zoom *= factor;
    if (g_cam.zoom < zoomMin) g_cam.zoom = zoomMin;
    if (g_cam.zoom > zoomMax) g_cam.zoom = zoomMax;
}

static void mbt_window_size_cb(void* viewer, const PKVector2* size) {
    (void)viewer; (void)size;
}

// --- Public API ---

// Read a file into a malloc'd buffer. Returns size via *out_size, or NULL on error.
static unsigned char* read_file(const char* path, long* out_size) {
    FILE* f = fopen(path, "rb");
    if (!f) return NULL;
    fseek(f, 0, SEEK_END);
    long sz = ftell(f);
    fseek(f, 0, SEEK_SET);
    unsigned char* buf = (unsigned char*)malloc(sz);
    if (!buf) { fclose(f); return NULL; }
    if (fread(buf, 1, sz, f) != (size_t)sz) { free(buf); fclose(f); return NULL; }
    fclose(f);
    *out_size = sz;
    return buf;
}

// Try to load IBL lighting from extracted DDS files.
// Looks for _assets/Diffuse.dds and _assets/Specular.dds relative to
// the picogkffi package directory, or via the PICOGK_ASSETS env var.
// Returns 1 if loaded, 0 if not.
static int load_ibl_lighting(void* viewer) {
    const char* env_assets = getenv("PICOGK_ASSETS");
    char diffuse_path[4096];
    char specular_path[4096];

    if (env_assets) {
        snprintf(diffuse_path, sizeof(diffuse_path), "%s/Diffuse.dds", env_assets);
        snprintf(specular_path, sizeof(specular_path), "%s/Specular.dds", env_assets);
    } else {
        // Default: look relative to the executable / current directory
        const char* base = "_assets";
        snprintf(diffuse_path, sizeof(diffuse_path), "%s/Diffuse.dds", base);
        snprintf(specular_path, sizeof(specular_path), "%s/Specular.dds", base);
    }

    long diffuse_size = 0, specular_size = 0;
    unsigned char* diffuse = read_file(diffuse_path, &diffuse_size);
    unsigned char* specular = read_file(specular_path, &specular_size);

    if (diffuse && specular && diffuse_size > 0 && specular_size > 0) {
        bool ok = Viewer_bLoadLightSetup(viewer,
            (const char*)diffuse, (int32_t)diffuse_size,
            (const char*)specular, (int32_t)specular_size);
        free(diffuse);
        free(specular);
        return ok ? 1 : 0;
    }
    free(diffuse);
    free(specular);
    return 0;
}

// Create a viewer with full callbacks and a default camera.
// Camera params are passed via a struct to avoid exceeding float register count on ARM64.
void* mbt_viewer_create(const char* title, float width, float height,
                         const float* cam_params  // [target_x, target_y, target_z, radius, azimuth, elevation, zoom, bg_r, bg_g, bg_b, bg_a]
                         ) {
    // Set up camera from params array
    memset(&g_cam, 0, sizeof(g_cam));
    g_cam.target[0] = cam_params[0];
    g_cam.target[1] = cam_params[1];
    g_cam.target[2] = cam_params[2];
    g_cam.radius = cam_params[3];
    g_cam.azimuth = cam_params[4];
    g_cam.elevation = cam_params[5];
    g_cam.zoom = cam_params[6];
    g_cam.autofit = 1;
    g_cam.drag_button = -1;
    g_cam.bg_r = cam_params[7];
    g_cam.bg_g = cam_params[8];
    g_cam.bg_b = cam_params[9];
    g_cam.bg_a = cam_params[10];

    PKVector2 size = {width, height};
    void* v = Viewer_hCreate(title, &size,
        mbt_info_cb, mbt_update_cb, mbt_key_cb,
        mbt_mouse_move_cb, mbt_mouse_button_cb, mbt_scroll_cb, mbt_window_size_cb);
    g_active_viewer = v;

    // Load IBL lighting if available (essential for PBR rendering)
    if (v) {
        load_ibl_lighting(v);
    }

    return v;
}

// Set camera autofit off and fit to the current scene bounding box.
void mbt_viewer_autofit(void* viewer) {
    PKBBox3 bbox;
    Viewer_GetBoundingBox(viewer, &bbox);
    float cx = (bbox.vecMin.X + bbox.vecMax.X) * 0.5f;
    float cy = (bbox.vecMin.Y + bbox.vecMax.Y) * 0.5f;
    float cz = (bbox.vecMin.Z + bbox.vecMax.Z) * 0.5f;
    g_cam.target[0] = cx;
    g_cam.target[1] = cy;
    g_cam.target[2] = cz;
    float dx = bbox.vecMax.X - bbox.vecMin.X;
    float dy = bbox.vecMax.Y - bbox.vecMin.Y;
    float dz = bbox.vecMax.Z - bbox.vecMin.Z;
    float r = sqrtf(dx*dx + dy*dy + dz*dz) * 0.5f;
    if (r > 0) g_cam.radius = r;
    g_cam.autofit = 0;
}

// Take a screenshot (warm-up frames + screenshot + conversion to PNG).
// This is declared in picogk_png.c but we forward-declare it here.
extern int picogk_screenshot_png(void* viewer, const char* png_path, int frames);

int mbt_viewer_screenshot_png(void* viewer, const char* png_path, int frames) {
    // Use picogk_screenshot_png which does warm-up + screenshot + TGA→PNG conversion
    return picogk_screenshot_png(viewer, png_path, frames);
}

// Add voxels to the viewer at a group.
void mbt_viewer_add_voxels(void* viewer, int group, uint64_t instance, uint64_t vox) {
    Viewer_AddVoxels(instance, viewer, group, vox);
}

// Set group material.
void mbt_viewer_set_group_material(void* viewer, int group,
                                     float r, float g, float b, float a,
                                     float metallic, float roughness) {
    PKColorFloat c = {r, g, b, a};
    Viewer_SetGroupMaterial(viewer, group, &c, metallic, roughness);
}

// Request close and destroy.
void mbt_viewer_close(void* viewer) {
    Viewer_RequestClose(viewer);
    Viewer_Destroy(viewer);
}