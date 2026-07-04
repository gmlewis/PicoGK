# Gossamer SDKs for PicoGK

Gossamer (`.gos`) SDKs for the [PicoGK](https://picogk.org) computational geometry kernel and the [Blender MCP](https://github.com/ahujasid/blender-mcp) server.

## Quick Start

### PicoGK Full API Example

```bash
cd sdk/gos/examples/full-api
gos run . -- --v
```

Prerequisites: the PicoGK MCP server binary at `~/.local/bin/picogk-mcp/PicoGK.Mcp`.

### Blender Scene Example

```bash
cd sdk/gos/examples/blender-scene
gos run .
```

Prerequisites: Blender running with the MCP addon enabled; `pip install blender-mcp`.

## Directory Layout

```
sdk/gos/
├── README.md                          # this file
├── blender/                           # Blender MCP SDK
│   ├── project.toml
│   └── src/
│       ├── lib.gos                    # Client struct, stdio transport
│       └── tools.gos                  # 26 Blender MCP tool methods
├── picogk/                            # PicoGK MCP SDK
│   ├── project.toml
│   └── src/
│       ├── lib.gos                    # Client struct, stdio transport
│       └── tools.gos                  # 62 PicoGK MCP tool methods
└── examples/
    ├── blender-scene/                 # Blender scene inspection example
    │   ├── project.toml               # path dep on blender SDK
    │   └── main.gos
    └── full-api/                      # PicoGK full API exercise
        ├── project.toml               # path dep on picogk SDK
        └── main.gos
```

Examples depend on their SDK via `[dependencies]` path dependencies in
`project.toml`. No symlinks or file copies needed.

## Gossamer Quirks (Important)

Gossamer is pre-1.0. These notes document behaviors that shaped these
SDKs and may be useful to future maintainers.

### 1. Subprocess stdio pipes

Both SDKs use `process::spawn_piped(prog, args) -> Result<Child,
errors::Error>` with `Child::write_stdin`, `Child::read_line`,
`Child::close_stdin`, `Child::kill`, and `Child::wait` for interactive
JSON-RPC over stdio — the standard MCP transport. This matches the Go
and MoonBit SDKs exactly.

### 2. Path dependencies

Both examples use `[dependencies]` with `path = "../../picogk"` in
`project.toml` and `use "github.com/gmlewis/picogk/gos" as picogk` in
source. The SDK libraries use the conventional `src/lib.gos` layout so
the dependency resolver finds the library root.

### 3. No `src/` directory required for single-file projects

Gossamer's convention is `src/main.gos` + `src/lib.gos`, but the
auto-bundler's `is_inside_project` check looks for `project.toml` in the
directory itself or its immediate parent. So `.gos` files placed
directly next to `project.toml` (flat layout, no `src/`) work fine for
single-file entry points. This matches Go and MoonBit conventions.
Library projects that serve as path dependencies need `src/lib.gos`.

### 4. Struct fields cannot be `mut`

Gossamer structs are value types. Fields cannot be declared `mut`.
For mutable state inside a struct (like a request-id counter), use
`sync::AtomicI64` which is a heap-managed type — copies of the struct
share the same atomic.

### 5. No `.iter().map().collect()` on Vec

Gossamer's `Vec<T>` doesn't expose `.iter().map(f).collect()` in the
Rust style. Build arrays with a `for` loop and `push()` instead.

### 6. `HashMap` uses `insert` / `get(&key)`, not `set` / `get(key)`

The Gossamer `HashMap` API follows Rust's: `.insert(key, value)` and
`.get(&key)`. There is no `.set()` method.

### 7. Lint false positives with array literals

The `gos lint` unused-variable check doesn't detect variables that are
used as elements of array literals. For example:

```gossamer
let dir = expand_path(path)
let args = ["--directory", dir, ...]  // dir IS used, but lint says unused
```

Workaround: prefix with `_` (`let _dir = ...`) and reference `_dir` in
the array, or inline the expression directly.

### 8. `json::Value` constructor names are capitalized

Use `json::Value::String(...)`, `json::Value::Int(...)`,
`json::Value::Float(...)`, `json::Value::Bool(...)`,
`json::Value::Array(...)`, `json::Value::object([...])` (lowercase `o`
for the object constructor, uppercase for the others). The lowercase
`json::Value::string(...)` is NOT valid and fails at runtime.

### 9. `gos build` (LLVM AOT)

`gos run` (bytecode VM) is the most reliable execution path for complex
programs. The LLVM backend may hit lowerer limitations on programs with
many auto-bundled module functions.

---

## Observations on the Gossamer Language

The following observations were made while porting the Go and MoonBit
PicoGK/Blender SDKs to Gossamer.

### No source-level C FFI

Gossamer's only FFI surface is `[rust-bindings]` in `project.toml`,
which requires writing a Rust crate using the `gossamer-binding`
crate's `register_module!` macro. Source-level `extern "C"` is
rejected at parse time (`GP0016`). There is no way to declare a C
function, include a C header, define a C-compatible struct layout,
or link a native library directly from `.gos` source.

The Go `picogkffi` SDK (3,222 lines across 16 `.go` files) uses cgo
to directly call the PicoGK C++ runtime: 200+ C functions, C struct
fields in Go structs, `//export` for C callbacks, platform-specific
linker flags. The MoonBit SDK (3,709 lines across 17 `.mbt` files +
C stubs) uses `extern "C" fn` declarations and C stub files compiled
alongside the MoonBit source. Neither approach is possible in
Gossamer.

A partial FFI wrapper could be written as a large Rust crate using
`gossamer-binding`, but it would have a completely different API
surface (integer handles instead of typed structs with methods), could
not support per-voxel SDF callbacks (the binding ABI's callback
mechanism is not designed for millions of per-voxel invocations), and
could not support native Viewer callbacks (C function-pointer-based
API). The `gossamer-binding` ABI types (`I64`, `F64`, `String`,
`Vec`, `Option`, `Result`, `Bytes`, `Map`, `Opaque`, `Callback`,
`Variant`) are sufficient for marshalling data but cannot represent C
struct layout or raw pointer arithmetic.

Even a limited source-level `extern "C" fn` mechanism — just function
declarations with scalar/string/Vec params and integer handles for
opaque pointers, without C structs or callbacks — would cover a large
fraction of FFI use cases. MoonBit's approach (extern declarations
in source + C stub files) is a good model.

