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
        var (vox, err) = session.SafeGet<Voxels>(objectId);
        if (err != null) return $"Error: {err}";

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
        var (vox, err) = session.SafeGet<Voxels>(objectId);
        if (err != null) return $"Error: {err}";

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
        var (vox, err) = session.SafeGet<Voxels>(objectId);
        if (err != null) return $"Error: {err}";

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
        var (vox, err) = session.SafeGet<Voxels>(objectId);
        if (err != null) return $"Error: {err}";

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
        var (vox, err) = session.SafeGet<Voxels>(objectId);
        if (err != null) return $"Error: {err}";

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
        var (vox, err) = session.SafeGet<Voxels>(objectId);
        if (err != null) return $"Error: {err}";

        var result = vox.voxProjectZSlice(startZ, endZ);
        return session.Register(result, id, $"ProjectZ({objectId}, z={startZ}-{endZ}mm)");
    }

    [McpServerTool]
    [Description("Transform a voxel object by translating, rotating, and/or scaling it. " +
        "Rotations are applied first (around the object's origin), then translation. " +
        "Uses native PicoGK signed-distance-field re-rasterization (no expensive mesh " +
        "round-trip), so it is efficient for large voxel fields. " +
        "Returns a new object ID.")]
    public static string TransformVoxels(
        PicoGkSession session,
        [Description("ID of the source voxel object")] string objectId,
        [Description("Translation X in mm")] float translateX = 0,
        [Description("Translation Y in mm")] float translateY = 0,
        [Description("Translation Z in mm")] float translateZ = 0,
        [Description("Rotation around X axis in degrees (pitch)")] float rotateX = 0,
        [Description("Rotation around Y axis in degrees (yaw)")] float rotateY = 0,
        [Description("Rotation around Z axis in degrees (roll)")] float rotateZ = 0,
        [Description("Uniform scale factor (1.0 = no change). Applied before rotation/translation.")] float scale = 1.0f,
        [Description("Optional ID for the result")] string? id = null)
    {
        var (vox, err) = session.SafeGet<Voxels>(objectId);
        if (err != null) return $"Error: {err}";

        if (scale <= 0)
            return "Error: scale must be positive.";

        // Build the forward transformation matrix: scale → rotate(X/Y/Z) → translate.
        var mat = Matrix4x4.CreateScale(scale);
        if (rotateX != 0) mat *= Matrix4x4.CreateRotationX(rotateX * MathF.PI / 180f);
        if (rotateY != 0) mat *= Matrix4x4.CreateRotationY(rotateY * MathF.PI / 180f);
        if (rotateZ != 0) mat *= Matrix4x4.CreateRotationZ(rotateZ * MathF.PI / 180f);
        if (translateX != 0 || translateY != 0 || translateZ != 0)
            mat *= Matrix4x4.CreateTranslation(translateX, translateY, translateZ);

        // Identity: just duplicate.
        if (mat == Matrix4x4.Identity)
        {
            var dup = vox.voxDuplicate();
            return session.Register(dup, id, $"Transform({objectId}, identity)");
        }

        // Pure translation (no rotation, no scale change) is a common case.
        // PicoGK's ScalarField preserves the voxel grid topology, and we can
        // re-render into a new voxel field with a shifted bounding box — the SDF
        // sampling is exact for translations. We still go through the SDF path
        // below, which handles this efficiently.
        bool invertible = Matrix4x4.Invert(mat, out Matrix4x4 matInv);
        if (!invertible)
            return "Error: transformation matrix is not invertible.";

        // Extract a signed distance field from the source voxels (native VDB op,
        // no mesh round-trip). We then sample it through an inverse-transformed
        // query point to place the geometry in its new position.
        using var sdf = new ScalarField(vox);

        // Compute the transformed bounding box by transforming all 8 corners
        // of the source bounding box and taking the AABB of the result.
        vox.GetVoxelDimensions(out int ox, out int oy, out int oz,
                               out int sx, out int sy, out int sz);
        var srcMin = vox.lib.vecVoxelsToMm(ox, oy, oz);
        var srcMax = vox.lib.vecVoxelsToMm(ox + sx, oy + sy, oz + sz);
        var corners = new Vector3[8];
        corners[0] = new(srcMin.X, srcMin.Y, srcMin.Z);
        corners[1] = new(srcMax.X, srcMin.Y, srcMin.Z);
        corners[2] = new(srcMin.X, srcMax.Y, srcMin.Z);
        corners[3] = new(srcMax.X, srcMax.Y, srcMin.Z);
        corners[4] = new(srcMin.X, srcMin.Y, srcMax.Z);
        corners[5] = new(srcMax.X, srcMin.Y, srcMax.Z);
        corners[6] = new(srcMin.X, srcMax.Y, srcMax.Z);
        corners[7] = new(srcMax.X, srcMax.Y, srcMax.Z);

        var tMin = new Vector3(float.MaxValue);
        var tMax = new Vector3(float.MinValue);
        foreach (var c in corners)
        {
            var t = Vector3.Transform(c, mat);
            tMin = Vector3.Min(tMin, t);
            tMax = Vector3.Max(tMax, t);
        }

        // Add a small margin so the re-rasterized surface isn't clipped.
        float margin = vox.lib.fVoxelSize * 2;
        var outBounds = new BBox3(tMin - new Vector3(margin),
                                  tMax + new Vector3(margin));

        // Create the output voxel field and render the transformed SDF into it.
        // The IImplicit callback inverse-transforms each query point back into
        // the source SDF's coordinate space, so the geometry appears transformed.
        var transformedImplicit = new TransformedImplicit(sdf, matInv);
        var result = new Voxels(session.Library, transformedImplicit, outBounds);

        var desc = $"Transform({objectId}";
        if (scale != 1.0f) desc += $", s={scale}";
        if (rotateX != 0 || rotateY != 0 || rotateZ != 0)
            desc += $", rot=({rotateX},{rotateY},{rotateZ})";
        if (translateX != 0 || translateY != 0 || translateZ != 0)
            desc += $", t=({translateX},{translateY},{translateZ})";
        desc += ")";
        return session.Register(result, id, desc);
    }

    /// <summary>
    /// Wraps an IImplicit (SDF) and applies an inverse matrix to each query
    /// point before sampling, so the geometry appears transformed when
    /// rendered into a new voxel field.
    /// </summary>
    private sealed class TransformedImplicit : IImplicit
    {
        private readonly ScalarField _sdf;
        private readonly Matrix4x4 _matInv;

        public TransformedImplicit(ScalarField sdf, Matrix4x4 matInv)
        {
            _sdf = sdf;
            _matInv = matInv;
        }

        public float fSignedDistance(in Vector3 vec)
        {
            // Map the output-space query point back into the source SDF's space.
            var src = Vector3.Transform(vec, _matInv);
            return _sdf.fSignedDistance(src);
        }
    }
}
