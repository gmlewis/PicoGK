// Fields, metadata, VDB persistence, and mesh round-trip via the native FFI SDK.
//
// This is the FFI counterpart to the fields-and-io example (a Go port of the
// PicoPie Python example fields_and_io.py). It uses the picogkffi package,
// which binds directly to the native PicoGK C++ runtime — no MCP server
// required. Unlike the MCP version, the FFI binding exposes ScalarField and
// VDB metadata directly, so the full PicoPie fields_and_io workflow is
// reproduced: voxel persistence to OpenVDB, scalar-field extraction, STL
// round-trip, and re-voxelization.
//
// Run:  go run main.go
package main

import (
	"encoding/binary"
	"fmt"
	"io"
	"math"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/gmlewis/PicoGK/sdk/go/picogkffi"
)

func main() {
	outdir := "/tmp/go-picogkffi-fields"
	os.MkdirAll(outdir, 0755)

	fmt.Println("=== Fields & I/O (Go FFI) ===")
	fmt.Printf("Output dir: %s\n\n", outdir)

	if err := picogkffi.InitWithSize(0.3); err != nil {
		fmt.Fprintln(os.Stderr, "Init:", err)
		os.Exit(1)
	}
	defer picogkffi.Shutdown()

	fmt.Println("PicoGK", picogkffi.Version())

	// --- Build a part via boolean subtraction ---
	fmt.Println("--- Build part ---")
	body := picogkffi.NewSphere(picogkffi.Vec3{0, 0, 0}, 10)
	defer body.Destroy()
	hole := picogkffi.NewSphere(picogkffi.Vec3{6, 0, 0}, 6)
	defer hole.Destroy()
	part := body.Sub(hole)
	defer part.Destroy()
	fmt.Printf("  part volume: %.1f mm³\n", part.Volume())

	// --- Persist to VDB, then reload ---
	fmt.Println("\n--- VDB persistence ---")
	vdbPath := filepath.Join(outdir, "part.vdb")
	vdb := picogkffi.NewVdbFile()
	defer vdb.Destroy()
	vdb.AddVoxels("body", part)
	if !vdb.SaveToFile(vdbPath) {
		fmt.Fprintln(os.Stderr, "  VDB save failed")
		os.Exit(1)
	}
	fmt.Printf("  -> %s\n", vdbPath)

	// List fields in the saved VDB.
	loaded := picogkffi.VdbFileFromFile(vdbPath)
	defer loaded.Destroy()
	n := loaded.FieldCount()
	fmt.Printf("  VDB fields: %d\n", n)
	for i := int32(0); i < n; i++ {
		name := loaded.GetFieldName(i)
		ftype := loaded.FieldType(i)
		typeName := "unknown"
		switch ftype {
		case picogkffi.FieldTypeVoxels:
			typeName = "voxels"
		case picogkffi.FieldTypeScalar:
			typeName = "scalar"
		case picogkffi.FieldTypeVector:
			typeName = "vector"
		}
		fmt.Printf("    [%d] %s (%s)\n", i, name, typeName)
	}

	loadedPart := loaded.GetVoxels(0)
	defer loadedPart.Destroy()
	fmt.Printf("  loaded part volume: %.1f mm³\n", loadedPart.Volume())

	// --- Scalar field extraction (FFI-only — not available via MCP) ---
	fmt.Println("\n--- Scalar field ---")
	sf := picogkffi.ScalarFieldFromVoxels(loadedPart)
	defer sf.Destroy()
	ox, oy, oz, sx, sy, sz := sf.ScalarFieldDimensions()
	fmt.Printf("  scalar field grid: origin=(%d,%d,%d) size=(%d,%d,%d)\n", ox, oy, oz, sx, sy, sz)

	// --- Export mesh, re-import, re-voxelize (round trip) ---
	fmt.Println("\n--- STL round trip ---")
	stlPath := filepath.Join(outdir, "part.stl")
	partMesh := loadedPart.ToMesh()
	defer partMesh.Destroy()
	saveSTL(stlPath, partMesh.Vertices(), partMesh.Triangles())
	fmt.Printf("  -> %s  (%d verts, %d tris)\n", stlPath, partMesh.VertexCount(), partMesh.TriangleCount())

	// Re-import the STL as a mesh, then re-voxelize.
	reimportedMesh, err := loadSTL(stlPath)
	if err != nil {
		fmt.Fprintln(os.Stderr, "  load STL:", err)
		os.Exit(1)
	}
	defer reimportedMesh.Destroy()
	fmt.Printf("  re-imported mesh: %d verts, %d tris\n", reimportedMesh.VertexCount(), reimportedMesh.TriangleCount())

	revox := picogkffi.FromMesh(reimportedMesh)
	defer revox.Destroy()

	// Offset (thicken) the re-voxelized part by 0.5 mm.
	revox.Offset(0.5)
	fmt.Printf("  re-voxelized + offset volume: %.1f mm³\n", revox.Volume())
	revoxMesh := revox.ToMesh()
	defer revoxMesh.Destroy()
	offsetPath := filepath.Join(outdir, "part_reimported_offset.stl")
	saveSTL(offsetPath, revoxMesh.Vertices(), revoxMesh.Triangles())
	fmt.Printf("  -> %s\n", offsetPath)

	fmt.Printf("\nNative memory: %.1f MB\n", float64(picogkffi.TotalMemoryUsage())/1e6)
	fmt.Println("done.")
}