### Lint false positives with array literal elements

`gos lint` reports unused-variable warnings for variables that are
used as elements of array literals:

```gossamer
let dir = expand_path(path)
let args = ["--directory", dir, ...]  // dir IS used, but lint says unused
```

The workaround is to prefix with `_` (`let _dir = ...`) or inline the
expression, both of which reduce readability.

### Match arm ergonomics

- The last arm before `}` must not have a trailing comma if the arm
  body is a bare expression (not a block). This is inconsistent with
  the optional trailing comma on other arms and with Rust's
  always-optional trailing comma.
- `Ok(_) => ()` as a non-last arm confuses the parser — `()` looks
  like the end of the match. Using `Ok(_) => { () }` with braces works
  but is noisy.
- `match` on a `bool` does not support `true =>` / `false =>` as
  patterns. `if`/`else` is the only option, which is fine for simple
  cases but means `match` cannot be used uniformly for all scrutinee
  types.

### `json::Value` constructor casing inconsistency

The enum variant constructors are `json::Value::String` (capital S),
`json::Value::Int`, `json::Value::Float`, `json::Value::Bool`,
`json::Value::Array`, but `json::Value::object` (lowercase o). The
lowercase `json::Value::string(...)` fails at runtime with `GX0002`.
This inconsistency is easy to hit when writing JSON-building code.

### No `.iter().map().collect()` on Vec

`Vec<T>` does not expose `.iter().map(f).collect()` in the Rust style.
The canonical replacement is a `for` loop with `push()`, which works
but is more verbose for simple transformations.

### `gos build` (LLVM AOT) may fail on complex programs

The LLVM backend fails on programs with many auto-bundled module
functions, producing "undefined symbol" errors (e.g. `@boolean_add`
not found). `gos run` (bytecode VM) handles the same programs
correctly. The `read_entry_source` auto-bundling path is shared
between `gos run` and `gos build`, but the LLVM lowerer does not
correctly resolve all auto-bundled module function symbols.
