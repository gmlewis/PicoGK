package picogkffi

/*
#include <stdlib.h>
#include <string.h>
#include "picogk_ffi.h"
*/
import "C"

import "unsafe"

// Viewer is the interactive OpenGL viewer (requires a display).
// Must be created and used on the OS main thread.
type Viewer struct {
	h C.PKVIEWER
}

// Note: The Viewer requires 7 C callbacks. Implementing these via cgo
// //export is complex. For now, we provide a simplified Viewer that
// uses default callbacks (no input handling, auto-orbit camera).
// A full implementation would export all 7 callbacks and wire them
// to Go-side handlers.

// NewViewer creates a viewer with the given title and window size.
// Requires a display + OpenGL. Will crash if headless.
func NewViewer(title string, width, height int) *Viewer {
	mustInit()
	cTitle := C.CString(title)
	defer C.free(unsafe.Pointer(cTitle))
	cSize := C.PKVector2{X: C.float(float32(width)), Y: C.float(float32(height))}
	// Pass nil for all callbacks — the native viewer handles defaults.
	// A full implementation would pass Go callbacks via //export.
	h := C.Viewer_hCreate(cTitle, &cSize, nil, nil, nil, nil, nil, nil, nil)
	if h == nil {
		panic("picogkffi: Viewer_hCreate returned null (no display?)")
	}
	return &Viewer{h: h}
}

// Destroy closes the viewer.
func (v *Viewer) Destroy() {
	if v.h != nil {
		C.Viewer_Destroy(v.h)
		v.h = nil
	}
}

// IsValid returns true if the viewer is still open.
func (v *Viewer) IsValid() bool {
	return v.h != nil && bool(C.Viewer_bIsValid(v.h))
}

// Poll processes events and renders one frame. Returns false if the
// viewer was closed.
func (v *Viewer) Poll() bool {
	return bool(C.Viewer_bPoll(v.h))
}

// RequestClose asks the viewer to close.
func (v *Viewer) RequestClose() {
	C.Viewer_RequestClose(v.h)
}

// RequestScreenShot asks the viewer to save a screenshot.
func (v *Viewer) RequestScreenShot(path string) {
	cPath := C.CString(path)
	defer C.free(unsafe.Pointer(cPath))
	C.Viewer_RequestScreenShot(v.h, cPath)
}

// AddVoxels adds a voxel object to the viewer at the given group.
func (v *Viewer) AddVoxels(group int, vox *Voxels) {
	C.Viewer_AddVoxels(instance, v.h, C.int32_t(group), vox.h)
}

// AddMesh adds a mesh object to the viewer at the given group.
func (v *Viewer) AddMesh(group int, mesh *Mesh) {
	C.Viewer_AddMesh(instance, v.h, C.int32_t(group), mesh.h)
}

// RemoveAllObjects removes all objects from the viewer.
func (v *Viewer) RemoveAllObjects() {
	C.Viewer_RemoveAllObjects(v.h)
}

// SetGroupMaterial sets the PBR material for a group.
func (v *Viewer) SetGroupMaterial(group int, color ColorFloat, metallic, roughness float32) {
	c := C.PKColorFloat{R: C.float(color.R), G: C.float(color.G), B: C.float(color.B), A: C.float(color.A)}
	C.Viewer_SetGroupMaterial(v.h, C.int32_t(group), &c, C.float(metallic), C.float(roughness))
}

// SetGroupVisible sets the visibility of a group.
func (v *Viewer) SetGroupVisible(group int, visible bool) {
	C.Viewer_SetGroupVisible(v.h, C.int32_t(group), C.bool(visible))
}

// Run blocks and runs the viewer event loop until closed.
func (v *Viewer) Run() {
	for v.Poll() {
	}
	v.Destroy()
}

// Screenshot takes a screenshot. The viewer needs to poll a few frames
// for the screenshot to complete.
func (v *Viewer) Screenshot(path string, frames int) {
	v.RequestScreenShot(path)
	for i := 0; i < frames; i++ {
		v.Poll()
	}
}
