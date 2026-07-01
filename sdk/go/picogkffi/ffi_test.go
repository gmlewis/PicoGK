package picogkffi

import (
	"math"
	"os"
	"sync"
	"testing"
)

var testOnce sync.Once

func initOnce(t *testing.T) {
	t.Helper()
	testOnce.Do(func() {
		if err := InitWithSize(0.5); err != nil {
			t.Fatalf("InitWithSize: %v", err)
		}
	})
}

func TestMain(m *testing.M) {
	os.Exit(func() int {
		defer Shutdown()
		return m.Run()
	}())
}

func approxEqual(a, b, tol float32) bool {
	return math.Abs(float64(a-b)) < float64(tol)
}

func vecApproxEqual(a, b Vec3, tol float32) bool {
	return approxEqual(a.X, b.X, tol) && approxEqual(a.Y, b.Y, tol) && approxEqual(a.Z, b.Z, tol)
}

// --- Runtime lifecycle ---

func TestInitShutdown(t *testing.T) {
	initOnce(t)
	if !IsInitialized() {
		t.Fatal("expected IsInitialized() == true after Init")
	}
}

func TestVersion(t *testing.T) {
	initOnce(t)
	v := Version()
	if v == "" {
		t.Fatal("Version() returned empty string")
	}
	t.Logf("Version: %s", v)
}

func TestName(t *testing.T) {
	initOnce(t)
	n := Name()
	if n == "" {
		t.Fatal("Name() returned empty string")
	}
	t.Logf("Name: %s", n)
}

func TestBuildInfo(t *testing.T) {
	initOnce(t)
	b := BuildInfo()
	if b == "" {
		t.Fatal("BuildInfo() returned empty string")
	}
	t.Logf("BuildInfo: %s", b)
}

func TestTotalMemoryUsage(t *testing.T) {
	initOnce(t)
	mem := TotalMemoryUsage()
	if mem < 0 {
		t.Errorf("expected non-negative TotalMemoryUsage, got %d", mem)
	}
	t.Logf("TotalMemoryUsage: %d bytes", mem)
}

func TestMemoryStats(t *testing.T) {
	initOnce(t)

	before := TotalMemoryUsage()

	s := NewSphere(Vec3{0, 0, 0}, 5.0)
	defer s.Destroy()

	after := TotalMemoryUsage()
	if after <= before {
		t.Errorf("expected memory to increase after creating sphere: before=%d, after=%d", before, after)
	}

	if VoxelsAllocated() < 1 {
		t.Error("expected at least 1 voxel allocated")
	}
	if VoxelsMemUsage() <= 0 {
		t.Error("expected positive VoxelsMemUsage")
	}

	m := NewMesh()
	defer m.Destroy()
	if MeshesAllocated() < 1 {
		t.Error("expected at least 1 mesh allocated")
	}
}

// --- Types ---

func TestVec3(t *testing.T) {
	v := Vec3{X: 1.0, Y: 2.5, Z: -3.0}
	if v.X != 1.0 || v.Y != 2.5 || v.Z != -3.0 {
		t.Errorf("Vec3 fields wrong: got %+v", v)
	}
	c := v.toC()
	back := vec3FromC(c)
	if !vecApproxEqual(v, back, 1e-6) {
		t.Errorf("Vec3 round-trip failed: original %+v, got %+v", v, back)
	}
}

func TestBBox3(t *testing.T) {
	box := BBox3{
		Min: Vec3{X: -1, Y: -2, Z: -3},
		Max: Vec3{X: 4, Y: 5, Z: 6},
	}
	if box.Min.X != -1 || box.Max.Z != 6 {
		t.Errorf("BBox3 fields wrong: %+v", box)
	}
}

func TestTriangle(t *testing.T) {
	tri := Triangle{A: 0, B: 1, C: 2}
	if tri.A != 0 || tri.B != 1 || tri.C != 2 {
		t.Errorf("Triangle fields wrong: %+v", tri)
	}
}

func TestColorFloat(t *testing.T) {
	c := ColorFloat{R: 0.1, G: 0.2, B: 0.3, A: 0.4}
	if c.R != 0.1 || c.G != 0.2 || c.B != 0.3 || c.A != 0.4 {
		t.Errorf("ColorFloat fields wrong: %+v", c)
	}
}

