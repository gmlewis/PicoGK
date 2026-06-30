// picogkshapes: A Go port of PicoPie's picogk.shapes parametric shape library.
//
// This package provides high-level parametric shapes (Sphere, Box, Cylinder,
// Ring, Lens, Pipe, etc.) that build meshes from parametric surface sampling
// and rasterize them into voxel fields via the picogkffi FFI binding.
//
// This is a direct port of the Python picogk.shapes package, preserving the
// same algorithms, tessellation parameters, and winding conventions to
// produce identical geometry to the C# ShapeKernel and PicoPie.
package picogkshapes

import (
	"math"

	"github.com/gmlewis/PicoGK/sdk/go/picogkffi"
)

// Vec3 is a 3D float64 vector (used for parametric computations).
type Vec3 struct {
	X, Y, Z float64
}

// Vec is a type alias for Vec3.
type Vec = Vec3

// V returns a Vec3 from 3 floats.
func V(x, y, z float64) Vec3 { return Vec3{X: x, Y: y, Z: z} }

// Add returns v + o.
func (v Vec3) Add(o Vec3) Vec3 { return Vec3{v.X + o.X, v.Y + o.Y, v.Z + o.Z} }

// Sub returns v - o.
func (v Vec3) Sub(o Vec3) Vec3 { return Vec3{v.X - o.X, v.Y - o.Y, v.Z - o.Z} }

// Mul returns v * scalar.
func (v Vec3) Mul(s float64) Vec3 { return Vec3{v.X * s, v.Y * s, v.Z * s} }

// Dot returns the dot product.
func (v Vec3) Dot(o Vec3) float64 { return v.X*o.X + v.Y*o.Y + v.Z*o.Z }

// Cross returns the cross product.
func (v Vec3) Cross(o Vec3) Vec3 {
	return Vec3{
		v.Y*o.Z - v.Z*o.Y,
		v.Z*o.X - v.X*o.Z,
		v.X*o.Y - v.Y*o.X,
	}
}

// Len returns the vector length.
func (v Vec3) Len() float64 { return math.Sqrt(v.X*v.X + v.Y*v.Y + v.Z*v.Z) }

// Normalized returns the unit vector, or zero if length is 0.
func (v Vec3) Normalized() Vec3 {
	l := v.Len()
	if l < 1e-12 {
		return Vec3{}
	}
	return Vec3{v.X / l, v.Y / l, v.Z / l}
}

// SafeNormalized returns the unit vector, or zero if length < eps.
func SafeNormalized(v Vec3, eps ...float64) Vec3 {
	e := 1e-12
	if len(eps) > 0 {
		e = eps[0]
	}
	l := v.Len()
	if l < e {
		return Vec3{}
	}
	return Vec3{v.X / l, v.Y / l, v.Z / l}
}

// Lerp returns linear interpolation: p1*(1-t) + p2*t.
func Lerp(p1, p2 Vec3, t float64) Vec3 {
	return Vec3{
		p1.X*(1-t) + p2.X*t,
		p1.Y*(1-t) + p2.Y*t,
		p1.Z*(1-t) + p2.Z*t,
	}
}

// RotateAroundAxis rotates point pt by angle (radians) around axis through origin.
// Matches C# Quaternion.CreateFromAxisAngle + Vector3.Transform.
func RotateAroundAxis(pt, axis Vec3, angle float64, origin ...Vec3) Vec3 {
	o := Vec3{}
	if len(origin) > 0 {
		o = origin[0]
	}
	pt = pt.Sub(o)
	axis = axis.Normalized()
	if axis.Len() < 1e-12 {
		return pt.Add(o)
	}
	half := angle / 2
	s := math.Sin(half)
	qx, qy, qz, qw := axis.X*s, axis.Y*s, axis.Z*s, math.Cos(half)
	// Quaternion rotation: v' = q * v * q^-1
	// Using the formula: v' = v + 2*cross(q.xyz, cross(q.xyz, v) + qw*v)
	qv := Vec3{qx, qy, qz}
	cross1 := qv.Cross(pt)
	cross1 = cross1.Add(pt.Mul(qw))
	cross2 := qv.Cross(cross1)
	return pt.Add(cross2.Mul(2)).Add(o)
}

// OrthogonalDir returns an arbitrary unit vector orthogonal to direction.
func OrthogonalDir(dir Vec3) Vec3 {
	dir = dir.Normalized()
	if math.Abs(dir.X) < 0.95 {
		return Vec3{1, 0, 0}.Sub(dir.Mul(dir.X)).Normalized()
	}
	return Vec3{0, 1, 0}.Sub(dir.Mul(dir.Y)).Normalized()
}

// ToFFI converts a Vec3 (float64) to a picogkffi.Vec3 (float32).
func ToFFI(v Vec3) picogkffi.Vec3 {
	return picogkffi.Vec3{X: float32(v.X), Y: float32(v.Y), Z: float32(v.Z)}
}

// FromFFI converts a picogkffi.Vec3 (float32) to a Vec3 (float64).
func FromFFI(v picogkffi.Vec3) Vec3 {
	return Vec3{X: float64(v.X), Y: float64(v.Y), Z: float64(v.Z)}
}
