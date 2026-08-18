import 'dart:math' as math;

enum PlayerDetectionKind { person, ball }

class PlayerDetectionBox {
  const PlayerDetectionBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.score = 1,
    this.kind = PlayerDetectionKind.person,
    this.jerseyNumber,
    this.teamId,
    this.playerId,
    this.circular = false,
  });

  /// Normalized [0, 1] coordinates relative to the video frame.
  final double left;
  final double top;
  final double width;
  final double height;
  final double score;
  final PlayerDetectionKind kind;
  final int? jerseyNumber;
  final String? teamId;
  final String? playerId;
  final bool circular;

  PlayerDetectionBox copyWith({
    double? left,
    double? top,
    double? width,
    double? height,
    double? score,
    PlayerDetectionKind? kind,
    int? jerseyNumber,
    String? teamId,
    String? playerId,
    bool? circular,
  }) {
    return PlayerDetectionBox(
      left: left ?? this.left,
      top: top ?? this.top,
      width: width ?? this.width,
      height: height ?? this.height,
      score: score ?? this.score,
      kind: kind ?? this.kind,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      teamId: teamId ?? this.teamId,
      playerId: playerId ?? this.playerId,
      circular: circular ?? this.circular,
    );
  }
}

const double kPlayerDetectionMinScore = 0.20;
const double kBallDetectionMinScore = 0.12;

/// A single player in a wide shot is small. Huge boxes are almost always
/// a group, the crowd, or the whole pitch.
const double kMaxPlayerBoxArea = 0.08;
const double kMinPlayerBoxArea = 0.00032;
const double kMaxPlayerBoxWidth = 0.18;
const double kMaxPlayerBoxHeight = 0.50;

const double kMaxBallBoxArea = 0.016;
const double kMinBallBoxArea = 0.00006;
const double kMaxBallBoxSide = 0.16;

/// Associated-player tracking: keep a walking / running player locked
/// frame-to-frame. IoU can drop when YOLO resizes the box; nearest same-team
/// (or unlabeled) person within [kAssociatedTrackMaxCenterDistance] still
/// follows.
const double kAssociatedTrackMinIou = 0.15;
const double kAssociatedTrackMaxCenterDistance = 0.28;

PlayerDetectionKind? detectionKindForCocoClass(String label) {
  switch (label.toLowerCase().trim()) {
    case 'person':
      return PlayerDetectionKind.person;
    case 'sports ball':
    case 'ball':
    case 'football':
    case 'soccer ball':
      return PlayerDetectionKind.ball;
    default:
      return null;
  }
}

PlayerDetectionBox? playerBoxFromPixelRect({
  required double x,
  required double y,
  required double width,
  required double height,
  required double imageWidth,
  required double imageHeight,
  double score = 1,
  double minScore = kPlayerDetectionMinScore,
}) {
  if (imageWidth <= 0 || imageHeight <= 0 || width <= 0 || height <= 0) {
    return null;
  }
  if (score < minScore) return null;
  return PlayerDetectionBox(
    left: (x / imageWidth).clamp(0.0, 1.0),
    top: (y / imageHeight).clamp(0.0, 1.0),
    width: (width / imageWidth).clamp(0.0, 1.0),
    height: (height / imageHeight).clamp(0.0, 1.0),
    score: score,
  );
}

List<double>? cocoBboxToList(dynamic bbox) {
  if (bbox is List && bbox.length >= 4) {
    final values = <double>[];
    for (var i = 0; i < 4; i++) {
      final value = bbox[i];
      if (value is! num) return null;
      values.add(value.toDouble());
    }
    return values;
  }
  return null;
}

List<PlayerDetectionBox> playerBoxesFromCocoPredictions({
  required List<dynamic> predictions,
  required double imageWidth,
  required double imageHeight,
}) {
  final boxes = <PlayerDetectionBox>[];
  for (final raw in predictions) {
    if (raw is! Map) continue;
    final label = '${raw['class'] ?? raw['label'] ?? ''}';
    final kind = detectionKindForCocoClass(label);
    if (kind == null) continue;
    final score = (raw['score'] as num?)?.toDouble() ?? 0;
    final bbox = cocoBboxToList(raw['bbox']);
    if (bbox == null) continue;
    final box = playerBoxFromPixelRect(
      x: bbox[0],
      y: bbox[1],
      width: bbox[2],
      height: bbox[3],
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      score: score,
      minScore: kind == PlayerDetectionKind.ball
          ? kBallDetectionMinScore
          : kPlayerDetectionMinScore,
    );
    if (box == null) continue;
    boxes.add(
      PlayerDetectionBox(
        left: box.left,
        top: box.top,
        width: box.width,
        height: box.height,
        score: box.score,
        kind: kind,
        jerseyNumber: parseJerseyNumber(raw['jerseyNumber']),
        teamId: raw['teamId']?.toString(),
        circular: kind == PlayerDetectionKind.ball,
      ),
    );
  }
  return filterPlausibleDetections(boxes);
}

bool isPlausiblePlayerBox(PlayerDetectionBox box) {
  final area = box.width * box.height;
  if (area < kMinPlayerBoxArea || area > kMaxPlayerBoxArea) return false;
  if (box.width > kMaxPlayerBoxWidth || box.height > kMaxPlayerBoxHeight) {
    return false;
  }
  final aspect = box.width / box.height;
  return aspect >= 0.20 && aspect <= 1.15;
}

bool isPlausibleBallBox(PlayerDetectionBox box) {
  final area = box.width * box.height;
  if (area < kMinBallBoxArea || area > kMaxBallBoxArea) return false;
  if (box.width > kMaxBallBoxSide || box.height > kMaxBallBoxSide) {
    return false;
  }
  final aspect = box.width / box.height;
  return aspect >= 0.55 && aspect <= 1.8;
}

List<PlayerDetectionBox> filterPlausibleDetections(
  List<PlayerDetectionBox> boxes,
) {
  return boxes
      .where(
        (box) => box.kind == PlayerDetectionKind.ball
            ? isPlausibleBallBox(box)
            : isPlausiblePlayerBox(box),
      )
      .toList(growable: false);
}

/// Axis-aligned green-band of the video frame (0–1), not a homography.
/// Used as a stable scale for feet → 105×68 m / minimap mapping.
class PitchRegion {
  const PitchRegion({
    required this.top,
    required this.bottom,
    this.left = 0,
    this.right = 1,
  });

  final double top;
  final double bottom;
  final double left;
  final double right;

  bool containsY(double y) => y >= top && y <= bottom;

  @override
  bool operator ==(Object other) {
    return other is PitchRegion &&
        other.top == top &&
        other.bottom == bottom &&
        other.left == left &&
        other.right == right;
  }

  @override
  int get hashCode => Object.hash(top, bottom, left, right);
}

