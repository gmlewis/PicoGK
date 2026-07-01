package picogkshapes

import (
	"math"

	"github.com/gmlewis/PicoGK/sdk/go/picogkffi"
)

// ImplicitGyroid is a gyroid TPMS shell SDF.
type ImplicitGyroid struct {
	UnitSize       float64
	ThicknessRatio float64
	frequency      float64
}

// NewImplicitGyroid creates a gyroid with the given unit size and thickness ratio.
func NewImplicitGyroid(unitSize, thicknessRatio float64) *ImplicitGyroid {
	return &ImplicitGyroid{
		UnitSize:       unitSize,
		ThicknessRatio: thicknessRatio,
		frequency:      2 * math.Pi / unitSize,
	}
}

// Eval evaluates the SDF at (x, y, z). Negative = inside.
func (g *ImplicitGyroid) Eval(x, y, z float64) float64 {
	d := math.Sin(g.frequency*x)*math.Cos(g.frequency*y) +
		math.Sin(g.frequency*y)*math.Cos(g.frequency*z) +
		math.Sin(g.frequency*z)*math.Cos(g.frequency*x)
	return math.Abs(d) - 0.5*g.ThicknessRatio
}

// Render renders the gyroid into a voxel field within the given bbox.
func (g *ImplicitGyroid) Render(bbox picogkffi.BBox3) *picogkffi.Voxels {
	sdf := picogkffi.NewSDF(func(x, y, z float32) float32 {
		return float32(g.Eval(float64(x), float64(y), float64(z)))
	})
	v := picogkffi.NewVoxels()
	v.RenderImplicitWith(bbox, sdf)
	return v
}

// Intersect clips the given voxels by this gyroid SDF.
func (g *ImplicitGyroid) Intersect(voxels *picogkffi.Voxels) *picogkffi.Voxels {
	result := voxels.Copy()
	sdf := picogkffi.NewSDF(func(x, y, z float32) float32 {
		return float32(g.Eval(float64(x), float64(y), float64(z)))
	})
	result.IntersectImplicitWith(sdf)
	return result
}

// ImplicitSphere is a solid sphere SDF.
type ImplicitSphere struct {
	Center Vec3
	Radius float64
}

// NewImplicitSphere creates a sphere SDF.
func NewImplicitSphere(center Vec3, radius float64) *ImplicitSphere {
	return &ImplicitSphere{Center: center, Radius: radius}
}

// Eval evaluates the SDF. Negative = inside.
func (s *ImplicitSphere) Eval(x, y, z float64) float64 {
	dx, dy, dz := x-s.Center.X, y-s.Center.Y, z-s.Center.Z
	return math.Sqrt(dx*dx+dy*dy+dz*dz) - s.Radius
}

// Render renders the sphere into a voxel field.
func (s *ImplicitSphere) Render(bbox picogkffi.BBox3) *picogkffi.Voxels {
	sdf := picogkffi.NewSDF(func(x, y, z float32) float32 {
		return float32(s.Eval(float64(x), float64(y), float64(z)))
	})
	v := picogkffi.NewVoxels()
	v.RenderImplicitWith(bbox, sdf)
	return v
}

// Intersect clips the given voxels by this sphere SDF.
func (s *ImplicitSphere) Intersect(voxels *picogkffi.Voxels) *picogkffi.Voxels {
	result := voxels.Copy()
	sdf := picogkffi.NewSDF(func(x, y, z float32) float32 {
		return float32(s.Eval(float64(x), float64(y), float64(z)))
	})
	result.IntersectImplicitWith(sdf)
	return result
}

// ImplicitGenus is a genus-2 implicit surface SDF.
type ImplicitGenus struct {
	Gap float64
}

// NewImplicitGenus creates a genus surface SDF.
func NewImplicitGenus(gap float64) *ImplicitGenus {
	return &ImplicitGenus{Gap: gap}
}

