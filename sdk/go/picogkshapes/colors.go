package picogkshapes

import "github.com/gmlewis/PicoGK/sdk/go/picogkffi"

// Palette of named RGB colors (0..1) matching PicoPie's picogk.shapes.colors.Palette.
type RGB struct {
	R, G, B float64
}

var Palette = struct {
	Blue        RGB
	Frozen      RGB
	Pitaya      RGB
	Warning     RGB
	Green       RGB
	Yellow      RGB
	Blueberry   RGB
	Lemongrass  RGB
	Orchid      RGB
	Ruby        RGB
	RacingGreen RGB
	Crystal     RGB
	Billie      RGB
	Lavender    RGB
	Bubblegum   RGB
	Gray        RGB
}{
	Blue:        RGB{0.346, 0.6, 0.902},
	Frozen:      RGB{0.494, 0.784, 0.89},
	Pitaya:      RGB{0.902, 0.439, 0.357},
	Warning:     RGB{0.902, 0.722, 0.31},
	Green:       RGB{0.42, 0.84, 0.42},
	Yellow:      RGB{0.902, 0.863, 0.31},
	Blueberry:   RGB{0.31, 0.42, 0.902},
	Lemongrass:  RGB{0.769, 0.839, 0.42},
	Orchid:      RGB{0.608, 0.353, 0.714},
	Ruby:        RGB{0.902, 0.31, 0.42},
	RacingGreen: RGB{0.043, 0.478, 0.294},
	Crystal:     RGB{0.69, 0.878, 0.902},
	Billie:      RGB{0.31, 0.714, 0.902},
	Lavender:    RGB{0.69, 0.608, 0.902},
	Bubblegum:   RGB{0.902, 0.482, 0.69},
	Gray:        RGB{0.533, 0.533, 0.533},
}

// ToFFI converts an RGB to a picogkffi.ColorFloat.
func (c RGB) ToFFI() picogkffi.ColorFloat {
	return picogkffi.ColorFloat{R: float32(c.R), G: float32(c.G), B: float32(c.B), A: 1.0}
}

// ToHex converts an RGB to a hex color string.
func (c RGB) ToHex() string {
	return rgbToHex(c.R, c.G, c.B)
}

func rgbToHex(r, g, b float64) string {
	ir := int(r * 255)
	ig := int(g * 255)
	ib := int(b * 255)
	if ir > 255 { ir = 255 }
	if ig > 255 { ig = 255 }
	if ib > 255 { ib = 255 }
	if ir < 0 { ir = 0 }
	if ig < 0 { ig = 0 }
	if ib < 0 { ib = 0 }
	return hexFromByte(ir) + hexFromByte(ig) + hexFromByte(ib)
}

func hexFromByte(b int) string {
	hi := b >> 4
	lo := b & 0xf
	return string(hexDigit(hi)) + string(hexDigit(lo))
}

func hexDigit(d int) rune {
	if d < 10 {
		return rune('0' + d)
	}
	return rune('a' + d - 10)
}