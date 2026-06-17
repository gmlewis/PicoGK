//
// SPDX-License-Identifier: Apache-2.0
//
// PicoGK is developed and maintained by LEAP 71 - © 2023-2026 by LEAP 71
// https://leap71.com
//
// LEAP 71 licenses this file to you under the Apache License, Version 2.0

using ModelContextProtocol.Server;
using SkiaSharp;
using System.ComponentModel;
using System.Numerics;

namespace PicoGK.Mcp.Tools;

[McpServerToolType]
public static class RenderTools
{
    [McpServerTool]
    [Description("Render an object to a PNG image using an isometric projection with Lambertian " +
        "shading. The agent can use this to visually inspect geometry. " +
        "Returns the file path of the rendered image.")]
    public static string RenderToImage(
        PicoGkSession session,
        [Description("ID of the object to render (voxels or mesh)")] string objectId,
        [Description("Full path for the output PNG file")] string path,
        [Description("Image width in pixels")] int width = 800,
        [Description("Image height in pixels")] int height = 600,
        [Description("Background color as hex (default: white)")] string backgroundColor = "#FFFFFF",
        [Description("Object color as hex (default: steel blue)")] string objectColor = "#4682B4")
    {
        if (!session.Exists(objectId))
            return $"Error: Object '{objectId}' not found. Use list_objects to see available objects.";

        BBox3 bbox;
        Mesh? mesh = null;

        if (session.TryGet<Voxels>(objectId, out var vox))
        {
            mesh = vox.mshAsMesh();
            bbox = vox.oCalculateBoundingBox();
        }
        else if (session.TryGet<Mesh>(objectId, out var m))
        {
            mesh = m;
            bbox = m.oBoundingBox();
        }
        else
        {
            return $"Error: Cannot render object '{objectId}'. Only voxels and meshes are supported.";
        }

        if (mesh.nTriangleCount() == 0)
            return $"Error: Object '{objectId}' has no triangles to render.";

        Directory.CreateDirectory(Path.GetDirectoryName(path) ?? ".");

        using var surface = SKSurface.Create(new SKImageInfo(width, height));
        var canvas = surface.Canvas;

        var bgClr = SKColor.Parse(backgroundColor);
        var baseClr = SKColor.Parse(objectColor);
        canvas.Clear(bgClr);

        var size = bbox.vecSize();
        float maxDim = Math.Max(size.X, Math.Max(size.Y, size.Z));
        if (maxDim < 1e-6f)
            return $"Error: Object '{objectId}' has zero size.";

        float scale = Math.Min(width, height) * 0.7f / maxDim;
        var center = bbox.vecCenter();

        // Isometric projection: rotate around Y by 45°, then around X by 30°.
        float cosA = MathF.Cos(MathF.PI / 6);
        float sinA = MathF.Sin(MathF.PI / 6);
        float cosB = MathF.Cos(MathF.PI / 4);
        float sinB = MathF.Sin(MathF.PI / 4);

        // Light direction in world space (upper-front-left), normalized.
        var lightDir = Vector3.Normalize(new Vector3(-0.5f, 0.8f, -0.4f));
        const float ambient = 0.35f;

        // Project a world point to screen, also return the projected Z (depth).
        (SKPoint pt, float depth) Project(Vector3 p)
        {
            var shifted = p - center;
            float rx = shifted.X * cosB - shifted.Z * sinB;
            float rz = shifted.X * sinB + shifted.Z * cosB;
            float ry = shifted.Y * cosA - rz * sinA;
            float projZ = shifted.Y * sinA + rz * cosA;

            return (new SKPoint(
                width / 2f + rx * scale,
                height / 2f - ry * scale), projZ);
        }

        var strokePaint = new SKPaint
        {
            Color = SKColor.Parse("#000000").WithAlpha(80),
            Style = SKPaintStyle.Stroke,
            StrokeWidth = 0.5f,
            IsAntialias = true,
        };

        // Extract base RGB once for shading.
        byte r0 = baseClr.Red, g0 = baseClr.Green, b0 = baseClr.Blue;

        var triCount = mesh.nTriangleCount();
        var triangles = new List<(SKPoint p0, SKPoint p1, SKPoint p2, float depth, byte r, byte g, byte b)>(triCount);

        for (int i = 0; i < triCount; i++)
        {
            mesh.GetTriangle(i, out var v0, out var v1, out var v2);

            // Face normal (not normalized per-triangle is fine for back-face culling;
            // we normalize for shading).
            var n = Vector3.Cross(v1 - v0, v2 - v0);
            float area2 = n.Length();
            if (area2 < 1e-9f)
                continue; // degenerate

            // Back-face culling: skip triangles facing away from the camera.
            // Camera in world space looks down -Y after the isometric rotation;
            // a face is visible if its normal has a positive Y component after the
            // same Y-rotation we apply in Project. Equivalently, project the normal
            // and test the projected Z sign. We reuse the projection math.
            float nrx = n.X * cosB - n.Z * sinB;
            float nrz = n.X * sinB + n.Z * cosB;
            float nry = n.Y * cosA - nrz * sinA;
            // nry > 0 means the face points toward the camera (we negate Y for screen).
            if (nry <= 0)
                continue;

            var normal = n / area2;
            float lambert = Math.Max(0f, Vector3.Dot(normal, lightDir));
            float intensity = ambient + (1f - ambient) * lambert;

            byte sr = (byte)Math.Clamp(r0 * intensity, 0, 255);
            byte sg = (byte)Math.Clamp(g0 * intensity, 0, 255);
            byte sb = (byte)Math.Clamp(b0 * intensity, 0, 255);

            var (p0, d0) = Project(v0);
            var (p1, d1) = Project(v1);
            var (p2, d2) = Project(v2);
            float depth = (d0 + d1 + d2) / 3f;

            triangles.Add((p0, p1, p2, depth, sr, sg, sb));
        }

        // Painter's algorithm: far-to-near.
        var sorted = triangles.OrderBy(t => t.depth).ToList();

        foreach (var (p0, p1, p2, _, r, g, b) in sorted)
        {
            using var triPath = new SKPath();
            triPath.MoveTo(p0);
            triPath.LineTo(p1);
            triPath.LineTo(p2);
            triPath.Close();
            using var fillPaint = new SKPaint
            {
                Color = new SKColor(r, g, b),
                Style = SKPaintStyle.Fill,
                IsAntialias = true,
            };
            canvas.DrawPath(triPath, fillPaint);
            canvas.DrawPath(triPath, strokePaint);
        }

        using var image = surface.Snapshot();
        using var data = image.Encode(SKEncodedImageFormat.Png, 95);
        using var stream = File.OpenWrite(path);
        data.SaveTo(stream);

        return $"Rendered '{objectId}' to {path} ({width}x{height}, {triCount} triangles, " +
               $"Lambertian-shaded isometric view)";
    }

