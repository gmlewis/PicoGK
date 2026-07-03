///|
/// ShapeKernel example gallery — a MoonBit port of LEAP71_ShapeKernel/Examples.
/// Uses the picogkshapes parametric shape library, matching the Go FFI gallery.
///
/// Run:  moon run . --target native [-out DIR] [-voxel-size MM] [-no-viewer] [-scene NAME]
fn main {
  // Parse command-line arguments.
  let cmd = @argparse.Command(
    "shapekernel-gallery",
    about="PicoGK ShapeKernel Gallery (MoonBit FFI)",
    flags=[
      @argparse.FlagArg(
        "no-viewer",
        long="no-viewer",
        about="Save STLs only (no display needed)",
      ),
    ],
    options=[
      @argparse.OptionArg("out", long="out", about="Output directory", default_values=[
        "/tmp/mbt-picogk-gallery",
      ]),
      @argparse.OptionArg(
        "voxel-size",
        long="voxel-size",
        about="Voxel size in mm",
        default_values=["0.2"],
      ),
      @argparse.OptionArg(
        "scene",
        long="scene",
        about="Render only this scene",
        default_values=[""],
      ),
    ],
  )
  let matches = cmd.parse() catch {
    _ => {
      println(cmd.render_help())
      return
    }
  }
  let outdir = match matches.values.get("out") {
    Some(arr) => arr[0]
    None => "/tmp/mbt-picogk-gallery"
  }
  let voxel_size_str = match matches.values.get("voxel-size") {
    Some(arr) => arr[0]
    None => "0.2"
  }
  let voxel_size = parse_double(voxel_size_str).or(0.2)
  let no_viewer = match matches.flags.get("no-viewer") {
    Some(v) => v
    None => false
  }
  let scene_only = match matches.values.get("scene") {
    Some(arr) => arr[0]
    None => ""
  }

  println("=== ShapeKernel Gallery (MoonBit FFI) ===")
  println("Output dir: " + outdir)
  println("Voxel size: \{voxel_size} mm")
  println("")

  match @pk.init_with_size(voxel_size) {
    Ok(_) => ()
    Err(e) => {
      println("Failed to init PicoGK: " + e)
      return
    }
  }
  println("  PicoGK version: " + @pk.version())

  // Build all scenes.
  let scenes : Array[(String, Array[@s.SceneGroup])] = []
  scenes.push(("box", build_box()))
  scenes.push(("sphere", build_sphere()))
  scenes.push(("cylinder", build_cylinder()))
  scenes.push(("ring", build_ring()))
  scenes.push(("lens", build_lens()))
  scenes.push(("pipe", build_pipe()))
  scenes.push(("pipe_segment", build_pipe_segment()))
  scenes.push(("basic_lattices", build_basic_lattices()))
  scenes.push(("lattice_pipe", build_lattice_pipe()))
  scenes.push(("lattice_manifold", build_lattice_manifold()))
  scenes.push(("gyroid_sphere", build_gyroid_sphere()))
  scenes.push(("gyroid_genus", build_gyroid_genus()))
  scenes.push(("superellipsoid", build_superellipsoid()))
  scenes.push(("mesh_painter", build_mesh_painter()))
  scenes.push(("mesh_trafo", build_mesh_trafo()))
  scenes.push(("over_offset", build_over_offset()))

  for scene in scenes {
    let name = scene.0
    let groups = scene.1
    if scene_only != "" && scene_only != name {
      for g in groups {
        match g.voxels {
          Some(v) => v.destroy()
          None => ()
        }
        match g.mesh {
          Some(m) => m.destroy()
          None => ()
        }
      }
      continue
    }
    println("--- " + name + " ---")
    if groups.is_empty() {
      println("  (empty)")
      continue
    }

    if no_viewer {
      // Save STLs only.
      for idx, g in groups {
        match g.voxels {
          Some(v) => {
            let mesh = v.to_mesh()
            let stl_path = outdir + "/" + name + "_" + idx.to_string() + ".stl"
            if mesh.save_stl(stl_path) {
              println("  -> " + stl_path)
            }
            mesh.destroy()
          }
          None =>
            match g.mesh {
              Some(m) => {
                let stl_path = outdir +
                  "/" +
                  name +
                  "_" +
                  idx.to_string() +
                  ".stl"
                if m.save_stl(stl_path) {
                  println("  -> " + stl_path)
                }
              }
              None => ()
            }
        }
      }
    } else {
      // Render via the native ViewerEx (with camera callbacks for PBR rendering).
      let v = @pk.new_viewer_ex(
        "PicoGK Gallery — " + name,
        1280,
        960,
        0.16,
        0.16,
        0.20,
        1.0,
      )
      if v.is_valid() {
        for idx, g in groups {
          match g.voxels {
            Some(vox) => {
              v.add_voxels(idx, vox)
              v.set_group_material(idx, g.color.to_ffi(), 0.1, 0.5)
            }
            None =>
              match g.mesh {
                Some(m) => {
                  v.add_mesh(idx, m)
                  v.set_group_material(idx, g.color.to_ffi(), 0.1, 0.5)
                }
                None => ()
              }
          }
        }
        let png_path = outdir + "/" + name + ".png"
        if v.screenshot_png(png_path, 12) {
          println("  -> " + png_path)
        } else {
          println("  ERROR: failed to write PNG")
        }
        v.request_close()
        v.destroy()
      } else {
        // No display — fall back to STL.
        println("  (Viewer not available — saving STLs only)")
        for idx, g in groups {
          match g.voxels {
            Some(vox) => {
              let mesh = vox.to_mesh()
              let stl_path = outdir +
                "/" +
                name +
                "_" +
                idx.to_string() +
                ".stl"
              if mesh.save_stl(stl_path) {
                println("  -> " + stl_path)
              }
              mesh.destroy()
            }
            None => ()
          }
        }
      }
    }

    // Cleanup.
    for g in groups {
      match g.voxels {
        Some(v) => v.destroy()
        None => ()
      }
      match g.mesh {
        Some(m) => m.destroy()
        None => ()
      }
    }
  }

  println("")
  println("done.")
  @pk.shutdown()
}

