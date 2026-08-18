import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:grinta/model/fieldGpsCorners.dart';
import 'package:grinta/model/tracker/trackerData.dart';
import 'package:grinta/services/analyze_player_detection.dart';
import 'package:grinta/services/analyze_video_analysis.dart';
import 'package:grinta/widget/gps_field.dart';

const double kDebugVideoPitchMinimapAspect = 105 / 68;
const Color kDebugVideoPitchMinimapTeam1Fallback = Color(0xFF1E88E5);
const Color kDebugVideoPitchMinimapTeam2Fallback = Color(0xFFE53935);
const Color kDebugVideoPitchMinimapUnknownTeam = Color(0xFFFFA000);

/// Same virtual 105×68 pitch as the schematic heatmap field
/// (kept local so the web debug screen does not import `dart:io`).
const FootballFieldGps kDebugVideoHeatmapPitchField = FootballFieldGps(
  topLeft: FieldCornerGps(latitude: 0, longitude: 0),
  topRight: FieldCornerGps(latitude: 0, longitude: 0.001),
  bottomLeft: FieldCornerGps(latitude: -0.0006, longitude: 0),
  bottomRight: FieldCornerGps(latitude: -0.0006, longitude: 0.001),
  fieldLengthMeters: 105,
  fieldWidthMeters: 68,
);

const EdgeInsets kDebugVideoMinimapPitchPadding = EdgeInsets.all(5);

Rect debugVideoMinimapFieldRect(Size size) {
  if (size.isEmpty) return Rect.zero;
  final points = kDebugVideoHeatmapPitchField.cornersToPitchMeters();
  if (points.length != 4) {
    return Rect.fromLTWH(0, 0, size.width, size.height).deflate(5);
  }
  final fitted = fitPointsToMinimapCanvas(
    points: points,
    size: size,
    padding: kDebugVideoMinimapPitchPadding,
  );
  if (fitted.length != 4) {
    return Rect.fromLTWH(0, 0, size.width, size.height).deflate(5);
  }
  final xs = fitted.map((point) => point.dx);
  final ys = fitted.map((point) => point.dy);
  return Rect.fromLTRB(
    xs.reduce(math.min),
    ys.reduce(math.min),
    xs.reduce(math.max),
    ys.reduce(math.max),
  );
}

List<Offset> fitPointsToMinimapCanvas({
  required List<Offset> points,
  required Size size,
  required EdgeInsets padding,
}) {
  if (points.isEmpty) return const <Offset>[];
  final minX = points.map((point) => point.dx).reduce(math.min);
  final maxX = points.map((point) => point.dx).reduce(math.max);
  final minY = points.map((point) => point.dy).reduce(math.min);
  final maxY = points.map((point) => point.dy).reduce(math.max);
  final rawWidth = maxX - minX;
  final rawHeight = maxY - minY;
  if (rawWidth <= 0 || rawHeight <= 0) {
    return List<Offset>.filled(points.length, Offset(size.width / 2, size.height / 2));
  }
  final availableWidth = size.width - padding.horizontal;
  final availableHeight = size.height - padding.vertical;
  if (availableWidth <= 0 || availableHeight <= 0) {
    return List<Offset>.filled(points.length, Offset.zero);
  }
  final scale = math.min(availableWidth / rawWidth, availableHeight / rawHeight);
  final dx = padding.left + (availableWidth - rawWidth * scale) / 2;
  final dy = padding.top + (availableHeight - rawHeight * scale) / 2;
  return [
    for (final point in points)
      Offset((point.dx - minX) * scale + dx, (point.dy - minY) * scale + dy),
  ];
}

class DebugVideoPitchMinimap extends StatelessWidget {
  const DebugVideoPitchMinimap({
    super.key,
    required this.detections,
    this.analysisSamples = const <PlayerDistanceSample>[],
    this.atMs = 0,
    this.preferLiveDetections = false,
    this.pitch,
    this.team1Id,
    this.team2Id,
    this.team1KitColor,
    this.team2KitColor,
    this.rosterJerseyByPlayerId = const <String, int>{},
    this.rosterTeamByPlayerId = const <String, String>{},
    this.width = 208,
  });

