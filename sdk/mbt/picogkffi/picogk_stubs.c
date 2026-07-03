#include <stdlib.h>
#include <dlfcn.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include "picogk_stubs.h"

// Minimal PKVector3 definition (packed, 12 bytes)
typedef struct { float x, y, z; } PKVec3;

static void* g_lib = NULL;
static uint64_t g_instance = 0;

// Function pointer types matching the real PicoGK C API
typedef void (*fn_library_get_version)(char*);
typedef uint64_t (*fn_library_hcreate)(float);
typedef void (*fn_library_destroy)(uint64_t);
typedef int64_t (*fn_library_mem)(uint64_t);
typedef uint64_t (*fn_voxels_hcreate)(uint64_t);
typedef uint64_t (*fn_voxels_sphere)(uint64_t, const PKVec3*, float);
typedef void (*fn_voxels_destroy)(uint64_t, uint64_t);
typedef void (*fn_voxels_bool)(uint64_t, uint64_t, uint64_t);
typedef void (*fn_voxels_offset)(uint64_t, uint64_t, float);
typedef float (*fn_voxels_volume)(uint64_t, uint64_t);
typedef bool (*fn_voxels_isempty)(uint64_t, uint64_t);
typedef uint64_t (*fn_voxels_copy)(uint64_t, uint64_t);
typedef uint64_t (*fn_mesh_fromvox)(uint64_t, uint64_t);
typedef void (*fn_mesh_destroy)(uint64_t, uint64_t);
typedef int32_t (*fn_mesh_vcount)(uint64_t, uint64_t);
typedef int32_t (*fn_mesh_tcount)(uint64_t, uint64_t);
typedef uint64_t (*fn_lattice_hcreate)(uint64_t);
typedef void (*fn_lattice_sphere)(uint64_t, uint64_t, const PKVec3*, float);
typedef void (*fn_lattice_beam)(uint64_t, uint64_t, const PKVec3*, const PKVec3*, float, float, bool);
typedef void (*fn_lattice_destroy)(uint64_t, uint64_t);
typedef void (*fn_voxels_render_lattice)(uint64_t, uint64_t, uint64_t);

// Cached function pointers
static fn_library_get_version p_get_version;
static fn_library_hcreate p_hcreate_inst;
static fn_library_destroy p_destroy_inst;
static fn_library_mem p_mem_usage;
static fn_voxels_hcreate p_vox_hcreate;
static fn_voxels_sphere p_vox_sphere;
static fn_voxels_destroy p_vox_destroy;
static fn_voxels_bool p_vox_add, p_vox_sub, p_vox_intersect;
static fn_voxels_offset p_vox_offset;
static fn_voxels_volume p_vox_volume;
static fn_voxels_isempty p_vox_isempty;
static fn_voxels_copy p_vox_copy;
static fn_mesh_fromvox p_mesh_fromvox;
static fn_mesh_destroy p_mesh_destroy;
static fn_mesh_vcount p_mesh_vcount;
static fn_mesh_tcount p_mesh_tcount;
static fn_lattice_hcreate p_lat_hcreate;
static fn_lattice_sphere p_lat_sphere;
static fn_lattice_beam p_lat_beam;
static fn_lattice_destroy p_lat_destroy;
static fn_voxels_render_lattice p_render_lat;

#define SYM(name) dlsym(g_lib, name)

