# blender — Gossamer SDK for the Blender MCP Server

`blender` is a Gossamer SDK for the [Blender MCP](https://github.com/ahujasid/blender-mcp) server. It provides a fully typed, idiomatic Gossamer interface to all 26 Blender MCP tools — from executing Python code to querying scene objects, capturing screenshots, rendering, and inspecting blend files.

Unlike the Go and MoonBit SDKs (which launch the MCP server as a subprocess and communicate via JSON-RPC over stdio), the Gossamer SDK connects to the Blender MCP server over its **streamable-http** transport. This fits Gossamer's stdlib naturally: `std::http` provides the client, and no subprocess pipe management is needed.

## Quick Start

Start the Blender MCP server with HTTP transport:

```bash
uv --directory ~/Projects/Blender/blender_mcp/mcp/blmcp run \
  python -m blmcp --transport http --port 8765
```

Blender must be running with the MCP add-on enabled and connected.

Run the demo (exercises 5 tools against the live server):

```bash
gos run src/lib.gos
```

Run the unit tests (SSE parser, path expansion — no server needed):

```bash
gos test src/lib.gos
```

## Usage

```gossamer
use std::errors
use blender

fn main() -> Result<(), errors::Error> {
    let client = blender::new_client("http://127.0.0.1:8765")?
    defer client.close()

    // Execute Python code in Blender
    let res = client.execute_blender_code(
        "import bpy; result = {'count': len(bpy.data.objects)}".to_string()
    )?
    println!("{}", res)

    // Get scene objects summary
    let summary = client.get_objects_summary()?
    println!("{}", summary)

    // Search the Blender Python API docs
    let docs = client.search_api_docs("how to bake", None, None, None)?
    println!("{}", docs)

    Ok(())
}
```

The base URL defaults to `http://127.0.0.1:8765` via the `BLENDER_MCP_URL` environment variable.

## API Overview

The SDK exposes all 26 Blender MCP tools via methods on `Client`:

| Category | Tools |
|----------|-------|
| **Execute** | `execute_blender_code`, `execute_blender_code_for_cli` |
| **Blend File** | `get_blendfile_summary_datablocks`, `_for_cli`, `get_blendfile_summary_missing_files`, `_for_cli`, `get_blendfile_summary_of_linked_libraries`, `_for_cli`, `get_blendfile_summary_path_info`, `_for_cli`, `get_blendfile_summary_usage_guess`, `_for_cli` |
| **Objects** | `get_object_detail_summary`, `get_objects_summary` |
| **API Docs** | `get_python_api_docs`, `search_api_docs` |
| **Screenshot** | `get_screenshot_of_area_as_image`, `get_screenshot_of_window_as_image`, `get_screenshot_of_window_as_json` |
| **Workspace** | `jump_to_tab_by_name`, `jump_to_tab_by_space_type` |
| **Viewport** | `jump_to_view3d_object_by_name`, `jump_to_view3d_object_data_by_name` |
| **Render** | `render_thumbnail_to_path`, `render_viewport_to_path` |
| **Manual Docs** | `search_manual_docs` |

Each method:
- Takes typed parameters (optional params are `Option<T>` — pass `None` to omit)
- Returns `Result<String, errors::Error>` (the tool's text content on success)
- Has a doc comment

The low-level `client.call_tool(tool_name, args)` method is also public for direct MCP tool invocation with `json::Value` arguments.

## Architecture

The SDK communicates with the Blender MCP server over HTTP using the MCP streamable-http transport:

1. **`new_client(base_url)`** — performs the MCP `initialize` handshake over HTTP POST.
2. **Each tool call** — sends a JSON-RPC `tools/call` request via HTTP POST, receives an SSE-formatted response (`event: message\ndata: {...}`), parses the `data:` line as JSON, and extracts the text content from the tool result.
3. **No persistent connection** — each call is an independent HTTP request, so the client is naturally thread-safe (the request id counter uses `AtomicI64`).

Request headers include `Accept: application/json, text/event-stream` as required by the MCP streamable-http protocol.

## Files

```
sdk/gos/blender/
├── project.toml       # manifest
├── README.md          # this file
└── src/
    ├── lib.gos         # Client struct, JSON-RPC transport, demo entry, unit tests
    └── tools.gos        # all 26 tool methods (impl Client)
```