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
}