  final List<PlayerDetectionBox> detections;
  final List<PlayerDistanceSample> analysisSamples;
  final int atMs;
  final bool preferLiveDetections;
  final PitchRegion? pitch;
  final String? team1Id;
  final String? team2Id;
  final int? team1KitColor;
  final int? team2KitColor;
  final Map<String, int> rosterJerseyByPlayerId;
  final Map<String, String> rosterTeamByPlayerId;
  final double width;

  @override
  Widget build(BuildContext context) {
    final height = width / kDebugVideoPitchMinimapAspect;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x66FFFFFF)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GpsFieldWidget(
                field: kDebugVideoHeatmapPitchField,
                drawHeatmap: false,
                drawGoals: false,
                padding: kDebugVideoMinimapPitchPadding,
                borderWidth: math.max(1.0, width * 0.008),
              ),
              CustomPaint(
                painter: DebugVideoPitchMinimapPainter(
                  markers: minimapMarkersAt(
                    samples: analysisSamples,
                    atMs: atMs,
                    detections: detections,
                    pitch: pitch,
                    preferLiveDetections: preferLiveDetections,
                    rosterJerseyByPlayerId: rosterJerseyByPlayerId,
                    rosterTeamByPlayerId: rosterTeamByPlayerId,
                  ),
                  team1Id: team1Id,
                  team2Id: team2Id,
                  team1KitColor: team1KitColor,
                  team2KitColor: team2KitColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DebugVideoPitchMinimapPainter extends CustomPainter {
  const DebugVideoPitchMinimapPainter({
    required this.markers,
    this.team1Id,
    this.team2Id,
    this.team1KitColor,
    this.team2KitColor,
  });

  final List<MinimapPlayerMarker> markers;
  final String? team1Id;
  final String? team2Id;
  final int? team1KitColor;
  final int? team2KitColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final field = debugVideoMinimapFieldRect(size);
    if (field.isEmpty) return;

    // marker.x / marker.y are 0–1 along heatmap length / width:
    // x = 0 left goal, y = 0 far sideline (top of GpsFieldWidget).
    for (final marker in markers) {
      final offset = Offset(
        field.left + marker.x * field.width,
        field.top + marker.y * field.height,
      );
      _paintPlayer(canvas, offset, marker, field.shortestSide * 0.055);
    }
  }

  void _paintPlayer(
    Canvas canvas,
    Offset center,
    MinimapPlayerMarker marker,
    double radius,
  ) {
    final color = _colorForTeam(marker.teamId);
    final r = radius.clamp(6.0, 11.0);
    canvas.drawCircle(
      center,
      r + 0.8,
      Paint()..color = const Color(0xCC000000),
    );
    canvas.drawCircle(center, r, Paint()..color = color);

    final number = marker.jerseyNumber;
    if (number == null) return;

    final label = '$number';
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color.computeLuminance() > 0.55
              ? const Color(0xFF111111)
              : Colors.white,
          fontSize: label.length > 1 ? r * 1.05 : r * 1.15,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  Color _colorForTeam(String? teamId) {
    final id = teamId?.trim() ?? '';
    final team1 = team1Id?.trim() ?? '';
    final team2 = team2Id?.trim() ?? '';
    if (id.isNotEmpty && id == team1) {
      return team1KitColor == null
          ? kDebugVideoPitchMinimapTeam1Fallback
          : Color(team1KitColor!);
    }
    if (id.isNotEmpty && id == team2) {
      return team2KitColor == null
          ? kDebugVideoPitchMinimapTeam2Fallback
          : Color(team2KitColor!);
    }
    return kDebugVideoPitchMinimapUnknownTeam;
  }

  @override
  bool shouldRepaint(covariant DebugVideoPitchMinimapPainter oldDelegate) {
    return !_sameMinimapMarkers(oldDelegate.markers, markers) ||
        oldDelegate.team1Id != team1Id ||
        oldDelegate.team2Id != team2Id ||
        oldDelegate.team1KitColor != team1KitColor ||
        oldDelegate.team2KitColor != team2KitColor;
  }
}

bool _sameMinimapMarkers(
  List<MinimapPlayerMarker> a,
  List<MinimapPlayerMarker> b,
) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final left = a[i];
    final right = b[i];
    if (left.playerId != right.playerId ||
        left.x != right.x ||
        left.y != right.y ||
        left.teamId != right.teamId ||
        left.jerseyNumber != right.jerseyNumber) {
      return false;
    }
  }
  return true;
}
