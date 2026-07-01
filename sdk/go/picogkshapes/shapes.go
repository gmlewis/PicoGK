package picogkshapes

import (
	"math"

	"github.com/gmlewis/PicoGK/sdk/go/picogkffi"
)

// Sphere is a parametric sphere with optional radius modulation.
type Sphere struct {
	BaseShape
	frame      *LocalFrame
	radius     *SurfaceModulation
	azimSteps  int
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
	for i := range a {
		theta := math.Pi * float64(i) / float64(a-1)
		for j := range p {
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
	frame  *LocalFrame
	length float64
	width  *LineModulation
	depth  *LineModulation
	frames *Frames
	wSteps int
	dSteps int
	lSteps int
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
// Matches the Python picogk.shapes.box.Box.to_mesh exactly:
// 6 faces, each a 2D grid via NumPy-style broadcasting of (wr, dr, lr).
func (b *Box) ToMesh() *picogkffi.Mesh {
	nw, nd, nl := b.wSteps, b.dSteps, b.lSteps
	// w: -1..1, d: -1..1, lr: 0..1
	w := make([]float64, nw)
	for i := range nw {
		w[i] = 2.0*float64(i)/float64(nw-1) - 1.0
	}
	d := make([]float64, nd)
	for i := range nd {
		d[i] = 2.0*float64(i)/float64(nd-1) - 1.0
	}
	lr := make([]float64, nl)
	for i := range nl {
		lr[i] = float64(i) / float64(nl-1)
	}

	smb := NewSurfaceMeshBuilder()
	// Top face: grid (nw, nd), w varies on axis0, d on axis1, lr=last
	smb.Add(b.boxSurfaceGrid(w, d, []float64{lr[nl-1]}), true)
	// Bottom face: grid (nw, nd)
	smb.Add(b.boxSurfaceGrid(w, d, []float64{lr[0]}), false)
	// Front face (w=-1): grid (nl, nd), lr varies on axis0, d on axis1, w=first
	smb.Add(b.boxSurfaceGrid([]float64{w[0]}, d, lr), true)
	// Back face (w=+1): grid (nl, nd)
	smb.Add(b.boxSurfaceGrid([]float64{w[nw-1]}, d, lr), false)
	// Right face (d=+1): grid (nl, nw), lr varies on axis0, w on axis1, d=last
	smb.Add(b.boxSurfaceGrid(w, []float64{d[nd-1]}, lr), true)
	// Left face (d=-1): grid (nl, nw)
	smb.Add(b.boxSurfaceGrid(w, []float64{d[0]}, lr), false)
	return smb.Build()
}

// boxSurfaceGrid builds a 2D grid by broadcasting (wr, dr, lr) arrays.
// The grid dimensions are (max(len(wr),len(lr)), max(len(dr),len(lr)))
// following NumPy broadcasting rules: scalars (len==1) are broadcast,
// arrays with len>1 define that axis.
// If lr has len>1, it varies on axis0. If wr has len>1 and lr has len==1,
// wr varies on axis0. dr with len>1 varies on axis1.
func (b *Box) boxSurfaceGrid(wR, dR, lR []float64) [][]Vec3 {
	// Determine grid shape via broadcasting
	r0 := 1
	r1 := 1
	if len(lR) > 1 {
		r0 = len(lR)
	} else if len(wR) > 1 {
		r0 = len(wR)
	}
	if len(dR) > 1 {
		r1 = len(dR)
	} else if len(wR) > 1 && len(lR) > 1 {
		// w varies on axis1
		r1 = len(wR)
	}
	// Fix: when both lr>1 and wr>1, lr is axis0 and wr is axis1
	if len(lR) > 1 && len(wR) > 1 {
		r0 = len(lR)
		r1 = len(wR)
	}
	if len(lR) > 1 && len(dR) > 1 {
		r0 = len(lR)
		r1 = len(dR)
	}
	if len(wR) > 1 && len(dR) > 1 {
		// top/bottom: w is axis0, d is axis1
		r0 = len(wR)
		r1 = len(dR)
	}

	grid := makeGrid(r0, r1)
	for i := range r0 {
		for j := range r1 {
			// Pick the right ratio for each axis
			var wr, dr, lrVal float64
			if len(wR) == 1 {
				wr = wR[0]
			} else if len(lR) == 1 {
				// w varies on axis0
				wr = wR[min(i, len(wR)-1)]
			} else {
				// w varies on axis1
				wr = wR[min(j, len(wR)-1)]
			}
			if len(dR) == 1 {
				dr = dR[0]
			} else {
				dr = dR[min(j, len(dR)-1)]
			}
			if len(lR) == 1 {
				lrVal = lR[0]
			} else {
				lrVal = lR[min(i, len(lR)-1)]
			}

			// Get spine position and local axes at lr
			sp, lx, ly := b.boxSpine(lrVal)
			wm := b.width.Call(lrVal) * 0.5 * wr
			dm := b.depth.Call(lrVal) * 0.5 * dr
			grid[i][j] = sp.Add(lx.Mul(wm)).Add(ly.Mul(dm))
		}
	}
	grid = b.applyGridTransform(grid)
	return grid
}

// boxSpine returns the spine position and local axes at the given length ratio.
func (b *Box) boxSpine(lr float64) (Vec3, Vec3, Vec3) {
	if b.frames != nil {
		fr := b.frames.FrameAt(lr)
		return fr.Pos, fr.LocalX, fr.LocalY
	}
	pos := b.frame.Pos.Add(b.frame.LocalZ.Mul(b.length * lr))
	return pos, b.frame.LocalX, b.frame.LocalY
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
	frame       *LocalFrame
	length      float64
	radius      *SurfaceModulation
	frames      *Frames
	polarSteps  int
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

func CylinderFrames(fs *Frames) CylinderOpt {
	return func(c *Cylinder) { c.frames = fs; c.lengthSteps = 500 }
}
func CylinderPolarSteps(n int) CylinderOpt  { return func(c *Cylinder) { c.polarSteps = n } }
func CylinderRadialSteps(n int) CylinderOpt { return func(c *Cylinder) { c.radialSteps = n } }
func CylinderLengthSteps(n int) CylinderOpt { return func(c *Cylinder) { c.lengthSteps = n } }

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
	for i := range c.polarSteps {
		phi := 2 * math.Pi * float64(i) / float64(c.polarSteps-1)
		for j := range c.radialSteps + 1 {
			rr := float64(j) / float64(c.radialSteps)
			r := rr * c.radius.Call(phi, 1.0)
			grid[i][j] = spine(1.0).Add(lx.Mul(r * math.Cos(phi))).Add(ly.Mul(r * math.Sin(phi)))
		}
	}
	smb.Add(grid, false)
	// Bottom cap (lr=0, flip)
	grid = makeGrid(c.polarSteps, c.radialSteps+1)
	for i := range c.polarSteps {
		phi := 2 * math.Pi * float64(i) / float64(c.polarSteps-1)
		for j := range c.radialSteps + 1 {
			rr := float64(j) / float64(c.radialSteps)
			r := rr * c.radius.Call(phi, 0.0)
			grid[i][j] = spine(0.0).Add(lx.Mul(r * math.Cos(phi))).Add(ly.Mul(r * math.Sin(phi)))
		}
	}
	smb.Add(grid, true)
	// Outer mantle (no flip)
	grid = makeGrid(c.polarSteps, nl+1)
	for i := range c.polarSteps {
		phi := 2 * math.Pi * float64(i) / float64(c.polarSteps-1)
		for j := range nl + 1 {
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
		return startRadius + clamp(lr, 0, 1)*(endRadius-startRadius)
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
	ringRadius  float64
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
	for i := range nA {
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
		for j := range nP {
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

func (r *Ring) ToVoxels() *picogkffi.Voxels {
	return ToVoxels(r.ToMesh())
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

// Lens is a disc/annulus between inner and outer radius with modulated height.
type Lens struct {
	BaseShape
	frame       *LocalFrame
	height      float64
	innerRadius float64
	outerRadius float64
	lower       *SurfaceModulation
	upper       *SurfaceModulation
	radialSteps int
	polarSteps  int
	heightSteps int
}

// NewLens creates a lens. lower and upper are SurfaceModulation(phi, radius_ratio).
func NewLens(frame *LocalFrame, height, innerRadius, outerRadius float64, opts ...LensOpt) *Lens {
	l := &Lens{
		frame:       frame,
		height:      height,
		innerRadius: innerRadius,
		outerRadius: outerRadius,
		lower:       NewSurfaceModulation(0.0),
		upper:       NewSurfaceModulation(height),
		radialSteps: 5,
		polarSteps:  360,
		heightSteps: 5,
	}
	if frame == nil {
		l.frame = NewLocalFrame(V(0, 0, 0))
	}
	for _, opt := range opts {
		opt(l)
	}
	return l
}

// LensOpt configures a Lens.
type LensOpt func(*Lens)

func LensLower(m *SurfaceModulation) LensOpt {
	return func(l *Lens) { l.lower = m; l.radialSteps = 500 }
}
func LensUpper(m *SurfaceModulation) LensOpt {
	return func(l *Lens) { l.upper = m; l.radialSteps = 500 }
}
func LensRadialSteps(n int) LensOpt { return func(l *Lens) { l.radialSteps = n } }
func LensPolarSteps(n int) LensOpt  { return func(l *Lens) { l.polarSteps = n } }
func LensHeightSteps(n int) LensOpt { return func(l *Lens) { l.heightSteps = n } }

func (l *Lens) lensSurface(h float64, phiR, radR []float64) [][]Vec3 {
	nphi := len(phiR)
	nrad := len(radR)
	grid := makeGrid(nphi, nrad)
	f := l.frame
	for i := range nphi {
		phi := 2 * math.Pi * phiR[i]
		for j := range nrad {
			radius := (l.outerRadius-l.innerRadius)*radR[j] + l.innerRadius
			lower := l.lower.Call(phi, radR[j])
			upper := l.upper.Call(phi, radR[j])
			z := lower + h*(upper-lower)
			grid[i][j] = f.Pos.
				Add(f.LocalX.Mul(radius * math.Cos(phi))).
				Add(f.LocalY.Mul(radius * math.Sin(phi))).
				Add(f.LocalZ.Mul(z))
		}
	}
	return grid
}

func (l *Lens) ToMesh() *picogkffi.Mesh {
	smb := NewSurfaceMeshBuilder()
	p := arange(l.polarSteps)
	rr := arange(l.radialSteps)
	hr := arange(l.heightSteps)
	// top (h=1, no flip)
	smb.Add(l.lensSurface(1.0, p, rr), false)
	// bottom (h=0, flip)
	smb.Add(l.lensSurface(0.0, p, rr), true)
	// inner mantle (radR=0, no flip)
	smb.Add(l.lensMantleSurface(hr, p, 0.0), false)
	// outer mantle (radR=1, flip)
	smb.Add(l.lensMantleSurface(hr, p, 1.0), true)
	return smb.Build()
}

func (l *Lens) lensMantleSurface(hr, p []float64, radR float64) [][]Vec3 {
	nh := len(hr)
	np := len(p)
	grid := makeGrid(nh, np)
	f := l.frame
	for i := range nh {
		for j := range np {
			phi := 2 * math.Pi * p[j]
			radius := (l.outerRadius-l.innerRadius)*radR + l.innerRadius
			lower := l.lower.Call(phi, radR)
			upper := l.upper.Call(phi, radR)
			z := lower + hr[i]*(upper-lower)
			grid[i][j] = f.Pos.
				Add(f.LocalX.Mul(radius * math.Cos(phi))).
				Add(f.LocalY.Mul(radius * math.Sin(phi))).
				Add(f.LocalZ.Mul(z))
		}
	}
	return grid
}

func (l *Lens) ToVoxels() *picogkffi.Voxels {
	return ToVoxels(l.ToMesh())
}

// Pipe is a hollow tube with inner/outer radius over a length-spine.
type Pipe struct {
	BaseShape
	frame       *LocalFrame
	length      float64
	inner       *SurfaceModulation
	outer       *SurfaceModulation
	frames      *Frames
	polarSteps  int
	radialSteps int
	lengthSteps int
	// phiAngleFunc is the angle function for this pipe.
	// Pipe uses 2*pi*phiRatio; PipeSegment overrides with mid+(phiRatio-0.5)*range.
	phiAngleFunc func(phiRatio, lr float64) float64
}

// NewPipe creates a pipe. innerRadius/outerRadius can be float64 or func(phi,lr float64) float64.
func NewPipe(frame *LocalFrame, length, innerRadius, outerRadius any, opts ...PipeOpt) *Pipe {
	p := &Pipe{
		frame:        frame,
		length:       toFloat(length),
		inner:        NewSurfaceModulation(innerRadius),
		outer:        NewSurfaceModulation(outerRadius),
		polarSteps:   360,
		radialSteps:  5,
		lengthSteps:  5,
		phiAngleFunc: func(phiRatio, lr float64) float64 { return 2 * math.Pi * phiRatio },
	}
	if frame == nil {
		p.frame = NewLocalFrame(V(0, 0, 0))
	}
	// Check if radii are constant — if not, or if there's a spine/transform,
	// bump lengthSteps to 500 (matching Python's C# ShapeKernel behavior).
	innerConst := isConstant(innerRadius)
	outerConst := isConstant(outerRadius)
	if !innerConst || !outerConst {
		p.lengthSteps = 500
	}
	for _, opt := range opts {
		opt(p)
	}
	// If a spine or transform was set via opts, also bump lengthSteps
	if (p.frames != nil || p.transform != nil) && p.lengthSteps < 500 {
		p.lengthSteps = 500
	}
	return p
}

// PipeOpt configures a Pipe.
type PipeOpt func(*Pipe)

func PipeFrames(fs *Frames) PipeOpt           { return func(p *Pipe) { p.frames = fs; p.lengthSteps = 500 } }
func PipePolarSteps(n int) PipeOpt            { return func(p *Pipe) { p.polarSteps = n } }
func PipeRadialSteps(n int) PipeOpt           { return func(p *Pipe) { p.radialSteps = n } }
func PipeLengthSteps(n int) PipeOpt           { return func(p *Pipe) { p.lengthSteps = n } }
func PipeTransform(t VertexTransform) PipeOpt { return func(p *Pipe) { p.transform = t } }

func (p *Pipe) pipeSpine(lr float64) (Vec3, Vec3, Vec3) {
	if p.frames != nil {
		fr := p.frames.FrameAt(lr)
		return fr.Pos, fr.LocalX, fr.LocalY
	}
	pos := p.frame.Pos.Add(p.frame.LocalZ.Mul(p.length * lr))
	return pos, p.frame.LocalX, p.frame.LocalY
}

func (p *Pipe) pipeSurface(lrs, phiRs, radRs []float64) [][]Vec3 {
	// Match Python's NumPy broadcasting exactly:
	// Top/bottom cap: _surface(lr_scalar, p[:,None], rr[None,:]) → grid (polar, radial)
	//   phi on axis0, rad on axis1, lr scalar
	// Inner/outer mantle: _surface(lr[None,:], p[:,None], 0.0) → grid (polar, length)
	//   phi on axis0, lr on axis1, rad scalar
	// Segment start/end cap: _surface(lr[:,None], 0.0, rr[None,:]) → grid (length, radial)
	//   lr on axis0, rad on axis1, phi scalar
	//
	// Rule: phi ALWAYS goes on axis0 (via p[:,None]).
	// lr goes on axis1 for mantles (via lr[None,:]) or axis0 for segment caps (via lr[:,None]).
	// rad goes on axis1 for caps (via rr[None,:]).
	//
	// We determine the axis assignment by the "which array varies" heuristic:
	// - If phi varies (len>1) AND lr varies (len>1): phi=axis0, lr=axis1 (mantle case)
	// - If phi varies AND rad varies: phi=axis0, rad=axis1 (top/bottom cap case)
	// - If lr varies AND rad varies: lr=axis0, rad=axis1 (segment cap case)
	// - If only one varies: that one = axis0, axis1=1
	nl, np, nr := len(lrs), len(phiRs), len(radRs)

	var r0, r1 int = 1, 1
	var lrAxis, phiAxis, radAxis int = -1, -1, -1 // -1 = scalar, 0 = axis0, 1 = axis1

	if np > 1 && nl > 1 {
		// Mantle: phi=axis0, lr=axis1
		phiAxis, lrAxis = 0, 1
		r0, r1 = np, nl
	} else if np > 1 && nr > 1 {
		// Top/bottom cap: phi=axis0, rad=axis1
		phiAxis, radAxis = 0, 1
		r0, r1 = np, nr
	} else if nl > 1 && nr > 1 {
		// Segment cap: lr=axis0, rad=axis1
		lrAxis, radAxis = 0, 1
		r0, r1 = nl, nr
	} else if np > 1 {
		phiAxis = 0
		r0 = np
	} else if nl > 1 {
		lrAxis = 0
		r0 = nl
	} else if nr > 1 {
		radAxis = 0
		r0 = nr
	}

	grid := makeGrid(r0, r1)
	for i := range r0 {
		for j := range r1 {
			var lrVal, phiVal, radVal float64
			if lrAxis == 0 {
				lrVal = lrs[min(i, nl-1)]
			} else if lrAxis == 1 {
				lrVal = lrs[min(j, nl-1)]
			} else {
				lrVal = lrs[0]
			}
			if phiAxis == 0 {
				phiVal = phiRs[min(i, np-1)]
			} else if phiAxis == 1 {
				phiVal = phiRs[min(j, np-1)]
			} else {
				phiVal = phiRs[0]
			}
			if radAxis == 0 {
				radVal = radRs[min(i, nr-1)]
			} else if radAxis == 1 {
				radVal = radRs[min(j, nr-1)]
			} else {
				radVal = radRs[0]
			}

			sp, lx, ly := p.pipeSpine(lrVal)
			phi := p.phiAngleFunc(phiVal, lrVal)
			outer := p.outer.Call(phi, lrVal)
			inner := p.inner.Call(phi, lrVal)
			radius := radVal*(outer-inner) + inner
			grid[i][j] = sp.Add(lx.Mul(radius * math.Cos(phi))).Add(ly.Mul(radius * math.Sin(phi)))
		}
	}
	// Apply vertex transform if set
	if p.transform != nil {
		var pts []Vec3
		for _, row := range grid {
			pts = append(pts, row...)
		}
		pts = p.transform(pts)
		idx := 0
		for i := range grid {
			for j := range grid[i] {
				grid[i][j] = pts[idx]
				idx++
			}
		}
	}
	return grid
}

func (p *Pipe) ToMesh() *picogkffi.Mesh {
	smb := NewSurfaceMeshBuilder()
	pr := arange(p.polarSteps)
	rr := arange(p.radialSteps)
	lr := arange(p.lengthSteps)
	// top cap (lr=last, no flip)
	smb.Add(p.pipeSurface([]float64{lr[len(lr)-1]}, pr, rr), false)
	// bottom cap (lr=first, flip)
	smb.Add(p.pipeSurface([]float64{lr[0]}, pr, rr), true)
	// inner mantle (radR=0, no flip)
	smb.Add(p.pipeSurface(lr, pr, []float64{0.0}), false)
	// outer mantle (radR=1, flip)
	smb.Add(p.pipeSurface(lr, pr, []float64{1.0}), true)
	return smb.Build()
}

func (p *Pipe) ToVoxels() *picogkffi.Voxels {
	return ToVoxels(p.ToMesh())
}

// PipeSegment is an angular slice of a pipe.
type PipeSegment struct {
	Pipe
	mid *LineModulation
	rng *LineModulation
}

// NewPipeSegment creates a pipe segment. start/end are angles or LineModulation.
func NewPipeSegment(frame *LocalFrame, length, innerRadius, outerRadius any,
	start, end any, method string, opts ...PipeOpt) *PipeSegment {
	pipe := *NewPipe(frame, length, innerRadius, outerRadius, opts...)
	a := NewLineModulation(start)
	b := NewLineModulation(end)
	ps := &PipeSegment{Pipe: pipe}
	var mid, rng *LineModulation
	if method == "start_end" {
		mid = a.Add(b).Mul(0.5)
		rng = b.Sub(a)
	} else { // mid_range
		mid = a
		rng = b
	}
	ps.mid = mid
	ps.rng = rng
	// Override the angle function so pipeSurface uses the segment's phi
	ps.phiAngleFunc = func(phiRatio, lr float64) float64 {
		return mid.Call(lr) + (phiRatio-0.5)*rng.Call(lr)
	}
	return ps
}

func (ps *PipeSegment) ToMesh() *picogkffi.Mesh {
	smb := NewSurfaceMeshBuilder()
	pr := arange(ps.polarSteps)
	rr := arange(ps.radialSteps)
	lr := arange(ps.lengthSteps)
	// Standard pipe surfaces
	smb.Add(ps.pipeSurface([]float64{lr[len(lr)-1]}, pr, rr), false) // top cap
	smb.Add(ps.pipeSurface([]float64{lr[0]}, pr, rr), true)          // bottom cap
	smb.Add(ps.pipeSurface(lr, pr, []float64{0.0}), false)           // inner mantle
	smb.Add(ps.pipeSurface(lr, pr, []float64{1.0}), true)            // outer mantle
	// Segment start cap (phiR=0, no flip)
	smb.Add(ps.pipeSurface(lr, []float64{0.0}, rr), false)
	// Segment end cap (phiR=1, flip)
	smb.Add(ps.pipeSurface(lr, []float64{1.0}, rr), true)
	return smb.Build()
}

func (ps *PipeSegment) ToVoxels() *picogkffi.Voxels {
	return ToVoxels(ps.ToMesh())
}

func isConstant(v any) bool {
	switch v.(type) {
	case float64, int, int32, int64, float32:
		return true
	default:
		return false
	}
}

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