/// Convex image quad of the grass (0–1), for a perspective map to the
/// 105×68 m pitch. Far = top of the green, near = bottom (sideline camera).
class PitchQuad {
  const PitchQuad({
    required this.farLeft,
    required this.farRight,
    required this.nearLeft,
    required this.nearRight,
  });

  final ({double x, double y}) farLeft;
  final ({double x, double y}) farRight;
  final ({double x, double y}) nearLeft;
  final ({double x, double y}) nearRight;

  PitchRegion get bounds {
    final xs = <double>[farLeft.x, farRight.x, nearLeft.x, nearRight.x];
    final ys = <double>[farLeft.y, farRight.y, nearLeft.y, nearRight.y];
    xs.sort();
    ys.sort();
    return PitchRegion(
      top: ys.first,
      bottom: ys.last,
      left: xs.first,
      right: xs.last,
    );
  }

  bool get isUsable {
    final box = bounds;
    final farW = (farRight.x - farLeft.x).abs();
    final nearW = (nearRight.x - nearLeft.x).abs();
    final height = (nearLeft.y + nearRight.y) / 2 - (farLeft.y + farRight.y) / 2;
    return farW >= 0.12 &&
        nearW >= 0.18 &&
        height >= 0.16 &&
        farLeft.x < farRight.x - 0.08 &&
        nearLeft.x < nearRight.x - 0.08 &&
        (box.right - box.left) >= 0.20 &&
        (box.bottom - box.top) >= 0.18;
  }

  @override
  bool operator ==(Object other) {
    return other is PitchQuad &&
        other.farLeft == farLeft &&
        other.farRight == farRight &&
        other.nearLeft == nearLeft &&
        other.nearRight == nearRight;
  }

  @override
  int get hashCode => Object.hash(farLeft, farRight, nearLeft, nearRight);
}

PitchQuad pitchQuadFromRegion(PitchRegion pitch) {
  return PitchQuad(
    farLeft: (x: pitch.left, y: pitch.top),
    farRight: (x: pitch.right, y: pitch.top),
    nearLeft: (x: pitch.left, y: pitch.bottom),
    nearRight: (x: pitch.right, y: pitch.bottom),
  );
}

double _cross2d(double ax, double ay, double bx, double by) => ax * by - ay * bx;

/// Maps an image point (0–1) into pitch UV (0–1 length, 0–1 width).
/// Inverse bilinear interpolation of the grass quad.
({double u, double v})? imagePointToPitchUv({
  required double x,
  required double y,
  required PitchQuad quad,
}) {
  final ax = quad.farLeft.x;
  final ay = quad.farLeft.y;
  final ex = quad.farRight.x - ax;
  final ey = quad.farRight.y - ay;
  final fx = quad.nearLeft.x - ax;
  final fy = quad.nearLeft.y - ay;
  final gx = ax - quad.farRight.x + quad.nearRight.x - quad.nearLeft.x;
  final gy = ay - quad.farRight.y + quad.nearRight.y - quad.nearLeft.y;
  final hx = x - ax;
  final hy = y - ay;

  final k2 = _cross2d(gx, gy, fx, fy);
  final k1 = _cross2d(ex, ey, fx, fy) + _cross2d(hx, hy, gx, gy);
  final k0 = _cross2d(hx, hy, ex, ey);

  final candidates = <double>[];
  if (k2.abs() < 1e-8) {
    if (k1.abs() < 1e-8) return null;
    candidates.add(-k0 / k1);
  } else {
    final disc = k1 * k1 - 4 * k2 * k0;
    if (disc < 0) return null;
    final root = math.sqrt(disc);
    candidates.add((-k1 - root) / (2 * k2));
    candidates.add((-k1 + root) / (2 * k2));
  }

  ({double u, double v})? best;
  var bestPenalty = 1e9;
  for (final v in candidates) {
    final denomX = ex + gx * v;
    final denomY = ey + gy * v;
    final u = denomX.abs() >= denomY.abs() && denomX.abs() > 1e-8
        ? (hx - fx * v) / denomX
        : denomY.abs() > 1e-8
            ? (hy - fy * v) / denomY
            : null;
    if (u == null) continue;
    final inside = u >= -0.08 && u <= 1.08 && v >= -0.08 && v <= 1.08;
    final penalty = (u < 0 ? -u : 0) +
        (u > 1 ? u - 1 : 0) +
        (v < 0 ? -v : 0) +
        (v > 1 ? v - 1 : 0);
    if (!inside && penalty > 0.2) continue;
    if (penalty < bestPenalty) {
      bestPenalty = penalty;
      best = (u: u.clamp(0.0, 1.0), v: v.clamp(0.0, 1.0));
    }
  }
  return best;
}

/// Least-squares line `x = a + b*y` for grass left/right edges.
({double a, double b})? fitImageLineXOfY(List<double> ys, List<double> xs) {
  final n = ys.length;
  if (n < 2 || n != xs.length) return null;
  var sumY = 0.0;
  var sumX = 0.0;
  var sumYy = 0.0;
  var sumYx = 0.0;
  for (var i = 0; i < n; i++) {
    sumY += ys[i];
    sumX += xs[i];
    sumYy += ys[i] * ys[i];
    sumYx += ys[i] * xs[i];
  }
  final denom = n * sumYy - sumY * sumY;
  if (denom.abs() < 1e-10) {
    return (a: sumX / n, b: 0);
  }
  final b = (n * sumYx - sumY * sumX) / denom;
  final a = (sumX - b * sumY) / n;
  return (a: a, b: b);
}

double _lineXAtY(({double a, double b}) line, double y) => line.a + line.b * y;

/// Grass quad from the green silhouette: left/right touchlines are fitted
/// across the band (perspective taper), not the axis-aligned green AABB.
PitchQuad? estimatePitchQuad({
  required List<int> rgba,
  required int width,
  required int height,
}) {
  final region = estimatePitchRegion(
    rgba: rgba,
    width: width,
    height: height,
  );
  if (region == null) return null;

  final y0 = (region.top * height).floor().clamp(0, height - 1);
  final y1 = ((region.bottom * height).ceil() - 1).clamp(0, height - 1);
  final step = math.max(1, ((y1 - y0) / 28).round());
  final leftXs = <double>[];
  final rightXs = <double>[];
  final ys = <double>[];
  for (var y = y0; y <= y1; y += step) {
    var left = -1;
    var right = -1;
    for (var x = 0; x < width; x++) {
      final o = (y * width + x) * 4;
      if (!isFieldGreenPixel(rgba[o], rgba[o + 1], rgba[o + 2])) continue;
      if (left < 0) left = x;
      right = x;
    }
    if (left < 0 || right - left < width * 0.08) continue;
    leftXs.add(left / width);
    rightXs.add((right + 1) / width);
    ys.add((y + 0.5) / height);
  }

  PitchQuad fallback() {
    final rect = pitchQuadFromRegion(region);
    return rect;
  }

  if (ys.length < 4) {
    final rect = fallback();
    return rect.isUsable ? rect : null;
  }

  final leftLine = fitImageLineXOfY(ys, leftXs);
  final rightLine = fitImageLineXOfY(ys, rightXs);
  if (leftLine == null || rightLine == null) {
    final rect = fallback();
    return rect.isUsable ? rect : null;
  }

  final farY = ys.first;
  final nearY = ys.last;
  final quad = PitchQuad(
    farLeft: (
      x: _lineXAtY(leftLine, farY).clamp(0.0, 1.0),
      y: farY,
    ),
    farRight: (
      x: _lineXAtY(rightLine, farY).clamp(0.0, 1.0),
      y: farY,
    ),
    nearLeft: (
      x: _lineXAtY(leftLine, nearY).clamp(0.0, 1.0),
      y: nearY,
    ),
    nearRight: (
      x: _lineXAtY(rightLine, nearY).clamp(0.0, 1.0),
      y: nearY,
    ),
  );
  if (quad.isUsable) return quad;
  final rect = fallback();
  return rect.isUsable ? rect : null;
}

