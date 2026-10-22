package main

import (
	"errors"
	"math"
)

var ErrInvalidConfig = errors.New("invalid turbine configuration")

// Config describes the first-pass geometry. All lengths are millimetres.
type Config struct {
	RotorDiameter   float64 // target outer diameter
	AxialLength     float64 // target full z span
	BladeCount      int
	Samples         int     // samples around the one-turn spiral
	RadialStart     float64 // radius at u=0, as a fraction of rotor radius
	Turns           float64 // spiral turns; use 1 for the initial model
	Thickness       float64 // blade thickness, measured normal to the ruled surface
	OpeningAngleDeg float64 // angle between the inner generating line and the +Z rotor axis
}

// defaultConfig returns the user-selected envelope and conservative starting sampling.
func defaultConfig() Config {
	return Config{
		RotorDiameter: 150, AxialLength: 140, BladeCount: 3,
		Samples: 240, RadialStart: 0.08, Turns: 1,
		Thickness: 1.2, OpeningAngleDeg: 80,
	}
}

func (c Config) Validate() error {
	if c.RotorDiameter <= 0 || c.AxialLength <= 0 || c.BladeCount < 1 ||
		c.Samples < 8 || c.RadialStart < 0 || c.RadialStart >= 1 ||
		c.Turns <= 0 || c.Thickness <= 0 ||
		c.OpeningAngleDeg <= 0 || c.OpeningAngleDeg >= 90 {
		return ErrInvalidConfig
	}
	if math.IsNaN(c.RotorDiameter) || math.IsNaN(c.AxialLength) ||
		math.IsInf(c.RotorDiameter, 0) || math.IsInf(c.AxialLength, 0) {
		return ErrInvalidConfig
	}
	for _, v := range []float64{c.RadialStart, c.Turns, c.Thickness, c.OpeningAngleDeg} {
		if math.IsNaN(v) || math.IsInf(v, 0) {
			return ErrInvalidConfig
		}
	}
	return nil
}

// RotorRadius is half the target outer diameter.
func (c Config) RotorRadius() float64 { return c.RotorDiameter / 2 }

// Anchor returns the fixed point on the rotor axis from which every
// generating line of the ruled blade surface starts. It is placed so that
// the generating line at the spiral's inner end (u=0) makes
// OpeningAngleDeg with the +Z rotor axis.
func (c Config) Anchor() Vec3 {
	r0 := c.RotorRadius() * c.RadialStart
	theta := c.OpeningAngleDeg * math.Pi / 180
	return Vec3{0, 0, -c.AxialLength/2 - r0/math.Tan(theta)}
}

// SpiralPoint evaluates one 3D Archimedean spiral on the blade's outer boundary.
// u is in radians. The projected radius grows linearly from innerRadius to outerRadius.
// z progresses linearly over AxialLength. Angle is measured in radians.
func (c Config) SpiralPoint(u float64) Vec3 {
	rMax := c.RotorDiameter / 2
	r0 := rMax * c.RadialStart
	b := (rMax - r0) / (2 * math.Pi * c.Turns)
	r := r0 + b*u
	z := -c.AxialLength/2 + c.AxialLength*u/(2*math.Pi*c.Turns)
	return Vec3{r * math.Cos(u), r * math.Sin(u), z}
}

// SpiralDerivative is dB/du at u.
func (c Config) SpiralDerivative(u float64) Vec3 {
	rMax := c.RotorRadius()
	r0 := rMax * c.RadialStart
	b := (rMax - r0) / (2 * math.Pi * c.Turns)
	span := 2 * math.Pi * c.Turns
	r := r0 + b*u
	dzdu := c.AxialLength / span
	return Vec3{
		b*math.Cos(u) - r*math.Sin(u),
		b*math.Sin(u) + r*math.Cos(u),
		dzdu,
	}
}

// SurfaceNormal returns the unit normal of the ruled surface at (u, v) for
// v > 0. Because the surface is ruled with a fixed anchor, the normal
// direction is independent of v; the value returned is also the limit used
// along the inner edge.
func (c Config) SurfaceNormal(u float64) Vec3 {
	generator := c.SpiralPoint(u).Sub(c.Anchor())
	return c.SpiralDerivative(u).Cross(generator).Normalized()
}

// SurfacePoint linearly interpolates from fixed anchor A to the spiral boundary B(u).
// This is a ruled surface family, S(u,v)=(1-v)A+vB(u). v is in [0,1].
// This simple model is intentionally exposed so alternative anchor/curve laws can be tested.
func (c Config) SurfacePoint(u, v float64, anchor Vec3) Vec3 {
	b := c.SpiralPoint(u)
	return anchor.Scale(1 - v).Add(b.Scale(v))
}

// BladeBoundarySamples samples the outer 3D spiral including both endpoints.
func (c Config) BladeBoundarySamples() []Vec3 {
	out := make([]Vec3, c.Samples+1)
	end := 2 * math.Pi * c.Turns
	for i := range out {
		out[i] = c.SpiralPoint(end * float64(i) / float64(c.Samples))
	}
	return out
}
