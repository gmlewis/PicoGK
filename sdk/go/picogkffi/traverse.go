package picogkffi

/*
#include <stdlib.h>
#include "picogk_ffi.h"

// The //export functions from trampoline.go are auto-declared as extern by cgo.
extern void goScalarFieldTraverseTrampoline(const PKVector3*, float);
extern void goVectorFieldTraverseTrampoline(const PKVector3*, const PKVector3*);
*/
import "C"

// TraverseActive calls fn for every active voxel with its position and value.
func (sf *ScalarField) TraverseActive(fn func(pt Vec3, val float32)) {
	setScalarFieldTraverseCallback(fn)
	defer clearScalarFieldTraverseCallback()
	C.ScalarField_TraverseActive(instance, sf.h, C.PKFnTraverseActiveS(C.goScalarFieldTraverseTrampoline))
}

// TraverseActive calls fn for every active voxel with its position and vector value.
func (vf *VectorField) TraverseActive(fn func(pt, val Vec3)) {
	setVectorFieldTraverseCallback(fn)
	defer clearVectorFieldTraverseCallback()
	C.VectorField_TraverseActive(instance, vf.h, C.PKFnTraverseActiveV(C.goVectorFieldTraverseTrampoline))
}
