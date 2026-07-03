// SDF (signed distance function) implementations for implicit rendering.
// These are C-side SDF callbacks that can be passed directly to
// Voxels_RenderImplicit / Voxels_IntersectImplicit.
// This avoids the need for C->MoonBit callbacks (which MoonBit's native
// backend does not support cleanly) by implementing the specific SDFs
// used by the examples directly in C.

#include "picogk_ffi.h"
#include <math.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

// --- Global SDF parameters (set before calling render) ---
// This is a simple approach: set globals before calling render_implicit.
// Only one SDF can be active at a time (same as the Go single-currentSDF pattern).

static int g_sdf_type = 0;  // 0=none, 1=gyroid_sphere, 2=gyroid_genus, 3=superellipsoid
static float g_sdf_param1 = 0;
static float g_sdf_param2 = 0;
static float g_sdf_param3 = 0;
static float g_sdf_param4 = 0;
static float g_sdf_param5 = 0;
static float g_sdf_param6 = 0;
static float g_sdf_param7 = 0;

// Set the current SDF parameters for gyroid_sphere.
// param1 = radius, param2 = wall_thickness, param3 = k (frequency = 2*pi/unit_size)
void mbt_sdf_set_gyroid_sphere(float radius, float wall, float k) {
    g_sdf_type = 1;
    g_sdf_param1 = radius;
    g_sdf_param2 = wall;
    g_sdf_param3 = k;
}

// Set the current SDF parameters for gyroid_genus.
// param1 = scale, param2 = gap, param3 = k (gyroid frequency)
void mbt_sdf_set_gyroid_genus(float scale, float gap, float k) {
    g_sdf_type = 2;
    g_sdf_param1 = scale;
    g_sdf_param2 = gap;
    g_sdf_param3 = k;
}

// Set the current SDF parameters for superellipsoid.
// param1=a, param2=b, param3=c, param4=e1, param5=e2
void mbt_sdf_set_superellipsoid(float a, float b, float c, float e1, float e2) {
    g_sdf_type = 3;
    g_sdf_param1 = a;
    g_sdf_param2 = b;
    g_sdf_param3 = c;
    g_sdf_param4 = e1;
    g_sdf_param5 = e2;
}

// Set the current SDF parameters for a plain gyroid.
// param1 = wall, param2 = k
void mbt_sdf_set_gyroid(float wall, float k) {
    g_sdf_type = 4;
    g_sdf_param1 = wall;
    g_sdf_param2 = k;
}

// Set the current SDF parameters for gyroid sphere with offset.
// Like gyroid_sphere but with x/y/z offset.
void mbt_sdf_set_gyroid_sphere_offset(float radius, float wall, float k,
                                        float ox, float oy, float oz) {
    g_sdf_type = 5;
    g_sdf_param1 = radius;
    g_sdf_param2 = wall;
    g_sdf_param3 = k;
    g_sdf_param4 = ox;
    g_sdf_param5 = oy;
    g_sdf_param6 = oz;
}

// --- SDF callback functions ---

// Gyroid sphere: max(abs(gyroid) - wall, sphere_sdf)
static float sdf_gyroid_sphere(const PKVector3* p) {
    float k = g_sdf_param3;
    float g = sinf(k*p->X)*cosf(k*p->Y) +
              sinf(k*p->Y)*cosf(k*p->Z) +
              sinf(k*p->Z)*cosf(k*p->X);
    float r = g_sdf_param1;
    float wall = g_sdf_param2;
    float sphere = sqrtf(p->X*p->X + p->Y*p->Y + p->Z*p->Z) - r;
    float gyroid_val = fabsf(g) - wall;
    return fmaxf(gyroid_val, sphere);
}

// Gyroid sphere with offset
static float sdf_gyroid_sphere_offset(const PKVector3* p) {
    float k = g_sdf_param3;
    float dx = p->X - g_sdf_param4;
    float dy = p->Y - g_sdf_param5;
    float dz = p->Z - g_sdf_param6;
    float g = sinf(k*dx)*cosf(k*dy) +
              sinf(k*dy)*cosf(k*dz) +
              sinf(k*dz)*cosf(k*dx);
    float r = g_sdf_param1;
    float wall = g_sdf_param2;
    float sphere = sqrtf(dx*dx + dy*dy + dz*dz) - r;
    return fmaxf(g, sphere);
}

// Gyroid genus: max(genus_sdf/scale, gyroid_sdf)
static float sdf_gyroid_genus(const PKVector3* p) {
    float s = g_sdf_param1;
    float gap = g_sdf_param2;
    float k = g_sdf_param3;
    // Genus-2 surface: (x^2+y^2-1)^2 + z^2 - gap (scaled)
    float x = p->X / s, y = p->Y / s, z = p->Z / s;
    float r2 = x*x + y*y;
    float genus = (r2 - 1.0f)*(r2 - 1.0f) + z*z - gap;
    float g = sinf(k*p->X)*cosf(k*p->Y) +
              sinf(k*p->Y)*cosf(k*p->Z) +
              sinf(k*p->Z)*cosf(k*p->X);
    return fmaxf(genus, g);
}