// --- Voxels ---

func TestNewVoxels(t *testing.T) {
	initOnce(t)
	v := NewVoxels()
	defer v.Destroy()
	if !v.IsValid() {
		t.Fatal("NewVoxels returned invalid handle")
	}
	if !v.IsEmpty() {
		t.Error("expected new empty voxels to be empty")
	}
}

func TestNewSphere(t *testing.T) {
	initOnce(t)
	s := NewSphere(Vec3{0, 0, 0}, 10.0)
	defer s.Destroy()
	if !s.IsValid() {
		t.Fatal("NewSphere returned invalid handle")
	}
	if s.IsEmpty() {
		t.Error("sphere should not be empty")
	}
	if s.Volume() <= 0 {
		t.Errorf("expected positive volume for sphere, got %f", s.Volume())
	}
	expectedVol := float32(4.0/3.0*math.Pi) * 10.0 * 10.0 * 10.0
	if !approxEqual(s.Volume(), expectedVol, expectedVol*0.2) {
		t.Errorf("sphere volume %f not close to expected %f (within 20%%)", s.Volume(), expectedVol)
	}
}

func TestNewCapsule(t *testing.T) {
	initOnce(t)
	c := NewCapsule(Vec3{0, 0, 0}, Vec3{10, 0, 0}, 3.0, 3.0)
	defer c.Destroy()
	if !c.IsValid() {
		t.Fatal("NewCapsule returned invalid handle")
	}
	if c.IsEmpty() {
		t.Error("capsule should not be empty")
	}
	if c.Volume() <= 0 {
		t.Errorf("expected positive volume for capsule, got %f", c.Volume())
	}
}

func TestVoxelsBoolAdd(t *testing.T) {
	initOnce(t)
	a := NewSphere(Vec3{-3, 0, 0}, 5.0)
	defer a.Destroy()
	b := NewSphere(Vec3{3, 0, 0}, 5.0)
	defer b.Destroy()

	volA := a.Volume()
	volB := b.Volume()

	a.BoolAdd(b)
	volAB := a.Volume()

	if volAB < volA {
		t.Errorf("union volume %f should be >= sphere A volume %f", volAB, volA)
	}
	if volAB < volB {
		t.Errorf("union volume %f should be >= sphere B volume %f", volAB, volB)
	}
}

func TestVoxelsBoolSubtract(t *testing.T) {
	initOnce(t)
	a := NewSphere(Vec3{0, 0, 0}, 10.0)
	defer a.Destroy()
	b := NewSphere(Vec3{0, 0, 0}, 5.0)
	defer b.Destroy()

	volBefore := a.Volume()
	a.BoolSubtract(b)
	volAfter := a.Volume()

	if volAfter >= volBefore {
		t.Errorf("subtraction should reduce volume: before=%f, after=%f", volBefore, volAfter)
	}
	if volAfter <= 0 {
		t.Error("resulting volume should be positive after subtracting smaller sphere")
	}
}

func TestVoxelsBoolIntersect(t *testing.T) {
	initOnce(t)
	a := NewSphere(Vec3{0, 0, 0}, 10.0)
	defer a.Destroy()
	b := NewSphere(Vec3{5, 0, 0}, 10.0)
	defer b.Destroy()

	a.BoolIntersect(b)
	vol := a.Volume()

	if vol <= 0 {
		t.Error("intersection of overlapping spheres should have positive volume")
	}
	if vol >= 4.0/3.0*math.Pi*1000 {
		t.Error("intersection volume should be less than a full sphere")
	}
}

func TestVoxelsOffset(t *testing.T) {
	initOnce(t)
	s := NewSphere(Vec3{0, 0, 0}, 10.0)
	defer s.Destroy()
	volBefore := s.Volume()

	s.Offset(1.0)
	volAfter := s.Volume()

	if volAfter <= volBefore {
		t.Errorf("positive offset should increase volume: before=%f, after=%f", volBefore, volAfter)
	}
}

func TestVoxelsShell(t *testing.T) {
	initOnce(t)
	s := NewSphere(Vec3{0, 0, 0}, 10.0)
	defer s.Destroy()
	volBefore := s.Volume()

	s.Shell(1.0)
	volAfter := s.Volume()

	if volAfter >= volBefore {
		t.Errorf("shell should reduce volume: before=%f, after=%f", volBefore, volAfter)
	}
	if volAfter <= 0 {
		t.Error("shelled sphere should have positive volume")
	}
}

