import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sehati_ai/inti/layanan/layanan_rute_cerdas.dart';

void main() {
  group('SmartRouteService Tests', () {
    test('generateAthleticTrackLoop generates standard closed 400m track loop', () {
      const center = LatLng(-6.2183, 106.8022); // GBK Senayan
      final points = SmartRouteService.generateAthleticTrackLoop(center, laps: 5);

      expect(points, isNotEmpty);
      expect(points.length, greaterThanOrEqualTo(28));
      // Loop should be closed: first and last point should be identical
      expect(points.first.latitude, closeTo(points.last.latitude, 0.00001));
      expect(points.first.longitude, closeTo(points.last.longitude, 0.00001));

      // Calculate perimeter of the track loop
      double perimeterMeters = 0.0;
      const dist = Distance();
      for (int i = 0; i < points.length - 1; i++) {
        perimeterMeters += dist.as(LengthUnit.Meter, points[i], points[i + 1]);
      }

      // Standard IAAF 400m track should be approximately ~400 meters perimeter (+/- 5%)
      expect(perimeterMeters, inInclusiveRange(380.0, 420.0));
    });

    test('checkHikingAvailability detects urban area when user is in central Jakarta', () {
      const jakartaMonas = LatLng(-6.1754, 106.8272); // Monas Jakarta Pusat
      final result = SmartRouteService.checkHikingAvailability(jakartaMonas, radiusKm: 20.0);

      // Jakarta Pusat is in an urban plain, far from mountains (>25 km)
      expect(result.isHikingNearby, isFalse);
      expect(result.distanceToNearestKm, greaterThan(25.0));
      expect(result.nearestSpot, isNotNull);
      expect(result.nearestDestinations, isNotEmpty);
    });

    test('checkHikingAvailability detects nearby hiking when user is in Bogor / Sentul', () {
      const sentul = LatLng(-6.5900, 106.9050); // Near Sentul / Gunung Pancar
      final result = SmartRouteService.checkHikingAvailability(sentul, radiusKm: 20.0);

      expect(result.isHikingNearby, isTrue);
      expect(result.distanceToNearestKm, lessThanOrEqualTo(5.0));
      expect(result.nearestSpot?.name.contains('Sentul') == true || result.nearestSpot?.name.contains('Pancar') == true, isTrue);
    });

    test('checkHikingAvailability detects urban residential when user is in Cileunyi Bandung', () {
      // User in Cileunyi Bandung residential area (~12 km from Mt Manglayang summit)
      const cileunyiBandung = LatLng(-6.9400, 107.7400);
      final result = SmartRouteService.checkHikingAvailability(cileunyiBandung);

      // Should be false with default 3.0 km threshold, detecting it as urbanResidential
      expect(result.isHikingNearby, isFalse);
      expect(SmartRouteService.detectEnvironment(cileunyiBandung), AreaEnvironment.urbanResidential);
    });
  });
}
