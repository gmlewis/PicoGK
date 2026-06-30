package picogkshapes

import (
	"math"

	"github.com/gmlewis/PicoGK/sdk/go/picogkffi"
)

// Sphere is a parametric sphere with optional radius modulation.
type Sphere struct {
	BaseShape
	frame     *LocalFrame
	radius    *SurfaceModulation
	azimSteps int
	polarSteps int
}

// NewSphere creates a sphere. radius can be a float64, func(phi,theta float64) float64,
// or *SurfaceModulation. Default azim=360, polar=180 (matching C# ShapeKernel).
func NewSphere(frame *LocalFrame, radius any, opts ...SphereOpt) *Sphere {
	s := &Sphere{
		frame:      frame,
		radius:     NewSurfaceModulation(radius),
		azimSteps:  360,
		polarSteps: 180,
	}
	if frame == nil {
		s.frame = NewLocalFrame(V(0, 0, 0))
	}
	for _, opt := range opts {
		opt(s)
	}
	return s
}

// SphereOpt configures a Sphere.
type SphereOpt func(*Sphere)

// SphereAzimSteps sets the azimuthal (theta) sampling resolution.
func SphereAzimSteps(n int) SphereOpt { return func(s *Sphere) { s.azimSteps = n } }

// SpherePolarSteps sets the polar (phi) sampling resolution.
func SpherePolarSteps(n int) SphereOpt { return func(s *Sphere) { s.polarSteps = n } }

// ToMesh builds the sphere mesh by sampling (theta, phi) on a grid.
func (s *Sphere) ToMesh() *picogkffi.Mesh {
	a := s.azimSteps
	p := s.polarSteps + 1
	grid := makeGrid(a, p)
	f := s.frame
	for i := 0; i < a; i++ {
		theta := math.Pi * float64(i) / float64(a-1)
		for j := 0; j < p; j++ {
			phi := 2 * math.Pi * (float64(j) - 1) / float64(s.polarSteps-1)
			r := s.radius.Call(phi, theta)
			x := r * math.Cos(phi) * math.Sin(theta)
			y := r * math.Sin(phi) * math.Sin(theta)
			z := r * math.Cos(theta)
			grid[i][j] = f.PointToWorld(V(x, y, z))
		}
	}
	grid = s.applyGridTransform(grid)
	return QuadGridToMesh(grid)
}

// ToVoxels builds a mesh and rasterizes it to voxels.
func (s *Sphere) ToVoxels() *picogkffi.Voxels {
	return ToVoxels(s.ToMesh())
}

// Box is a parametric box with optional width/depth modulations.
type Box struct {
	BaseShape
	frame   *LocalFrame
	length  float64
	width   *LineModulation
	depth   *LineModulation
	frames  *Frames
	wSteps  int
	dSteps  int
	lSteps  int
}

// NewBox creates a box. width and depth can be float64, func(lr float64) float64,
// or *LineModulation.
func NewBox(frame *LocalFrame, length, width, depth any, opts ...BoxOpt) *Box {
	b := &Box{
		frame:  frame,
		length: toFloat(length),
		width:  NewLineModulation(width),
		depth:  NewLineModulation(depth),
	}
	if frame == nil {
		b.frame = NewLocalFrame(V(0, 0, 0))
	}
	// Default steps: 5 for constant, 500 for modulated
	b.wSteps = 5
	b.dSteps = 5
	b.lSteps = 5
	for _, opt := range opts {
		opt(b)
	}
	return b
}

// BoxOpt configures a Box.
type BoxOpt func(*Box)

// BoxFrames sets the spine frames (replaces length).
func BoxFrames(fs *Frames) BoxOpt { return func(b *Box) { b.frames = fs; b.lSteps = 500 } }

// BoxWidthSteps sets the width tessellation.
func BoxWidthSteps(n int) BoxOpt { return func(b *Box) { b.wSteps = n } }

// BoxDepthSteps sets the depth tessellation.
func BoxDepthSteps(n int) BoxOpt { return func(b *Box) { b.dSteps = n } }

// BoxLengthSteps sets the length tessellation.
func BoxLengthSteps(n int) BoxOpt { return func(b *Box) { b.lSteps = n } }

