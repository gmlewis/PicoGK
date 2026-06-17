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
public static class QueryTools
{
    [McpServerTool]
    [Description("Get the axis-aligned bounding box of any object. Returns min/max corners in mm.")]
    public static string GetBoundingBox(
        PicoGkSession session,
        [Description("ID of the object to query")] string objectId)
    {
        BBox3 bbox;
        if (session.TryGet<Voxels>(objectId, out var vox))
        {
            bbox = vox.oCalculateBoundingBox();
        }
        else if (session.TryGet<Mesh>(objectId, out var mesh))
        {
            bbox = mesh.oBoundingBox();
        }
        else if (session.TryGet<PolyLine>(objectId, out var poly))
        {
            bbox = poly.oBoundingBox();
        }
        else
        {
            return $"Cannot get bounding box for object type of '{objectId}'.";
        }

        return $"Bounding Box of '{objectId}':\n" +
               $"  Min: ({bbox.vecMin.X:F3}, {bbox.vecMin.Y:F3}, {bbox.vecMin.Z:F3})\n" +
               $"  Max: ({bbox.vecMax.X:F3}, {bbox.vecMax.Y:F3}, {bbox.vecMax.Z:F3})\n" +
               $"  Size: ({bbox.vecSize().X:F3}, {bbox.vecSize().Y:F3}, {bbox.vecSize().Z:F3}) mm";
    }

    [McpServerTool]
    [Description("Calculate the volume and bounding box of a voxel object.")]
    public static string GetVolume(
        PicoGkSession session,
        [Description("ID of the voxel object")] string objectId)
    {
        var vox = session.Get<Voxels>(objectId);
        vox.CalculateProperties(out float volume, out BBox3 bbox);
        return $"Volume of '{objectId}': {volume:F2} mm³\n" +
               $"Bounding box: ({bbox.vecMin.X:F2}, {bbox.vecMin.Y:F2}, {bbox.vecMin.Z:F2}) " +
               $"to ({bbox.vecMax.X:F2}, {bbox.vecMax.Y:F2}, {bbox.vecMax.Z:F2})";
    }

    [McpServerTool]
    [Description("Get information about a mesh: vertex count, triangle count, bounding box.")]
    public static string GetMeshInfo(
        PicoGkSession session,
        [Description("ID of the mesh object")] string objectId)
    {
        var mesh = session.Get<Mesh>(objectId);
        var bbox = mesh.oBoundingBox();
        return $"Mesh '{objectId}':\n" +
               $"  Vertices: {mesh.nVertexCount()}\n" +
               $"  Triangles: {mesh.nTriangleCount()}\n" +
               $"  BBox: ({bbox.vecMin.X:F2}, {bbox.vecMin.Y:F2}, {bbox.vecMin.Z:F2}) " +
               $"to ({bbox.vecMax.X:F2}, {bbox.vecMax.Y:F2}, {bbox.vecMax.Z:F2})";
    }

    [McpServerTool]
    [Description("Check if a 3D point is inside a voxel object.")]
    public static string PointInside(
        PicoGkSession session,
        [Description("ID of the voxel object")] string objectId,
        [Description("X coordinate")] float x,
        [Description("Y coordinate")] float y,
        [Description("Z coordinate")] float z)
    {
        var vox = session.Get<Voxels>(objectId);
        var point = new Vector3(x, y, z);
        bool inside = vox.bIsInside(point);
        return $"Point ({x}, {y}, {z}) is {(inside ? "INSIDE" : "OUTSIDE")} '{objectId}'.";
    }

    [McpServerTool]
    [Description("Get the surface normal vector at a point on a voxel object's surface.")]
    public static string SurfaceNormal(
        PicoGkSession session,
        [Description("ID of the voxel object")] string objectId,
        [Description("X coordinate")] float x,
        [Description("Y coordinate")] float y,
        [Description("Z coordinate")] float z)
    {
        var vox = session.Get<Voxels>(objectId);
        var point = new Vector3(x, y, z);
        var normal = vox.vecSurfaceNormal(point);
        return $"Surface normal at ({x}, {y}, {z}) on '{objectId}':\n" +
               $"  ({normal.X:F4}, {normal.Y:F4}, {normal.Z:F4})";
    }

    [McpServerTool]
    [Description("Find the closest point on a voxel object's surface to a given point.")]
    public static string ClosestPoint(
        PicoGkSession session,
        [Description("ID of the voxel object")] string objectId,
        [Description("X coordinate of query point")] float x,
        [Description("Y coordinate of query point")] float y,
        [Description("Z coordinate of query point")] float z)
    {
        var vox = session.Get<Voxels>(objectId);
        var point = new Vector3(x, y, z);
        if (vox.bClosestPointOnSurface(point, out var closest))
        {
            return $"Closest point on '{objectId}' to ({x}, {y}, {z}):\n" +
                   $"  ({closest.X:F3}, {closest.Y:F3}, {closest.Z:F3})";
        }
        return $"Could not find closest point on '{objectId}'.";
    }

    [McpServerTool]
    [Description("List all objects in the current session with their IDs, types, and descriptions.")]
    public static string ListObjects(PicoGkSession session)
    {
        if (!session.IsInitialized)
            return "PicoGK is not initialized. Call picogk_init first.";

        var objects = session.ListObjects();
        if (objects.Count == 0)
            return "No objects in session. Use create_* tools to add geometry.";

        var lines = new List<string> { $"Objects ({objects.Count}):" };
        foreach (var obj in objects)
        {
            lines.Add($"  [{obj.Id}] {obj.Type}: {obj.Description}");
        }
        return string.Join("\n", lines);
    }

    [McpServerTool]
    [Description("Delete an object from the session. Frees memory and removes the object from the registry.")]
    public static string DeleteObject(
        PicoGkSession session,
        [Description("ID of the object to delete")] string objectId)
    {
        if (session.Delete(objectId))
            return $"Deleted object '{objectId}'.";
        return $"Object '{objectId}' not found.";
    }

    [McpServerTool]
    [Description("Get the voxel dimensions (grid size) of a voxel object.")]
    public static string GetVoxelDimensions(
        PicoGkSession session,
        [Description("ID of the voxel object")] string objectId)
    {
        var vox = session.Get<Voxels>(objectId);
        vox.GetVoxelDimensions(out int sx, out int sy, out int sz);
        return $"Voxel grid of '{objectId}': {sx} x {sy} x {sz} = {sx * sy * sz:N0} voxels";
    }
}
