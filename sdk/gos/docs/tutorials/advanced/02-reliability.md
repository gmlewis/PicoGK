# Advanced 2 — Reliability

## Error handling

The Gossamer FFI SDK uses `Result[T, String]` for all operations that can
fail. Always handle errors:

```gos
let ball = match new_sphere(Vec3 { x: 0.0, y: 0.0, z: 0.0 }, 10.0) {
    Ok(h) => h,
    Err(e) => { eprintln!("new_sphere failed: {}", e); return }
}
```

## Object lifecycle

Every native object must be destroyed exactly once. The pattern is:

```gos
let obj = match create_something(...) {
    Ok(h) => h,
    Err(e) => { eprintln!("error: {}", e); return }
}
defer destroy_something(obj)  // Cleanup on scope exit
```

### Common mistakes

1. **Forgetting to destroy**: Leaks native memory
2. **Double-destroying**: Causes undefined behavior
3. **Using after destroy**: Accesses freed memory

### Safe patterns

```gos
// Pattern 1: defer cleanup
let mesh = match voxels_to_mesh(vox) {
    Ok(h) => h,
    Err(e) => { eprintln!("error: {}", e); return }
}
defer mesh_destroy(mesh)

// Pattern 2: explicit cleanup in sequence
let a = match new_sphere(...) { Ok(h) => h, Err(e) => return }
let b = match new_sphere(...) { Ok(h) => h, Err(e) => { voxels_destroy(a); return } }
// Use a and b...
voxels_destroy(b)
voxels_destroy(a)
```

## Initialization safety

`init()` can only be called once per process. Calling it again creates a
new instance (the old one is destroyed). Check for errors:

```gos
match init(0.2) {
    Ok(_) => (),
    Err(e) => { eprintln!("init failed: {}", e); return }
}
defer shutdown()
```

## Thread safety

The PicoGK library is not thread-safe. All FFI calls must happen on the
same thread. The Gossamer runtime handles this by default — all code runs
on a single thread.

For the OpenGL viewer, the main thread requirement is handled by the
runtime when you use `gos run --main-thread`.

## Idempotent operations

Some operations are idempotent (safe to call multiple times):
- `shutdown()` — safe to call multiple times
- `voxels_destroy()` — only call once per handle

Others are not:
- `init()` — creates a new instance each time
- `voxels_bool_add()` — modifies the first operand

## Next steps

- [Advanced 3 — Viewer →](03-viewer.md)