///|
fn parse_double(s : String) -> Double? {
  Some(@strconv.parse_double(s)) catch {
    _ => None
  }
}

// --- Shared modulations (matching the Go/Python gallery) ---

///|
fn line1(lr : Double) -> Double {
  10.0 - 3.0 * @math.cos(8.0 * lr)
}

///|
fn line2(lr : Double) -> Double {
  8.0 - @math.cos(40.0 * lr)
}

///|
fn surf1(phi : Double, lr : Double) -> Double {
  12.0 + 3.0 * @math.cos(5.0 * phi)
}

///|
fn surf3(phi : Double, lr : Double) -> Double {
  8.0 + 5.0 * @math.cos(5.0 * phi)
}

// --- Scene builders (matching Go ffi-gallery exactly) ---

///|
fn build_box() -> Array[@s.SceneGroup] {
  let b1 = @s.new_box(
    Some(@s.new_local_frame(@s.V(-50.0, 0.0, 0.0), None)),
    20.0,
    @s.line_const(10.0),
    @s.line_const(15.0),
  ).to_voxels()
  let b2 = @s.new_box(
    Some(@s.new_local_frame(@s.V(50.0, 0.0, 0.0), None)),
    20.0,
    @s.line_fn(line2),
    @s.line_fn(line1),
  ).to_voxels()
  let b3 = @s.new_box(
    Some(@s.new_local_frame(@s.V(0.0, 0.0, 0.0), None)),
    20.0,
    @s.line_fn(line2),
    @s.line_fn(line1),
  ).to_voxels()
  [
    @s.scene_group_voxels(b1, @s.palette["blue"].unwrap()),
    @s.scene_group_voxels(b2, @s.palette["green"].unwrap()),
    @s.scene_group_voxels(b3, @s.palette["yellow"].unwrap()),
  ]
}

