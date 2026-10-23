package main

import (
	"math"
	"testing"
)

func TestDefaultConfigValid(t *testing.T) {
	if err := defaultConfig().Validate(); err != nil {
		t.Fatalf("default config invalid: %v", err)
	}
}

func TestSpiralEndpoints(t *testing.T) {
	c := defaultConfig()
	root := c.SpiralPoint(0)
	apex := c.SpiralPoint(c.bladeSpan())
	if math.Abs(root.Z+c.AxialLength/2) > 1e-9 {
		t.Fatalf("root z=%g", root.Z)
	}
	if math.Abs(math.Hypot(root.X, root.Y)-c.RotorRadius()) > 1e-9 {
		t.Fatalf("root radius = %g, want %g", math.Hypot(root.X, root.Y), c.RotorRadius())
	}
	if math.Abs(apex.Z-c.AxialLength/2) > 1e-9 {
		t.Fatalf("apex z=%g", apex.Z)
	}
	wantApex := c.RotorRadius() * c.ApexRadius
	if math.Abs(math.Hypot(apex.X, apex.Y)-wantApex) > 1e-9 {
		t.Fatalf("apex radius = %g, want %g", math.Hypot(apex.X, apex.Y), wantApex)
	}
}

func TestSurfaceInterpolation(t *testing.T) {
	c := defaultConfig()
	u := 0.7
	if got, want := c.SurfacePoint(u, 0), c.AxisPoint(u); got != want {
		t.Fatalf("v=0: got %+v want %+v", got, want)
	}
	if got, want := c.SurfacePoint(u, 1), c.SpiralPoint(u); got != want {
		t.Fatalf("v=1: got %+v want %+v", got, want)
	}
	// The generating line must be radial: both ends share the same z.
	if a, b := c.SurfacePoint(u, 0), c.SurfacePoint(u, 1); math.Abs(a.Z-b.Z) > 1e-9 {
		t.Fatalf("generator not radial: z %g vs %g", a.Z, b.Z)
	}
}

func TestAxisPointOnRotorAxis(t *testing.T) {
	c := defaultConfig()
	for _, u := range []float64{0, 1, math.Pi, c.bladeSpan()} {
		p := c.AxisPoint(u)
		if p.X != 0 || p.Y != 0 {
			t.Fatalf("u=%g: axis point not on the Z axis: %+v", u, p)
		}
	}
}

func TestSamplesAndFinite(t *testing.T) {
	c := defaultConfig()
	pts := c.BladeBoundarySamples()
	if len(pts) != c.Samples+1 {
		t.Fatalf("got %d points", len(pts))
	}
	for i, p := range pts {
		if !p.Finite() {
			t.Fatalf("point %d not finite: %+v", i, p)
		}
	}
}

func TestBladeThicknessTapers(t *testing.T) {
	c := defaultConfig()
	if got, want := c.BaseThickness(), 4.0; got != want {
		t.Fatalf("base thickness = %g, want %g", got, want)
	}
	if got, want := c.TopThickness(), 2.0; got != want {
		t.Fatalf("top thickness = %g, want %g", got, want)
	}
	span := c.bladeSpan()
	if got, want := c.BladeThicknessAt(0), 4.0; got != want {
		t.Fatalf("thickness at base = %g, want %g", got, want)
	}
	if got, want := c.BladeThicknessAt(span), 2.0; got != want {
		t.Fatalf("thickness at top = %g, want %g", got, want)
	}
	if got, want := c.BladeThicknessAt(span/2), 3.0; got != want {
		t.Fatalf("thickness at mid-span = %g, want %g", got, want)
	}
	prev := math.Inf(1)
	for i := 0; i <= 20; i++ {
		got := c.BladeThicknessAt(span * float64(i) / 20)
		if got > prev {
			t.Fatalf("thickness increased from %g to %g at step %d", prev, got, i)
		}
		prev = got
	}
}

