// picogkffi: Direct Go FFI binding to the PicoGK native C library.
//
// This package provides a thin cgo wrapper around the PicoGKRuntime shared
// library, giving Go programs the same direct, in-process access to the
// geometry kernel that PicoPie (Python) has via ctypes.
package picogkffi

/*
#cgo CFLAGS: -I${SRCDIR}
#cgo darwin LDFLAGS: ${SRCDIR}/../../../native/osx-arm64/picogk.26.2.dylib -Wl,-rpath,${SRCDIR}/../../../native/osx-arm64
#cgo linux LDFLAGS: -L${SRCDIR}/../../../native/linux-x64 -lpicogk.26.2 -Wl,-rpath,${SRCDIR}/../../../native/linux-x64

#include <stdlib.h>
#include "picogk_ffi.h"
*/
import "C"