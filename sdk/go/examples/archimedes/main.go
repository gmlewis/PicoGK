package main

import (
	"flag"
	"fmt"
	"os"
)

func main() {
	flag.Parse()

	c := defaultConfig()
	if err := c.Validate(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	fmt.Printf("Archimedes geometry prototype\n")
	fmt.Printf("Rotor envelope: diameter %.1f mm, axial length %.1f mm, blades %v\n",
		c.RotorDiameter, c.AxialLength, c.BladeCount)
	fmt.Printf("Spiral samples: %v; turns %.2f; nominal thickness %.2f mm\n",
		c.Samples, c.Turns, c.Thickness)
	pts := c.BladeBoundarySamples()
	fmt.Printf("Boundary points: %v\n", len(pts))
	fmt.Printf("First: %+v\nLast:  %+v\n", pts[0], pts[len(pts)-1])
	fmt.Println("Geometry core only: STL export and PicoGK FFI solidification are the next milestone.")
}