func TestVoxelsVolume(t *testing.T) {
	initOnce(t)
	s := NewSphere(Vec3{0, 0, 0}, 5.0)
	defer s.Destroy()
	vol := s.Volume()
	if vol <= 0 {
		t.Errorf("expected positive volume, got %f", vol)
	}
}

func TestVoxelsIsEmpty(t *testing.T) {
	initOnce(t)
	v := NewVoxels()
	defer v.Destroy()
	if !v.IsEmpty() {
		t.Error("new empty voxels should be empty")
	}

	s := NewSphere(Vec3{0, 0, 0}, 5.0)
	defer s.Destroy()
	if s.IsEmpty() {
		t.Error("sphere should not be empty")
	}
}

func TestVoxelsIsInside(t *testing.T) {
	initOnce(t)
	s := NewSphere(Vec3{0, 0, 0}, 10.0)
	defer s.Destroy()

	if !s.IsInside(Vec3{0, 0, 0}) {
		t.Error("center of sphere should be inside")
	}
	if s.IsInside(Vec3{100, 100, 100}) {
		t.Error("far point should not be inside")
	}
}

func TestVoxelsSurfaceNormal(t *testing.T) {
	initOnce(t)
	s := NewSphere(Vec3{0, 0, 0}, 10.0)
	defer s.Destroy()

	pt, ok := s.ClosestPoint(Vec3{20, 0, 0})
	if !ok {
		t.Fatal("ClosestPoint failed for sphere")
	}
	normal := s.SurfaceNormal(pt)
	normLen := float32(math.Sqrt(float64(normal.X*normal.X + normal.Y*normal.Y + normal.Z*normal.Z)))
	if !approxEqual(normLen, 1.0, 0.1) {
		t.Errorf("surface normal should be approximately unit length, got %f", normLen)
	}
}

func TestVoxelsClosestPoint(t *testing.T) {
	initOnce(t)
	s := NewSphere(Vec3{0, 0, 0}, 10.0)
	defer s.Destroy()

	pt, ok := s.ClosestPoint(Vec3{20, 0, 0})
	if !ok {
		t.Fatal("ClosestPoint returned false for external point")
	}
	dist := float32(math.Sqrt(float64(pt.X*pt.X + pt.Y*pt.Y + pt.Z*pt.Z)))
	if !approxEqual(dist, 10.0, 1.0) {
		t.Errorf("closest point should be on sphere surface (dist ~10), got dist=%f, pt=%+v", dist, pt)
	}
}

func TestVoxelsRayCast(t *testing.T) {
	initOnce(t)
	s := NewSphere(Vec3{0, 0, 0}, 10.0)
	defer s.Destroy()

	hit, ok := s.RayCast(Vec3{-50, 0, 0}, Vec3{1, 0, 0})
	if !ok {
		t.Fatal("RayCast should hit sphere from outside")
	}
	if hit.X < -11 || hit.X > -9 {
		t.Errorf("expected hit near x=-10, got x=%f", hit.X)
	}

	_, ok = s.RayCast(Vec3{-50, 0, 0}, Vec3{0, 1, 0})
	if ok {
		t.Error("ray parallel to sphere should miss")
	}
}

func TestVoxelsVoxelDimensions(t *testing.T) {
	initOnce(t)
	s := NewSphere(Vec3{0, 0, 0}, 5.0)
	defer s.Destroy()

	ox, oy, oz, sx, sy, sz := s.VoxelDimensions()
	if sx <= 0 || sy <= 0 || sz <= 0 {
		t.Errorf("expected positive voxel dimensions, got %d x %d x %d", sx, sy, sz)
	}
	t.Logf("VoxelDimensions: origin=(%d,%d,%d) size=(%d,%d,%d)", ox, oy, oz, sx, sy, sz)
}

