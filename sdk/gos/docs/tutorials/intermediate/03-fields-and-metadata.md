# Intermediate 3 — Fields and metadata

## Overview

The FFI SDK exposes `ScalarField`, `VectorField`, and `Metadata` types
directly — the same types the Python PicoPie binding provides. These let
you attach per-voxel data and key/value annotations to voxel objects, all
of which persist in OpenVDB files alongside the geometry.

## Scalar fields

A `ScalarField` stores a `f64` value at each active voxel point. The
most common way to create one is from an existing voxel field:

```gos
use picogkffi::{init, shutdown, new_sphere, voxels_bool_subtract,
    scalar_field_from_voxels, scalar_field_set_value, scalar_field_get_value,
    voxels_destroy, Vec3}

fn main() {
    match init(0.3) {
        Ok(_) => (),
        Err(e) => { eprintln!("init: {}", e); return }
    }
    defer shutdown()

    // Build a part.
    let body = match new_sphere(Vec3 { x: 0.0, y: 0.0, z: 0.0 }, 10.0) {
        Ok(h) => h,
        Err(e) => { eprintln!("sphere: {}", e); return }
    }
    let hole = match new_sphere(Vec3 { x: 6.0, y: 0.0, z: 0.0 }, 6.0) {
        Ok(h) => h,
        Err(e) => { eprintln!("hole: {}", e); return }
    }
    voxels_bool_subtract(body, hole)

    // Create a scalar field from the voxels:
    let sf = scalar_field_from_voxels(body)

    // Set and get values:
    scalar_field_set_value(sf, Vec3 { x: 0.0, y: 0.0, z: 0.0 }, -1.0)
    match scalar_field_get_value(sf, Vec3 { x: 0.0, y: 0.0, z: 0.0 }) {
        Some(v) => println!("scalar field value @ origin: {}", v),
        None => println!("no value at origin"),
    }

    voxels_destroy(body)
}
```

## Vector fields

A `VectorField` stores a `Vec3` value at each active voxel point — useful
for storing normals, flow directions, or other vector data:

```gos
use picogkffi::{new_sphere, vector_field_from_voxels, vector_field_set_value,
    vector_field_get_value, voxels_destroy, Vec3}

let vf = vector_field_from_voxels(body)
vector_field_set_value(vf, Vec3 { x: 0.0, y: 0.0, z: 0.0 }, Vec3 { x: 1.0, y: 0.0, z: 0.0 })
match vector_field_get_value(vf, Vec3 { x: 0.0, y: 0.0, z: 0.0 }) {
    Some(v) => println!("vector field value: ({}, {}, {})", v.x, v.y, v.z),
    None => println!("no value"),
}
```

## Metadata

Metadata holds key/value pairs attached to a voxel field:

```gos
use picogkffi::{new_sphere, metadata_from_voxels, metadata_set_string, metadata_get_string,
    metadata_set_float, metadata_get_float, voxels_destroy, Vec3}

let md = metadata_from_voxels(body)
metadata_set_string(md, "part", "ball")
metadata_set_float(md, "density", 1.2)
match metadata_get_string(md, "part") {
    Some(v) => println!("metadata part: {}", v),
    None => println!("no part metadata"),
}
```

## Complete example

```gos
use picogkffi::{init, shutdown, new_sphere, voxels_bool_subtract,
    scalar_field_from_voxels, scalar_field_set_value, scalar_field_get_value,
    vector_field_from_voxels, vector_field_set_value, vector_field_get_value,
    metadata_from_voxels, metadata_set_string, metadata_get_string,
    metadata_set_float, metadata_get_float,
    voxels_destroy, Vec3}

fn main() {
    match init(0.3) {
        Ok(_) => (),
        Err(e) => { eprintln!("init: {}", e); return }
    }
    defer shutdown()

    let body = match new_sphere(Vec3 { x: 0.0, y: 0.0, z: 0.0 }, 10.0) {
        Ok(h) => h,
        Err(e) => { eprintln!("sphere: {}", e); return }
    }
    let hole = match new_sphere(Vec3 { x: 6.0, y: 0.0, z: 0.0 }, 6.0) {
        Ok(h) => h,
        Err(e) => { eprintln!("hole: {}", e); return }
    }
    voxels_bool_subtract(body, hole)

    // Scalar field
    let sf = scalar_field_from_voxels(body)
    scalar_field_set_value(sf, Vec3 { x: 0.0, y: 0.0, z: 0.0 }, -1.0)
    match scalar_field_get_value(sf, Vec3 { x: 0.0, y: 0.0, z: 0.0 }) {
        Some(v) => println!("scalar: {}", v),
        None => println!("no scalar value"),
    }

    // Vector field
    let vf = vector_field_from_voxels(body)
    vector_field_set_value(vf, Vec3 { x: 0.0, y: 0.0, z: 0.0 }, Vec3 { x: 1.0, y: 0.0, z: 0.0 })
    match vector_field_get_value(vf, Vec3 { x: 0.0, y: 0.0, z: 0.0 }) {
        Some(v) => println!("vector: ({}, {}, {})", v.x, v.y, v.z),
        None => println!("no vector value"),
    }

    // Metadata
    let md = metadata_from_voxels(body)
    metadata_set_string(md, "part", "ball")
    metadata_set_float(md, "density", 1.2)
    match metadata_get_string(md, "part") {
        Some(v) => println!("meta part: {}", v),
        None => println!("no metadata"),
    }
    match metadata_get_float(md, "density") {
        Some(v) => println!("meta density: {}", v),
        None => println!("no density"),
    }

    voxels_destroy(body)
}
```

## Next steps

- [Advanced 1 — Performance →](../advanced/01-performance.md)
