# blender — Gossamer SDK for the Blender MCP Server

`blender` is a Gossamer SDK for the [Blender MCP](https://github.com/ahujasid/blender-mcp) server. It provides a fully typed, idiomatic Gossamer interface to all 26 Blender MCP tools — from executing Python code to querying scene objects, capturing screenshots, rendering, and inspecting blend files.

## Prerequisites (same as the Go and MoonBit SDKs)

- Blender running with the MCP addon enabled and server started
- The blender-mcp server installed: `pip install blender-mcp`

The SDK auto-starts the blender-mcp HTTP server on first connect, so `gos run .` just works — no manual server launch needed.

## Quick Start

```gossamer
let client = blender::new_client()?
defer client.close()

let res = client.execute_blender_code(
    "import bpy; result = {'count': len(bpy.data.objects)}".to_string()
)?
println(res)
```

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

The SDK communicates with the Blender MCP server over HTTP using the MCP streamable-http transport. Gossamer's `process::spawn` connects child stdio to `/dev/null` (no pipe access), so stdio-based JSON-RPC isn't possible. Instead, the SDK:

1. **`new_client()`** — tries connecting to an existing server on port 8765. If that fails, launches the blender-mcp HTTP server via `process::spawn`, polls until ready, then performs the MCP `initialize` handshake.
2. **Each tool call** — sends a JSON-RPC `tools/call` request via HTTP POST, receives an SSE-formatted response (`event: message\ndata: {...}`), parses the `data:` line as JSON, and extracts the text content from the tool result.
3. **`close()`** — kills the server process if the SDK launched it.

Request headers include `Accept: application/json, text/event-stream` as required by the MCP streamable-http protocol.

## Files

```
sdk/gos/blender/
├── project.toml       # manifest
├── README.md          # this file
├── blender.gos         # Client struct, JSON-RPC transport, auto-server-start, unit tests
└── tools.gos           # all 26 tool methods (impl Client)
```