///|
fn build_sphere() -> Array[@s.SceneGroup] {
  let s1 = @s.new_sphere(
    Some(@s.new_local_frame(@s.V(-100.0, 0.0, 0.0), None)),
    @s.surf_const(40.0),
  ).to_voxels()
  let s2 = @s.new_sphere(
    Some(@s.new_local_frame(@s.V(0.0, 0.0, 0.0), None)),
    @s.surf_fn(fn(phi : Double, theta : Double) {
      40.0 - 10.0 * @math.cos(6.0 * theta)
    }),
  ).to_voxels()
  let s3 = @s.new_sphere(
    Some(@s.new_local_frame(@s.V(150.0, 0.0, 0.0), None)),
    @s.surf_fn(fn(phi : Double, theta : Double) {
      40.0 - 10.0 * @math.cos(6.0 * theta) + 30.0 * @math.cos(2.0 * phi)
    }),
  ).to_voxels()
  [
    @s.scene_group_voxels(s1, @s.palette["frozen"].unwrap()),
    @s.scene_group_voxels(s2, @s.palette["pitaya"].unwrap()),
    @s.scene_group_voxels(s3, @s.palette["warning"].unwrap()),
  ]
}

///|
fn build_cylinder() -> Array[@s.SceneGroup] {
  let c1 = @s.new_cylinder(
    Some(@s.new_local_frame(@s.V(-50.0, 0.0, 0.0), None)),
    60.0,
    @s.surf_const(40.0),
  ).to_voxels()
  let c2 = @s.new_cylinder(
    Some(@s.new_local_frame(@s.V(50.0, 0.0, 0.0), None)),
    60.0,
    @s.surf_from_line(@s.line_fn(line1), "second"),
  ).to_voxels()
  let c3 = @s.new_cylinder(
    Some(@s.new_local_frame(@s.V(0.0, 0.0, 0.0), None)),
    60.0,
    @s.surf_fn(surf1),
  ).to_voxels()
  [
    @s.scene_group_voxels(c1, @s.palette["blue"].unwrap()),
    @s.scene_group_voxels(c2, @s.palette["green"].unwrap()),
    @s.scene_group_voxels(c3, @s.palette["yellow"].unwrap()),
  ]
}

///|
fn build_ring() -> Array[@s.SceneGroup] {
  let r1 = @s.new_ring(
    Some(@s.new_local_frame(@s.V(-50.0, -50.0, 0.0), None)),
    30.0,
    @s.surf_const(8.0),
  ).to_voxels()
  let r2 = @s.new_ring(
    Some(@s.new_local_frame(@s.V(-50.0, 50.0, 0.0), None)),
    30.0,
    @s.surf_fn(fn(phi : Double, _ : Double) {
      10.0 - 2.0 * @math.cos(5.0 * phi)
    }),
  ).to_voxels()
  let r3 = @s.new_ring(
    Some(@s.new_local_frame(@s.V(50.0, 50.0, 0.0), None)),
    30.0,
    @s.surf_fn(fn(_ : Double, alpha : Double) {
      10.0 + 3.0 * @math.cos(5.0 * alpha)
    }),
  ).to_voxels()
  let r4 = @s.new_ring(
    Some(@s.new_local_frame(@s.V(50.0, -50.0, 0.0), None)),
    30.0,
    @s.surf_fn(fn(phi : Double, alpha : Double) {
      10.0 - 2.0 * @math.cos(5.0 * (phi + alpha)) + 3.0 * @math.cos(5.0 * alpha)
    }),
  ).to_voxels()
  [
    @s.scene_group_voxels(r1, @s.palette["frozen"].unwrap()),
    @s.scene_group_voxels(r2, @s.palette["pitaya"].unwrap()),
    @s.scene_group_voxels(r3, @s.palette["warning"].unwrap()),
    @s.scene_group_voxels(r4, @s.palette["blueberry"].unwrap()),
  ]
}

///|
fn build_lens() -> Array[@s.SceneGroup] {
  let surf = fn(phi : Double, rr : Double) { 12.0 + 3.0 * @math.cos(5.0 * phi) }
  let l1 = @s.new_lens(
    Some(@s.new_local_frame(@s.V(-50.0, -50.0, 0.0), None)),
    10.0,
    10.0,
    40.0,
  ).to_voxels()
  let l2 = @s.new_lens_with_mods(
    Some(@s.new_local_frame(@s.V(50.0, 50.0, 0.0), None)),
    10.0,
    10.0,
    40.0,
    @s.surf_fn(fn(phi : Double, rr : Double) { 5.0 - surf(phi, rr) }),
    @s.surf_fn(fn(phi : Double, rr : Double) { 5.0 + surf(phi, rr) }),
  ).to_voxels()
  let l3 = @s.new_lens_with_mods(
    Some(@s.new_local_frame(@s.V(-50.0, 50.0, 0.0), None)),
    10.0,
    10.0,
    40.0,
    @s.surf_fn(fn(phi : Double, rr : Double) { 5.0 - surf(phi, rr) }),
    @s.surf_fn(fn(phi : Double, rr : Double) {
      5.0 +
      @math.cos(6.0 * (phi + 0.3 * 3.14159265358979 * rr)) +
      3.0 * @math.cos(20.0 * rr)
    }),
  ).to_voxels()
  [
    @s.scene_group_voxels(l1, @s.palette["frozen"].unwrap()),
    @s.scene_group_voxels(l2, @s.palette["pitaya"].unwrap()),
    @s.scene_group_voxels(l3, @s.palette["warning"].unwrap()),
  ]
}

