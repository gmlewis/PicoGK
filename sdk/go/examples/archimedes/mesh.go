package main

import (
	"errors"
	"math"
)

// MeshData is a triangle mesh in millimetres. Triangles are counter-clockwise
// when viewed from outside the solid.
type MeshData struct {
	Vertices  []float32 // x,y,z per vertex
	Triangles []int32   // three vertex indices per triangle
}

// VertexCount returns the number of vertices.
func (m *MeshData) VertexCount() int { return len(m.Vertices) / 3 }

// TriangleCount returns the number of triangles.
func (m *MeshData) TriangleCount() int { return len(m.Triangles) / 3 }

func (m *MeshData) addVertex(p Vec3) int32 {
	m.Vertices = append(m.Vertices, float32(p.X), float32(p.Y), float32(p.Z))
	return int32(len(m.Vertices)/3 - 1)
}

func (m *MeshData) addTriangle(a, b, c int32) {
	m.Triangles = append(m.Triangles, a, b, c)
}

func (m *MeshData) vertex(i int32) Vec3 {
	return Vec3{
		float64(m.Vertices[i*3]),
		float64(m.Vertices[i*3+1]),
		float64(m.Vertices[i*3+2]),
	}
}

// RotorMesh builds a closed, thickness-bearing triangle mesh of all blades.
// Each blade is a ruled surface S(u,v) offset along its normal by half the
// local Config.BladeThicknessAt(u), with side walls closing the four boundary
// edges. The blade therefore tapers from the base to the top. Blades
// are copies rotated about the Z axis by 2*pi*blade/BladeCount.
func (c Config) RotorMesh() (*MeshData, error) {
	if err := c.Validate(); err != nil {
		return nil, err
	}

	md := &MeshData{}
	for blade := 0; blade < c.BladeCount; blade++ {
		phi := 2 * math.Pi * float64(blade) / float64(c.BladeCount)
		first := len(md.Triangles)
		c.appendBlade(md, phi)
		// Guard against a mis-ordered patch: a closed shell built with
		// outward normals has positive signed volume.
		if signedVolume(md, first) < 0 {
			for i := first; i+2 < len(md.Triangles); i += 3 {
				md.Triangles[i+1], md.Triangles[i+2] = md.Triangles[i+2], md.Triangles[i+1]
			}
		}
	}

	for _, f := range md.Vertices {
		f64 := float64(f)
		if math.IsNaN(f64) || math.IsInf(f64, 0) {
			return nil, errors.New("archimedes: rotor mesh contains a non-finite vertex")
		}
	}
	return md, nil
}

// appendBlade appends one closed blade shell rotated about Z by phi.
func (c Config) appendBlade(md *MeshData, phi float64) {
	// The surface normal changes across v, so sample v as well as u.
	const nv = 8

	nu := c.Samples
	uMax := c.bladeSpan()

	top := make([][]int32, nu+1)
	bot := make([][]int32, nu+1)
	for i := 0; i <= nu; i++ {
		u := uMax * float64(i) / float64(nu)
		half := c.BladeThicknessAt(u) / 2
		top[i] = make([]int32, nv+1)
		bot[i] = make([]int32, nv+1)
		for j := 0; j <= nv; j++ {
			v := float64(j) / float64(nv)
			p := c.SurfacePoint(u, v)
			normal := c.SurfaceNormal(u, v)
			top[i][j] = md.addVertex(p.Add(normal.Scale(half)).RotateZ(phi))
			bot[i][j] = md.addVertex(p.Sub(normal.Scale(half)).RotateZ(phi))
		}
	}

	// Two offset sheets. The top sheet faces +normal, the bottom -normal.
	for i := 0; i < nu; i++ {
		for j := 0; j < nv; j++ {
			md.addTriangle(top[i][j], top[i+1][j], top[i+1][j+1])
			md.addTriangle(top[i][j], top[i+1][j+1], top[i][j+1])
			md.addTriangle(bot[i][j], bot[i+1][j+1], bot[i+1][j])
			md.addTriangle(bot[i][j], bot[i][j+1], bot[i+1][j+1])
		}
	}

	// Boundary of the (u,v) rectangle, counter-clockwise as seen from the
	// +normal side: inner edge, u=uMax edge, outer edge, u=0 edge.
	type edge struct{ top, bot int32 }
	var loop []edge
	add := func(i, j int) { loop = append(loop, edge{top[i][j], bot[i][j]}) }
	for i := 0; i <= nu; i++ {
		add(i, 0)
	}
	for j := 1; j <= nv; j++ {
		add(nu, j)
	}
	for i := nu - 1; i >= 0; i-- {
		add(i, nv)
	}
	for j := nv - 1; j >= 1; j-- {
		add(0, j)
	}

	for k := range loop {
		next := (k + 1) % len(loop)
		t0, b0 := loop[k].top, loop[k].bot
		t1, b1 := loop[next].top, loop[next].bot
		md.addTriangle(t0, b0, b1)
		md.addTriangle(t0, b1, t1)
	}
}

// signedVolume returns the signed volume of the triangles starting at index
// first, treating them as a closed shell.
func signedVolume(md *MeshData, first int) float64 {
	var vol float64
	for i := first; i+2 < len(md.Triangles); i += 3 {
		a := md.vertex(md.Triangles[i])
		b := md.vertex(md.Triangles[i+1])
		c := md.vertex(md.Triangles[i+2])
		vol += a.Dot(b.Cross(c)) / 6
	}
	return vol
}
