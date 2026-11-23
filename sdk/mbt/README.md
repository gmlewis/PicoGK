# MoonBit SDKs for PicoGK and Blender

This directory contains MoonBit SDKs for the [PicoGK](https://picogk.org)
computational geometry kernel and the [Blender MCP](https://github.com/ahujasid/blender-mcp)
server.

## SDKs

| Package | Description | Details |
|---------|-------------|---------|
| [`picogk`](picogk/) | PicoGK MCP SDK — typed MoonBit client for all 62 PicoGK MCP tools (async, JSON-RPC over stdio) | [README](picogk/README.md) |
| [`picogkffi`](picogkffi/) | PicoGK FFI SDK — direct `extern "C"` binding to the native C++ runtime (no MCP server needed) | [README](picogkffi/README.md) |
| [`picogkshapes`](picogkshapes/) | Parametric shape library — shape construction helpers built on `picogkffi` | [README](picogkshapes/README.md) |
| [`picogk-reinforce`](reinforce/) | Stress-guided FDM micro-fissure and slicer-modifier reinforcer built on `picogkffi` | [README](reinforce/README.md) |
| [`blender`](blender/) | Blender MCP SDK — typed MoonBit client for all 26 Blender MCP tools (async, JSON-RPC over stdio) | [README](blender/README.md) |

## Two PicoGK SDK flavors

| | MCP SDK (`picogk`) | FFI SDK (`picogkffi`) |
|---|---|---|
| **Backend** | PicoGK MCP server (JSON-RPC over stdio) | Native C++ runtime via `extern "C"` |
| **Server required?** | Yes | No |
| **Latency** | One process round-trip per call | In-process (fastest) |
| **Per-voxel SDF** | Not practical | Fast (C-side implementations) |
| **ScalarField / VectorField / Metadata** | Not exposed | Full access |
| **OpenGL Viewer** | Not available | Native Viewer / ViewerEx |

## Examples

Runnable example programs are in [`examples/`](examples/). See the
[examples README](examples/README.md) for a full listing.

## Moon workspace

The `moon.work` file at the root ties all packages together for local
development. All `moon.mod` files set `preferred_target = "native"`, so
`--target native` is never needed.

```bash
cd sdk/mbt/examples/hello-picogk
moon run .
```

## Releasing

All MoonBit packages share one version. From this directory:

```bash
../../scripts/bump-minor-version.py 0.2.5   # set the shared version across all SDKs
# or ./bump-all-versions.sh for a MoonBit-only patch bump
./publish-all.sh -n                         # optional: preview
./publish-all.sh
```

`publish-all.sh` syncs every `moon.mod` (SDK packages, examples, and
`picogk-reinforce`) to the release version, refuses to reuse a published
version, runs `moon check --deny-warn`, commits `sdk/mbt`, tags the repository
`vX.Y.Z`, pushes the commit and tag, and publishes `picogk`, `picogkffi`,
`picogkshapes`, `blender`, and `picogk-reinforce`.

Run `./update-all.sh` to test every published package with warnings treated as
errors.

## Toolchain

The code has been updated to support compiler:

```bash
$ moon version --all
moon 0.1.20261119 (738607b 2026-11-19) ~/.moon/bin/moon
moonc v0.10.22+124d61d05 (2026-11-19) ~/.moon/bin/moonc
moonrun 0.1.20261119 (738607b 2026-11-19) ~/.moon/bin/moonrun

```
