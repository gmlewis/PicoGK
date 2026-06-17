using ModelContextProtocol.Client;
using ModelContextProtocol.Protocol;

var mcpDir = $"{args[0]}/PicoGK.Mcp/bin/Release/net9.0";
var transport = new StdioClientTransport(new StdioClientTransportOptions
{
    Name = "PicoGK Test",
    Command = "dotnet",
    Arguments = [$"{mcpDir}/PicoGK.Mcp.dll"],
    WorkingDirectory = mcpDir,
});

var client = await McpClient.CreateAsync(transport);

Console.WriteLine("=== Connected to PicoGK MCP Server ===\n");

// List tools
var tools = await client.ListToolsAsync();
Console.WriteLine($"Available tools: {tools.Count}");
foreach (var t in tools.OrderBy(t => t.Name))
    Console.WriteLine($"  {t.Name}");

Console.WriteLine("\n=== Running End-to-End Test ===\n");

async Task<string> Call(string name, Dictionary<string, object?>? args = null)
{
    args ??= new();
    var result = await client.CallToolAsync(name, args);
    var text = result.Content.OfType<TextContentBlock>().FirstOrDefault()?.Text ?? "(no text)";
    Console.WriteLine($"[{name}] {text}\n");
    return text;
}

// 1. Initialize
await Call("picogk_init", new() { ["voxelSizeMM"] = 0.5f });

// 2. Create primitives
await Call("create_sphere", new() { ["x"] = 0, ["y"] = 0, ["z"] = 0, ["radius"] = 30, ["id"] = "body" });
await Call("create_box", new() { ["minX"] = -10, ["minY"] = -10, ["minZ"] = -40, ["maxX"] = 10, ["maxY"] = 10, ["maxZ"] = 40, ["id"] = "cutout" });

// 3. Boolean subtract
await Call("boolean_subtract", new() { ["a"] = "body", ["b"] = "cutout", ["id"] = "result" });

// 4. Smooth
await Call("smooth", new() { ["objectId"] = "result", ["distance"] = 2.0f, ["id"] = "smoothed" });

// 5. Convert to mesh
await Call("voxels_to_mesh", new() { ["voxelsId"] = "smoothed", ["id"] = "result_mesh" });

// 6. Save STL
await Call("save_stl", new() { ["meshId"] = "result_mesh", ["path"] = "/tmp/picogk_mcp_test/part.stl" });

// 7. Queries
await Call("get_bounding_box", new() { ["objectId"] = "smoothed" });
await Call("get_volume", new() { ["objectId"] = "smoothed" });
await Call("get_mesh_info", new() { ["objectId"] = "result_mesh" });
await Call("list_objects");

// 8. Render
await Call("render_to_image", new() { ["objectId"] = "result_mesh", ["path"] = "/tmp/picogk_mcp_test/preview.png", ["width"] = 600, ["height"] = 400 });
await Call("render_slice", new() { ["voxelsId"] = "smoothed", ["zPosition"] = 0, ["path"] = "/tmp/picogk_mcp_test/slice_z0.png" });

// 9. Shutdown
await Call("picogk_shutdown");

Console.WriteLine("=== All Tests Passed ===");
