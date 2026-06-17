//
// SPDX-License-Identifier: Apache-2.0
//
// PicoGK is developed and maintained by LEAP 71 - © 2023-2026 by LEAP 71
// https://leap71.com
//
// LEAP 71 licenses this file to you under the Apache License, Version 2.0

using ModelContextProtocol.Server;
using System.ComponentModel;
using PicoGK;

namespace PicoGK.Mcp.Tools;

[McpServerToolType]
public static class IoTools
{
    [McpServerTool]
    [Description("Save a mesh to an STL file. The mesh is typically obtained from voxels_to_mesh. " +
        "Units are millimeters by default.")]
    public static string SaveStl(
        PicoGkSession session,
        [Description("ID of the mesh object")] string meshId,
        [Description("Full path for the output STL file")] string path,
        [Description("Units: MM, CM, M, FT, IN (default: MM)")] string units = "MM")
    {
        var (mesh, err) = session.SafeGet<Mesh>(meshId);
        if (err != null) return $"Error: {err}";

        var unit = units.ToUpperInvariant() switch
        {
            "CM" => Mesh.EStlUnit.CM,
            "M" => Mesh.EStlUnit.M,
            "FT" => Mesh.EStlUnit.FT,
            "IN" => Mesh.EStlUnit.IN,
            _ => Mesh.EStlUnit.MM
        };

        Directory.CreateDirectory(Path.GetDirectoryName(path) ?? ".");
        mesh.SaveToStlFile(path, unit);
        var info = new FileInfo(path);
        return $"Saved mesh '{meshId}' to {path} ({info.Length / 1024.0:F1} KB, {mesh.nTriangleCount()} triangles)";
    }

    [McpServerTool]
    [Description("Save voxels to an OpenVDB file. VDB files preserve the full voxel field data.")]
    public static string SaveVdb(
        PicoGkSession session,
        [Description("ID of the voxel object")] string voxelsId,
        [Description("Full path for the output VDB file")] string path,
        [Description("Optional name for the field inside the VDB file")] string? fieldName = null)
    {
        var (vox, err) = session.SafeGet<Voxels>(voxelsId);
        if (err != null) return $"Error: {err}";

        Directory.CreateDirectory(Path.GetDirectoryName(path) ?? ".");

        if (fieldName != null)
        {
            var vdb = new OpenVdbFile(session.Library);
            vdb.nAdd(vox, fieldName);
            vdb.SaveToFile(path);
        }
        else
        {
            vox.SaveToVdbFile(path);
        }

        var info = new FileInfo(path);
        return $"Saved voxels '{voxelsId}' to {path} ({info.Length / 1024.0:F1} KB)";
    }

    [McpServerTool]
    [Description("Load voxels from an OpenVDB file. Returns the object ID.")]
    public static string LoadVdb(
        PicoGkSession session,
        [Description("Full path to the VDB file")] string path,
        [Description("Optional field name to load (loads first field if not specified)")] string? fieldName = null,
        [Description("Optional ID to assign")] string? id = null)
    {
        if (!File.Exists(path))
            return $"Error: File not found: {path}";

        Voxels vox;
        if (fieldName != null)
        {
            var vdb = new OpenVdbFile(session.Library, path);
            vox = vdb.voxGet(fieldName);
        }
        else
        {
            vox = Voxels.voxFromVdbFile(session.Library, path);
        }

        return session.Register(vox, id, $"Loaded from {Path.GetFileName(path)}");
    }

    [McpServerTool]
    [Description("List all fields in a VDB file with their names, types, and indices. " +
        "Useful for inspecting multi-field VDB files before loading a specific field with load_vdb. " +
        "Returns field count and a table of index, name, type, and PicoGK compatibility.")]
    public static string ListVdbFields(
        PicoGkSession session,
        [Description("Full path to the VDB file")] string path)
    {
        if (!File.Exists(path))
            return $"Error: File not found: {path}";

        var vdb = new OpenVdbFile(session.Library, path);
        int n = vdb.nFieldCount();
        if (n == 0)
            return $"VDB file '{Path.GetFileName(path)}' contains no fields.";

        bool compatible = vdb.bIsPicoGKCompatible();
        float voxelSize = vdb.fPicoGKVoxelSizeMM();

        var lines = new List<string>
        {
            $"VDB file: {path}",
            $"  Fields: {n}",
            $"  PicoGK compatible: {compatible}",
            $"  Voxel size: {voxelSize}mm",
            "",
            "  Idx  Name                            Type",
            "  ---  ----                            ----"
        };

        for (int i = 0; i < n; i++)
        {
            string name = vdb.strFieldName(i);
            string type = vdb.strFieldType(i);
            lines.Add($"  {i,3}  {name,-30}  {type}");
        }

        return string.Join("\n", lines);
    }

