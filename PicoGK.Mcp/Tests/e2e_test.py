#!/usr/bin/env python3
"""Comprehensive PicoGK MCP Server End-to-End Test.

Uses the MCP Python client to test every tool exposed by the PicoGK MCP server.
Run with: python3 e2e_test.py [/path/to/PicoGK.Mcp] [output_dir]

If no arguments are given, defaults to the published binary at
~/.local/bin/picogk-mcp/PicoGK.Mcp and /tmp/picogk_e2e_output.
"""

import asyncio
import json
import os
import sys
import tempfile

MCP_BIN = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser(
    "~/.local/bin/picogk-mcp/PicoGK.Mcp"
)
OUTDIR = sys.argv[2] if len(sys.argv) > 2 else "/tmp/picogk_e2e_output"
os.makedirs(OUTDIR, exist_ok=True)

results: list[str] = []
pass_count = 0
fail_count = 0


def check(label: str, result) -> tuple[str, bool]:
    """Check an MCP tool call result and record pass/fail."""
    global pass_count, fail_count
    is_error = result.isError if hasattr(result, "isError") else False
    text = ""
    for c in result.content or []:
        if hasattr(c, "text"):
            text += c.text

    if is_error:
        fail_count += 1
        results.append(f"  FAIL: {label} -> {text[:200]}")
        return text, False
    else:
        pass_count += 1
        results.append(f"  PASS: {label} -> {text[:200]}")
        return text, True


