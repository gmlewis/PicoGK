package picogkshapes

import (
	"github.com/gmlewis/PicoGK/sdk/go/picogkffi"
)

// VertexTransform is a point-wise vertex transform function.
type VertexTransform func(pts []Vec3) []Vec3

// BaseShape is the base for all parametric shapes.
type BaseShape struct {
	transform VertexTransform
}

// SetTransform sets the vertex transform.
func (b *BaseShape) SetTransform(t VertexTransform) {
	b.transform = t
}

// ApplyTransform applies the vertex transform to a point array.
func (b *BaseShape) ApplyTransform(pts []Vec3) []Vec3 {
	if b.transform == nil {
		return pts
	}
	return b.transform(pts)
}

// ToVoxels converts a mesh to voxels via the FFI binding.
func ToVoxels(mesh *picogkffi.Mesh) *picogkffi.Voxels {
	return picogkffi.FromMesh(mesh)
}

// QuadGridToMesh triangulates an (A,B,3) grid into a Mesh.
// Two triangles per cell: (p0,p1,p2) and (p0,p2,p3).
// Vertices emitted per-triangle (no dedup — rasteriser doesn't care).
func QuadGridToMesh(grid [][]Vec3) *picogkffi.Mesh {
	var verts []float32
	var tris []int32
	a := len(grid)
	if a < 2 {
		return picogkffi.NewMesh()
	}
	b := len(grid[0])
	if b < 2 {
		return picogkffi.NewMesh()
	}
	for i := range a - 1 {
		for j := range b - 1 {
			p0 := grid[i][j]
			p1 := grid[i+1][j]
			p2 := grid[i+1][j+1]
			p3 := grid[i][j+1]
			// Triangle 1: p0, p1, p2
			idx := int32(len(verts) / 3)
			verts = appendVert(verts, p0)
			verts = appendVert(verts, p1)
			verts = appendVert(verts, p2)
			tris = append(tris, idx, idx+1, idx+2)
			// Triangle 2: p0, p2, p3
			idx = int32(len(verts) / 3)
			verts = appendVert(verts, p0)
			verts = appendVert(verts, p2)
			verts = appendVert(verts, p3)
			tris = append(tris, idx, idx+1, idx+2)
		}
	}
	return picogkffi.MeshFromArrays(verts, tris)
}

// SurfaceMeshBuilder accumulates multiple quad-grid surface patches.
type SurfaceMeshBuilder struct {
	verts []float32
	tris  []int32
}

// NewSurfaceMeshBuilder creates a new builder.
func NewSurfaceMeshBuilder() *SurfaceMeshBuilder {
	return &SurfaceMeshBuilder{}
}

// Add triangulates a grid with optional winding flip.
// Corner order: p0=g[i,j], p1=g[i,j+1], p2=g[i+1,j+1], p3=g[i,j+1]
// (matches Python picogk.shapes._base.SurfaceMeshBuilder)
func (smb *SurfaceMeshBuilder) Add(grid [][]Vec3, flip bool) *SurfaceMeshBuilder {
	a := len(grid)
	if a < 2 {
		return smb
	}
	b := len(grid[0])
	if b < 2 {
		return smb
	}
	for i := range a - 1 {
		for j := range b - 1 {
			p0 := grid[i][j]
			p1 := grid[i][j+1]
			p2 := grid[i+1][j+1]
			p3 := grid[i+1][j]
			if flip {
				// Reversed winding
				idx := int32(len(smb.verts) / 3)
				smb.verts = appendVert(smb.verts, p0)
				smb.verts = appendVert(smb.verts, p2)
				smb.verts = appendVert(smb.verts, p1)
				smb.tris = append(smb.tris, idx, idx+1, idx+2)

				idx = int32(len(smb.verts) / 3)
				smb.verts = appendVert(smb.verts, p0)
				smb.verts = appendVert(smb.verts, p3)
				smb.verts = appendVert(smb.verts, p2)
				smb.tris = append(smb.tris, idx, idx+1, idx+2)
			} else {
				idx := int32(len(smb.verts) / 3)
				smb.verts = appendVert(smb.verts, p0)
				smb.verts = appendVert(smb.verts, p1)
				smb.verts = appendVert(smb.verts, p2)
				smb.tris = append(smb.tris, idx, idx+1, idx+2)

				idx = int32(len(smb.verts) / 3)
				smb.verts = appendVert(smb.verts, p0)
				smb.verts = appendVert(smb.verts, p2)
				smb.verts = appendVert(smb.verts, p3)
				smb.tris = append(smb.tris, idx, idx+1, idx+2)
			}
		}
	}
	return smb
}

// Build creates a Mesh from accumulated patches.
func (smb *SurfaceMeshBuilder) Build() *picogkffi.Mesh {
	if len(smb.verts) == 0 {
		return picogkffi.NewMesh()
	}
	return picogkffi.MeshFromArrays(smb.verts, smb.tris)
}

// appendVert appends a Vec3 as 3 float32 values to the verts slice.
func appendVert(verts []float32, v Vec3) []float32 {
	return append(verts, float32(v.X), float32(v.Y), float32(v.Z))
}

// makeGrid creates an (A, B) grid of Vec3.
func makeGrid(a, b int) [][]Vec3 {
	grid := make([][]Vec3, a)
	for i := range grid {
		grid[i] = make([]Vec3, b)
	}
	return grid
}

// arange returns n equally-spaced values from 0 to 1 (inclusive).
func arange(n int) []float64 {
	result := make([]float64, n)
	for i := range n {
		result[i] = float64(i) / float64(n-1)
	}
	return result
}
