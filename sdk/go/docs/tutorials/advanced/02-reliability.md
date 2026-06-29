# Advanced 2 — Reliability: errors, lifetimes, and cleanup

## Error handling

The Go SDK uses Go's standard error-return pattern. `client.Do(cmd)` returns
`(label, result string, err error)`. `client.Must(cmd)` wraps this and calls
`log.Fatal` on error — convenient for examples, but in production code you
should check the error:

```go
    label, result, err := client.Do(picogk.CreateSphere{X: 0, Y: 0, Z: 0, Radius: 10, ID: "ball"})
    if err != nil {
        return fmt.Errorf("create sphere: %w", err)
    }
    fmt.Printf("%s -> %s\n", label, result)
```

## The never-abort contract

PicoGK's native runtime is designed to never abort the process on bad input.
C++/OpenVDB exceptions are caught by the MCP server and returned as JSON-RPC
error responses. The Go SDK surfaces these as `error` return values — your
program stays alive.

Common error scenarios:

- **Invalid object ID**: referencing an object that doesn't exist (deleted,
  never created, or invalidated by `Shutdown`).
- **Empty intersection**: `BooleanIntersect` of non-overlapping volumes
  produces an empty result. Check with `VoxelsIsEmpty` if needed.
- **File not found**: `LoadVDB` or `MeshFromSTL` with a non-existent path.
- **Invalid parameters**: NaN or infinite values in coordinates/radii are
  rejected by the native runtime.

## Object lifetimes

Objects live in the MCP server's memory. They persist until:

1. You delete them (`DeleteObject`, `DeleteObjects`).
2. You call `Shutdown` (invalidates everything).
3. You close the client (`client.Close()` kills the subprocess).

There is no explicit "close" per object — deletion is the cleanup mechanism.

```go
    // Create and use:
    do(picogk.CreateSphere{X: 0, Y: 0, Z: 0, Radius: 5, ID: "temp"})

    // Use it...

    // Clean up:
    do(picogk.DeleteObject{ObjectID: "temp"})

    // Referencing it now will return an error:
    _, _, err := client.Do(picogk.GetVolume{ObjectID: "temp"})
    // err will be non-nil
```

## Resource cleanup pattern

```go
func buildPart(client *picogk.Client) (string, error) {
    // Create temporary objects.
    if _, _, err := client.Do(picogk.CreateSphere{X: 0, Y: 0, Z: 0, Radius: 10, ID: "body"}); err != nil {
        return "", err
    }
    if _, _, err := client.Do(picogk.CreateSphere{X: 6, Y: 0, Z: 0, Radius: 6, ID: "hole"}); err != nil {
        return "", err
    }
    if _, _, err := client.Do(picogk.BooleanSubtract{A: "body", B: "hole", ID: "part"}); err != nil {
        return "", err
    }

    // Clean up intermediates, keep only the result.
    client.Must(picogk.DeleteObjects{ObjectIDs: []string{"body", "hole"}})

    return "part", nil
}
```

## Using `KeepOnly` for bulk cleanup

`DeleteObjects` with `KeepOnly: new(true)` deletes **everything except** the
listed objects — useful for a final cleanup that preserves only the output:

```go
    // ... many intermediate objects created ...

    // Keep only the final result:
    do(picogk.DeleteObjects{ObjectIDs: []string{"finalPart"}, KeepOnly: new(true)})
```

## Checking for empty results

After a boolean intersect or a subtract that might remove all material, check
emptiness:

```go
    do(picogk.BooleanIntersect{A: "a", B: "b", ID: "result"})
    _, emptyStr := client.Must(picogk.VoxelsIsEmpty{ObjectID: "result"})
    if emptyStr == "true" {
        log.Println("warning: intersection produced no volume")
    }
```

## Next steps

- [Advanced 3 — Rendering →](03-viewer.md)