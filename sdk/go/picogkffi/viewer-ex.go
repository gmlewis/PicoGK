package picogkffi

/*
#include <stdlib.h>
#include <string.h>
#include "picogk_ffi.h"

// Forward declarations of the exported Go callbacks.
extern void goInfoCb(const char* msg, bool fatal);
extern void goUpdateCb(void* viewer, const PKVector2* vp, PKColorFloat* bg, PKMatrix4x4* mvp, PKVector3* eye);
extern void goKeyCb(void* viewer, int32_t key, int32_t scancode, int32_t action, int32_t mods);
extern void goMouseMoveCb(void* viewer, const PKVector2* pos, bool shift, bool ctrl, bool alt, bool sup);
extern void goMouseButtonCb(void* viewer, int32_t button, int32_t action, int32_t mods, const PKVector2* pos);
extern void goScrollCb(void* viewer, const PKVector2* offset, const PKVector2* pos, bool shift, bool ctrl, bool alt, bool sup);
extern void goWindowSizeCb(void* viewer, const PKVector2* size);

// Helper to create a viewer with all callbacks wired.
static PKVIEWER createViewer(const char* title, const PKVector2* size) {
    return Viewer_hCreate(title, size,
        goInfoCb, goUpdateCb, goKeyCb,
        goMouseMoveCb, goMouseButtonCb, goScrollCb, goWindowSizeCb);
}
*/
import "C"

import (
	"archive/zip"
	"fmt"
	"image"
	"image/color"
	"image/png"
	"io"
	"math"
	"os"
	"unsafe"
)

// CameraState holds the orbit camera state.
type CameraState struct {
	Target    [3]float32
	Radius    float32
	Azimuth   float32 // radians
	Elevation float32 // radians
	Zoom      float32
	Autofit   bool

	// Mouse state
	DragButton int // -1 = no drag
	MouseX     float32
	MouseY     float32

	// Background
	BgR, BgG, BgB, BgA float32

	// Screenshot
	PendingScreenshot string
}

// DefaultCameraState returns the default camera state matching PicoPie.
func DefaultCameraState() CameraState {
	return CameraState{
		Target:     [3]float32{0, 0, 0},
		Radius:     10.0,
		Azimuth:    float32(45.0 * math.Pi / 180.0),
		Elevation:  float32(25.0 * math.Pi / 180.0),
		Zoom:       1.0,
		Autofit:    true,
		DragButton: -1,
		BgR:        0.16, BgG: 0.16, BgB: 0.20, BgA: 1.0,
	}
}

// ViewerEx is the interactive OpenGL viewer with full callback support.
type ViewerEx struct {
	h      C.PKVIEWER
	cam    CameraState
	active bool // tracks if this viewer is the current callback target
}

// activeViewer is the viewer that receives callbacks (single active viewer).
var activeViewer *ViewerEx

// NewViewerEx creates a viewer with full callback support.
// Must be called on the main OS thread (use runtime.LockOSThread).
func NewViewerEx(title string, width, height int, cam CameraState) *ViewerEx {
	mustInit()
	cTitle := C.CString(title)
	defer C.free(unsafe.Pointer(cTitle))
	cSize := C.PKVector2{X: C.float(float32(width)), Y: C.float(float32(height))}

	v := &ViewerEx{cam: cam, active: true}
	activeViewer = v

	h := C.createViewer(cTitle, &cSize)
	if h == nil {
		panic("picogkffi: Viewer_hCreate returned null (no display?)")
	}
	v.h = h

	// Load IBL lighting if available
	loadLightSetup(v.h)

	return v
}

// Destroy closes the viewer.
func (v *ViewerEx) Destroy() {
	if v.h != nil {
		C.Viewer_Destroy(v.h)
		v.h = nil
	}
	if activeViewer == v {
		activeViewer = nil
	}
}

// IsValid returns true if the viewer is still open.
func (v *ViewerEx) IsValid() bool {
	return v.h != nil && bool(C.Viewer_bIsValid(v.h))
}

// Poll processes events and renders one frame.
func (v *ViewerEx) Poll() bool {
	activeViewer = v
	return bool(C.Viewer_bPoll(v.h))
}

// RequestClose asks the viewer to close.
func (v *ViewerEx) RequestClose() {
	C.Viewer_RequestClose(v.h)
}

