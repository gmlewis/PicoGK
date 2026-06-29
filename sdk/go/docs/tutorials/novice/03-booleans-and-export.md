# Novice 3 — Booleans, offsets, and hollowing

## Boolean operations

The SDK provides three boolean CSG operations. Each takes two object IDs
(`A` and `B`) and returns a new object with the given `ID`:

```go
package main

import (
    "context"
    "log"

    "github.com/gmlewis/PicoGK/sdk/go/picogk"
)

func main() {
    log.SetFlags(0)
    client, err := picogk.NewClient(context.Background(), "")
    if err != nil { log.Fatal(err) }
    defer client.Close()

    do := func(cmd any) { client.Must(cmd) }

    client.Must(picogk.Init{VoxelSizeMM: new(0.2)})

    do(picogk.CreateSphere{X: 0, Y: 0, Z: 0, Radius: 10, ID: "a"})
    do(picogk.CreateSphere{X: 8, Y: 0, Z: 0, Radius: 8, ID: "b"})

    // Union: A + B
    do(picogk.BooleanAdd{A: "a", B: "b", ID: "union"})

    // Subtract: A - B
    do(picogk.BooleanSubtract{A: "a", B: "b", ID: "cut"})

    // Intersect: A & B
    do(picogk.BooleanIntersect{A: "a", B: "b", ID: "overlap"})
}
```

### Multi-object booleans

```go
    // Union of many objects at once:
    do(picogk.BooleanAddAll{ObjectIDs: []string{"a", "b", "union"}, ID: "all"})

    // Subtract many from one:
    do(picogk.BooleanSubtractAll{A: "a", SubtractIDs: []string{"b", "overlap"}, ID: "drilled"})
```

## Offsets

Offset expands (positive) or shrinks (negative) the surface by a distance:

```go
    // Expand by 2mm:
    do(picogk.Offset{ObjectID: "a", Distance: 2.0, ID: "grown"})

    // Shrink by 1mm:
    do(picogk.Offset{ObjectID: "a", Distance: -1.0, ID: "shrunk"})
```

Double offset applies two sequential offsets — useful for morphological
operations (open, close, round):

```go
    // Morphological open: expand 2mm, then shrink 2mm (removes thin features):
    do(picogk.DoubleOffset{ObjectID: "a", Offset1: 2.0, Offset2: -2.0, ID: "opened"})

    // Rounding: expand 2mm, then shrink 1.5mm (net +0.5mm, rounded edges):
    do(picogk.DoubleOffset{ObjectID: "a", Offset1: 2.0, Offset2: -1.5, ID: "rounded"})
```

## Hollowing (shell)

Shell creates a hollow wall of a specified thickness:

```go
    do(picogk.CreateSphere{X: 0, Y: 0, Z: 0, Radius: 12, ID: "ball"})
    // Create a 1.5mm wall:
    do(picogk.Shell{ObjectID: "ball", InnerOffset: 1.5, OuterOffset: 0, ID: "hollow"})
```

- `InnerOffset`: how far the inner surface is from the original (wall thickness).
- `OuterOffset`: how far the outer surface is from the original (0 = keep outer surface).
- `Smooth` (optional): smoothing distance for the shell walls.

## Vented hollow ball (complete example)

```go
package main

import (
    "context"
    "fmt"
    "log"

    "github.com/gmlewis/PicoGK/sdk/go/picogk"
)

func main() {
    log.SetFlags(0)
    client, err := picogk.NewClient(context.Background(), "")
    if err != nil { log.Fatal(err) }
    defer client.Close()

    do := func(cmd any) { client.Must(cmd) }

    client.Must(picogk.Init{VoxelSizeMM: new(0.2)})

    // Build a sphere, subtract a bite, then hollow it.
    do(picogk.CreateSphere{X: 0, Y: 0, Z: 0, Radius: 12, ID: "ball"})
    do(picogk.CreateSphere{X: 9, Y: 0, Z: 0, Radius: 6, ID: "bite"})
    do(picogk.BooleanSubtract{A: "ball", B: "bite", ID: "part"})
    do(picogk.Shell{ObjectID: "part", InnerOffset: 1.5, OuterOffset: 0, ID: "shelled"})

    // Query volume.
    _, vol := client.Must(picogk.GetVolume{ObjectID: "shelled"})
    fmt.Println("volume:", vol)

    // Export STL.
    do(picogk.VoxelsToMesh{VoxelsID: "shelled", ID: "mesh"})
    do(picogk.SaveSTL{MeshID: "mesh", Path: "/tmp/vented_ball.stl"})
    fmt.Println("wrote /tmp/vented_ball.stl")
}
```

## Queries

```go
    // Is a point inside the solid?
    _, r1 := client.Must(picogk.PointInside{ObjectID: "shelled", X: 0, Y: 0, Z: 0})
    fmt.Println("inside origin:", r1) // true

    // Closest surface point to a query point:
    _, r2 := client.Must(picogk.ClosestPoint{ObjectID: "shelled", X: 50, Y: 0, Z: 0})
    fmt.Println("closest:", r2)

    // Surface normal at a point:
    _, r3 := client.Must(picogk.SurfaceNormal{ObjectID: "shelled", X: 12, Y: 0, Z: 0})
    fmt.Println("normal:", r3)

    // Volume (fast):
    _, r4 := client.Must(picogk.GetVolume{ObjectID: "shelled"})
    fmt.Println("volume:", r4)

    // Bounding box:
    _, r5 := client.Must(picogk.GetBoundingBox{ObjectID: "shelled"})
    fmt.Println("bbox:", r5)
```

## Next steps

- [Intermediate 1 — Implicit modeling →](../intermediate/01-implicit-modeling.md)