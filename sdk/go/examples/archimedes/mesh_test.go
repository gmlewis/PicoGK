package main

import (
	"encoding/binary"
	"math"
	"os"
	"path/filepath"
	"testing"
)

func TestSurfaceNormalUnit(t *testing.T) {
	c := defaultConfig()
	for _, u := range []float64{0, 0.3, math.Pi, 2 * math.Pi} {
		for _, v := range []float64{0, 0.5, 1} {
			n := c.SurfaceNormal(u, v)
			if math.Abs(n.Norm()-1) > 1e-12 {
				t.Errorf("u=%g v=%g: normal length %g", u, v, n.Norm())
			}
		}
	}
}

func TestRotorMeshClosed(t *testing.T) {
	c := defaultConfig()
	c.Samples = 24
	md, err := c.RotorMesh()
	if err != nil {
		t.Fatal(err)
	}

	edges := map[[2]int32]int{}
	for i := 0; i+2 < len(md.Triangles); i += 3 {
		a, b, d := md.Triangles[i], md.Triangles[i+1], md.Triangles[i+2]
		for _, e := range [][2]int32{{a, b}, {b, d}, {d, a}} {
			if e[0] == e[1] {
				t.Fatalf("degenerate triangle at %d", i/3)
			}
			if e[0] > e[1] {
				e[0], e[1] = e[1], e[0]
			}
			edges[e]++
		}
	}
	for e, n := range edges {
		if n != 2 {
			t.Errorf("edge %v used by %d triangles, want 2", e, n)
		}
	}
}

func TestRotorMeshVolumeAndBounds(t *testing.T) {
	c := defaultConfig()
	c.Samples = 48
	md, err := c.RotorMesh()
	if err != nil {
		t.Fatal(err)
	}

	vol := signedVolume(md, 0)
	if vol <= 0 {
		t.Fatalf("signed volume = %g, want positive", vol)
	}
	envelope := math.Pi * math.Pow(c.RotorRadius(), 2) * c.AxialLength
	if vol >= envelope {
		t.Fatalf("blade volume %g mm³ exceeds envelope %g mm³", vol, envelope)
	}

	// The base extension spirals outward past the nominal rotor radius and
	// down below the bed plane, so bound by its start plus an offset.
	maxOffset := c.MaxBladeThickness()
	lead := c.SpiralPoint(c.baseStart())
	maxR := math.Hypot(lead.X, lead.Y) + maxOffset
	zMin := lead.Z - maxOffset
	zMax := c.AxialLength/2 + maxOffset
	for i := 0; i < len(md.Vertices); i += 3 {
		x, y, z := float64(md.Vertices[i]), float64(md.Vertices[i+1]), float64(md.Vertices[i+2])
		if r := math.Hypot(x, y); r > maxR+1e-4 {
			t.Fatalf("vertex radius %g exceeds %g", r, maxR)
		}
		if z < zMin || z > zMax {
			t.Fatalf("vertex z=%g outside expected span [%g,%g]", z, zMin, zMax)
		}
	}
}

func TestRotorMeshThicknessTapers(t *testing.T) {
	c := defaultConfig()
	c.BladeCount = 1
	c.Samples = 8
	md, err := c.RotorMesh()
	if err != nil {
		t.Fatal(err)
	}

	// appendBlade stores, for each (u,v) sample, the top vertex then the
	// bottom vertex, so the pair's separation is the local blade thickness.
	// j=0 is the inner edge where all blades meet the rotor axis, so this also
	// checks that the common junction is never thinner than the minimum.
	const nv = 8
	perStation := (nv + 1) * 2
	for i, u := range c.bladeStations() {
		want := c.BladeThicknessAt(u)
		for j := 0; j <= nv; j++ {
			top := md.vertex(int32(i*perStation + j*2))
			bot := md.vertex(int32(i*perStation + j*2 + 1))
			if got := top.Sub(bot).Norm(); math.Abs(got-want) > 1e-3 {
				t.Fatalf("u=%g v=%g: thickness %g, want %g", u, float64(j)/nv, got, want)
			}
		}
	}
}

