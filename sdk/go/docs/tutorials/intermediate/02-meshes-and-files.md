# Intermediate 2 — Meshes, lattices, and file I/O

## Mesh ↔ Voxels

Every voxel object can be converted to a mesh (marching cubes) and vice
versa. The FFI SDK uses direct method calls — no server round-trip:

```go
package main

import (
    "fmt"
    "runtime"

    "github.com/gmlewis/PicoGK/sdk/go/picogkffi"
)

func main() {
    runtime.LockOSThread()
    defer runtime.UnlockOSThread()

    picogkffi.InitWithSize(0.3)
    defer picogkffi.Shutdown()

    // Build a sphere.
    part := picogkffi.NewSphere(picogkffi.Vec3{0, 0, 0}, 10)
    defer part.Destroy()

    // Voxels -> Mesh (marching cubes):
    mesh := part.ToMesh()
    defer mesh.Destroy()

    // Query mesh info:
    fmt.Printf("mesh: %d verts, %d tris\n",
        mesh.VertexCount(), mesh.TriangleCount())

    // Mesh bounding box:
    bb := mesh.BoundingBox()
    fmt.Printf("bbox: (%.1f,%.1f,%.1f)–(%.1f,%.1f,%.1f)\n",
        bb.Min.X, bb.Min.Y, bb.Min.Z, bb.Max.X, bb.Max.Y, bb.Max.Z)

    // Mesh -> Voxels (re-voxelize):
    revox := picogkffi.FromMesh(mesh)
    defer revox.Destroy()
}
```

## STL import / export

The FFI SDK does not have a built-in STL writer or reader — the native
runtime hands you raw vertex/triangle arrays, and you write the binary STL
yourself. This is the `saveSTL` helper used by the example programs:

```go
import (
    "encoding/binary"
    "os"
)

// saveSTL writes a binary STL file from vertex and triangle arrays.
func saveSTL(path string, vertices []float32, triangles []int32) {
    f, err := os.Create(path)
    if err != nil { panic(err) }
    defer f.Close()

    f.Write(make([]byte, 80))
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
```

Export and import:

```go
    // Export mesh to STL:
    saveSTL("/tmp/part.stl", mesh.Vertices(), mesh.Triangles())

    // Import STL as a mesh, then voxelize:
    imported, err := loadSTL("/tmp/part.stl")
    if err != nil { panic(err) }
    defer imported.Destroy()

    importedVox := picogkffi.FromMesh(imported)
    defer importedVox.Destroy()
```

A complete `loadSTL` helper (binary + ASCII STL reader) is in the
`ffi-fields-and-io` example. The simplified binary-only core:

```go
import (
    "encoding/binary"
    "math"
    "os"
)

func loadSTL(path string) (*picogkffi.Mesh, error) {
    data, err := os.ReadFile(path)
    if err != nil { return nil, err }
    if len(data) < 84 {
        return nil, fmt.Errorf("STL too short: %d bytes", len(data))
    }
    nt := int(binary.LittleEndian.Uint32(data[80:84]))

    mesh := picogkffi.NewMesh()
    offset := 84
    for i := 0; i < nt; i++ {
        base := offset + i*50
        // Each 50-byte record: normal (12) + 3 vertices (36) + uint16 (2)
        readV := func(b []byte) picogkffi.Vec3 {
            return picogkffi.Vec3{
                math.Float32frombits(binary.LittleEndian.Uint32(b[0:])),
                math.Float32frombits(binary.LittleEndian.Uint32(b[4:])),
                math.Float32frombits(binary.LittleEndian.Uint32(b[8:])),
            }
        }
        v0 := readV(data[base+12:])
        v1 := readV(data[base+24:])
        v2 := readV(data[base+36:])
        ia := mesh.AddVertex(v0)
        ib := mesh.AddVertex(v1)
        ic := mesh.AddVertex(v2)
        mesh.AddTriangle(ia, ib, ic)
    }
    return mesh, nil
}
```

## Building a mesh from scratch

`picogkffi.NewMesh()` creates an empty mesh. Add vertices and triangles
by index:

```go
    mesh := picogkffi.NewMesh()
    defer mesh.Destroy()

    // Add vertices (returns the index):
    i0 := mesh.AddVertex(picogkffi.Vec3{0, 0, 0})
    i1 := mesh.AddVertex(picogkffi.Vec3{10, 0, 0})
    i2 := mesh.AddVertex(picogkffi.Vec3{0, 10, 0})

    // Add a triangle by vertex indices:
    mesh.AddTriangle(i0, i1, i2)

    // Add more vertices + triangle:
    j0 := mesh.AddVertex(picogkffi.Vec3{0, 0, 10})
    j1 := mesh.AddVertex(picogkffi.Vec3{10, 0, 10})
    j2 := mesh.AddVertex(picogkffi.Vec3{0, 10, 10})
    mesh.AddTriangle(j0, j1, j2)
```

### Building from arrays

If you already have flat vertex and triangle arrays, use
`MeshFromArrays`:

