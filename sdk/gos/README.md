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
├── blender/                           # Blender MCP SDK (flat layout)
│   ├── project.toml
│   ├── blender.gos                    # Client struct, HTTP transport, auto-server-start
│   └── tools.gos                      # 26 Blender MCP tool methods
├── picogk/                            # PicoGK MCP SDK (flat layout)
│   ├── project.toml
│   ├── picogk.gos                      # Client struct, batch pipeline transport
│   └── tools.gos                       # 62 PicoGK MCP tool methods
└── examples/
    ├── blender-scene/                 # Blender scene inspection example
    │   ├── project.toml
    │   ├── main.gos
    │   ├── blender.gos -> ../../blender/blender.gos    (symlink)
    │   └── tools.gos   -> ../../blender/tools.gos       (symlink)
    └── full-api/                      # PicoGK full API exercise
        ├── project.toml
        ├── main.gos
        ├── picogk.gos  -> ../../picogk/picogk.gos       (symlink)
        └── tools.gos   -> ../../picogk/tools.gos        (symlink)
```

Examples reference their SDK via **symlinks** to the SDK source files, not
copies. This keeps the SDK in one canonical location.

## Gossamer Quirks (Important)

Gossamer is pre-1.0 and has several limitations that shaped these SDKs.
These are documented here so future maintainers understand the design
decisions.

### 1. No subprocess stdio pipes

Gossamer's `process::spawn` connects stdin/stdout/stderr to `/dev/null`
with no way to pipe data to/from a child process. `process::run` is
one-shot (captures stdout after the child exits). There is no
`Command::new(...).stdin(Pipe).stdout(Pipe)` builder accessible from
`.gos` source — those types are Rust-only.

**Impact:** The Go and MoonBit SDKs launch the MCP server as a subprocess
and talk JSON-RPC over stdio. Gossamer cannot do this.

**Workarounds used:**

- **Blender SDK** — the Blender MCP server supports an HTTP transport
  (`--transport http`). The SDK uses `std::http` to talk to it via HTTP POST
  with SSE-framed responses. It auto-starts the server via `process::spawn`
  and polls until ready.

- **PicoGK SDK** — the PicoGK MCP server only supports stdio. The SDK
  uses `process::pipeline_run` to batch all JSON-RPC requests through the
  server in a single pipeline: it builds a shell script that echoes each
  request with a 100ms delay between them (ensuring sequential processing),
  pipes that into the server, and parses the newline-delimited JSON
  responses. A trailing `sleep 10` keeps stdin open long enough for the
  .NET server to flush all responses. The `Client` collects all tool
  calls, then `execute()` runs them all at once and returns a
  `HashMap<i64, String>` of results keyed by request id.

### 2. Path dependencies don't link at runtime

`project.toml` supports `[dependencies]` with `path = "../other"`, and
`gos fetch` resolves them into the cache. However, neither `gos run` (the
bytecode VM) nor `gos build` (LLVM AOT) actually links dependency code
into the running program. The `use "project-id" as name` import resolves
at `gos check` time (type checking passes), but at runtime the imported
functions are unbound (`GX0002: name not bound in this scope`).

**Impact:** You cannot split a project into a library + consumer with
path dependencies. Everything must be in one flat directory.

**Workaround:** Examples use **symlinks** to the SDK source files in the
same directory as `main.gos`. Gossamer's auto-bundler (which inlines
sibling `.gos` files as `mod NAME { ... }`) follows symlinks correctly
as long as the symlink targets resolve to real files. The `project.toml`
in the SDK directory must NOT be visible to the example's auto-bundler
(which is why we symlink individual files, not the whole directory).

### 3. No `src/` directory required

Gossamer's convention is `src/main.gos` + `src/lib.gos`, but the
auto-bundler's `is_inside_project` check looks for `project.toml` in the
directory itself or its immediate parent. So `.gos` files placed
directly next to `project.toml` (flat layout, no `src/`) work fine —
the bundler treats siblings as modules. This matches Go and MoonBit
conventions.

### 4. Struct fields cannot be `mut`

Gossamer structs are value types. Fields cannot be declared `mut`.
For mutable state inside a struct (like a request-id counter), use
`sync::AtomicI64` which is a heap-managed type — copies of the struct
share the same atomic.

### 5. No `ok_or_else` / `and_then` / `unwrap_or` method chains on Option

Gossamer's `Option<T>` has `unwrap_or` and `unwrap_or_else` but not
`ok_or_else` (which converts `Option` to `Result`). Use explicit `match`
or `if let` patterns instead.

### 6. Match arm quirks

- Match arms need commas between them, but the **last** arm before `}`
  must NOT have a trailing comma if the arm body is a bare expression
  (not a block). `Ok(_) => ()` as a non-last arm confuses the parser
  because `()` looks like the end of the match — use `Ok(_) => { () }`
  with braces instead.
- `match` on a `bool` doesn't support `true =>` / `false =>` as
  patterns. Use `if`/`else` instead.

### 7. No raw strings

Gossamer has no `r"..."` raw string syntax. Strings containing both
single and double quotes need manual escaping or construction via
`json::render()` (which handles escaping correctly).

### 8. No `.iter().map().collect()` on Vec

Gossamer's `Vec<T>` doesn't expose `.iter().map(f).collect()` in the
Rust style. Build arrays with a `for` loop and `push()` instead.

### 9. `HashMap` uses `insert` / `get(&key)`, not `set` / `get(key)`

The Gossamer `HashMap` API follows Rust's: `.insert(key, value)` and
`.get(&key)`. There is no `.set()` method.

### 10. Lint false positives with array literals

The `gos lint` unused-variable check doesn't detect variables that are
used as elements of array literals. For example:

```gossamer
let dir = expand_path(path)
let args = ["--directory", dir, ...]  // dir IS used, but lint says unused
```

Workaround: prefix with `_` (`let _dir = ...`) and reference `_dir` in
the array, or inline the expression directly.

### 11. `json::Value` constructor names are capitalized

Use `json::Value::String(...)`, `json::Value::Int(...)`,
`json::Value::Float(...)`, `json::Value::Bool(...)`,
`json::Value::Array(...)`, `json::Value::object([...])` (lowercase `o`
for the object constructor, uppercase for the others). The lowercase
`json::Value::string(...)` is NOT valid and fails at runtime.

### 12. `gos build` (LLVM AOT) may fail on complex programs

The LLVM backend is still maturing. Programs with many functions or
complex module structures may hit lowerer limitations (undefined
symbol errors). `gos run` (bytecode VM) is the reliable execution path.

---

## Observations on the Gossamer Language

The following observations were made while porting the Go and MoonBit
PicoGK/Blender SDKs to Gossamer.

### No subprocess stdio pipe access

`process::spawn` connects stdin/stdout/stderr to `/dev/null`.
`process::run` is one-shot (captures stdout after exit). There is no
way from `.gos` source to pipe data to a child process's stdin or read
from its stdout interactively. The `Command`/`Stdio`/`Child` types
exist in the Rust stdlib behind `gossamer-std` but are not exposed to
`.gos` code (`process::Command::new(...)` is a `GX0002` error).

This is the single biggest gap encountered. The standard MCP
(Model Context Protocol) transport is JSON-RPC over stdio — the Go
and MoonBit SDKs both launch the MCP server as a subprocess and
communicate via piped stdin/stdout. Without stdio pipe access, every
stdio-only MCP server requires a workaround:

- The Blender SDK works because the Blender MCP server also supports
  an HTTP transport, so the SDK uses `std::http` instead.
- The PicoGK SDK works by batching all requests through
  `process::pipeline_run` (a shell pipeline), which is fundamentally
  non-interactive — all requests are collected and sent at once, then
  all responses are parsed. This changes the API shape from "call and
  get result immediately" to "queue everything, then execute."

A subprocess pipe API — even a simple one like
`process::popen(prog, args) -> (stdin_writer, stdout_reader, pid)` —
would make Gossamer a first-class MCP client language and eliminate
the need for the batch pipeline workaround.

### Path dependencies resolve at check time but not at runtime

`project.toml` supports `[dependencies]` with `path = "../other"`.
`gos fetch` resolves and caches the dependency. `gos check` type-checks
against the dependency's public API successfully. But `gos run` and
`gos build` both fail at runtime with `GX0002: name not bound in this
scope` — the dependency's code is never linked into the running
program. The `read_entry_source` function used by both `gos run` and
`gos build` auto-bundles sibling `.gos` files in the entry's directory
but does not pull in path-dependency sources from the cache.

This means there is no working library mechanism: you cannot write a
reusable `.gos` library and `use` it from a separate project. Every
file must live in the same directory (or subdirectory) as the entry
point. The workaround used here is symlinks: examples symlink the SDK
source files into their own directory so the auto-bundler picks them
up as sibling modules. This works but is fragile — the SDK directory's
own `project.toml` can confuse the auto-bundler's
`is_inside_project` check if the whole directory is symlinked rather
than individual files.

Making path dependencies link at runtime — having `gos run` and
`gos build` include cached dependency sources in the compilation
unit the same way `gos check` resolves them — would enable proper
code reuse and eliminate the symlink workaround.

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

### Raw strings are in the grammar but not implemented

The SPEC (§2.6) defines `raw_string = "r\"" { raw_char } "\"" | "r#\"" { raw_char } "\"#"`
but `r"..."` is not accepted by the parser. Building JSON-RPC payloads
containing both single and double quotes requires manual escaping or
construction via `json::render()`.

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