// RequestUpdate asks for a redraw.
func (v *ViewerEx) RequestUpdate() {
	C.Viewer_RequestUpdate(v.h)
}

// RequestScreenShot asks the viewer to save a screenshot.
func (v *ViewerEx) RequestScreenShot(path string) {
	cPath := C.CString(path)
	defer C.free(unsafe.Pointer(cPath))
	C.Viewer_RequestScreenShot(v.h, cPath)
}

// AddVoxels adds a voxel object to the viewer at the given group.
func (v *ViewerEx) AddVoxels(group int, vox *Voxels) {
	C.Viewer_AddVoxels(instance, v.h, C.int32_t(group), vox.h)
}

// AddMesh adds a mesh object to the viewer at the given group.
func (v *ViewerEx) AddMesh(group int, mesh *Mesh) {
	C.Viewer_AddMesh(instance, v.h, C.int32_t(group), mesh.h)
}

// RemoveAllObjects removes all objects from the viewer.
func (v *ViewerEx) RemoveAllObjects() {
	C.Viewer_RemoveAllObjects(v.h)
}

// SetGroupMaterial sets the PBR material for a group.
func (v *ViewerEx) SetGroupMaterial(group int, color ColorFloat, metallic, roughness float32) {
	c := C.PKColorFloat{R: C.float(color.R), G: C.float(color.G), B: C.float(color.B), A: C.float(color.A)}
	C.Viewer_SetGroupMaterial(v.h, C.int32_t(group), &c, C.float(metallic), C.float(roughness))
}

// SetGroupVisible sets the visibility of a group.
func (v *ViewerEx) SetGroupVisible(group int, visible bool) {
	C.Viewer_SetGroupVisible(v.h, C.int32_t(group), C.bool(visible))
}

// RemoveMesh removes a mesh from the viewer.
func (v *ViewerEx) RemoveMesh(mesh *Mesh) {
	C.Viewer_RemoveMesh(instance, v.h, mesh.h)
}

// SetMeshMatrix sets the transform matrix for a mesh in the viewer.
func (v *ViewerEx) SetMeshMatrix(mesh *Mesh, matrix [16]float32) {
	m := C.PKMatrix4x4{
		vec1: C.PKVector4{X: C.float(matrix[0]), Y: C.float(matrix[1]), Z: C.float(matrix[2]), W: C.float(matrix[3])},
		vec2: C.PKVector4{X: C.float(matrix[4]), Y: C.float(matrix[5]), Z: C.float(matrix[6]), W: C.float(matrix[7])},
		vec3: C.PKVector4{X: C.float(matrix[8]), Y: C.float(matrix[9]), Z: C.float(matrix[10]), W: C.float(matrix[11])},
		vec4: C.PKVector4{X: C.float(matrix[12]), Y: C.float(matrix[13]), Z: C.float(matrix[14]), W: C.float(matrix[15])},
	}
	C.Viewer_SetMeshMatrix(instance, v.h, mesh.h, &m)
}

// RemoveVoxels removes a voxel object from the viewer.
func (v *ViewerEx) RemoveVoxels(vox *Voxels) {
	C.Viewer_RemoveVoxels(instance, v.h, vox.h)
}

// SetVoxelsMatrix sets the transform matrix for a voxel object in the viewer.
func (v *ViewerEx) SetVoxelsMatrix(vox *Voxels, matrix [16]float32) {
	m := C.PKMatrix4x4{
		vec1: C.PKVector4{X: C.float(matrix[0]), Y: C.float(matrix[1]), Z: C.float(matrix[2]), W: C.float(matrix[3])},
		vec2: C.PKVector4{X: C.float(matrix[4]), Y: C.float(matrix[5]), Z: C.float(matrix[6]), W: C.float(matrix[7])},
		vec3: C.PKVector4{X: C.float(matrix[8]), Y: C.float(matrix[9]), Z: C.float(matrix[10]), W: C.float(matrix[11])},
		vec4: C.PKVector4{X: C.float(matrix[12]), Y: C.float(matrix[13]), Z: C.float(matrix[14]), W: C.float(matrix[15])},
	}
	C.Viewer_SetVoxelsMatrix(instance, v.h, vox.h, &m)
}

// AddPolyLine adds a polyline to the viewer at the given group.
func (v *ViewerEx) AddPolyLine(group int, pl *PolyLine) {
	C.Viewer_AddPolyLine(instance, v.h, C.int32_t(group), pl.h)
}

