# PicoGK MoonBit examples

Each directory is a runnable MoonBit module in the [`sdk/mbt`](../) workspace.
Install the PicoGK native library first (see [`picogkffi`](../picogkffi/)).

Run an example from its directory:

```bash
cd examples/hello-picogk
moon run .
```

Many examples accept command-line options (for example `-out DIR`); run
`moon run . -- --help` where available.

| Example | Description |
|---------|-------------|
| [`hello-picogk`](hello-picogk/) | Minimal FFI SDK demo (port of the PicoPie `hello_picogk.py`) |
| [`fields-and-io`](fields-and-io/) | Scalar/vector fields, metadata, VDB persistence, and mesh round-trip |
| [`full-api`](full-api/) | Exercises every `picogkffi` FFI function at least once |
| [`viewer-demo`](viewer-demo/) | Hollow part rendered to PNG through the native OpenGL viewer, plus STL |
| [`visualize`](visualize/) | Z-slice cross-section and 3D viewer renders |
| [`web-demo`](web-demo/) | Self-contained HTML + three.js viewer export |
| [`shapekernel-gallery`](shapekernel-gallery/) | Parametric shape gallery built on `picogkshapes` |
| [`blender-scene`](blender-scene/) | Blender MCP scene inspection and manipulation |
| [`micro-fissure-reinforce`](micro-fissure-reinforce/) | Stress-guided FDM micro-fissure and slicer-modifier pipeline (uses `picogk-reinforce`) |