func TestVoxelsBoundingBox(t *testing.T) {
	initOnce(t)
	s := NewSphere(Vec3{0, 0, 0}, 10.0)
	defer s.Destroy()

	bb := s.BoundingBox()
	if bb.Min.X >= bb.Max.X || bb.Min.Y >= bb.Max.Y || bb.Min.Z >= bb.Max.Z {
		t.Errorf("bounding box min should be < max: %+v", bb)
	}
	dx := bb.Max.X - bb.Min.X
	dy := bb.Max.Y - bb.Min.Y
	dz := bb.Max.Z - bb.Min.Z
	if dx < 15 || dy < 15 || dz < 15 {
		t.Errorf("bounding box dimensions too small for sphere r=10: dims=(%f,%f,%f)", dx, dy, dz)
	}
}

func TestVoxelsCopy(t *testing.T) {
	initOnce(t)
	s := NewSphere(Vec3{0, 0, 0}, 5.0)
	defer s.Destroy()

	cp := s.Copy()
	defer cp.Destroy()
	if !cp.IsValid() {
		t.Fatal("Copy returned invalid handle")
	}
	if !cp.IsEqual(s) {
		t.Error("copied voxels should be equal to original")
	}
	if cp.Volume() != s.Volume() {
		t.Errorf("copied volume %f should match original %f", cp.Volume(), s.Volume())
	}
}

func TestVoxelsDiagnose(t *testing.T) {
	initOnce(t)
	s := NewSphere(Vec3{0, 0, 0}, 5.0)
	defer s.Destroy()

	diag := s.Diagnose()
	t.Logf("Diagnose: %s", diag)
}

func TestVoxelsGetSlices(t *testing.T) {
	initOnce(t)
	s := NewSphere(Vec3{0, 0, 0}, 10.0)
	defer s.Destroy()

	ox, oy, oz, sx, sy, sz := s.VoxelDimensions()
	if sx <= 0 || sy <= 0 || sz <= 0 {
		t.Fatalf("expected positive voxel dimensions, got (%d,%d,%d)", sx, sy, sz)
	}
	t.Logf("VoxelDimensions: origin=(%d,%d,%d) size=(%d,%d,%d)", ox, oy, oz, sx, sy, sz)

	t.Skip("GetXSlice/GetYSlice/GetZSlice pass nil to C float* parameter — known SDK issue")
}

// --- Mesh ---

func TestNewMesh(t *testing.T) {
	initOnce(t)
	m := NewMesh()
	defer m.Destroy()
	if !m.IsValid() {
		t.Fatal("NewMesh returned invalid handle")
	}
	if m.VertexCount() != 0 {
		t.Errorf("new mesh should have 0 vertices, got %d", m.VertexCount())
	}
	if m.TriangleCount() != 0 {
		t.Errorf("new mesh should have 0 triangles, got %d", m.TriangleCount())
	}
}

func TestMeshFromVoxels(t *testing.T) {
	initOnce(t)
	s := NewSphere(Vec3{0, 0, 0}, 5.0)
	defer s.Destroy()

	m := MeshFromVoxels(s)
	defer m.Destroy()
	if !m.IsValid() {
		t.Fatal("MeshFromVoxels returned invalid handle")
	}
	if m.VertexCount() == 0 {
		t.Error("mesh from sphere should have vertices")
	}
	if m.TriangleCount() == 0 {
		t.Error("mesh from sphere should have triangles")
	}
}

func TestMeshAddVertex(t *testing.T) {
	initOnce(t)
	m := NewMesh()
	defer m.Destroy()

	idx := m.AddVertex(Vec3{1, 2, 3})
	if idx != 0 {
		t.Errorf("first vertex index should be 0, got %d", idx)
	}
	if m.VertexCount() != 1 {
		t.Errorf("expected 1 vertex, got %d", m.VertexCount())
	}

	idx = m.AddVertex(Vec3{4, 5, 6})
	if idx != 1 {
		t.Errorf("second vertex index should be 1, got %d", idx)
	}
}

func TestMeshAddTriangle(t *testing.T) {
	initOnce(t)
	m := NewMesh()
	defer m.Destroy()

	m.AddVertex(Vec3{0, 0, 0})
	m.AddVertex(Vec3{1, 0, 0})
	m.AddVertex(Vec3{0, 1, 0})

	idx := m.AddTriangle(0, 1, 2)
	if idx != 0 {
		t.Errorf("first triangle index should be 0, got %d", idx)
	}
	if m.TriangleCount() != 1 {
		t.Errorf("expected 1 triangle, got %d", m.TriangleCount())
	}
}

