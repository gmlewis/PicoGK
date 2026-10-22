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
	a := c.SpiralPoint(0)
	b := c.SpiralPoint(2 * math.Pi * c.Turns)
	if math.Abs(a.Z+c.AxialLength/2) > 1e-9 {
		t.Fatalf("start z=%g", a.Z)
	}
	if math.Abs(b.Z-c.AxialLength/2) > 1e-9 {
		t.Fatalf("end z=%g", b.Z)
	}
	if math.Abs(math.Hypot(b.X, b.Y)-c.RotorDiameter/2) > 1e-9 {
		t.Fatalf("outer radius mismatch")
	}
}

func TestSurfaceInterpolation(t *testing.T) {
	c := defaultConfig()
	anchor := Vec3{1, 2, 3}
	u := 0.7
	if got := c.SurfacePoint(u, 0, anchor); got != anchor {
		t.Fatalf("v=0: got %+v", got)
	}
	if got, want := c.SurfacePoint(u, 1, anchor), c.SpiralPoint(u); got != want {
		t.Fatalf("v=1: got %+v want %+v", got, want)
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
}
