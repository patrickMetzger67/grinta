import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/fieldGpsCorners.dart';
import 'package:grinta/model/tracker/trackerData.dart';
import 'package:grinta/util/match_heatmap_service.dart';
import 'package:grinta/util/satellite_heatmap_svg_generator.dart';
import 'package:grinta/util/web_mercator.dart';

void main() {
  group('MatchHeatmapService geolocalized guard', () {
    test('isFieldGeolocalized is true only when fieldGps is set', () {
      expect(MatchHeatmapService.isFieldGeolocalized(null), isFalse);

      const field = FootballFieldGps(
        topLeft: FieldCornerGps(latitude: 48.4220, longitude: 7.6610),
        topRight: FieldCornerGps(latitude: 48.4220, longitude: 7.6624),
        bottomLeft: FieldCornerGps(latitude: 48.4214, longitude: 7.6610),
        bottomRight: FieldCornerGps(latitude: 48.4214, longitude: 7.6624),
        fieldLengthMeters: 105,
        fieldWidthMeters: 68,
      );
      expect(MatchHeatmapService.isFieldGeolocalized(field), isTrue);
    });

    test('geolocalized path never marks satellite background', () async {
      const field = FootballFieldGps(
        topLeft: FieldCornerGps(latitude: 48.4220, longitude: 7.6610),
        topRight: FieldCornerGps(latitude: 48.4220, longitude: 7.6624),
        bottomLeft: FieldCornerGps(latitude: 48.4214, longitude: 7.6610),
        bottomRight: FieldCornerGps(latitude: 48.4214, longitude: 7.6624),
        fieldLengthMeters: 105,
        fieldWidthMeters: 68,
      );

      final bundle = await MatchHeatmapService.generateAndSaveMatchHeatmaps(
        trackerId: 't1',
        eventId: 'e1',
        fieldGps: field,
        fullSamples: const [],
        fullHeatmapPoints: [
          HeatmapPoint(xMeters: 10, yMeters: 10, timeMs: 1, intensity: 1),
          HeatmapPoint(xMeters: 20, yMeters: 20, timeMs: 2, intensity: 2),
        ],
        persist: false,
      );

      expect(bundle.usedSatelliteBackground, isFalse);
      expect(bundle.fullMatch, isNotNull);
      expect(
        bundle.fullMatch!,
        isNot(contains('data-grinta-heatmap="satellite"')),
      );
      expect(bundle.fullMatch!, contains('#2E7D32'));
    });
  });

  group('WebMercator', () {
    test('zoomForBounds returns a sensible zoom for a pitch-sized box', () {
      final bounds = GpsLatLngBounds(
        south: 48.4190,
        west: 7.6600,
        north: 48.4200,
        east: 7.6615,
      ).padded();

      final zoom = WebMercator.zoomForBounds(
        south: bounds.south,
        west: bounds.west,
        north: bounds.north,
        east: bounds.east,
        width: 640,
        height: 400,
      );

      expect(zoom, greaterThanOrEqualTo(16));
      expect(zoom, lessThanOrEqualTo(20));
    });

    test('project keeps relative ordering', () {
      const zoom = 18;
      final a = WebMercator.project(48.42, 7.66, zoom);
      final b = WebMercator.project(48.42, 7.67, zoom);
      final c = WebMercator.project(48.41, 7.66, zoom);
      expect(b.x, greaterThan(a.x));
      expect(c.y, greaterThan(a.y));
    });
  });

  group('SatelliteHeatmapSvgGenerator', () {
    test('embeds satellite marker and heatmap rects with injected image',
        () async {
      // Minimal valid JPEG (1x1) so mime detection succeeds.
      final jpeg = Uint8List.fromList(<int>[
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
        0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
        0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
        0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
        0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
        0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
        0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
        0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
        0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x03, 0xFF, 0xC4, 0x00, 0x14, 0x10, 0x01, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F, 0x00,
        0x7F, 0xFF, 0xD9,
      ]);

      final samples = <TrackerRaw>[
        for (var i = 0; i < 40; i++)
          TrackerRaw(
            trackerId: 't',
            timeMs: 1000 + i * 200,
            latitude: 48.4200 + (i % 5) * 0.00002,
            longitude: 7.6610 + (i ~/ 5) * 0.00002,
            speedMps: 2.0 + (i % 3),
          ),
      ];

      final svg = await SatelliteHeatmapSvgGenerator.generateSvg(
        samples: samples,
        satelliteImageBytes: jpeg,
        svgWidth: 640,
        svgHeight: 400,
      );

      expect(svg, isNotNull);
      expect(svg!, contains('data-grinta-heatmap="satellite"'));
      expect(svg, contains('data:image/jpeg;base64,'));
      expect(svg, contains('<rect'));
    });
  });
}
