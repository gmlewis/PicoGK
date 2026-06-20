# blender — MoonBit SDK for the Blender MCP Server

`blender` is an auto-generated MoonBit SDK for the [Blender MCP](https://github.com/ahujasid/blender-mcp) server. It provides a fully typed, idiomatic MoonBit interface to all 26 Blender MCP tools — from executing Python code to querying scene objects, capturing screenshots, rendering, and inspecting blend files.

All tool methods are **async** and use `moonbitlang/async` for subprocess management.
They must be called within an `async fn main` block.

## Quick Start

```bash
moon add gmlewis/blender
```

```moonbit
///|
async fn main {
  let client = @blender.new_client("")

  // Execute Python code in Blender
  let res = client.execute_blender_code("import bpy; result = {'count': len(bpy.data.objects)}")
  println(res)

  // Get scene objects summary
  let summary = client.get_objects_summary()
  println(summary)

  // Search the Blender Python API docs
  let docs = client.search_api_docs("how to bake")
  println(docs)

  client.close()
}
```

## API Overview

The SDK exposes all 26 Blender MCP tools via typed methods:

| Category | Tools |
|----------|-------|
| **API Docs** | get_python_api_docs, search_api_docs |
| **Blend File** | get_blendfile_summary_datablocks, get_blendfile_summary_datablocks_for_cli, get_blendfile_summary_missing_files, get_blendfile_summary_missing_files_for_cli, get_blendfile_summary_of_linked_libraries, get_blendfile_summary_of_linked_libraries_for_cli, get_blendfile_summary_path_info, get_blendfile_summary_path_info_for_cli, get_blendfile_summary_usage_guess, get_blendfile_summary_usage_guess_for_cli |
| **Execute** | execute_blender_code, execute_blender_code_for_cli |
| **Manual Docs** | search_manual_docs |
| **Objects** | get_object_detail_summary, get_objects_summary |
| **Render** | render_thumbnail_to_path, render_viewport_to_path |
| **Screenshot** | get_screenshot_of_area_as_image, get_screenshot_of_window_as_image, get_screenshot_of_window_as_json |
| **Viewport** | jump_to_view3d_object_by_name, jump_to_view3d_object_data_by_name |
| **Workspace** | jump_to_tab_by_name, jump_to_tab_by_space_type |

Each tool has:
- A `Client::method_name(...)` method with typed parameters (snake_case)
- Optional parameters are `Option[T]` (use `Some(value)` or `None`)
- Returns `String` (the tool's text response) or raises `Failure` on error
- Full doc comments

## Architecture

The SDK launches the Blender MCP server as a subprocess and communicates via
JSON-RPC over stdio. The Blender MCP server must be installed separately, and
Blender must be running with the MCP addon enabled.

## Auto-Generation

This SDK is auto-generated from the Blender MCP server tool definitions by
`scripts/generate-mbt-blender-sdk.py`. To regenerate:

```bash
./scripts/generate-mbt-blender-sdk.py --verbose
```

**DO NOT EDIT** the generated files — changes will be overwritten.