// ToMesh builds the box mesh.
func (b *Box) ToMesh() *picogkffi.Mesh {
	smb := NewSurfaceMeshBuilder()
	nw, nd, nl := b.wSteps, b.dSteps, b.lSteps
	wRatios := arange(nw + 1) // -1 to 1
	dRatios := arange(nd + 1)
	lRatios := arange(nl + 1)
	for i := range wRatios {
		wRatios[i] = wRatios[i]*2 - 1 // [-1, 1]
	}
	for i := range dRatios {
		dRatios[i] = dRatios[i]*2 - 1
	}
	f := b.frame
	spine := func(lr float64) Vec3 {
		if b.frames != nil {
			return b.frames.FrameAt(lr).Pos
		}
		return f.Pos.Add(f.LocalZ.Mul(b.length * lr))
	}
	lx, ly := f.LocalX, f.LocalY
	if b.frames != nil {
		fr := b.frames.FrameAt(0)
		lx, ly = fr.LocalX, fr.LocalY
	}
	// Top face (lr=1, flip)
	smb.Add(b.boxSurface(wRatios, dRatios, []float64{1.0}, spine, lx, ly, b.width, b.depth, f), true)
	// Bottom face (lr=0, no flip)
	smb.Add(b.boxSurface(wRatios, dRatios, []float64{0.0}, spine, lx, ly, b.width, b.depth, f), false)
	// Front face (w=-1, flip)
	smb.Add(b.boxSurface([]float64{-1.0}, dRatios, lRatios, spine, lx, ly, b.width, b.depth, f), true)
	// Back face (w=1, no flip)
	smb.Add(b.boxSurface([]float64{1.0}, dRatios, lRatios, spine, lx, ly, b.width, b.depth, f), false)
	// Right face (d=1, flip)
	smb.Add(b.boxSurface(wRatios, []float64{1.0}, lRatios, spine, lx, ly, b.width, b.depth, f), true)
	// Left face (d=-1, no flip)
	smb.Add(b.boxSurface(wRatios, []float64{-1.0}, lRatios, spine, lx, ly, b.width, b.depth, f), false)
	return smb.Build()
}

func (b *Box) boxSurface(wR, dR, lR []float64, spine func(float64) Vec3, lx, ly Vec3, width, depth *LineModulation, f *LocalFrame) [][]Vec3 {
	nw, nd, nl := len(wR), len(dR), len(lR)
	grid := makeGrid(nw*nl, nd*nl)
	for i := 0; i < nw*nl; i++ {
		for j := 0; j < nd*nl; j++ {
			wi := i % nw
			li := i / nw
			di := j % nd
			// Actually we need the full grid — let me fix the indexing
			_ = wi; _ = li; _ = di
		}
	}
	// Simpler approach: build grid as (max(nw,nl), max(nd,nl))
	// Actually the Python code builds each face separately with different dimensions.
	// Let me match the Python approach more closely.
	// For a face with (wR, dR, lR), the grid is (len(wR)*len(lR), len(dR)*len(lR))
	// but actually it's more nuanced. Let me just build the surface grid directly.
	grid = makeGrid(max(len(wR), len(lR)), max(len(dR), len(lR)))
	for i := 0; i < len(grid); i++ {
		for j := 0; j < len(grid[0]); j++ {
			// Determine which ratio to use for each axis
			var wr, dr, lr float64
			if len(wR) > 1 {
				wr = wR[min(i, len(wR)-1)]
			} else if len(wR) == 1 {
				wr = wR[0]
			}
			if len(dR) > 1 {
				dr = dR[min(j, len(dR)-1)]
			} else if len(dR) == 1 {
				dr = dR[0]
			}
			if len(lR) > 1 {
				lr = lR[min(i, len(lR)-1)]
			} else if len(lR) == 1 {
				lr = lR[0]
			}
			sp := spine(lr)
			w := width.Call(lr) * 0.5 * wr
			d := depth.Call(lr) * 0.5 * dr
			grid[i][j] = sp.Add(lx.Mul(w)).Add(ly.Mul(d))
		}
	}
	grid = b.applyGridTransform(grid)
	return grid
}

func (b *Box) applyGridTransform(grid [][]Vec3) [][]Vec3 {
	if b.transform == nil {
		return grid
	}
	var pts []Vec3
	for _, row := range grid {
		pts = append(pts, row...)
	}
	pts = b.transform(pts)
	idx := 0
	for i := range grid {
		for j := range grid[i] {
			grid[i][j] = pts[idx]
			idx++
		}
	}
	return grid
}

