package main

import (
	"fmt"
	"math"
	"runtime"

	"github.com/gmlewis/PicoGK/sdk/go/picogkffi"
)

// SolidResult summarises a PicoGK-solidified rotor export.
type SolidResult struct {
	PicoGKVersion string
	VoxelSizeMM   float32
	VolumeMM3     float64
	Vertices      int
	Triangles     int
}

// exportSolidSTL rasterizes a closed triangle mesh into a PicoGK voxel field,
// cuts it flat at the print-bed plane, extracts the resulting solid with
// marching cubes, and writes it as a binary STL file.
func exportSolidSTL(path string, mesh *MeshData, voxelSizeMM, bedZ float32) (*SolidResult, error) {
	if voxelSizeMM <= 0 {
		return nil, fmt.Errorf("voxel size must be positive, got %g mm", voxelSizeMM)
	}
	if mesh == nil || mesh.TriangleCount() == 0 {
		return nil, fmt.Errorf("empty rotor mesh")
	}

	// PicoGK's runtime is happiest when every call happens on one OS thread.
	runtime.LockOSThread()
	defer runtime.UnlockOSThread()

	if err := picogkffi.InitWithSize(voxelSizeMM); err != nil {
		return nil, fmt.Errorf("initialize PicoGK: %w", err)
	}
	defer picogkffi.Shutdown()

	source := picogkffi.MeshFromArrays(mesh.Vertices, mesh.Triangles)
	defer source.Destroy()

	voxels := picogkffi.FromMesh(source)
	defer voxels.Destroy()
	if voxels.IsEmpty() {
		return nil, fmt.Errorf("PicoGK produced an empty solid (voxel size %g mm); "+
			"the blade may be thinner than a voxel or the mesh may not be closed", voxelSizeMM)
	}

	// The blade sheets run smoothly past the bed plane. Clip them there so
	// the printed part starts on a flat, fully supported footprint.
	cut := bedCutBox(mesh, bedZ)
	defer cut.Destroy()
	voxels.BoolIntersect(cut)
	if voxels.IsEmpty() {
		return nil, fmt.Errorf("PicoGK produced an empty solid after the bed cut at z=%g mm", bedZ)
	}

	out := voxels.ToMesh()
	defer out.Destroy()
	if out.TriangleCount() == 0 {
		return nil, fmt.Errorf("PicoGK marching cubes produced an empty mesh")
	}

	if err := writeBinarySTL(path, out.Vertices(), out.Triangles()); err != nil {
		return nil, fmt.Errorf("write %s: %w", path, err)
	}

	return &SolidResult{
		PicoGKVersion: picogkffi.Version(),
		VoxelSizeMM:   voxelSizeMM,
		VolumeMM3:     float64(voxels.Volume()),
		Vertices:      int(out.VertexCount()),
		Triangles:     int(out.TriangleCount()),
	}, nil
}

// bedCutBox voxelizes a closed box that starts exactly at the bed plane and
// encloses the rotor. Intersecting the rotor with it removes everything below
// the bed, leaving a flat, fully supported bottom face.
func bedCutBox(mesh *MeshData, bedZ float32) *picogkffi.Voxels {
	minX, maxX := float32(math.MaxFloat32), float32(-math.MaxFloat32)
	minY, maxY := minX, maxX
	maxZ := maxX
	for i := 0; i+2 < len(mesh.Vertices); i += 3 {
		x, y, z := mesh.Vertices[i], mesh.Vertices[i+1], mesh.Vertices[i+2]
		minX = min32(minX, x)
		maxX = max32(maxX, x)
		minY = min32(minY, y)
		maxY = max32(maxY, y)
		maxZ = max32(maxZ, z)
	}
	const pad = float32(2)
	x0, x1 := minX-pad, maxX+pad
	y0, y1 := minY-pad, maxY+pad
	z0, z1 := bedZ, maxZ+pad

	vertices := []float32{
		x0, y0, z0, x1, y0, z0, x1, y1, z0, x0, y1, z0,
		x0, y0, z1, x1, y0, z1, x1, y1, z1, x0, y1, z1,
	}
	triangles := []int32{
		0, 2, 1, 0, 3, 2, // bottom, -Z
		4, 5, 6, 4, 6, 7, // top, +Z
		0, 1, 5, 0, 5, 4, // front, -Y
		3, 7, 6, 3, 6, 2, // back, +Y
		0, 4, 7, 0, 7, 3, // left, -X
		1, 2, 6, 1, 6, 5, // right, +X
	}
	box := picogkffi.MeshFromArrays(vertices, triangles)
	defer box.Destroy()
	return picogkffi.FromMesh(box)
}

func min32(a, b float32) float32 {
	if a < b {
		return a
	}
	return b
}

func max32(a, b float32) float32 {
	if a > b {
		return a
	}
	return b
}
