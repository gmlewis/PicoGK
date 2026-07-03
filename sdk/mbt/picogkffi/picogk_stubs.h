#ifndef PICOGK_STUBS_H
#define PICOGK_STUBS_H

#include <stdint.h>
#include <stdbool.h>

// dlopen-based init
int mbt_init(const char* lib_path, float voxel_size);
void mbt_shutdown(void);

// Library
void mbt_library_get_version(char* buf);
int64_t mbt_library_total_mem_usage(void);

// Voxels (instance is internal to the stub)
uint64_t mbt_voxels_hcreate(void);
uint64_t mbt_voxels_hcreate_sphere(float x, float y, float z, float radius);
void mbt_voxels_destroy(uint64_t vox);
void mbt_voxels_bool_add(uint64_t dst, uint64_t src);
void mbt_voxels_bool_subtract(uint64_t dst, uint64_t src);
void mbt_voxels_bool_intersect(uint64_t dst, uint64_t src);
void mbt_voxels_offset(uint64_t vox, float dist);
float mbt_voxels_volume(uint64_t vox);
bool mbt_voxels_is_empty(uint64_t vox);
uint64_t mbt_voxels_hcreate_copy(uint64_t src);

// Mesh
uint64_t mbt_mesh_hcreate_from_voxels(uint64_t vox);
void mbt_mesh_destroy(uint64_t mesh);
int32_t mbt_mesh_vertex_count(uint64_t mesh);
int32_t mbt_mesh_triangle_count(uint64_t mesh);

// Lattice
uint64_t mbt_lattice_hcreate(void);
void mbt_lattice_add_sphere(uint64_t lat, float x, float y, float z, float radius);
void mbt_lattice_add_beam(uint64_t lat, float x1, float y1, float z1, float r1, float x2, float y2, float z2, float r2, bool round_cap);
uint64_t mbt_lattice_to_voxels(uint64_t lat);
void mbt_lattice_destroy(uint64_t lat);

#endif
