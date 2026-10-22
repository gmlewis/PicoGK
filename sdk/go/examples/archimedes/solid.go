package main

import (
	"fmt"
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
// extracts the resulting solid with marching cubes, and writes it as a binary
// STL file.
func exportSolidSTL(path string, mesh *MeshData, voxelSizeMM float32) (*SolidResult, error) {
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