PitchRegion? estimatePitchRegion({
  required List<int> rgba,
  required int width,
  required int height,
}) {
  if (width < 8 || height < 8 || rgba.length < width * height * 4) {
    return null;
  }

  var bestStart = -1;
  var bestEnd = -1;
  var bestLen = 0;
  var runStart = -1;
  for (var y = 0; y < height; y++) {
    var green = 0;
    var samples = 0;
    for (var x = 0; x < width; x += 2) {
      final o = (y * width + x) * 4;
      samples++;
      if (isFieldGreenPixel(rgba[o], rgba[o + 1], rgba[o + 2])) green++;
    }
    final onPitch = samples > 0 && green / samples >= 0.28;
    if (onPitch) {
      if (runStart < 0) runStart = y;
    } else if (runStart >= 0) {
      final len = y - runStart;
      if (len > bestLen) {
        bestLen = len;
        bestStart = runStart;
        bestEnd = y - 1;
      }
      runStart = -1;
    }
  }
  if (runStart >= 0 && height - runStart > bestLen) {
    bestStart = runStart;
    bestEnd = height - 1;
    bestLen = height - runStart;
  }
  if (bestLen < height * 0.18 || bestStart < 0) return null;

  var leftCol = width;
  var rightCol = -1;
  final bandRows = bestEnd - bestStart + 1;
  for (var x = 0; x < width; x += 2) {
    var green = 0;
    for (var y = bestStart; y <= bestEnd; y += 2) {
      final o = (y * width + x) * 4;
      if (isFieldGreenPixel(rgba[o], rgba[o + 1], rgba[o + 2])) green++;
    }
    final samples = (bandRows / 2).ceil();
    if (samples > 0 && green / samples >= 0.28) {
      if (x < leftCol) leftCol = x;
      if (x > rightCol) rightCol = x;
    }
  }
  return PitchRegion(
    top: bestStart / height,
    bottom: (bestEnd + 1) / height,
    left: leftCol >= width ? 0 : leftCol / width,
    right: rightCol < 0 ? 1 : (rightCol + 1) / width,
  );
}

double detectionAnchorY(PlayerDetectionBox box) {
  if (box.kind == PlayerDetectionKind.ball) {
    return box.top + box.height / 2;
  }
  return box.top + box.height * 0.92;
}

bool boxStandsOnPitch(PlayerDetectionBox box, PitchRegion? pitch) {
  final y = detectionAnchorY(box).clamp(0.0, 1.0);
  final x = (box.left + box.width / 2).clamp(0.0, 1.0);
  if (pitch != null) {
    if (x < pitch.left - 0.03 || x > pitch.right + 0.03) return false;
    return y >= pitch.top + 0.008 && y <= pitch.bottom + 0.03;
  }
  return y >= 0.22;
}

bool boxIntrudesStands(PlayerDetectionBox box, PitchRegion? pitch) {
  if (box.kind != PlayerDetectionKind.person || pitch == null) return false;
  if (box.top >= pitch.top - 0.03) return false;
  final above = pitch.top - box.top;
  return above > box.height * 0.22 || box.height > 0.26;
}

bool hasPlausiblePlayerScale(PlayerDetectionBox box) {
  if (box.kind != PlayerDetectionKind.person) return true;
  final feet = (box.top + box.height).clamp(0.05, 1.0);
  final expected = 0.026 + 0.20 * feet;
  return box.height >= expected * 0.32 && box.height <= expected * 2.4;
}

bool feetHaveGrassSupport({
  required PlayerDetectionBox box,
  required List<int> rgba,
  required int width,
  required int height,
}) {
  if (box.kind != PlayerDetectionKind.person) return true;
  if (width < 8 || height < 8 || rgba.length < width * height * 4) {
    return true;
  }
  final cx = ((box.left + box.width / 2) * width).round();
  final feetY = (detectionAnchorY(box) * height).round();
  var green = 0;
  var total = 0;
  final rx = (width * 0.02).round().clamp(2, 12);
  final ry = (height * 0.03).round().clamp(2, 14);
  for (var y = feetY - 1; y <= feetY + ry; y++) {
    for (var x = cx - rx; x <= cx + rx; x++) {
      if (x < 0 || y < 0 || x >= width || y >= height) continue;
      total++;
      final o = (y * width + x) * 4;
      if (isFieldGreenPixel(rgba[o], rgba[o + 1], rgba[o + 2])) green++;
    }
  }
  if (total == 0) return false;
  return green / total >= 0.16;
}

List<PlayerDetectionBox> rejectCrowdBoxes(List<PlayerDetectionBox> boxes) {
  final people = boxes
      .where((box) => box.kind == PlayerDetectionKind.person)
      .toList(growable: false);
  final crowd = <PlayerDetectionBox>{};
  for (var i = 0; i < people.length; i++) {
    final a = people[i];
    if (a.top + a.height > 0.44) continue;
    var neighbors = 0;
    final acx = a.left + a.width / 2;
    final acy = a.top + a.height / 2;
    for (var j = 0; j < people.length; j++) {
      if (i == j) continue;
      final b = people[j];
      final dx = acx - (b.left + b.width / 2);
      final dy = acy - (b.top + b.height / 2);
      if (dx * dx + dy * dy < 0.012) neighbors++;
    }
    if (neighbors >= 3) crowd.add(a);
  }

  final upper = people.where((box) => box.top + box.height < 0.34).toList();
  if (upper.length >= 6) {
    crowd.addAll(upper);
  }
  if (crowd.isEmpty) return boxes;
  return boxes.where((box) => !crowd.contains(box)).toList(growable: false);
}

