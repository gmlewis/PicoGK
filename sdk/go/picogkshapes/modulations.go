package picogkshapes

// LineModulation is a 1D modulation: value as a function of a single ratio [0,1].
type LineModulation struct {
	fn func(ratio float64) float64
}

// NewLineModulation creates a modulation from a constant, a function, or another modulation.
func NewLineModulation(value any) *LineModulation {
	switch v := value.(type) {
	case float64:
		return &LineModulation{fn: func(_ float64) float64 { return v }}
	case int:
		return &LineModulation{fn: func(_ float64) float64 { return float64(v) }}
	case func(float64) float64:
		return &LineModulation{fn: v}
	case *LineModulation:
		return &LineModulation{fn: v.fn}
	default:
		return &LineModulation{fn: func(_ float64) float64 { return 0 }}
	}
}

// Call evaluates the modulation at the given ratio.
func (m *LineModulation) Call(ratio float64) float64 {
	if m == nil || m.fn == nil {
		return 0
	}
	return m.fn(ratio)
}

// Mul returns a new modulation scaled by a factor.
func (m *LineModulation) Mul(factor float64) *LineModulation {
	return &LineModulation{fn: func(r float64) float64 { return m.Call(r) * factor }}
}

// Add returns a new modulation that adds two modulations.
func (m *LineModulation) Add(other *LineModulation) *LineModulation {
	return &LineModulation{fn: func(r float64) float64 { return m.Call(r) + other.Call(r) }}
}

// Sub returns a new modulation that subtracts other from this.
func (m *LineModulation) Sub(other *LineModulation) *LineModulation {
	return &LineModulation{fn: func(r float64) float64 { return m.Call(r) - other.Call(r) }}
}

// SurfaceModulation is a 2D modulation: value as a function of (phi, length_ratio).
type SurfaceModulation struct {
	fn func(phi, lr float64) float64
}

// NewSurfaceModulation creates a modulation from a constant, a function, another
// SurfaceModulation, or a LineModulation (broadcast across one axis).
func NewSurfaceModulation(value any, line ...string) *SurfaceModulation {
	lineArg := "second"
	if len(line) > 0 {
		lineArg = line[0]
	}
	switch v := value.(type) {
	case float64:
		return &SurfaceModulation{fn: func(_, _ float64) float64 { return v }}
	case int:
		return &SurfaceModulation{fn: func(_, _ float64) float64 { return float64(v) }}
	case func(float64, float64) float64:
		return &SurfaceModulation{fn: v}
	case *SurfaceModulation:
		return &SurfaceModulation{fn: v.fn}
	case *LineModulation:
		if lineArg == "first" {
			return &SurfaceModulation{fn: func(phi, _ float64) float64 { return v.Call(phi) }}
		}
		return &SurfaceModulation{fn: func(_, lr float64) float64 { return v.Call(lr) }}
	default:
		return &SurfaceModulation{fn: func(_, _ float64) float64 { return 0 }}
	}
}

// Call evaluates the modulation at (phi, lr).
func (m *SurfaceModulation) Call(phi, lr float64) float64 {
	if m == nil || m.fn == nil {
		return 0
	}
	return m.fn(phi, lr)
}

// Mul returns a new modulation scaled by a factor.
func (m *SurfaceModulation) Mul(factor float64) *SurfaceModulation {
	return &SurfaceModulation{fn: func(p, l float64) float64 { return m.Call(p, l) * factor }}
}

// Add returns a new modulation that adds two modulations.
func (m *SurfaceModulation) Add(other *SurfaceModulation) *SurfaceModulation {
	return &SurfaceModulation{fn: func(p, l float64) float64 { return m.Call(p, l) + other.Call(p, l) }}
}

// Sub returns a new modulation that subtracts other from this.
func (m *SurfaceModulation) Sub(other *SurfaceModulation) *SurfaceModulation {
	return &SurfaceModulation{fn: func(p, l float64) float64 { return m.Call(p, l) - other.Call(p, l) }}
}