func TestMeshVertices(t *testing.T) {
	initOnce(t)
	m := NewMesh()
	defer m.Destroy()

	m.AddVertex(Vec3{1, 2, 3})
	m.AddVertex(Vec3{4, 5, 6})

	verts := m.Vertices()
	if len(verts) != 6 {
		t.Fatalf("expected 6 floats (2 vertices * 3), got %d", len(verts))
	}
	if verts[0] != 1 || verts[1] != 2 || verts[2] != 3 {
		t.Errorf("first vertex wrong: %v", verts[:3])
	}
	if verts[3] != 4 || verts[4] != 5 || verts[5] != 6 {
		t.Errorf("second vertex wrong: %v", verts[3:6])
	}
}

func TestMeshTriangles(t *testing.T) {
	initOnce(t)
	m := NewMesh()
	defer m.Destroy()

	m.AddVertex(Vec3{0, 0, 0})
	m.AddVertex(Vec3{1, 0, 0})
	m.AddVertex(Vec3{0, 1, 0})
	m.AddTriangle(0, 1, 2)

	tris := m.Triangles()
	if len(tris) != 3 {
		t.Fatalf("expected 3 ints (1 triangle * 3), got %d", len(tris))
	}
	if tris[0] != 0 || tris[1] != 1 || tris[2] != 2 {
		t.Errorf("triangle indices wrong: %v", tris)
	}
}

func TestMeshGetTriangleVertices(t *testing.T) {
	initOnce(t)
	m := NewMesh()
	defer m.Destroy()

	m.AddVertex(Vec3{1, 0, 0})
	m.AddVertex(Vec3{0, 1, 0})
	m.AddVertex(Vec3{0, 0, 1})
	m.AddTriangle(0, 1, 2)

	v0, v1, v2 := m.GetTriangleVertices(0)
	if !vecApproxEqual(v0, Vec3{1, 0, 0}, 1e-6) {
		t.Errorf("v0 wrong: %+v", v0)
	}
	if !vecApproxEqual(v1, Vec3{0, 1, 0}, 1e-6) {
		t.Errorf("v1 wrong: %+v", v1)
	}
	if !vecApproxEqual(v2, Vec3{0, 0, 1}, 1e-6) {
		t.Errorf("v2 wrong: %+v", v2)
	}
}

func TestMeshBoundingBox(t *testing.T) {
	initOnce(t)
	m := NewMesh()
	defer m.Destroy()

	m.AddVertex(Vec3{-5, -3, -1})
	m.AddVertex(Vec3{5, 3, 1})

	bb := m.BoundingBox()
	if bb.Min.X != -5 || bb.Max.X != 5 {
		t.Errorf("X bounds wrong: %+v", bb)
	}
	if bb.Min.Y != -3 || bb.Max.Y != 3 {
		t.Errorf("Y bounds wrong: %+v", bb)
	}
	if bb.Min.Z != -1 || bb.Max.Z != 1 {
		t.Errorf("Z bounds wrong: %+v", bb)
	}
}

// --- Lattice ---

func TestNewLattice(t *testing.T) {
	initOnce(t)
	lat := NewLattice()
	defer lat.Destroy()
	if !lat.IsValid() {
		t.Fatal("NewLattice returned invalid handle")
	}
}

func TestLatticeAddSphere(t *testing.T) {
	initOnce(t)
	lat := NewLattice()
	defer lat.Destroy()
	lat.AddSphere(Vec3{0, 0, 0}, 2.0)
	lat.AddSphere(Vec3{10, 0, 0}, 2.0)
	if lat.MemUsage() <= 0 {
		t.Error("lattice with spheres should have positive memory usage")
	}
}

func TestLatticeAddBeam(t *testing.T) {
	initOnce(t)
	lat := NewLattice()
	defer lat.Destroy()
	lat.AddBeam(Vec3{0, 0, 0}, Vec3{10, 0, 0}, 1.0, 1.0, true)
	if lat.MemUsage() <= 0 {
		t.Error("lattice with beam should have positive memory usage")
	}
}

