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
    [Description("Render an object to a PNG image using a simple isometric projection. " +
        "The agent can use this to visually inspect geometry. " +
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
            return $"Cannot render object '{objectId}'. Only voxels and meshes are supported.";
        }

        if (mesh.nTriangleCount() == 0)
            return $"Object '{objectId}' has no triangles to render.";

        Directory.CreateDirectory(Path.GetDirectoryName(path) ?? ".");

        using var surface = SKSurface.Create(new SKImageInfo(width, height));
        var canvas = surface.Canvas;

        var bgClr = SKColor.Parse(backgroundColor);
        var objClr = SKColor.Parse(objectColor);
        canvas.Clear(bgClr);

        var size = bbox.vecSize();
        float maxDim = Math.Max(size.X, Math.Max(size.Y, size.Z));
        if (maxDim < 1e-6f)
            return $"Object '{objectId}' has zero size.";

        float scale = Math.Min(width, height) * 0.7f / maxDim;
        var center = bbox.vecCenter();

        float cosA = MathF.Cos(MathF.PI / 6);
        float sinA = MathF.Sin(MathF.PI / 6);
        float cosB = MathF.Cos(MathF.PI / 4);
        float sinB = MathF.Sin(MathF.PI / 4);

        SKPoint Project(Vector3 p)
        {
            var shifted = p - center;
            float rx = shifted.X * cosB - shifted.Z * sinB;
            float rz = shifted.X * sinB + shifted.Z * cosB;
            float ry = shifted.Y * cosA - rz * sinA;
            float projZ = shifted.Y * sinA + rz * cosA;

            return new SKPoint(
                width / 2f + rx * scale,
                height / 2f - ry * scale);
        }

        var paint = new SKPaint
        {
            Color = objClr,
            Style = SKPaintStyle.Fill,
            IsAntialias = true,
        };

        var strokePaint = new SKPaint
        {
            Color = objClr.WithAlpha(200),
            Style = SKPaintStyle.Stroke,
            StrokeWidth = 0.5f,
            IsAntialias = true,
        };

        var triCount = mesh.nTriangleCount();
        var triangles = new List<(SKPoint p0, SKPoint p1, SKPoint p2, float depth)>(triCount);

        for (int i = 0; i < triCount; i++)
        {
            mesh.GetTriangle(i, out var v0, out var v1, out var v2);
            var p0 = Project(v0);
            var p1 = Project(v1);
            var p2 = Project(v2);
            float depth = (v0.Y + v1.Y + v2.Y) / 3f;
            triangles.Add((p0, p1, p2, depth));
        }

        var sorted = triangles.OrderBy(t => t.depth).ToList();

        foreach (var (p0, p1, p2, _) in sorted)
        {
            using var triPath = new SKPath();
            triPath.MoveTo(p0);
            triPath.LineTo(p1);
            triPath.LineTo(p2);
            triPath.Close();
            canvas.DrawPath(triPath, paint);
            canvas.DrawPath(triPath, strokePaint);
        }

        using var image = surface.Snapshot();
        using var data = image.Encode(SKEncodedImageFormat.Png, 95);
        using var stream = File.OpenWrite(path);
        data.SaveTo(stream);

        return $"Rendered '{objectId}' to {path} ({width}x{height}, {triCount} triangles, depth-sorted isometric view)";
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
