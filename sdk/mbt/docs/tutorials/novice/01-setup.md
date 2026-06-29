# Novice 1 — Set up a project and install the MoonBit PicoGK SDK

## Prerequisites

- **MoonBit** (`moon` CLI tool)
- **PicoGK MCP server** at `~/.local/bin/picogk-mcp/PicoGK.Mcp`

### Install MoonBit

```bash
# macOS (Homebrew)
brew install moonbitlang/tap/moon

# Or download from https://www.moonbitlang.com/download/
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
moon init
```

## Add the PicoGK MoonBit SDK

Add the dependency to your `moon.mod`:

```toml
import {
  "gmlewis/picogk@0.1.0",
  "moonbitlang/async@0.19.2"
}
```

In your package's `moon.pkg`:

```
import {
  "gmlewis/picogk" @picogk,
  "moonbitlang/async",
}

options(
  "is-main": true,
)
```

## Your first program

Create `main.mbt`:

```moonbit
///|
async fn main {
  // Launch the PicoGK MCP server.
  let client = @picogk.new_client("")

  // Initialize the kernel with a 0.2mm voxel grid.
  let _ = client.picogk_init(Some(0.2))

  // Print runtime info.
  println(client.picogk_info())

  // Create a sphere and query its volume.
  let _ = client.create_sphere(0.0, 0.0, 0.0, 10.0, Some("ball"))
  println(client.get_volume("ball"))

  let _ = client.picogk_shutdown()
  client.close()
}
```

## Run it

```bash
moon run .
```

Expected output:

```
{"version":"26.2.0",...}
{"volumeMM3":4188.79,...}
```

## How it works

1. `@picogk.new_client("")` launches the PicoGK MCP server as a subprocess
   and performs the JSON-RPC `initialize` handshake.
2. Tool calls are async methods on `Client` — they return `String` (the tool's
   text response) or `raise` on error.
3. `client.picogk_init(Some(0.2))` initializes the voxel grid. The `Some(0.2)`
   is an optional parameter — use `None` to omit it.
4. `client.close()` shuts down the subprocess.

## Next steps

- [Novice 2 — First shapes →](02-first-shapes.md)