func TestLatticeToVoxels(t *testing.T) {
	initOnce(t)
	lat := NewLattice()
	defer lat.Destroy()
	lat.AddSphere(Vec3{0, 0, 0}, 5.0)
	lat.AddBeam(Vec3{0, 0, 0}, Vec3{10, 0, 0}, 2.0, 2.0, true)

	v := lat.ToVoxels()
	defer v.Destroy()
	if !v.IsValid() {
		t.Fatal("ToVoxels returned invalid handle")
	}
	if v.IsEmpty() {
		t.Error("lattice voxels should not be empty")
	}
	if v.Volume() <= 0 {
		t.Error("lattice voxels should have positive volume")
	}
}

// --- PolyLine ---

func TestNewPolyLine(t *testing.T) {
	initOnce(t)
	pl := NewPolyLine(ColorFloat{R: 1, G: 0, B: 0, A: 1})
	defer pl.Destroy()
	if !pl.IsValid() {
		t.Fatal("NewPolyLine returned invalid handle")
	}
	if pl.VertexCount() != 0 {
		t.Errorf("new polyline should have 0 vertices, got %d", pl.VertexCount())
	}
}

func TestPolyLineAddVertex(t *testing.T) {
	initOnce(t)
	pl := NewPolyLine(ColorFloat{R: 0, G: 1, B: 0, A: 1})
	defer pl.Destroy()

	idx := pl.AddVertex(Vec3{0, 0, 0})
	if idx != 0 {
		t.Errorf("first vertex index should be 0, got %d", idx)
	}
	pl.AddVertex(Vec3{1, 1, 1})
	if pl.VertexCount() != 2 {
		t.Errorf("expected 2 vertices, got %d", pl.VertexCount())
	}
}

func TestPolyLineGetColor(t *testing.T) {
	initOnce(t)
	color := ColorFloat{R: 0.5, G: 0.6, B: 0.7, A: 0.8}
	pl := NewPolyLine(color)
	defer pl.Destroy()

	got := pl.GetColor()
	if !approxEqual(got.R, 0.5, 1e-6) || !approxEqual(got.G, 0.6, 1e-6) ||
		!approxEqual(got.B, 0.7, 1e-6) || !approxEqual(got.A, 0.8, 1e-6) {
		t.Errorf("GetColor mismatch: expected %+v, got %+v", color, got)
	}
}

// --- VdbFile ---

func TestNewVdbFile(t *testing.T) {
	initOnce(t)
	f := NewVdbFile()
	defer f.Destroy()
	if !f.IsValid() {
		t.Fatal("NewVdbFile returned invalid handle")
	}
	if f.FieldCount() != 0 {
		t.Errorf("new vdb file should have 0 fields, got %d", f.FieldCount())
	}
}

func TestVdbFileAddVoxels(t *testing.T) {
	initOnce(t)
	f := NewVdbFile()
	defer f.Destroy()

	s := NewSphere(Vec3{0, 0, 0}, 5.0)
	defer s.Destroy()

	idx := f.AddVoxels("sphere", s)
	if idx != 0 {
		t.Errorf("first field index should be 0, got %d", idx)
	}
	if f.FieldCount() != 1 {
		t.Errorf("expected 1 field, got %d", f.FieldCount())
	}
}

func TestVdbFileFieldCount(t *testing.T) {
	initOnce(t)
	f := NewVdbFile()
	defer f.Destroy()

	s1 := NewSphere(Vec3{0, 0, 0}, 5.0)
	defer s1.Destroy()
	s2 := NewSphere(Vec3{10, 0, 0}, 3.0)
	defer s2.Destroy()

	f.AddVoxels("a", s1)
	f.AddVoxels("b", s2)
	if f.FieldCount() != 2 {
		t.Errorf("expected 2 fields, got %d", f.FieldCount())
	}
}

func TestVdbFileFieldName(t *testing.T) {
	initOnce(t)
	f := NewVdbFile()
	defer f.Destroy()

	s := NewSphere(Vec3{0, 0, 0}, 5.0)
	defer s.Destroy()

	f.AddVoxels("my_field", s)
	name := f.GetFieldName(0)
	if name != "my_field" {
		t.Errorf("expected field name 'my_field', got '%s'", name)
	}
}

// --- ScalarField ---

func TestNewScalarField(t *testing.T) {
	initOnce(t)
	sf := NewScalarField()
	defer sf.Destroy()
	if !sf.IsValid() {
		t.Fatal("NewScalarField returned invalid handle")
	}
}

