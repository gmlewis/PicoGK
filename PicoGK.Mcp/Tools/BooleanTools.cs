//
// SPDX-License-Identifier: Apache-2.0
//
// PicoGK is developed and maintained by LEAP 71 - © 2023-2026 by LEAP 71
// https://leap71.com
//
// LEAP 71 licenses this file to you under the Apache License, Version 2.0

using ModelContextProtocol.Server;
using System.ComponentModel;

namespace PicoGK.Mcp.Tools;

[McpServerToolType]
public static class BooleanTools
{
    [McpServerTool]
    [Description("Boolean UNION: combine two voxel objects. Both volumes are kept, overlapping regions are merged. Returns a new object ID.")]
    public static string BooleanAdd(
        PicoGkSession session,
        [Description("ID of first object")] string a,
        [Description("ID of second object")] string b,
        [Description("Optional ID for the result")] string? id = null)
    {
        var voxA = session.Get<Voxels>(a);
        var voxB = session.Get<Voxels>(b);
        var result = voxA + voxB;
        return session.Register(result, id, $"Union({a}, {b})");
    }

    [McpServerTool]
    [Description("Boolean SUBTRACTION: subtract voxels of B from A. Removes the volume of B from A. Returns a new object ID.")]
    public static string BooleanSubtract(
        PicoGkSession session,
        [Description("ID of the object to subtract FROM")] string a,
        [Description("ID of the object to subtract")] string b,
        [Description("Optional ID for the result")] string? id = null)
    {
        var voxA = session.Get<Voxels>(a);
        var voxB = session.Get<Voxels>(b);
        var result = voxA - voxB;
        return session.Register(result, id, $"Subtract({a}, {b})");
    }

    [McpServerTool]
    [Description("Boolean INTERSECTION: keep only the overlapping volume of two voxel objects. Returns a new object ID.")]
    public static string BooleanIntersect(
        PicoGkSession session,
        [Description("ID of first object")] string a,
        [Description("ID of second object")] string b,
        [Description("Optional ID for the result")] string? id = null)
    {
        var voxA = session.Get<Voxels>(a);
        var voxB = session.Get<Voxels>(b);
        var result = voxA & voxB;
        return session.Register(result, id, $"Intersect({a}, {b})");
    }

    [McpServerTool]
    [Description("Combine multiple voxel objects into one. All volumes are merged. Returns a new object ID.")]
    public static string BooleanAddAll(
        PicoGkSession session,
        [Description("List of object IDs to combine")] string[] objectIds,
        [Description("Optional ID for the result")] string? id = null)
    {
        var voxels = objectIds.Select(oid => session.Get<Voxels>(oid)).ToList();
        var first = voxels[0];
        for (int i = 1; i < voxels.Count; i++)
            first = first + voxels[i];
        return session.Register(first, id, $"CombineAll({string.Join(", ", objectIds)})");
    }
}
