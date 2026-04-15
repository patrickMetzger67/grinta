import 'dart:math';
import 'dart:math' as math;

class _RectangleCandidate {
  final FieldCornerGps topLeft;
  final FieldCornerGps topRight;
  final FieldCornerGps bottomRight;
  final FieldCornerGps bottomLeft;
  final double score;

  _RectangleCandidate({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
    required this.score,
  });
}

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
    final maxValue = math.max(a, b);
    if (maxValue == 0) return 0.0;
    return (a - b).abs() / maxValue;
  }



  FieldGeometry? computeGeometry() {
    if (!isComplete) return null;

    final points = <FieldCornerGps>[
      topLeft!,
      topRight!,
      bottomLeft!,
      bottomRight!,
    ];

    final candidates = _buildCandidateRectangles(points);

    if (candidates.isEmpty) {
      print('Impossible de construire FootballFieldGps : aucun rectangle cohérent trouvé.');
      return null;
    }

    // On prend le meilleur candidat : diagonales les plus proches,
    // puis côtés opposés les plus proches.
    candidates.sort((a, b) => a.score.compareTo(b.score));
    final best = candidates.first;

    final tl = best.topLeft;
    final tr = best.topRight;
    final br = best.bottomRight;
    final bl = best.bottomLeft;

    final topWidth = FieldCornerGps.distanceMeters(tl, tr);
    final rightLength = FieldCornerGps.distanceMeters(tr, br);
    final bottomWidth = FieldCornerGps.distanceMeters(bl, br);
    final leftLength = FieldCornerGps.distanceMeters(tl, bl);

    final diagonal1 = FieldCornerGps.distanceMeters(tl, br);
    final diagonal2 = FieldCornerGps.distanceMeters(tr, bl);

    final avgHorizontal = (topWidth + bottomWidth) / 2.0;
    final avgVertical = (leftLength + rightLength) / 2.0;

    final avgLength = math.max(avgHorizontal, avgVertical);
    final avgWidth = math.min(avgHorizontal, avgVertical);

    final topBottomDiffRatio = _relativeDifference(topWidth, bottomWidth);
    final leftRightDiffRatio = _relativeDifference(leftLength, rightLength);
    final diagonalDiffRatio = _relativeDifference(diagonal1, diagonal2);

    const maxOppositeSideDifferenceRatio = 0.20;
    const maxDiagonalDifferenceRatio = 0.20;

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

    if (!oppositeSidesOk || !diagonalsOk || !football11SizeOk) {
      print('Rectangle trouvé mais incohérent pour un terrain :');
      print('ordered tl=${tl.latitude}, ${tl.longitude}');
      print('ordered tr=${tr.latitude}, ${tr.longitude}');
      print('ordered br=${br.latitude}, ${br.longitude}');
      print('ordered bl=${bl.latitude}, ${bl.longitude}');
      print('topWidth=$topWidth');
      print('bottomWidth=$bottomWidth');
      print('leftLength=$leftLength');
      print('rightLength=$rightLength');
      print('diagonal1=$diagonal1');
      print('diagonal2=$diagonal2');
      print('avgLength=$avgLength');
      print('avgWidth=$avgWidth');
      print('topBottomDiffRatio=$topBottomDiffRatio');
      print('leftRightDiffRatio=$leftRightDiffRatio');
      print('diagonalDiffRatio=$diagonalDiffRatio');
      return null;
    }

    final headingTopToBottomLeft = FieldCornerGps.bearingDegrees(tl, bl);
    final headingTopToBottomRight = FieldCornerGps.bearingDegrees(tr, br);
    final headingTopToBottom = _averageAnglesDegrees([
      headingTopToBottomLeft,
      headingTopToBottomRight,
    ]);

    final headingBottomToTop = (headingTopToBottom + 180) % 360;

    final headingLeftToRightTop = FieldCornerGps.bearingDegrees(tl, tr);
    final headingLeftToRightBottom = FieldCornerGps.bearingDegrees(bl, br);
    final headingLeftToRight = _averageAnglesDegrees([
      headingLeftToRightTop,
      headingLeftToRightBottom,
    ]);

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

  List<_RectangleCandidate> _buildCandidateRectangles(List<FieldCornerGps> pts) {
    if (pts.length != 4) return [];

    final candidates = <_RectangleCandidate>[];

    // 3 façons possibles de choisir les diagonales
    final pairings = [
      [0, 1, 2, 3],
      [0, 2, 1, 3],
      [0, 3, 1, 2],
    ];

    for (final pairing in pairings) {
      final a = pts[pairing[0]];
      final b = pts[pairing[1]];
      final c = pts[pairing[2]];
      final d = pts[pairing[3]];

      // On forme deux diagonales candidates : (a,b) et (c,d)
      final diagA = FieldCornerGps.distanceMeters(a, b);
      final diagB = FieldCornerGps.distanceMeters(c, d);

      // Pour un rectangle, les diagonales doivent être proches
      final diagDiff = _relativeDifference(diagA, diagB);

      // Si déjà totalement incohérent, inutile d'aller plus loin
      if (diagDiff > 0.35) continue;

      // Les 4 côtés du quadrilatère sont :
      // a-c, c-b, b-d, d-a
      final side1 = FieldCornerGps.distanceMeters(a, c);
      final side2 = FieldCornerGps.distanceMeters(c, b);
      final side3 = FieldCornerGps.distanceMeters(b, d);
      final side4 = FieldCornerGps.distanceMeters(d, a);

      final opp1 = _relativeDifference(side1, side3);
      final opp2 = _relativeDifference(side2, side4);

      final score = diagDiff + opp1 + opp2;

      final ordered = _normalizeByNorthWest([a, c, b, d]);
      if (ordered == null) continue;

      candidates.add(_RectangleCandidate(
        topLeft: ordered[0],
        topRight: ordered[1],
        bottomRight: ordered[2],
        bottomLeft: ordered[3],
        score: score,
      ));
    }

    return candidates;
  }
  List<FieldCornerGps>? _normalizeByNorthWest(List<FieldCornerGps> points) {
    if (points.length != 4) return null;

    final centerLat =
        points.map((p) => p.latitude).reduce((a, b) => a + b) / 4.0;
    final centerLng =
        points.map((p) => p.longitude).reduce((a, b) => a + b) / 4.0;

    final sorted = [...points];
    sorted.sort((a, b) {
      final angleA = math.atan2(a.latitude - centerLat, a.longitude - centerLng);
      final angleB = math.atan2(b.latitude - centerLat, b.longitude - centerLng);
      return angleA.compareTo(angleB);
    });

    // rotation pour commencer par le point le plus au nord-ouest
    int start = 0;
    for (int i = 1; i < sorted.length; i++) {
      final p = sorted[i];
      final s = sorted[start];

      if (p.latitude > s.latitude ||
          ((p.latitude - s.latitude).abs() < 1e-10 &&
              p.longitude < s.longitude)) {
        start = i;
      }
    }

    final rotated = [
      sorted[start],
      sorted[(start + 1) % 4],
      sorted[(start + 2) % 4],
      sorted[(start + 3) % 4],
    ];

    // Forcer sens horaire TL -> TR -> BR -> BL
    final cross = _crossProduct(rotated[0], rotated[1], rotated[2]);
    if (cross > 0) {
      return [rotated[0], rotated[3], rotated[2], rotated[1]];
    }

    return rotated;
  }

  double _crossProduct(FieldCornerGps a, FieldCornerGps b, FieldCornerGps c) {
    final abx = b.longitude - a.longitude;
    final aby = b.latitude - a.latitude;
    final acx = c.longitude - a.longitude;
    final acy = c.latitude - a.latitude;
    return abx * acy - aby * acx;
  }

  List<FieldCornerGps>? _orderCornersClockwise(List<FieldCornerGps> points) {
    if (points.length != 4) return null;

    // Centre géométrique
    final centerLat =
        points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    final centerLng =
        points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;

    // Tri circulaire autour du centre
    final sorted = [...points];
    sorted.sort((a, b) {
      final angleA = math.atan2(a.latitude - centerLat, a.longitude - centerLng);
      final angleB = math.atan2(b.latitude - centerLat, b.longitude - centerLng);
      return angleA.compareTo(angleB);
    });

    // On veut ensuite partir du coin "top-left" géographique :
    // plus au nord, et à égalité plus à l'ouest
    int topLeftIndex = 0;
    for (int i = 1; i < sorted.length; i++) {
      final current = sorted[i];
      final best = sorted[topLeftIndex];

      final isMoreNorth = current.latitude > best.latitude;
      final sameNorth = (current.latitude - best.latitude).abs() < 1e-10;
      final isMoreWest = current.longitude < best.longitude;

      if (isMoreNorth || (sameNorth && isMoreWest)) {
        topLeftIndex = i;
      }
    }

    // Rotation pour commencer par top-left
    final rotated = [
      sorted[topLeftIndex],
      sorted[(topLeftIndex + 1) % 4],
      sorted[(topLeftIndex + 2) % 4],
      sorted[(topLeftIndex + 3) % 4],
    ];

    // Vérifie le sens de parcours.
    // On veut : topLeft -> topRight -> bottomRight -> bottomLeft
    // Si le point suivant est plus à l'ouest que le précédent, on inverse le sens.
    if (rotated[1].longitude < rotated[3].longitude) {
      return [
        rotated[0],
        rotated[3],
        rotated[2],
        rotated[1],
      ];
    }

    return rotated;
  }

  double _averageAnglesDegrees(List<double> angles) {
    if (angles.isEmpty) return 0.0;

    double x = 0.0;
    double y = 0.0;

    for (final angle in angles) {
      final r = angle * math.pi / 180.0;
      x += math.cos(r);
      y += math.sin(r);
    }

    final result = math.atan2(y, x) * 180.0 / math.pi;
    return (result + 360.0) % 360.0;
  }
}