///|
fn build_pipe() -> Array[@s.SceneGroup] {
  // Pipe 1: static blue pipe
  let p1 = @s.new_pipe(
    Some(@s.new_local_frame(@s.V(-50.0, 0.0, 0.0), None)),
    60.0,
    @s.surf_const(10.0),
    @s.surf_const(20.0),
  ).to_voxels()
  // Pipe 2: green pipe with vertex transform (creates a skewed/vase shape)
  let trafo = fn(pts : Array[@s.Vec3]) -> Array[@s.Vec3] {
    let result = Array::make(pts.length(), @s.V(0.0, 0.0, 0.0))
    for i, p in pts {
      result[i] = @s.V(p.y + 0.2 * p.z - 50.0, 0.5 * p.z + 50.0, 0.5 * p.x)
    }
    result
  }
  let p2 = @s.new_pipe_with_transform(
    Some(@s.new_local_frame(@s.V(0.0, 0.0, 0.0), None)),
    60.0,
    @s.surf_const(10.0),
    @s.surf_const(20.0),
    trafo,
  ).to_voxels()
  // Pipe 3: lemongrass pipe with modulated outer radius
  let p3 = @s.new_pipe(
    Some(@s.new_local_frame(@s.V(50.0, -50.0, 0.0), None)),
    60.0,
    @s.surf_const(6.0),
    @s.surf_from_line(@s.line_fn(line1), "second"),
  ).to_voxels()
  // Pipe 4: orchid pipe with modulated radii along a spline spine
  let spine = @s.frames_aligned_to_x(@s.spline_points(), @s.V(0.0, 1.0, 0.0))
  let p4 = @s.new_pipe_with_frames(
    None,
    60.0,
    @s.surf_fn(surf3),
    @s.surf_fn(surf1),
    spine,
  ).to_voxels()
  [
    @s.scene_group_voxels(p1, @s.palette["blue"].unwrap()),
    @s.scene_group_voxels(p2, @s.palette["green"].unwrap()),
    @s.scene_group_voxels(p3, @s.palette["lemongrass"].unwrap()),
    @s.scene_group_voxels(p4, @s.palette["orchid"].unwrap()),
  ]
}

///|
fn build_pipe_segment() -> Array[@s.SceneGroup] {
  let p1 = @s.new_pipe_segment(
    Some(@s.new_local_frame(@s.V(-50.0, 0.0, 0.0), None)),
    60.0,
    @s.surf_const(20.0),
    @s.surf_const(40.0),
    @s.line_const(3.14159265358979),
    @s.line_const(0.5 * 3.14159265358979),
    "mid_range",
  ).to_voxels()
  let p2 = @s.new_pipe_segment(
    Some(@s.new_local_frame(@s.V(50.0, 0.0, 0.0), None)),
    60.0,
    @s.surf_fn(surf3),
    @s.surf_fn(surf1),
    @s.line_fn(fn(lr : Double) { -3.14159265358979 * lr }),
    @s.line_const(1.75 * 3.14159265358979),
    "mid_range",
  ).to_voxels()
  let spine = @s.frames_aligned_to_x(@s.spline_points(), @s.V(0.0, 1.0, 0.0))
  let p3 = @s.new_pipe_segment_with_frames(
    None,
    60.0,
    @s.surf_fn(surf3),
    @s.surf_fn(surf1),
    @s.line_fn(fn(lr : Double) { 4.0 * 3.14159265358979 * lr }),
    @s.line_const(1.5 * 3.14159265358979),
    "mid_range",
    spine,
  ).to_voxels()
  [
    @s.scene_group_voxels(p1, @s.palette["blue"].unwrap()),
    @s.scene_group_voxels(p2, @s.palette["ruby"].unwrap()),
    @s.scene_group_voxels(p3, @s.palette["racing_green"].unwrap()),
  ]
}

