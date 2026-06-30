package picogkshapes

import "math"

// LocalFrame is a position + right-handed orthonormal basis.
type LocalFrame struct {
	Pos    Vec3
	LocalX Vec3
	LocalY Vec3
	LocalZ Vec3
}

// NewLocalFrame creates a frame at the given position.
// If localZ is zero, uses the identity frame (X=+X, Y=+Y, Z=+Z).
// If localX is zero, computes an orthogonal X to the given Z.
func NewLocalFrame(position Vec3, localZ ...Vec3) *LocalFrame {
	if len(localZ) == 0 || localZ[0].Len() < 1e-12 {
		return &LocalFrame{
			Pos:    position,
			LocalX: Vec3{1, 0, 0},
			LocalY: Vec3{0, 1, 0},
			LocalZ: Vec3{0, 0, 1},
		}
	}
	z := localZ[0].Normalized()
	x := OrthogonalDir(z)
	y := z.Cross(x).Normalized()
	return &LocalFrame{Pos: position, LocalX: x, LocalY: y, LocalZ: z}
}

// NewLocalFrameXYZ creates a frame with explicit local Z and local X.
func NewLocalFrameXYZ(position, localZ, localX Vec3) *LocalFrame {
	z := localZ.Normalized()
	x := localX.Normalized()
	y := z.Cross(x).Normalized()
	return &LocalFrame{Pos: position, LocalX: x, LocalY: y, LocalZ: z}
}

// Translated returns a copy with moved position.
func (f *LocalFrame) Translated(offset Vec3) *LocalFrame {
	return &LocalFrame{Pos: f.Pos.Add(offset), LocalX: f.LocalX, LocalY: f.LocalY, LocalZ: f.LocalZ}
}

// Rotated returns a copy with axes rotated by angle (radians) about axis.
func (f *LocalFrame) Rotated(angle float64, axis Vec3) *LocalFrame {
	return &LocalFrame{
		Pos:    f.Pos,
		LocalX: RotateAroundAxis(f.LocalX, axis, angle),
		LocalY: RotateAroundAxis(f.LocalY, axis, angle),
		LocalZ: RotateAroundAxis(f.LocalZ, axis, angle),
	}
}

// Inverted returns a copy with Z and/or X negated.
func (f *LocalFrame) Inverted(mirrorZ, mirrorX bool) *LocalFrame {
	z, x := f.LocalZ, f.LocalX
	if mirrorZ {
		z = z.Mul(-1)
	}
	if mirrorX {
		x = x.Mul(-1)
	}
	y := z.Cross(x).Normalized()
	return &LocalFrame{Pos: f.Pos, LocalX: x, LocalY: y, LocalZ: z}
}

// PointToWorld transforms a local point to world coordinates.
func (f *LocalFrame) PointToWorld(local Vec3) Vec3 {
	return f.Pos.Add(f.LocalX.Mul(local.X)).Add(f.LocalY.Mul(local.Y)).Add(f.LocalZ.Mul(local.Z))
}

// Frames is a field of local frames sampled along a spine.
type Frames struct {
	Spine  []Vec3
	LocalX []Vec3
	LocalY []Vec3
	LocalZ []Vec3
}

// FramesExtrude creates frames along a straight extrusion.
func FramesExtrude(length float64, frame *LocalFrame, spacing float64) *Frames {
	n := int(math.Ceil(length / spacing))
	if n < 2 {
		n = 2
	}
	pts := make([]Vec3, n+1)
	for i := 0; i <= n; i++ {
		lr := float64(i) / float64(n)
		pts[i] = frame.Pos.Add(frame.LocalZ.Mul(length * lr))
	}
	lx := make([]Vec3, len(pts))
	ly := make([]Vec3, len(pts))
	lz := make([]Vec3, len(pts))
	for i := range pts {
		lx[i] = frame.LocalX
		ly[i] = frame.LocalY
		lz[i] = frame.LocalZ
	}
	return &Frames{Spine: pts, LocalX: lx, LocalY: ly, LocalZ: lz}
}

// FrameAt returns an interpolated frame at length_ratio [0,1].
func (fs *Frames) FrameAt(lr float64) *LocalFrame {
	n := len(fs.Spine)
	if n == 0 {
		return NewLocalFrame(Vec3{})
	}
	if lr <= 0 {
		return NewLocalFrameXYZ(fs.Spine[0], fs.LocalZ[0], fs.LocalX[0])
	}
	if lr >= 1 {
		return NewLocalFrameXYZ(fs.Spine[n-1], fs.LocalZ[n-1], fs.LocalX[n-1])
	}
	t := lr * float64(n-1)
	i := int(t)
	frac := t - float64(i)
	if i >= n-1 {
		i = n - 2
		frac = 1
	}
	pos := Lerp(fs.Spine[i], fs.Spine[i+1], frac)
	z := Lerp(fs.LocalZ[i], fs.LocalZ[i+1], frac).Normalized()
	x := Lerp(fs.LocalX[i], fs.LocalX[i+1], frac).Normalized()
	return NewLocalFrameXYZ(pos, z, x)
}

// Samples returns the spine, lx, ly, lz arrays.
func (fs *Frames) Samples() ([]Vec3, []Vec3, []Vec3, []Vec3) {
	return fs.Spine, fs.LocalX, fs.LocalY, fs.LocalZ
}

// FramesAlignedToX creates frames with tangent-Z along the spine and
// local-X aligned to a constant target_x via align_with_target_x.
func FramesAlignedToX(points []Vec3, targetX Vec3) *Frames {
	n := len(points)
	lx := make([]Vec3, n)
	ly := make([]Vec3, n)
	lz := make([]Vec3, n)
	// Compute tangents
	for i := 0; i < n; i++ {
		var tangent Vec3
		if i == 0 {
			tangent = points[1].Sub(points[0])
		} else if i == n-1 {
			tangent = points[n-1].Sub(points[n-2])
		} else {
			tangent = points[i+1].Sub(points[i-1])
		}
		lz[i] = tangent.Normalized()
	}
	// Align X to target
	lastX := targetX
	for i := 0; i < n; i++ {
		lx[i] = alignWithTargetX(lz[i], lastX)
		lastX = lx[i]
		ly[i] = lz[i].Cross(lx[i]).Normalized()
	}
	return &Frames{Spine: points, LocalX: lx, LocalY: ly, LocalZ: lz}
}

// alignWithTargetX finds the in-plane direction orthogonal to localZ
// that is closest to targetX. Brute-force search over 0..180° at 0.01° res.
func alignWithTargetX(localZ, targetX Vec3) Vec3 {
	bestDot := -2.0
	bestDir := OrthogonalDir(localZ)
	for deg := 0.0; deg < 180.0; deg += 0.01 {
		angle := deg * math.Pi / 180.0
		dir := RotateAroundAxis(OrthogonalDir(localZ), localZ, angle)
		d := dir.Dot(targetX)
		if d > bestDot {
			bestDot = d
			bestDir = dir
		}
	}
	// Flip if needed
	if bestDir.Dot(targetX) < 0 {
		bestDir = bestDir.Mul(-1)
	}
	return bestDir.Normalized()
}
