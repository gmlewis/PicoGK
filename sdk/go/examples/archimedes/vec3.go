package main

import (
	"fmt"
	"math"
)

// Vec3 is a point/vector in millimetres.
type Vec3 struct{ X, Y, Z float64 }

func (a Vec3) String() string       { return fmt.Sprintf("{X:%.2f Y:%.2f Z:%.2f}", a.X, a.Y, a.Z) }
func (a Vec3) Add(b Vec3) Vec3      { return Vec3{a.X + b.X, a.Y + b.Y, a.Z + b.Z} }
func (a Vec3) Sub(b Vec3) Vec3      { return Vec3{a.X - b.X, a.Y - b.Y, a.Z - b.Z} }
func (a Vec3) Scale(s float64) Vec3 { return Vec3{a.X * s, a.Y * s, a.Z * s} }
func (a Vec3) Norm() float64        { return math.Sqrt(a.X*a.X + a.Y*a.Y + a.Z*a.Z) }

// Cross returns a × b.
func (a Vec3) Cross(b Vec3) Vec3 {
	return Vec3{
		a.Y*b.Z - a.Z*b.Y,
		a.Z*b.X - a.X*b.Z,
		a.X*b.Y - a.Y*b.X,
	}
}

// Dot returns a · b.
func (a Vec3) Dot(b Vec3) float64 { return a.X*b.X + a.Y*b.Y + a.Z*b.Z }

// Normalized returns a unit vector in the direction of a, or the zero
// vector if a has zero length.
func (a Vec3) Normalized() Vec3 {
	n := a.Norm()
	if n == 0 {
		return Vec3{}
	}
	return a.Scale(1 / n)
}

// RotateZ returns a rotated by angle radians about the Z axis.
func (a Vec3) RotateZ(angle float64) Vec3 {
	c, s := math.Cos(angle), math.Sin(angle)
	return Vec3{c*a.X - s*a.Y, s*a.X + c*a.Y, a.Z}
}
func (a Vec3) Finite() bool {
	return !math.IsNaN(a.X) && !math.IsNaN(a.Y) && !math.IsNaN(a.Z) &&
		!math.IsInf(a.X, 0) && !math.IsInf(a.Y, 0) && !math.IsInf(a.Z, 0)
}
