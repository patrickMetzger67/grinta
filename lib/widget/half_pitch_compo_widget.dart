import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../model/compoType.dart';
import '../util/app_theme.dart';

const double _fieldWidthM = 68.0;
const double _halfLengthM = 52.5;

const double _centerCircleRadiusM = 9.15;
const double _penaltyAreaWidthM = 40.3;
const double _penaltyAreaDepthM = 16.5;
const double _goalAreaWidthM = 18.32;
const double _goalAreaDepthM = 5.5;
const double _penaltySpotDistanceM = 11.0;
const double _goalWidthM = 7.32;
const double _cornerRadiusM = 1.0;

Rect _pitchRectForSize(Size size) {
  final targetRatio = _fieldWidthM / _halfLengthM;
  final availableRatio = size.width / size.height;

  double width;
  double height;

  if (availableRatio > targetRatio) {
    height = size.height;
    width = height * targetRatio;
  } else {
    width = size.width;
    height = width / targetRatio;
  }

  return Rect.fromLTWH(
    (size.width - width) / 2,
    (size.height - height) / 2,
    width,
    height,
  );
}

class HalfPitchCompoWidget extends StatelessWidget {
  final CompoType compoType;

  /// Clé = slot.id
  ///
  /// Exemples :
  /// goalkeeper_1
  /// defender_1
  /// defender_2
  /// midfielder_1
  /// striker_1
  final Map<String, CompoFieldPlayer?> selectedPlayers;

  /// Fonction de sélection à brancher plus tard.
  final void Function(CompoSlot slot)? onSlotTap;

  final double? height;

