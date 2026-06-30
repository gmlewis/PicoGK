package picogkffi

// This file contains only the //export callback. It must NOT have a C
// preamble with extern declarations — cgo auto-generates them.

/*
#include <stdlib.h>
#include "picogk_ffi.h"
*/
import "C"

//export goSdfTrampoline
func goSdfTrampoline(coord *C.PKVector3) C.float {
	if currentSDF == nil {
		return C.float(1.0e30)
	}
	x, y, z := float32(coord.X), float32(coord.Y), float32(coord.Z)
	r := currentSDF.fn(x, y, z)
	if r != r { // NaN
		return C.float(1.0e30)
	}
	return C.float(r)
}

// ScalarField traverse callback support.
var currentScalarFieldTraverse func(pt Vec3, val float32)

func setScalarFieldTraverseCallback(fn func(pt Vec3, val float32)) {
	currentScalarFieldTraverse = fn
}

func clearScalarFieldTraverseCallback() {
	currentScalarFieldTraverse = nil
}

//export goScalarFieldTraverseTrampoline
func goScalarFieldTraverseTrampoline(coord *C.PKVector3, val C.float) {
	if currentScalarFieldTraverse == nil {
		return
	}
	currentScalarFieldTraverse(vec3FromC(*coord), float32(val))
}

// VectorField traverse callback support.
var currentVectorFieldTraverse func(pt, val Vec3)

func setVectorFieldTraverseCallback(fn func(pt, val Vec3)) {
	currentVectorFieldTraverse = fn
}

func clearVectorFieldTraverseCallback() {
	currentVectorFieldTraverse = nil
}

//export goVectorFieldTraverseTrampoline
func goVectorFieldTraverseTrampoline(coord *C.PKVector3, val *C.PKVector3) {
	if currentVectorFieldTraverse == nil {
		return
	}
	currentVectorFieldTraverse(vec3FromC(*coord), vec3FromC(*val))
}
