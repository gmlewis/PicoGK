# Advanced 2 — Reliability: errors, lifetimes, and cleanup

## Error handling

MoonBit methods `raise` on error. Use `try ... catch` to handle errors:

```moonbit
///|
async fn main {
  let client = @picogk.new_client("")
  let _ = client.picogk_init(Some(0.5))

  try {
    let result = client.create_sphere(0.0, 0.0, 0.0, 10.0, Some("ball"))
    println(result)
  } catch {
    e => println("error: " + e.to_string())
  }

  let _ = client.picogk_shutdown()
  client.close()
}
```

## The never-abort contract

PicoGK's native runtime is designed to never abort the process on bad input.
C++/OpenVDB exceptions are caught by the MCP server and returned as JSON-RPC
error responses. The MoonBit SDK surfaces these as `Failure` raises — your
program stays alive.

Common error scenarios:

- **Invalid object ID**: referencing an object that doesn't exist.
- **Empty intersection**: `boolean_intersect` of non-overlapping volumes
  produces an empty result. Check with `voxels_is_empty` if needed.
- **File not found**: `load_vdb` or `mesh_from_stl` with a non-existent path.
- **Invalid parameters**: NaN or infinite values in coordinates/radii.

## Object lifetimes

Objects live in the MCP server's memory. They persist until:

1. You delete them (`delete_object`, `delete_objects`).
2. You call `picogk_shutdown` (invalidates everything).
3. You close the client (`client.close()` kills the subprocess).

```moonbit
  // Create and use:
  let _ = client.create_sphere(0.0, 0.0, 0.0, 5.0, Some("temp"))

  // Clean up:
  let _ = client.delete_object("temp")

  // Referencing it now will raise an error:
  // client.get_volume("temp")  // raises Failure
```

## Resource cleanup pattern

```moonbit
  // Create temporary objects.
  let _ = client.create_sphere(0.0, 0.0, 0.0, 10.0, Some("body"))
  let _ = client.create_sphere(6.0, 0.0, 0.0, 6.0, Some("hole"))
  let _ = client.boolean_subtract("body", "hole", Some("part"))

  // Clean up intermediates, keep only the result.
  let _ = client.delete_objects(["body", "hole"], None)
```

## Using `keepOnly` for bulk cleanup

`delete_objects` with `keepOnly = Some(true)` deletes **everything except**
the listed objects:

```moonbit
  // Keep only the final result:
  let _ = client.delete_objects(["finalPart"], Some(true))
```

## Checking for empty results

After a boolean intersect or a subtract that might remove all material, check
emptiness:

```moonbit
  let _ = client.boolean_intersect("a", "b", Some("result"))
  let empty = client.voxels_is_empty("result")
  // empty contains "True" or "False" in the result string
```

## Next steps

- [Advanced 3 — Rendering →](03-viewer.md)