# fast_poisson_disk_sampling

Dart port of the JS library https://github.com/kchapelier/fast-2d-poisson-disk-sampling

Fast 2D Poisson Disk Sampling based on a modified Bridson algorithm.

## Basic example

```
var p = FastPoissonDiskSampling(shape: Size(500, 200), radius: 6, maxTries: 20, minDistance: 0, rng: null);
List<List<double>> points = p.fill();
```
### Result as an image

<img src="https://github.com/kchapelier/fast-2d-poisson-disk-sampling/raw/master/img/example1.png" style="image-rendering:pixelated; width:500px;"></img>

### Constructor

**new FastPoissonDiskSampling(options[, rng])**

- *options :*
  - *shape :* Size/dimensions of the grid to generate points in, required.
  - *radius :* Minimum distance between each points, required.
  - *tries :* Maximum number of tries per point, defaults to 30.
- *rng :* A function to use as random number generator, defaults to Math.random.

Note: "minDistance" can be used instead of "radius", ensuring API compatibility with [poisson-disk-sampling](https://github.com/kchapelier/poisson-disk-sampling).

```dart
var pds = new FastPoissonDiskSampling(
    shape: Size(50, 50),
    radius: 4,
    maxTries: 10
);
```

### Method

**pds.fill()**

Fill the grid with random points following the distance constraint.

Returns the entirety of the points in the grid as an array of coordinate arrays. The points are sorted in their generation order.

```dart
var points = pds.fill();

print(points[0]);
// prints something like [30, 16]
```

**pds.getAllPoints()**

Get all the points present in the grid without trying to generate any new points.

Returns the entirety of the points in the grid as an array of coordinate arrays. The points are sorted in their generation order.

```dart
var points = pds.getAllPoints();

print(points[0]);
// prints something like [30, 16]
```

**pds.addRandomPoint()**

Add a completely random point to the grid. There won't be any check on the distance constraint with the other points already present in the grid.

Returns the point as a coordinate array.

**pds.addPoint(point)**

- *point :* Point represented as a coordinate array.

Add an arbitrary point to the grid. There won't be any check on the distance constraint with the other points already present in the grid.

Returns the point added to the grid.

If the given coordinate array does not have a length of 2 or doesn't fit in the grid size, null will be returned.

```dart
pds.addPoint([20, 30]);
```

**pds.next()**

Try to generate a new point in the grid following the distance constraint.

Returns a coordinate array when a point is generated, null otherwise.

```dart
var point;

while(point = pds.next()) {
    print(point); // [x, y]
}
```

**pds.reset()**

Reinitialize the grid as well as the internal state.

When doing multiple samplings in the same grid, it is preferable to reuse the same instance of PoissonDiskSampling instead of creating a new one for each sampling.

## License

MIT