  const HalfPitchCompoWidget({
    super.key,
    required this.compoType,
    this.selectedPlayers = const {},
    this.onSlotTap,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final slots = _buildSlots(compoType);

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = MediaQuery.sizeOf(context);

        final bool isPhone = constraints.maxWidth < 600;
        final bool isTablet =
            constraints.maxWidth >= 600 && constraints.maxWidth < 1000;

        final double maxPitchWidth = isPhone
            ? constraints.maxWidth
            : isTablet
            ? 760
            : 980;

        final double pitchBoxWidth = math.min(
          constraints.maxWidth,
          maxPitchWidth,
        );

        final double ratio = _fieldWidthM / _halfLengthM;
        final double naturalHeight = pitchBoxWidth / ratio;

        final double maxHeight = isPhone
            ? screenSize.height * 0.68
            : isTablet
            ? screenSize.height * 0.74
            : 760;

        final double minHeight = isPhone ? 390 : 520;

        final double responsiveHeight = height ??
            math.max(
              minHeight,
              math.min(naturalHeight, maxHeight),
            );

        return Center(
          child: Container(
            width: pitchBoxWidth,
            padding: EdgeInsets.all(isPhone ? 6 : 10),
            decoration: BoxDecoration(
              color: colors.card,
              border: Border.all(color: colors.border),
            ),
            child: SizedBox(
              height: responsiveHeight,
              child: LayoutBuilder(
                builder: (context, pitchConstraints) {
                  final size = Size(
                    pitchConstraints.maxWidth,
                    pitchConstraints.maxHeight,
                  );

                  final pitchRect = _pitchRectForSize(size);

                  final slotSize = math.min(
                    isPhone ? 48.0 : 60.0,
                    math.max(
                      isPhone ? 38.0 : 46.0,
                      pitchRect.width * (isPhone ? 0.105 : 0.115),
                    ),
                  );

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _ProHalfPitchPainter(),
                        ),
                      ),

                      for (final slot in slots)
                        Positioned(
                          left: pitchRect.left +
                              (slot.x * pitchRect.width) -
                              (slotSize / 2),
                          top: pitchRect.top +
                              (slot.y * pitchRect.height) -
                              (slotSize / 2),
                          child: _PositionButton(
                            size: slotSize,
                            slot: slot,
                            player: selectedPlayers[slot.id],
                            onTap: () {
                              if (onSlotTap != null) {
                                onSlotTap!(slot);
                              }
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class CompoSlot {
  final String id;
  final String role;
  final int index;
  final double x;
  final double y;

  const CompoSlot({
    required this.id,
    required this.role,
    required this.index,
    required this.x,
    required this.y,
  });
}

class CompoFieldPlayer {
  final String id;
  final String name;
  final String? photoUrl;
  final String? shirtNumber;

  const CompoFieldPlayer({
    required this.id,
    required this.name,
    this.photoUrl,
    this.shirtNumber,
  });
}

class _PositionButton extends StatelessWidget {
  final double size;
  final CompoSlot slot;
  final CompoFieldPlayer? player;
  final VoidCallback onTap;

  const _PositionButton({
    required this.size,
    required this.slot,
    required this.player,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final hasPlayer = player != null;
    final photoUrl = player?.photoUrl?.trim() ?? '';
    final shirtNumber = player?.shirtNumber?.trim() ?? '';

    return SizedBox(
      width: size,
      height: size + 22,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          if (shirtNumber.isNotEmpty)
            Positioned(
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  shirtNumber,
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),

          Positioned(
            top: 17,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: hasPlayer ? Colors.white : colors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _ButtonContent(
                      player: player,
                      photoUrl: photoUrl,
                      role: slot.role,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  final CompoFieldPlayer? player;
  final String photoUrl;
  final String role;

  const _ButtonContent({
    required this.player,
    required this.photoUrl,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (player != null && photoUrl.isNotEmpty) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _InitialsContent(playerName: player!.name);
        },
      );
    }

    if (player != null) {
      return _InitialsContent(playerName: player!.name);
    }

    return Container(
      color: colors.primary,
      child: Icon(
        _roleIcon(role),
        color: Colors.white,
        size: 24,
      ),
    );
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'goalkeeper':
        return Icons.sports_handball_rounded;
      case 'defender':
        return Icons.shield_rounded;
      case 'midfielderDefensive':
        return Icons.security_rounded;
      case 'midfielder':
        return Icons.adjust_rounded;
      case 'midfielderAttacking':
        return Icons.bolt_rounded;
      case 'striker':
        return Icons.sports_soccer_rounded;
      default:
        return Icons.person_add_alt_1_rounded;
    }
  }
}

class _InitialsContent extends StatelessWidget {
  final String playerName;

  const _InitialsContent({
    required this.playerName,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      color: colors.primary,
      alignment: Alignment.center,
      child: Text(
        _initials(playerName),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
class _ProHalfPitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pitchRect = _pitchRectForSize(size);

    canvas.save();
    canvas.clipRect(pitchRect);

    _drawGrass(canvas, pitchRect);
    _drawLines(canvas, pitchRect);

    canvas.restore();

    _drawBorder(canvas, pitchRect);
  }

  Offset _mToPx(Rect rect, double xM, double yM) {
    return Offset(
      rect.left + (xM / _fieldWidthM) * rect.width,
      rect.top + (yM / _halfLengthM) * rect.height,
    );
  }

  double _scale(Rect rect) {
    return math.min(
      rect.width / _fieldWidthM,
      rect.height / _halfLengthM,
    );
  }

  void _drawGrass(Canvas canvas, Rect rect) {
    final grassShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF1F6B3C),
        Color(0xFF2E8B57),
        Color(0xFF1F6B3C),
      ],
      stops: [0.0, 0.55, 1.0],
    ).createShader(rect);

    canvas.drawRect(
      rect,
      Paint()..shader = grassShader,
    );

    final stripeCount = 8;
    final stripeHeight = rect.height / stripeCount;

    for (int i = 0; i < stripeCount; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          rect.left,
          rect.top + (i * stripeHeight),
          rect.width,
          stripeHeight,
        ),
        Paint()
          ..color = i.isEven
              ? const Color(0x13FFFFFF)
              : const Color(0x08000000),
      );
    }

    final vignette = const RadialGradient(
      center: Alignment.center,
      radius: 0.95,
      colors: [
        Color(0x00000000),
        Color(0x33000000),
      ],
      stops: [0.64, 1.0],
    ).createShader(rect);

    canvas.drawRect(
      rect,
      Paint()..shader = vignette,
    );
  }

  void _drawLines(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = const Color(0xEFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.8, rect.shortestSide * 0.0045)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = const Color(0xEFFFFFFF)
      ..style = PaintingStyle.fill;

    _drawOutline(canvas, rect, paint);
    _drawHalfwayLineAndCenterCircle(canvas, rect, paint, fillPaint);
    _drawPenaltyArea(canvas, rect, paint);
    _drawGoalArea(canvas, rect, paint);
    _drawPenaltySpotAndArc(canvas, rect, paint, fillPaint);
    _drawGoal(canvas, rect, paint);
    _drawCornerArcs(canvas, rect, paint);
  }

  void _drawOutline(Canvas canvas, Rect rect, Paint paint) {
    canvas.drawRect(
      rect.deflate(paint.strokeWidth / 2),
      paint,
    );
  }

  void _drawHalfwayLineAndCenterCircle(
      Canvas canvas,
      Rect rect,
      Paint paint,
      Paint fillPaint,
      ) {
    canvas.drawLine(
      _mToPx(rect, 0, 0),
      _mToPx(rect, _fieldWidthM, 0),
      paint,
    );

    final center = _mToPx(rect, _fieldWidthM / 2, 0);
    final radius = _centerCircleRadiusM * _scale(rect);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi,
      false,
      paint,
    );

    canvas.drawCircle(
      center,
      paint.strokeWidth * 1.2,
      fillPaint,
    );
  }

  void _drawPenaltyArea(Canvas canvas, Rect rect, Paint paint) {
    final leftM = (_fieldWidthM - _penaltyAreaWidthM) / 2;
    final topM = _halfLengthM - _penaltyAreaDepthM;

    canvas.drawRect(
      Rect.fromPoints(
        _mToPx(rect, leftM, topM),
        _mToPx(rect, leftM + _penaltyAreaWidthM, _halfLengthM),
      ),
      paint,
    );
  }

  void _drawGoalArea(Canvas canvas, Rect rect, Paint paint) {
    final leftM = (_fieldWidthM - _goalAreaWidthM) / 2;
    final topM = _halfLengthM - _goalAreaDepthM;

    canvas.drawRect(
      Rect.fromPoints(
        _mToPx(rect, leftM, topM),
        _mToPx(rect, leftM + _goalAreaWidthM, _halfLengthM),
      ),
      paint,
    );
  }

  void _drawPenaltySpotAndArc(
      Canvas canvas,
      Rect rect,
      Paint paint,
      Paint fillPaint,
      ) {
    final spotX = _fieldWidthM / 2;
    final spotY = _halfLengthM - _penaltySpotDistanceM;

    final spot = _mToPx(rect, spotX, spotY);

    canvas.drawCircle(
      spot,
      paint.strokeWidth * 1.35,
      fillPaint,
    );

    final radiusM = _centerCircleRadiusM;
    final penaltyAreaTopY = _halfLengthM - _penaltyAreaDepthM;

    final dy = penaltyAreaTopY - spotY;
    final dx = math.sqrt((radiusM * radiusM) - (dy * dy));

    final startAngle = math.atan2(dy, -dx);
    final endAngle = math.atan2(dy, dx);
    final sweepAngle = endAngle - startAngle;

    final radiusPx = radiusM * _scale(rect);

    canvas.drawArc(
      Rect.fromCircle(center: spot, radius: radiusPx),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  void _drawGoal(Canvas canvas, Rect rect, Paint paint) {
    final leftM = (_fieldWidthM - _goalWidthM) / 2;
    final rightM = leftM + _goalWidthM;

    final left = _mToPx(rect, leftM, _halfLengthM);
    final right = _mToPx(rect, rightM, _halfLengthM);

    final goalDepth = math.max(8.0, rect.height * 0.018);

    final goalRect = Rect.fromLTRB(
      left.dx,
      rect.bottom - goalDepth,
      right.dx,
      rect.bottom,
    );

    canvas.drawRect(goalRect, paint);
  }

  void _drawCornerArcs(Canvas canvas, Rect rect, Paint paint) {
    final radius = math.max(
      _cornerRadiusM * _scale(rect),
      8.0,
    );

    final bottomLeft = _mToPx(rect, 0, _halfLengthM);
    final bottomRight = _mToPx(rect, _fieldWidthM, _halfLengthM);

    canvas.drawArc(
      Rect.fromCircle(center: bottomLeft, radius: radius),
      -math.pi / 2,
      math.pi / 2,
      false,
      paint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: bottomRight, radius: radius),
      math.pi,
      math.pi / 2,
      false,
      paint,
    );
  }

  void _drawBorder(Canvas canvas, Rect rect) {
    final borderPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x88FFFFFF),
          Color(0x22FFFFFF),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    canvas.drawRect(
      rect.deflate(0.7),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProHalfPitchPainter oldDelegate) => false;
}

List<CompoSlot> _buildSlots(CompoType compoType) {
  final slots = <CompoSlot>[];

  slots.addAll(
    _buildLine(
      role: 'striker',
      count: _safeCount(compoType.stricker),
      y: 0.15,
    ),
  );

  final bool isDiamond = compoType.isDiamond == true;

  if (isDiamond) {
    slots.addAll(_buildDiamondMidfieldSlots(compoType));
  } else {
    slots.addAll(
      _buildLine(
        role: 'midfielderAttacking',
        count: _safeCount(compoType.midfielderAttacking),
        y: 0.30,
      ),
    );

    slots.addAll(
      _buildLine(
        role: 'midfielder',
        count: _safeCount(compoType.midfielder),
        y: 0.45,
      ),
    );

    slots.addAll(
      _buildLine(
        role: 'midfielderDefensive',
        count: _safeCount(compoType.midfielderDefensive),
        y: 0.60,
      ),
    );
  }

  slots.addAll(
    _buildLine(
      role: 'defender',
      count: _safeCount(compoType.defender),
      y: 0.75,
    ),
  );

  slots.addAll(
    _buildLine(
      role: 'goalkeeper',
      count: 1,
      y: 0.91,
    ),
  );

  return slots;
}
List<CompoSlot> _buildDiamondMidfieldSlots(CompoType compoType) {
  final attackingCount = _safeCount(compoType.midfielderAttacking);
  final centralCount = _safeCount(compoType.midfielder);
  final defensiveCount = _safeCount(compoType.midfielderDefensive);

  final hasDetailedMidfield =
      attackingCount > 0 || defensiveCount > 0;

  if (hasDetailedMidfield) {
    return [
      ..._buildDiamondLine(
        role: 'midfielderAttacking',
        count: attackingCount,
        y: 0.33,
      ),
      ..._buildDiamondLine(
        role: 'midfielder',
        count: centralCount,
        y: 0.47,
        wideWhenTwo: true,
      ),
      ..._buildDiamondLine(
        role: 'midfielderDefensive',
        count: defensiveCount,
        y: 0.61,
      ),
    ];
  }

  return _buildAutoDiamondFromMidfielderCount(centralCount);
}

List<CompoSlot> _buildAutoDiamondFromMidfielderCount(int count) {
  if (count <= 0) return [];

  if (count == 1) {
    return const [
      CompoSlot(
        id: 'midfielder_1',
        role: 'midfielder',
        index: 1,
        x: 0.50,
        y: 0.47,
      ),
    ];
  }

  if (count == 2) {
    return const [
      CompoSlot(
        id: 'midfielderDefensive_1',
        role: 'midfielderDefensive',
        index: 1,
        x: 0.50,
        y: 0.58,
      ),
      CompoSlot(
        id: 'midfielderAttacking_1',
        role: 'midfielderAttacking',
        index: 1,
        x: 0.50,
        y: 0.36,
      ),
    ];
  }

  if (count == 3) {
    return const [
      CompoSlot(
        id: 'midfielderAttacking_1',
        role: 'midfielderAttacking',
        index: 1,
        x: 0.50,
        y: 0.34,
      ),
      CompoSlot(
        id: 'midfielder_1',
        role: 'midfielder',
        index: 1,
        x: 0.34,
        y: 0.49,
      ),
      CompoSlot(
        id: 'midfielder_2',
        role: 'midfielder',
        index: 2,
        x: 0.66,
        y: 0.49,
      ),
    ];
  }

  if (count == 4) {
    return const [
      CompoSlot(
        id: 'midfielderAttacking_1',
        role: 'midfielderAttacking',
        index: 1,
        x: 0.50,
        y: 0.32,
      ),
      CompoSlot(
        id: 'midfielder_1',
        role: 'midfielder',
        index: 1,
        x: 0.30,
        y: 0.47,
      ),
      CompoSlot(
        id: 'midfielder_2',
        role: 'midfielder',
        index: 2,
        x: 0.70,
        y: 0.47,
      ),
      CompoSlot(
        id: 'midfielderDefensive_1',
        role: 'midfielderDefensive',
        index: 1,
        x: 0.50,
        y: 0.62,
      ),
    ];
  }

  return [
    const CompoSlot(
      id: 'midfielderAttacking_1',
      role: 'midfielderAttacking',
      index: 1,
      x: 0.50,
      y: 0.31,
    ),
    ..._buildDiamondLine(
      role: 'midfielder',
      count: count - 2,
      y: 0.47,
      wideWhenTwo: true,
    ),
    const CompoSlot(
      id: 'midfielderDefensive_1',
      role: 'midfielderDefensive',
      index: 1,
      x: 0.50,
      y: 0.62,
    ),
  ];
}

List<CompoSlot> _buildDiamondLine({
  required String role,
  required int count,
  required double y,
  bool wideWhenTwo = false,
}) {
  if (count <= 0) return [];

  if (count == 1) {
    return [
      CompoSlot(
        id: '${role}_1',
        role: role,
        index: 1,
        x: 0.50,
        y: y,
      ),
    ];
  }

  if (wideWhenTwo && count == 2) {
    return [
      CompoSlot(
        id: '${role}_1',
        role: role,
        index: 1,
        x: 0.30,
        y: y,
      ),
      CompoSlot(
        id: '${role}_2',
        role: role,
        index: 2,
        x: 0.70,
        y: y,
      ),
    ];
  }

  return _buildLine(
    role: role,
    count: count,
    y: y,
  );
}

List<CompoSlot> _buildLine({
  required String role,
  required int count,
  required double y,
}) {
  if (count <= 0) return [];

  final slots = <CompoSlot>[];

  for (int i = 0; i < count; i++) {
    final index = i + 1;

    slots.add(
      CompoSlot(
        id: '${role}_$index',
        role: role,
        index: index,
        x: (i + 1) / (count + 1),
        y: y,
      ),
    );
  }

  return slots;
}

int _safeCount(int? value) {
  if (value == null) return 0;
  if (value < 0) return 0;
  return value;
}

String _initials(String value) {
  final cleanName = value.trim();

  if (cleanName.isEmpty) {
    return '?';
  }

  final parts = cleanName
      .split(RegExp(r'\s+'))
      .where((part) => part.trim().isNotEmpty)
      .toList();

  if (parts.isEmpty) {
    return '?';
  }

  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }

  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}