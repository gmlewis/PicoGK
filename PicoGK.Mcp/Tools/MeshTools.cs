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
public static class MeshTools
{
    [McpServerTool]
    [Description("Create an empty mesh. Add vertices and triangles to build geometry. Returns the object ID.")]
    public static string CreateMesh(
        PicoGkSession session,
        [Description("Optional ID to assign")] string? id = null)
    {
        var mesh = new Mesh(session.Library);
        return session.Register(mesh, id, "Empty mesh");
    }

    [McpServerTool]
    [Description("Add a vertex to a mesh. Returns the vertex index (0-based) for use in triangle creation.")]
    public static string MeshAddVertex(
        PicoGkSession session,
        [Description("ID of the mesh")] string meshId,
        [Description("X coordinate")] float x,
        [Description("Y coordinate")] float y,
        [Description("Z coordinate")] float z)
    {
        var (mesh, err) = session.SafeGet<Mesh>(meshId);
        if (err != null) return $"Error: {err}";

        int index = mesh.nAddVertex(new Vector3(x, y, z));
        return $"Vertex {index} added to '{meshId}': ({x}, {y}, {z})";
    }

    [McpServerTool]
    [Description("Add a triangle to a mesh using vertex indices. Returns the triangle index.")]
    public static string MeshAddTriangle(
        PicoGkSession session,
        [Description("ID of the mesh")] string meshId,
        [Description("Index of first vertex")] int a,
        [Description("Index of second vertex")] int b,
        [Description("Index of third vertex")] int c)
    {
        var (mesh, err) = session.SafeGet<Mesh>(meshId);
        if (err != null) return $"Error: {err}";

        int index = mesh.nAddTriangle(a, b, c);
        return $"Triangle {index} added to '{meshId}': ({a}, {b}, {c})";
    }

    [McpServerTool]
    [Description("Add a triangle to a mesh by specifying three vertex positions directly. " +
        "The vertices are added automatically. Returns the triangle index.")]
    public static string MeshAddTriangleVertices(
        PicoGkSession session,
        [Description("ID of the mesh")] string meshId,
        [Description("Vertex 1 X")] float x1, [Description("Vertex 1 Y")] float y1, [Description("Vertex 1 Z")] float z1,
        [Description("Vertex 2 X")] float x2, [Description("Vertex 2 Y")] float y2, [Description("Vertex 2 Z")] float z2,
        [Description("Vertex 3 X")] float x3, [Description("Vertex 3 Y")] float y3, [Description("Vertex 3 Z")] float z3)
    {
        var (mesh, err) = session.SafeGet<Mesh>(meshId);
        if (err != null) return $"Error: {err}";

        int index = mesh.nAddTriangle(
            new Vector3(x1, y1, z1),
            new Vector3(x2, y2, z2),
            new Vector3(x3, y3, z3));
        return $"Triangle {index} added to '{meshId}'.";
    }

    [McpServerTool]
    [Description("Convert a voxel object to a mesh using marching cubes. Returns a new mesh object ID.")]
    public static string VoxelsToMesh(
        PicoGkSession session,
        [Description("ID of the voxel object")] string voxelsId,
        [Description("Optional ID for the result")] string? id = null)
    {
        var (vox, err) = session.SafeGet<Voxels>(voxelsId);
        if (err != null) return $"Error: {err}";

        var mesh = vox.mshAsMesh();
        return session.Register(mesh, id,
            $"Mesh from '{voxelsId}' ({mesh.nVertexCount()} vertices, {mesh.nTriangleCount()} triangles)");
    }

    [McpServerTool]
    [Description("Convert a mesh to voxels. Returns a new voxel object ID.")]
    public static string MeshToVoxels(
        PicoGkSession session,
        [Description("ID of the mesh object")] string meshId,
        [Description("Optional ID for the result")] string? id = null)
    {
        var (mesh, err) = session.SafeGet<Mesh>(meshId);
        if (err != null) return $"Error: {err}";

        var voxels = new Voxels(mesh);
        return session.Register(voxels, id, $"Voxels from '{meshId}'");
    }

    [McpServerTool]
    [Description("Load a mesh from an STL file on disk. Returns the object ID.")]
    public static string MeshFromStl(
        PicoGkSession session,
        [Description("Full path to the STL file")] string path,
        [Description("Optional ID to assign")] string? id = null)
    {
        if (!File.Exists(path))
            return $"Error: File not found: {path}";

        var mesh = Mesh.mshFromStlFile(path, Mesh.EStlUnit.MM, 1.0f, null, session.Library);
        return session.Register(mesh, id, $"STL from {Path.GetFileName(path)}");
    }

    [McpServerTool]
    [Description("Transform a mesh: apply uniform scale and/or translation. Returns a new mesh object ID.")]
    public static string MeshTransform(
        PicoGkSession session,
        [Description("ID of the source mesh")] string meshId,
        [Description("Scale factor (1.0 = no scale)")] float scale = 1.0f,
        [Description("Translation X")] float translateX = 0,
        [Description("Translation Y")] float translateY = 0,
        [Description("Translation Z")] float translateZ = 0,
        [Description("Optional ID for the result")] string? id = null)
    {
        var (mesh, err) = session.SafeGet<Mesh>(meshId);
        if (err != null) return $"Error: {err}";

        var scaleVec = new Vector3(scale, scale, scale);
        var offsetVec = new Vector3(translateX, translateY, translateZ);
        var result = mesh.mshCreateTransformed(scaleVec, offsetVec);
        return session.Register(result, id, $"Transform('{meshId}', scale={scale})");
    }

    [McpServerTool]
    [Description("Mirror a mesh across a plane defined by a point and normal. Returns a new mesh object ID.")]
    public static string MeshMirror(
        PicoGkSession session,
        [Description("ID of the source mesh")] string meshId,
        [Description("A point on the mirror plane X")] float ptX,
        [Description("A point on the mirror plane Y")] float ptY,
        [Description("A point on the mirror plane Z")] float ptZ,
        [Description("Mirror plane normal X")] float nX,
        [Description("Mirror plane normal Y")] float nY,
        [Description("Mirror plane normal Z")] float nZ,
        [Description("Optional ID for the result")] string? id = null)
    {
        var (mesh, err) = session.SafeGet<Mesh>(meshId);
        if (err != null) return $"Error: {err}";

        var result = mesh.mshCreateMirrored(
            new Vector3(ptX, ptY, ptZ),
            new Vector3(nX, nY, nZ));
        return session.Register(result, id, $"Mirror('{meshId}')");
    }

    [McpServerTool]
    [Description("Append one mesh into another (modifies the target). Returns the target mesh ID.")]
    public static string MeshAppend(
        PicoGkSession session,
        [Description("ID of the target mesh (will be modified)")] string targetId,
        [Description("ID of the source mesh (will be appended)")] string sourceId)
    {
        var (target, errT) = session.SafeGet<Mesh>(targetId);
        if (errT != null) return $"Error: {errT}";
        var (source, errS) = session.SafeGet<Mesh>(sourceId);
        if (errS != null) return $"Error: {errS}";

        if (targetId == sourceId)
            return $"Error: Cannot append mesh to itself (same ID: '{targetId}').";

        target.Append(source);
        return $"Appended '{sourceId}' into '{targetId}'. " +
               $"Now has {target.nVertexCount()} vertices, {target.nTriangleCount()} triangles.";
    }
}
