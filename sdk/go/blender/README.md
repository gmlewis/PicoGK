# blender — Go SDK for the Blender MCP Server

`blender` is an auto-generated Go SDK for the [Blender MCP](https://github.com/ahujasid/blender-mcp) server. It provides a fully typed, idiomatic Go interface to all 26 Blender MCP tools — from executing Python code to querying scene objects, capturing screenshots, rendering, and inspecting blend files.

## Quick Start

```bash
go get github.com/gmlewis/PicoGK/sdk/go/blender
```

```go
package main

import (
    "context"
    "fmt"
    "log"

    "github.com/gmlewis/PicoGK/sdk/go/blender"
)

func main() {
    ctx := context.Background()

    // Launch the Blender MCP server
    // Assumes 'python -m blmcp' is available, or pass a custom path
    client, err := blender.NewClient(ctx, "")
    if err != nil {
        log.Fatal(err)
    }
    defer client.Close()

    // Execute Python code in Blender
    res, err := client.ExecuteBlenderCode(blender.ExecuteBlenderCodeRequest{
        Code: "import bpy; result = {'count': len(bpy.data.objects)}",
    })
    if err != nil {
        log.Fatal(err)
    }
    fmt.Println(res)

    // Get scene objects summary
    res, err = client.GetObjectsSummary(blender.GetObjectsSummaryRequest{})
    if err != nil {
        log.Fatal(err)
    }
    fmt.Println(res)

    // Capture a screenshot
    _, err = client.GetScreenshotOfWindowAsImage(blender.GetScreenshotOfWindowAsImageRequest{
        SizeLimitInBytes: intPtr(512 * 1024),
    })
    if err != nil {
        log.Fatal(err)
    }

    // Search the Blender Python API docs
    res, err = client.SearchAPIDocs(blender.SearchAPIDocsRequest{
        Query: "how to bake",
    })
    if err != nil {
        log.Fatal(err)
    }
    fmt.Println(res)
}

// Helper: create an int pointer
func intPtr(v int) *int { return &v }
```

## API Overview

The SDK exposes all 26 Blender MCP tools via request structs:

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
- A `XxxRequest` struct with typed fields (optional params are pointers)
- A `client.Xxx(req)` method returning `(string, error)`
- Full doc comments

## Architecture

The SDK launches the Blender MCP server as a subprocess and communicates via
JSON-RPC over stdio. The Blender MCP server must be installed separately, and
Blender must be running with the MCP addon enabled.

## Auto-Generation

This SDK is auto-generated from the Blender MCP server tool definitions by
`scripts/generate-go-blender-sdk.py`. To regenerate:

```bash
./scripts/generate-go-blender-sdk.py --verbose
```

**DO NOT EDIT** the generated files — changes will be overwritten.
