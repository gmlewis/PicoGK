package picogkshapes

import (
	"math"

	"github.com/gmlewis/PicoGK/sdk/go/picogkffi"
)

// RainbowSpectrum returns blue→green→yellow→orange→red control colors.
func RainbowSpectrum() []RGB {
	return []RGB{
		{0.0, 0.0, 1.0},
		{0.0, 1.0, 0.0},
		{1.0, 1.0, 0.0},
		{1.0, 130.0 / 255.0, 0.0},
		{1.0, 0.0, 0.0},
	}
}

// ColorScale3D maps a value through a smooth multi-colour spectrum.
type ColorScale3D struct {
	rgb      []RGB
	MinValue float64
	MaxValue float64
}

// NewColorScale3D creates a color scale from a spectrum of control colors.
func NewColorScale3D(spectrum []RGB, minValue, maxValue float64) *ColorScale3D {
	// Simple linear interpolation between control colors (no NURB smoothing yet)
	n := 500
	rgb := make([]RGB, n)
	nc := len(spectrum)
	for i := 0; i < n; i++ {
		t := float64(i) / float64(n-1)
		idx := t * float64(nc-1)
		lo := int(idx)
		if lo >= nc-1 {
			lo = nc - 2
		}
		frac := idx - float64(lo)
		c1, c2 := spectrum[lo], spectrum[lo+1]
		rgb[i] = RGB{
			c1.R + frac*(c2.R-c1.R),
			c1.G + frac*(c2.G-c1.G),
			c1.B + frac*(c2.B-c1.B),
		}
	}
	return &ColorScale3D{rgb: rgb, MinValue: minValue, MaxValue: maxValue}
}

// Color returns the RGB color for a given value.
func (cs *ColorScale3D) Color(value float64) RGB {
	v := value
	if v < cs.MinValue {
		v = cs.MinValue
	}
	if v > cs.MaxValue {
		v = cs.MaxValue
	}
	ratio := (v - cs.MinValue) / (cs.MaxValue - cs.MinValue)
	idx := int(ratio * float64(len(cs.rgb)-1))
	if idx < 0 {
		idx = 0
	}
	if idx >= len(cs.rgb) {
		idx = len(cs.rgb) - 1
	}
	c := cs.rgb[idx]
	return RGB{clamp(c.R, 0, 1), clamp(c.G, 0, 1), clamp(c.B, 0, 1)}
}

// SplitByOverhangAngle splits a mesh into colored sub-meshes by triangle
// overhang angle (degrees: 0 = vertical wall, 90 = horizontal).
// Returns (sub-mesh voxels, color) pairs.
func SplitByOverhangAngle(mesh *picogkffi.Mesh, scale *ColorScale3D, nClasses int) []SceneGroup {
	verts := mesh.Vertices()
	tris := mesh.Triangles()
	nt := len(tris) / 3

	// Compute per-triangle overhang angle
	angles := make([]float64, nt)
	for i := 0; i < nt; i++ {
		a := tris[i*3] * 3
		b := tris[i*3+1] * 3
		c := tris[i*3+2] * 3
		// Vertices
		ax, ay, az := float64(verts[a]), float64(verts[a+1]), float64(verts[a+2])
		bx, by, bz := float64(verts[b]), float64(verts[b+1]), float64(verts[b+2])
		cx, cy, cz := float64(verts[c]), float64(verts[c+1]), float64(verts[c+2])
		// Normal = cross(a-b, c-b)
		nx := (ay-by)*(cz-bz) - (az-bz)*(cy-by)
		ny := (az-bz)*(cx-bx) - (ax-bx)*(cz-bz)
		nz := (ax-bx)*(cy-by) - (ay-by)*(cx-bx)
		nlen := math.Sqrt(nx*nx + ny*ny + nz*nz)
		if nlen > 0 {
			nx /= nlen
			ny /= nlen
			nz /= nlen
		}
		dr := math.Hypot(nx, ny)
		dz := math.Abs(nz)
		angle := math.Atan2(dz, dr) * 180 / math.Pi
		if angle > 90 {
			angle = 90
		}
		if angle < 0 {
			angle = 0
		}
		angles[i] = angle
	}

	// Group by angle class
	lo, hi := scale.MinValue, scale.MaxValue
	var groups []SceneGroup
	for k := 0; k < nClasses; k++ {
		loK := lo + float64(k)*(hi-lo)/float64(nClasses-1)
		hiK := lo + float64(k+1)*(hi-lo)/float64(nClasses-1)
		var subVerts []float32
		var subTris []int32
		for i := 0; i < nt; i++ {
			if angles[i] >= loK && (angles[i] < hiK || k == nClasses-1) {
				a := tris[i*3] * 3
				b := tris[i*3+1] * 3
				c := tris[i*3+2] * 3
				idx := int32(len(subVerts) / 3)
				subVerts = append(subVerts, verts[a], verts[a+1], verts[a+2])
				subVerts = append(subVerts, verts[b], verts[b+1], verts[b+2])
				subVerts = append(subVerts, verts[c], verts[c+1], verts[c+2])
				subTris = append(subTris, idx, idx+1, idx+2)
			}
		}
		if len(subTris) > 0 {
			subMesh := picogkffi.MeshFromArrays(subVerts, subTris)
			subVox := picogkffi.FromMesh(subMesh)
			subMesh.Destroy()
			color := scale.Color(loK)
			groups = append(groups, SceneGroup{Voxels: subVox, Color: color})
		}
	}
	return groups
}

// SceneGroup is one (voxels, color) pair for rendering.
type SceneGroup struct {
	Voxels *picogkffi.Voxels
	Color  RGB
}