///|
fn build_basic_lattices() -> Array[@s.SceneGroup] {
  let lat = @pk.new_lattice()
  lat.add_sphere(@pk.Vec3::new(1.0, 5.0, -10.0), 5.0)
  lat.add_beam(
    @pk.Vec3::new(5.0, 3.0, 0.0),
    @pk.Vec3::new(-3.0, 0.0, 7.0),
    1.0,
    3.0,
    true,
  )
  let v = @pk.from_lattice(lat)
  lat.destroy()
  [@s.scene_group_voxels(v, @s.palette["blueberry"].unwrap())]
}

///|
fn build_lattice_pipe() -> Array[@s.SceneGroup] {
  let lp1 = @s.new_lattice_pipe(
    Some(@s.new_local_frame(@s.V(-50.0, 0.0, 0.0), None)),
    60.0,
    @s.line_const(10.0),
  ).to_voxels()
  let lp2 = @s.new_lattice_pipe(
    Some(@s.new_local_frame(@s.V(50.0, -50.0, 0.0), None)),
    60.0,
    @s.line_fn(line1),
  ).to_voxels()
  let spine = @s.frames_aligned_to_x(@s.spline_points(), @s.V(0.0, 1.0, 0.0))
  let lp3 = @s.new_lattice_pipe_with_frames(
    None,
    60.0,
    @s.line_fn(line1),
    spine,
  ).to_voxels()
  [
    @s.scene_group_voxels(lp1, @s.palette["yellow"].unwrap()),
    @s.scene_group_voxels(lp2, @s.palette["frozen"].unwrap()),
    @s.scene_group_voxels(lp3, @s.palette["racing_green"].unwrap()),
  ]
}

///|
fn build_lattice_manifold() -> Array[@s.SceneGroup] {
  // local_z=(0,1,0) means the manifold extends along Y from the frame position
  let lm1 = @s.new_lattice_manifold(
    @s.new_local_frame_xyz(
      @s.V(-50.0, 0.0, 0.0),
      @s.V(0.0, 1.0, 0.0),
      @s.V(1.0, 0.0, 0.0),
    ),
    50.0,
    5.0,
    45.0,
  ).to_voxels()
  let lm2 = @s.new_lattice_manifold(
    @s.new_local_frame_xyz(
      @s.V(0.0, 0.0, 0.0),
      @s.V(0.0, 1.0, 0.0),
      @s.V(1.0, 0.0, 0.0),
    ),
    50.0,
    10.0,
    30.0,
  ).to_voxels()
  let lm3 = @s.new_lattice_manifold(
    @s.new_local_frame_xyz(
      @s.V(50.0, 0.0, 0.0),
      @s.V(0.0, 1.0, 0.0),
      @s.V(1.0, 0.0, 0.0),
    ),
    50.0,
    5.0,
    60.0,
  ).to_voxels()
  [
    @s.scene_group_voxels(lm1, @s.palette["yellow"].unwrap()),
    @s.scene_group_voxels(lm2, @s.palette["crystal"].unwrap()),
    @s.scene_group_voxels(lm3, @s.palette["green"].unwrap()),
  ]
}

///|
fn build_gyroid_sphere() -> Array[@s.SceneGroup] {
  let gyroid = @s.new_implicit_gyroid(3, 1)
  let r = 10.0
  let vox = @pk.new_voxels()
  let pad = 2.0
  vox.render_gyroid_sphere(
    @pk.BBox3::new(
      @pk.Vec3::new(-r - pad, -r - pad, -r - pad),
      @pk.Vec3::new(r + pad, r + pad, r + pad),
    ),
    r,
    0.5,
    gyroid.frequency,
  )
  [@s.scene_group_voxels(vox, @s.palette["billie"].unwrap())]
}

