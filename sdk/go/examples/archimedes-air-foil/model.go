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
	Thickness     float64 // peak section thickness floor, measured normal to the ruled surface
	// MinBaseThickness and MinTopThickness set the peak blade-section
	// thickness at the wide base and the narrow top. The section peaks at the
	// root (v=0) and tapers toward the outer edge, so its peak at either end
	// is never below the corresponding setting.
	MinBaseThickness float64
	MinTopThickness  float64
	// BaseExtensionDeg continues each blade below the nominal base by this
	// many degrees of the same spiral. The surfaces stay smooth, and the
	// print bed then cuts the extended solid flat.
	BaseExtensionDeg float64

	// Airfoil selects an airfoil-style blade section. When false the blade is
	// the original constant-thickness sheet.
	Airfoil bool
	// Camber is the peak camber of the blade section as a fraction of the
	// local chord. Positive camber bows the mid-surface toward the +normal
	// ("top") side. Zero gives a symmetric section.
	Camber float64
	// CamberPosition is the chord fraction of maximum camber, following the
	// NACA 4-digit convention (0 < CamberPosition < 1).
	CamberPosition float64
	// TrailingEdgeMM is a finite trailing-edge thickness. Zero gives a
	// mathematically sharp point, which the voxelizer rounds off.
	TrailingEdgeMM float64
}

// defaultConfig returns the user-selected envelope and conservative starting sampling.
func defaultConfig() Config {
	return Config{
		RotorDiameter: 150, AxialLength: 140, BladeCount: 3,
		Samples: 240, ApexRadius: 0.05, Turns: 1,
		Thickness: 1.2, MinBaseThickness: 4.0, MinTopThickness: 2.0,
		// A little past the ~5 deg needed to carry the thickest sheet below
		// the bed at the default base thickness.
		BaseExtensionDeg: 10,
		// A NACA-style section with the thickness peak at the root and a sharp
		// trailing edge at the outer radius. 2% camber is a gentle starting
		// point; flip its sign to reverse the section.
		Airfoil: true, Camber: 0.02, CamberPosition: 0.4, TrailingEdgeMM: 0,
	}
}

