// picogkffi lattice: Beam-and-node lattice structure.

///|
pub struct Lattice {
  h : Int64
}

///|
pub fn new_lattice() -> Lattice {
  Lattice::{ h: lattice_h_create(get_instance()) }
}

///|
pub fn Lattice::destroy(self : Lattice) -> Unit {
  lattice_destroy(get_instance(), self.h)
}

///|
pub fn Lattice::is_valid(self : Lattice) -> Bool {
  lattice_b_is_valid(get_instance(), self.h)
}

///|
pub fn Lattice::mem_usage(self : Lattice) -> Int64 {
  lattice_n_mem_usage(get_instance(), self.h)
}

///|
pub fn Lattice::add_sphere(
  self : Lattice,
  center : Vec3,
  radius : Double,
) -> Unit {
  lattice_add_sphere(
    get_instance(),
    self.h,
    pack_vec3(center),
    Float::from_double(radius),
  )
}

///|
pub fn Lattice::add_beam(
  self : Lattice,
  start : Vec3,
  end : Vec3,
  radius1 : Double,
  radius2 : Double,
  round_cap : Bool,
) -> Unit {
  lattice_add_beam(
    get_instance(),
    self.h,
    pack_vec3(start),
    pack_vec3(end),
    Float::from_double(radius1),
    Float::from_double(radius2),
    round_cap,
  )
}
