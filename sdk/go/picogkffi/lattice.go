package picogkffi

/*
#include <stdlib.h>
#include "picogk_ffi.h"
*/
import "C"

// Lattice is a beam-and-node structure that can be rasterized into voxels.
type Lattice struct {
	h C.PKLATTICE
}

// NewLattice creates an empty lattice.
func NewLattice() *Lattice {
	mustInit()
	return &Lattice{h: C.Lattice_hCreate(instance)}
}

// Destroy frees the native lattice handle.
func (lat *Lattice) Destroy() {
	if lat.h != 0 {
		C.Lattice_Destroy(instance, lat.h)
		lat.h = 0
	}
}

// IsValid returns true if the handle is valid.
func (lat *Lattice) IsValid() bool {
	return lat.h != 0 && bool(C.Lattice_bIsValid(instance, lat.h))
}

// MemUsage returns memory in bytes.
func (lat *Lattice) MemUsage() int64 {
	return int64(C.Lattice_nMemUsage(instance, lat.h))
}

// AddSphere adds a sphere node at center with the given radius.
func (lat *Lattice) AddSphere(center Vec3, radius float32) {
	c := center.toC()
	C.Lattice_AddSphere(instance, lat.h, &c, C.float(radius))
}

// AddBeam adds a beam from start to end with (optionally tapered) radii.
func (lat *Lattice) AddBeam(start, end Vec3, radiusStart, radiusEnd float32, roundCap bool) {
	s, e := start.toC(), end.toC()
	C.Lattice_AddBeam(instance, lat.h, &s, &e, C.float(radiusStart), C.float(radiusEnd), C.bool(roundCap))
}

// ToVoxels rasterizes the lattice into a voxel field.
func (lat *Lattice) ToVoxels() *Voxels {
	return FromLattice(lat)
}
