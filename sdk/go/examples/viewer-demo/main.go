// Headless render demo: build a hollow shelled part and render it to a PNG.
//
// This is a Go port of the PicoPie Python example viewer_demo.py.
// The Go MCP SDK does not include an interactive OpenGL viewer (that requires
// a display + GLFW). Instead, this example exercises the headless
// render_to_image tool, which produces a PNG via an isometric projection with
// Lambertian shading.
//
// Run:  go run main.go [output.png]
package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"

	"github.com/gmlewis/PicoGK/sdk/go/picogk"
)

func main() {
	log.SetFlags(0)
	flag.Parse()
	ctx := context.Background()

	out := "/tmp/go-picogk-viewer/viewer_demo.png"
	if flag.NArg() > 0 {
		out = flag.Arg(0)
	}
	os.MkdirAll(filepath_dir(out), 0755)

	fmt.Println("=== Viewer Demo (Go) ===")

	client, err := picogk.NewClient(ctx, "")
	if err != nil {
		log.Fatalf("NewClient: %v", err)
	}
	defer client.Close()

	do := func(cmd any) { client.Must(cmd) }

	do(picogk.Init{VoxelSizeMM: new(0.2)})

	// A hollow shell with a bite taken out, so the wall is visible.
	do(picogk.CreateSphere{X: 0, Y: 0, Z: 0, Radius: 12, ID: "body"})
	do(picogk.CreateSphere{X: 8, Y: 0, Z: 0, Radius: 7, ID: "bite"})
	do(picogk.BooleanSubtract{A: "body", B: "bite", ID: "part"})
	do(picogk.Shell{ObjectID: "part", InnerOffset: 1.5, OuterOffset: 0, ID: "shelled"})

	// Headless render to PNG.
	do(picogk.RenderToImage{
		ObjectID:        "shelled",
		Path:            out,
		Width:           new(1280),
		Height:          new(960),
		BackgroundColor:  "#292933",
		ObjectColor:      "#5999e6",
	})

	fmt.Printf("wrote %s\n", out)
	fmt.Println("\n(Interactive OpenGL viewer not available in the Go MCP SDK.)")
	client.Must(picogk.Shutdown{})
}

// filepath_dir returns the directory portion of a path (like filepath.Dir but
// avoids importing filepath just for this).
func filepath_dir(p string) string {
	for i := len(p) - 1; i >= 0; i-- {
		if p[i] == '/' {
			if i == 0 {
				return "/"
			}
			return p[:i]
		}
	}
	return "."
}