import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/core/utils/geo_distance.dart';

/// Konversi koordinat → jarak (dipakai filter "laporan terdekat" & Watch Zone).
void main() {
  group('GeoDistance.meters', () {
    test('titik sama = 0 meter', () {
      expect(GeoDistance.meters(-7.4478, 112.7183, -7.4478, 112.7183),
          closeTo(0, 0.001));
    });

    test('1 derajat lintang ≈ 111 km', () {
      final d = GeoDistance.meters(0, 0, 1, 0);
      expect(d, closeTo(111195, 500));
    });

    test('simetris (a→b == b→a)', () {
      final ab = GeoDistance.meters(-7.44, 112.71, -7.45, 112.72);
      final ba = GeoDistance.meters(-7.45, 112.72, -7.44, 112.71);
      expect(ab, closeTo(ba, 0.001));
    });
  });

  group('GeoDistance.format', () {
    test('< 1km dalam meter', () => expect(GeoDistance.format(120), '120 m'));
    test('>= 1km dalam km', () => expect(GeoDistance.format(2000), '2.0 km'));
  });
}
