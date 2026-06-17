//
// SPDX-License-Identifier: Apache-2.0
//
// PicoGK is developed and maintained by LEAP 71 - © 2023-2026 by LEAP 71
// https://leap71.com
//
// LEAP 71 licenses this file to you under the Apache License, Version 2.0

using ModelContextProtocol.Server;
using System.ComponentModel;
using System.Numerics;

namespace PicoGK.Mcp.Tools;

[McpServerToolType]
public static class TransformTools
{
    [McpServerTool]
    [Description("Offset a voxel surface outward (positive) or inward (negative) by a distance. " +
        "Use for thickening, thinning, or creating clearance. Returns a new object ID.")]
    public static string Offset(
        PicoGkSession session,
        [Description("ID of the source object")] string objectId,
        [Description("Offset distance in mm. Positive = expand, negative = shrink.")] float distance,
        [Description("Optional ID for the result")] string? id = null)
    {
        var vox = session.Get<Voxels>(objectId);
        var result = vox.voxOffset(distance);
        return session.Register(result, id, $"Offset({objectId}, {distance}mm)");
    }

    [McpServerTool]
    [Description("Smooth/round a voxel surface by applying triple offset. " +
        "Good for removing sharp edges. Returns a new object ID.")]
    public static string Smooth(
        PicoGkSession session,
        [Description("ID of the source object")] string objectId,
        [Description("Smoothing distance in mm. Larger = smoother.")] float distance,
        [Description("Optional ID for the result")] string? id = null)
    {
        var vox = session.Get<Voxels>(objectId);
        var result = vox.voxSmoothen(distance);
        return session.Register(result, id, $"Smooth({objectId}, {distance}mm)");
    }

    [McpServerTool]
    [Description("Trim a voxel object to fit within a bounding box. " +
        "Everything outside the box is removed. Returns a new object ID.")]
    public static string Trim(
        PicoGkSession session,
        [Description("ID of the source object")] string objectId,
        [Description("Minimum X of trim box")] float minX,
        [Description("Minimum Y of trim box")] float minY,
        [Description("Minimum Z of trim box")] float minZ,
        [Description("Maximum X of trim box")] float maxX,
        [Description("Maximum Y of trim box")] float maxY,
        [Description("Maximum Z of trim box")] float maxZ,
        [Description("Optional ID for the result")] string? id = null)
    {
        var vox = session.Get<Voxels>(objectId);
        var bbox = new BBox3(new Vector3(minX, minY, minZ), new Vector3(maxX, maxY, maxZ));
        var result = vox.voxTrim(bbox);
        return session.Register(result, id, $"Trim({objectId})");
    }

    [McpServerTool]
    [Description("Create a hollow shell from a voxel object. " +
        "Both positive and negative offsets are applied. Returns a new object ID.")]
    public static string Shell(
        PicoGkSession session,
        [Description("ID of the source object")] string objectId,
        [Description("Inner wall offset in mm (positive = thinner walls)")] float innerOffset,
        [Description("Outer wall offset in mm (positive = thicker walls)")] float outerOffset,
        [Description("Smoothing for the shell walls in mm (0 = no smoothing)")] float smooth = 0,
        [Description("Optional ID for the result")] string? id = null)
    {
        var vox = session.Get<Voxels>(objectId);
        var result = vox.voxShell(-innerOffset, outerOffset, smooth);
        return session.Register(result, id, $"Shell({objectId}, in={innerOffset}mm, out={outerOffset}mm)");
    }

    [McpServerTool]
    [Description("Fillets (rounds) the surface of a voxel object. " +
        "Same as smooth but semantically for rounding edges. Returns a new object ID.")]
    public static string Fillet(
        PicoGkSession session,
        [Description("ID of the source object")] string objectId,
        [Description("Fillet radius in mm")] float radius,
        [Description("Optional ID for the result")] string? id = null)
    {
        var vox = session.Get<Voxels>(objectId);
        var result = vox.voxFillet(radius);
        return session.Register(result, id, $"Fillet({objectId}, r={radius}mm)");
    }

    [McpServerTool]
    [Description("Project voxels onto a Z-plane (top-down silhouette). " +
        "Useful for creating 2D cross-sections. Returns a new object ID.")]
    public static string ProjectZSlice(
        PicoGkSession session,
        [Description("ID of the source object")] string objectId,
        [Description("Start Z position in mm")] float startZ,
        [Description("End Z position in mm")] float endZ,
        [Description("Optional ID for the result")] string? id = null)
    {
        var vox = session.Get<Voxels>(objectId);
        var result = vox.voxProjectZSlice(startZ, endZ);
        return session.Register(result, id, $"ProjectZ({objectId}, z={startZ}-{endZ}mm)");
    }
}
