package picogkffi

/*
#include <stdlib.h>
#include "picogk_ffi.h"

// goSdfTrampoline is defined in trampoline.go via //export.
// We declare it extern here so this translation unit can reference it.
extern float goSdfTrampoline(const PKVector3* coord);
static PKPFnfSdf getSdfCallback() {
    return (PKPFnfSdf)goSdfTrampoline;
}
*/
import "C"

// SDF is a signed-distance function callback for implicit rendering.
type SDF struct {
	fn func(x, y, z float32) float32
}

// NewSDF creates an SDF callback from a Go function.
func NewSDF(fn func(x, y, z float32) float32) *SDF {
	return &SDF{fn: fn}
}

// currentSDF is the SDF currently being evaluated (single active callback).
var currentSDF *SDF

// RenderImplicitWith renders an implicit SDF into this voxel field.
func (v *Voxels) RenderImplicitWith(bbox BBox3, sdf *SDF) {
	currentSDF = sdf
	defer func() { currentSDF = nil }()
	cmin := bbox.Min.toC()
	cmax := bbox.Max.toC()
	cbbox := C.PKBBox3{vecMin: cmin, vecMax: cmax}
	C.Voxels_RenderImplicit(instance, v.h, &cbbox, C.getSdfCallback())
}

// IntersectImplicitWith clips this voxel field by an implicit SDF (in-place).
func (v *Voxels) IntersectImplicitWith(sdf *SDF) {
	currentSDF = sdf
	defer func() { currentSDF = nil }()
	C.Voxels_IntersectImplicit(instance, v.h, C.getSdfCallback())
}