int mbt_init(const char* lib_path, float voxel_size) {
    g_lib = dlopen(lib_path, RTLD_NOW | RTLD_GLOBAL);
    if (!g_lib) return -1;
    p_get_version = SYM("Library_GetVersion");
    p_hcreate_inst = SYM("Library_hCreateInstance");
    p_destroy_inst = SYM("Library_DestroyInstance");
    p_mem_usage = SYM("Library_nTotalMemUsage");
    p_vox_hcreate = SYM("Voxels_hCreate");
    p_vox_sphere = SYM("Voxels_hCreateSphere");
    p_vox_destroy = SYM("Voxels_Destroy");
    p_vox_add = SYM("Voxels_BoolAdd");
    p_vox_sub = SYM("Voxels_BoolSubtract");
    p_vox_intersect = SYM("Voxels_BoolIntersect");
    p_vox_offset = SYM("Voxels_Offset");
    p_vox_volume = SYM("Voxels_fCalculateVolume");
    p_vox_isempty = SYM("Voxels_bIsEmpty");
    p_vox_copy = SYM("Voxels_hCreateCopy");
    p_mesh_fromvox = SYM("Mesh_hCreateFromVoxels");
    p_mesh_destroy = SYM("Mesh_Destroy");
    p_mesh_vcount = SYM("Mesh_nVertexCount");
    p_mesh_tcount = SYM("Mesh_nTriangleCount");
    p_lat_hcreate = SYM("Lattice_hCreate");
    p_lat_sphere = SYM("Lattice_AddSphere");
    p_lat_beam = SYM("Lattice_AddBeam");
    p_lat_destroy = SYM("Lattice_Destroy");
    p_render_lat = SYM("Voxels_RenderLattice");
    if (!p_hcreate_inst || !p_vox_hcreate || !p_vox_sphere) return -2;
    g_instance = p_hcreate_inst(voxel_size);
    if (!g_instance) return -3;
    return 0;
}

void mbt_shutdown(void) {
    if (g_instance) { p_destroy_inst(g_instance); g_instance = 0; }
    if (g_lib) { dlclose(g_lib); g_lib = NULL; }
}

void mbt_library_get_version(char* buf) { p_get_version(buf); }
int64_t mbt_library_total_mem_usage(void) { return p_mem_usage(g_instance); }

uint64_t mbt_voxels_hcreate(void) { return p_vox_hcreate(g_instance); }
uint64_t mbt_voxels_hcreate_sphere(float x, float y, float z, float r) {
    PKVec3 c = {x, y, z};
    return p_vox_sphere(g_instance, &c, r);
}
void mbt_voxels_destroy(uint64_t v) { p_vox_destroy(g_instance, v); }
void mbt_voxels_bool_add(uint64_t d, uint64_t s) { p_vox_add(g_instance, d, s); }
void mbt_voxels_bool_subtract(uint64_t d, uint64_t s) { p_vox_sub(g_instance, d, s); }
void mbt_voxels_bool_intersect(uint64_t d, uint64_t s) { p_vox_intersect(g_instance, d, s); }
void mbt_voxels_offset(uint64_t v, float d) { p_vox_offset(g_instance, v, d); }
float mbt_voxels_volume(uint64_t v) { return p_vox_volume(g_instance, v); }
bool mbt_voxels_is_empty(uint64_t v) { return p_vox_isempty(g_instance, v); }
uint64_t mbt_voxels_hcreate_copy(uint64_t s) { return p_vox_copy(g_instance, s); }

uint64_t mbt_mesh_hcreate_from_voxels(uint64_t v) { return p_mesh_fromvox(g_instance, v); }
void mbt_mesh_destroy(uint64_t m) { p_mesh_destroy(g_instance, m); }
int32_t mbt_mesh_vertex_count(uint64_t m) { return p_mesh_vcount(g_instance, m); }
int32_t mbt_mesh_triangle_count(uint64_t m) { return p_mesh_tcount(g_instance, m); }

uint64_t mbt_lattice_hcreate(void) { return p_lat_hcreate(g_instance); }
void mbt_lattice_add_sphere(uint64_t lat, float x, float y, float z, float r) {
    PKVec3 c = {x, y, z};
    p_lat_sphere(g_instance, lat, &c, r);
}
void mbt_lattice_add_beam(uint64_t lat, float x1, float y1, float z1, float r1,
                          float x2, float y2, float z2, float r2, bool rc) {
    PKVec3 a = {x1, y1, z1}, b = {x2, y2, z2};
    p_lat_beam(g_instance, lat, &a, &b, r1, r2, rc);
}
uint64_t mbt_lattice_to_voxels(uint64_t lat) {
    uint64_t vox = p_vox_hcreate(g_instance);
    p_render_lat(g_instance, vox, lat);
    return vox;
}
void mbt_lattice_destroy(uint64_t lat) { p_lat_destroy(g_instance, lat); }