// RemovePolyLine removes a polyline from the viewer.
func (v *ViewerEx) RemovePolyLine(pl *PolyLine) {
	C.Viewer_RemovePolyLine(instance, v.h, pl.h)
}

// SetPolyLineMatrix sets the transform matrix for a polyline in the viewer.
func (v *ViewerEx) SetPolyLineMatrix(pl *PolyLine, matrix [16]float32) {
	m := C.PKMatrix4x4{
		vec1: C.PKVector4{X: C.float(matrix[0]), Y: C.float(matrix[1]), Z: C.float(matrix[2]), W: C.float(matrix[3])},
		vec2: C.PKVector4{X: C.float(matrix[4]), Y: C.float(matrix[5]), Z: C.float(matrix[6]), W: C.float(matrix[7])},
		vec3: C.PKVector4{X: C.float(matrix[8]), Y: C.float(matrix[9]), Z: C.float(matrix[10]), W: C.float(matrix[11])},
		vec4: C.PKVector4{X: C.float(matrix[12]), Y: C.float(matrix[13]), Z: C.float(matrix[14]), W: C.float(matrix[15])},
	}
	C.Viewer_SetPolyLineMatrix(instance, v.h, pl.h, &m)
}

// SetGroupMatrix sets the transform matrix for a group.
func (v *ViewerEx) SetGroupMatrix(group int, matrix [16]float32) {
	m := C.PKMatrix4x4{
		vec1: C.PKVector4{X: C.float(matrix[0]), Y: C.float(matrix[1]), Z: C.float(matrix[2]), W: C.float(matrix[3])},
		vec2: C.PKVector4{X: C.float(matrix[4]), Y: C.float(matrix[5]), Z: C.float(matrix[6]), W: C.float(matrix[7])},
		vec3: C.PKVector4{X: C.float(matrix[8]), Y: C.float(matrix[9]), Z: C.float(matrix[10]), W: C.float(matrix[11])},
		vec4: C.PKVector4{X: C.float(matrix[12]), Y: C.float(matrix[13]), Z: C.float(matrix[14]), W: C.float(matrix[15])},
	}
	C.Viewer_SetGroupMatrix(v.h, C.int32_t(group), &m)
}

// EnableGroupWarnOverhang enables overhang warnings for a group.
func (v *ViewerEx) EnableGroupWarnOverhang(group int, maxAngle, minLength float32) {
	C.Viewer_EnableGroupWarnOverhang(v.h, C.int32_t(group), C.float(maxAngle), C.float(minLength))
}

// DisableGroupWarnOverhang disables overhang warnings for a group.
func (v *ViewerEx) DisableGroupWarnOverhang(group int) {
	C.Viewer_DisableGroupWarnOverhang(v.h, C.int32_t(group))
}

// BoundingBox returns the viewer scene bounding box.
func (v *ViewerEx) BoundingBox() BBox3 {
	var out C.PKBBox3
	C.Viewer_GetBoundingBox(v.h, &out)
	return bboxFromC(out)
}

// EnableExperimental enables experimental viewer features.
func (v *ViewerEx) EnableExperimental(enable bool) {
	C.Viewer_EnableExperimental(v.h, C.bool(enable))
}

// SetBackground sets the background color.
func (v *ViewerEx) SetBackground(r, g, b, a float32) {
	v.cam.BgR = r
	v.cam.BgG = g
	v.cam.BgB = b
	v.cam.BgA = a
}

// Screenshot takes a screenshot by polling frames.
// The native viewer writes TGA; we convert to PNG if needed.
func (v *ViewerEx) Screenshot(path string, frames int) {
	activeViewer = v
	// Pump frames to ensure scene is rendered
	for i := 0; i < frames; i++ {
		v.RequestUpdate()
		if !v.Poll() {
			break
		}
	}

	// Determine if we need TGA→PNG conversion
	ext := ""
	for i := len(path) - 1; i >= 0; i-- {
		if path[i] == '.' {
			ext = path[i+1:]
			break
		}
	}

	if ext == "tga" {
		// Native TGA output
		v.RequestScreenShot(path)
		for i := 0; i < frames; i++ {
			v.RequestUpdate()
			if !v.Poll() {
				break
			}
		}
	} else {
		// Write TGA to temp, then convert to PNG
		tgaPath := path + ".tga"
		v.RequestScreenShot(tgaPath)
		for i := 0; i < frames; i++ {
			v.RequestUpdate()
			if !v.Poll() {
				break
			}
		}
		// Convert TGA to target format using Go's image package
		convertTGA(tgaPath, path)
		os.Remove(tgaPath)
	}
}

