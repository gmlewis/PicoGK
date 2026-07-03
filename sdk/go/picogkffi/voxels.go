package picogkffi

/*
#include <stdlib.h>
#include "picogk_ffi.h"
*/
import "C"

// Voxels is a signed-distance / level-set volume.
type Voxels struct {
	h C.PKVOXELS
}

// NewVoxels creates an empty voxel field.
func NewVoxels() *Voxels {
	mustInit()
	return &Voxels{h: C.Voxels_hCreate(instance)}
}

// NewSphere creates a sphere voxel field.
func NewSphere(center Vec3, radius float32) *Voxels {
	mustInit()
	c := center.toC()
	return &Voxels{h: C.Voxels_hCreateSphere(instance, &c, C.float(radius))}
}

// NewCapsule creates a capsule (sphere-swept segment) voxel field.
func NewCapsule(start, end Vec3, radius1, radius2 float32) *Voxels {
	mustInit()
	s, e := start.toC(), end.toC()
	return &Voxels{h: C.Voxels_hCreateCapsule(instance, &s, &e, C.float(radius1), C.float(radius2))}
}

// NewMeshShell creates a voxel shell from a mesh at the given radius.
func NewMeshShell(mesh *Mesh, radius float32) *Voxels {
	mustInit()
	return &Voxels{h: C.Voxels_hCreateMeshShell(instance, mesh.h, C.float(radius))}
}

// FromMesh creates a voxel field by rasterizing a mesh.
func FromMesh(mesh *Mesh) *Voxels {
	mustInit()
	v := NewVoxels()
	C.Voxels_RenderMesh(instance, v.h, mesh.h)
	return v
}

// FromLattice creates a voxel field by rasterizing a lattice.
func FromLattice(lat *Lattice) *Voxels {
	mustInit()
	v := NewVoxels()
	C.Voxels_RenderLattice(instance, v.h, lat.h)
	return v
}

// Copy creates a deep copy.
func (v *Voxels) Copy() *Voxels {
	mustInit()
	return &Voxels{h: C.Voxels_hCreateCopy(instance, v.h)}
}

// Destroy frees the native voxels handle.
func (v *Voxels) Destroy() {
	if v.h != 0 {
		C.Voxels_Destroy(instance, v.h)
		v.h = 0
	}
}

// IsValid returns true if the handle is valid.
func (v *Voxels) IsValid() bool {
	return v.h != 0 && bool(C.Voxels_bIsValid(instance, v.h))
}

// IsEmpty returns true if the voxel field contains no volume.
func (v *Voxels) IsEmpty() bool {
	return bool(C.Voxels_bIsEmpty(instance, v.h))
}

// MemUsage returns memory in bytes.
func (v *Voxels) MemUsage() int64 {
	return int64(C.Voxels_nMemUsage(instance, v.h))
}

// VoxelSize returns the voxel size in mm.
func (v *Voxels) VoxelSize() float32 {
	return float32(C.Voxels_fVoxelSize(instance, v.h))
}

// BoolAdd adds other to this voxel field (in-place).
func (v *Voxels) BoolAdd(other *Voxels) {
	C.Voxels_BoolAdd(instance, v.h, other.h)
}

// BoolSubtract subtracts other from this voxel field (in-place).
func (v *Voxels) BoolSubtract(other *Voxels) {
	C.Voxels_BoolSubtract(instance, v.h, other.h)
}

// BoolIntersect intersects this voxel field with other (in-place).
func (v *Voxels) BoolIntersect(other *Voxels) {
	C.Voxels_BoolIntersect(instance, v.h, other.h)
}

// Add returns a new voxel field that is the union of v and other.
func (v *Voxels) Add(other *Voxels) *Voxels {
	r := v.Copy()
	r.BoolAdd(other)
	return r
}

// Sub returns a new voxel field that is v minus other.
func (v *Voxels) Sub(other *Voxels) *Voxels {
	r := v.Copy()
	r.BoolSubtract(other)
	return r
}

// Intersect returns a new voxel field that is the intersection of v and other.
func (v *Voxels) Intersect(other *Voxels) *Voxels {
	r := v.Copy()
	r.BoolIntersect(other)
	return r
}

// Offset expands (positive) or shrinks (negative) the surface by dist mm.
func (v *Voxels) Offset(dist float32) {
	C.Voxels_Offset(instance, v.h, C.float(dist))
}

// DoubleOffset applies two sequential offsets.
func (v *Voxels) DoubleOffset(dist1, dist2 float32) {
	C.Voxels_DoubleOffset(instance, v.h, C.float(dist1), C.float(dist2))
}

// TripleOffset applies triple-offset smoothing.
func (v *Voxels) TripleOffset(dist float32) {
	C.Voxels_TripleOffset(instance, v.h, C.float(dist))
}

// Shell creates a hollow shell of the given thickness (in-place).
func (v *Voxels) Shell(thickness float32) {
	c := v.Copy()
	c.Offset(-thickness)
	v.BoolSubtract(c)
	c.Destroy()
}

// RenderMesh rasterizes a mesh into this voxel field (in-place).
func (v *Voxels) RenderMesh(mesh *Mesh) {
	C.Voxels_RenderMesh(instance, v.h, mesh.h)
}

// RenderLattice rasterizes a lattice into this voxel field (in-place).
func (v *Voxels) RenderLattice(lat *Lattice) {
	C.Voxels_RenderLattice(instance, v.h, lat.h)
}

// ProjectZSlice projects the voxel field onto a Z range (in-place).
func (v *Voxels) ProjectZSlice(startZ, endZ float32) {
	C.Voxels_ProjectZSlice(instance, v.h, C.float(startZ), C.float(endZ))
}