List<PlayerDetectionBox> keepMatchSheetDetections({
  required List<PlayerDetectionBox> boxes,
  PitchRegion? pitch,
  List<int>? rgba,
  int? sampleWidth,
  int? sampleHeight,
  int? team1KitColor,
  int? team2KitColor,
  int? refereeKitColor,
}) {
  final filtered = filterPlausibleDetections(boxes).where((box) {
    if (!boxStandsOnPitch(box, pitch) || !hasPlausiblePlayerScale(box)) {
      return false;
    }
    if (boxIntrudesStands(box, pitch)) return false;
    if (rgba == null || sampleWidth == null || sampleHeight == null) {
      return true;
    }
    if (looksLikeMatchOfficial(
      box: box,
      rgba: rgba,
      width: sampleWidth,
      height: sampleHeight,
      refereeKitColor: refereeKitColor,
      team1KitColor: team1KitColor,
      team2KitColor: team2KitColor,
    )) {
      return false;
    }
    return feetHaveGrassSupport(
      box: box,
      rgba: rgba,
      width: sampleWidth,
      height: sampleHeight,
    );
  }).toList(growable: false);
  return rejectCrowdBoxes(filtered);
}

double detectionCenterDistance(PlayerDetectionBox a, PlayerDetectionBox b) {
  final dx = (a.left + a.width / 2) - (b.left + b.width / 2);
  final dy = (a.top + a.height / 2) - (b.top + b.height / 2);
  return math.sqrt(dx * dx + dy * dy);
}

double detectionBoxIou(PlayerDetectionBox a, PlayerDetectionBox b) {
  final ax2 = a.left + a.width;
  final ay2 = a.top + a.height;
  final bx2 = b.left + b.width;
  final by2 = b.top + b.height;
  final left = a.left > b.left ? a.left : b.left;
  final top = a.top > b.top ? a.top : b.top;
  final right = ax2 < bx2 ? ax2 : bx2;
  final bottom = ay2 < by2 ? ay2 : by2;
  final interW = right - left;
  final interH = bottom - top;
  if (interW <= 0 || interH <= 0) return 0;
  final inter = interW * interH;
  final union = a.width * a.height + b.width * b.height - inter;
  if (union <= 0) return 0;
  return inter / union;
}

bool detectionsOverlap(PlayerDetectionBox a, PlayerDetectionBox b) {
  if (detectionBoxIou(a, b) > 0.15) return true;
  bool centerInside(PlayerDetectionBox inner, PlayerDetectionBox outer) {
    final cx = inner.left + inner.width / 2;
    final cy = inner.top + inner.height / 2;
    return cx >= outer.left &&
        cx <= outer.left + outer.width &&
        cy >= outer.top &&
        cy <= outer.top + outer.height;
  }

  return centerInside(a, b) || centerInside(b, a);
}

PlayerDetectionBox? playerBoxFromNormalizedDrag({
  required double x1,
  required double y1,
  required double x2,
  required double y2,
}) {
  return playerBoxFromNormalizedCircle(
    cx: x1,
    cy: y1,
    edgeX: x2,
    edgeY: y2,
  );
}

/// Circle from a center click to a drag edge, in normalized video coordinates.
///
/// [aspectRatio] is frame width / height so the stored box draws as a
/// visual circle, not an oval stretched by the frame.
PlayerDetectionBox? playerBoxFromNormalizedCircle({
  required double cx,
  required double cy,
  required double edgeX,
  required double edgeY,
  double aspectRatio = 16 / 9,
}) {
  final aspect = aspectRatio <= 0 ? 16 / 9 : aspectRatio;
  final nx = edgeX - cx;
  final ny = edgeY - cy;
  final radiusX = math.sqrt(nx * nx + (ny * ny) / (aspect * aspect));
  if (radiusX < 0.008) return null;
  final radiusY = radiusX * aspect;
  final left = (cx - radiusX).clamp(0.0, 1.0);
  final top = (cy - radiusY).clamp(0.0, 1.0);
  final right = (cx + radiusX).clamp(0.0, 1.0);
  final bottom = (cy + radiusY).clamp(0.0, 1.0);
  final width = right - left;
  final height = bottom - top;
  if (width < 0.008 || height < 0.008) return null;
  return PlayerDetectionBox(
    left: left,
    top: top,
    width: width,
    height: height,
    circular: true,
  );
}

PlayerDetectionBox defaultManualPlayerFrame() {
  return const PlayerDetectionBox(
    left: 0.44,
    top: 0.36,
    width: 0.12,
    height: 0.24,
  );
}

PlayerDetectionBox moveManualPlayerFrame(
  PlayerDetectionBox box, {
  double dx = 0,
  double dy = 0,
}) {
  final width = box.width.clamp(0.02, 1.0);
  final height = box.height.clamp(0.02, 1.0);
  return box.copyWith(
    left: (box.left + dx).clamp(0.0, 1.0 - width),
    top: (box.top + dy).clamp(0.0, 1.0 - height),
    width: width,
    height: height,
  );
}

PlayerDetectionBox resizeManualPlayerFrame(
  PlayerDetectionBox box, {
  double dWidth = 0,
  double dHeight = 0,
  double minWidth = 0.03,
  double minHeight = 0.05,
  double maxWidth = 0.40,
  double maxHeight = 0.70,
}) {
  final width = (box.width + dWidth).clamp(minWidth, maxWidth);
  final height = (box.height + dHeight).clamp(minHeight, maxHeight);
  final left = (box.left + (box.width - width) / 2).clamp(0.0, 1.0 - width);
  final top = (box.top + (box.height - height) / 2).clamp(0.0, 1.0 - height);
  return box.copyWith(
    left: left,
    top: top,
    width: width,
    height: height,
  );
}

List<PlayerDetectionBox> assignTeamIdsFromKit({
  required List<PlayerDetectionBox> boxes,
  required List<int> rgba,
  required int width,
  required int height,
  required int? team1KitColor,
  required int? team2KitColor,
  required String? team1Id,
  required String? team2Id,
}) {
  if (boxes.isEmpty) return boxes;
  return boxes.map((box) {
    if (box.kind != PlayerDetectionKind.person) return box;
    if ((box.teamId ?? '').trim().isNotEmpty) return box;
    final teamId = suggestedTeamIdFromKitSample(
      box: box,
      rgba: rgba,
      width: width,
      height: height,
      team1KitColor: team1KitColor,
      team2KitColor: team2KitColor,
      team1Id: team1Id,
      team2Id: team2Id,
    );
    return teamId == null ? box : box.copyWith(teamId: teamId);
  }).toList(growable: false);
}

