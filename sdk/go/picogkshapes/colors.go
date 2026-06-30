package picogkshapes

import "github.com/gmlewis/PicoGK/sdk/go/picogkffi"

// Palette of named RGB colors (0..1) — exact values from PicoPie's picogk.shapes.colors.Palette.
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
	Blue:        RGB{0.258824, 0.529412, 0.960784},
	Frozen:      RGB{0.427451, 0.886275, 0.988235},
	Pitaya:      RGB{0.980392, 0.164706, 0.533333},
	Warning:     RGB{0.988235, 0.400000, 0.031373},
	Green:       RGB{0.000000, 0.721569, 0.000000},
	Yellow:      RGB{0.988235, 0.847059, 0.031373},
	Blueberry:   RGB{0.309804, 0.050980, 0.749020},
	Lemongrass:  RGB{0.721569, 0.878431, 0.192157},
	Orchid:      RGB{0.780392, 0.141176, 0.513725},
	Ruby:        RGB{0.690196, 0.000000, 0.172549},
	RacingGreen: RGB{0.023529, 0.360784, 0.207843},
	Crystal:     RGB{0.047059, 0.756863, 0.968627},
	Billie:      RGB{0.007843, 0.968627, 0.043137},
	Lavender:    RGB{0.788235, 0.400000, 1.000000},
	Bubblegum:   RGB{1.000000, 0.400000, 0.807843},
	Gray:        RGB{0.741176, 0.741176, 0.741176},
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
	if ir > 255 {
		ir = 255
	}
	if ig > 255 {
		ig = 255
	}
	if ib > 255 {
		ib = 255
	}
	if ir < 0 {
		ir = 0
	}
	if ig < 0 {
		ig = 0
	}
	if ib < 0 {
		ib = 0
	}
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
