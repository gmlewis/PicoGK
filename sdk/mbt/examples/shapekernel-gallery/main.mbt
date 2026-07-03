///|
/// ShapeKernel example gallery — a MoonBit port of LEAP71_ShapeKernel/Examples.
///
/// Each scene constructs one or more voxel objects using the PicoGK FFI SDK
/// primitives, booleans, lattices, and implicit SDF rendering. The scenes
/// are exported as STL files and rendered to PNG via the native Viewer.
///
/// Run:  moon run . --target native [-out DIR] [-voxel-size MM] [-no-viewer] [-scene NAME]
fn main {
  // Parse command-line arguments.
  let cmd = @argparse.Command(
    "shapekernel-gallery",
    about="PicoGK ShapeKernel Gallery (MoonBit FFI)",
    flags=[
      @argparse.FlagArg("no-viewer", long="no-viewer", about="Save STLs only (no display needed)"),
    ],
    options=[
      @argparse.OptionArg("out", long="out", about="Output directory", default_values=["/tmp/mbt-picogk-gallery"]),
      @argparse.OptionArg("voxel-size", long="voxel-size", about="Voxel size in mm", default_values=["0.2"]),
      @argparse.OptionArg("scene", long="scene", about="Render only this scene", default_values=[""]),
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
  let scenes : Array[(String, Array[SceneGroup])] = []
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
        if g.voxels.is_valid() {
          g.voxels.destroy()
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
        if g.voxels.is_valid() {
          let mesh = g.voxels.to_mesh()
          let stl_path = outdir + "/" + name + "_" + idx.to_string() + ".stl"
          if mesh.save_stl(stl_path) {
            println("  -> " + stl_path)
          }
          mesh.destroy()
        }
      }
    } else {
      // Render via the native ViewerEx (with camera callbacks for 3D rendering).
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
          if g.voxels.is_valid() {
            v.add_voxels(idx, g.voxels)
            v.set_group_material(idx, g.color, 0.1, 0.5)
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
          if g.voxels.is_valid() {
            let mesh = g.voxels.to_mesh()
            let stl_path = outdir + "/" + name + "_" + idx.to_string() + ".stl"
            if mesh.save_stl(stl_path) {
              println("  -> " + stl_path)
            }
            mesh.destroy()
          }
        }
      }
    }

    // Cleanup.
    for g in groups {
      if g.voxels.is_valid() {
        g.voxels.destroy()
      }
    }
  }

  println("")
  println("done.")
  @pk.shutdown()
}

///|
struct SceneGroup {
  voxels : @pk.Voxels
  color : @pk.ColorFloat
}

///|
/// Create a SceneGroup from voxels with a color.
fn group(vox : @pk.Voxels, color : @pk.ColorFloat) -> SceneGroup {
  SceneGroup::{ voxels: vox, color }
}

///|
/// Parse a double from a string, returning None on failure.
fn parse_double(s : String) -> Double? {
  try {
    Some(@strconv.parse_double(s))
  } catch {
    _ => None
  }
}

// --- Color palette (matching PicoPie/Go palette) ---

///|
let col_frozen : @pk.ColorFloat = @pk.ColorFloat::new(0.6, 0.8, 1.0, 1.0)

///|
let col_pitaya : @pk.ColorFloat = @pk.ColorFloat::new(0.95, 0.45, 0.55, 1.0)

///|
let col_warning : @pk.ColorFloat = @pk.ColorFloat::new(0.95, 0.7, 0.25, 1.0)

///|
let col_blue : @pk.ColorFloat = @pk.ColorFloat::new(0.35, 0.6, 0.9, 1.0)

///|
let col_green : @pk.ColorFloat = @pk.ColorFloat::new(0.3, 0.7, 0.4, 1.0)

///|
let col_yellow : @pk.ColorFloat = @pk.ColorFloat::new(0.9, 0.85, 0.3, 1.0)