    [McpServerTool]
    [Description("Render a Z-slice of a voxel object to a PNG image. " +
        "Shows the cross-section at a specific height. Returns the file path.")]
    public static string RenderSlice(
        PicoGkSession session,
        [Description("ID of the voxel object")] string voxelsId,
        [Description("Z position in mm")] float zPosition,
        [Description("Full path for the output PNG file")] string path,
        [Description("Slice mode: Sdf, Bw, or Antialiased (default: Antialiased)")] string mode = "Antialiased")
    {
        var err = session.ValidateId(voxelsId, typeof(Voxels));
        if (err != null) return $"Error: {err}";

        var vox = session.Get<Voxels>(voxelsId);

        var sliceMode = mode.ToLowerInvariant() switch
        {
            "sd" or "sdf" or "signeddistance" => Voxels.ESliceMode.SignedDistance,
            "bw" or "blackwhite" => Voxels.ESliceMode.BlackWhite,
            _ => Voxels.ESliceMode.Antialiased
        };

        var img = vox.imgAllocateSlice(out _, Voxels.ESliceAxis.Z);
        vox.GetInterpolatedVoxelSlice(zPosition, ref img, sliceMode);

        Directory.CreateDirectory(Path.GetDirectoryName(path) ?? ".");
        img.SavePng(path, 95);

        return $"Rendered Z={zPosition}mm slice of '{voxelsId}' to {path}";
    }
}