String? suggestedTeamIdFromKitSample({
  required PlayerDetectionBox box,
  required List<int> rgba,
  required int width,
  required int height,
  required int? team1KitColor,
  required int? team2KitColor,
  required String? team1Id,
  required String? team2Id,
}) {
  if (team1KitColor == null && team2KitColor == null) return null;
  final ratio1 = team1KitColor == null
      ? 0.0
      : boxPixelRatio(
          box: box,
          rgba: rgba,
          width: width,
          height: height,
          test: (r, g, b) => isKitColorPixel(r, g, b, team1KitColor),
        );
  final ratio2 = team2KitColor == null
      ? 0.0
      : boxPixelRatio(
          box: box,
          rgba: rgba,
          width: width,
          height: height,
          test: (r, g, b) => isKitColorPixel(r, g, b, team2KitColor),
        );
  if (ratio1 < 0.05 && ratio2 < 0.05) return null;
  if (ratio1 >= ratio2) return team1Id;
  return team2Id;
}

List<PlayerDetectionBox> mergeManualPlayerBoxes(
  List<PlayerDetectionBox> automatic,
  List<PlayerDetectionBox> manual,
) {
  if (manual.isEmpty) return automatic;
  final kept = automatic.where((box) {
    return !manual.any((labeled) => detectionBoxIou(box, labeled) > 0.22);
  });
  return [...kept, ...manual];
}

class AssociatedPlayerTrack {
  const AssociatedPlayerTrack({
    required this.box,
    this.missed = 0,
  });

  final PlayerDetectionBox box;
  final int missed;
}

bool associatedTrackTeamsCompatible({
  required String? lockTeamId,
  required String? boxTeamId,
}) {
  final lockTeam = lockTeamId?.trim() ?? '';
  final boxTeam = boxTeamId?.trim() ?? '';
  if (lockTeam.isEmpty || boxTeam.isEmpty) return true;
  return lockTeam == boxTeam;
}

int associatedTrackTeamRank({
  required String? lockTeamId,
  required String? boxTeamId,
}) {
  final lockTeam = lockTeamId?.trim() ?? '';
  final boxTeam = boxTeamId?.trim() ?? '';
  if (lockTeam.isNotEmpty && lockTeam == boxTeam) return 0;
  if (boxTeam.isEmpty) return 1;
  return 2;
}

/// Keeps a locked player identity on the next frame.
/// Prefers IoU, then the nearest same-team (or unlabeled) person.
/// Unmatched locks stay visible for a few frames instead of being re-labeled.
({List<PlayerDetectionBox> boxes, List<AssociatedPlayerTrack> tracks})
persistAssociatedPlayers({
  required List<PlayerDetectionBox> current,
  required List<AssociatedPlayerTrack> tracks,
  double minIou = kAssociatedTrackMinIou,
  double maxCenterDistance = kAssociatedTrackMaxCenterDistance,
  bool requireSameTeam = false,
  int maxMissed = 18,
}) {
  if (tracks.isEmpty) {
    return (boxes: current, tracks: const <AssociatedPlayerTrack>[]);
  }

  bool eligible(PlayerDetectionBox lock, PlayerDetectionBox box) {
    if (lock.kind != PlayerDetectionKind.person) return false;
    if (box.kind != PlayerDetectionKind.person) return false;
    if (!associatedTrackTeamsCompatible(
      lockTeamId: lock.teamId,
      boxTeamId: box.teamId,
    )) {
      return false;
    }
    if (requireSameTeam &&
        (lock.teamId ?? '').trim().isNotEmpty &&
        (box.teamId ?? '').trim().isNotEmpty &&
        lock.teamId!.trim() != box.teamId!.trim()) {
      return false;
    }
    return true;
  }

  final usedTracks = <int>{};
  final usedBoxes = <int>{};
  final next = List<PlayerDetectionBox>.from(current);
  final nextTracks = <AssociatedPlayerTrack>[];

  void assign(int trackIndex, int boxIndex) {
    final lock = tracks[trackIndex].box;
    final matched = next[boxIndex].copyWith(
      playerId: lock.playerId,
      teamId: lock.teamId ?? next[boxIndex].teamId,
      jerseyNumber: lock.jerseyNumber ?? next[boxIndex].jerseyNumber,
      circular: lock.circular || next[boxIndex].circular,
    );
    next[boxIndex] = matched;
    nextTracks.add(AssociatedPlayerTrack(box: matched));
    usedTracks.add(trackIndex);
    usedBoxes.add(boxIndex);
  }

  final pairs = <({double iou, double distance, int rank, int track, int box})>[];
  for (var t = 0; t < tracks.length; t++) {
    for (var b = 0; b < current.length; b++) {
      if (!eligible(tracks[t].box, current[b])) continue;
      final distance = detectionCenterDistance(tracks[t].box, current[b]);
      if (distance > maxCenterDistance) continue;
      final iou = detectionBoxIou(tracks[t].box, current[b]);
      if (iou < minIou) continue;
      pairs.add((
        iou: iou,
        distance: distance,
        rank: associatedTrackTeamRank(
          lockTeamId: tracks[t].box.teamId,
          boxTeamId: current[b].teamId,
        ),
        track: t,
        box: b,
      ));
    }
  }
  pairs.sort((a, b) {
    final iouCmp = b.iou.compareTo(a.iou);
    if (iouCmp != 0) return iouCmp;
    final rankCmp = a.rank.compareTo(b.rank);
    if (rankCmp != 0) return rankCmp;
    return a.distance.compareTo(b.distance);
  });
  for (final pair in pairs) {
    if (usedTracks.contains(pair.track) || usedBoxes.contains(pair.box)) {
      continue;
    }
    assign(pair.track, pair.box);
  }

  final leftovers = <({double distance, int rank, int track, int box})>[];
  for (var t = 0; t < tracks.length; t++) {
    if (usedTracks.contains(t)) continue;
    for (var b = 0; b < current.length; b++) {
      if (usedBoxes.contains(b)) continue;
      if (!eligible(tracks[t].box, current[b])) continue;
      final distance = detectionCenterDistance(tracks[t].box, current[b]);
      if (distance > maxCenterDistance) continue;
      leftovers.add((
        distance: distance,
        rank: associatedTrackTeamRank(
          lockTeamId: tracks[t].box.teamId,
          boxTeamId: current[b].teamId,
        ),
        track: t,
        box: b,
      ));
    }
  }
  leftovers.sort((a, b) {
    final rankCmp = a.rank.compareTo(b.rank);
    if (rankCmp != 0) return rankCmp;
    return a.distance.compareTo(b.distance);
  });
  for (final pair in leftovers) {
    if (usedTracks.contains(pair.track) || usedBoxes.contains(pair.box)) {
      continue;
    }
    assign(pair.track, pair.box);
  }

  for (var t = 0; t < tracks.length; t++) {
    if (usedTracks.contains(t)) continue;
    final missed = tracks[t].missed + 1;
    if (missed > maxMissed) continue;
    nextTracks.add(AssociatedPlayerTrack(box: tracks[t].box, missed: missed));
    next.add(tracks[t].box);
  }

  return (boxes: next, tracks: nextTracks);
}

