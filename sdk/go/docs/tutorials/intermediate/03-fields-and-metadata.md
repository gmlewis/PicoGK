# Intermediate 3 — Fields and metadata

## Overview

The FFI SDK exposes `ScalarField`, `VectorField`, and `Metadata` types
directly — the same types the Python PicoPie binding provides. These let
you attach per-voxel data and key/value annotations to voxel objects, all
of which persist in OpenVDB files alongside the geometry.

## Scalar fields

A `ScalarField` stores a `float32` value at each active voxel point. The
most common way to create one is from an existing voxel field — the field
inherits the voxel grid's dimensions and active topology:

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

    // Build a part.
    body := picogkffi.NewSphere(picogkffi.Vec3{0, 0, 0}, 10)
    defer body.Destroy()
    hole := picogkffi.NewSphere(picogkffi.Vec3{6, 0, 0}, 6)
    defer hole.Destroy()
    part := body.Sub(hole)
    defer part.Destroy()

    // Create a scalar field from the voxels:
    sf := picogkffi.ScalarFieldFromVoxels(part)
    defer sf.Destroy()

    // Grid dimensions:
    ox, oy, oz, sx, sy, sz := sf.ScalarFieldDimensions()
    fmt.Printf("scalar field grid: origin=(%d,%d,%d) size=(%d,%d,%d)\n",
        ox, oy, oz, sx, sy, sz)
}
```

### Set and get per-point values

```go
    // Set a value at a point:
    sf.SetValue(picogkffi.Vec3{0, 0, 0}, 42.0)

    // Get a value at a point:
    val, ok := sf.GetValue(picogkffi.Vec3{0, 0, 0})
    if ok {
        fmt.Printf("value at origin: %.1f\n", val)
    }

    // Remove a value:
    sf.RemoveValue(picogkffi.Vec3{0, 0, 0})
```

### Slicing

`GetSlice(z)` returns the scalar values at a given Z layer as a flat
`[]float32`, indexed as `[x*sizeY + y]`:

```go
    slice := sf.GetSlice(0)
    fmt.Printf("slice at z=0: %d values\n", len(slice))
```

### Traverse active values

`TraverseActive` calls a function for every active voxel in the field —
the point position and its scalar value:

```go
    count := 0
    sf.TraverseActive(func(pt picogkffi.Vec3, val float32) {
        if count < 5 {
            fmt.Printf("  (%.1f,%.1f,%.1f) = %.2f\n", pt.X, pt.Y, pt.Z, val)
        }
        count++
    })
    fmt.Printf("total active: %d\n", count)
```

### Creating an empty scalar field

`NewScalarField()` creates an empty scalar field. You must set values
manually — the field starts with no active topology:

```go
    sf := picogkffi.NewScalarField()
    defer sf.Destroy()
    sf.SetValue(picogkffi.Vec3{0, 0, 0}, 1.0)
    sf.SetValue(picogkffi.Vec3{1, 0, 0}, 2.0)
    sf.SetValue(picogkffi.Vec3{0, 1, 0}, 3.0)
```

## Vector fields

A `VectorField` stores a `Vec3` (three `float32`s) at each active point —
useful for flow direction, normals, displacement, etc.

```go
    // Create from voxels (inherits grid):
    vf := picogkffi.VectorFieldFromVoxels(part)
    defer vf.Destroy()

    // Or create empty:
    vf2 := picogkffi.NewVectorField()
    defer vf2.Destroy()

    // Set / get:
    vf.SetValue(picogkffi.Vec3{0, 0, 0}, picogkffi.Vec3{1, 0, 0})
    val, ok := vf.GetValue(picogkffi.Vec3{0, 0, 0})
    if ok {
        fmt.Printf("vector at origin: (%.1f,%.1f,%.1f)\n", val.X, val.Y, val.Z)
    }

    // Traverse active:
    vf.TraverseActive(func(pt, vec picogkffi.Vec3) {
        fmt.Printf("  (%.1f,%.1f,%.1f) -> (%.2f,%.2f,%.2f)\n",
            pt.X, pt.Y, pt.Z, vec.X, vec.Y, vec.Z)
    })
```

## Metadata

`Metadata` holds key/value annotations — strings, floats, or vectors —
attached to a voxel field, scalar field, or vector field. Metadata
persists in VDB files:

```go
    // Extract metadata from a voxel field:
    md := picogkffi.MetadataFromVoxels(part)
    defer md.Destroy()

    // Set values:
    md.SetString("part_name", "shelled_sphere")
    md.SetFloat("wall_thickness", 1.5)
    md.SetVector("build_origin", picogkffi.Vec3{0, 0, 0})

    // Get values:
    if name, ok := md.GetString("part_name"); ok {
        fmt.Println("name:", name)
    }
    if thickness, ok := md.GetFloat("wall_thickness"); ok {
        fmt.Printf("wall: %.1f mm\n", thickness)
    }
    if origin, ok := md.GetVector("build_origin"); ok {
        fmt.Printf("origin: (%.1f,%.1f,%.1f)\n", origin.X, origin.Y, origin.Z)
    }

    // Check the type of an entry:
    typ := md.TypeAt("part_name")
    // typ == picogkffi.MetaTypeString

    // Remove an entry:
    md.Remove("part_name")
