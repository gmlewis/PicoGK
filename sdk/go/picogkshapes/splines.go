package picogkshapes

import "math"

// ControlPointSpline is a B-spline curve through a control polygon (open or closed).
// Port of PicoPie's picogk.shapes.splines.ControlPointSpline.
type ControlPointSpline struct {
	controlPoints []Vec3
	degree        int
	closed        bool
	knot          []float64
}

// NewControlPointSpline creates a B-spline from control points.
// degree defaults to 2 (quadratic). If closed, wraps the control polygon.
func NewControlPointSpline(controlPoints []Vec3, degree int, closed bool) *ControlPointSpline {
	if degree < 1 {
		degree = 2
	}
	pts := make([]Vec3, len(controlPoints))
	copy(pts, controlPoints)

	if closed {
		// If first and last points coincide, drop the duplicate
		if pts[0].Sub(pts[len(pts)-1]).Len() < 1e-7 {
			pts = pts[:len(pts)-1]
		}
		nBefore := len(pts)
		// Wrap by appending n-1 points
		for i := range nBefore - 1 {
			pts = append(pts, pts[i])
		}
	}

	s := &ControlPointSpline{
		controlPoints: pts,
		degree:        degree,
		closed:        closed,
	}
	s.knot = splineKnotVector(len(pts), degree, !closed)
	return s
}

// PointAt evaluates the B-spline at parameter t [0,1].
func (s *ControlPointSpline) PointAt(t float64) Vec3 {
	var pt Vec3
	for i := range s.controlPoints {
		b := splineBasis(s.knot, t, i, s.degree)
		pt = pt.Add(s.controlPoints[i].Mul(b))
	}
	return pt
}

// Points returns n samples along the spline.
func (s *ControlPointSpline) Points(n int) []Vec3 {
	pts := make([]Vec3, n)
	for i := range n {
		pts[i] = s.PointAt(float64(i) / float64(n-1))
	}
	return pts
}

// splineBasis is the Cox-de Boor B-spline basis function (recursive).
func splineBasis(knot []float64, t float64, i, degree int) float64 {
	const eps = 1e-7
	if degree == 0 {
		if (knot[i] <= t && t < knot[i+1]) ||
			(math.Abs(t-knot[i+1]) < eps && math.Abs(t-knot[len(knot)-1]) < eps) {
			return 1.0
		}
		return 0.0
	}
	value := 0.0
	if math.Abs(knot[i+degree]-knot[i]) > eps {
		value += (t - knot[i]) / (knot[i+degree] - knot[i]) * splineBasis(knot, t, i, degree-1)
	}
	if math.Abs(knot[i+degree+1]-knot[i+1]) > eps {
		value += (knot[i+degree+1] - t) / (knot[i+degree+1] - knot[i+1]) * splineBasis(knot, t, i+1, degree-1)
	}
	return value
}

// splineKnotVector builds a uniform knot vector.
// For clamp=true: clamped to [0,1]. For clamp=false: open (unclamped).
func splineKnotVector(nControl, degree int, clamp bool) []float64 {
	nKnots := nControl + degree + 1
	validRange := nControl - degree
	if validRange < 1 {
		validRange = 1
	}
	d := 1.0 / float64(validRange)
	knot := make([]float64, nKnots)
	for i := range nKnots {
		knot[i] = -d*float64(degree) + d*float64(i)
	}
	if clamp {
		for i := range knot {
			if knot[i] < 0 {
				knot[i] = 0
			}
			if knot[i] > 1 {
				knot[i] = 1
			}
		}
	}
	return knot
}