// convertTGA converts a TGA file to PNG format.
func convertTGA(tgaPath, pngPath string) {
	// Read TGA file
	data, err := os.ReadFile(tgaPath)
	if err != nil {
		return
	}

	// Parse TGA header (18 bytes)
	if len(data) < 18 {
		return
	}
	idLen := int(data[0])
	colorMapType := data[1]
	imageType := data[2]
	width := int(data[12]) | int(data[13])<<8
	height := int(data[14]) | int(data[15])<<8
	bpp := int(data[16])
	descriptor := data[17]

	// Skip image ID
	offset := 18 + idLen
	// Skip color map if present
	if colorMapType == 1 {
		mapLen := int(data[5]) | int(data[6])<<8
		mapEntrySize := int(data[7])
		offset += mapLen * (mapEntrySize / 8)
	}

	// Only handle uncompressed true-color (type 2)
	if imageType != 2 {
		return
	}

	pixelData := data[offset:]
	stride := width * (bpp / 8)

	// Create RGBA image
	img := image.NewRGBA(image.Rect(0, 0, width, height))
	topOrigin := (descriptor & 0x20) != 0

	for y := 0; y < height; y++ {
		rowOffset := y * stride
		if rowOffset+stride > len(pixelData) {
			break
		}
		dstY := y
		if !topOrigin {
			dstY = height - 1 - y
		}
		for x := 0; x < width; x++ {
			srcIdx := rowOffset + x*(bpp/8)
			if bpp == 32 {
				img.SetRGBA(x, dstY, color.RGBA{
					R: pixelData[srcIdx+2],
					G: pixelData[srcIdx+1],
					B: pixelData[srcIdx+0],
					A: pixelData[srcIdx+3],
				})
			} else if bpp == 24 {
				img.SetRGBA(x, dstY, color.RGBA{
					R: pixelData[srcIdx+2],
					G: pixelData[srcIdx+1],
					B: pixelData[srcIdx+0],
					A: 255,
				})
			}
		}
	}

	// Write PNG with best compression
	f, err := os.Create(pngPath)
	if err != nil {
		return
	}
	defer f.Close()
	enc := png.Encoder{CompressionLevel: png.BestCompression}
	enc.Encode(f, img)
}

// Run blocks and runs the viewer event loop until closed.
func (v *ViewerEx) Run() {
	for v.Poll() {
	}
	v.Destroy()
}

// loadLightSetup loads the IBL lighting from PicoPie's bundled assets.
func loadLightSetup(viewer C.PKVIEWER) {
	assetPath := "/Users/glenn/src/github.com/Borderliner/PicoPie/src/picogk/_assets/viewer_environment.zip"
	if _, err := os.Stat(assetPath); err != nil {
		return
	}

	diffuse, specular, err := loadDDSFromZip(assetPath)
	if err != nil {
		return
	}

	C.Viewer_bLoadLightSetup(viewer,
		(*C.char)(unsafe.Pointer(&diffuse[0])), C.int32_t(len(diffuse)),
		(*C.char)(unsafe.Pointer(&specular[0])), C.int32_t(len(specular)))
}

func loadDDSFromZip(zipPath string) (diffuse, specular []byte, err error) {
	r, err := zip.OpenReader(zipPath)
	if err != nil {
		return nil, nil, err
	}
	defer r.Close()

	for _, f := range r.File {
		if f.Name == "Diffuse.dds" {
			rc, err := f.Open()
			if err != nil {
				return nil, nil, err
			}
			defer rc.Close()
			diffuse, err = io.ReadAll(rc)
			if err != nil {
				return nil, nil, err
			}
		}
		if f.Name == "Specular.dds" {
			rc, err := f.Open()
			if err != nil {
				return nil, nil, err
			}
			defer rc.Close()
			specular, err = io.ReadAll(rc)
			if err != nil {
				return nil, nil, err
			}
		}
	}

	if len(diffuse) == 0 || len(specular) == 0 {
		return nil, nil, fmt.Errorf("DDS files not found in zip")
	}
	return diffuse, specular, nil
}

// --- Camera math (ported from PicoPie viewer.py) ---

