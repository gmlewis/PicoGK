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
public static class PrimitiveTools
{
    [McpServerTool]
    [Description("Create a sphere voxel object. Returns the object ID.")]
    public static string CreateSphere(
        PicoGkSession session,
        [Description("X coordinate of center in mm")] float x,
        [Description("Y coordinate of center in mm")] float y,
        [Description("Z coordinate of center in mm")] float z,
        [Description("Radius in mm")] float radius,
        [Description("Optional ID to assign to this object")] string? id = null)
    {
        try
        {
            var sphere = Voxels.voxSphere(session.Library, new Vector3(x, y, z), radius);
            return session.Register(sphere, id, $"Sphere r={radius}mm at ({x},{y},{z})");
        }
        catch (Exception ex)
        {
            return $"Error creating sphere: {ex.Message}";
        }
    }

    [McpServerTool]
    [Description("Create a box (axis-aligned cuboid) from minimum and maximum corner coordinates. Returns the object ID.")]
    public static string CreateBox(
        PicoGkSession session,
        [Description("Minimum X")] float minX,
        [Description("Minimum Y")] float minY,
        [Description("Minimum Z")] float minZ,
        [Description("Maximum X")] float maxX,
        [Description("Maximum Y")] float maxY,
        [Description("Maximum Z")] float maxZ,
        [Description("Optional ID to assign to this object")] string? id = null)
    {
        try
        {
            var bbox = new BBox3(new Vector3(minX, minY, minZ), new Vector3(maxX, maxY, maxZ));
            var mesh = Utils.mshCreateCube(session.Library, bbox);
            var voxels = new Voxels(mesh);
            return session.Register(voxels, id, $"Box ({minX},{minY},{minZ})-({maxX},{maxY},{maxZ})");
        }
        catch (Exception ex)
        {
            return $"Error creating box: {ex.Message}";
        }
    }

    [McpServerTool]
    [Description("Create a cylinder along the Z axis. Returns the object ID.")]
    public static string CreateCylinder(
        PicoGkSession session,
        [Description("X coordinate of center")] float x,
        [Description("Y coordinate of center")] float y,
        [Description("Z coordinate of bottom center")] float z,
        [Description("Radius in mm")] float radius,
        [Description("Height in mm (extends upward along +Z)")] float height,
        [Description("Optional ID to assign")] string? id = null)
    {
        try
        {
            var bottom = new Vector3(x, y, z);
            var top = new Vector3(x, y, z + height);

            var sphereBottom = Voxels.voxSphere(session.Library, bottom, radius);
            var sphereTop = Voxels.voxSphere(session.Library, top, radius);
            var beam = sphereBottom + sphereTop;
            var lat = new Lattice(session.Library);
            lat.AddBeam(bottom, radius, top, radius);
            var latVoxels = new Voxels(lat);
            var voxels = beam + latVoxels;

            return session.Register(voxels, id, $"Cylinder r={radius}mm h={height}mm at ({x},{y},{z})");
        }
        catch (Exception ex)
        {
            return $"Error creating cylinder: {ex.Message}";
        }
    }

    [McpServerTool]
    [Description("Create a capsule (a sphere-swept line segment). Returns the object ID.")]
    public static string CreateCapsule(
        PicoGkSession session,
        [Description("Start point X")] float x1,
        [Description("Start point Y")] float y1,
        [Description("Start point Z")] float z1,
        [Description("End point X")] float x2,
        [Description("End point Y")] float y2,
        [Description("End point Z")] float z2,
        [Description("Radius in mm")] float radius,
        [Description("Optional ID to assign")] string? id = null)
    {
        try
        {
            var vox = Voxels.voxLatticeBeam(session.Library,
                new Vector3(x1, y1, z1), radius,
                new Vector3(x2, y2, z2), radius);
            return session.Register(vox, id,
                $"Capsule r={radius}mm ({x1},{y1},{z1})-({x2},{y2},{z2})");
        }
        catch (Exception ex)
        {
            return $"Error creating capsule: {ex.Message}";
        }
    }

    [McpServerTool]
    [Description("Create a torus (donut shape) by revolving a circle around the Z axis. Returns the object ID.")]
    public static string CreateTorus(
        PicoGkSession session,
        [Description("Major radius (distance from center to tube center) in mm")] float majorRadius,
        [Description("Minor radius (tube radius) in mm")] float minorRadius,
        [Description("X offset of center")] float x = 0,
        [Description("Y offset of center")] float y = 0,
        [Description("Z offset of center")] float z = 0,
        [Description("Optional ID to assign")] string? id = null)
    {
        try
        {
            var lat = new Lattice(session.Library);
            int segments = Math.Max(12, (int)(majorRadius / session.VoxelSizeMM));
            float angleStep = MathF.PI * 2 / segments;

            for (int i = 0; i < segments; i++)
            {
                float a0 = i * angleStep;
                float a1 = (i + 1) * angleStep;

                var p0 = new Vector3(
                    x + majorRadius * MathF.Cos(a0),
                    y + majorRadius * MathF.Sin(a0),
                    z);
                var p1 = new Vector3(
                    x + majorRadius * MathF.Cos(a1),
                    y + majorRadius * MathF.Sin(a1),
                    z);

                lat.AddBeam(p0, minorRadius, p1, minorRadius);
                lat.AddSphere(p0, minorRadius);
            }

            var voxels = new Voxels(lat);
            return session.Register(voxels, id,
                $"Torus R={majorRadius}mm r={minorRadius}mm at ({x},{y},{z})");
        }
        catch (Exception ex)
        {
            return $"Error creating torus: {ex.Message}";
        }
    }
}