func (s *Sphere) applyGridTransform(grid [][]Vec3) [][]Vec3 {
	if s.transform == nil {
		return grid
	}
	var pts []Vec3
	for _, row := range grid {
		pts = append(pts, row...)
	}
	pts = s.transform(pts)
	idx := 0
	for i := range grid {
		for j := range grid[i] {
			grid[i][j] = pts[idx]
			idx++
		}
	}
	return grid
}

// ToVoxels builds a mesh and rasterizes it to voxels.
func (b *Box) ToVoxels() *picogkffi.Voxels {
	return ToVoxels(b.ToMesh())
}

// Cylinder is a parametric cylinder with optional radius modulation.
type Cylinder struct {
	BaseShape
	frame      *LocalFrame
	length      float64
	radius     *SurfaceModulation
	frames     *Frames
	polarSteps int
	radialSteps int
	lengthSteps int
}

// NewCylinder creates a cylinder. radius can be float64, func(phi,lr float64) float64,
// or *SurfaceModulation.
func NewCylinder(frame *LocalFrame, length, radius any, opts ...CylinderOpt) *Cylinder {
	c := &Cylinder{
		frame:       frame,
		length:      toFloat(length),
		radius:      NewSurfaceModulation(radius),
		polarSteps:  360,
		radialSteps: 5,
		lengthSteps: 5,
	}
	if frame == nil {
		c.frame = NewLocalFrame(V(0, 0, 0))
	}
	for _, opt := range opts {
		opt(c)
	}
	return c
}

// CylinderOpt configures a Cylinder.
type CylinderOpt func(*Cylinder)

func CylinderFrames(fs *Frames) CylinderOpt      { return func(c *Cylinder) { c.frames = fs; c.lengthSteps = 500 } }
func CylinderPolarSteps(n int) CylinderOpt        { return func(c *Cylinder) { c.polarSteps = n } }
func CylinderRadialSteps(n int) CylinderOpt       { return func(c *Cylinder) { c.radialSteps = n } }
func CylinderLengthSteps(n int) CylinderOpt       { return func(c *Cylinder) { c.lengthSteps = n } }

func (c *Cylinder) ToMesh() *picogkffi.Mesh {
	smb := NewSurfaceMeshBuilder()
	nl := c.lengthSteps
	if nl < 2 {
		nl = 2
	}
	lRatios := arange(nl + 1) // [0, 1]
	spine := func(lr float64) Vec3 {
		if c.frames != nil {
			return c.frames.FrameAt(lr).Pos
		}
		return c.frame.Pos.Add(c.frame.LocalZ.Mul(c.length * lr))
	}
	lx, ly := c.frame.LocalX, c.frame.LocalY
	if c.frames != nil {
		fr := c.frames.FrameAt(0)
		lx, ly = fr.LocalX, fr.LocalY
	}
	// Top cap (lr=1, no flip)
	grid := makeGrid(c.polarSteps, c.radialSteps+1)
	for i := 0; i < c.polarSteps; i++ {
		phi := 2 * math.Pi * float64(i) / float64(c.polarSteps-1)
		for j := 0; j <= c.radialSteps; j++ {
			rr := float64(j) / float64(c.radialSteps)
			r := rr * c.radius.Call(phi, 1.0)
			grid[i][j] = spine(1.0).Add(lx.Mul(r * math.Cos(phi))).Add(ly.Mul(r * math.Sin(phi)))
		}
	}
	smb.Add(grid, false)
	// Bottom cap (lr=0, flip)
	grid = makeGrid(c.polarSteps, c.radialSteps+1)
	for i := 0; i < c.polarSteps; i++ {
		phi := 2 * math.Pi * float64(i) / float64(c.polarSteps-1)
		for j := 0; j <= c.radialSteps; j++ {
			rr := float64(j) / float64(c.radialSteps)
			r := rr * c.radius.Call(phi, 0.0)
			grid[i][j] = spine(0.0).Add(lx.Mul(r * math.Cos(phi))).Add(ly.Mul(r * math.Sin(phi)))
		}
	}
	smb.Add(grid, true)
	// Outer mantle (no flip)
	grid = makeGrid(c.polarSteps, nl+1)
	for i := 0; i < c.polarSteps; i++ {
		phi := 2 * math.Pi * float64(i) / float64(c.polarSteps-1)
		for j := 0; j <= nl; j++ {
			lr := lRatios[j]
			r := c.radius.Call(phi, lr)
			grid[i][j] = spine(lr).Add(lx.Mul(r * math.Cos(phi))).Add(ly.Mul(r * math.Sin(phi)))
		}
	}
	smb.Add(grid, true)
	return smb.Build()
}

