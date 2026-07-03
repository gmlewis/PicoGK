// Visualization demo via the native FFI SDK: Z-slice cross-section PNG and
// 3D Viewer render.
//
// This is the FFI counterpart to the visualize example (a Go port of the
// PicoPie Python example visualize.py). It uses the picogkffi package, which
// binds directly to the native PicoGK C++ runtime. The Z-slice is rendered
// from the raw SDF slice array (Voxels.GetZSlice) into a PNG using Go's
// image package — no MCP render_slice tool needed. The 3D render uses the
// native OpenGL Viewer via ViewerEx.Screenshot.
//
// Requires a display for the 3D Viewer render. The Z-slice PNG is headless.
//
// Run:  go run main.go
package main

import (
	"flag"
	"fmt"
	"image"
	_ "image/color"
	"image/png"
	"math"
	"os"
	"path/filepath"
	"runtime"

	"github.com/gmlewis/PicoGK/sdk/go/picogkffi"
)

var verbose = flag.Bool("v", false, "Verbose output")

func main() {
	flag.Parse()

	// The OpenGL Viewer requires the OS main thread on macOS.
	runtime.LockOSThread()
	defer runtime.UnlockOSThread()

	outdir := "/tmp/go-picogkffi-visualize"
	os.MkdirAll(outdir, 0755)

	fmt.Println("=== Visualize (Go FFI) ===")
	fmt.Printf("Output dir: %s\n\n", outdir)

	if err := picogkffi.InitWithSize(0.3); err != nil {
		fmt.Fprintln(os.Stderr, "Init:", err)
		os.Exit(1)
	}
	defer picogkffi.Shutdown()

	fmt.Println("PicoGK", picogkffi.Version())

	// A hollow shelled part with a through-hole.
	body := picogkffi.NewSphere(picogkffi.Vec3{0, 0, 0}, 12)
	defer body.Destroy()
	hole := picogkffi.NewSphere(picogkffi.Vec3{7, 0, 0}, 7)
	defer hole.Destroy()
	part := body.Sub(hole)
	defer part.Destroy()
	part.Shell(1.5)
	fmt.Printf("  shelled part volume: %.1f mm³\n", part.Volume())

	// Query voxel grid dimensions.
	fmt.Println("\n--- Voxel dimensions ---")
	ox, oy, oz, sx, sy, sz := part.VoxelDimensions()
	fmt.Printf("  origin=(%d,%d,%d) size=(%d,%d,%d)\n", ox, oy, oz, sx, sy, sz)
	bbox := part.BoundingBox()
	fmt.Printf("  bbox min=(%.1f,%.1f,%.1f) max=(%.1f,%.1f,%.1f)\n",
		bbox.Min.X, bbox.Min.Y, bbox.Min.Z, bbox.Max.X, bbox.Max.Y, bbox.Max.Z)

	// 1) A single mid-Z slice as a cross-section PNG (headless).
	//    GetInterpolatedZSlice takes a Z position in mm (not a voxel index),
	//    so z=0.0 is the geometric center of the part.
	fmt.Println("\n--- Z-slice render ---")
	slicePath := filepath.Join(outdir, "slice_z0.png")
	sliceData := part.GetInterpolatedZSlice(0.0)
	if err := writeSlicePNG(slicePath, sliceData, sx, sy, *verbose); err != nil {
		fmt.Fprintf(os.Stderr, "  slice PNG: %v\n", err)
	} else {
		fmt.Printf("  -> %s  (Z-slice cross-section)\n", slicePath)
	}

	// 2) A 3D render of the meshed surface via the native Viewer.
	fmt.Println("\n--- 3D render ---")
	cam := picogkffi.DefaultCameraState()
	cam.BgR = 0.16
	cam.BgG = 0.16
	cam.BgB = 0.20
	cam.BgA = 1.0
	v := picogkffi.NewViewerEx("PicoGK Visualize (FFI)", 1280, 960, cam)
	v.AddVoxels(0, part)
	v.SetGroupMaterial(0, picogkffi.ColorFloat{R: 0.35, G: 0.6, B: 0.9, A: 1.0}, 0.1, 0.5)
	previewPath := filepath.Join(outdir, "mesh_preview.png")
	v.Screenshot(previewPath, 12)
	v.RequestClose()
	v.Destroy()
	fmt.Printf("  -> %s  (3D Viewer render)\n", previewPath)

	fmt.Println("\ndone.")
}

// writeSlicePNG writes a Z-slice SDF array to a grayscale PNG.
// SDF values <= 0 are inside (solid) → dark; > 0 are outside → light.
func writeSlicePNG(path string, sdf []float32, sizeX, sizeY int32, verbose bool) error {
	if len(sdf) == 0 {
		return fmt.Errorf("empty slice")
	}
	// Find the SDF range for normalization.
	minVal, maxVal := float32(math.MaxFloat32), float32(-math.MaxFloat32)
	for _, v := range sdf {
		if v < minVal {
			minVal = v
		}
		if v > maxVal {
			maxVal = v
		}
	}
	if verbose {
		fmt.Printf("  slice SDF range: [%.3f, %.3f]\n", minVal, maxVal)
	}

	w, h := int(sizeX), int(sizeY)
	if w*h > len(sdf) {
		// Dimensions may not match exactly; use what we have.
		w = len(sdf)
		if h > 0 {
			w = len(sdf) / h
		}
	}

	img := image.NewGray(image.Rect(0, 0, w, h))
	for i := 0; i < w*h && i < len(sdf); i++ {
		v := sdf[i]
		var g uint8
		if v <= 0 {
			// Inside: dark blue-gray (solid)
			g = 40
		} else {
			// Outside: scale by SDF distance
			t := float64(v) / float64(maxVal+1e-6)
			if t > 1 {
				t = 1
			}
			g = uint8(40 + t*200)
		}
		img.Pix[i] = g
	}

	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()
	return png.Encode(f, img)
}
