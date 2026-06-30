package picogkffi

/*
#include <stdlib.h>
#include "picogk_ffi.h"
*/
import "C"

// PolyLine is a colored line strip for debug visualization.
type PolyLine struct {
	h C.PKPOLYLINE
}

// NewPolyLine creates a polyline with the given color.
func NewPolyLine(color ColorFloat) *PolyLine {
	mustInit()
	c := C.PKColorFloat{
		R: C.float(color.R), G: C.float(color.G),
		B: C.float(color.B), A: C.float(color.A),
	}
	return &PolyLine{h: C.PolyLine_hCreate(instance, &c)}
}

// IsValid returns true if the handle is valid.
func (pl *PolyLine) IsValid() bool {
	return pl.h != 0 && bool(C.PolyLine_bIsValid(instance, pl.h))
}

// Destroy frees the native polyline handle.
func (pl *PolyLine) Destroy() {
	if pl.h != 0 {
		C.PolyLine_Destroy(instance, pl.h)
		pl.h = 0
	}
}

// MemUsage returns memory in bytes.
func (pl *PolyLine) MemUsage() int64 {
	return int64(C.PolyLine_nMemUsage(instance, pl.h))
}

// AddVertex adds a vertex and returns its index.
func (pl *PolyLine) AddVertex(pt Vec3) int32 {
	c := pt.toC()
	return int32(C.PolyLine_nAddVertex(instance, pl.h, &c))
}

// VertexCount returns the number of vertices.
func (pl *PolyLine) VertexCount() int32 {
	return int32(C.PolyLine_nVertexCount(instance, pl.h))
}

// GetVertex returns the vertex at the given index.
func (pl *PolyLine) GetVertex(index int32) Vec3 {
	var out C.PKVector3
	C.PolyLine_GetVertex(instance, pl.h, C.int32_t(index), &out)
	return vec3FromC(out)
}

// GetColor returns the polyline color.
func (pl *PolyLine) GetColor() ColorFloat {
	var out C.PKColorFloat
	C.PolyLine_GetColor(instance, pl.h, &out)
	return ColorFloat{R: float32(out.R), G: float32(out.G), B: float32(out.B), A: float32(out.A)}
}

// BoundingBox returns the bounding box.
func (pl *PolyLine) BoundingBox() BBox3 {
	var out C.PKBBox3
	C.PolyLine_GetBoundingBox(instance, pl.h, &out)
	return bboxFromC(out)
}

// Vertices returns all vertices as a flat (N*3) float32 slice.
func (pl *PolyLine) Vertices() []float32 {
	n := int(pl.VertexCount())
	result := make([]float32, n*3)
	for i := 0; i < n; i++ {
		v := pl.GetVertex(int32(i))
		result[i*3] = v.X
		result[i*3+1] = v.Y
		result[i*3+2] = v.Z
	}
	return result
}

// PolyLineFromVertices creates a polyline from a flat (N*3) float32 vertex slice.
func PolyLineFromVertices(vertices []float32, color ColorFloat) *PolyLine {
	pl := NewPolyLine(color)
	for i := 0; i+2 < len(vertices); i += 3 {
		pl.AddVertex(Vec3{X: vertices[i], Y: vertices[i+1], Z: vertices[i+2]})
	}
	return pl
}
