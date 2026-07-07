# Advanced 1 — Performance

The FFI SDK (`picogkffi` + `picogkshapes`) binds directly to the native PicoGK
C++ runtime via Rust bindings. There is no subprocess, no JSON-RPC, and no process
boundary — every call is an in-process function invocation. This makes the
FFI SDK substantially faster than the MCP SDK, and it changes which
performance levers matter.

## Voxel size dominates cost

The voxel size (set at `init`) is the single biggest performance lever.
Cost scales with the number of voxels, which scales with the **surface
area** divided by **voxel size squared**. Halving the voxel size roughly
quadruples the compute time and memory.

```gos
// Fast (coarse): 0.5mm — good for prototyping
init(0.5)

// Slow (fine): 0.1mm — use only for final output
init(0.1)
```

| Voxel size | Relative speed | Relative memory | Surface quality |
|:-:|:-:|:-:|:-:|
| 0.5mm | 25× | 1/25 | Faceted |
| 0.2mm | 1× | 1× | Good (default) |
| 0.1mm | 1/25 | 25× | Very smooth |
| 0.05mm | 1/100 | 100× | Excellent (use only when necessary) |

## Built-in primitives vs. SDF callbacks

The FFI SDK provides built-in SDF primitives (`new_sphere`, `new_capsule`)
that are extremely fast. For custom geometry, the gyroid and super-ellipsoid
renderers are implemented in Rust and called directly — no marshaling overhead.

## Batch operations

Create objects once, then combine. Avoid repeated create/destroy cycles:

```gos
// Good: create once, operate many times
let a = new_sphere(...)
let b = new_sphere(...)
let c = new_sphere(...)
voxels_bool_add(a, b)
voxels_bool_add(a, c)

// Bad: create/destroy for each operation
let temp = new_sphere(...)
voxels_bool_add(a, temp)
voxels_destroy(temp)
```

## Memory management

Native objects are not garbage-collected. Always destroy objects when done:

```gos
let obj = match new_sphere(...) {
    Ok(h) => h,
    Err(e) => { eprintln!("error: {}", e); return }
}
defer voxels_destroy(obj)  // Always clean up
```

Forgetting to destroy objects leaks native memory. Use `defer` to ensure
cleanup happens even on early returns.

## Choosing the right resolution

| Use case | Recommended voxel size |
|----------|----------------------|
| Prototyping / development | 0.5mm |
| General purpose | 0.2mm |
| Final output / rendering | 0.1mm |
| High-precision engineering | 0.05mm |

Start coarse, refine only when needed. The voxel size is fixed for the
lifetime of the library instance — you must `shutdown()` and `init()` again
to change it.

## Next steps

- [Advanced 2 — Reliability →](02-reliability.md)
