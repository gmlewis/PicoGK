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
	Thickness       float64 // intended wall/skin thickness; mesh solidification is a later step
	OpeningAngleDeg float64 // angle between generating line and rotor axis, design parameter
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
		c.OpeningAngleDeg <= 0 || c.OpeningAngleDeg >= 180 {
		return ErrInvalidConfig
	}
	if math.IsNaN(c.RotorDiameter) || math.IsNaN(c.AxialLength) ||
		math.IsInf(c.RotorDiameter, 0) || math.IsInf(c.AxialLength, 0) {
		return ErrInvalidConfig
	}
	return nil
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
