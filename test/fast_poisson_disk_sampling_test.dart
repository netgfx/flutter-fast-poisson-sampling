import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:fast_poisson_disk_sampling/fast_poisson_disk_sampling.dart';

void main() {
  test('adds one to input values', () {
    var p = FastPoissonDiskSampling(
        shape: Size(100, 100),
        radius: null,
        maxTries: 50,
        minDistance: 100,
        rng: null);
    List<List<double>> points = p.fill();
    expect(points.length, points.length > 0);
  });
}
