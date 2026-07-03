// Binary STL writer for PicoGK meshes.
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <math.h>

// Write a binary STL file from vertex and triangle arrays.
// vertices: flat array of float32 (x,y,z triples)
// triangles: flat array of int32 (vertex index triples)
// Returns 0 on success, -1 on error.
int picogk_write_stl(const char* path, const float* vertices, int32_t n_verts,
                     const int32_t* triangles, int32_t n_tris) {
    FILE* f = fopen(path, "wb");
    if (!f) return -1;
    // 80-byte header (zeroed)
    uint8_t header[80] = {0};
    fwrite(header, 1, 80, f);
    // Triangle count
    fwrite(&n_tris, 4, 1, f);
    for (int32_t i = 0; i < n_tris; i++) {
        int32_t a = triangles[i * 3] * 3;
        int32_t b = triangles[i * 3 + 1] * 3;
        int32_t c = triangles[i * 3 + 2] * 3;
        // Compute normal (cross product)
        float ax = vertices[a], ay = vertices[a+1], az = vertices[a+2];
        float bx = vertices[b], by = vertices[b+1], bz = vertices[b+2];
        float cx = vertices[c], cy = vertices[c+1], cz = vertices[c+2];
        float ux = bx - ax, uy = by - ay, uz = bz - az;
        float vx = cx - ax, vy = cy - ay, vz = cz - az;
        float nx = uy * vz - uz * vy;
        float ny = uz * vx - ux * vz;
        float nz = ux * vy - uy * vx;
        float len = sqrtf(nx*nx + ny*ny + nz*nz);
        if (len > 0) { nx /= len; ny /= len; nz /= len; }
        // Normal
        fwrite(&nx, 4, 1, f);
        fwrite(&ny, 4, 1, f);
        fwrite(&nz, 4, 1, f);
        // Vertices
        fwrite(&ax, 4, 1, f); fwrite(&ay, 4, 1, f); fwrite(&az, 4, 1, f);
        fwrite(&bx, 4, 1, f); fwrite(&by, 4, 1, f); fwrite(&bz, 4, 1, f);
        fwrite(&cx, 4, 1, f); fwrite(&cy, 4, 1, f); fwrite(&cz, 4, 1, f);
        // Attribute byte count
        uint16_t attr = 0;
        fwrite(&attr, 2, 1, f);
    }
    fclose(f);
    return 0;
}