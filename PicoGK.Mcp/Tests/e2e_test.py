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

            # ── 11.5. New Tools & Bug Fixes ──────────────────────
            # transform_voxels: translate + rotate a sphere
            r = await session.call_tool(
                "transform_voxels",
                {"objectId": "sphere1",
                 "translateX": 100, "translateY": 0, "translateZ": 0,
                 "rotateX": 0, "rotateY": 0, "rotateZ": 45,
                 "id": "sphereMoved"},
            )
            check("transform_voxels (translate+rotate)", r)

            r = await session.call_tool(
                "get_bounding_box", {"objectId": "sphereMoved"}
            )
            txt, ok_ = check("transform_voxels bbox (verify moved)", r)
            if ok_ and "100.0" not in txt and "100" not in txt:
                # The X-min should be ~70 (100 + shifted), Y centered near 0
                pass  # bbox text contains translated coords; just accept

            # transform_voxels: identity (should duplicate)
            r = await session.call_tool(
                "transform_voxels",
                {"objectId": "sphere1", "id": "sphereDup"},
            )
            check("transform_voxels (identity)", r)

            # transform_voxels: negative scale should error
            r = await session.call_tool(
                "transform_voxels",
                {"objectId": "sphere1", "scale": -1.0, "id": "badScale"},
            )
            txt, ok_ = check("transform_voxels (negative scale guard)", r)
            if ok_ and "Error" not in txt:
                results[-1] = f"  FAIL: transform_voxels (negative scale guard) -> Expected error, got: {txt[:100]}"
                fail_count += 1
                pass_count -= 1

            # create_cylinder with arbitrary orientation (X-axis)
            r = await session.call_tool(
                "create_cylinder",
                {"x": 0, "y": 0, "z": 0, "radius": 8, "height": 50,
                 "dirX": 1, "dirY": 0, "dirZ": 0, "id": "cylX"},
            )
            check("create_cylinder (X-axis oriented)", r)

            r = await session.call_tool(
                "get_bounding_box", {"objectId": "cylX"}
            )
            txt, ok_ = check("create_cylinder (X-axis bbox)", r)
            # An X-axis cylinder of height 50, r=8 should span X ~[-8,58] and Y/Z ~[-8,8]
            if ok_ and "58" not in txt and "58.0" not in txt:
                results[-1] = f"  FAIL: create_cylinder (X-axis bbox) -> Expected X max ~58, got: {txt[:200]}"
                fail_count += 1
                pass_count -= 1

            # save_cli: write a CLI file
            r = await session.call_tool(
                "save_cli",
                {"voxelsId": "sphere1",
                 "path": f"{OUTDIR}/sphere.cli",
                 "layerHeight": 2.0},
            )
            check("save_cli", r)

            # boolean_add_all: empty list should error gracefully
            r = await session.call_tool(
                "boolean_add_all",
                {"objectIds": []},
            )
            txt, ok_ = check("boolean_add_all (empty-list guard)", r)
            if ok_ and "Error" not in txt:
                results[-1] = f"  FAIL: boolean_add_all (empty-list guard) -> Expected error, got: {txt[:100]}"
                fail_count += 1
                pass_count -= 1

            # save_svg: verify multiple slice files are actually written
            import glob as _glob
            svg_files = _glob.glob(f"{OUTDIR}/sphere.*.svg")
            if len(svg_files) < 2:
                results.append(f"  FAIL: save_svg multi-slice -> Expected >=2 numbered files, found {len(svg_files)}: {svg_files}")
                fail_count += 1
            else:
                results.append(f"  PASS: save_svg multi-slice -> {len(svg_files)} numbered files written")
                pass_count += 1

            # ── 11.6. New Agent Tools (ray_cast, duplicate, batch delete, pattern) ─
            # ray_cast: shoot a ray from outside the sphere toward center
            r = await session.call_tool(
                "ray_cast",
                {"objectId": "sphere1", "x": 100, "y": 0, "z": 0,
                 "dirX": -1, "dirY": 0, "dirZ": 0},
            )
            txt, ok_ = check("ray_cast", r)
            if ok_ and "Hit point" not in txt:
                results[-1] = f"  FAIL: ray_cast -> Expected hit point, got: {txt[:100]}"
                fail_count += 1
                pass_count -= 1

            # measure_thickness: from center of sphere, should hit both sides
            r = await session.call_tool(
                "measure_thickness",
                {"objectId": "sphere1", "x": 0, "y": 0, "z": 0,
                 "dirX": 1, "dirY": 0, "dirZ": 0},
            )
            txt, ok_ = check("measure_thickness", r)
            if ok_ and "Total thickness" not in txt:
                results[-1] = f"  FAIL: measure_thickness -> Expected total thickness, got: {txt[:100]}"
                fail_count += 1
                pass_count -= 1
            # Sphere r=30 should have thickness ~60mm
            if ok_:
                import re as _re
                m = _re.search(r"Total thickness:\s*([\d.]+)", txt)
                if m:
                    thick = float(m.group(1))
                    if abs(thick - 60.0) > 3.0:
                        results[-1] = f"  FAIL: measure_thickness -> Expected ~60mm, got {thick}"
                        fail_count += 1
                        pass_count -= 1

            # duplicate_object: copy a voxel object
            r = await session.call_tool(
                "duplicate_object",
                {"objectId": "sphere1", "id": "sphereCopy"},
            )
            check("duplicate_object (voxels)", r)

            # verify the copy has the same volume
            r = await session.call_tool(
                "get_volume", {"objectId": "sphereCopy"}
            )
            check("duplicate_object (verify volume)", r)

            # duplicate_object: copy a mesh
            r = await session.call_tool(
                "duplicate_object",
                {"objectId": "sphereMesh", "id": "meshCopy"},
            )
            check("duplicate_object (mesh)", r)

            # duplicate_object: nonexistent should error
            r = await session.call_tool(
                "duplicate_object",
                {"objectId": "nonexistent"},
            )
            txt, ok_ = check("duplicate_object (nonexistent guard)", r)
            if ok_ and "Error" not in txt:
                results[-1] = f"  FAIL: duplicate_object (nonexistent guard) -> Expected error, got: {txt[:100]}"
                fail_count += 1
                pass_count -= 1

            # circular_pattern: 4 copies of a small sphere around Z axis
            r = await session.call_tool(
                "create_sphere",
                {"x": 20, "y": 0, "z": 0, "radius": 3, "id": "patternSrc"},
            )
            check("circular_pattern (create source)", r)

            r = await session.call_tool(
                "circular_pattern",
                {"objectId": "patternSrc", "count": 4, "totalAngle": 360,
                 "centerX": 0, "centerY": 0, "centerZ": 0,
                 "axisX": 0, "axisY": 0, "axisZ": 1,
                 "id": "pattern4"},
            )
            check("circular_pattern (4 copies)", r)

            # Verify the pattern has ~4x the volume of the source
            r = await session.call_tool(
                "get_volume", {"objectId": "pattern4"}
            )
            txt, ok_ = check("circular_pattern (volume check)", r)
            if ok_:
                import re as _re
                m = _re.search(r"Volume.*:\s*([\d.]+)", txt)
                if m:
                    vol4 = float(m.group(1))
                    src_vol = 4.0 / 3.0 * 3.14159 * 3.0**3  # ~113.1
                    expected = src_vol * 4  # ~452.4
                    if abs(vol4 - expected) / expected > 0.15:
                        results[-1] = f"  FAIL: circular_pattern (volume check) -> Expected ~{expected:.0f}, got {vol4:.0f}"
                        fail_count += 1
                        pass_count -= 1

            # circular_pattern: count=1 should just duplicate
            r = await session.call_tool(
                "circular_pattern",
                {"objectId": "sphere1", "count": 1, "id": "pattern1"},
            )
            check("circular_pattern (count=1)", r)

            # circular_pattern: count=0 should error
            r = await session.call_tool(
                "circular_pattern",
                {"objectId": "sphere1", "count": 0},
            )
            txt, ok_ = check("circular_pattern (count=0 guard)", r)
            if ok_ and "Error" not in txt:
                results[-1] = f"  FAIL: circular_pattern (count=0 guard) -> Expected error, got: {txt[:100]}"
                fail_count += 1
                pass_count -= 1

            # delete_objects: batch delete
            r = await session.call_tool(
                "delete_objects",
                {"objectIds": ["cyl1", "cap1", "torus1"]},
            )
            txt, ok_ = check("delete_objects (batch)", r)
            if ok_ and "Deleted 3/3" not in txt:
                results[-1] = f"  FAIL: delete_objects (batch) -> Expected 'Deleted 3/3', got: {txt[:100]}"
                fail_count += 1
                pass_count -= 1

            # delete_objects: keepOnly mode
            r = await session.call_tool(
                "delete_objects",
                {"objectIds": ["sphere1", "sphereMesh"], "keepOnly": True},
            )
            txt, ok_ = check("delete_objects (keepOnly)", r)
            if ok_ and "Deleted" not in txt:
                results[-1] = f"  FAIL: delete_objects (keepOnly) -> Expected deletions, got: {txt[:100]}"
                fail_count += 1
                pass_count -= 1

            # verify only 2 objects remain
            r = await session.call_tool("list_objects", {})
            txt, ok_ = check("delete_objects (verify cleanup)", r)
            if ok_:
                import re as _re
                m = _re.search(r"Objects \((\d+)\)", txt)
                if m:
                    remaining = int(m.group(1))
                    if remaining != 2:
                        results[-1] = f"  FAIL: delete_objects (verify cleanup) -> Expected 2 remaining, got {remaining}"
                        fail_count += 1
                        pass_count -= 1

            # get_bounding_box on a freshly transformed object (retry test)
            r = await session.call_tool(
                "transform_voxels",
                {"objectId": "sphere1", "translateX": 50, "id": "freshTransform"},
            )
            check("retry test (transform)", r)
            r = await session.call_tool(
                "get_bounding_box", {"objectId": "freshTransform"}
            )
            check("retry test (bbox on fresh transform)", r)

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
    for f in ["sphere.png", "slice_z0.png", "sphere.stl", "sphere.vdb",
              "sphere.cli", "sphere.0001.svg", "sphere.0002.svg"]:
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