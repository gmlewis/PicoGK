//
// SPDX-License-Identifier: Apache-2.0
//
// PicoGK ("peacock") is a compact software kernel for computational geometry,
// specifically for use in Computational Engineering Models (CEM).
//
// For more information, please visit https://picogk.org
//
// PicoGK is developed and maintained by LEAP 71 - © 2023-2026 by LEAP 71
// https://leap71.com
//
// LEAP 71 licenses this file to you under the Apache License, Version 2.0
// (the "License"); you may not use this file except in compliance with the
// License. You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, SOFTWARE IS
// PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED.

using ModelContextProtocol.Server;
using System.ComponentModel;

namespace PicoGK.Mcp.Tools;

[McpServerToolType]
public static class SessionTools
{
    [McpServerTool]
    [Description("Initialize the PicoGK geometry kernel. Must be called before any other tool. " +
        "Sets the voxel resolution in millimeters. Smaller values = higher resolution but more memory. " +
        "Typical range: 0.1mm (fine) to 5.0mm (coarse).")]
    public static string PicogkInit(
        PicoGkSession session,
        [Description("Voxel size in millimeters. Controls resolution. Use 0.5 for general purpose, 0.1 for fine detail, 2.0+ for large parts.")]
        float voxelSizeMM = 0.5f)
    {
        try
        {
            if (session.IsInitialized)
                return $"PicoGK already initialized with voxel size {session.VoxelSizeMM}mm. " +
                       "Call picogk_shutdown first to reinitialize.";

            if (voxelSizeMM <= 0)
                return "Error: voxelSizeMM must be positive.";

            session.Initialize(voxelSizeMM);
            return $"PicoGK initialized. Voxel size: {voxelSizeMM}mm. " +
                   $"Library version: {Library.strVersion()}. " +
                   "You can now create geometry objects.";
        }
        catch (Exception ex)
        {
            return $"Error initializing PicoGK: {ex.Message}\n" +
                   "Make sure the native library (picogk.26.2) and its dependencies " +
                   "(libboost_iostreams, etc.) are in the same directory as PicoGK.Mcp.";
        }
    }

    [McpServerTool]
    [Description("Get information about the PicoGK library and current session state. " +
        "Returns version, memory usage, and counts of allocated objects.")]
    public static string PicogkInfo(PicoGkSession session)
    {
        if (!session.IsInitialized)
            return "PicoGK is not initialized. Call picogk_init first.";

        var lib = session.Library;
        var objects = session.ListObjects();

        return $"PicoGK Info:\n" +
               $"  Version: {Library.strVersion()}\n" +
               $"  Voxel size: {session.VoxelSizeMM}mm\n" +
               $"  Memory: {lib.nTotalMemUsage() / 1024.0 / 1024.0:F1} MB\n" +
               $"  Objects: {objects.Count}\n" +
               $"    Meshes: {lib.nMeshesAllocated()}\n" +
               $"    Voxels: {lib.nVoxelsAllocated()}\n" +
               $"    Lattices: {lib.nLatticesAllocated()}\n" +
               $"    PolyLines: {lib.nPolyLinesAllocated()}\n" +
               $"    ScalarFields: {lib.nScalarFieldsAllocated()}\n" +
               $"    VectorFields: {lib.nVectorFieldsAllocated()}";
    }

    [McpServerTool]
    [Description("Shut down the PicoGK session and release all resources. " +
        "All object references become invalid after this call.")]
    public static string PicogkShutdown(PicoGkSession session)
    {
        try
        {
            if (!session.IsInitialized)
                return "PicoGK is not initialized.";

            var count = session.ListObjects().Count;
            session.Dispose();
            return $"PicoGK shut down. Released {count} objects.";
        }
        catch (Exception ex)
        {
            return $"Error during shutdown: {ex.Message}";
        }
    }
}
