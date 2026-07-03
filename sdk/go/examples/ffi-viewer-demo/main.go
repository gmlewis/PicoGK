// Viewer demo via the native FFI SDK: build a hollow shelled part and render
// it to a PNG using the native OpenGL Viewer.
//
// This is the FFI counterpart to the viewer-demo example (a Go port of the
// PicoPie Python example viewer_demo.py). It uses the picogkffi package,
// which binds directly to the native PicoGK C++ runtime. Rendering uses the
// native OpenGL Viewer (the same viewer PicoPie uses) via ViewerEx.Screenshot,
// which produces a higher-quality PBR-shaded image than the MCP
// render_to_image tool's isometric Lambertian projection.
//
// Requires a display (GLFW/OpenGL). On macOS, the main goroutine must be
// locked to the OS main thread (done below).
//
// Run:  go run main.go [output.png]
package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"runtime"

	"github.com/gmlewis/PicoGK/sdk/go/picogkffi"
)

func main() {
	flag.Parse()

	// The OpenGL Viewer requires the OS main thread on macOS.
	runtime.LockOSThread()
	defer runtime.UnlockOSThread()

	out := "/tmp/go-picogkffi-viewer/viewer_demo.png"
	if flag.NArg() > 0 {
		out = flag.Arg(0)
	}
	os.MkdirAll(filepath.Dir(out), 0755)

	fmt.Println("=== Viewer Demo (Go FFI) ===")

	if err := picogkffi.InitWithSize(0.2); err != nil {
		fmt.Fprintln(os.Stderr, "Init:", err)
		os.Exit(1)
	}
	defer picogkffi.Shutdown()

	fmt.Println("PicoGK", picogkffi.Version())

	// A hollow shell with a bite taken out, so the wall is visible.
	body := picogkffi.NewSphere(picogkffi.Vec3{0, 0, 0}, 12)
	defer body.Destroy()
	bite := picogkffi.NewSphere(picogkffi.Vec3{8, 0, 0}, 7)
	defer bite.Destroy()
	part := body.Sub(bite)
	defer part.Destroy()
	part.Shell(1.5)
	fmt.Printf("  shelled part volume: %.1f mm³\n", part.Volume())

	// Render via the native ViewerEx (PBR shading, screenshot to PNG).
	cam := picogkffi.DefaultCameraState()
	cam.BgR = 0.16
	cam.BgG = 0.16
	cam.BgB = 0.20
	cam.BgA = 1.0
	v := picogkffi.NewViewerEx("PicoGK Viewer Demo (FFI)", 1280, 960, cam)
	v.AddVoxels(0, part)
	v.SetGroupMaterial(0, picogkffi.ColorFloat{R: 0.35, G: 0.6, B: 0.9, A: 1.0}, 0.1, 0.5)
	v.Screenshot(out, 12)
	v.RequestClose()
	v.Destroy()

	fmt.Printf("wrote %s\n", out)
	fmt.Println("done.")
}
