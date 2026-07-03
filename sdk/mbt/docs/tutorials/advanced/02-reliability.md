# Advanced 2 — Reliability: errors, lifetimes, and cleanup

## Error handling

The FFI SDK uses `Result` types for initialization and direct method calls
that can fail. Use `try`/`catch` or `.unwrap()` appropriately:

```moonbit
///|

fn main {
  // init_with_size returns Result[Unit, String]
  match @pk@pk.init_library(0.5) {
    Ok(_) => println("initialized OK")
    Err(msg) => {
      println("failed to initialize: " + msg)
      return
    }
  }
  defer @pk@pk@pk.shutdown()

  let ball = @pk@pk.new_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 10.0)
  // ... operations on ball ...
  ball.destroy()
}
```

## The never-abort contract

PicoGK's native runtime is designed to never abort the process on bad input.
Invalid operations (e.g., boolean on empty geometry) produce empty or
default results rather than crashes. The FFI SDK surfaces these as:

- **Empty objects**: check with `obj.is_empty()`.
- **Invalid handles**: check with `obj.is_valid()`.
- **Optional return values**: methods like `closest_point()` and `ray_cast()`
  return `Option[Vec3]` — `None` means no intersection.

## Object lifetimes

Objects live in the PicoGK native library's memory. They persist until:

1. You destroy them (`obj.destroy()`).
2. You call `@pk@pk@pk.shutdown()` (invalidates everything).

```moonbit
  let temp = @pk@pk.new_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 5.0)
  // ... use temp ...
  temp.destroy()
  // Do NOT use temp after destroy — it's a dangling handle.
```

## Resource cleanup pattern

```moonbit
  let body = @pk@pk.new_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let hole = @pk@pk.new_sphere(@pk.Vec3::new(6.0, 0.0, 0.0), 6.0)
  let part = body.sub(hole)

  // Clean up intermediates, keep only the result.
  hole.destroy()
  body.destroy()

  // ... use part ...

  part.destroy()
```

## Checking for empty results

After a boolean intersect or a subtract that might remove all material, check
emptiness:

```moonbit
  let a = @pk@pk.new_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let b = @pk@pk.new_sphere(@pk.Vec3::new(50.0, 0.0, 0.0), 5.0) // far away
  let result = a.intersect(b)
  if result.is_empty() {
    println("intersection is empty — objects don't overlap")
  }
  a.destroy(); b.destroy(); result.destroy()
```

## Copying objects

Use `.copy()` to create an independent deep copy:

```moonbit
  let original = @pk@pk.new_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 10.0)
  let clone = original.copy()

  // Check equality:
  println("equal: " + original.is_equal(clone).to_string())

  original.destroy()
  clone.destroy()
```

## Next steps

- [Advanced 3 — Rendering →](03-viewer.md)