func (c *Cylinder) ToVoxels() *picogkffi.Voxels {
	return ToVoxels(c.ToMesh())
}

// Cone is a cylinder with linearly varying radius.
type Cone struct {
	Cylinder
}

// NewCone creates a cone from start_radius to end_radius.
func NewCone(frame *LocalFrame, length, startRadius, endRadius float64, opts ...CylinderOpt) *Cone {
	linear := func(_, lr float64) float64 {
		return startRadius + clamp(lr, 0, 1) * (endRadius - startRadius)
	}
	c := &Cone{
		Cylinder: *NewCylinder(frame, length, linear, opts...),
	}
	return c
}

// Ring is a torus: a tube of radius swept around a circle of ring_radius.
type Ring struct {
	BaseShape
	frame       *LocalFrame
	ringRadius   float64
	radius      *SurfaceModulation
	radialSteps int
	polarSteps  int
}

// NewRing creates a ring (torus).
func NewRing(frame *LocalFrame, ringRadius, radius any, opts ...RingOpt) *Ring {
	r := &Ring{
		frame:       frame,
		ringRadius:  toFloat(ringRadius),
		radius:      NewSurfaceModulation(radius),
		radialSteps: 360,
		polarSteps:  360,
	}
	if frame == nil {
		r.frame = NewLocalFrame(V(0, 0, 0))
	}
	for _, opt := range opts {
		opt(r)
	}
	return r
}

// RingOpt configures a Ring.
type RingOpt func(*Ring)

func RingRadialSteps(n int) RingOpt { return func(r *Ring) { r.radialSteps = n } }
func RingPolarSteps(n int) RingOpt  { return func(r *Ring) { r.polarSteps = n } }

func (r *Ring) ToMesh() *picogkffi.Mesh {
	// Alpha grid wraps: first cell joins alpha=2π back to alpha=0
	nA := r.radialSteps + 1
	nP := r.polarSteps
	grid := makeGrid(nA, nP)
	f := r.frame
	for i := 0; i < nA; i++ {
		var a float64
		if i == 0 {
			a = 1.0
		} else {
			a = float64(i) / float64(r.radialSteps-1)
		}
		alpha := 2 * math.Pi * a
		// Spine circle point
		spine := f.Pos.Add(f.LocalX.Mul(r.ringRadius * math.Cos(alpha))).Add(f.LocalY.Mul(r.ringRadius * math.Sin(alpha)))
		// Local X at each station is the radial direction
		localX := SafeNormalized(spine.Sub(f.Pos))
		localY := f.LocalZ
		for j := 0; j < nP; j++ {
			phi := 2 * math.Pi * float64(j) / float64(nP-1)
			mod := r.radius.Call(phi, alpha)
			grid[i][j] = spine.Add(localX.Mul(mod * math.Cos(phi))).Add(localY.Mul(mod * math.Sin(phi)))
		}
	}
	grid = r.applyGridTransform(grid)
	smb := NewSurfaceMeshBuilder()
	smb.Add(grid, true)
	return smb.Build()
}

func (r *Ring) applyGridTransform(grid [][]Vec3) [][]Vec3 {
	if r.transform == nil {
		return grid
	}
	var pts []Vec3
	for _, row := range grid {
		pts = append(pts, row...)
	}
	pts = r.transform(pts)
	idx := 0
	for i := range grid {
		for j := range grid[i] {
			grid[i][j] = pts[idx]
			idx++
		}
	}
	return grid
}

func (r *Ring) ToVoxels() *picogkffi.Voxels {
	return ToVoxels(r.ToMesh())
}

// Helper functions

func toFloat(v any) float64 {
	switch x := v.(type) {
	case float64:
		return x
	case int:
		return float64(x)
	case int64:
		return float64(x)
	default:
		return 0
	}
}

func clamp(v, lo, hi float64) float64 {
	if v < lo {
		return lo
	}
	if v > hi {
		return hi
	}
	return v
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}