func TestAirfoilThicknessProfile(t *testing.T) {
	c := defaultConfig()
	if !c.Airfoil {
		t.Fatal("the default section should be an airfoil")
	}
	u := c.bladeSpan() * 0.4
	maxT := c.BladeThicknessAt(u)

	// The root carries the full peak thickness; the outer edge is a point.
	if got := c.BladeThicknessAtUV(u, 0); math.Abs(got-maxT) > 1e-12 {
		t.Fatalf("root thickness = %g, want the peak section thickness %g", got, maxT)
	}
	if got := c.BladeThicknessAtUV(u, 1); got != 0 {
		t.Fatalf("trailing-edge thickness = %g, want 0", got)
	}

	// The section must taper monotonically and never exceed the peak.
	prev := math.Inf(1)
	for i := 0; i <= 200; i++ {
		v := float64(i) / 200
		th := c.BladeThicknessAtUV(u, v)
		if th > prev+1e-12 {
			t.Fatalf("thickness increased at v=%g: %g after %g", v, th, prev)
		}
		if th < 0 || th > maxT+1e-12 {
			t.Fatalf("v=%g: thickness %g outside [0,%g]", v, th, maxT)
		}
		prev = th
	}

	// The aft-loaded NACA section should already be thin near the tip.
	if got := c.BladeThicknessAtUV(u, 0.9); got >= 0.25*maxT {
		t.Fatalf("v=0.9 thickness %g is not tapering to a point (peak %g)", got, maxT)
	}
}

func TestFlatBladeSection(t *testing.T) {
	c := defaultConfig()
	c.Airfoil = false
	u := c.bladeSpan() * 0.4
	want := c.BladeThicknessAt(u)
	for i := 0; i <= 10; i++ {
		v := float64(i) / 10
		if got := c.BladeThicknessAtUV(u, v); got != want {
			t.Fatalf("v=%g: flat thickness %g, want %g", v, got, want)
		}
		if got := c.BladeCamberAt(u, v); got != 0 {
			t.Fatalf("v=%g: flat camber %g, want 0", v, got)
		}
	}
}

func TestAirfoilCamber(t *testing.T) {
	c := defaultConfig()
	u := c.bladeSpan() * 0.4
	chord := c.ChordAt(u)
	if got := c.BladeCamberAt(u, 0); got != 0 {
		t.Fatalf("root camber = %g, want 0", got)
	}
	if got := c.BladeCamberAt(u, 1); got != 0 {
		t.Fatalf("trailing-edge camber = %g, want 0", got)
	}
	want := c.Camber * chord
	if got := c.BladeCamberAt(u, c.CamberPosition); math.Abs(got-want) > 1e-9 {
		t.Fatalf("peak camber = %g, want %g", got, want)
	}

	// Flipping the sign flips the bow.
	c.Camber = -c.Camber
	if got, want := c.BladeCamberAt(u, c.CamberPosition), -want; math.Abs(got-want) > 1e-9 {
		t.Fatalf("negative-camber peak = %g, want %g", got, want)
	}
}

func TestBladeSectionThickness(t *testing.T) {
	c := defaultConfig()
	for _, u := range []float64{0, c.bladeSpan() / 3, c.bladeSpan()} {
		for _, v := range []float64{0, 0.3, 0.8, 1} {
			top, bot, half := c.BladeSection(u, v)
			want := c.BladeThicknessAtUV(u, v)
			if got := top.Sub(bot).Norm(); math.Abs(got-want) > 1e-9 {
				t.Fatalf("u=%g v=%g: section thickness %g, want %g", u, v, got, want)
			}
			if got := 2 * half; got != want {
				t.Fatalf("u=%g v=%g: half-thickness %g, want %g", u, v, got, want)
			}
		}
	}
}

func TestTrailingEdgeThickness(t *testing.T) {
	c := defaultConfig()
	c.TrailingEdgeMM = 0.4
	if err := c.Validate(); err != nil {
		t.Fatal(err)
	}
	u := c.bladeSpan() * 0.4
	if got, want := c.BladeThicknessAtUV(u, 1), 0.4; math.Abs(got-want) > 1e-12 {
		t.Fatalf("trailing-edge thickness = %g, want %g", got, want)
	}
}

func TestThicknessFloors(t *testing.T) {
	c := defaultConfig()
	c.Thickness = 5
	if got := c.BaseThickness(); got != 5 {
		t.Errorf("base thickness = %g, want the 5 mm floor", got)
	}
	if got := c.TopThickness(); got != 5 {
		t.Errorf("top thickness = %g, want the 5 mm floor", got)
	}

	c = defaultConfig()
	c.Thickness = 3
	if got := c.BaseThickness(); got != 4 {
		t.Errorf("base thickness = %g, want 4", got)
	}
	if got := c.TopThickness(); got != 3 {
		t.Errorf("top thickness = %g, want the 3 mm floor", got)
	}
}