    [McpServerTool]
    [Description("Vectorize voxels into 2D slice contours and save as SVG. " +
        "Each slice is written to its own file: <path>.NNNN.svg (zero-padded 4 digits). " +
        "Useful for 2D manufacturing or visualization. Returns the count of files written.")]
    public static string SaveSvg(
        PicoGkSession session,
        [Description("ID of the voxel object")] string voxelsId,
        [Description("Output path. The slice index is inserted before the extension: " +
            "'out.svg' -> 'out.0001.svg'; if no extension, '.NNNN.svg' is appended")] string path,
        [Description("Layer height in mm for slicing")] float layerHeight = 1.0f)
    {
        var (vox, err) = session.SafeGet<Voxels>(voxelsId);
        if (err != null) return $"Error: {err}";

        var slices = vox.oVectorize(layerHeight, false);
        if (slices.nCount() == 0)
            return $"Error: No slices produced from '{voxelsId}'.";

        // Compute a shared bounding box across all slices so they share scale/origin.
        var sharedBBox = new BBox2();
        for (int i = 0; i < slices.nCount(); i++)
        {
            var s = slices.oSliceAt(i);
            sharedBBox.Include(s.oBBox());
        }

        Directory.CreateDirectory(Path.GetDirectoryName(path) ?? ".");

        // Derive a path stem + extension: "dir/out.svg" -> ("dir/out", ".svg")
        // "dir/out" -> ("dir/out", "")  ;  "dir/out.foo.svg" -> ("dir/out.foo", ".svg")
        string stem = path;
        string ext = "";
        int dot = path.LastIndexOf('.');
        int slash = path.LastIndexOf(Path.DirectorySeparatorChar);
        if (dot > slash && dot >= 0)
        {
            stem = path[..dot];
            ext = path[dot..];
        }
        if (string.IsNullOrEmpty(ext))
            ext = ".svg";

        int written = 0;
        for (int i = 0; i < slices.nCount(); i++)
        {
            var slice = slices.oSliceAt(i);
            if (slice.bIsEmpty())
                continue;

            string numbered = $"{stem}.{i + 1:D4}{ext}";
            slice.SaveToSvgFile(numbered, true, sharedBBox);
            written++;
        }

        return $"Saved {written}/{slices.nCount()} slices to {stem}.NNNN{ext} " +
               $"(layer height {layerHeight}mm, shared bbox {sharedBBox.vecSize().X:F1}x{sharedBBox.vecSize().Y:F1}mm)";
    }

    [McpServerTool]
    [Description("Save voxels to a CLI (Common Layer Interface) file for 3D printing. " +
        "Vectorizes the voxel field into 2D layers and writes the CLI format. " +
        "Returns the file path and slice count.")]
    public static string SaveCli(
        PicoGkSession session,
        [Description("ID of the voxel object")] string voxelsId,
        [Description("Full path for the output CLI file")] string path,
        [Description("Layer height in mm for slicing (0 = use voxel size)")] float layerHeight = 0f,
        [Description("Format: 'FirstLayerWithContent' (default) or 'UseEmptyFirstLayer' " +
            "(adds an empty zero-height layer so readers can infer layer height)")] string format = "FirstLayerWithContent",
        [Description("If true, use absolute X/Y origin; if false (default), slices are " +
            "relative to the voxel field boundaries")] bool useAbsXYOrigin = false)
    {
        var (vox, err) = session.SafeGet<Voxels>(voxelsId);
        if (err != null) return $"Error: {err}";

        var eFormat = format.Equals("UseEmptyFirstLayer", StringComparison.OrdinalIgnoreCase)
            ? CliIo.EFormat.UseEmptyFirstLayer
            : CliIo.EFormat.FirstLayerWithContent;

        Directory.CreateDirectory(Path.GetDirectoryName(path) ?? ".");
        vox.SaveToCliFile(path, layerHeight, eFormat, useAbsXYOrigin);
        var info = new FileInfo(path);
        return $"Saved CLI to {path} ({info.Length / 1024.0:F1} KB, layer height " +
               $"{(layerHeight > 0 ? layerHeight : vox.lib.fVoxelSize)}mm)";
    }
}