func TestRotorMeshBladeCount(t *testing.T) {
	one := defaultConfig()
	one.BladeCount = 1
	one.Samples = 16
	m1, err := one.RotorMesh()
	if err != nil {
		t.Fatal(err)
	}
	one.BladeCount = 4
	m4, err := one.RotorMesh()
	if err != nil {
		t.Fatal(err)
	}
	if got, want := m4.TriangleCount(), 4*m1.TriangleCount(); got != want {
		t.Errorf("4 blades: %d triangles, want %d", got, want)
	}
	if got, want := m4.VertexCount(), 4*m1.VertexCount(); got != want {
		t.Errorf("4 blades: %d vertices, want %d", got, want)
	}
}

func TestWriteBinarySTL(t *testing.T) {
	path := filepath.Join(t.TempDir(), "triangle.stl")
	vertices := []float32{0, 0, 0, 1, 0, 0, 0, 1, 0}
	triangles := []int32{0, 1, 2}
	if err := writeBinarySTL(path, vertices, triangles); err != nil {
		t.Fatal(err)
	}

	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if want := 84 + 50; len(data) != want {
		t.Fatalf("file size = %d, want %d", len(data), want)
	}
	if n := binary.LittleEndian.Uint32(data[80:84]); n != 1 {
		t.Fatalf("facet count = %d, want 1", n)
	}
	normal := [3]float32{
		math.Float32frombits(binary.LittleEndian.Uint32(data[84:])),
		math.Float32frombits(binary.LittleEndian.Uint32(data[88:])),
		math.Float32frombits(binary.LittleEndian.Uint32(data[92:])),
	}
	if math.Abs(float64(normal[0])) > 1e-6 || math.Abs(float64(normal[1])) > 1e-6 || math.Abs(float64(normal[2])-1) > 1e-6 {
		t.Fatalf("normal = %v, want (0,0,1)", normal)
	}
}

func TestWriteBinarySTLRejectsBadIndex(t *testing.T) {
	path := filepath.Join(t.TempDir(), "bad.stl")
	err := writeBinarySTL(path, []float32{0, 0, 0}, []int32{0, 1, 2})
	if err == nil {
		t.Fatal("expected an error for out-of-range index")
	}
}

func TestExportSolidSTL(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping PicoGK FFI export in short mode")
	}
	c := defaultConfig()
	c.Samples = 24
	c.MinBaseThickness = 3
	c.MinTopThickness = 3
	md, err := c.RotorMesh()
	if err != nil {
		t.Fatal(err)
	}

	path := filepath.Join(t.TempDir(), "rotor.stl")
	result, err := exportSolidSTL(path, md, 2, float32(c.BedZ()))
	if err != nil {
		t.Fatal(err)
	}
	if result.VolumeMM3 <= 0 || result.Triangles == 0 {
		t.Fatalf("empty solid: %+v", result)
	}

	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	nf := binary.LittleEndian.Uint32(data[80:84])
	if nf == 0 {
		t.Fatal("STL has no facets")
	}
	if got, want := len(data), 84+50*int(nf); got != want {
		t.Fatalf("file size = %d, want %d", got, want)
	}

	// The bed cut must leave a broad, perfectly flat face at the lowest z.
	minZ := math.Inf(1)
	for i := 0; i < int(nf); i++ {
		base := 84 + i*50 + 12 // skip normal
		for v := 0; v < 3; v++ {
			off := base + v*12 + 8
			z := float64(math.Float32frombits(binary.LittleEndian.Uint32(data[off:])))
			if z < minZ {
				minZ = z
			}
		}
	}
	flat := 0
	for i := 0; i < int(nf); i++ {
		base := 84 + i*50 + 12
		for v := 0; v < 3; v++ {
			off := base + v*12 + 8
			z := float64(math.Float32frombits(binary.LittleEndian.Uint32(data[off:])))
			if z <= minZ+1e-3 {
				flat++
			}
		}
	}
	if flat < 100 {
		t.Fatalf("only %d vertices at the bed plane z=%g; expected a flat contact face", flat, minZ)
	}
}
