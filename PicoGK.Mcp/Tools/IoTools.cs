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
    [Description("Vectorize voxels into 2D slice contours and save as SVG. " +
        "Useful for 2D manufacturing or visualization.")]
    public static string SaveSvg(
        PicoGkSession session,
        [Description("ID of the voxel object")] string voxelsId,
        [Description("Full path for the output SVG file")] string path,
        [Description("Layer height in mm for slicing")] float layerHeight = 1.0f)
    {
        var (vox, err) = session.SafeGet<Voxels>(voxelsId);
        if (err != null) return $"Error: {err}";

        var slices = vox.oVectorize(layerHeight, false);

        Directory.CreateDirectory(Path.GetDirectoryName(path) ?? ".");
        var sliceList = new List<PolySlice>();
        for (int i = 0; i < slices.nCount(); i++)
            sliceList.Add(slices.oSliceAt(i));

        var stack = new PolySliceStack(sliceList);
        stack.oSliceAt(0).SaveToSvgFile(path, true);

        return $"Saved {slices.nCount()} slices to SVG: {path}";
    }
}