///|
let col_blueberry : @pk.ColorFloat = @pk.ColorFloat::new(0.3, 0.35, 0.6, 1.0)

///|
let col_ruby : @pk.ColorFloat = @pk.ColorFloat::new(0.8, 0.2, 0.3, 1.0)

///|
let col_bubblegum : @pk.ColorFloat = @pk.ColorFloat::new(0.9, 0.5, 0.8, 1.0)

///|
let col_orchid : @pk.ColorFloat = @pk.ColorFloat::new(0.6, 0.4, 0.8, 1.0)

///|
let col_gray : @pk.ColorFloat = @pk.ColorFloat::new(0.5, 0.5, 0.5, 1.0)

///|
let col_lemongrass : @pk.ColorFloat = @pk.ColorFloat::new(0.7, 0.8, 0.3, 1.0)

///|
let col_racing_green : @pk.ColorFloat = @pk.ColorFloat::new(0.1, 0.4, 0.2, 1.0)

///|
let col_crystal : @pk.ColorFloat = @pk.ColorFloat::new(0.5, 0.8, 0.9, 1.0)

///|
let col_billie : @pk.ColorFloat = @pk.ColorFloat::new(0.4, 0.3, 0.6, 1.0)

///|
let col_lavender : @pk.ColorFloat = @pk.ColorFloat::new(0.7, 0.6, 0.9, 1.0)

// --- Shared modulation functions (matching the Go/Python gallery) ---

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

// --- Scenes ---

///|
fn build_box() -> Array[SceneGroup] {
  // Box at (-50,0,0): 20x10x15
  let b1 = @pk.new_box(-60.0, -5.0, -7.5, -40.0, 5.0, 7.5)
  // Box at (50,0,0): modulated width/depth (approximated with constant)
  let b2 = @pk.new_box(40.0, -4.0, -5.0, 60.0, 4.0, 5.0)
  // Box at (0,0,0): modulated width/depth (approximated)
  let b3 = @pk.new_box(-10.0, -4.0, -5.0, 10.0, 4.0, 5.0)
  [
    group(b1, col_blue),
    group(b2, col_green),
    group(b3, col_yellow),
  ]
}

///|
fn build_sphere() -> Array[SceneGroup] {
  let s1 = @pk.new_sphere(@pk.Vec3::new(-100.0, 0.0, 0.0), 40.0)
  let s2 = @pk.new_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 37.0)
  let s3 = @pk.new_sphere(@pk.Vec3::new(150.0, 0.0, 0.0), 42.0)
  [
    group(s1, col_frozen),
    group(s2, col_pitaya),
    group(s3, col_warning),
  ]
}

///|
fn build_cylinder() -> Array[SceneGroup] {
  let c1 = @pk.new_cylinder(-50.0, 0.0, -30.0, 40.0, 60.0, None, None, None)
  let c2 = @pk.new_cylinder(50.0, 0.0, -30.0, 10.0, 60.0, None, None, None)
  let c3 = @pk.new_cylinder(0.0, 0.0, -30.0, 12.0, 60.0, None, None, None)
  [
    group(c1, col_blue),
    group(c2, col_green),
    group(c3, col_yellow),
  ]
}

///|
fn build_ring() -> Array[SceneGroup] {
  let r1 = torus(30.0, 8.0, @pk.Vec3::new(-50.0, -50.0, 0.0))
  let r2 = torus(30.0, 8.0, @pk.Vec3::new(-50.0, 50.0, 0.0))
  let r3 = torus(30.0, 11.0, @pk.Vec3::new(50.0, 50.0, 0.0))
  let r4 = torus(30.0, 10.0, @pk.Vec3::new(50.0, -50.0, 0.0))
  [
    group(r1, col_frozen),
    group(r2, col_pitaya),
    group(r3, col_warning),
    group(r4, col_blueberry),
  ]
}