func TestScalarFieldFromVoxels(t *testing.T) {
	initOnce(t)
	s := NewSphere(Vec3{0, 0, 0}, 5.0)
	defer s.Destroy()

	sf := ScalarFieldFromVoxels(s)
	defer sf.Destroy()
	if !sf.IsValid() {
		t.Fatal("ScalarFieldFromVoxels returned invalid handle")
	}
}

func TestScalarFieldSetGetValue(t *testing.T) {
	initOnce(t)
	sf := NewScalarField()
	defer sf.Destroy()

	pt := Vec3{1, 2, 3}
	sf.SetValue(pt, 42.0)

	val, ok := sf.GetValue(pt)
	if !ok {
		t.Fatal("GetValue returned false for set point")
	}
	if !approxEqual(val, 42.0, 1e-6) {
		t.Errorf("expected value 42.0, got %f", val)
	}

	_, ok = sf.GetValue(Vec3{99, 99, 99})
	if ok {
		t.Error("GetValue should return false for unset point")
	}
}

// --- VectorField ---

func TestNewVectorField(t *testing.T) {
	initOnce(t)
	vf := NewVectorField()
	defer vf.Destroy()
	if !vf.IsValid() {
		t.Fatal("NewVectorField returned invalid handle")
	}
}

func TestVectorFieldFromVoxels(t *testing.T) {
	initOnce(t)
	s := NewSphere(Vec3{0, 0, 0}, 5.0)
	defer s.Destroy()

	vf := VectorFieldFromVoxels(s)
	defer vf.Destroy()
	if !vf.IsValid() {
		t.Fatal("VectorFieldFromVoxels returned invalid handle")
	}
}

func TestVectorFieldSetGetValue(t *testing.T) {
	initOnce(t)
	vf := NewVectorField()
	defer vf.Destroy()

	pt := Vec3{1, 2, 3}
	val := Vec3{4, 5, 6}
	vf.SetValue(pt, val)

	got, ok := vf.GetValue(pt)
	if !ok {
		t.Fatal("GetValue returned false for set point")
	}
	if !vecApproxEqual(got, val, 1e-6) {
		t.Errorf("expected %+v, got %+v", val, got)
	}

	_, ok = vf.GetValue(Vec3{99, 99, 99})
	if ok {
		t.Error("GetValue should return false for unset point")
	}
}

// --- Metadata ---

func TestMetadataFromVoxels(t *testing.T) {
	initOnce(t)
	s := NewSphere(Vec3{0, 0, 0}, 5.0)
	defer s.Destroy()

	md := MetadataFromVoxels(s)
	defer md.Destroy()
	if md.Count() < 0 {
		t.Errorf("metadata count should be >= 0, got %d", md.Count())
	}
}

func TestMetadataSetGet(t *testing.T) {
	initOnce(t)
	s := NewSphere(Vec3{0, 0, 0}, 5.0)
	defer s.Destroy()

	md := MetadataFromVoxels(s)
	defer md.Destroy()

	// String
	md.SetString("name", "test_sphere")
	str, ok := md.GetString("name")
	if !ok {
		t.Fatal("GetString returned false")
	}
	if str != "test_sphere" {
		t.Errorf("expected 'test_sphere', got '%s'", str)
	}

	// Float
	md.SetFloat("radius", 5.0)
	fval, ok := md.GetFloat("radius")
	if !ok {
		t.Fatal("GetFloat returned false")
	}
	if !approxEqual(fval, 5.0, 1e-6) {
		t.Errorf("expected 5.0, got %f", fval)
	}

	// Vector
	md.SetVector("center", Vec3{1, 2, 3})
	vval, ok := md.GetVector("center")
	if !ok {
		t.Fatal("GetVector returned false")
	}
	if !vecApproxEqual(vval, Vec3{1, 2, 3}, 1e-6) {
		t.Errorf("expected {1,2,3}, got %+v", vval)
	}

	// Missing key
	_, ok = md.GetString("nonexistent")
	if ok {
		t.Error("GetString should return false for nonexistent key")
	}
	_, ok = md.GetFloat("nonexistent")
	if ok {
		t.Error("GetFloat should return false for nonexistent key")
	}
	_, ok = md.GetVector("nonexistent")
	if ok {
		t.Error("GetVector should return false for nonexistent key")
	}
}