///|
fn build_gyroid_genus() -> Array[@s.SceneGroup] {
  let s = 8.0
  let vox = @pk.new_voxels()
  vox.render_gyroid_genus(
    @pk.BBox3::new(
      @pk.Vec3::new(-3.0 * s, -3.0 * s, -1.6 * s),
      @pk.Vec3::new(3.0 * s, 3.0 * s, 1.6 * s),
    ),
    s,
    0.0,
    2.0 * 3.14159265358979 / 10.0,
  )
  [@s.scene_group_voxels(vox, @s.palette["lavender"].unwrap())]
}

///|
fn build_superellipsoid() -> Array[@s.SceneGroup] {
  let a = 16.0
  let specs = [
    (@s.V(-45.0, 0.0, 0.0), 3.0, 0.25, @s.palette["ruby"].unwrap()),
    (@s.V(0.0, 0.0, 0.0), 1.5, 1.5, @s.palette["blue"].unwrap()),
    (@s.V(45.0, 0.0, 0.0), 0.25, 0.25, @s.palette["bubblegum"].unwrap()),
  ]
  let groups : Array[@s.SceneGroup] = []
  for spec in specs {
    let center = spec.0
    let e1 = spec.1
    let e2 = spec.2
    let color = spec.3
    let vox = @pk.new_voxels()
    vox.render_superellipsoid(
      @pk.BBox3::new(
        @pk.Vec3::new(center.x - a, center.y - a, center.z - a),
        @pk.Vec3::new(center.x + a, center.y + a, center.z + a),
      ),
      a,
      a,
      a,
      e1,
      e2,
    )
    groups.push(@s.scene_group_voxels(vox, color))
  }
  groups
}

///|
fn build_mesh_painter() -> Array[@s.SceneGroup] {
  // Build a sphere mesh and split it by overhang angle into colored groups
  // (approximated as a single sphere for now)
  let s = @s.new_sphere(None, @s.surf_const(40.0)).to_voxels()
  [@s.scene_group_voxels(s, @s.palette["frozen"].unwrap())]
}

///|
fn build_mesh_trafo() -> Array[@s.SceneGroup] {
  let box = @s.new_box(
    Some(@s.new_local_frame(@s.V(0.0, 0.0, 0.0), None)),
    40.0,
    @s.line_const(30.0),
    @s.line_const(20.0),
  ).to_voxels()
  // Rotate 45° around Z — need mesh round-trip
  let mesh = box.to_mesh()
  box.destroy()
  let verts = mesh.vertices_arr()
  let tris = mesh.triangles_arr()
  let c = @math.cos(3.14159265358979 / 4.0)
  let s_val = @math.sin(3.14159265358979 / 4.0)
  for i in 0..<(verts.length() / 3) {
    let x = verts[i * 3]
    let y = verts[i * 3 + 1]
    verts[i * 3] = c * x - s_val * y
    verts[i * 3 + 1] = s_val * x + c * y
  }
  let rotated_mesh = @pk.mesh_from_arrays(verts, tris)
  mesh.destroy()
  let rotated_vox = @pk.from_mesh(rotated_mesh)
  rotated_mesh.destroy()
  let original_box = @s.new_box(
    Some(@s.new_local_frame(@s.V(0.0, 0.0, 0.0), None)),
    40.0,
    @s.line_const(30.0),
    @s.line_const(20.0),
  ).to_voxels()
  [
    @s.scene_group_voxels(original_box, @s.palette["gray"].unwrap()),
    @s.scene_group_voxels(rotated_vox, @s.palette["orchid"].unwrap()),
  ]
}

///|
fn build_over_offset() -> Array[@s.SceneGroup] {
  let b1 = @s.new_box(
    Some(@s.new_local_frame(@s.V(-15.0, 0.0, 0.0), None)),
    30.0,
    @s.line_const(30.0),
    @s.line_const(30.0),
  ).to_voxels()
  let b2 = @s.new_box(
    Some(@s.new_local_frame(@s.V(15.0, 0.0, 0.0), None)),
    30.0,
    @s.line_const(30.0),
    @s.line_const(30.0),
  ).to_voxels()
  b1.bool_add(b2)
  b2.destroy()
  b1.double_offset(4.0, -4.0)
  [@s.scene_group_voxels(b1, @s.palette["bubblegum"].unwrap())]
}