// Superellipsoid: |x/a|^n1 + |y/b|^n1 + |z/c|^n2 - 1 (approximate SDF)
static float sdf_superellipsoid(const PKVector3* p) {
    float a = g_sdf_param1, b = g_sdf_param2, c = g_sdf_param3;
    float e1 = g_sdf_param4, e2 = g_sdf_param5;
    // Superellipsoid: (|x/a|^n + |y/a|^n)^m + |z/c|^m <= 1
    // where n = 2/e1, m = 2/e2
    float n = 2.0f / e1;
    float m = 2.0f / e2;
    float xa = fabsf(p->X) / a;
    float ya = fabsf(p->Y) / a;
    float za = fabsf(p->Z) / c;
    // Use powf for the general case
    float xy = powf(xa, n) + powf(ya, n);
    float val = powf(xy, m / n) + powf(za, m) - 1.0f;
    // This is not a true SDF but works for rasterization
    return val * fminf(a, fminf(b, c));  // scale to approximate distance
}

// Plain gyroid: abs(gyroid) - wall
static float sdf_gyroid(const PKVector3* p) {
    float k = g_sdf_param2;
    float wall = g_sdf_param1;
    float g = sinf(k*p->X)*cosf(k*p->Y) +
              sinf(k*p->Y)*cosf(k*p->Z) +
              sinf(k*p->Z)*cosf(k*p->X);
    return fabsf(g) - wall;
}

// Dispatch to the current SDF
static float mbt_sdf_dispatch(const PKVector3* p) {
    switch (g_sdf_type) {
        case 1: return sdf_gyroid_sphere(p);
        case 2: return sdf_gyroid_genus(p);
        case 3: return sdf_superellipsoid(p);
        case 4: return sdf_gyroid(p);
        case 5: return sdf_gyroid_sphere_offset(p);
        default: return 1e30f;  // far outside
    }
}

// --- C wrapper functions callable from MoonBit ---

// Render implicit gyroid sphere into voxels.
void mbt_render_gyroid_sphere(uint64_t instance, uint64_t vox,
                               float minX, float minY, float minZ,
                               float maxX, float maxY, float maxZ,
                               float radius, float wall, float k) {
    mbt_sdf_set_gyroid_sphere(radius, wall, k);
    PKBBox3 bbox;
    bbox.vecMin.X = minX; bbox.vecMin.Y = minY; bbox.vecMin.Z = minZ;
    bbox.vecMax.X = maxX; bbox.vecMax.Y = maxY; bbox.vecMax.Z = maxZ;
    Voxels_RenderImplicit(instance, vox, &bbox, mbt_sdf_dispatch);
}

// Render implicit gyroid sphere with offset into voxels.
void mbt_render_gyroid_sphere_offset(uint64_t instance, uint64_t vox,
                                      float minX, float minY, float minZ,
                                      float maxX, float maxY, float maxZ,
                                      float radius, float wall, float k,
                                      float ox, float oy, float oz) {
    mbt_sdf_set_gyroid_sphere_offset(radius, wall, k, ox, oy, oz);
    PKBBox3 bbox;
    bbox.vecMin.X = minX; bbox.vecMin.Y = minY; bbox.vecMin.Z = minZ;
    bbox.vecMax.X = maxX; bbox.vecMax.Y = maxY; bbox.vecMax.Z = maxZ;
    Voxels_RenderImplicit(instance, vox, &bbox, mbt_sdf_dispatch);
}

// Render implicit gyroid genus into voxels.
void mbt_render_gyroid_genus(uint64_t instance, uint64_t vox,
                              float minX, float minY, float minZ,
                              float maxX, float maxY, float maxZ,
                              float scale, float gap, float k) {
    mbt_sdf_set_gyroid_genus(scale, gap, k);
    PKBBox3 bbox;
    bbox.vecMin.X = minX; bbox.vecMin.Y = minY; bbox.vecMin.Z = minZ;
    bbox.vecMax.X = maxX; bbox.vecMax.Y = maxY; bbox.vecMax.Z = maxZ;
    Voxels_RenderImplicit(instance, vox, &bbox, mbt_sdf_dispatch);
}

// Render implicit superellipsoid into voxels.
void mbt_render_superellipsoid(uint64_t instance, uint64_t vox,
                                float minX, float minY, float minZ,
                                float maxX, float maxY, float maxZ,
                                float a, float b, float c, float e1, float e2) {
    mbt_sdf_set_superellipsoid(a, b, c, e1, e2);
    PKBBox3 bbox;
    bbox.vecMin.X = minX; bbox.vecMin.Y = minY; bbox.vecMin.Z = minZ;
    bbox.vecMax.X = maxX; bbox.vecMax.Y = maxY; bbox.vecMax.Z = maxZ;
    Voxels_RenderImplicit(instance, vox, &bbox, mbt_sdf_dispatch);
}

// Render plain gyroid into voxels.
void mbt_render_gyroid(uint64_t instance, uint64_t vox,
                        float minX, float minY, float minZ,
                        float maxX, float maxY, float maxZ,
                        float wall, float k) {
    mbt_sdf_set_gyroid(wall, k);
    PKBBox3 bbox;
    bbox.vecMin.X = minX; bbox.vecMin.Y = minY; bbox.vecMin.Z = minZ;
    bbox.vecMax.X = maxX; bbox.vecMax.Y = maxY; bbox.vecMax.Z = maxZ;
    Voxels_RenderImplicit(instance, vox, &bbox, mbt_sdf_dispatch);
}

// Intersect voxels with gyroid sphere SDF (in-place).
void mbt_intersect_gyroid_sphere(uint64_t instance, uint64_t vox,
                                  float radius, float wall, float k) {
    mbt_sdf_set_gyroid_sphere(radius, wall, k);
    Voxels_IntersectImplicit(instance, vox, mbt_sdf_dispatch);
}