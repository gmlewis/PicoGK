# Advanced 1 — Performance

## Voxel size dominates cost

The voxel size (set at `Init`) is the single biggest performance lever.
Cost scales with the number of voxels, which scales with the **surface
area** divided by **voxel size squared**. Halving the voxel size roughly
quadruples the compute time and memory.

```go
    // Fast (coarse): 0.5mm — good for prototyping
    client.Must(picogk.Init{VoxelSizeMM: picogk.Ptr(0.5)})

    // Slow (fine): 0.1mm — use only for final output
    client.Must(picogk.Init{VoxelSizeMM: picogk.Ptr(0.1)})
```

| Voxel size | Relative speed | Relative memory | Surface quality |
|:-:|:-:|:-:|:-:|
| 0.5mm | 25× | 1/25 | Faceted |
| 0.2mm | 1× | 1× | Good (default) |
| 0.1mm | 1/25 | 25× | Very smooth |
| 0.05mm | 1/100 | 100× | Excellent (use only when necessary) |

## Use primitives + booleans, not per-voxel callbacks

The Python binding's `render_implicit_(sdf, bbox)` evaluates a Python callable
once per voxel from native code — inherently slow. The Go MCP SDK does not
expose per-voxel SDF callbacks at all (the process-boundary overhead would be
prohibitive).

Instead, build shapes from primitives and combine with booleans:

```go
    // FAST: built-in primitives + boolean subtract
    do(picogk.CreateSphere{X: 0, Y: 0, Z: 0, Radius: 12, ID: "ball"})
    do(picogk.CreateCapsule{X1: -13, Y1: 0, Z1: 0, X2: 13, Y2: 0, Z2: 0, Radius: 4, ID: "bore"})
    do(picogk.BooleanSubtract{A: "ball", B: "bore", ID: "part"})
```

## MCP communication overhead

Each `client.Do(cmd)` call sends a JSON-RPC message to the MCP server
subprocess and waits for the response. This means:

1. **Batch operations**: prefer multi-object tools (`BooleanAddAll`,
   `BooleanSubtractAll`, `DeleteObjects`) over looping single-object tools.
2. **Avoid unnecessary queries**: each `GetVolume`, `GetBoundingBox`, etc.
   is a round-trip. Cache results when possible.
3. **Use `Do` for fire-and-forget**: `Must` calls `log.Fatal` on error,
   which is fine for examples but in production you may want `Do` with
   error handling.

```go
    // GOOD: one call for multiple objects
    do(picogk.BooleanAddAll{ObjectIDs: []string{"a", "b", "c", "d"}, ID: "all"})

    // SLOWER: N individual calls
    do(picogk.BooleanAdd{A: "a", B: "b", ID: "ab"})
    do(picogk.BooleanAdd{A: "ab", B: "c", ID: "abc"})
    do(picogk.BooleanAdd{A: "abc", B: "d", ID: "all"})
```

## Volume queries: fast vs. accurate

The `GetVolume` tool returns the voxel-based volume (fast, directly from
the voxel grid). For a more accurate mesh-based volume, convert to mesh
first and use `GetMeshInfo`:

```go
    // Fast: voxel-based volume
    _, vol := client.Must(picogk.GetVolume{ObjectID: "part"})

    // Accurate: mesh-based (involves marching cubes)
    do(picogk.VoxelsToMesh{VoxelsID: "part", ID: "mesh"})
    _, meshInfo := client.Must(picogk.GetMeshInfo{ObjectID: "mesh"})
```

## Memory management

Monitor memory usage with `VoxelsMemUsage` and clean up intermediate
objects with `DeleteObject` or `DeleteObjects`:

```go
    // Check memory:
    _, mem := client.Must(picogk.VoxelsMemUsage{ObjectID: "bigPart"})

    // Clean up intermediates:
    do(picogk.DeleteObject{ObjectID: "temp1"})
    do(picogk.DeleteObjects{ObjectIDs: []string{"temp2", "temp3"}})

    // Keep only the final result, delete everything else:
    do(picogk.DeleteObjects{ObjectIDs: []string{"finalPart"}, KeepOnly: picogk.Ptr(true)})
```

## Shutdown

`Shutdown` releases all native resources. All object references become
invalid after this call. The `defer client.Close()` pattern handles this
automatically (it kills the subprocess).

## Next steps

- [Advanced 2 — Reliability →](02-reliability.md)