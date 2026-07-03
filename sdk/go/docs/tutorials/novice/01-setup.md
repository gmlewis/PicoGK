# Novice 1 — Set up a project and install the Go PicoGK SDK

This tutorial covers the **FFI SDK** (`picogkffi` + `picogkshapes`), which
binds directly to the native PicoGK C++ runtime in-process — no MCP server,
low latency, and access to scalar/vector fields and the OpenGL Viewer.

## Prerequisites

- **Go 1.22+**
- **The native PicoGK dylib**, which ships in `native/<platform>/` inside the
  PicoGK repo. The `picogkffi` package loads it automatically via cgo.

### Install Go

```bash
# macOS (Homebrew)
brew install go

# Linux (download from https://go.dev/dl/)
# Or use your package manager: apt install golang, dnf install golang, etc.
```

### Verify the native library

```bash
# From your PicoGK checkout:
ls native/darwin/libPicoGK.dylib   # macOS
ls native/linux/libPicoGK.so       # Linux
```

The `picogkffi` cgo build tags select the right platform directory
automatically; you do not need to set `LD_LIBRARY_PATH` or copy the dylib
manually when building from within the repo tree.

## Create a project

```bash
mkdir my-parts
cd my-parts
go mod init my-parts
```

## Add the PicoGK Go SDK

The SDK uses a `replace` directive to point at a local checkout. If you're
using a published version, use `go get` instead:

```bash
# Option A: use a local checkout
git clone https://github.com/gmlewis/PicoGK.git ../PicoGK
go mod edit -replace github.com/gmlewis/PicoGK=../PicoGK
go get github.com/gmlewis/PicoGK/sdk/go/picogkffi

# Option B: use the published module (when available)
go get github.com/gmlewis/PicoGK/sdk/go/picogkffi
```

If you also want the parametric shapes (Box, Cylinder, Ring, …), add
`picogkshapes` too:

```bash
go get github.com/gmlewis/PicoGK/sdk/go/picogkshapes
```

## Your first program

Create `main.go`:

```go
package main

import (
    "fmt"
    "os"
    "runtime"

    "github.com/gmlewis/PicoGK/sdk/go/picogkffi"
)

func main() {
    // The OpenGL Viewer (used for screenshots in later tutorials) must run
    // on the OS main thread. Lock it once at startup.
    runtime.LockOSThread()
    defer runtime.UnlockOSThread()

    // Initialize the kernel with a 0.2mm voxel grid. This creates the single
    // PicoGK library instance for the process. The voxel size is fixed for
    // the lifetime of the instance.
    if err := picogkffi.InitWithSize(0.2); err != nil {
        fmt.Fprintln(os.Stderr, "init:", err)
        os.Exit(1)
    }
    defer picogkffi.Shutdown()

    // Print runtime info.
    fmt.Printf("PicoGK %s (%s)\n", picogkffi.Version(), picogkffi.Name())

    // Create a sphere at the origin with radius 10mm and query its volume.
    // Every native object (Voxels, Mesh, Lattice, Viewer) owns a handle that
    // must be freed with Destroy. Use defer so it happens on exit.
    ball := picogkffi.NewSphere(picogkffi.Vec3{0, 0, 0}, 10)
    defer ball.Destroy()
    fmt.Printf("volume: %.1f mm³\n", ball.Volume())
}
```

## Run it

```bash
go run main.go
```

Expected output:

```
PicoGK 26.2.0 (PicoGK)
volume: 4188.8 mm³
```

## How it works

1. `runtime.LockOSThread()` pins `main` to the OS main thread. This is
   required on macOS because the OpenGL Viewer (used in later tutorials)
   can only create a window on the main thread. Locking once at the top of
   `main` is the simplest way to guarantee it.
2. `picogkffi.InitWithSize(0.2)` calls the native
   `Library_hCreateInstance` to create the one-and-only PicoGK instance for
   the process, with a 0.2mm voxel grid. All subsequent `picogkffi` calls
   use this instance. There is no separate "Init" step — `InitWithSize`
   does both.
3. `picogkffi.NewSphere(...)` returns a `*picogkffi.Voxels` — a Go handle
   around a native voxel field. The handle is reference-counted on the C++
   side; calling `Destroy()` (here via `defer`) releases it. Forgetting to
   destroy objects leaks native memory.
4. `ball.Volume()` calls straight into the native runtime and returns a
   `float32` — no JSON-RPC round trip.
5. `defer picogkffi.Shutdown()` destroys the library instance on exit. All
   object handles become invalid after this call.

## Next steps

- [Novice 2 — First shapes →](02-first-shapes.md)