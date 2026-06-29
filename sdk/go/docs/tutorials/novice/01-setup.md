# Novice 1 — Set up a project and install the Go PicoGK SDK

## Prerequisites

- **Go 1.22+**
- **PicoGK MCP server** at `~/.local/bin/picogk-mcp/PicoGK.Mcp`

### Install Go

```bash
# macOS (Homebrew)
brew install go

# Linux (download from https://go.dev/dl/)
# Or use your package manager: apt install golang, dnf install golang, etc.
```

### Verify the MCP server

```bash
ls ~/.local/bin/picogk-mcp/PicoGK.Mcp
# If not present, install it following the PicoGK documentation.
```

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
go mod edit -replace github.com/gmlewis/PicoGK/sdk/go/picogk=../PicoGK/sdk/go/picogk
go get github.com/gmlewis/PicoGK/sdk/go/picogk

# Option B: use the published module (when available)
go get github.com/gmlewis/PicoGK/sdk/go/picogk
```

## Your first program

Create `main.go`:

```go
package main

import (
    "context"
    "fmt"
    "log"

    "github.com/gmlewis/PicoGK/sdk/go/picogk"
)

func main() {
    log.SetFlags(0)
    client, err := picogk.NewClient(context.Background(), "")
    if err != nil {
        log.Fatal(err)
    }
    defer client.Close()

    // Initialize the kernel with a 0.2mm voxel grid.
    client.Must(picogk.Init{VoxelSizeMM: picogk.Ptr(0.2)})

    // Print runtime info.
    label, info := client.Must(picogk.Info{})
    fmt.Printf("%s: %s\n", label, info)

    // Create a sphere and query its volume.
    client.Must(picogk.CreateSphere{X: 0, Y: 0, Z: 0, Radius: 10, ID: "ball"})
    _, vol := client.Must(picogk.GetVolume{ObjectID: "ball"})
    fmt.Printf("volume: %s\n", vol)

    client.Must(picogk.Shutdown{})
}
```

## Run it

```bash
go run main.go
```

Expected output:

```
picogk_info: {"version":"26.2.0",...}
volume: {"volumeMM3":4188.79,...}
```

## How it works

1. `picogk.NewClient` launches the PicoGK MCP server as a subprocess and
   performs the JSON-RPC `initialize` handshake.
2. `client.Must(cmd)` sends a tool call and returns `(label, result)`. On
   error, it calls `log.Fatal`.
3. `picogk.Init{VoxelSizeMM: picogk.Ptr(0.2)}` initializes the voxel grid. The
   `picogk.Ptr()` helper creates a `*float64` — required for optional fields.
4. `defer client.Close()` shuts down the subprocess on exit.

## Next steps

- [Novice 2 — First shapes →](02-first-shapes.md)