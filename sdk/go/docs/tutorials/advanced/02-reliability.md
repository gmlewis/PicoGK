# Advanced 2 — Reliability: errors, lifetimes, and cleanup

## Error handling

The FFI SDK uses Go-native error handling. Functions that can fail return
an `error` (e.g. `picogkffi.Init`). Operations on invalid objects **panic**
rather than return an error — the idiomatic way to handle that is a
`recover()` guard (shown below). For one-shot programs, letting the panic
crash is fine and produces a clear stack trace.

```go
    // Initialization returns an error:
    if err := picogkffi.InitWithSize(0.2); err != nil {
        return fmt.Errorf("picogkffi init: %w", err)
    }
    defer picogkffi.Shutdown()
```

## The never-abort contract

PicoGK's native runtime is designed to never abort the process on bad
input. The PicoGK native runtime never aborts on bad input; errors are
returned as Go errors or panics that can be recovered. The FFI SDK surfaces
these as:

- **Go `error`** for operations that report failure gracefully
  (initialization, file I/O).
- **Go `panic`** for invalid object handles, NaN/infinite parameters, or
  operations on a destroyed object. A `recover()` guard turns these into
  handled errors.

Common error scenarios:

- **Destroyed object**: calling a method on an object whose `Destroy()` was
  already called (the handle is zeroed). This panics.
- **Empty intersection**: `BoolIntersect` of non-overlapping volumes
  produces an empty result. Check with `vox.IsEmpty()` if needed.
- **File not found**: `picogkffi.LoadVDB` or mesh loading with a
  non-existent path returns an error.
- **Invalid parameters**: NaN or infinite values in coordinates/radii are
  rejected by the native runtime (panic).

## Recovering from panics

Wrap risky operations in a deferred `recover()` to convert panics into
handled errors:

```go
    func safeSubtract(a, b *picogkffi.Voxels) (result *picogkffi.Voxels, err error) {
        defer func() {
            if r := recover(); r != nil {
                err = fmt.Errorf("boolean subtract failed: %v", r)
                if result != nil {
                    result.Destroy()
                    result = nil
                }
            }
        }()
        result = a.Sub(b)
        return result, nil
    }
```

## Object lifetimes

Objects live in native memory until `Destroy()` is called. There is no
server, no subprocess, and no garbage collector tracking them — you own
the lifecycle. Use `defer obj.Destroy()` for automatic cleanup:

```go
    // Create and use:
    temp := picogkffi.NewSphere(picogkffi.Vec3{0, 0, 0}, 5)
    defer temp.Destroy()

    // Use it...
    fmt.Println(temp.Volume())

    // After Destroy() (or when defer runs at function return), the handle
    // is zeroed. Calling methods on it will panic.
```

The handle is set to zero (`h == 0`) inside `Destroy()`, and `IsValid()`
returns false afterwards. Double-`Destroy()` is safe (the second call is a
no-op because the handle is already zero).

## Resource cleanup pattern

```go
    func buildPart() (*picogkffi.Voxels, error) {
        // Create temporary objects — defer Destroy cleans them up
        // automatically when this function returns.
        body := picogkffi.NewSphere(picogkffi.Vec3{0, 0, 0}, 10)
        defer body.Destroy()

        hole := picogkffi.NewSphere(picogkffi.Vec3{6, 0, 0}, 6)
        defer hole.Destroy()

        // The result is a *new* object (Sub copies). The caller owns it
        // and must Destroy() it when done.
        part := body.Sub(hole)
        return part, nil
    }

    func main() {
        picogkffi.InitWithSize(0.2)
        defer picogkffi.Shutdown()

        part, err := buildPart()
        if err != nil {
            log.Fatal(err)
        }
        defer part.Destroy() // caller owns the result

        fmt.Println(part.Volume())
    }
```

Note the ownership rule: `Sub`, `Add`, `Intersect`, and `Copy` return a
**new** object. The caller must `Destroy()` the result (and the inputs,
via their own `defer`). This is the same rule as `os.Create` — the caller
closes what it receives.

## Checking for empty results

After a boolean intersect or a subtract that might remove all material,
check emptiness:

```go
    result := a.Intersect(b)
    defer result.Destroy()
    if result.IsEmpty() {
        log.Println("warning: intersection produced no volume")
    }
```

`IsEmpty()` returns a plain `bool` — no error to inspect.

## Next steps

- [Advanced 3 — Rendering →](03-viewer.md)