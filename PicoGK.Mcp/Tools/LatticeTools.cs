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
public static class LatticeTools
{
    [McpServerTool]
    [Description("Create an empty lattice structure. Add beams and sphere nodes to build it, " +
        "then convert to voxels. Returns the object ID.")]
    public static string CreateLattice(
        PicoGkSession session,
        [Description("Optional ID to assign")] string? id = null)
    {
        var lattice = new Lattice(session.Library);
        return session.Register(lattice, id, "Empty lattice");
    }

    [McpServerTool]
    [Description("Add a tapered beam (strut) between two points in a lattice. " +
        "Each end has its own radius. Returns a confirmation.")]
    public static string LatticeAddBeam(
        PicoGkSession session,
        [Description("ID of the lattice object")] string latticeId,
        [Description("Start point X")] float x1,
        [Description("Start point Y")] float y1,
        [Description("Start point Z")] float z1,
        [Description("Start radius in mm")] float radius1,
        [Description("End point X")] float x2,
        [Description("End point Y")] float y2,
        [Description("End point Z")] float z2,
        [Description("End radius in mm")] float radius2,
        [Description("Use round caps (default true)")] bool roundCap = true)
    {
        var (lattice, err) = session.SafeGet<Lattice>(latticeId);
        if (err != null) return $"Error: {err}";

        lattice.AddBeam(
            new Vector3(x1, y1, z1), radius1,
            new Vector3(x2, y2, z2), radius2,
            roundCap);
        return $"Beam added to '{latticeId}': ({x1},{y1},{z1},r={radius1}) → ({x2},{y2},{z2},r={radius2})";
    }

    [McpServerTool]
    [Description("Add a sphere node at a point in a lattice. Returns a confirmation.")]
    public static string LatticeAddSphere(
        PicoGkSession session,
        [Description("ID of the lattice object")] string latticeId,
        [Description("Center X")] float x,
        [Description("Center Y")] float y,
        [Description("Center Z")] float z,
        [Description("Radius in mm")] float radius)
    {
        var (lattice, err) = session.SafeGet<Lattice>(latticeId);
        if (err != null) return $"Error: {err}";

        lattice.AddSphere(new Vector3(x, y, z), radius);
        return $"Sphere node added to '{latticeId}' at ({x},{y},{z}) r={radius}mm";
    }

    [McpServerTool]
    [Description("Convert a lattice to voxels. Renders the lattice beams and nodes " +
        "into a voxel field. Returns a new voxel object ID.")]
    public static string LatticeToVoxels(
        PicoGkSession session,
        [Description("ID of the lattice object")] string latticeId,
        [Description("Optional ID for the result")] string? id = null)
    {
        var (lattice, err) = session.SafeGet<Lattice>(latticeId);
        if (err != null) return $"Error: {err}";

        var voxels = new Voxels(lattice);
        return session.Register(voxels, id, $"Voxels from lattice '{latticeId}'");
    }
}