List<PlayerDetectionBox> mergeDetectionBoxes(
  List<PlayerDetectionBox> primary,
  List<PlayerDetectionBox> extra,
) {
  final merged = <PlayerDetectionBox>[...primary];
  for (final box in extra) {
    final overlaps = merged.any(
      (existing) =>
          existing.kind == box.kind && detectionsOverlap(existing, box),
    );
    if (!overlaps) merged.add(box);
  }
  return merged;
}

int? parseJerseyNumber(Object? raw) {
  if (raw is num) {
    final value = raw.round();
    if (value >= 1 && value <= 99) return value;
    return null;
  }
  final digits = '${raw ?? ''}'.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  final clipped = digits.length > 2 ? digits.substring(0, 2) : digits;
  final value = int.tryParse(clipped);
  if (value == null || value < 1 || value > 99) return null;
  return value;
}

Set<int> detectedJerseyNumbers(Iterable<PlayerDetectionBox> boxes) {
  return {
    for (final box in boxes)
      if (box.kind == PlayerDetectionKind.person && box.jerseyNumber != null)
        box.jerseyNumber!,
  };
}

bool isRosterJerseyDetected(int? number, Set<int> detectedNumbers) {
  return number != null && detectedNumbers.contains(number);
}

String rosterJerseyKey(String teamId, int number) => '${teamId.trim()}|$number';

Set<String> detectedTeamJerseyKeys(Iterable<PlayerDetectionBox> boxes) {
  return {
    for (final box in boxes)
      if (box.kind == PlayerDetectionKind.person &&
          box.jerseyNumber != null &&
          (box.teamId ?? '').trim().isNotEmpty)
        rosterJerseyKey(box.teamId!, box.jerseyNumber!),
  };
}

bool isRosterJerseyOnTeam({
  required String teamId,
  required int? number,
  required Set<String> keys,
}) {
  if (number == null || teamId.trim().isEmpty) return false;
  return keys.contains(rosterJerseyKey(teamId, number));
}

Set<String> associatedPlayerIds(Iterable<PlayerDetectionBox> boxes) {
  return {
    for (final box in associatedDetectionBoxes(boxes)) box.playerId!.trim(),
  };
}

List<PlayerDetectionBox> associatedDetectionBoxes(
  Iterable<PlayerDetectionBox> boxes,
) {
  return [
    for (final box in boxes)
      if (box.kind == PlayerDetectionKind.person &&
          (box.playerId ?? '').trim().isNotEmpty)
        box,
  ];
}

/// Video overlay: associated players only, and only while paused.
/// Balls and unlabeled people are never drawn — they stay internal.
List<PlayerDetectionBox> overlayDetectionBoxes(
  Iterable<PlayerDetectionBox> boxes, {
  required bool showAssociatedPlayers,
}) {
  if (!showAssociatedPlayers) return const <PlayerDetectionBox>[];
  return associatedDetectionBoxes(boxes);
}

/// 2D minimap: associated players that have a jersey number. No balls.
List<PlayerDetectionBox> minimapDetectionBoxes(
  Iterable<PlayerDetectionBox> boxes,
) {
  return [
    for (final box in associatedDetectionBoxes(boxes))
      if (box.jerseyNumber != null) box,
  ];
}

List<PlayerDetectionBox> styledBallBoxes(Iterable<PlayerDetectionBox> boxes) {
  return [
    for (final box in boxes)
      if (box.kind == PlayerDetectionKind.ball)
        box.circular ? box : box.copyWith(circular: true),
  ];
}

bool isRosterPlayerAssociated(String? playerId, Set<String> associatedIds) {
  final id = playerId?.trim() ?? '';
  return id.isNotEmpty && associatedIds.contains(id);
}

List<PlayerDetectionBox> carryJerseyNumbers(
  List<PlayerDetectionBox> previous,
  List<PlayerDetectionBox> current,
) {
  if (previous.isEmpty) return current;
  return current.map((box) {
    if (box.jerseyNumber != null || box.kind != PlayerDetectionKind.person) {
      return box;
    }
    PlayerDetectionBox? best;
    var bestIou = 0.25;
    for (final prior in previous) {
      if (prior.jerseyNumber == null || prior.kind != box.kind) continue;
      final iou = detectionBoxIou(prior, box);
      if (iou > bestIou) {
        bestIou = iou;
        best = prior;
      }
    }
    return best == null ? box : box.copyWith(jerseyNumber: best.jerseyNumber);
  }).toList(growable: false);
}

bool isFieldGreenPixel(int r, int g, int b) {
  if (g <= 70 || g <= r + 12 || g <= b + 8) return false;
  // Referee lime / fluorescent yellow is bright Y+G, not pitch grass.
  if (r >= 110 &&
      g >= 155 &&
      b <= 110 &&
      (r + g) >= 280 &&
      (g - b) >= 45) {
    return false;
  }
  return true;
}

bool isSoccerBallPixel(int r, int g, int b) {
  if (isFieldGreenPixel(r, g, b)) return false;
  final maxc = r > g ? (r > b ? r : b) : (g > b ? g : b);
  final minc = r < g ? (r < b ? r : b) : (g < b ? g : b);
  final lum = 0.30 * r + 0.59 * g + 0.11 * b;
  final whitish = lum >= 145 && (maxc - minc) <= 72;
  final yellowish = r >= 160 && g >= 135 && b <= 120 && lum >= 130;
  return whitish || yellowish;
}

bool isBlueKitPixel(int r, int g, int b) {
  return b >= 52 && b > r + 12 && b > g + 6 && g < 155;
}

bool isWhiteKitPixel(int r, int g, int b) {
  if (isFieldGreenPixel(r, g, b)) return false;
  final maxc = r > g ? (r > b ? r : b) : (g > b ? g : b);
  final minc = r < g ? (r < b ? r : b) : (g < b ? g : b);
  final lum = 0.30 * r + 0.59 * g + 0.11 * b;
  return lum >= 175 && (maxc - minc) <= 52;
}

bool isRedKitPixel(int r, int g, int b) {
  return r >= 120 && r > g + 25 && r > b + 20 && g < 140;
}

bool isDarkKitPixel(int r, int g, int b) {
  if (isFieldGreenPixel(r, g, b)) return false;
  final lum = 0.30 * r + 0.59 * g + 0.11 * b;
  return lum <= 62;
}

bool isOfficialFluorescentPixel(int r, int g, int b) {
  if (b > 145 || g < 135 || r < 95) return false;
  if (isFieldGreenPixel(r, g, b)) return false;
  if (g < r - 70) return false;
  return (r + g) >= 260 && (g - b) >= 30 && (r + g - 2 * b) >= 90;
}