const (
	fovY       = 35.0 * math.Pi / 180.0
	orbitSpeed = 0.008
	panScale   = 0.0015
	zoomMin    = 0.05
	zoomMax    = 20.0
	elevClamp  = math.Pi/2 - 1e-3
)

var up = [3]float32{0, 0, 1}

func cameraBasis(cam *CameraState) (d, right, upCam [3]float32) {
	ce := float32(math.Cos(float64(cam.Elevation)))
	se := float32(math.Sin(float64(cam.Elevation)))
	ca := float32(math.Cos(float64(cam.Azimuth)))
	sa := float32(math.Sin(float64(cam.Azimuth)))
	d = [3]float32{ce * ca, ce * sa, se}
	right = cross3(up, d)
	rl := norm3(right)
	if rl > 0 {
		right[0] /= rl
		right[1] /= rl
		right[2] /= rl
	}
	upCam = cross3(d, right)
	return
}

func cameraDistance(cam *CameraState) float32 {
	return cam.Radius / float32(math.Sin(fovY/2)) * 1.1 * cam.Zoom
}

func viewProjection(cam *CameraState, aspect float32) (mvp [16]float32, eye [3]float32) {
	dist := cameraDistance(cam)
	d, _, _ := cameraBasis(cam)
	eye = [3]float32{
		cam.Target[0] + d[0]*dist,
		cam.Target[1] + d[1]*dist,
		cam.Target[2] + d[2]*dist,
	}
	near := dist * 0.01
	if near < 0.01 {
		near = 0.01
	}
	far := dist*10.0 + 1000.0
	if far < near+1e-3 {
		far = near + 1e-3
	}
	v := lookAt(eye[:], cam.Target[:], up[:])
	p := perspective(float32(fovY), aspect, near, far)
	mvp = mat4Mul(v, p)
	return
}

func lookAt(eye, target, upV []float32) [16]float32 {
	z := sub3(eye, target)
	z = norm3v(z)
	up3 := [3]float32{upV[0], upV[1], upV[2]}
	x := cross3(up3, z)
	x = norm3v(x)
	y := cross3(z, x)
	// Row-major, System.Numerics convention (point transforms as p·M)
	return [16]float32{
		x[0], y[0], z[0], 0,
		x[1], y[1], z[1], 0,
		x[2], y[2], z[2], 0,
		-dot3(x, eye), -dot3(y, eye), -dot3(z, eye), 1,
	}
}

func perspective(fovy, aspect, near, far float32) [16]float32 {
	ys := 1.0 / float32(math.Tan(float64(fovy)*0.5))
	xs := ys / aspect
	if aspect < 1e-6 {
		xs = ys / 1e-6
	}
	return [16]float32{
		xs, 0, 0, 0,
		0, ys, 0, 0,
		0, 0, far / (near - far), -1,
		0, 0, near * far / (near - far), 1,
	}
}

func mat4Mul(a, b [16]float32) [16]float32 {
	var r [16]float32
	for i := 0; i < 4; i++ {
		for j := 0; j < 4; j++ {
			s := float32(0)
			for k := 0; k < 4; k++ {
				s += a[i*4+k] * b[k*4+j]
			}
			r[i*4+j] = s
		}
	}
	return r
}

func cross3(a, b [3]float32) [3]float32 {
	return [3]float32{
		a[1]*b[2] - a[2]*b[1],
		a[2]*b[0] - a[0]*b[2],
		a[0]*b[1] - a[1]*b[0],
	}
}

func cross3s(a, b []float32) [3]float32 {
	return [3]float32{
		a[1]*b[2] - a[2]*b[1],
		a[2]*b[0] - a[0]*b[2],
		a[0]*b[1] - a[1]*b[0],
	}
}

func norm3(v [3]float32) float32 {
	return float32(math.Sqrt(float64(v[0]*v[0] + v[1]*v[1] + v[2]*v[2])))
}

func norm3v(v [3]float32) [3]float32 {
	l := norm3(v)
	if l < 1e-12 {
		return [3]float32{0, 0, 0}
	}
	return [3]float32{v[0] / l, v[1] / l, v[2] / l}
}

func sub3(a, b []float32) [3]float32 {
	return [3]float32{a[0] - b[0], a[1] - b[1], a[2] - b[2]}
}

func dot3(a [3]float32, b []float32) float32 {
	return a[0]*b[0] + a[1]*b[1] + a[2]*b[2]
}
