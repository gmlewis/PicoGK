package picogkffi

/*
#include <stdlib.h>
#include <string.h>
#include "picogk_ffi.h"
*/
import "C"

import (
	"math"
	"unsafe"
)

//export goInfoCb
func goInfoCb(msg *C.char, fatal C.bool) {
	// No-op: info messages from the native viewer are ignored.
}

//export goUpdateCb
func goUpdateCb(viewer unsafe.Pointer, vp *C.PKVector2, bg *C.PKColorFloat, mvp *C.PKMatrix4x4, eye *C.PKVector3) {
	if activeViewer == nil {
		return
	}
	cam := &activeViewer.cam

	// Autofit: compute target and radius from the scene bounding box.
	if cam.Autofit {
		var box C.PKBBox3
		C.Viewer_GetBoundingBox(activeViewer.h, &box)
		lo := [3]float32{float32(box.vecMin.X), float32(box.vecMin.Y), float32(box.vecMin.Z)}
		hi := [3]float32{float32(box.vecMax.X), float32(box.vecMax.Y), float32(box.vecMax.Z)}
		if hi[0] >= lo[0] && hi[1] >= lo[1] && hi[2] >= lo[2] {
			cam.Target[0] = (lo[0] + hi[0]) * 0.5
			cam.Target[1] = (lo[1] + hi[1]) * 0.5
			cam.Target[2] = (lo[2] + hi[2]) * 0.5
			dx, dy, dz := hi[0]-lo[0], hi[1]-lo[1], hi[2]-lo[2]
			diag := float32(math.Sqrt(float64(dx*dx + dy*dy + dz*dz)))
			if diag < 1e-3 {
				diag = 1e-3
			}
			cam.Radius = diag * 0.5
		}
	}

	aspect := float32(1.0)
	if vp != nil {
		aspect = float32(vp.X) / maxf(float32(vp.Y), 1.0)
	}

	m, e := viewProjection(cam, aspect)

	// Write back into native structs
	if mvp != nil {
		mvp.vec1 = C.PKVector4{X: C.float(m[0]), Y: C.float(m[1]), Z: C.float(m[2]), W: C.float(m[3])}
		mvp.vec2 = C.PKVector4{X: C.float(m[4]), Y: C.float(m[5]), Z: C.float(m[6]), W: C.float(m[7])}
		mvp.vec3 = C.PKVector4{X: C.float(m[8]), Y: C.float(m[9]), Z: C.float(m[10]), W: C.float(m[11])}
		mvp.vec4 = C.PKVector4{X: C.float(m[12]), Y: C.float(m[13]), Z: C.float(m[14]), W: C.float(m[15])}
	}
	if eye != nil {
		eye.X = C.float(e[0])
		eye.Y = C.float(e[1])
		eye.Z = C.float(e[2])
	}
	if bg != nil {
		bg.R = C.float(cam.BgR)
		bg.G = C.float(cam.BgG)
		bg.B = C.float(cam.BgB)
		bg.A = C.float(cam.BgA)
	}
}

//export goKeyCb
func goKeyCb(viewer unsafe.Pointer, key C.int32_t, scancode C.int32_t, action C.int32_t, mods C.int32_t) {
	if activeViewer == nil || action != 1 {
		return
	}
	switch int(key) {
	case 256, 81: // Esc, Q
		C.Viewer_RequestClose(activeViewer.h)
	case 70: // F
		activeViewer.cam.Autofit = true
		activeViewer.cam.Zoom = 1.0
		activeViewer.cam.Azimuth = float32(45.0 * 3.14159265358979 / 180.0)
		activeViewer.cam.Elevation = float32(25.0 * 3.14159265358979 / 180.0)
		C.Viewer_RequestUpdate(activeViewer.h)
	case 83: // S
		activeViewer.cam.PendingScreenshot = "picopie_screenshot.png"
		C.Viewer_RequestScreenShot(activeViewer.h, C.CString("picopie_screenshot.png"))
	}
}

//export goMouseMoveCb
func goMouseMoveCb(viewer unsafe.Pointer, pos *C.PKVector2, shift, ctrl, alt, sup C.bool) {
	if activeViewer == nil || pos == nil {
		return
	}
	cam := &activeViewer.cam
	px, py := float32(pos.X), float32(pos.Y)
	dx, dy := px-cam.MouseX, py-cam.MouseY
	cam.MouseX = px
	cam.MouseY = py

	if cam.DragButton >= 0 {
		btn := cam.DragButton
		isPan := btn == 1 || btn == 2 || (btn == 0 && bool(shift))
		if isPan {
			// Pan
			_, right, upCam := cameraBasis(cam)
			dist := cameraDistance(cam)
			scale := dist * panScale
			cam.Target[0] += (-dx*right[0] + dy*upCam[0]) * scale
			cam.Target[1] += (-dx*right[1] + dy*upCam[1]) * scale
			cam.Target[2] += (-dx*right[2] + dy*upCam[2]) * scale
		} else {
			// Orbit
			cam.Azimuth -= dx * orbitSpeed
			cam.Elevation += dy * orbitSpeed
			if cam.Elevation > elevClamp {
				cam.Elevation = elevClamp
			}
			if cam.Elevation < -elevClamp {
				cam.Elevation = -elevClamp
			}
			cam.Autofit = false
		}
		C.Viewer_RequestUpdate(activeViewer.h)
	}
}

//export goMouseButtonCb
func goMouseButtonCb(viewer unsafe.Pointer, button, action, mods C.int32_t, pos *C.PKVector2) {
	if activeViewer == nil || pos == nil {
		return
	}
	cam := &activeViewer.cam
	if action == 1 { // press
		cam.DragButton = int(button)
		cam.MouseX = float32(pos.X)
		cam.MouseY = float32(pos.Y)
	} else { // release
		cam.DragButton = -1
	}
}

//export goScrollCb
func goScrollCb(viewer unsafe.Pointer, offset, pos *C.PKVector2, shift, ctrl, alt, sup C.bool) {
	if activeViewer == nil || offset == nil {
		return
	}
	cam := &activeViewer.cam
	amount := float32(offset.Y)
	cam.Zoom *= (1.0 - 0.1*amount)
	if cam.Zoom < zoomMin {
		cam.Zoom = zoomMin
	}
	if cam.Zoom > zoomMax {
		cam.Zoom = zoomMax
	}
	C.Viewer_RequestUpdate(activeViewer.h)
}

//export goWindowSizeCb
func goWindowSizeCb(viewer unsafe.Pointer, size *C.PKVector2) {
	if activeViewer == nil {
		return
	}
	C.Viewer_RequestUpdate(activeViewer.h)
}

// Helper functions
func maxf(a, b float32) float32 {
	if a > b {
		return a
	}
	return b
}
