# Advanced 1 — Performance

## Voxel size dominates cost

The voxel size (set at `picogk_init`) is the single biggest performance lever.
Cost scales with the number of voxels, which scales with the **surface
area** divided by **voxel size squared**. Halving the voxel size roughly
quadruples the compute time and memory.

```moonbit
  // Fast (coarse): 0.5mm — good for prototyping
  let _ = client.picogk_init(Some(0.5))

  // Slow (fine): 0.1mm — use only for final output
  let _ = client.picogk_init(Some(0.1))
```

| Voxel size | Relative speed | Relative memory | Surface quality |
|:-:|:-:|:-:|:-:|
| 0.5mm | 25× | 1/25 | Faceted |
| 0.2mm | 1× | 1× | Good (default) |
| 0.1mm | 1/25 | 25× | Very smooth |

## Use primitives + booleans, not per-voxel callbacks

The Python binding's `render_implicit_(sdf, bbox)` evaluates a Python callable
once per voxel from native code — inherently slow. The MoonBit MCP SDK does not
expose per-voxel SDF callbacks at all (the process-boundary overhead would be
prohibitive).

Instead, build shapes from primitives and combine with booleans:

```moonbit
  // FAST: built-in primitives + boolean subtract
  let _ = client.create_sphere(0.0, 0.0, 0.0, 12.0, Some("ball"))
  let _ = client.create_capsule(-13.0, 0.0, 0.0, 13.0, 0.0, 0.0, 4.0, Some("bore"))
  let _ = client.boolean_subtract("ball", "bore", Some("part"))
```

## MCP communication overhead

Each tool call sends a JSON-RPC message to the MCP server subprocess and waits
for the response. This means:

1. **Batch operations**: prefer multi-object tools (`boolean_add_all`,
   `boolean_subtract_all`, `delete_objects`) over looping single-object tools.
2. **Avoid unnecessary queries**: each `get_volume`, `get_bounding_box`, etc.
   is a round-trip. Cache results when possible.

```moonbit
  // GOOD: one call for multiple objects
  let _ = client.boolean_add_all(["a", "b", "c", "d"], Some("all"))

  // SLOWER: N individual calls
  let _ = client.boolean_add("a", "b", Some("ab"))
  let _ = client.boolean_add("ab", "c", Some("abc"))
  let _ = client.boolean_add("abc", "d", Some("all"))
```

## Memory management

Monitor memory usage with `voxels_mem_usage` and clean up intermediate
objects with `delete_object` or `delete_objects`:

```moonbit
  // Check memory:
  println(client.voxels_mem_usage("bigPart"))

  // Clean up intermediates:
  let _ = client.delete_object("temp1")
  let _ = client.delete_objects(["temp2", "temp3"], None)

  // Keep only the final result, delete everything else:
  let _ = client.delete_objects(["finalPart"], Some(true))
```

## Shutdown

`picogk_shutdown` releases all native resources. All object references become
invalid after this call. `client.close()` kills the subprocess.

## Next steps

- [Advanced 2 — Reliability →](02-reliability.md)