package picogkffi

/*
#include <stdlib.h>
#include "picogk_ffi.h"
*/
import "C"

// VdbFile represents an OpenVDB file handle for reading/writing voxel data.
type VdbFile struct {
	h C.PKVDBFILE
}

// NewVdbFile creates an empty VDB file handle.
func NewVdbFile() *VdbFile {
	mustInit()
	return &VdbFile{h: C.VdbFile_hCreate(instance)}
}

// VdbFileFromFile loads a VDB file from disk.
func VdbFileFromFile(path string) *VdbFile {
	mustInit()
	p := cstr(path)
	defer freeCstr(p)
	return &VdbFile{h: C.VdbFile_hCreateFromFile(instance, p)}
}

// IsValid returns true if the handle is valid.
func (f *VdbFile) IsValid() bool {
	return f.h != 0 && bool(C.VdbFile_bIsValid(instance, f.h))
}

// Destroy frees the native VDB file handle.
func (f *VdbFile) Destroy() {
	if f.h != 0 {
		C.VdbFile_Destroy(instance, f.h)
		f.h = 0
	}
}

// MemUsage returns memory in bytes.
func (f *VdbFile) MemUsage() int64 {
	return int64(C.VdbFile_nMemUsage(instance, f.h))
}

// SaveToFile saves the VDB file to disk.
func (f *VdbFile) SaveToFile(path string) bool {
	p := cstr(path)
	defer freeCstr(p)
	return bool(C.VdbFile_bSaveToFile(instance, f.h, p))
}

// AddVoxels adds a voxel field to the VDB file with the given name.
// Returns the field index.
func (f *VdbFile) AddVoxels(name string, vox *Voxels) int32 {
	p := cstr(name)
	defer freeCstr(p)
	return int32(C.VdbFile_nAddVoxels(instance, f.h, p, vox.h))
}

// GetVoxels returns the voxel field at the given index.
func (f *VdbFile) GetVoxels(index int32) *Voxels {
	return &Voxels{h: C.VdbFile_hGetVoxels(instance, f.h, C.int32_t(index))}
}

// AddScalarField adds a scalar field to the VDB file with the given name.
// Returns the field index.
func (f *VdbFile) AddScalarField(name string, sf *ScalarField) int32 {
	p := cstr(name)
	defer freeCstr(p)
	return int32(C.VdbFile_nAddScalarField(instance, f.h, p, sf.h))
}

// GetScalarField returns the scalar field at the given index.
func (f *VdbFile) GetScalarField(index int32) *ScalarField {
	return &ScalarField{h: C.VdbFile_hGetScalarField(instance, f.h, C.int32_t(index))}
}

// AddVectorField adds a vector field to the VDB file with the given name.
// Returns the field index.
func (f *VdbFile) AddVectorField(name string, vf *VectorField) int32 {
	p := cstr(name)
	defer freeCstr(p)
	return int32(C.VdbFile_nAddVectorField(instance, f.h, p, vf.h))
}

// GetVectorField returns the vector field at the given index.
func (f *VdbFile) GetVectorField(index int32) *VectorField {
	return &VectorField{h: C.VdbFile_hGetVectorField(instance, f.h, C.int32_t(index))}
}

// FieldCount returns the number of fields in the VDB file.
func (f *VdbFile) FieldCount() int32 {
	return int32(C.VdbFile_nFieldCount(instance, f.h))
}

// GetFieldName returns the name of the field at the given index.
func (f *VdbFile) GetFieldName(index int32) string {
	buf := make([]C.char, C.PKINFOSTRINGLEN)
	C.VdbFile_GetFieldName(instance, f.h, C.int32_t(index), &buf[0])
	return goStringFromC(buf)
}

// FieldType returns the type of the field at the given index.
// Returns one of FieldTypeVoxels, FieldTypeScalar, FieldTypeVector, or FieldTypeUnknown.
func (f *VdbFile) FieldType(index int32) int32 {
	return int32(C.VdbFile_nFieldType(instance, f.h, C.int32_t(index)))
}

// ScalarField represents a scalar field for voxel data.
type ScalarField struct {
	h C.PKSCALARFIELD
}

// NewScalarField creates an empty scalar field.
func NewScalarField() *ScalarField {
	mustInit()
	return &ScalarField{h: C.ScalarField_hCreate(instance)}
}

// ScalarFieldFromVoxels creates a scalar field from a voxel field.
func ScalarFieldFromVoxels(v *Voxels) *ScalarField {
	mustInit()
	return &ScalarField{h: C.ScalarField_hCreateFromVoxels(instance, v.h)}
}

// ScalarFieldBuildFromVoxels builds a scalar field from voxels with min/max range.
func ScalarFieldBuildFromVoxels(v *Voxels, minVal, maxVal float32) *ScalarField {
	mustInit()
	return &ScalarField{h: C.ScalarField_hBuildFromVoxels(instance, v.h, C.float(minVal), C.float(maxVal))}
}

