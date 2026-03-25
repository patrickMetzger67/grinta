import 'dart:math';

class FieldGeometry {
  final double topWidthMeters;
  final double bottomWidthMeters;
  final double leftLengthMeters;
  final double rightLengthMeters;
  final double averageWidthMeters;
  final double averageLengthMeters;

  /// Orientation du terrain en degrés depuis le nord :
  /// 0 = nord, 90 = est, 180 = sud, 270 = ouest
  final double headingTopToBottom;
  final double headingBottomToTop;
  final double headingLeftToRight;
  final double headingRightToLeft;

  const FieldGeometry({
    required this.topWidthMeters,
    required this.bottomWidthMeters,
    required this.leftLengthMeters,
    required this.rightLengthMeters,
    required this.averageWidthMeters,
    required this.averageLengthMeters,
    required this.headingTopToBottom,
    required this.headingBottomToTop,
    required this.headingLeftToRight,
    required this.headingRightToLeft,
  });

  Map<String, dynamic> toMap() {
    return {
      'topWidthMeters': topWidthMeters,
      'bottomWidthMeters': bottomWidthMeters,
      'leftLengthMeters': leftLengthMeters,
      'rightLengthMeters': rightLengthMeters,
      'averageWidthMeters': averageWidthMeters,
      'averageLengthMeters': averageLengthMeters,
      'headingTopToBottom': headingTopToBottom,
      'headingBottomToTop': headingBottomToTop,
      'headingLeftToRight': headingLeftToRight,
      'headingRightToLeft': headingRightToLeft,
    };
  }
}

class FieldCornerGps {
  final double latitude;
  final double longitude;

  const FieldCornerGps({
    required this.latitude,
    required this.longitude,
  });

  factory FieldCornerGps.fromMap(Map<String, dynamic> map) {
    return FieldCornerGps(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static double distanceMeters(FieldCornerGps a, FieldCornerGps b) {
    const double earthRadius = 6371000;
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLon = _degToRad(b.longitude - a.longitude);

    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(h), sqrt(1 - h));
    return earthRadius * c;
  }

  static double bearingDegrees(FieldCornerGps from, FieldCornerGps to) {
    final lat1 = _degToRad(from.latitude);
    final lat2 = _degToRad(to.latitude);
    final dLon = _degToRad(to.longitude - from.longitude);

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) -
        sin(lat1) * cos(lat2) * cos(dLon);

    final bearing = atan2(y, x);
    return (_radToDeg(bearing) + 360) % 360;
  }

  static double _degToRad(double deg) => deg * pi / 180.0;
  static double _radToDeg(double rad) => rad * 180.0 / pi;
}

class FieldGpsCorners {
  FieldCornerGps? topLeft;
  FieldCornerGps? topRight;
  FieldCornerGps? bottomLeft;
  FieldCornerGps? bottomRight;

  FieldGpsCorners({
    this.topLeft,
    this.topRight,
    this.bottomLeft,
    this.bottomRight,
  });

  bool get isComplete =>
      topLeft != null &&
          topRight != null &&
          bottomLeft != null &&
          bottomRight != null;

  factory FieldGpsCorners.fromMap(Map<String, dynamic> map) {
    return FieldGpsCorners(
      topLeft: map['topLeft'] != null
          ? FieldCornerGps.fromMap(Map<String, dynamic>.from(map['topLeft']))
          : null,
      topRight: map['topRight'] != null
          ? FieldCornerGps.fromMap(Map<String, dynamic>.from(map['topRight']))
          : null,
      bottomLeft: map['bottomLeft'] != null
          ? FieldCornerGps.fromMap(Map<String, dynamic>.from(map['bottomLeft']))
          : null,
      bottomRight: map['bottomRight'] != null
          ? FieldCornerGps.fromMap(Map<String, dynamic>.from(map['bottomRight']))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'topLeft': topLeft?.toMap(),
      'topRight': topRight?.toMap(),
      'bottomLeft': bottomLeft?.toMap(),
      'bottomRight': bottomRight?.toMap(),
    };
  }

  FieldCornerGps _midpoint(FieldCornerGps a, FieldCornerGps b) {
    return FieldCornerGps(
      latitude: (a.latitude + b.latitude) / 2.0,
      longitude: (a.longitude + b.longitude) / 2.0,
    );
  }

