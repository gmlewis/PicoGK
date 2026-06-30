package picogkffi

/*
#include <stdlib.h>
#include "picogk_ffi.h"
*/
import "C"

import (
	"errors"
	"fmt"
	"unsafe"
)

// Instance is the PicoGK library instance (one per process, fixed voxel size).
var instance C.PKINSTANCE

// Init initializes the PicoGK library with the given voxel size (mm).
// Must be called before any other function. Returns an error if already
// initialized with a different voxel size.
func Init(voxelSizeMM float32) error {
	if instance != 0 {
		return errors.New("picogkffi: already initialized (call Shutdown first to reinit)")
	}
	inst := C.Library_hCreateInstance(C.float(voxelSizeMM))
	if inst == 0 {
		return errors.New("picogkffi: Library_hCreateInstance returned null handle")
	}
	instance = inst
	return nil
}

// Shutdown destroys the library instance and releases all resources.
// All object handles become invalid after this call.
func Shutdown() {
	if instance != 0 {
		C.Library_DestroyInstance(instance)
		instance = 0
	}
}

// IsInitialized returns true if the library has been initialized.
func IsInitialized() bool {
	return instance != 0
}

// VoxelSize returns the voxel size in mm. Requires initialization.
func VoxelSize() float32 {
	mustInit()
	// Create a dummy voxels to query voxel size — actually we can use the
	// library instance directly. The C API doesn't have a library-level
	// voxel size getter, so we return the value passed to Init.
	// (In practice, store it.)
	return initVoxelSize
}

// initVoxelSize stores the voxel size passed to Init.
var initVoxelSize float32

// TotalMemoryUsage returns the total memory in bytes used by the library.
func TotalMemoryUsage() int64 {
	mustInit()
	return int64(C.Library_nTotalMemUsage(instance))
}

// Version returns the PicoGK runtime version string.
func Version() string {
	buf := make([]C.char, C.PKINFOSTRINGLEN)
	C.Library_GetVersion(&buf[0])
	return goStringFromC(buf)
}

// Name returns the PicoGK runtime name string.
func Name() string {
	buf := make([]C.char, C.PKINFOSTRINGLEN)
	C.Library_GetName(&buf[0])
	return goStringFromC(buf)
}

// BuildInfo returns the PicoGK build info string.
func BuildInfo() string {
	buf := make([]C.char, C.PKINFOSTRINGLEN)
	C.Library_GetBuildInfo(&buf[0])
	return goStringFromC(buf)
}

// mustInit panics if the library is not initialized.
func mustInit() {
	if instance == 0 {
		panic("picogkffi: library not initialized — call Init() first")
	}
}

// InitWithSize initializes and stores the voxel size for later queries.
func InitWithSize(voxelSizeMM float32) error {
	if err := Init(voxelSizeMM); err != nil {
		return err
	}
	initVoxelSize = voxelSizeMM
	return nil
}

// VDB field type constants.
const (
	FieldTypeVoxels  = 0
	FieldTypeScalar  = 1
	FieldTypeVector  = 2
	FieldTypeUnknown = -1
)

// Metadata type constants.
const (
	MetaTypeString  = 0
	MetaTypeFloat   = 1
	MetaTypeVector  = 2
	MetaTypeUnknown = -1
)

// cstr converts a Go string to a C string (NUL-terminated).
// The returned pointer is valid only during the call — caller must free.
func cstr(s string) *C.char {
	return C.CString(s)
}

// freeCstr frees a C string allocated by cstr.
func freeCstr(s *C.char) {
	C.free(unsafe.Pointer(s))
}

// fmt error helper
func errf(format string, args ...any) error {
	return fmt.Errorf(format, args...)
}
