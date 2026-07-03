# Advanced 1 — Performance

The FFI SDK (`picogkffi` + `picogkshapes`) binds directly to the native PicoGK
C++ runtime via cgo. There is no subprocess, no JSON-RPC, and no process
boundary — every call is an in-process C function invocation. This makes the
FFI SDK substantially faster than the MCP SDK, and it changes which
performance levers matter.

## Voxel size dominates cost

The voxel size (set at `Init`) is the single biggest performance lever.
Cost scales with the number of voxels, which scales with the **surface
area** divided by **voxel size squared**. Halving the voxel size roughly
quadruples the compute time and memory.

```go
    // Fast (coarse): 0.5mm — good for prototyping
    if err := picogkffi.InitWithSize(0.5); err != nil {
        log.Fatal(err)
    }

    // Slow (fine): 0.1mm — use only for final output
    if err := picogkffi.InitWithSize(0.1); err != nil {
        log.Fatal(err)
    }
```

| Voxel size | Relative speed | Relative memory | Surface quality |
|:-:|:-:|:-:|:-:|
| 0.5mm | 25× | 1/25 | Faceted |
| 0.2mm | 1× | 1× | Good (default) |
| 0.1mm | 1/25 | 25× | Very smooth |
| 0.05mm | 1/100 | 100× | Excellent (use only when necessary) |

## Built-in primitives vs. per-voxel SDF callbacks

The FFI SDK **does** support per-voxel SDF callbacks — unlike the MCP SDK,
which could not afford the process-boundary overhead. Because the FFI
callback runs in-process (a Go function called directly from C via a cgo
trampoline), it is fast enough for real use, including gyroid TPMS
surfaces, super-ellipsoids, and other implicit geometries.

Use `picogkffi.NewSDF` to wrap a Go function, then call
`vox.RenderImplicitWith(bbox, sdf)` to rasterize it into a voxel field:

```go
    // An implicit gyroid surface, evaluated per-voxel in-process.
    gyroid := picogkshapes.NewImplicitGyroid(3, 1)
    sdf := picogkffi.NewSDF(func(x, y, z float32) float32 {
        return float32(gyroid.Eval(float64(x), float64(y), float64(z)))
    })

    vox := picogkffi.NewVoxels()
    defer vox.Destroy()
    vox.RenderImplicitWith(bbox, sdf)
```

That said, **built-in primitives are still cheaper** than a per-voxel
callback. A `NewSphere` or `NewCapsule` is a single C++ call with no Go
callback overhead. Prefer primitives + booleans when the shape allows it:

```go
    // FASTEST: built-in primitives + boolean subtract (no callback)
    body := picogkffi.NewSphere(picogkffi.Vec3{0, 0, 0}, 12)
    defer body.Destroy()
    bore := picogkffi.NewCapsule(
        picogkffi.Vec3{-13, 0, 0}, picogkffi.Vec3{13, 0, 0}, 4, 4)
    defer bore.Destroy()
    part := body.Sub(bore)
    defer part.Destroy()
```

Rule of thumb: use a per-voxel SDF only when no primitive or boolean
combination can express the shape (gyroids, genus surfaces, field-based
modulations).

## No MCP communication overhead

The MCP SDK sent a JSON-RPC message per call and waited for the subprocess
to respond. The FFI SDK has none of that — every operation is a direct cgo
call into the native library. This means:

1. **No batching needed**: there is no round-trip cost to amortize. Calling
   `BoolAdd` twice is just as fast as a hypothetical `BoolAddAll`.
2. **Queries are cheap**: `vox.Volume()`, `vox.BoundingBox()`, etc. are
   in-process reads — no need to cache them to avoid round-trips.
3. **No serialization**: large voxel fields never cross a process
   boundary; they stay in native memory and are addressed by handle.

## Volume queries: fast vs. accurate

`vox.Volume()` returns the voxel-based volume (fast, directly from the
voxel grid). For a more accurate mesh-based volume, convert to mesh first
and read the mesh info:

```go
    // Fast: voxel-based volume
    vol := part.Volume()

    // Accurate: mesh-based (involves marching cubes)
    mesh := part.ToMesh()
    defer mesh.Destroy()
    nTris := mesh.TriangleCount()
```

## Memory management

Monitor memory with `picogkffi.TotalMemoryUsage()` (library-wide) or
`vox.MemUsage()` (per object). Free objects with `obj.Destroy()` — the
idiomatic FFI pattern is `defer obj.Destroy()` immediately after
creation, so cleanup is automatic when the enclosing function returns:

```go
    // Per-object memory:
    fmt.Printf("part memory: %d bytes\n", part.MemUsage())

    // Library-wide memory:
    fmt.Printf("total memory: %d bytes\n", picogkffi.TotalMemoryUsage())

    // Idiomatic cleanup — defer Destroy right after creation:
    body := picogkffi.NewSphere(picogkffi.Vec3{0, 0, 0}, 12)
    defer body.Destroy()

    bite := picogkffi.NewSphere(picogkffi.Vec3{8, 0, 0}, 7)
    defer bite.Destroy()

    part := body.Sub(bite)
    defer part.Destroy()
```

For long-running programs that build many intermediates, call `Destroy()`
explicitly (rather than `defer`) to release memory as soon as the
intermediate is no longer needed — `defer` only runs at function return.

## Shutdown

`picogkffi.Shutdown()` destroys the library instance and releases all
native resources. Every object handle becomes invalid after this call.
Use `defer picogkffi.Shutdown()` once, near the top of `main`:

```go
    func main() {
        if err := picogkffi.InitWithSize(0.2); err != nil {
            log.Fatal(err)
        }
        defer picogkffi.Shutdown()
        // ... build geometry ...
    }
```

## Next steps

- [Advanced 2 — Reliability →](02-reliability.md)