///|
fn build_lens() -> Array[SceneGroup] {
  // Approximated lens with spheres (no parametric lens shape in FFI primitives).
  let l1 = @pk.new_sphere(@pk.Vec3::new(-50.0, -50.0, 0.0), 20.0)
  let l2 = @pk.new_sphere(@pk.Vec3::new(50.0, 50.0, 0.0), 18.0)
  let l3 = @pk.new_sphere(@pk.Vec3::new(-50.0, 50.0, 0.0), 22.0)
  [
    group(l1, col_frozen),
    group(l2, col_pitaya),
    group(l3, col_warning),
  ]
}

///|
fn build_pipe() -> Array[SceneGroup] {
  // Pipes approximated with hollow cylinders.
  let p1 = hollow_pipe(-50.0, 0.0, -30.0, 20.0, 10.0, 60.0)
  let p2 = hollow_pipe(0.0, 0.0, -30.0, 20.0, 10.0, 60.0)
  let p3 = hollow_pipe(50.0, -50.0, -30.0, 10.0, 6.0, 60.0)
  let p4 = hollow_pipe(0.0, 0.0, 0.0, 12.0, 8.0, 60.0)
  [
    group(p1, col_blue),
    group(p2, col_green),
    group(p3, col_lemongrass),
    group(p4, col_orchid),
  ]
}

///|
fn build_pipe_segment() -> Array[SceneGroup] {
  let ps1 = hollow_pipe(-50.0, 0.0, -30.0, 40.0, 20.0, 60.0)
  let ps2 = hollow_pipe(50.0, 0.0, -30.0, 12.0, 8.0, 60.0)
  let ps3 = hollow_pipe(0.0, 0.0, 0.0, 12.0, 8.0, 60.0)
  [
    group(ps1, col_blue),
    group(ps2, col_ruby),
    group(ps3, col_racing_green),
  ]
}

///|
fn build_basic_lattices() -> Array[SceneGroup] {
  let lat = @pk.new_lattice()
  lat.add_sphere(@pk.Vec3::new(1.0, 5.0, -10.0), 5.0)
  lat.add_beam(
    @pk.Vec3::new(5.0, 3.0, 0.0),
    @pk.Vec3::new(-3.0, 0.0, 7.0),
    1.0,
    3.0,
    true,
  )
  let vox = @pk.from_lattice(lat)
  lat.destroy()
  [group(vox, col_blueberry)]
}

///|
fn build_lattice_pipe() -> Array[SceneGroup] {
  let lp1 = @pk.new_cylinder(-50.0, 0.0, -30.0, 10.0, 60.0, None, None, None)
  let lp2 = @pk.new_cylinder(50.0, -50.0, -30.0, 10.0, 60.0, None, None, None)
  let lp3 = @pk.new_cylinder(0.0, 0.0, 0.0, 10.0, 60.0, None, None, None)
  [
    group(lp1, col_yellow),
    group(lp2, col_frozen),
    group(lp3, col_racing_green),
  ]
}

///|
fn build_lattice_manifold() -> Array[SceneGroup] {
  let lm1 = @pk.new_cylinder(-50.0, -25.0, 0.0, 5.0, 50.0, Some(0.0), Some(1.0), Some(0.0))
  let lm2 = @pk.new_cylinder(0.0, -25.0, 0.0, 10.0, 50.0, Some(0.0), Some(1.0), Some(0.0))
  let lm3 = @pk.new_cylinder(50.0, -25.0, 0.0, 5.0, 50.0, Some(0.0), Some(1.0), Some(0.0))
  [
    group(lm1, col_yellow),
    group(lm2, col_crystal),
    group(lm3, col_green),
  ]
}

///|
fn build_gyroid_sphere() -> Array[SceneGroup] {
  // Real gyroid sphere via implicit SDF — same approach as PicoPie/Go FFI.
  let unit_size = 3.0
  let k = 2.0 * 3.14159265358979 / unit_size
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
    k,
  )
  [group(vox, col_billie)]
}

