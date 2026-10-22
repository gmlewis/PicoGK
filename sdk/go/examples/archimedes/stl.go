package main

import (
	"bufio"
	"encoding/binary"
	"fmt"
	"math"
	"os"
)

// writeBinarySTL writes a binary STL file. vertices holds x,y,z triples and
// triangles holds three vertex indices per facet.
func writeBinarySTL(path string, vertices []float32, triangles []int32) error {
	if len(vertices)%3 != 0 {
		return fmt.Errorf("STL: vertex array length %d is not a multiple of 3", len(vertices))
	}
	if len(triangles)%3 != 0 {
		return fmt.Errorf("STL: triangle array length %d is not a multiple of 3", len(triangles))
	}
	vertexCount := int32(len(vertices) / 3)
	for i, idx := range triangles {
		if idx < 0 || idx >= vertexCount {
			return fmt.Errorf("STL: triangle index %d at position %d out of range", idx, i)
		}
	}
	facetCount := len(triangles) / 3
	if uint64(facetCount) > uint64(^uint32(0)) {
		return fmt.Errorf("STL: %d facets exceed the binary STL limit", facetCount)
	}

	f, err := os.Create(path)
	if err != nil {
		return err
	}
	bw := bufio.NewWriter(f)

	header := make([]byte, 80)
	copy(header, "binary STL - PicoGK archimedes example")
	if _, err := bw.Write(header); err != nil {
		f.Close()
		return err
	}
	if err := binary.Write(bw, binary.LittleEndian, uint32(facetCount)); err != nil {
		f.Close()
		return err
	}

	vertexAt := func(i int32) Vec3 {
		return Vec3{
			float64(vertices[i*3]),
			float64(vertices[i*3+1]),
			float64(vertices[i*3+2]),
		}
	}

	var facet [50]byte
	for i := 0; i+2 < len(triangles); i += 3 {
		a := vertexAt(triangles[i])
		b := vertexAt(triangles[i+1])
		c := vertexAt(triangles[i+2])
		n := b.Sub(a).Cross(c.Sub(a)).Normalized()
		values := [12]float32{
			float32(n.X), float32(n.Y), float32(n.Z),
			float32(a.X), float32(a.Y), float32(a.Z),
			float32(b.X), float32(b.Y), float32(b.Z),
			float32(c.X), float32(c.Y), float32(c.Z),
		}
		for j, v := range values {
			binary.LittleEndian.PutUint32(facet[j*4:], math.Float32bits(v))
		}
		binary.LittleEndian.PutUint16(facet[48:], 0) // attribute byte count
		if _, err := bw.Write(facet[:]); err != nil {
			f.Close()
			return err
		}
	}

	if err := bw.Flush(); err != nil {
		f.Close()
		return err
	}
	return f.Close()
}
