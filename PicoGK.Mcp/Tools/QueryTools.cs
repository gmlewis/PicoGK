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
    [Description("Get the axis-aligned bounding box of any object. Returns min/max corners in mm. " +
        "Retries internally with exponential backoff if the object was just created/transformed " +
        "and the internal mesh conversion is not yet settled.")]
    public static string GetBoundingBox(
        PicoGkSession session,
        [Description("ID of the object to query")] string objectId)
    {
        if (!session.Exists(objectId))
            return $"Error: Object '{objectId}' not found. Use list_objects to see available objects.";

        try
        {
            BBox3 bbox;
            if (session.TryGet<Voxels>(objectId, out var vox))
            {
                bbox = session.RetryMeshQuery(() => vox.oCalculateBoundingBox(),
                    $"bounding box of '{objectId}'");
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
                return $"Error: Cannot get bounding box for object type of '{objectId}'.";
            }

            return $"Bounding Box of '{objectId}':\n" +
                   $"  Min: ({bbox.vecMin.X:F3}, {bbox.vecMin.Y:F3}, {bbox.vecMin.Z:F3})\n" +
                   $"  Max: ({bbox.vecMax.X:F3}, {bbox.vecMax.Y:F3}, {bbox.vecMax.Z:F3})\n" +
                   $"  Size: ({bbox.vecSize().X:F3}, {bbox.vecSize().Y:F3}, {bbox.vecSize().Z:F3}) mm";
        }
        catch (Exception ex)
        {
            return $"Error getting bounding box of '{objectId}': {ex.Message}";
        }
    }

    [McpServerTool]
    [Description("Calculate the volume and bounding box of a voxel object. " +
        "Retries internally with exponential backoff if the object was just created/transformed.")]
    public static string GetVolume(
        PicoGkSession session,
        [Description("ID of the voxel object")] string objectId)
    {
        var (vox, err) = session.SafeGet<Voxels>(objectId);
        if (err != null) return $"Error: {err}";

        try
        {
            float volume = 0;
            BBox3 bbox = new();
            session.RetryMeshQuery(() =>
            {
                vox.CalculateProperties(out volume, out bbox);
                return true;
            }, $"volume of '{objectId}'");

            return $"Volume of '{objectId}': {volume:F2} mm³\n" +
                   $"Bounding box: ({bbox.vecMin.X:F2}, {bbox.vecMin.Y:F2}, {bbox.vecMin.Z:F2}) " +
                   $"to ({bbox.vecMax.X:F2}, {bbox.vecMax.Y:F2}, {bbox.vecMax.Z:F2})";
        }
        catch (Exception ex)
        {
            return $"Error calculating volume of '{objectId}': {ex.Message}";
        }
    }

    [McpServerTool]
    [Description("Get information about a mesh: vertex count, triangle count, bounding box.")]
    public static string GetMeshInfo(
        PicoGkSession session,
        [Description("ID of the mesh object")] string objectId)
    {
        var (mesh, err) = session.SafeGet<Mesh>(objectId);
        if (err != null) return $"Error: {err}";

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
        var (vox, err) = session.SafeGet<Voxels>(objectId);
        if (err != null) return $"Error: {err}";

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
        var (vox, err) = session.SafeGet<Voxels>(objectId);
        if (err != null) return $"Error: {err}";

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
        var (vox, err) = session.SafeGet<Voxels>(objectId);
        if (err != null) return $"Error: {err}";

        var point = new Vector3(x, y, z);
        if (vox.bClosestPointOnSurface(point, out var closest))
        {
            return $"Closest point on '{objectId}' to ({x}, {y}, {z}):\n" +
                   $"  ({closest.X:F3}, {closest.Y:F3}, {closest.Z:F3})";
        }
        return $"Error: Could not find closest point on '{objectId}'.";
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
        if (!session.Exists(objectId))
            return $"Error: Object '{objectId}' not found.";

        session.Delete(objectId);
        return $"Deleted object '{objectId}'.";
    }

    [McpServerTool]
    [Description("Get the voxel dimensions (grid size) of a voxel object.")]
    public static string GetVoxelDimensions(
        PicoGkSession session,
        [Description("ID of the voxel object")] string objectId)
    {
        var (vox, err) = session.SafeGet<Voxels>(objectId);
        if (err != null) return $"Error: {err}";

        vox.GetVoxelDimensions(out int sx, out int sy, out int sz);
        return $"Voxel grid of '{objectId}': {sx} x {sy} x {sz} = {sx * sy * sz:N0} voxels";
    }

    [McpServerTool]
    [Description("Cast a ray from a point in a given direction and find where it hits the " +
        "surface of a voxel object. Useful for measuring wall thickness, checking bore " +
        "clearance, and probing internal geometry. Returns the hit point and the distance " +
        "from the origin, or an error if no intersection is found.")]
    public static string RayCast(
        PicoGkSession session,
        [Description("ID of the voxel object")] string objectId,
        [Description("Origin X of the ray")] float x,
        [Description("Origin Y of the ray")] float y,
        [Description("Origin Z of the ray")] float z,
        [Description("Ray direction X (need not be normalized)")] float dirX,
        [Description("Ray direction Y")] float dirY,
        [Description("Ray direction Z")] float dirZ)
    {
        var (vox, err) = session.SafeGet<Voxels>(objectId);
        if (err != null) return $"Error: {err}";

        var origin = new Vector3(x, y, z);
        var dirVec = new Vector3(dirX, dirY, dirZ);
        if (dirVec.LengthSquared() < 1e-12f)
            return "Error: ray direction must be non-zero.";

        var dirNorm = Vector3.Normalize(dirVec);

        if (!vox.bRayCastToSurface(origin, dirNorm, out var hit))
            return $"No ray-surface intersection found for '{objectId}' " +
                   $"from ({x},{y},{z}) in direction ({dirX},{dirY},{dirZ}).";

        float dist = Vector3.Distance(origin, hit);
        return $"Ray hit on '{objectId}':\n" +
               $"  Origin: ({x:F3}, {y:F3}, {z:F3})\n" +
               $"  Direction: ({dirNorm.X:F3}, {dirNorm.Y:F3}, {dirNorm.Z:F3})\n" +
               $"  Hit point: ({hit.X:F3}, {hit.Y:F3}, {hit.Z:F3})\n" +
               $"  Distance: {dist:F3} mm";
    }

    [McpServerTool]
    [Description("Cast a ray from a point in both +direction and -direction and report both " +
        "hit points and the total span between them. Ideal for measuring wall thickness: " +
        "place the origin inside the wall and shoot in any direction; the tool reports how " +
        "far the surface is in each direction and the total thickness.")]
    public static string MeasureThickness(
        PicoGkSession session,
        [Description("ID of the voxel object")] string objectId,
        [Description("Origin X (ideally inside the wall/material)")] float x,
        [Description("Origin Y")] float y,
        [Description("Origin Z")] float z,
        [Description("Measurement direction X (need not be normalized)")] float dirX,
        [Description("Measurement direction Y")] float dirY,
        [Description("Measurement direction Z")] float dirZ)
    {
        var (vox, err) = session.SafeGet<Voxels>(objectId);
        if (err != null) return $"Error: {err}";

        var origin = new Vector3(x, y, z);
        var dirVec = new Vector3(dirX, dirY, dirZ);
        if (dirVec.LengthSquared() < 1e-12f)
            return "Error: direction must be non-zero.";

        var dirNorm = Vector3.Normalize(dirVec);

        bool hitPos = vox.bRayCastToSurface(origin, dirNorm, out var hitP);
        bool hitNeg = vox.bRayCastToSurface(origin, -dirNorm, out var hitN);

        var lines = new List<string> { $"Thickness measurement on '{objectId}':" };
        lines.Add($"  Origin: ({x:F3}, {y:F3}, {z:F3})");
        lines.Add($"  Direction: ({dirNorm.X:F3}, {dirNorm.Y:F3}, {dirNorm.Z:F3})");

        if (hitPos)
        {
            float d = Vector3.Distance(origin, hitP);
            lines.Add($"  +dir hit: ({hitP.X:F3}, {hitP.Y:F3}, {hitP.Z:F3}) — {d:F3} mm");
        }
        else
        {
            lines.Add("  +dir hit: none (no surface found in positive direction)");
        }

        if (hitNeg)
        {
            float d = Vector3.Distance(origin, hitN);
            lines.Add($"  -dir hit: ({hitN.X:F3}, {hitN.Y:F3}, {hitN.Z:F3}) — {d:F3} mm");
        }
        else
        {
            lines.Add("  -dir hit: none (no surface found in negative direction)");
        }

        if (hitPos && hitNeg)
        {
            float thickness = Vector3.Distance(hitP, hitN);
            lines.Add($"  Total thickness: {thickness:F3} mm");
        }
        else
        {
            lines.Add("  Total thickness: N/A (one or both directions did not hit surface)");
        }

        return string.Join("\n", lines);
    }

    [McpServerTool]
    [Description("Create a duplicate (deep copy) of an existing object. " +
        "Works with voxel and mesh objects. Returns the new object ID.")]
    public static string DuplicateObject(
        PicoGkSession session,
        [Description("ID of the object to duplicate")] string objectId,
        [Description("Optional ID for the copy")] string? id = null)
    {
        if (!session.Exists(objectId))
            return $"Error: Object '{objectId}' not found. Use list_objects to see available objects.";

        if (session.TryGet<Voxels>(objectId, out var vox))
        {
            var dup = vox.voxDuplicate();
            return session.Register(dup, id, $"Duplicate of '{objectId}'");
        }

        if (session.TryGet<Mesh>(objectId, out var mesh))
        {
            // No native Mesh copy; rebuild by copying all triangles.
            var newMesh = new Mesh(session.Library);
            for (int i = 0; i < mesh.nTriangleCount(); i++)
            {
                mesh.GetTriangle(i, out var a, out var b, out var c);
                newMesh.nAddTriangle(a, b, c);
            }
            return session.Register(newMesh, id, $"Duplicate of '{objectId}'");
        }

        return $"Error: Cannot duplicate '{objectId}'. Only voxels and meshes are supported.";
    }

    [McpServerTool]
    [Description("Delete multiple objects from the session in one call. " +
        "Useful for cleaning up intermediate objects after a complex build. " +
        "Returns the count of objects actually deleted.")]
    public static string DeleteObjects(
        PicoGkSession session,
        [Description("List of object IDs to delete")] string[] objectIds,
        [Description("If true, delete ALL objects EXCEPT those in objectIds (keep-only mode). " +
            "Default false = delete the listed objects.")] bool keepOnly = false)
    {
        if (objectIds == null || objectIds.Length == 0)
        {
            if (!keepOnly)
                return "Error: objectIds list is empty. Provide at least one ID, " +
                       "or use keepOnly=true to delete everything.";
            // keepOnly=true with empty list = delete everything
        }

        if (keepOnly)
        {
            var keep = new HashSet<string>(objectIds);
            int n = session.DeleteAllExcept(keep);
            return $"Deleted {n} objects (kept {keep.Count}: {string.Join(", ", keep)}).";
        }
        else
        {
            int n = session.DeleteMany(objectIds);
            return $"Deleted {n}/{objectIds.Length} objects: {string.Join(", ", objectIds)}";
        }
    }
}