```go
    vertices := []float32{
        0, 0, 0,
        10, 0, 0,
        0, 10, 0,
    }
    triangles := []int32{0, 1, 2}
    mesh := picogkffi.MeshFromArrays(vertices, triangles)
    defer mesh.Destroy()
```

## Inspecting mesh data

Read back vertices and triangles:

```go
    // Get a single vertex:
    v := mesh.GetVertex(0)
    fmt.Printf("vertex 0: (%.1f, %.1f, %.1f)\n", v.X, v.Y, v.Z)

    // Get a single triangle:
    t := mesh.GetTriangle(0)
    fmt.Printf("triangle 0: %d %d %d\n", t.A, t.B, t.C)

    // Get all three vertex positions of a triangle:
    v0, v1, v2 := mesh.GetTriangleVertices(0)

    // Get all vertices as a flat []float32 (N*3):
    allVerts := mesh.Vertices()
    // Get all triangles as a flat []int32 (M*3):
    allTris := mesh.Triangles()
```

## Lattices

Lattices are beam-and-node structures that rasterize into voxel fields:

```go
    lat := picogkffi.NewLattice()
    defer lat.Destroy()

    // Add sphere nodes:
    lat.AddSphere(picogkffi.Vec3{-10, 0, 0}, 2)
    lat.AddSphere(picogkffi.Vec3{ 10, 0, 0}, 2)

    // Add a beam (can be tapered — different radius at each end):
    lat.AddBeam(
        picogkffi.Vec3{-10, 0, 0},  // start
        picogkffi.Vec3{ 10, 0, 0},  // end
        1.0, 1.0,                    // start radius, end radius
        true,                        // round caps
    )

    // Rasterize the lattice into a voxel field:
    beams := lat.ToVoxels()
    defer beams.Destroy()
```

`AddBeam` takes `start, end Vec3, radiusStart, radiusEnd float32, roundCap bool`.
Set `roundCap = false` for flat-ended beams.

## OpenVDB persistence

The FFI SDK exposes VDB files as a first-class type. A `VdbFile` can hold
multiple fields — voxels, scalar fields, and vector fields — in one file.

### Saving

```go
    // Create a VDB file, add a voxel field, save to disk:
    vdb := picogkffi.NewVdbFile()
    defer vdb.Destroy()
    vdb.AddVoxels("body", part)
    if !vdb.SaveToFile("/tmp/model.vdb") {
        panic("VDB save failed")
    }
```

### Loading and inspecting

```go
    // Load the VDB file:
    loaded := picogkffi.VdbFileFromFile("/tmp/model.vdb")
    defer loaded.Destroy()

    // List all fields:
    n := loaded.FieldCount()
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
        fmt.Printf("  [%d] %s (%s)\n", i, name, typeName)
    }

    // Get the voxel field at index 0:
    loadedPart := loaded.GetVoxels(0)
    defer loadedPart.Destroy()

    // Verify volume matches:
    fmt.Printf("original: %.1f mm³\n", part.Volume())
    fmt.Printf("loaded:   %.1f mm³\n", loadedPart.Volume())
    fmt.Println("equal:", part.IsEqual(loadedPart))
```

### Multiple fields in one VDB

A single VDB file can store multiple named fields. This is the key
advantage over the single-field MCP `SaveVDB`:

```go
    vdb := picogkffi.NewVdbFile()
    defer vdb.Destroy()
    vdb.AddVoxels("body", bodyVox)
    vdb.AddVoxels("support", supportVox)
    vdb.AddScalarField("heat", heatField)
    vdb.AddVectorField("flow", flowField)
    vdb.SaveToFile("/tmp/multifield.vdb")
```

See [Intermediate 3 — Fields & metadata →](03-fields-and-metadata.md) for
scalar fields, vector fields, and metadata — all of which can be stored in
VDB files alongside voxels.

## Querying voxel properties

```go
    // Volume:
    fmt.Printf("volume: %.1f mm³\n", part.Volume())

    // Voxel grid dimensions (origin + size in voxel units):
    ox, oy, oz, sx, sy, sz := part.VoxelDimensions()
    fmt.Printf("voxel grid: origin=(%d,%d,%d) size=(%d,%d,%d)\n",
        ox, oy, oz, sx, sy, sz)

    // Bounding box in mm:
    bb := part.BoundingBox()
    fmt.Printf("bbox: (%.1f,%.1f,%.1f)–(%.1f,%.1f,%.1f)\n",
        bb.Min.X, bb.Min.Y, bb.Min.Z, bb.Max.X, bb.Max.Y, bb.Max.Z)

    // Memory usage:
    fmt.Printf("memory: %d bytes\n", part.MemUsage())

    // Is it empty?
    fmt.Println("empty:", part.IsEmpty())
```

## A note on CLI and SVG export

The MCP SDK provided `SaveCLI` and `SaveSVG` for slice-based 3D-printing
and 2D-manufacturing output. The FFI SDK does not include these — if you
need CLI or SVG output, slice the voxel field yourself using
`GetZSlice(z)` (returns the SDF values at a given Z layer) and write the
format from Go.

## Next steps

- [Intermediate 3 — Fields & metadata →](03-fields-and-metadata.md)