func TestBaseExtensionIsSmooth(t *testing.T) {
	c := defaultConfig()
	start := c.baseStart()
	if start >= 0 {
		t.Fatalf("base extension start = %g, want negative", start)
	}
	if got := c.BladeThicknessAt(0); got != c.BaseThickness() {
		t.Fatalf("thickness at the base = %g, want %g", got, c.BaseThickness())
	}
	// The same linear law must hold on both sides of u=0: no jump and no
	// slope change, so the surfaces are smooth, not an added lead-in.
	const du = 1e-4
	slopeAbove := (c.BladeThicknessAt(du) - c.BladeThicknessAt(0)) / du
	slopeBelow := (c.BladeThicknessAt(0) - c.BladeThicknessAt(-du)) / du
	if math.Abs(slopeAbove-slopeBelow) > 1e-6 {
		t.Fatalf("thickness slope jumps at the base: %g vs %g", slopeAbove, slopeBelow)
	}
	if math.Abs(c.BladeThicknessAt(du)-c.BladeThicknessAt(-du)) > 1e-3 {
		t.Fatalf("thickness jumps at the base: %g vs %g",
			c.BladeThicknessAt(-du), c.BladeThicknessAt(du))
	}
	// The extension must carry the whole blade below the bed plane so the bed
	// can cut both sheets flat.
	lead := c.SpiralPoint(start)
	if lead.Z >= c.BedZ() {
		t.Fatalf("extension start z=%g is not below the bed z=%g", lead.Z, c.BedZ())
	}
	// The flat contact at v=0 is exactly the local peak section thickness,
	// because the airfoil keeps full thickness at the root. It is never below
	// -minBaseThickness.
	if got, want := c.BladeThicknessAtUV(0, 0), c.BladeThicknessAt(0); math.Abs(got-want) > 1e-12 {
		t.Fatalf("root section thickness %g, want the local peak %g", got, want)
	}
	if got := c.BladeThicknessAt(0); got < c.MinBaseThickness {
		t.Fatalf("base contact width %g is below minBaseThickness %g", got, c.MinBaseThickness)
	}
}

func TestRejectInvalidConfig(t *testing.T) {
	c := defaultConfig()
	c.BladeCount = 0
	if c.Validate() == nil {
		t.Fatal("expected invalid config")
	}
	c = defaultConfig()
	c.ApexRadius = 1
	if c.Validate() == nil {
		t.Fatal("expected an apex radius of 1 to be rejected")
	}
	c = defaultConfig()
	c.ApexRadius = 0
	if c.Validate() == nil {
		t.Fatal("expected a zero apex radius to be rejected")
	}
	c = defaultConfig()
	c.MinBaseThickness = 0
	if c.Validate() == nil {
		t.Fatal("expected a zero minimum base thickness to be rejected")
	}
	c = defaultConfig()
	c.MinTopThickness = -1
	if c.Validate() == nil {
		t.Fatal("expected a negative minimum top thickness to be rejected")
	}
	c = defaultConfig()
	c.BaseExtensionDeg = -1
	if c.Validate() == nil {
		t.Fatal("expected a negative base extension to be rejected")
	}
	c = defaultConfig()
	c.BaseExtensionDeg = 360 / float64(c.BladeCount)
	if c.Validate() == nil {
		t.Fatal("expected a base extension reaching the next blade to be rejected")
	}
	c = defaultConfig()
	c.CamberPosition = 0
	if c.Validate() == nil {
		t.Fatal("expected a zero camber position to be rejected")
	}
	c = defaultConfig()
	c.CamberPosition = 1
	if c.Validate() == nil {
		t.Fatal("expected a camber position of 1 to be rejected")
	}
	c = defaultConfig()
	c.Camber = 0.2
	if c.Validate() == nil {
		t.Fatal("expected excessive camber to be rejected")
	}
	c = defaultConfig()
	c.TrailingEdgeMM = -0.1
	if c.Validate() == nil {
		t.Fatal("expected a negative trailing-edge thickness to be rejected")
	}
	c = defaultConfig()
	c.TrailingEdgeMM = c.MinBladeThickness()
	if c.Validate() == nil {
		t.Fatal("expected a trailing edge as thick as the section to be rejected")
	}
}
