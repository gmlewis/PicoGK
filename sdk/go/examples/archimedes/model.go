package main

import (
	"errors"
	"math"
)

var ErrInvalidConfig = errors.New("invalid turbine configuration")

// Config describes the geometry. All lengths are millimetres.
type Config struct {
	RotorDiameter float64 // outer diameter at the wide (root) end
	AxialLength   float64 // full axial span of the rotor
	BladeCount    int
	Samples       int     // samples along each blade's spiral
	ApexRadius    float64 // radius at the narrow end, as a fraction of the rotor radius
	Turns         float64 // spiral turns per blade; 1 matches the standard blade
	Thickness     float64 // blade thickness, measured normal to the ruled surface
}

// defaultConfig returns the user-selected envelope and conservative starting sampling.
func defaultConfig() Config {
	return Config{
		RotorDiameter: 150, AxialLength: 140, BladeCount: 3,
		Samples: 240, ApexRadius: 0.05, Turns: 1,
		Thickness: 1.2,
	}
}

func (c Config) Validate() error {
	if c.RotorDiameter <= 0 || c.AxialLength <= 0 || c.BladeCount < 1 ||
		c.Samples < 8 || c.ApexRadius <= 0 || c.ApexRadius >= 1 ||
		c.Turns <= 0 || c.Thickness <= 0 {
		return ErrInvalidConfig
	}
	for _, v := range []float64{c.RotorDiameter, c.AxialLength, c.ApexRadius, c.Turns, c.Thickness} {
		if math.IsNaN(v) || math.IsInf(v, 0) {
			return ErrInvalidConfig
		}
	}
	return nil
}

// RotorRadius is half the target outer diameter.
func (c Config) RotorRadius() float64 { return c.RotorDiameter / 2 }

// bladeSpan is the angular span of one blade in radians.
func (c Config) bladeSpan() float64 { return 2 * math.Pi * c.Turns }

// SpiralPoint evaluates the 3D conical spiral that bounds the blade at v=1.
// u is in radians over one blade (0 <= u <= 2*pi*Turns). The projected radius
// shrinks linearly from the rotor radius at u=0 (the wide root) to
// ApexRadius*RotorRadius at u=2*pi*Turns (the narrow upwind end), while z
// advances linearly over the axial length.
func (c Config) SpiralPoint(u float64) Vec3 {
	rMax := c.RotorRadius()
	rMin := rMax * c.ApexRadius
	span := c.bladeSpan()
	r := rMax - (rMax-rMin)*u/span
	z := -c.AxialLength/2 + c.AxialLength*u/span
	return Vec3{r * math.Cos(u), r * math.Sin(u), z}
}

// AxisPoint returns the rotor-axis point at the same axial station as
// SpiralPoint(u). Together they define the radial generating line.
func (c Config) AxisPoint(u float64) Vec3 {
	span := c.bladeSpan()
	return Vec3{0, 0, -c.AxialLength/2 + c.AxialLength*u/span}
}

// SpiralDerivative is dB/du at u.
func (c Config) SpiralDerivative(u float64) Vec3 {
	rMax := c.RotorRadius()
	rMin := rMax * c.ApexRadius
	span := c.bladeSpan()
	drdu := -(rMax - rMin) / span
	dzdu := c.AxialLength / span
	r := rMax - (rMax-rMin)*u/span
	return Vec3{
		drdu*math.Cos(u) - r*math.Sin(u),
		drdu*math.Sin(u) + r*math.Cos(u),
		dzdu,
	}
}

// AxisDerivative is dC/du, where C(u)=AxisPoint(u).
func (c Config) AxisDerivative() Vec3 {
	return Vec3{0, 0, c.AxialLength / c.bladeSpan()}
}

// SurfacePoint is the conical helicoid S(u,v) = (1-v) C(u) + v B(u).
// C(u) lies on the rotor axis and B(u) on the 3D spiral; v is in [0,1].
// The generating line is straight and radial at every station, so the
// surface is a ruled helicoid rather than a fan from a single point.
func (c Config) SurfacePoint(u, v float64) Vec3 {
	return c.AxisPoint(u).Scale(1 - v).Add(c.SpiralPoint(u).Scale(v))
}

// SurfaceNormal returns the unit normal of the surface at (u,v).
func (c Config) SurfaceNormal(u, v float64) Vec3 {
	su := c.AxisDerivative().Scale(1 - v).Add(c.SpiralDerivative(u).Scale(v))
	sv := c.SpiralPoint(u).Sub(c.AxisPoint(u))
	return su.Cross(sv).Normalized()
}

// BladeBoundarySamples samples the outer 3D spiral including both endpoints.
func (c Config) BladeBoundarySamples() []Vec3 {
	out := make([]Vec3, c.Samples+1)
	end := c.bladeSpan()
	for i := range out {
		out[i] = c.SpiralPoint(end * float64(i) / float64(c.Samples))
	}
	return out
}