// ScalarFieldCopy creates a deep copy of the scalar field.
func (sf *ScalarField) ScalarFieldCopy() *ScalarField {
	mustInit()
	return &ScalarField{h: C.ScalarField_hCreateCopy(instance, sf.h)}
}

// IsValid returns true if the handle is valid.
func (sf *ScalarField) IsValid() bool {
	return sf.h != 0 && bool(C.ScalarField_bIsValid(instance, sf.h))
}

// Destroy frees the native scalar field handle.
func (sf *ScalarField) Destroy() {
	if sf.h != 0 {
		C.ScalarField_Destroy(instance, sf.h)
		sf.h = 0
	}
}

// MemUsage returns memory in bytes.
func (sf *ScalarField) MemUsage() int64 {
	return int64(C.ScalarField_nMemUsage(instance, sf.h))
}

// SetValue sets a value at the given point.
func (sf *ScalarField) SetValue(pt Vec3, val float32) {
	c := pt.toC()
	C.ScalarField_SetValue(instance, sf.h, &c, C.float(val))
}

// GetValue returns the value at the given point, or false if not set.
func (sf *ScalarField) GetValue(pt Vec3) (float32, bool) {
	c := pt.toC()
	var val C.float
	ok := bool(C.ScalarField_bGetValue(instance, sf.h, &c, &val))
	return float32(val), ok
}

// RemoveValue removes the value at the given point.
func (sf *ScalarField) RemoveValue(pt Vec3) {
	c := pt.toC()
	C.ScalarField_RemoveValue(instance, sf.h, &c)
}

// ScalarFieldDimensions returns the voxel grid origin and size.
func (sf *ScalarField) ScalarFieldDimensions() (originX, originY, originZ, sizeX, sizeY, sizeZ int32) {
	var cx, cy, cz, sx, sy, sz C.int32_t
	C.ScalarField_GetVoxelDimensions(instance, sf.h, &cx, &cy, &cz, &sx, &sy, &sz)
	return int32(cx), int32(cy), int32(cz), int32(sx), int32(sy), int32(sz)
}

// GetSlice returns the scalar values for the given Z slice as a flat float32 array.
func (sf *ScalarField) GetSlice(z int32) []float32 {
	_, _, _, sx, sy, _ := sf.ScalarFieldDimensions()
	n := int(sx * sy)
	result := make([]float32, n)
	if n > 0 {
		C.ScalarField_GetSlice(instance, sf.h, C.int32_t(z), (*C.float)(&result[0]))
	}
	return result
}

// VectorField represents a vector field for voxel data.
type VectorField struct {
	h C.PKVECTORFIELD
}

// NewVectorField creates an empty vector field.
func NewVectorField() *VectorField {
	mustInit()
	return &VectorField{h: C.VectorField_hCreate(instance)}
}

// VectorFieldFromVoxels creates a vector field from a voxel field.
func VectorFieldFromVoxels(v *Voxels) *VectorField {
	mustInit()
	return &VectorField{h: C.VectorField_hCreateFromVoxels(instance, v.h)}
}

// VectorFieldBuildFromVoxels builds a vector field from voxels with a reference vector.
func VectorFieldBuildFromVoxels(v *Voxels, ref Vec3, scale float32) *VectorField {
	mustInit()
	c := ref.toC()
	return &VectorField{h: C.VectorField_hBuildFromVoxels(instance, v.h, &c, C.float(scale))}
}

// VectorFieldCopy creates a deep copy of the vector field.
func (vf *VectorField) VectorFieldCopy() *VectorField {
	mustInit()
	return &VectorField{h: C.VectorField_hCreateCopy(instance, vf.h)}
}

// IsValid returns true if the handle is valid.
func (vf *VectorField) IsValid() bool {
	return vf.h != 0 && bool(C.VectorField_bIsValid(instance, vf.h))
}

// Destroy frees the native vector field handle.
func (vf *VectorField) Destroy() {
	if vf.h != 0 {
		C.VectorField_Destroy(instance, vf.h)
		vf.h = 0
	}
}

// MemUsage returns memory in bytes.
func (vf *VectorField) MemUsage() int64 {
	return int64(C.VectorField_nMemUsage(instance, vf.h))
}

// SetValue sets a vector value at the given point.
func (vf *VectorField) SetValue(pt, val Vec3) {
	cp := pt.toC()
	cv := val.toC()
	C.VectorField_SetValue(instance, vf.h, &cp, &cv)
}

// GetValue returns the vector value at the given point, or false if not set.
func (vf *VectorField) GetValue(pt Vec3) (Vec3, bool) {
	c := pt.toC()
	var out C.PKVector3
	ok := bool(C.VectorField_bGetValue(instance, vf.h, &c, &out))
	return vec3FromC(out), ok
}

// RemoveValue removes the vector value at the given point.
func (vf *VectorField) RemoveValue(pt Vec3) {
	c := pt.toC()
	C.VectorField_RemoveValue(instance, vf.h, &c)
}