  double _relativeDifference(double a, double b) {
    final maxValue = a > b ? a : b;
    if (maxValue == 0) return 0;
    return (a - b).abs() / maxValue;
  }

  FieldGeometry? computeGeometry() {
    if (!isComplete) return null;

    final tl = topLeft!;
    final tr = topRight!;
    final bl = bottomLeft!;
    final br = bottomRight!;

    // Côtés
    final topWidth = FieldCornerGps.distanceMeters(tl, tr);
    final bottomWidth = FieldCornerGps.distanceMeters(bl, br);
    final leftLength = FieldCornerGps.distanceMeters(tl, bl);
    final rightLength = FieldCornerGps.distanceMeters(tr, br);

    // Diagonales
    final diagonal1 = FieldCornerGps.distanceMeters(tl, br);
    final diagonal2 = FieldCornerGps.distanceMeters(tr, bl);

    // Moyennes brutes
    final avgHorizontal = (topWidth + bottomWidth) / 2.0;
    final avgVertical = (leftLength + rightLength) / 2.0;

    // Longueur = plus grande dimension, largeur = plus petite
    final avgLength = avgHorizontal >= avgVertical ? avgHorizontal : avgVertical;
    final avgWidth = avgHorizontal >= avgVertical ? avgVertical : avgHorizontal;

    // Vérifications de cohérence
    final topBottomDiffRatio = _relativeDifference(topWidth, bottomWidth);
    final leftRightDiffRatio = _relativeDifference(leftLength, rightLength);
    final diagonalDiffRatio = _relativeDifference(diagonal1, diagonal2);

    // Tolérances
    const maxOppositeSideDifferenceRatio = 0.15; // 15%
    const maxDiagonalDifferenceRatio = 0.12; // 12%

    // Contraintes "terrain à 11" assez larges
    const minFootball11Length = 90.0;
    const maxFootball11Length = 120.0;
    const minFootball11Width = 45.0;
    const maxFootball11Width = 90.0;

    final oppositeSidesOk =
        topBottomDiffRatio <= maxOppositeSideDifferenceRatio &&
            leftRightDiffRatio <= maxOppositeSideDifferenceRatio;

    final diagonalsOk = diagonalDiffRatio <= maxDiagonalDifferenceRatio;

    final football11SizeOk =
        avgLength >= minFootball11Length &&
            avgLength <= maxFootball11Length &&
            avgWidth >= minFootball11Width &&
            avgWidth <= maxFootball11Width;

    // Si les points ne ressemblent pas à un terrain crédible, on refuse
    if (!oppositeSidesOk || !diagonalsOk || !football11SizeOk) {
      return null;
    }

    final headingTopToBottomLeft = FieldCornerGps.bearingDegrees(tl, bl);
    final headingTopToBottomRight = FieldCornerGps.bearingDegrees(tr, br);
    final headingTopToBottom =
    _averageAnglesDegrees([headingTopToBottomLeft, headingTopToBottomRight]);

    final headingBottomToTop = (headingTopToBottom + 180) % 360;

    final headingLeftToRightTop = FieldCornerGps.bearingDegrees(tl, tr);
    final headingLeftToRightBottom = FieldCornerGps.bearingDegrees(bl, br);
    final headingLeftToRight =
    _averageAnglesDegrees([headingLeftToRightTop, headingLeftToRightBottom]);

    final headingRightToLeft = (headingLeftToRight + 180) % 360;

    return FieldGeometry(
      topWidthMeters: topWidth,
      bottomWidthMeters: bottomWidth,
      leftLengthMeters: leftLength,
      rightLengthMeters: rightLength,
      averageWidthMeters: avgWidth,
      averageLengthMeters: avgLength,
      headingTopToBottom: headingTopToBottom,
      headingBottomToTop: headingBottomToTop,
      headingLeftToRight: headingLeftToRight,
      headingRightToLeft: headingRightToLeft,
    );
  }

  static double _averageAnglesDegrees(List<double> angles) {
    final sinSum = angles.map((a) => sin(a * pi / 180.0)).reduce((a, b) => a + b);
    final cosSum = angles.map((a) => cos(a * pi / 180.0)).reduce((a, b) => a + b);

    final avg = atan2(sinSum / angles.length, cosSum / angles.length) * 180.0 / pi;
    return (avg + 360) % 360;
  }
}