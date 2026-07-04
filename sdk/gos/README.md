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