// IsInside returns true if the point is inside the solid.
func (v *Voxels) IsInside(pt Vec3) bool {
	c := pt.toC()
	return bool(C.Voxels_bIsInside(instance, v.h, &c))
}

// IsEqual returns true if two voxel fields contain the same data.
func (v *Voxels) IsEqual(other *Voxels) bool {
	return bool(C.Voxels_bIsEqual(instance, v.h, other.h))
}

// Volume returns the volume in mm³.
func (v *Voxels) Volume() float32 {
	return float32(C.Voxels_fCalculateVolume(instance, v.h))
}

// SurfaceNormal returns the surface normal at a surface point.
func (v *Voxels) SurfaceNormal(pt Vec3) Vec3 {
	c := pt.toC()
	var out C.PKVector3
	C.Voxels_GetSurfaceNormal(instance, v.h, &c, &out)
	return vec3FromC(out)
}

// ClosestPoint returns the closest surface point to the query point,
// or false if no surface was found.
func (v *Voxels) ClosestPoint(pt Vec3) (Vec3, bool) {
	c := pt.toC()
	var out C.PKVector3
	ok := bool(C.Voxels_bClosestPointOnSurface(instance, v.h, &c, &out))
	return vec3FromC(out), ok
}

// RayCast casts a ray from origin in the given direction. Returns the hit
// point and true if the surface was hit.
func (v *Voxels) RayCast(origin, dir Vec3) (Vec3, bool) {
	co := origin.toC()
	cd := dir.toC()
	var out C.PKVector3
	ok := bool(C.Voxels_bRayCastToSurface(instance, v.h, &co, &cd, &out))
	return vec3FromC(out), ok
}

// VoxelDimensions returns the voxel grid origin and size.
func (v *Voxels) VoxelDimensions() (originX, originY, originZ, sizeX, sizeY, sizeZ int32) {
	var cx, cy, cz, sx, sy, sz C.int32_t
	C.Voxels_GetVoxelDimensions(instance, v.h, &cx, &cy, &cz, &sx, &sy, &sz)
	return int32(cx), int32(cy), int32(cz), int32(sx), int32(sy), int32(sz)
}

// BoundingBox returns the bounding box in mm.
func (v *Voxels) BoundingBox() BBox3 {
	ox, oy, oz, sx, sy, sz := v.VoxelDimensions()
	// Convert voxel origin and origin+size to mm
	voxMin := C.PKVector3{X: C.float(float32(ox)), Y: C.float(float32(oy)), Z: C.float(float32(oz))}
	voxMax := C.PKVector3{X: C.float(float32(ox + sx)), Y: C.float(float32(oy + sy)), Z: C.float(float32(oz + sz))}
	var mmMin, mmMax C.PKVector3
	C.Library_VoxelsToMm(instance, &voxMin, &mmMin)
	C.Library_VoxelsToMm(instance, &voxMax, &mmMax)
	return BBox3{Min: vec3FromC(mmMin), Max: vec3FromC(mmMax)}
}

// ToMesh converts the voxel field to a mesh via marching cubes.
func (v *Voxels) ToMesh() *Mesh {
	mustInit()
	return &Mesh{h: C.Mesh_hCreateFromVoxels(instance, v.h)}
}

// Diagnose returns diagnostic information about the voxel field.
func (v *Voxels) Diagnose() string {
	buf := make([]C.char, C.PKINFOSTRINGLEN)
	C.Voxels_bDiagnose(instance, v.h, &buf[0])
	return goStringFromC(buf)
}

// GetXSlice returns the SDF values for the given X slice as a flat float32 array.
// The array has sizeY * sizeZ elements, indexed as [y*sizeZ + z].
func (v *Voxels) GetXSlice(x int32) []float32 {
	_, _, _, _, sy, sz := v.VoxelDimensions()
	n := int(sy * sz)
	result := make([]float32, n)
	if n > 0 {
		var bg C.float
		C.Voxels_GetXSlice(instance, v.h, C.int32_t(x), (*C.float)(&result[0]), &bg)
	}
	return result
}

// GetYSlice returns the SDF values for the given Y slice as a flat float32 array.
// The array has sizeX * sizeZ elements, indexed as [x*sizeZ + z].
func (v *Voxels) GetYSlice(y int32) []float32 {
	_, _, _, sx, _, sz := v.VoxelDimensions()
	n := int(sx * sz)
	result := make([]float32, n)
	if n > 0 {
		var bg C.float
		C.Voxels_GetYSlice(instance, v.h, C.int32_t(y), (*C.float)(&result[0]), &bg)
	}
	return result
}

// GetZSlice returns the SDF values for the given Z slice as a flat float32 array.
// The array has sizeX * sizeY elements, indexed as [x*sizeY + y].
func (v *Voxels) GetZSlice(z int32) []float32 {
	_, _, _, sx, sy, _ := v.VoxelDimensions()
	n := int(sx * sy)
	result := make([]float32, n)
	if n > 0 {
		var bg C.float
		C.Voxels_GetZSlice(instance, v.h, C.int32_t(z), (*C.float)(&result[0]), &bg)
	}
	return result
}

// GetInterpolatedZSlice returns the SDF values at the given floating-point Z position
// by trilinear interpolation. The array has sizeX * sizeY elements.
func (v *Voxels) GetInterpolatedZSlice(z float32) []float32 {
	_, _, _, sx, sy, _ := v.VoxelDimensions()
	n := int(sx * sy)
	result := make([]float32, n)
	if n > 0 {
		var bg C.float
		C.Voxels_GetInterpolatedZSlice(instance, v.h, C.float(z), (*C.float)(&result[0]), &bg)
	}
	return result
}