bool isYellowishKitColor(int? argb) {
  if (argb == null) return false;
  final r = (argb >> 16) & 0xff;
  final g = (argb >> 8) & 0xff;
  final b = argb & 0xff;
  return r >= 160 && g >= 125 && b <= 130 && r + g > b * 2.3;
}

bool isKitColorPixel(int r, int g, int b, int kitColor) {
  if (isFieldGreenPixel(r, g, b)) return false;
  final kr = (kitColor >> 16) & 0xff;
  final kg = (kitColor >> 8) & 0xff;
  final kb = kitColor & 0xff;
  final kitLum = 0.30 * kr + 0.59 * kg + 0.11 * kb;
  if (kitLum >= 200 && (kr - kb).abs() < 45) {
    return isWhiteKitPixel(r, g, b);
  }
  if (kitLum <= 48) return isDarkKitPixel(r, g, b);
  if (kb > kr + 20 && kb > kg + 10) return isBlueKitPixel(r, g, b);
  if (kr > kg + 20 && kr > kb + 20) return isRedKitPixel(r, g, b);
  final dist =
      (r - kr) * (r - kr) + (g - kg) * (g - kg) + (b - kb) * (b - kb);
  final maxDist = isYellowishKitColor(kitColor) ? 140 * 140 : 95 * 95;
  return dist <= maxDist;
}

bool isRefereeKitPixel(int r, int g, int b, int kitColor) {
  if (isYellowishKitColor(kitColor) && isOfficialFluorescentPixel(r, g, b)) {
    return true;
  }
  return isKitColorPixel(r, g, b, kitColor);
}

List<int> effectiveKitColors({int? team1KitColor, int? team2KitColor}) {
  final selected = <int>[
    if (team1KitColor != null) team1KitColor,
    if (team2KitColor != null) team2KitColor,
  ];
  if (selected.isNotEmpty) return selected;
  return const <int>[0xFF1E4DB7, 0xFFFFFFFF, 0xFFC62828, 0xFF111111];
}

double boxPixelRatio({
  required PlayerDetectionBox box,
  required List<int> rgba,
  required int width,
  required int height,
  required bool Function(int r, int g, int b) test,
  double leftInset = 0.18,
  double rightInset = 0.82,
  double topInset = 0.12,
  double bottomInset = 0.62,
}) {
  if (width < 8 || height < 8 || rgba.length < width * height * 4) {
    return 0;
  }
  final left = ((box.left + box.width * leftInset) * width).round();
  final right = ((box.left + box.width * rightInset) * width).round();
  final top = ((box.top + box.height * topInset) * height).round();
  final bottom = ((box.top + box.height * bottomInset) * height).round();
  var hits = 0;
  var total = 0;
  for (var y = top; y <= bottom; y += 1) {
    for (var x = left; x <= right; x += 1) {
      if (x < 0 || y < 0 || x >= width || y >= height) continue;
      total++;
      final o = (y * width + x) * 4;
      if (test(rgba[o], rgba[o + 1], rgba[o + 2])) hits++;
    }
  }
  if (total == 0) return 0;
  return hits / total;
}

bool looksLikeMatchOfficial({
  required PlayerDetectionBox box,
  required List<int> rgba,
  required int width,
  required int height,
  int? refereeKitColor,
  int? team1KitColor,
  int? team2KitColor,
}) {
  if (box.kind != PlayerDetectionKind.person) return false;
  if (refereeKitColor != null) {
    return boxPixelRatio(
          box: box,
          rgba: rgba,
          width: width,
          height: height,
          topInset: 0.08,
          bottomInset: 0.78,
          test: (r, g, b) => isRefereeKitPixel(r, g, b, refereeKitColor),
        ) >=
        0.05;
  }
  if (isYellowishKitColor(team1KitColor) || isYellowishKitColor(team2KitColor)) {
    return false;
  }
  return boxPixelRatio(
        box: box,
        rgba: rgba,
        width: width,
        height: height,
        test: isOfficialFluorescentPixel,
      ) >=
      0.09;
}

class _PixelBlob {
  const _PixelBlob({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
    required this.count,
  });

  final int minX;
  final int minY;
  final int maxX;
  final int maxY;
  final int count;

  int get width => maxX - minX + 1;
  int get height => maxY - minY + 1;
}

List<_PixelBlob> _findConnectedBlobs(
  List<bool> mask,
  int width,
  int height, {
  int dilate = 0,
}) {
  var current = mask;
  for (var step = 0; step < dilate; step++) {
    final next = List<bool>.from(current);
    for (var y = 1; y < height - 1; y++) {
      for (var x = 1; x < width - 1; x++) {
        if (current[y * width + x]) continue;
        if (current[y * width + x - 1] ||
            current[y * width + x + 1] ||
            current[(y - 1) * width + x] ||
            current[(y + 1) * width + x]) {
          next[y * width + x] = true;
        }
      }
    }
    current = next;
  }

  final visited = List<bool>.filled(width * height, false);
  final blobs = <_PixelBlob>[];
  final stack = <int>[];
  for (var start = 0; start < current.length; start++) {
    if (!current[start] || visited[start]) continue;
    var minX = width;
    var minY = height;
    var maxX = 0;
    var maxY = 0;
    var count = 0;
    stack.add(start);
    visited[start] = true;
    while (stack.isNotEmpty) {
      final i = stack.removeLast();
      final x = i % width;
      final y = i ~/ width;
      count++;
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
      for (final n in <int>[i - 1, i + 1, i - width, i + width]) {
        if (n < 0 || n >= current.length || visited[n] || !current[n]) {
          continue;
        }
        final nx = n % width;
        final ny = n ~/ width;
        if ((nx - x).abs() + (ny - y).abs() != 1) continue;
        visited[n] = true;
        stack.add(n);
      }
    }
    blobs.add(
      _PixelBlob(
        minX: minX,
        minY: minY,
        maxX: maxX,
        maxY: maxY,
        count: count,
      ),
    );
  }
  return blobs;
}

double _greenRingRatio({
  required List<int> rgba,
  required int width,
  required int height,
  required _PixelBlob blob,
}) {
  var greenNeighbors = 0;
  var ring = 0;
  for (var y = blob.minY - 2; y <= blob.maxY + 2; y++) {
    for (var x = blob.minX - 2; x <= blob.maxX + 2; x++) {
      if (x < 0 || y < 0 || x >= width || y >= height) continue;
      if (x >= blob.minX &&
          x <= blob.maxX &&
          y >= blob.minY &&
          y <= blob.maxY) {
        continue;
      }
      ring++;
      final o = (y * width + x) * 4;
      if (isFieldGreenPixel(rgba[o], rgba[o + 1], rgba[o + 2])) {
        greenNeighbors++;
      }
    }
  }
  if (ring == 0) return 0;
  return greenNeighbors / ring;
}

