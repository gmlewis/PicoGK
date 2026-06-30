package picogkffi

/*
#include <stdlib.h>
#include "picogk_ffi.h"
*/
import "C"

// Metadata holds key/value metadata for voxel fields.
type Metadata struct {
	h C.PKMETADATA
}

// MetadataFromVoxels creates metadata from a voxel field.
func MetadataFromVoxels(v *Voxels) *Metadata {
	mustInit()
	return &Metadata{h: C.Metadata_hFromVoxels(instance, v.h)}
}

// MetadataFromScalarField creates metadata from a scalar field.
func MetadataFromScalarField(sf *ScalarField) *Metadata {
	mustInit()
	return &Metadata{h: C.Metadata_hFromScalarField(instance, sf.h)}
}

// MetadataFromVectorField creates metadata from a vector field.
func MetadataFromVectorField(vf *VectorField) *Metadata {
	mustInit()
	return &Metadata{h: C.Metadata_hFromVectorField(instance, vf.h)}
}

// Destroy frees the native metadata handle.
func (m *Metadata) Destroy() {
	if m.h != 0 {
		C.Metadata_Destroy(instance, m.h)
		m.h = 0
	}
}

// Count returns the number of metadata entries.
func (m *Metadata) Count() int32 {
	return int32(C.Metadata_nCount(instance, m.h))
}

// NameAt returns the name of the entry at the given index.
func (m *Metadata) NameAt(index int32) string {
	nameLen := int32(C.Metadata_nNameLengthAt(instance, m.h, C.int32_t(index)))
	if nameLen <= 0 {
		return ""
	}
	buf := make([]C.char, nameLen+1)
	C.Metadata_bGetNameAt(instance, m.h, C.int32_t(index), &buf[0], C.int32_t(nameLen+1))
	return goStringFromC(buf)
}

// TypeAt returns the type of the metadata entry with the given name.
// Returns MetaTypeString, MetaTypeFloat, MetaTypeVector, or MetaTypeUnknown.
func (m *Metadata) TypeAt(name string) int32 {
	p := cstr(name)
	defer freeCstr(p)
	return int32(C.Metadata_nTypeAt(instance, m.h, p))
}

// GetString returns the string value for the given key, or false if not found.
func (m *Metadata) GetString(name string) (string, bool) {
	p := cstr(name)
	defer freeCstr(p)
	strLen := int32(C.Metadata_nStringLengthAt(instance, m.h, p))
	if strLen <= 0 {
		return "", false
	}
	buf := make([]C.char, strLen+1)
	if !bool(C.Metadata_bGetStringAt(instance, m.h, p, &buf[0], C.int32_t(strLen+1))) {
		return "", false
	}
	return goStringFromC(buf), true
}

// GetFloat returns the float value for the given key, or false if not found.
func (m *Metadata) GetFloat(name string) (float32, bool) {
	p := cstr(name)
	defer freeCstr(p)
	var val C.float
	if !bool(C.Metadata_bGetFloatAt(instance, m.h, p, &val)) {
		return 0, false
	}
	return float32(val), true
}

// GetVector returns the vector value for the given key, or false if not found.
func (m *Metadata) GetVector(name string) (Vec3, bool) {
	p := cstr(name)
	defer freeCstr(p)
	var out C.PKVector3
	if !bool(C.Metadata_bGetVectorAt(instance, m.h, p, &out)) {
		return Vec3{}, false
	}
	return vec3FromC(out), true
}

// SetString sets a string value.
func (m *Metadata) SetString(name, value string) {
	pn := cstr(name)
	defer freeCstr(pn)
	pv := cstr(value)
	defer freeCstr(pv)
	C.Metadata_SetStringValue(instance, m.h, pn, pv)
}

// SetFloat sets a float value.
func (m *Metadata) SetFloat(name string, value float32) {
	p := cstr(name)
	defer freeCstr(p)
	C.Metadata_SetFloatValue(instance, m.h, p, C.float(value))
}

// SetVector sets a vector value.
func (m *Metadata) SetVector(name string, value Vec3) {
	pn := cstr(name)
	defer freeCstr(pn)
	v := value.toC()
	C.Metadata_SetVectorValue(instance, m.h, pn, &v)
}

// Remove removes the metadata entry with the given name.
func (m *Metadata) Remove(name string) {
	p := cstr(name)
	defer freeCstr(p)
	C.MetaData_RemoveValue(instance, m.h, p)
}

// Entries returns all metadata entries as a map.
func (m *Metadata) Entries() map[string]any {
	count := int(m.Count())
	result := make(map[string]any, count)
	for i := int32(0); i < int32(count); i++ {
		name := m.NameAt(i)
		typ := m.TypeAt(name)
		switch typ {
		case MetaTypeString:
			if v, ok := m.GetString(name); ok {
				result[name] = v
			}
		case MetaTypeFloat:
			if v, ok := m.GetFloat(name); ok {
				result[name] = v
			}
		case MetaTypeVector:
			if v, ok := m.GetVector(name); ok {
				result[name] = v
			}
		}
	}
	return result
}