// Eval evaluates the SDF. Negative = inside.
func (g *ImplicitGenus) Eval(x, y, z float64) float64 {
	return 2*y*(y*y-3*x*x)*(1-z*z) + (x*x+y*y)*(x*x+y*y) - (9*z*z-1)*(1-z*z) - g.Gap
}

// Render renders the genus surface into a voxel field.
func (g *ImplicitGenus) Render(bbox picogkffi.BBox3, scale float64) *picogkffi.Voxels {
	sdf := picogkffi.NewSDF(func(x, y, z float32) float32 {
		return float32(g.Eval(float64(x)/scale, float64(y)/scale, float64(z)/scale))
	})
	v := picogkffi.NewVoxels()
	v.RenderImplicitWith(bbox, sdf)
	return v
}

// ImplicitSuperEllipsoid is a super-ellipsoid SDF.
type ImplicitSuperEllipsoid struct {
	Center             Vec3
	Ax, Ay, Az, E1, E2 float64
}

// NewImplicitSuperEllipsoid creates a super-ellipsoid SDF.
func NewImplicitSuperEllipsoid(center Vec3, ax, ay, az, e1, e2 float64) *ImplicitSuperEllipsoid {
	return &ImplicitSuperEllipsoid{Center: center, Ax: ax, Ay: ay, Az: az, E1: e1, E2: e2}
}

// Eval evaluates the SDF. Negative = inside.
func (s *ImplicitSuperEllipsoid) Eval(x, y, z float64) float64 {
	dx := math.Abs(x-s.Center.X) / s.Ax
	dy := math.Abs(y-s.Center.Y) / s.Ay
	dz := math.Abs(z-s.Center.Z) / s.Az
	d := math.Pow(math.Pow(dx, 2/s.E2)+math.Pow(dy, 2/s.E2), s.E2/s.E1) + math.Pow(dz, 2/s.E1)
	return d - 1
}

// Render renders the super-ellipsoid into a voxel field.
func (s *ImplicitSuperEllipsoid) Render(bbox picogkffi.BBox3) *picogkffi.Voxels {
	sdf := picogkffi.NewSDF(func(x, y, z float32) float32 {
		return float32(s.Eval(float64(x), float64(y), float64(z)))
	})
	v := picogkffi.NewVoxels()
	v.RenderImplicitWith(bbox, sdf)
	return v
}

// LatticePipe is a round pipe built from lattice beams along a length-spine.
type LatticePipe struct {
	BaseShape
	frame  *LocalFrame
	length float64
	radius *LineModulation
	frames *Frames
	lSteps int
}

// NewLatticePipe creates a lattice pipe.
func NewLatticePipe(frame *LocalFrame, length, radius any, opts ...LatticePipeOpt) *LatticePipe {
	lp := &LatticePipe{
		frame:  frame,
		length: toFloat(length),
		radius: NewLineModulation(radius),
		lSteps: 100,
	}
	if frame == nil {
		lp.frame = NewLocalFrame(V(0, 0, 0))
	}
	for _, opt := range opts {
		opt(lp)
	}
	return lp
}

// LatticePipeOpt configures a LatticePipe.
type LatticePipeOpt func(*LatticePipe)

func LatticePipeFrames(fs *Frames) LatticePipeOpt {
	return func(lp *LatticePipe) { lp.frames = fs; lp.lSteps = 500 }
}
func LatticePipeLengthSteps(n int) LatticePipeOpt { return func(lp *LatticePipe) { lp.lSteps = n } }

func (lp *LatticePipe) spinePoint(lr float64) Vec3 {
	if lp.frames != nil {
		pos := lp.frames.FrameAt(lr).Pos
		return pos
	}
	return lp.frame.Pos.Add(lp.frame.LocalZ.Mul(lp.length * lr))
}

// ToLattice builds the lattice structure.
func (lp *LatticePipe) ToLattice() *picogkffi.Lattice {
	lat := picogkffi.NewLattice()
	n := lp.lSteps
	for i := 1; i <= n; i++ {
		lr0 := float64(i-1) / float64(n)
		lr1 := float64(i) / float64(n)
		p0 := lp.spinePoint(lr0)
		p1 := lp.spinePoint(lr1)
		r0 := lp.radius.Call(lr0)
		r1 := lp.radius.Call(lr1)
		lat.AddBeam(ToFFI(p0), ToFFI(p1), float32(r0), float32(r1), true)
	}
	return lat
}

