package picogkffi

/*
#include <stdlib.h>
#include "picogk_ffi.h"
*/
import "C"

// Vec3 is a 3D float vector (mm).
type Vec3 struct {
	X, Y, Z float32
}

// BBox3 is an axis-aligned bounding box.
type BBox3 struct {
	Min, Max Vec3
}

// Triangle is a triangle defined by 3 vertex indices.
type Triangle struct {
	A, B, C int32
}

// ColorFloat is an RGBA float color (0..1).
type ColorFloat struct {
	R, G, B, A float32
}

// Handle is an opaque native object handle.
type Handle uint64

// toC converts a Vec3 to a C PKVector3.
func (v Vec3) toC() C.PKVector3 {
	return C.PKVector3{X: C.float(v.X), Y: C.float(v.Y), Z: C.float(v.Z)}
}

// vec3FromC converts a C PKVector3 to a Vec3.
func vec3FromC(cv C.PKVector3) Vec3 {
	return Vec3{X: float32(cv.X), Y: float32(cv.Y), Z: float32(cv.Z)}
}

// bboxFromC converts a C PKBBox3 to a BBox3.
func bboxFromC(cb C.PKBBox3) BBox3 {
	return BBox3{Min: vec3FromC(cb.vecMin), Max: vec3FromC(cb.vecMax)}
}

// cString writes a Go string into a C char buffer and returns it.
func cStringBuf(s string, buf []C.char) {
	for i := 0; i < len(buf) && i < len(s); i++ {
		buf[i] = C.char(s[i])
	}
	if len(buf) > 0 {
		if len(s) < len(buf) {
			buf[len(s)] = 0
		} else {
			buf[len(buf)-1] = 0
		}
	}
}

// goStringFromC reads a NUL-terminated C char array into a Go string.
func goStringFromC(buf []C.char) string {
	n := 0
	for n < len(buf) && buf[n] != 0 {
		n++
	}
	// Convert byte-by-byte (safe for ASCII)
	result := make([]byte, n)
	for i := 0; i < n; i++ {
		result[i] = byte(buf[i])
	}
	return string(result)
}

// infoStringLen matches PKINFOSTRINGLEN.
const infoStringLen = C.PKINFOSTRINGLEN