///|
fn build_gyroid_genus() -> Array[SceneGroup] {
  // Real gyroid genus via implicit SDF — same approach as PicoPie/Go FFI.
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
  [group(vox, col_lavender)]
}

///|
fn build_superellipsoid() -> Array[SceneGroup] {
  // Real superellipsoid via implicit SDF — same approach as PicoPie/Go FFI.
  // Three superellipsoids at different positions.
  let a = 16.0
  let specs = [
    (@pk.Vec3::new(-45.0, 0.0, 0.0), 3.0, 0.25, col_ruby),
    (@pk.Vec3::new(0.0, 0.0, 0.0), 1.5, 1.5, col_blue),
    (@pk.Vec3::new(45.0, 0.0, 0.0), 0.25, 0.25, col_bubblegum),
  ]
  let groups : Array[SceneGroup] = []
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
    groups.push(group(vox, color))
  }
  groups
}

///|
fn build_mesh_painter() -> Array[SceneGroup] {
  // Approximated mesh painter: a single sphere.
  let s = @pk.new_sphere(@pk.Vec3::new(0.0, 0.0, 0.0), 40.0)
  [group(s, col_frozen)]
}

///|
fn build_mesh_trafo() -> Array[SceneGroup] {
  // Box + rotated box (approximated with two boxes).
  let box1 = @pk.new_box(-20.0, -15.0, -10.0, 20.0, 15.0, 10.0)
  let box2 = @pk.new_box(-20.0, -15.0, -10.0, 20.0, 15.0, 10.0)
  box2.offset(0.0)
  [
    group(box1, col_gray),
    group(box2, col_orchid),
  ]
}

///|
fn build_over_offset() -> Array[SceneGroup] {
  let b1 = @pk.new_box(-30.0, -15.0, -15.0, 0.0, 15.0, 15.0)
  let b2 = @pk.new_box(0.0, -15.0, -15.0, 30.0, 15.0, 15.0)
  b1.bool_add(b2)
  b2.destroy()
  b1.double_offset(4.0, -4.0)
  [group(b1, col_bubblegum)]
}

// --- Helper functions ---

///|
/// torus creates a torus voxel object by sweeping capsules in a circle.
fn torus(
  major_radius : Double,
  minor_radius : Double,
  center : @pk.Vec3,
) -> @pk.Voxels {
  let n_segments = 32
  let mut result : @pk.Voxels? = None
  for i in 0..<n_segments {
    let angle1 = i.to_double() / n_segments.to_double() * 2.0 * 3.14159265358979
    let angle2 = (i + 1).to_double() /
      n_segments.to_double() *
      2.0 *
      3.14159265358979
    let x1 = center.x + major_radius * @math.cos(angle1)
    let y1 = center.y + major_radius * @math.sin(angle1)
    let z1 = center.z
    let x2 = center.x + major_radius * @math.cos(angle2)
    let y2 = center.y + major_radius * @math.sin(angle2)
    let z2 = center.z
    let seg = @pk.new_capsule(
      @pk.Vec3::new(x1, y1, z1),
      @pk.Vec3::new(x2, y2, z2),
      minor_radius,
      minor_radius,
    )
    match result {
      Some(prev) => {
        let combined = prev.add(seg)
        prev.destroy()
        seg.destroy()
        result = Some(combined)
      }
      None => result = Some(seg)
    }
  }
  result.unwrap()
}

///|
/// hollow_pipe creates a hollow cylinder (pipe) by subtracting inner from outer.
fn hollow_pipe(
  x : Double,
  y : Double,
  z : Double,
  outer_r : Double,
  inner_r : Double,
  height : Double,
) -> @pk.Voxels {
  let outer = @pk.new_cylinder(x, y, z, outer_r, height, None, None, None)
  let inner = @pk.new_cylinder(x, y, z, inner_r, height, None, None, None)
  let pipe = outer.sub(inner)
  outer.destroy()
  inner.destroy()
  pipe
}