// ToVoxels rasterizes the lattice into a voxel field.
func (lp *LatticePipe) ToVoxels() *picogkffi.Voxels {
	return lp.ToLattice().ToVoxels()
}

// ToMesh meshes the voxel field.
func (lp *LatticePipe) ToMesh() *picogkffi.Mesh {
	return lp.ToVoxels().ToMesh()
}

// LatticeManifold is a lattice pipe with tear-drop tips for printability.
type LatticeManifold struct {
	LatticePipe
	maxOverhangAngle   float64
	extendBothSides    bool
	minPrintableRadius float64
}

// NewLatticeManifold creates a lattice manifold.
func NewLatticeManifold(frame *LocalFrame, length, radius, maxOverhangAngle float64, opts ...LatticeManifoldOpt) *LatticeManifold {
	lm := &LatticeManifold{
		LatticePipe:        *NewLatticePipe(frame, length, radius),
		maxOverhangAngle:   maxOverhangAngle,
		extendBothSides:    false,
		minPrintableRadius: 0.1,
	}
	for _, opt := range opts {
		opt(lm)
	}
	return lm
}

// LatticeManifoldOpt configures a LatticeManifold.
type LatticeManifoldOpt func(*LatticeManifold)

func LMExtendBothSides(b bool) LatticeManifoldOpt {
	return func(lm *LatticeManifold) { lm.extendBothSides = b }
}
func LMMinPrintableRadius(r float64) LatticeManifoldOpt {
	return func(lm *LatticeManifold) { lm.minPrintableRadius = r }
}
func LMFrames(fs *Frames) LatticeManifoldOpt {
	return func(lm *LatticeManifold) { lm.frames = fs; lm.lSteps = 500 }
}
func LMLengthSteps(n int) LatticeManifoldOpt { return func(lm *LatticeManifold) { lm.lSteps = n } }

func (lm *LatticeManifold) ToLattice() *picogkffi.Lattice {
	lat := picogkffi.NewLattice()
	n := lm.lSteps
	limitAngle := lm.maxOverhangAngle * math.Pi / 180.0
	halfAlpha := math.Pi/2 - limitAngle
	maxR := lm.radius.Call(0)
	r := maxR
	h := r * (1 - math.Cos(halfAlpha))
	s := 2 * r * math.Sin(halfAlpha)
	tipLength := math.Tan(halfAlpha) * (0.5*s - lm.minPrintableRadius)
	// The tear-drop tips point along world Z (up/down), NOT along the frame's local_z.
	// This matches PicoPie: z = np.array([0.0, 0.0, 1.0])
	worldZ := Vec3{0, 0, 1}
	for i := range n {
		lr := float64(i) / float64(n)
		pt := lm.spinePoint(lr)
		beam := lm.radius.Call(lr)
		// Round pipe station (sphere-like)
		lat.AddBeam(ToFFI(pt), ToFFI(pt), float32(beam), float32(beam), true)
		// Tear-drop tip (+Z direction)
		mid := pt.Add(worldZ.Mul(r - h))
		tip := mid.Add(worldZ.Mul(tipLength))
		lat.AddBeam(ToFFI(mid), ToFFI(tip), float32(0.5*s), float32(lm.minPrintableRadius), false)
		if lm.extendBothSides {
			// Tear-drop tip (-Z direction)
			midN := pt.Sub(worldZ.Mul(r - h))
			tipN := midN.Sub(worldZ.Mul(tipLength))
			lat.AddBeam(ToFFI(midN), ToFFI(tipN), float32(0.5*s), float32(lm.minPrintableRadius), false)
		}
	}
	return lat
}

func (lm *LatticeManifold) ToVoxels() *picogkffi.Voxels {
	return lm.ToLattice().ToVoxels()
}