```

### Enumerating metadata

```go
    // Count entries:
    fmt.Printf("metadata entries: %d\n", md.Count())

    // Enumerate by index:
    for i := int32(0); i < md.Count(); i++ {
        name := md.NameAt(i)
        typ := md.TypeAt(name)
        switch typ {
        case picogkffi.MetaTypeString:
            v, _ := md.GetString(name)
            fmt.Printf("  %s (string): %s\n", name, v)
        case picogkffi.MetaTypeFloat:
            v, _ := md.GetFloat(name)
            fmt.Printf("  %s (float): %.2f\n", name, v)
        case picogkffi.MetaTypeVector:
            v, _ := md.GetVector(name)
            fmt.Printf("  %s (vector): (%.1f,%.1f,%.1f)\n", name, v.X, v.Y, v.Z)
        }
    }

    // Or get everything as a map[string]any:
    entries := md.Entries()
    fmt.Printf("all entries: %v\n", entries)
```

### Metadata from scalar/vector fields

Metadata can also be extracted from scalar and vector fields:

```go
    sfMd := picogkffi.MetadataFromScalarField(sf)
    defer sfMd.Destroy()

    vfMd := picogkffi.MetadataFromVectorField(vf)
    defer vfMd.Destroy()
```

## VDB with multiple fields

The key workflow: store geometry (voxels), scalar data, and vector data in
a **single VDB file**, then reload and query each field independently.

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

    // Build a part.
    body := picogkffi.NewSphere(picogkffi.Vec3{0, 0, 0}, 10)
    defer body.Destroy()
    hole := picogkffi.NewSphere(picogkffi.Vec3{6, 0, 0}, 6)
    defer hole.Destroy()
    part := body.Sub(hole)
    defer part.Destroy()

    // Extract a scalar field and a vector field from the part:
    heat := picogkffi.ScalarFieldFromVoxels(part)
    defer heat.Destroy()
    flow := picogkffi.VectorFieldFromVoxels(part)
    defer flow.Destroy()

    // Set some metadata on the scalar field:
    heatMd := picogkffi.MetadataFromScalarField(heat)
    defer heatMd.Destroy()
    heatMd.SetString("units", "celsius")
    heatMd.SetFloat("max_temp", 250.0)

    // Save everything to one VDB file:
    vdb := picogkffi.NewVdbFile()
    defer vdb.Destroy()
    vdb.AddVoxels("body", part)
    vdb.AddScalarField("heat", heat)
    vdb.AddVectorField("flow", flow)
    if !vdb.SaveToFile("/tmp/thermal.vdb") {
        panic("VDB save failed")
    }
    fmt.Println("wrote /tmp/thermal.vdb")

    // Reload and query each field:
    loaded := picogkffi.VdbFileFromFile("/tmp/thermal.vdb")
    defer loaded.Destroy()

    n := loaded.FieldCount()
    fmt.Printf("fields: %d\n", n)
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

    // Query the voxel field:
    bodyVox := loaded.GetVoxels(0)
    defer bodyVox.Destroy()
    fmt.Printf("body volume: %.1f mm³\n", bodyVox.Volume())

    // Query the scalar field:
    heatField := loaded.GetScalarField(1)
    defer heatField.Destroy()
    ox, oy, oz, sx, sy, sz := heatField.ScalarFieldDimensions()
    fmt.Printf("heat field grid: (%d,%d,%d) size=(%d,%d,%d)\n",
        ox, oy, oz, sx, sy, sz)

    // Query the vector field:
    flowField := loaded.GetVectorField(2)
    defer flowField.Destroy()
    count := 0
    flowField.TraverseActive(func(pt, vec picogkffi.Vec3) {
        count++
    })
    fmt.Printf("flow field active points: %d\n", count)

    // Read metadata from the reloaded heat field:
    heatMd2 := picogkffi.MetadataFromScalarField(heatField)
    defer heatMd2.Destroy()
    if units, ok := heatMd2.GetString("units"); ok {
        fmt.Println("units:", units)
    }
    if maxT, ok := heatMd2.GetFloat("max_temp"); ok {
        fmt.Printf("max temp: %.1f\n", maxT)
    }
}
```

## Summary

| Capability | FFI SDK |
|---|---|
| `ScalarFieldFromVoxels(v)` | ✅ |
| `sf.SetValue(pt, val)` / `sf.GetValue(pt)` | ✅ |
| `sf.ScalarFieldDimensions()` | ✅ |
| `sf.GetSlice(z)` | ✅ |
| `sf.TraverseActive(fn)` | ✅ |
| `NewScalarField()` | ✅ |
| `VectorFieldFromVoxels(v)` / `NewVectorField()` | ✅ |
| `vf.SetValue(pt, val)` / `vf.GetValue(pt)` | ✅ |
| `vf.TraverseActive(fn)` | ✅ |
| `MetadataFromVoxels(v)` | ✅ |
| `md.GetString/SetFloat/SetVector` | ✅ |
| `md.Count()` / `md.NameAt(i)` / `md.Entries()` | ✅ |
| VDB with voxels + scalar + vector + metadata | ✅ |

## Next steps

- [Advanced 1 — Performance →](../advanced/01-performance.md)