# Advanced 1 — Performance

## Voxel size dominates cost

The voxel size (set at `init_with_size`) is the single biggest performance lever.
Cost scales with the number of voxels, which scales with the **surface
area** divided by **voxel size squared**. Halving the voxel size roughly
quadruples the compute time and memory.

```moonbit
  // Fast (coarse): 0.5mm — good for prototyping
  @pk@pk@pk.init_with_size(0.5).unwrap()

  // Slow (fine): 0.1mm — use only for final output
  @pk@pk@pk.init_with_size(0.1).unwrap()
```

| Voxel size | Relative speed | Relative memory | Surface quality |
|:-:|:-:|:-:|:-:|
| 0.5mm | 25× | 1/25 | Faceted |
| 0.2mm | 1× | 1× | Good (default) |
| 0.1mm | 1/25 | 25× | Very smooth |

## FFI: no process-boundary overhead

Unlike the MCP SDK (which communicates with a subprocess over JSON-RPC), the
FFI SDK calls the native PicoGK library directly in-process. This means:

1. **No per-call serialization overhead**: tool calls are native function calls.
2. **No batching needed**: each operation is fast enough on its own.
3. **Implicit SDF rendering works**: per-voxel C callbacks run at full native speed.

```moonbit
  // FAST: built-in primitives + boolean subtract
  let ball = @pk@pk.new_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 12.0)
  let bore = @pk@pk.new_capsule(
    @pk.Vec3::new(-13.0, 0.0, 0.0),
    @pk.Vec3::new(13.0, 0.0, 0.0),
    4.0,
    4.0,
  )
  let part = ball.sub(bore)
```

## Memory management

The FFI SDK manages native memory. You **must** call `.destroy()` on objects
when done, or memory will leak. `@pk@pk@pk.shutdown()` releases all remaining
resources, but explicit cleanup is best practice for long-running programs:

```moonbit
  // Check memory usage:
  println("part memory: " + part.mem_usage().to_string() + " bytes")

  // Clean up intermediates:
  bore.destroy()
  ball.destroy()
  // Keep only the final result.
```

## `init_with_size` vs `init_library`

`init_with_size` is the recommended entry point. It calls `init_library`
internally and also records the voxel size for later use. `init_library`
is the lower-level call that only initializes the library.

```moonbit
  // Recommended:
  @pk@pk@pk.init_with_size(0.2).unwrap()

  // Lower-level (you'd need to track voxel_size yourself):
  @pk@pk.init_library(0.2).unwrap()
```

## Shutdown

`@pk@pk@pk.shutdown()` releases all native resources. All object references become
invalid after this call. Using `defer @pk@pk@pk.shutdown()` ensures cleanup even
on errors.

## Next steps

- [Advanced 2 — Reliability →](02-reliability.md)