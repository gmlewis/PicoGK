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