async def run_tests():
    global pass_count, fail_count

    from mcp import ClientSession, StdioServerParameters, stdio_client

    server_params = StdioServerParameters(command=MCP_BIN, args=[])

    async with stdio_client(server_params) as (read_stream, write_stream):
        async with ClientSession(read_stream, write_stream) as session:
            await session.initialize()

            # ── 1. Session Management ──────────────────────────
            r = await session.call_tool("picogk_init", {"voxelSizeMM": 0.5})
            check("picogk_init", r)

            # ── 2. Primitives ─────────────────────────────────
            r = await session.call_tool(
                "create_sphere", {"x": 0, "y": 0, "z": 0, "radius": 30, "id": "sphere1"}
            )
            check("create_sphere", r)

            r = await session.call_tool(
                "create_box",
                {
                    "minX": -10, "minY": -10, "minZ": -40,
                    "maxX": 10, "maxY": 10, "maxZ": 40,
                    "id": "box1",
                },
            )
            check("create_box", r)

            r = await session.call_tool(
                "create_cylinder",
                {"x": 0, "y": 0, "z": 0, "radius": 10, "height": 50, "id": "cyl1"},
            )
            check("create_cylinder", r)

            r = await session.call_tool(
                "create_capsule",
                {"x1": 0, "y1": 0, "z1": -20, "x2": 0, "y2": 0, "z2": 20,
                 "radius": 8, "id": "cap1"},
            )
            check("create_capsule", r)

            r = await session.call_tool(
                "create_torus",
                {"majorRadius": 25, "minorRadius": 5, "x": 0, "y": 0, "z": 0, "id": "torus1"},
            )
            check("create_torus", r)

            # ── 3. Boolean Operations ─────────────────────────
            r = await session.call_tool(
                "boolean_add", {"a": "sphere1", "b": "cyl1", "id": "union1"}
            )
            check("boolean_add", r)

            r = await session.call_tool(
                "boolean_subtract", {"a": "sphere1", "b": "box1", "id": "sub1"}
            )
            check("boolean_subtract", r)

            r = await session.call_tool(
                "boolean_intersect", {"a": "sphere1", "b": "cyl1", "id": "inter1"}
            )
            check("boolean_intersect", r)

            r = await session.call_tool(
                "boolean_add_all",
                {"objectIds": ["sphere1", "cyl1"], "id": "combined1"},
            )
            check("boolean_add_all", r)

            # ── 4. Transform Operations ────────────────────────
            r = await session.call_tool(
                "offset", {"objectId": "sphere1", "distance": 2, "id": "offset1"}
            )
            check("offset", r)

            r = await session.call_tool(
                "smooth", {"objectId": "sub1", "distance": 1.5, "id": "smooth1"}
            )
            check("smooth", r)

            r = await session.call_tool(
                "shell",
                {"objectId": "sphere1", "innerOffset": 2, "outerOffset": 0,
                 "smooth": 0.5, "id": "shell1"},
            )
            check("shell", r)

            r = await session.call_tool(
                "trim",
                {"objectId": "sphere1",
                 "minX": -50, "minY": -50, "minZ": 0,
                 "maxX": 50, "maxY": 50, "maxZ": 50,
                 "id": "trimmed1"},
            )
            check("trim", r)

            r = await session.call_tool(
                "fillet", {"objectId": "box1", "radius": 1.5, "id": "fillet1"}
            )
            check("fillet", r)

            # ── 5. Lattice Operations ──────────────────────────
            r = await session.call_tool("create_lattice", {"id": "lat1"})
            check("create_lattice", r)

            r = await session.call_tool(
                "lattice_add_beam",
                {"latticeId": "lat1",
                 "x1": -20, "y1": 0, "z1": 0, "radius1": 3,
                 "x2": 20, "y2": 0, "z2": 0, "radius2": 3},
            )
            check("lattice_add_beam", r)

            r = await session.call_tool(
                "lattice_add_sphere",
                {"latticeId": "lat1", "x": -20, "y": 0, "z": 0, "radius": 5},
            )
            check("lattice_add_sphere", r)

            r = await session.call_tool(
                "lattice_to_voxels", {"latticeId": "lat1", "id": "latVox1"}
            )
            check("lattice_to_voxels", r)

            # ── 6. Mesh Operations ────────────────────────────
            r = await session.call_tool("create_mesh", {"id": "mesh1"})
            check("create_mesh", r)

            r = await session.call_tool(
                "mesh_add_vertex", {"meshId": "mesh1", "x": 0, "y": 0, "z": 0}
            )
            check("mesh_add_vertex (v0)", r)

            r = await session.call_tool(
                "mesh_add_vertex", {"meshId": "mesh1", "x": 10, "y": 0, "z": 0}
            )
            check("mesh_add_vertex (v1)", r)

            r = await session.call_tool(
                "mesh_add_vertex", {"meshId": "mesh1", "x": 0, "y": 10, "z": 0}
            )
            check("mesh_add_vertex (v2)", r)

            r = await session.call_tool(
                "mesh_add_triangle", {"meshId": "mesh1", "a": 0, "b": 1, "c": 2}
            )
            check("mesh_add_triangle", r)

            r = await session.call_tool(
                "mesh_add_triangle_vertices",
                {"meshId": "mesh1",
                 "x1": 0, "y1": 0, "z1": 10,
                 "x2": 10, "y2": 0, "z2": 10,
                 "x3": 0, "y3": 10, "z3": 10},
            )
            check("mesh_add_triangle_vertices", r)

            # ── 7. Conversions ──────────────────────────────────
            r = await session.call_tool(
                "voxels_to_mesh", {"voxelsId": "sphere1", "id": "sphereMesh"}
            )
            check("voxels_to_mesh", r)

            r = await session.call_tool(
                "mesh_to_voxels", {"meshId": "sphereMesh", "id": "sphereVox2"}
            )
            check("mesh_to_voxels", r)

            # ── 8. Mesh Transform & Mirror ─────────────────────
            r = await session.call_tool(
                "mesh_transform",
                {"meshId": "sphereMesh", "scale": 2.0,
                 "translateX": 50, "id": "sphereMesh2x"},
            )
            check("mesh_transform", r)

            r = await session.call_tool(
                "mesh_mirror",
                {"meshId": "sphereMesh",
                 "ptX": 0, "ptY": 0, "ptZ": 0,
                 "nX": 1, "nY": 0, "nZ": 0,
                 "id": "sphereMirrored"},
            )
            check("mesh_mirror", r)

            # mesh_append with a *different* mesh (not self)
            r = await session.call_tool(
                "mesh_append",
                {"targetId": "sphereMesh", "sourceId": "sphereMesh2x"},
            )
            check("mesh_append (different meshes)", r)

            # mesh_append self-reference guard
            r = await session.call_tool(
                "mesh_append",
                {"targetId": "mesh1", "sourceId": "mesh1"},
            )
            txt, ok = check("mesh_append (self-ref guard)", r)
            if ok and "Error" not in txt:
                results[-1] = f"  FAIL: mesh_append (self-ref guard) -> Expected error, got: {txt[:100]}"
                fail_count += 1
                pass_count -= 1

            # ── 9. Query Operations ────────────────────────────
            r = await session.call_tool("get_bounding_box", {"objectId": "sphere1"})
            check("get_bounding_box", r)

            r = await session.call_tool("get_volume", {"objectId": "sphere1"})
            check("get_volume", r)

            r = await session.call_tool("get_voxel_dimensions", {"objectId": "sphere1"})
            check("get_voxel_dimensions", r)

            r = await session.call_tool(
                "point_inside", {"objectId": "sphere1", "x": 0, "y": 0, "z": 0}
            )
            txt, ok = check("point_inside (center)", r)
            if ok and "INSIDE" not in txt:
                results[-1] = f"  FAIL: point_inside (center) -> Expected INSIDE, got: {txt[:100]}"
                fail_count += 1
                pass_count -= 1

            r = await session.call_tool(
                "point_inside", {"objectId": "sphere1", "x": 100, "y": 0, "z": 0}
            )
            txt, ok = check("point_inside (outside)", r)
            if ok and "OUTSIDE" not in txt:
                results[-1] = f"  FAIL: point_inside (outside) -> Expected OUTSIDE, got: {txt[:100]}"
                fail_count += 1
                pass_count -= 1

            r = await session.call_tool(
                "closest_point", {"objectId": "sphere1", "x": 40, "y": 0, "z": 0}
            )
            check("closest_point", r)

            r = await session.call_tool(
                "surface_normal", {"objectId": "sphere1", "x": 30, "y": 0, "z": 0}
            )
            check("surface_normal", r)

            r = await session.call_tool("get_mesh_info", {"objectId": "sphereMesh"})
            check("get_mesh_info", r)

            r = await session.call_tool("list_objects", {})
            check("list_objects", r)

            # ── 10. Project Z Slice ─────────────────────────────
            r = await session.call_tool(
                "project_z_slice",
                {"objectId": "sphere1", "startZ": -5, "endZ": 5, "id": "proj1"},
            )
            check("project_z_slice", r)

            # ── 11. Render & Export ─────────────────────────────
            r = await session.call_tool(
                "render_to_image",
                {"objectId": "sphere1",
                 "path": f"{OUTDIR}/sphere.png",
                 "width": 600, "height": 400},
            )
            check("render_to_image", r)

            r = await session.call_tool(
                "render_slice",
                {"voxelsId": "sphere1", "zPosition": 0,
                 "path": f"{OUTDIR}/slice_z0.png"},
            )
            check("render_slice", r)

            r = await session.call_tool(
                "save_stl",
                {"meshId": "sphereMesh", "path": f"{OUTDIR}/sphere.stl"},
            )
            check("save_stl", r)

            r = await session.call_tool(
                "save_vdb",
                {"voxelsId": "sphere1", "path": f"{OUTDIR}/sphere.vdb"},
            )
            check("save_vdb", r)

            r = await session.call_tool(
                "save_svg",
                {"voxelsId": "sphere1",
                 "path": f"{OUTDIR}/sphere.svg",
                 "layerHeight": 2.0},
            )
            check("save_svg", r)

            # ── 12. Info & Cleanup ──────────────────────────────
            r = await session.call_tool("picogk_info", {})
            check("picogk_info", r)

            r = await session.call_tool("delete_object", {"objectId": "box1"})
            check("delete_object", r)

            r = await session.call_tool("picogk_shutdown", {})
            check("picogk_shutdown", r)

    # ── Print Results ──────────────────────────────────────────
    print("\n" + "=" * 80)
    print("PICOgK MCP SERVER — END-TO-END TEST RESULTS")
    print("=" * 80)
    for r in results:
        print(r)

    print(f"\n{'=' * 80}")
    print("OUTPUT FILES:")
    for f in ["sphere.png", "slice_z0.png", "sphere.stl", "sphere.vdb", "sphere.svg"]:
        fp = os.path.join(OUTDIR, f)
        if os.path.exists(fp):
            sz = os.path.getsize(fp)
            print(f"  {f}: {sz:,} bytes")
        else:
            print(f"  {f}: MISSING")

    print(f"\n{'=' * 80}")
    total = pass_count + fail_count
    print(f"SUMMARY: {pass_count} passed, {fail_count} failed out of {total} tests")
    if fail_count == 0:
        print("ALL TESTS PASSED!")
        return 0
    else:
        print("SOME TESTS FAILED!")
        return 1


if __name__ == "__main__":
    sys.exit(asyncio.run(run_tests()))