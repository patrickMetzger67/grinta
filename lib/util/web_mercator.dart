import 'dart:math' as math;

/// Web Mercator helpers aligned with Google Maps Static API projection.
class WebMercator {
  WebMercator._();

  static const double tileSize = 256.0;
  static const int maxZoom = 21;

  static double longitudeToX(double longitude, int zoom) {
    final scale = tileSize * math.pow(2.0, zoom);
    return (longitude + 180.0) / 360.0 * scale;
  }

  static double latitudeToY(double latitude, int zoom) {
    final scale = tileSize * math.pow(2.0, zoom);
    final latRad = latitude * math.pi / 180.0;
    final sinLat = math.sin(latRad).clamp(-0.9999, 0.9999);
    return (0.5 - math.log((1 + sinLat) / (1 - sinLat)) / (4 * math.pi)) *
        scale;
  }

  static ({double x, double y}) project(
    double latitude,
    double longitude,
    int zoom,
  ) {
    return (
      x: longitudeToX(longitude, zoom),
      y: latitudeToY(latitude, zoom),
    );
  }

  /// Meters represented by one pixel at [latitude] and [zoom].
  static double metersPerPixel(double latitude, int zoom) {
    return 156543.03392 *
        math.cos(latitude * math.pi / 180.0) /
        math.pow(2.0, zoom);
  }

  /// Smallest zoom so that [bounds] fit inside [width]×[height] pixels.
  static int zoomForBounds({
    required double south,
    required double west,
    required double north,
    required double east,
    required int width,
    required int height,
    int maxZoomLevel = 20,
  }) {
    if (north <= south || east <= west) {
      return maxZoomLevel.clamp(0, maxZoom);
    }

    double latRad(double lat) {
      final sin = math.sin(lat * math.pi / 180.0);
      final radX2 = math.log((1 + sin) / (1 - sin)) / 2;
      return math.max(math.min(radX2, math.pi), -math.pi) / 2;
    }

    int zoom(double mapPx, double worldPx, double fraction) {
      if (fraction <= 0 || mapPx <= 0 || worldPx <= 0) {
        return maxZoomLevel;
      }
      return (math.log(mapPx / worldPx / fraction) / math.ln2).floor();
    }

    final latFraction = (latRad(north) - latRad(south)) / math.pi;
    var lngDiff = east - west;
    if (lngDiff < 0) lngDiff += 360;
    final lngFraction = lngDiff / 360.0;

    final latZoom = zoom(height.toDouble(), tileSize, latFraction);
    final lngZoom = zoom(width.toDouble(), tileSize, lngFraction);
    return math.min(math.min(latZoom, lngZoom), maxZoomLevel).clamp(0, maxZoom);
  }
}

/// Geographic bounding box with padding helpers.
class GpsLatLngBounds {
  const GpsLatLngBounds({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  final double south;
  final double west;
  final double north;
  final double east;

  double get centerLat => (south + north) / 2.0;
  double get centerLng => (west + east) / 2.0;

  /// Expands the box by [padFraction] of its span on each side (min meters).
  GpsLatLngBounds padded({
    double padFraction = 0.12,
    double minPadMeters = 12.0,
  }) {
    final latSpan = math.max(1e-8, north - south);
    final lngSpan = math.max(1e-8, east - west);

    final metersPerDegLat = 111320.0;
    final metersPerDegLng =
        111320.0 * math.cos(centerLat * math.pi / 180.0).abs().clamp(0.2, 1.0);

    final padLat = math.max(latSpan * padFraction, minPadMeters / metersPerDegLat);
    final padLng = math.max(lngSpan * padFraction, minPadMeters / metersPerDegLng);

    return GpsLatLngBounds(
      south: (south - padLat).clamp(-85.0, 85.0),
      west: (west - padLng).clamp(-180.0, 180.0),
      north: (north + padLat).clamp(-85.0, 85.0),
      east: (east + padLng).clamp(-180.0, 180.0),
    );
  }

  static GpsLatLngBounds? fromLatLngs(
    Iterable<({double lat, double lng})> points,
  ) {
    double? minLat;
    double? maxLat;
    double? minLng;
    double? maxLng;

    for (final p in points) {
      if (p.lat.abs() > 90 || p.lng.abs() > 180) continue;
      if (p.lat == 0 && p.lng == 0) continue;
      minLat = minLat == null ? p.lat : math.min(minLat, p.lat);
      maxLat = maxLat == null ? p.lat : math.max(maxLat, p.lat);
      minLng = minLng == null ? p.lng : math.min(minLng, p.lng);
      maxLng = maxLng == null ? p.lng : math.max(maxLng, p.lng);
    }

    if (minLat == null || maxLat == null || minLng == null || maxLng == null) {
      return null;
    }

    // Degenerate cluster (single point / GPS noise): expand to ~half a pitch.
    if ((maxLat - minLat) < 1e-5 && (maxLng - minLng) < 1e-5) {
      const halfLenDeg = 55.0 / 111320.0;
      const halfWidDeg = 35.0 / 111320.0;
      return GpsLatLngBounds(
        south: minLat - halfWidDeg,
        west: minLng - halfLenDeg,
        north: maxLat + halfWidDeg,
        east: maxLng + halfLenDeg,
      );
    }

    return GpsLatLngBounds(
      south: minLat,
      west: minLng,
      north: maxLat,
      east: maxLng,
    );
  }
}