func (c Config) Validate() error {
	if c.RotorDiameter <= 0 || c.AxialLength <= 0 || c.BladeCount < 1 ||
		c.Samples < 8 || c.ApexRadius <= 0 || c.ApexRadius >= 1 ||
		c.Turns <= 0 || c.Thickness <= 0 ||
		c.MinBaseThickness <= 0 || c.MinTopThickness <= 0 ||
		c.BaseExtensionDeg < 0 || c.BaseExtensionDeg >= 360/float64(c.BladeCount) {
		return ErrInvalidConfig
	}
	if c.Airfoil && (c.CamberPosition <= 0 || c.CamberPosition >= 1 ||
		math.Abs(c.Camber) > 0.15 ||
		c.TrailingEdgeMM < 0 || c.TrailingEdgeMM >= c.MinBladeThickness()) {
		return ErrInvalidConfig
	}
	for _, v := range []float64{c.RotorDiameter, c.AxialLength, c.ApexRadius, c.Turns,
		c.Thickness, c.MinBaseThickness, c.MinTopThickness, c.BaseExtensionDeg,
		c.Camber, c.CamberPosition, c.TrailingEdgeMM} {
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

// BaseThickness is the peak section thickness at the wide base (u=0): the
// larger of the peak Thickness floor and MinBaseThickness.
func (c Config) BaseThickness() float64 { return math.Max(c.Thickness, c.MinBaseThickness) }

// TopThickness is the peak section thickness at the narrow top
// (u=bladeSpan): the larger of the peak Thickness floor and MinTopThickness.
func (c Config) TopThickness() float64 { return math.Max(c.Thickness, c.MinTopThickness) }

// baseStart is the spiral parameter at the bottom end of the base extension.
func (c Config) baseStart() float64 { return -c.BaseExtensionDeg * math.Pi / 180 }

// BedZ is the print-bed plane. The solid extends smoothly below it and is cut
// flat by this plane, giving each blade a substantial flat footprint.
func (c Config) BedZ() float64 { return -c.AxialLength / 2 }

// BladeThicknessAt returns the local peak blade-section thickness at spiral
// parameter u. In airfoil mode this is the thickness at the root (v=0), where
// the NACA thickness distribution peaks. The same linear law is used
// everywhere, including the base extension (u < 0), so the section peak is
// smooth all the way past the bed: there is no added lead-in and no kink at
// u=0.
func (c Config) BladeThicknessAt(u float64) float64 {
	s := u / c.bladeSpan()
	if s > 1 {
		s = 1
	}
	return c.BaseThickness() + (c.TopThickness()-c.BaseThickness())*s
}

// airfoilRootX is where the blade root (v=0) sits on the NACA chord. 0.3 is
// the point of maximum thickness, so the root is exactly as thick as
// BladeThicknessAt(u) and the section tapers monotonically from there to a
// sharp trailing edge at the outer edge (v=1).
const airfoilRootX = 0.3

// nacaHalfThickness is the NACA 4-digit half-thickness distribution with a
// closed trailing edge, in units of the chord. Its peak is at x=0.3.
func nacaHalfThickness(x float64) float64 {
	if x <= 0 || x >= 1 {
		return 0
	}
	return 0.2969*math.Sqrt(x) - 0.1260*x - 0.3516*x*x +
		0.2843*x*x*x - 0.1036*x*x*x*x
}

// airfoilThicknessFraction returns the fraction of the peak section thickness
// at chord fraction v. The blade uses the aft part of the NACA distribution,
// from the thickness peak at the root to the closed trailing edge at the
// outer edge. The result is 1 at v=0, 0 at v=1, and monotonically decreasing.
// A finite TrailingEdgeMM blends the last part of the section to a flat edge.
func (c Config) airfoilThicknessFraction(v, maxThickness float64) float64 {
	var f float64
	switch {
	case v <= 0:
		f = 1
	case v >= 1:
		f = 0
	default:
		x := airfoilRootX + (1-airfoilRootX)*v
		f = nacaHalfThickness(x) / nacaHalfThickness(airfoilRootX)
	}
	if c.TrailingEdgeMM > 0 && maxThickness > 0 {
		teFrac := c.TrailingEdgeMM / maxThickness
		if teFrac > 1 {
			teFrac = 1
		}
		const blendStart = 0.85
		if v > blendStart {
			t := (v - blendStart) / (1 - blendStart)
			f = f*(1-t) + teFrac*t
		}
	}
	if f < 0 {
		f = 0
	} else if f > 1 {
		f = 1
	}
	return f
}

// BladeThicknessAtUV returns the full section thickness at spiral parameter u
// and chord fraction v (0 at the root, 1 at the outer edge). In airfoil mode
// the local peak thickness BladeThicknessAt(u) is distributed along v with the
// NACA-style profile: full thickness at the root and a sharp point at the
// outer edge. In flat mode the sheet keeps the same thickness for every v.
func (c Config) BladeThicknessAtUV(u, v float64) float64 {
	maxT := c.BladeThicknessAt(u)
	if !c.Airfoil {
		return maxT
	}
	return maxT * c.airfoilThicknessFraction(v, maxT)
}

// nacaCamberShape is the NACA 4-digit camber line normalized to a peak of 1.
// x is the chord fraction and p the position of maximum camber. It is zero at
// both x=0 and x=1.
func nacaCamberShape(x, p float64) float64 {
	if x <= 0 || x >= 1 {
		return 0
	}
	if x < p {
		return (2*p*x - x*x) / (p * p)
	}
	return ((1 - 2*p) + 2*p*x - x*x) / ((1 - p) * (1 - p))
}

// ChordAt is the length of the generating line at spiral parameter u, i.e. the
// local distance from the rotor axis to the outer spiral.
func (c Config) ChordAt(u float64) float64 {
	return c.SpiralPoint(u).Sub(c.AxisPoint(u)).Norm()
}

// BladeCamberAt returns the signed offset in millimetres of the blade
// section's mid-surface from the base helicoid. It is measured along
// SurfaceNormal, so positive camber bows the section toward the +normal
// ("top") sheet. The camber is zero in flat mode and at both the root and the
// outer edge.
func (c Config) BladeCamberAt(u, v float64) float64 {
	if !c.Airfoil || c.Camber == 0 {
		return 0
	}
	return c.ChordAt(u) * c.Camber * nacaCamberShape(v, c.CamberPosition)
}

// BladeSection returns the two surface points of the blade section at (u,v),
// offset from the cambered mid-surface by half the local thickness along
// SurfaceNormal. At the sharp trailing edge the thickness is zero and the two
// points coincide.
func (c Config) BladeSection(u, v float64) (top, bot Vec3, halfThickness float64) {
	p := c.SurfacePoint(u, v)
	n := c.SurfaceNormal(u, v)
	mid := p.Add(n.Scale(c.BladeCamberAt(u, v)))
	halfThickness = c.BladeThicknessAtUV(u, v) / 2
	return mid.Add(n.Scale(halfThickness)), mid.Sub(n.Scale(halfThickness)), halfThickness
}

// bladeStations returns the spiral parameters sampled along one blade: the
// base extension followed by the main spiral. It samples u=0 exactly so the
// bed plane and the nominal base are represented.
func (c Config) bladeStations() []float64 {
	uMax := c.bladeSpan()
	start := c.baseStart()
	us := make([]float64, 0, c.Samples+1)
	if start < 0 {
		nr := c.Samples / 20
		if nr < 4 {
			nr = 4
		}
		for i := 0; i < nr; i++ {
			us = append(us, start+(-start)*float64(i)/float64(nr))
		}
	}
	for i := 0; i <= c.Samples; i++ {
		us = append(us, uMax*float64(i)/float64(c.Samples))
	}
	return us
}

// MinBladeThickness is the thinnest point of the tapered blade.
func (c Config) MinBladeThickness() float64 { return math.Min(c.BaseThickness(), c.TopThickness()) }

// MaxBladeThickness is the thickest point of the tapered blade, including the
// base extension where the linear taper continues past the base.
func (c Config) MaxBladeThickness() float64 {
	return math.Max(math.Max(c.BaseThickness(), c.TopThickness()), c.BladeThicknessAt(c.baseStart()))
}

// MaxSectionOffset bounds the distance from the base helicoid to either blade
// surface, including camber and half the local section thickness. It is used
// to bound the rotor mesh.
func (c Config) MaxSectionOffset() float64 {
	maxChord := c.RotorRadius()
	if s := c.baseStart(); s < 0 {
		if r := c.ChordAt(s); r > maxChord {
			maxChord = r
		}
	}
	maxCamber := 0.0
	if c.Airfoil {
		maxCamber = math.Abs(c.Camber) * maxChord
	}
	return c.MaxBladeThickness()/2 + maxCamber
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

// BladeBoundarySamples samples the outer 3D spiral from the start of the base
// extension to the top, including both endpoints.
func (c Config) BladeBoundarySamples() []Vec3 {
	out := make([]Vec3, c.Samples+1)
	start := c.baseStart()
	end := c.bladeSpan()
	for i := range out {
		out[i] = c.SpiralPoint(start + (end-start)*float64(i)/float64(c.Samples))
	}
	return out
}