bool _looksLikePitchMarking(_PixelBlob blob, int imageWidth, int imageHeight) {
  if (blob.width > imageWidth * 0.20 || blob.height > imageHeight * 0.52) {
    return true;
  }
  if (blob.width < 5 && blob.height > blob.width * 3.4) return true;
  if (blob.height < 7 && blob.width > blob.height * 3.2) return true;
  return false;
}

/// Recovers kit-colored players that the generic person model often misses.
List<PlayerDetectionBox> detectPlayersFromKitColors({
  required List<int> rgba,
  required int width,
  required int height,
  int? team1KitColor,
  int? team2KitColor,
}) {
  if (width < 16 || height < 16 || rgba.length < width * height * 4) {
    return const <PlayerDetectionBox>[];
  }

  final kits = effectiveKitColors(
    team1KitColor: team1KitColor,
    team2KitColor: team2KitColor,
  );
  final boxes = <PlayerDetectionBox>[];
  void addFromMask(
    List<bool> mask, {
    required int dilate,
    required int minCount,
    required int minHeight,
  }) {
    for (final blob in _findConnectedBlobs(mask, width, height, dilate: dilate)) {
      if (blob.count < minCount || blob.width < 3 || blob.height < minHeight) {
        continue;
      }
      if (_looksLikePitchMarking(blob, width, height)) continue;
      final fill = blob.count / (blob.width * blob.height);
      if (fill < 0.24) continue;
      final aspect = blob.width / blob.height;
      if (aspect < 0.18 || aspect > 1.15) continue;
      if (blob.minY < height * 0.10) continue;
      if ((blob.minY + blob.maxY) / 2 < height * 0.16) continue;
      if (_greenRingRatio(
            rgba: rgba,
            width: width,
            height: height,
            blob: blob,
          ) <
          0.10) {
        continue;
      }
      final padX = blob.width * 0.22;
      final padY = blob.height * 0.28;
      final box = playerBoxFromPixelRect(
        x: blob.minX - padX,
        y: blob.minY - padY,
        width: blob.width + padX * 2,
        height: blob.height + padY * 2,
        imageWidth: width.toDouble(),
        imageHeight: height.toDouble(),
      );
      if (box == null) continue;
      final player = PlayerDetectionBox(
        left: box.left,
        top: box.top,
        width: box.width,
        height: box.height,
        score: 0.55,
        kind: PlayerDetectionKind.person,
      );
      if (isPlausiblePlayerBox(player)) boxes.add(player);
    }
  }

  for (final kit in kits) {
    final mask = List<bool>.filled(width * height, false);
    var hits = 0;
    for (var i = 0; i < width * height; i++) {
      final o = i * 4;
      final match = isKitColorPixel(rgba[o], rgba[o + 1], rgba[o + 2], kit);
      mask[i] = match;
      if (match) hits++;
    }
    if (hits < 8) continue;
    final kr = (kit >> 16) & 0xff;
    final kg = (kit >> 8) & 0xff;
    final kb = kit & 0xff;
    final kitLum = 0.30 * kr + 0.59 * kg + 0.11 * kb;
    final dilate = kb > kr + 15 ? 2 : 1;
    addFromMask(
      mask,
      dilate: dilate,
      minCount: kitLum >= 200 ? 10 : 8,
      minHeight: 6,
    );
  }
  return boxes;
}

/// Finds small bright circular blobs (soccer ball) in an RGBA frame.
List<PlayerDetectionBox> detectSoccerBallsFromRgba({
  required List<int> rgba,
  required int width,
  required int height,
}) {
  if (width < 8 || height < 8 || rgba.length < width * height * 4) {
    return const <PlayerDetectionBox>[];
  }

  final mask = List<bool>.filled(width * height, false);
  for (var i = 0; i < width * height; i++) {
    final o = i * 4;
    mask[i] = isSoccerBallPixel(rgba[o], rgba[o + 1], rgba[o + 2]);
  }

  final dilated = List<bool>.from(mask);
  for (var y = 1; y < height - 1; y++) {
    for (var x = 1; x < width - 1; x++) {
      if (mask[y * width + x]) continue;
      if (mask[y * width + x - 1] ||
          mask[y * width + x + 1] ||
          mask[(y - 1) * width + x] ||
          mask[(y + 1) * width + x]) {
        dilated[y * width + x] = true;
      }
    }
  }

  final visited = List<bool>.filled(width * height, false);
  final boxes = <PlayerDetectionBox>[];
  final stack = <int>[];

  for (var start = 0; start < dilated.length; start++) {
    if (!dilated[start] || visited[start]) continue;
    var minX = width;
    var minY = height;
    var maxX = 0;
    var maxY = 0;
    var count = 0;
    var greenNeighbors = 0;
    stack.add(start);
    visited[start] = true;
    while (stack.isNotEmpty) {
      final i = stack.removeLast();
      final x = i % width;
      final y = i ~/ width;
      count++;
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
      for (final n in <int>[i - 1, i + 1, i - width, i + width]) {
        if (n < 0 || n >= dilated.length || visited[n] || !dilated[n]) {
          continue;
        }
        final nx = n % width;
        final ny = n ~/ width;
        if ((nx - x).abs() + (ny - y).abs() != 1) continue;
        visited[n] = true;
        stack.add(n);
      }
    }

    final bw = maxX - minX + 1;
    final bh = maxY - minY + 1;
    if (count < 6 || bw < 3 || bh < 3) continue;
    final boxArea = bw * bh;
    if (count / boxArea < 0.38) continue;

    for (var y = minY - 1; y <= maxY + 1; y++) {
      for (var x = minX - 1; x <= maxX + 1; x++) {
        if (x < 0 || y < 0 || x >= width || y >= height) continue;
        if (x >= minX && x <= maxX && y >= minY && y <= maxY) continue;
        final o = (y * width + x) * 4;
        if (isFieldGreenPixel(rgba[o], rgba[o + 1], rgba[o + 2])) {
          greenNeighbors++;
        }
      }
    }
    final ring = ((maxX - minX + 3) * 2) + ((maxY - minY + 3) * 2);
    if (ring > 0 && greenNeighbors / ring < 0.25) continue;

    final padX = bw * 0.25;
    final padY = bh * 0.25;
    final box = playerBoxFromPixelRect(
      x: minX - padX,
      y: minY - padY,
      width: bw + padX * 2,
      height: bh + padY * 2,
      imageWidth: width.toDouble(),
      imageHeight: height.toDouble(),
    );
    if (box == null) continue;
    final ball = PlayerDetectionBox(
      left: box.left,
      top: box.top,
      width: box.width,
      height: box.height,
      score: 0.7,
      kind: PlayerDetectionKind.ball,
      circular: true,
    );
    if (isPlausibleBallBox(ball)) boxes.add(ball);
  }
  return boxes;
}
