library fast_poisson_disk_sampling;

import 'dart:math' as math;
import 'dart:typed_data';

import 'dart:ui';

/// FastPoissonDiskSampling class
class FastPoissonDiskSampling {
  double width = 0;
  double height = 0;
  int radius = 0;
  int maxTries = 0;
  var epsilon = 2e-14;
  var piDiv3 = math.pi / 3;
  Function rng = () => {};

  int squaredRadius = 0;
  double radiusPlusEpsilon = 0;
  double cellSize = 0;

  double angleIncrement = 0;
  double angleIncrementOnSuccess = 0;
  int triesIncrementOnSuccess = 0;

  List<dynamic> processList = [];
  List<List<double>> samplePoints = [];

  List<List<int>> neighbourhood = [
    [0, 0],
    [0, -1],
    [-1, 0],
    [1, 0],
    [0, 1],
    [-1, -1],
    [1, -1],
    [-1, 1],
    [1, 1],
    [0, -2],
    [-2, 0],
    [2, 0],
    [0, 2],
    [-1, -2],
    [1, -2],
    [-2, -1],
    [2, -1],
    [-2, 1],
    [2, 1],
    [-1, 2],
    [1, 2]
  ];

  var neighbourhoodLength = 0;

  // cache grid

  List<int> gridShape = [];

  Map<String, dynamic> grid = {};

  /// FastPoissonDiskSampling constructor
  FastPoissonDiskSampling({Size shape = const Size(100, 100), int? radius, int maxTries = 30, int minDistance = 0, Function? rng}) {
    this.rng = rng ?? random;
    this.width = shape.width;
    this.height = shape.height;
    this.radius = radius ?? minDistance;
    this.squaredRadius = this.radius * this.radius;
    this.radiusPlusEpsilon = this.radius + epsilon;
    this.cellSize = this.radius * math.sqrt1_2;
    this.angleIncrement = math.pi * 2 / this.maxTries;
    this.angleIncrementOnSuccess = piDiv3 + epsilon;
    this.triesIncrementOnSuccess = (this.angleIncrementOnSuccess / this.angleIncrement).ceil();
    this.maxTries = math.max(3, (maxTries).ceil());
    neighbourhoodLength = neighbourhood.length;

    /// cache grid
    gridShape = [(this.width / this.cellSize).ceil(), (this.height / this.cellSize).ceil()];

    grid = tinyNDArray(this.gridShape);
  }

  double random() {
    return math.Random().nextDouble();
  }

  Map<String, dynamic> tinyNDArray(List<int> gridShape) {
    var dimensions = gridShape.length;
    int totalLength = 1;
    List<int> stride = List.filled(dimensions, 0);
    int dimension;

    for (dimension = dimensions; dimension > 0; dimension--) {
      stride[dimension - 1] = totalLength;
      totalLength = totalLength * gridShape[dimension - 1];
    }

    return {"stride": stride, "data": new Uint32List(totalLength)};
  }

  /// Add a totally random point in the grid
  List<dynamic> addRandomPoint() {
    return directAddPoint([this.rng() * this.width, this.rng() * this.height, this.rng() * math.pi * 2, 0]);
  }

  /// Add a given point to the grid
  List<dynamic>? addPoint(List<dynamic> point) {
    var valid = point.length == 2 && point[0] >= 0 && point[0] < this.width && point[1] >= 0 && point[1] < this.height;

    return valid ? this.directAddPoint([point[0], point[1], this.rng() * math.pi * 2, 0]) : null;
  }

  /// Add a given point to the grid, without any check
  List<dynamic> directAddPoint(List<dynamic> point) {
    List<double> coordsOnly = [point[0], point[1]];
    this.processList.add(point);
    this.samplePoints.add(coordsOnly);
    var internalArrayIndex = ((point[0] / this.cellSize).toInt() | 0) * this.grid["stride"][0] + ((point[1] / this.cellSize).toInt() | 0);
    this.grid["data"][internalArrayIndex] = this.samplePoints.length; // store the point reference

    return coordsOnly;
  }

  /// Check whether a given point is in the neighbourhood of existing points
  bool inNeighbourhood(List<dynamic> point) {
    var dimensionNumber = 2, stride = this.grid["stride"], neighbourIndex, internalArrayIndex, dimension, currentDimensionValue, existingPoint;

    for (neighbourIndex = 0; neighbourIndex < neighbourhoodLength; neighbourIndex++) {
      internalArrayIndex = 0;

      for (dimension = 0; dimension < dimensionNumber; dimension++) {
        currentDimensionValue = ((point[dimension] / this.cellSize).toInt() | 0) + neighbourhood[neighbourIndex][dimension];

        if (currentDimensionValue < 0 || currentDimensionValue >= this.gridShape[dimension]) {
          internalArrayIndex = -1;
          break;
        }

        internalArrayIndex += currentDimensionValue * stride[dimension];
      }

      if (internalArrayIndex != -1 && this.grid["data"][internalArrayIndex] != 0) {
        existingPoint = this.samplePoints[this.grid["data"][internalArrayIndex] - 1];

        if (math.pow(point[0] - existingPoint[0], 2) + math.pow(point[1] - existingPoint[1], 2) < this.squaredRadius) {
          return true;
        }
      }
    }

    return false;
  }

  /// Try to generate a new point in the grid, returns null if it wasn't possible
  List<dynamic>? next() {
    var tries, currentPoint, currentAngle, newPoint;

    while (this.processList.length > 0) {
      int index = (this.processList.length * this.rng()).toInt();

      currentPoint = this.processList[index];
      currentAngle = currentPoint[2];
      tries = currentPoint[3];

      if (tries == 0) {
        currentAngle = currentAngle + (this.rng() - 0.5) * piDiv3 * 4;
      }

      for (; tries < this.maxTries; tries++) {
        newPoint = [currentPoint[0] + math.cos(currentAngle) * this.radiusPlusEpsilon, currentPoint[1] + math.sin(currentAngle) * this.radiusPlusEpsilon, currentAngle, 0];

        if ((newPoint[0] >= 0 && newPoint[0] < this.width) && (newPoint[1] >= 0 && newPoint[1] < this.height) && !this.inNeighbourhood(newPoint)) {
          currentPoint[2] = currentAngle + this.angleIncrementOnSuccess + this.rng() * this.angleIncrement;
          currentPoint[3] = tries + this.triesIncrementOnSuccess;
          return this.directAddPoint(newPoint);
        }

        currentAngle = currentAngle + this.angleIncrement;
      }

      if (tries >= this.maxTries) {
        var r = this.processList.removeLast();
        if (index < this.processList.length) {
          this.processList[index] = r;
        }
      }
    }

    return null;
  }

  /// Automatically fill the grid, adding a random point to start the process if needed.
  /// Will block the thread, probably best to use it in a Future or Isolate.
  List<List<double>> fill() {
    if (this.samplePoints.length == 0) {
      this.addRandomPoint();
    }

    while (this.next() != null) {}

    return this.samplePoints;
  }

  ///Get all the points in the grid.
  List<dynamic> getAllPoints() {
    return this.samplePoints;
  }

  /// Reinitialize the grid as well as the internal state
  void reset() {
    var gridData = this.grid["data"];
    int i;

    // reset the cache grid
    for (i = 0; i < gridData.length; i++) {
      gridData[i] = 0;
    }

    // new array for the samplePoints as it is passed by reference to the outside
    this.samplePoints = [];

    // reset the internal state
    this.processList.length = 0;
  }
}