// saveSTL writes a binary STL file from vertex and triangle arrays.
func saveSTL(path string, vertices []float32, triangles []int32) {
	f, err := os.Create(path)
	if err != nil {
		fmt.Fprintln(os.Stderr, "create STL:", err)
		return
	}
	defer f.Close()

	header := make([]byte, 80)
	f.Write(header)

	nt := int32(len(triangles) / 3)
	binary.Write(f, binary.LittleEndian, nt)

	for i := 0; i < len(triangles); i += 3 {
		a := triangles[i] * 3
		b := triangles[i+1] * 3
		c := triangles[i+2] * 3
		binary.Write(f, binary.LittleEndian, [3]float32{0, 0, 0})
		binary.Write(f, binary.LittleEndian, [3]float32{vertices[a], vertices[a+1], vertices[a+2]})
		binary.Write(f, binary.LittleEndian, [3]float32{vertices[b], vertices[b+1], vertices[b+2]})
		binary.Write(f, binary.LittleEndian, [3]float32{vertices[c], vertices[c+1], vertices[c+2]})
		binary.Write(f, binary.LittleEndian, uint16(0))
	}
}

// loadSTL reads a binary STL file and returns a picogkffi Mesh.
// Supports both ASCII and binary STL formats.
func loadSTL(path string) (*picogkffi.Mesh, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	// Detect ASCII STL: file starts with "solid" and contains "facet".
	if len(data) > 5 && string(data[:5]) == "solid" {
		// Heuristic: ASCII STL has "facet" near the top.
		scanEnd := len(data)
		if scanEnd > 512 {
			scanEnd = 512
		}
		if containsSubstring(data[:scanEnd], []byte("facet")) {
			return loadASCIISTL(data)
		}
	}

	return loadBinarySTL(data)
}

func containsSubstring(haystack, needle []byte) bool {
	if len(needle) == 0 {
		return true
	}
	for i := 0; i <= len(haystack)-len(needle); i++ {
		match := true
		for j := range needle {
			if haystack[i+j] != needle[j] {
				match = false
				break
			}
		}
		if match {
			return true
		}
	}
	return false
}

// loadBinarySTL parses a binary STL (80-byte header, uint32 tri count, then
// 50-byte records per triangle).
func loadBinarySTL(data []byte) (*picogkffi.Mesh, error) {
	if len(data) < 84 {
		return nil, fmt.Errorf("STL file too short: %d bytes", len(data))
	}
	nt := int(binary.LittleEndian.Uint32(data[80:84]))
	expected := 84 + nt*50
	if len(data) < expected {
		return nil, fmt.Errorf("STL file truncated: expected %d bytes, got %d", expected, len(data))
	}

	mesh := picogkffi.NewMesh()
	offset := 84
	for i := 0; i < nt; i++ {
		// Each record: 12 floats (normal + 3 vertices) + uint16 attribute
		base := offset + i*50
		// Skip the normal (bytes 0..11)
		v0 := [3]float32{
			readFloat32(data[base+12:]),
			readFloat32(data[base+16:]),
			readFloat32(data[base+20:]),
		}
		v1 := [3]float32{
			readFloat32(data[base+24:]),
			readFloat32(data[base+28:]),
			readFloat32(data[base+32:]),
		}
		v2 := [3]float32{
			readFloat32(data[base+36:]),
			readFloat32(data[base+40:]),
			readFloat32(data[base+44:]),
		}
		ia := mesh.AddVertex(picogkffi.Vec3{v0[0], v0[1], v0[2]})
		ib := mesh.AddVertex(picogkffi.Vec3{v1[0], v1[1], v1[2]})
		ic := mesh.AddVertex(picogkffi.Vec3{v2[0], v2[1], v2[2]})
		mesh.AddTriangle(ia, ib, ic)
	}
	return mesh, nil
}

// loadASCIISTL parses an ASCII STL file.
func loadASCIISTL(data []byte) (*picogkffi.Mesh, error) {
	mesh := picogkffi.NewMesh()
	r := &byteReader{data: data, pos: 0}
	for {
		tok, ok := r.readToken()
		if !ok {
			break
		}
		if tok == "vertex" {
			x, _ := r.readFloat()
			y, _ := r.readFloat()
			z, _ := r.readFloat()
			mesh.AddVertex(picogkffi.Vec3{float32(x), float32(y), float32(z)})
		}
	}
	// ASCII STL lists 3 consecutive vertices per triangle; build triangles
	// from consecutive vertex triplets.
	vc := mesh.VertexCount()
	for i := int32(0); i+2 < vc; i += 3 {
		mesh.AddTriangle(i, i+1, i+2)
	}
	return mesh, nil
}

func readFloat32(b []byte) float32 {
	bits := binary.LittleEndian.Uint32(b)
	return math.Float32frombits(bits)
}

// byteReader is a minimal token reader for ASCII STL.
type byteReader struct {
	data []byte
	pos  int
}

func (r *byteReader) readToken() (string, bool) {
	// Skip whitespace
	for r.pos < len(r.data) && isSpace(r.data[r.pos]) {
		r.pos++
	}
	if r.pos >= len(r.data) {
		return "", false
	}
	start := r.pos
	for r.pos < len(r.data) && !isSpace(r.data[r.pos]) {
		r.pos++
	}
	return string(r.data[start:r.pos]), true
}

func (r *byteReader) readFloat() (float64, error) {
	tok, ok := r.readToken()
	if !ok {
		return 0, io.EOF
	}
	return strconv.ParseFloat(strings.TrimRight(tok, ","), 64)
}

func isSpace(b byte) bool {
	return b == ' ' || b == '\t' || b == '\n' || b == '\r'
}