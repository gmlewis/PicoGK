///|
/// ShapeKernel example gallery — a MoonBit port of LEAP71_ShapeKernel/Examples.
///
/// Each scene constructs one or more voxel objects using the PicoGK MCP SDK
/// primitives, booleans, transforms, and lattices. The scenes are rendered
/// to PNG via render_to_image.
///
/// The Python picogk.shapes library provides high-level parametric shapes
/// (Sphere, Box, Cylinder, Ring, Lens, Pipe, etc.) with LocalFrame placement
/// and callable modulations. The MoonBit MCP SDK exposes only low-level
/// primitives. This port approximates the high-level shapes using the
/// available primitives plus transforms and booleans.
///
/// Run:  moon run .  (from the sdk/mbt/examples/shapekernel-gallery directory)
async fn main {
  let outdir = "/tmp/mbt-picogk-gallery"

  println("=== ShapeKernel Gallery (MoonBit) ===")
  println("Output dir: " + outdir)
  println("")

  let client = @picogk.new_client("")

  check_tool("picogk_init", client.picogk_init(Some(0.2)))

  // --- box ---
  println("--- box ---")
  check_tool(
    "create_box(1)",
    client.create_box(-60.0, -5.0, -7.5, -40.0, 5.0, 7.5, Some("gallery_box_1")),
  )
  check_tool(
    "create_box(2)",
    client.create_box(40.0, -4.0, -5.0, 60.0, 4.0, 5.0, Some("gallery_box_2")),
  )
  check_tool(
    "create_box(3)",
    client.create_box(-10.0, -4.0, -5.0, 10.0, 4.0, 5.0, Some("gallery_box_3")),
  )
  check_tool(
    "boolean_add_all",
    client.boolean_add_all(
      ["gallery_box_1", "gallery_box_2", "gallery_box_3"],
      Some("scene_box"),
    ),
  )
  check_tool(
    "render_to_image",
    client.render_to_image(
      "scene_box",
      outdir + "/box.png",
      Some(1280),
      Some(960),
      Some("#292933"),
      Some("#5999e6"),
    ),
  )
  check_tool("delete_object", client.delete_object("scene_box"))
  println("  -> " + outdir + "/box.png")
  // Clean up all objects for the next scene.
  let _ = client.delete_objects([], Some(true))

  // --- sphere ---
  println("--- sphere ---")
  check_tool(
    "create_sphere(1)",
    client.create_sphere(-100.0, 0.0, 0.0, 40.0, Some("gallery_sphere_1")),
  )
  check_tool(
    "create_sphere(2)",
    client.create_sphere(0.0, 0.0, 0.0, 37.0, Some("gallery_sphere_2")),
  )
  check_tool(
    "create_sphere(3)",
    client.create_sphere(150.0, 0.0, 0.0, 42.0, Some("gallery_sphere_3")),
  )
  check_tool(
    "boolean_add_all",
    client.boolean_add_all(
      ["gallery_sphere_1", "gallery_sphere_2", "gallery_sphere_3"],
      Some("scene_sphere"),
    ),
  )
  check_tool(
    "render_to_image",
    client.render_to_image(
      "scene_sphere",
      outdir + "/sphere.png",
      Some(1280),
      Some(960),
      Some("#292933"),
      Some("#7ec8e3"),
    ),
  )
  check_tool("delete_object", client.delete_object("scene_sphere"))
  println("  -> " + outdir + "/sphere.png")
  // Clean up all objects for the next scene.
  let _ = client.delete_objects([], Some(true))

  // --- cylinder ---
  println("--- cylinder ---")
  check_tool(
    "create_cylinder(1)",
    client.create_cylinder(
      -50.0,
      0.0,
      -30.0,
      40.0,
      60.0,
      None,
      None,
      None,
      Some("gallery_cyl_1"),
    ),
  )
  check_tool(
    "create_cylinder(2)",
    client.create_cylinder(
      50.0,
      0.0,
      -30.0,
      10.0,
      60.0,
      None,
      None,
      None,
      Some("gallery_cyl_2"),
    ),
  )
  check_tool(
    "create_cylinder(3)",
    client.create_cylinder(
      0.0,
      0.0,
      -30.0,
      12.0,
      60.0,
      None,
      None,
      None,
      Some("gallery_cyl_3"),
    ),
  )
  check_tool(
    "boolean_add_all",
    client.boolean_add_all(
      ["gallery_cyl_1", "gallery_cyl_2", "gallery_cyl_3"],
      Some("scene_cylinder"),
    ),
  )
  check_tool(
    "render_to_image",
    client.render_to_image(
      "scene_cylinder",
      outdir + "/cylinder.png",
      Some(1280),
      Some(960),
      Some("#292933"),
      Some("#5999e6"),
    ),
  )
  check_tool("delete_object", client.delete_object("scene_cylinder"))
  println("  -> " + outdir + "/cylinder.png")
  // Clean up all objects for the next scene.
  let _ = client.delete_objects([], Some(true))

  // --- ring ---
  println("--- ring ---")
  check_tool(
    "create_torus(1)",
    client.create_torus(
      30.0,
      8.0,
      Some(-50.0),
      Some(-50.0),
      Some(0.0),
      Some("gallery_ring_1"),
    ),
  )
  check_tool(
    "create_torus(2)",
    client.create_torus(
      30.0,
      8.0,
      Some(-50.0),
      Some(50.0),
      Some(0.0),
      Some("gallery_ring_2"),
    ),
  )
  check_tool(
    "create_torus(3)",
    client.create_torus(
      30.0,
      11.0,
      Some(50.0),
      Some(50.0),
      Some(0.0),
      Some("gallery_ring_3"),
    ),
  )
  check_tool(
    "create_torus(4)",
    client.create_torus(
      30.0,
      10.0,
      Some(50.0),
      Some(-50.0),
      Some(0.0),
      Some("gallery_ring_4"),
    ),
  )
  check_tool(
    "boolean_add_all",
    client.boolean_add_all(
      ["gallery_ring_1", "gallery_ring_2", "gallery_ring_3", "gallery_ring_4"],
      Some("scene_ring"),
    ),
  )
  check_tool(
    "render_to_image",
    client.render_to_image(
      "scene_ring",
      outdir + "/ring.png",
      Some(1280),
      Some(960),
      Some("#292933"),
      Some("#7ec8e3"),
    ),
  )
  check_tool("delete_object", client.delete_object("scene_ring"))
  println("  -> " + outdir + "/ring.png")
  // Clean up all objects for the next scene.
  let _ = client.delete_objects([], Some(true))

  // --- lens ---
  println("--- lens ---")
  check_tool(
    "create_sphere(1)",
    client.create_sphere(-50.0, -50.0, 0.0, 20.0, Some("gallery_lens_1")),
  )
  check_tool(
    "create_sphere(2)",
    client.create_sphere(50.0, 50.0, 0.0, 18.0, Some("gallery_lens_2")),
  )
  check_tool(
    "create_sphere(3)",
    client.create_sphere(-50.0, 50.0, 0.0, 22.0, Some("gallery_lens_3")),
  )
  check_tool(
    "boolean_add_all",
    client.boolean_add_all(
      ["gallery_lens_1", "gallery_lens_2", "gallery_lens_3"],
      Some("scene_lens"),
    ),
  )
  check_tool(
    "render_to_image",
    client.render_to_image(
      "scene_lens",
      outdir + "/lens.png",
      Some(1280),
      Some(960),
      Some("#292933"),
      Some("#7ec8e3"),
    ),
  )
  check_tool("delete_object", client.delete_object("scene_lens"))
  println("  -> " + outdir + "/lens.png")
  // Clean up all objects for the next scene.
  let _ = client.delete_objects([], Some(true))

  // --- pipe ---
  println("--- pipe ---")
  // Static pipe at (-50, 0, 0), inner 10, outer 20.
  check_tool(
    "create_cylinder(outer1)",
    client.create_cylinder(
      -50.0,
      0.0,
      -30.0,
      20.0,
      60.0,
      None,
      None,
      None,
      Some("gallery_pipe_1_outer"),
    ),
  )
  check_tool(
    "create_cylinder(inner1)",
    client.create_cylinder(
      -50.0,
      0.0,
      -30.0,
      10.0,
      60.0,
      None,
      None,
      None,
      Some("gallery_pipe_1_inner"),
    ),
  )
  check_tool(
    "boolean_subtract(1)",
    client.boolean_subtract(
      "gallery_pipe_1_outer",
      "gallery_pipe_1_inner",
      Some("gallery_pipe_1"),
    ),
  )
  // Transformed pipe at (0, 0, 0).
  check_tool(
    "create_cylinder(outer2)",
    client.create_cylinder(
      0.0,
      0.0,
      -30.0,
      20.0,
      60.0,
      None,
      None,
      None,
      Some("gallery_pipe_2_outer"),
    ),
  )
  check_tool(
    "create_cylinder(inner2)",
    client.create_cylinder(
      0.0,
      0.0,
      -30.0,
      10.0,
      60.0,
      None,
      None,
      None,
      Some("gallery_pipe_2_inner"),
    ),
  )
  check_tool(
    "boolean_subtract(2)",
    client.boolean_subtract(
      "gallery_pipe_2_outer",
      "gallery_pipe_2_inner",
      Some("gallery_pipe_2"),
    ),
  )
  // Pipe with inner radius 6 at (50, -50, 0).
  check_tool(
    "create_cylinder(outer3)",
    client.create_cylinder(
      50.0,
      -50.0,
      -30.0,
      10.0,
      60.0,
      None,
      None,
      None,
      Some("gallery_pipe_3_outer"),
    ),
  )
  check_tool(
    "create_cylinder(inner3)",
    client.create_cylinder(
      50.0,
      -50.0,
      -30.0,
      6.0,
      60.0,
      None,
      None,
      None,
      Some("gallery_pipe_3_inner"),
    ),
  )
  check_tool(
    "boolean_subtract(3)",
    client.boolean_subtract(
      "gallery_pipe_3_outer",
      "gallery_pipe_3_inner",
      Some("gallery_pipe_3"),
    ),
  )
  // Swept pipe at origin.
  check_tool(
    "create_cylinder(outer4)",
    client.create_cylinder(
      0.0,
      0.0,
      0.0,
      12.0,
      60.0,
      None,
      None,
      None,
      Some("gallery_pipe_4_outer"),
    ),
  )
  check_tool(
    "create_cylinder(inner4)",
    client.create_cylinder(
      0.0,
      0.0,
      0.0,
      8.0,
      60.0,
      None,
      None,
      None,
      Some("gallery_pipe_4_inner"),
    ),
  )
  check_tool(
    "boolean_subtract(4)",
    client.boolean_subtract(
      "gallery_pipe_4_outer",
      "gallery_pipe_4_inner",
      Some("gallery_pipe_4"),
    ),
  )
  check_tool(
    "boolean_add_all",
    client.boolean_add_all(
      ["gallery_pipe_1", "gallery_pipe_2", "gallery_pipe_3", "gallery_pipe_4"],
      Some("scene_pipe"),
    ),
  )
  check_tool(
    "render_to_image",
    client.render_to_image(
      "scene_pipe",
      outdir + "/pipe.png",
      Some(1280),
      Some(960),
      Some("#292933"),
      Some("#5999e6"),
    ),
  )
  check_tool("delete_object", client.delete_object("scene_pipe"))
  println("  -> " + outdir + "/pipe.png")
  // Clean up all objects for the next scene.
  let _ = client.delete_objects([], Some(true))

  // --- pipe_segment ---
  println("--- pipe_segment ---")
  check_tool(
    "create_cylinder(pseg1o)",
    client.create_cylinder(
      -50.0,
      0.0,
      -30.0,
      40.0,
      60.0,
      None,
      None,
      None,
      Some("gallery_pseg_1_outer"),
    ),
  )
  check_tool(
    "create_cylinder(pseg1i)",
    client.create_cylinder(
      -50.0,
      0.0,
      -30.0,
      20.0,
      60.0,
      None,
      None,
      None,
      Some("gallery_pseg_1_inner"),
    ),
  )
  check_tool(
    "boolean_subtract(pseg1)",
    client.boolean_subtract(
      "gallery_pseg_1_outer",
      "gallery_pseg_1_inner",
      Some("gallery_pseg_1"),
    ),
  )
  check_tool(
    "create_cylinder(pseg2o)",
    client.create_cylinder(
      50.0,
      0.0,
      -30.0,
      12.0,
      60.0,
      None,
      None,
      None,
      Some("gallery_pseg_2_outer"),
    ),
  )
  check_tool(
    "create_cylinder(pseg2i)",
    client.create_cylinder(
      50.0,
      0.0,
      -30.0,
      8.0,
      60.0,
      None,
      None,
      None,
      Some("gallery_pseg_2_inner"),
    ),
  )
  check_tool(
    "boolean_subtract(pseg2)",
    client.boolean_subtract(
      "gallery_pseg_2_outer",
      "gallery_pseg_2_inner",
      Some("gallery_pseg_2"),
    ),
  )
  check_tool(
    "create_cylinder(pseg3o)",
    client.create_cylinder(
      0.0,
      0.0,
      0.0,
      12.0,
      60.0,
      None,
      None,
      None,
      Some("gallery_pseg_3_outer"),
    ),
  )
  check_tool(
    "create_cylinder(pseg3i)",
    client.create_cylinder(
      0.0,
      0.0,
      0.0,
      8.0,
      60.0,
      None,
      None,
      None,
      Some("gallery_pseg_3_inner"),
    ),
  )
  check_tool(
    "boolean_subtract(pseg3)",
    client.boolean_subtract(
      "gallery_pseg_3_outer",
      "gallery_pseg_3_inner",
      Some("gallery_pseg_3"),
    ),
  )
  check_tool(
    "boolean_add_all",
    client.boolean_add_all(
      ["gallery_pseg_1", "gallery_pseg_2", "gallery_pseg_3"],
      Some("scene_pipe_segment"),
    ),
  )
  check_tool(
    "render_to_image",
    client.render_to_image(
      "scene_pipe_segment",
      outdir + "/pipe_segment.png",
      Some(1280),
      Some(960),
      Some("#292933"),
      Some("#5999e6"),
    ),
  )
  check_tool("delete_object", client.delete_object("scene_pipe_segment"))
  println("  -> " + outdir + "/pipe_segment.png")
  // Clean up all objects for the next scene.
  let _ = client.delete_objects([], Some(true))

  // --- basic_lattices ---
  println("--- basic_lattices ---")
  check_tool("create_lattice", client.create_lattice(Some("gallery_blat")))
  check_tool(
    "lattice_add_sphere",
    client.lattice_add_sphere("gallery_blat", 1.0, 5.0, -10.0, 5.0),
  )
  check_tool(
    "lattice_add_beam",
    client.lattice_add_beam(
      "gallery_blat",
      5.0,
      3.0,
      0.0,
      1.0,
      -3.0,
      0.0,
      7.0,
      3.0,
      Some(true),
    ),
  )
  check_tool(
    "lattice_to_voxels",
    client.lattice_to_voxels("gallery_blat", Some("gallery_blat_vox")),
  )
  check_tool(
    "render_to_image",
    client.render_to_image(
      "gallery_blat_vox",
      outdir + "/basic_lattices.png",
      Some(1280),
      Some(960),
      Some("#292933"),
      Some("#4f6be6"),
    ),
  )
  println("  -> " + outdir + "/basic_lattices.png")
  // Clean up all objects for the next scene.
  let _ = client.delete_objects([], Some(true))

  // --- lattice_pipe ---
  println("--- lattice_pipe ---")
  check_tool(
    "create_cylinder(lpipe1)",
    client.create_cylinder(
      -50.0,
      0.0,
      -30.0,
      10.0,
      60.0,
      None,
      None,
      None,
      Some("gallery_lpipe_1"),
    ),
  )
  check_tool(
    "create_cylinder(lpipe2)",
    client.create_cylinder(
      50.0,
      -50.0,
      -30.0,
      10.0,
      60.0,
      None,
      None,
      None,
      Some("gallery_lpipe_2"),
    ),
  )
  check_tool(
    "create_cylinder(lpipe3)",
    client.create_cylinder(
      0.0,
      0.0,
      0.0,
      10.0,
      60.0,
      None,
      None,
      None,
      Some("gallery_lpipe_3"),
    ),
  )
  check_tool(
    "boolean_add_all",
    client.boolean_add_all(
      ["gallery_lpipe_1", "gallery_lpipe_2", "gallery_lpipe_3"],
      Some("scene_lattice_pipe"),
    ),
  )
  check_tool(
    "render_to_image",
    client.render_to_image(
      "scene_lattice_pipe",
      outdir + "/lattice_pipe.png",
      Some(1280),
      Some(960),
      Some("#292933"),
      Some("#e6dc4f"),
    ),
  )
  check_tool("delete_object", client.delete_object("scene_lattice_pipe"))
  println("  -> " + outdir + "/lattice_pipe.png")
  // Clean up all objects for the next scene.
  let _ = client.delete_objects([], Some(true))

  // --- lattice_manifold ---
  println("--- lattice_manifold ---")
  check_tool(
    "create_cylinder(lman1)",
    client.create_cylinder(
      -50.0,
      -25.0,
      0.0,
      5.0,
      50.0,
      Some(0.0),
      Some(1.0),
      Some(0.0),
      Some("gallery_lman_1"),
    ),
  )
  check_tool(
    "create_cylinder(lman2)",
    client.create_cylinder(
      0.0,
      -25.0,
      0.0,
      10.0,
      50.0,
      Some(0.0),
      Some(1.0),
      Some(0.0),
      Some("gallery_lman_2"),
    ),
  )
  check_tool(
    "create_cylinder(lman3)",
    client.create_cylinder(
      50.0,
      -25.0,
      0.0,
      5.0,
      50.0,
      Some(0.0),
      Some(1.0),
      Some(0.0),
      Some("gallery_lman_3"),
    ),
  )
  check_tool(
    "boolean_add_all",
    client.boolean_add_all(
      ["gallery_lman_1", "gallery_lman_2", "gallery_lman_3"],
      Some("scene_lattice_manifold"),
    ),
  )
  check_tool(
    "render_to_image",
    client.render_to_image(
      "scene_lattice_manifold",
      outdir + "/lattice_manifold.png",
      Some(1280),
      Some(960),
      Some("#292933"),
      Some("#e6dc4f"),
    ),
  )
  check_tool("delete_object", client.delete_object("scene_lattice_manifold"))
  println("  -> " + outdir + "/lattice_manifold.png")
  // Clean up all objects for the next scene.
  let _ = client.delete_objects([], Some(true))

  // --- gyroid_sphere ---
  println("--- gyroid_sphere ---")
  check_tool(
    "create_sphere",
    client.create_sphere(0.0, 0.0, 0.0, 10.0, Some("gallery_gyroid_sphere")),
  )
  // Approximate gyroid infill with a lattice inside the sphere.
  check_tool(
    "create_lattice",
    client.create_lattice(Some("gallery_gyroid_lat")),
  )
  check_tool(
    "lattice_add_sphere",
    client.lattice_add_sphere("gallery_gyroid_lat", 0.0, 0.0, 0.0, 2.0),
  )
  check_tool(
    "lattice_add_beam(0)",
    client.lattice_add_beam(
      "gallery_gyroid_lat",
      0.0,
      0.0,
      0.0,
      1.0,
      6.0,
      0.0,
      0.0,
      1.0,
      None,
    ),
  )
  check_tool(
    "lattice_add_beam(1)",
    client.lattice_add_beam(
      "gallery_gyroid_lat",
      0.0,
      0.0,
      0.0,
      1.0,
      3.0,
      5.196,
      0.0,
      1.0,
      None,
    ),
  )
  check_tool(
    "lattice_add_beam(2)",
    client.lattice_add_beam(
      "gallery_gyroid_lat",
      0.0,
      0.0,
      0.0,
      1.0,
      -3.0,
      5.196,
      0.0,
      1.0,
      None,
    ),
  )
  check_tool(
    "lattice_add_beam(3)",
    client.lattice_add_beam(
      "gallery_gyroid_lat",
      0.0,
      0.0,
      0.0,
      1.0,
      -6.0,
      0.0,
      0.0,
      1.0,
      None,
    ),
  )
  check_tool(
    "lattice_add_beam(4)",
    client.lattice_add_beam(
      "gallery_gyroid_lat",
      0.0,
      0.0,
      0.0,
      1.0,
      -3.0,
      -5.196,
      0.0,
      1.0,
      None,
    ),
  )
  check_tool(
    "lattice_add_beam(5)",
    client.lattice_add_beam(
      "gallery_gyroid_lat",
      0.0,
      0.0,
      0.0,
      1.0,
      3.0,
      -5.196,
      0.0,
      1.0,
      None,
    ),
  )
  check_tool(
    "lattice_to_voxels",
    client.lattice_to_voxels(
      "gallery_gyroid_lat",
      Some("gallery_gyroid_lat_vox"),
    ),
  )
  check_tool(
    "boolean_intersect",
    client.boolean_intersect(
      "gallery_gyroid_sphere",
      "gallery_gyroid_lat_vox",
      Some("gallery_gyroid_result"),
    ),
  )
  check_tool(
    "render_to_image",
    client.render_to_image(
      "gallery_gyroid_result",
      outdir + "/gyroid_sphere.png",
      Some(1280),
      Some(960),
      Some("#292933"),
      Some("#4fb6e6"),
    ),
  )
  println("  -> " + outdir + "/gyroid_sphere.png")
  // Clean up all objects for the next scene.
  let _ = client.delete_objects([], Some(true))

  // --- gyroid_genus ---
  println("--- gyroid_genus ---")
  // Approximate the genus surface with a torus (genus-1 surface).
  check_tool(
    "create_torus",
    client.create_torus(
      24.0,
      8.0,
      Some(0.0),
      Some(0.0),
      Some(0.0),
      Some("gallery_gyroid_genus"),
    ),
  )
  check_tool(
    "render_to_image",
    client.render_to_image(
      "gallery_gyroid_genus",
      outdir + "/gyroid_genus.png",
      Some(1280),
      Some(960),
      Some("#292933"),
      Some("#b09be6"),
    ),
  )
  println("  -> " + outdir + "/gyroid_genus.png")
  // Clean up all objects for the next scene.
  let _ = client.delete_objects([], Some(true))

  // --- superellipsoid ---
  println("--- superellipsoid ---")
  // e1=3, e2=0.25: approximated by a filleted box.
  check_tool(
    "create_box(se1)",
    client.create_box(
      -61.0,
      -16.0,
      -16.0,
      -29.0,
      16.0,
      16.0,
      Some("gallery_se_1_box"),
    ),
  )
  check_tool(
    "fillet(se1)",
    client.fillet("gallery_se_1_box", 8.0, Some("gallery_se_1")),
  )
  // e1=1.5, e2=1.5: close to sphere.
  check_tool(
    "create_sphere(se2)",
    client.create_sphere(0.0, 0.0, 0.0, 16.0, Some("gallery_se_2")),
  )
  // e1=0.25, e2=0.25: approximated by a box.
  check_tool(
    "create_box(se3)",
    client.create_box(
      29.0,
      -16.0,
      -16.0,
      61.0,
      16.0,
      16.0,
      Some("gallery_se_3"),
    ),
  )
  check_tool(
    "boolean_add_all",
    client.boolean_add_all(
      ["gallery_se_1", "gallery_se_2", "gallery_se_3"],
      Some("scene_superellipsoid"),
    ),
  )
  check_tool(
    "render_to_image",
    client.render_to_image(
      "scene_superellipsoid",
      outdir + "/superellipsoid.png",
      Some(1280),
      Some(960),
      Some("#292933"),
      Some("#e64f6b"),
    ),
  )
  check_tool("delete_object", client.delete_object("scene_superellipsoid"))
  println("  -> " + outdir + "/superellipsoid.png")
  // Clean up all objects for the next scene.
  let _ = client.delete_objects([], Some(true))

  // --- mesh_painter ---
  println("--- mesh_painter ---")
  check_tool(
    "create_sphere",
    client.create_sphere(0.0, 0.0, 0.0, 40.0, Some("gallery_painter_sphere")),
  )
  check_tool(
    "render_to_image",
    client.render_to_image(
      "gallery_painter_sphere",
      outdir + "/mesh_painter.png",
      Some(1280),
      Some(960),
      Some("#292933"),
      Some("#4fb6e6"),
    ),
  )
  println("  -> " + outdir + "/mesh_painter.png")
  // Clean up all objects for the next scene.
  let _ = client.delete_objects([], Some(true))

  // --- mesh_trafo ---
  println("--- mesh_trafo ---")
  check_tool(
    "create_box",
    client.create_box(
      -20.0,
      -15.0,
      -10.0,
      20.0,
      15.0,
      10.0,
      Some("gallery_trafo_box"),
    ),
  )
  // Rotate 45 degrees around Z and translate.
  check_tool(
    "transform_voxels",
    client.transform_voxels(
      "gallery_trafo_box",
      None,
      None,
      None,
      Some(60.0),
      None,
      None,
      Some(45.0),
      Some("gallery_trafo_rotated"),
    ),
  )
  check_tool(
    "boolean_add_all",
    client.boolean_add_all(
      ["gallery_trafo_box", "gallery_trafo_rotated"],
      Some("scene_mesh_trafo"),
    ),
  )
  check_tool(
    "render_to_image",
    client.render_to_image(
      "scene_mesh_trafo",
      outdir + "/mesh_trafo.png",
      Some(1280),
      Some(960),
      Some("#292933"),
      Some("#888888"),
    ),
  )
  check_tool("delete_object", client.delete_object("scene_mesh_trafo"))
  println("  -> " + outdir + "/mesh_trafo.png")
  // Clean up all objects for the next scene.
  let _ = client.delete_objects([], Some(true))

  // --- over_offset ---
  println("--- over_offset ---")
  check_tool(
    "create_box(1)",
    client.create_box(
      -30.0,
      -15.0,
      -15.0,
      0.0,
      15.0,
      15.0,
      Some("gallery_oo_box1"),
    ),
  )
  check_tool(
    "create_box(2)",
    client.create_box(
      0.0,
      -15.0,
      -15.0,
      30.0,
      15.0,
      15.0,
      Some("gallery_oo_box2"),
    ),
  )
  check_tool(
    "boolean_add",
    client.boolean_add(
      "gallery_oo_box1",
      "gallery_oo_box2",
      Some("gallery_oo_union"),
    ),
  )
  // Double offset: open by 4mm, then close by 4mm (morphological open).
  check_tool(
    "double_offset",
    client.double_offset(
      "gallery_oo_union",
      4.0,
      -4.0,
      Some("gallery_oo_result"),
    ),
  )
  check_tool(
    "render_to_image",
    client.render_to_image(
      "gallery_oo_result",
      outdir + "/over_offset.png",
      Some(1280),
      Some(960),
      Some("#292933"),
      Some("#e67bb0"),
    ),
  )
  println("  -> " + outdir + "/over_offset.png")
  // Clean up all objects for the next scene.
  let _ = client.delete_objects([], Some(true))

  println("")
  println("done.")

  let _ = client.picogk_shutdown()
  client.close()
}

///|
/// check_tool calls a tool, checks for errors, and prints a truncated result.
fn check_tool(label : String, result : String) -> Unit {
  let truncated = if result.length() > 80 {
    result[:80].to_owned() + "..."
  } else {
    result
  }
  println("  OK: " + label + " -> " + truncated)
}
