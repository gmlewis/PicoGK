package picogkffi

/*
#include <stdlib.h>
#include "picogk_ffi.h"
*/
import "C"

// Mesh is a triangle mesh.
type Mesh struct {
	h C.PKMESH
}

// NewMesh creates an empty mesh.
func NewMesh() *Mesh {
	mustInit()
	return &Mesh{h: C.Mesh_hCreate(instance)}
}

// FromVoxels creates a mesh from a voxel field (marching cubes).
func MeshFromVoxels(v *Voxels) *Mesh {
	mustInit()
	return &Mesh{h: C.Mesh_hCreateFromVoxels(instance, v.h)}
}

// FromArrays creates a mesh from vertex and triangle arrays.
// vertices is (N,3) float32; triangles is (M,3) int32.
func MeshFromArrays(vertices []float32, triangles []int32) *Mesh {
	m := NewMesh()
	for i := 0; i+2 < len(vertices); i += 3 {
		v := C.PKVector3{X: C.float(vertices[i]), Y: C.float(vertices[i+1]), Z: C.float(vertices[i+2])}
		C.Mesh_nAddVertex(instance, m.h, &v)
	}
	for i := 0; i+2 < len(triangles); i += 3 {
		t := C.PKTriangle{A: C.int32_t(triangles[i]), B: C.int32_t(triangles[i+1]), C: C.int32_t(triangles[i+2])}
		C.Mesh_nAddTriangle(instance, m.h, &t)
	}
	return m
}

// Destroy frees the native mesh handle.
func (m *Mesh) Destroy() {
	if m.h != 0 {
		C.Mesh_Destroy(instance, m.h)
		m.h = 0
	}
}

// IsValid returns true if the handle is valid.
func (m *Mesh) IsValid() bool {
	return m.h != 0 && bool(C.Mesh_bIsValid(instance, m.h))
}

// MemUsage returns memory in bytes.
func (m *Mesh) MemUsage() int64 {
	return int64(C.Mesh_nMemUsage(instance, m.h))
}

// VertexCount returns the number of vertices.
func (m *Mesh) VertexCount() int32 {
	return int32(C.Mesh_nVertexCount(instance, m.h))
}

// TriangleCount returns the number of triangles.
func (m *Mesh) TriangleCount() int32 {
	return int32(C.Mesh_nTriangleCount(instance, m.h))
}

// AddVertex adds a vertex and returns its index.
func (m *Mesh) AddVertex(pt Vec3) int32 {
	c := pt.toC()
	return int32(C.Mesh_nAddVertex(instance, m.h, &c))
}

// AddTriangle adds a triangle by vertex indices and returns its index.
func (m *Mesh) AddTriangle(a, b, c int32) int32 {
	t := C.PKTriangle{A: C.int32_t(a), B: C.int32_t(b), C: C.int32_t(c)}
	return int32(C.Mesh_nAddTriangle(instance, m.h, &t))
}

// GetVertex returns the vertex at the given index.
func (m *Mesh) GetVertex(index int32) Vec3 {
	var out C.PKVector3
	C.Mesh_GetVertex(instance, m.h, C.int32_t(index), &out)
	return vec3FromC(out)
}

// GetTriangle returns the triangle at the given index.
func (m *Mesh) GetTriangle(index int32) Triangle {
	var out C.PKTriangle
	C.Mesh_GetTriangle(instance, m.h, C.int32_t(index), &out)
	return Triangle{A: int32(out.A), B: int32(out.B), C: int32(out.C)}
}

// BoundingBox returns the mesh bounding box.
func (m *Mesh) BoundingBox() BBox3 {
	var out C.PKBBox3
	C.Mesh_GetBoundingBox(instance, m.h, &out)
	return bboxFromC(out)
}

// Vertices returns all vertices as a flat (N*3) float32 slice.
func (m *Mesh) Vertices() []float32 {
	n := int(m.VertexCount())
	result := make([]float32, n*3)
	for i := 0; i < n; i++ {
		v := m.GetVertex(int32(i))
		result[i*3] = v.X
		result[i*3+1] = v.Y
		result[i*3+2] = v.Z
	}
	return result
}

// Triangles returns all triangles as a flat (M*3) int32 slice.
func (m *Mesh) Triangles() []int32 {
	n := int(m.TriangleCount())
	result := make([]int32, n*3)
	for i := 0; i < n; i++ {
		t := m.GetTriangle(int32(i))
		result[i*3] = t.A
		result[i*3+1] = t.B
		result[i*3+2] = t.C
	}
	return result
}
