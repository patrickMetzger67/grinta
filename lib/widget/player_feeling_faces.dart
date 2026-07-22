import 'package:flutter/material.dart';
import 'package:grinta/model/player_feeling.dart';
import 'package:grinta/util/app_theme.dart';

/// Reusable "Comment te sens-tu ?" smiley row (same faces as session feeling).
class PlayerFeelingFacesRow extends StatelessWidget {
  const PlayerFeelingFacesRow({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final PlayerFeeling? selected;
  final ValueChanged<PlayerFeeling> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final feeling in PlayerFeeling.values)
          _FeelingFaceButton(
            feeling: feeling,
            selected: selected == feeling,
            enabled: enabled,
            onTap: () => onChanged(feeling),
          ),
      ],
    );
  }
}

class _FeelingFaceButton extends StatelessWidget {
  const _FeelingFaceButton({
    required this.feeling,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final PlayerFeeling feeling;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? const Color(0xFFE53935) : context.appColors.textPrimary;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: CustomPaint(
          size: const Size(44, 44),
          painter: FeelingFacePainter(
            feeling: feeling,
            color: color,
          ),
        ),
      ),
    );
  }
}

class FeelingFacePainter extends CustomPainter {
  FeelingFacePainter({
    required this.feeling,
    required this.color,
  });

  final PlayerFeeling feeling;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 2;
    canvas.drawCircle(center, radius, stroke);

    final leftEye = Offset(center.dx - radius * 0.32, center.dy - radius * 0.18);
    final rightEye =
        Offset(center.dx + radius * 0.32, center.dy - radius * 0.18);

    switch (feeling) {
      case PlayerFeeling.veryBad:
        _drawArcEye(canvas, leftEye, radius * 0.16, stroke, smile: false);
        _drawArcEye(canvas, rightEye, radius * 0.16, stroke, smile: false);
        _drawMouth(canvas, center, radius, stroke, curve: -0.55);
        break;
      case PlayerFeeling.bad:
        canvas.drawCircle(leftEye, 2.2, fill);
        canvas.drawCircle(rightEye, 2.2, fill);
        canvas.drawLine(
          Offset(leftEye.dx - 4, leftEye.dy - 6),
          Offset(leftEye.dx + 4, leftEye.dy - 3),
          stroke,
        );
        canvas.drawLine(
          Offset(rightEye.dx - 4, rightEye.dy - 3),
          Offset(rightEye.dx + 4, rightEye.dy - 6),
          stroke,
        );
        _drawMouth(canvas, center, radius, stroke, curve: -0.35);
        break;
      case PlayerFeeling.neutral:
        canvas.drawCircle(leftEye, 2.2, fill);
        canvas.drawCircle(rightEye, 2.2, fill);
        canvas.drawLine(
          Offset(center.dx - radius * 0.35, center.dy + radius * 0.32),
          Offset(center.dx + radius * 0.35, center.dy + radius * 0.32),
          stroke,
        );
        break;
      case PlayerFeeling.good:
        canvas.drawCircle(leftEye, 2.2, fill);
        canvas.drawCircle(rightEye, 2.2, fill);
        _drawMouth(canvas, center, radius, stroke, curve: 0.35);
        break;
      case PlayerFeeling.veryGood:
        _drawArcEye(canvas, leftEye, radius * 0.16, stroke, smile: true);
        _drawArcEye(canvas, rightEye, radius * 0.16, stroke, smile: true);
        _drawMouth(canvas, center, radius, stroke, curve: 0.55);
        break;
    }
  }

  void _drawArcEye(
    Canvas canvas,
    Offset center,
    double r,
    Paint paint, {
    required bool smile,
  }) {
    final rect = Rect.fromCircle(center: center, radius: r);
    canvas.drawArc(
      rect,
      smile ? 3.6 : 0.4,
      smile ? -2.2 : 2.2,
      false,
      paint,
    );
  }

  void _drawMouth(
    Canvas canvas,
    Offset faceCenter,
    double radius,
    Paint paint, {
    required double curve,
  }) {
    final mouthCenter = Offset(faceCenter.dx, faceCenter.dy + radius * 0.28);
    final width = radius * 0.7;
    final path = Path();
    path.moveTo(mouthCenter.dx - width / 2, mouthCenter.dy);
    path.quadraticBezierTo(
      mouthCenter.dx,
      mouthCenter.dy + radius * curve,
      mouthCenter.dx + width / 2,
      mouthCenter.dy,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant FeelingFacePainter oldDelegate) {
    return oldDelegate.feeling != feeling || oldDelegate.color != color;
  }
}
