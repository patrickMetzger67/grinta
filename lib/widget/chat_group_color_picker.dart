import 'package:flutter/material.dart';
import 'package:grinta/util/app_theme.dart';

/// HSV color picker: saturation/value pad + hue slider.
class ChatGroupColorPicker extends StatelessWidget {
  const ChatGroupColorPicker({
    super.key,
    required this.color,
    required this.onColorChanged,
    this.enabled = true,
  });

  final Color color;
  final ValueChanged<Color> onColorChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hsv = HSVColor.fromColor(color);

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Column(
          children: [
            _SaturationValuePad(
              hsv: hsv,
              borderColor: colors.border,
              onChanged: onColorChanged,
            ),
            const SizedBox(height: 14),
            _HueSlider(
              hue: hsv.hue,
              borderColor: colors.border,
              onChanged: (hue) {
                onColorChanged(hsv.withHue(hue).toColor());
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SaturationValuePad extends StatelessWidget {
  const _SaturationValuePad({
    required this.hsv,
    required this.borderColor,
    required this.onChanged,
  });

  final HSVColor hsv;
  final Color borderColor;
  final ValueChanged<Color> onChanged;

  void _update(Offset local, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final saturation = (local.dx / size.width).clamp(0.0, 1.0);
    final value = (1 - local.dy / size.height).clamp(0.0, 1.0);
    onChanged(hsv.withSaturation(saturation).withValue(value).toColor());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = (width * 0.55).clamp(120.0, 180.0);
        final size = Size(width, height);
        return GestureDetector(
          onPanDown: (details) => _update(details.localPosition, size),
          onPanUpdate: (details) => _update(details.localPosition, size),
          child: CustomPaint(
            size: size,
            painter: _SaturationValuePainter(
              hsv: hsv,
              borderColor: borderColor,
            ),
          ),
        );
      },
    );
  }
}

class _SaturationValuePainter extends CustomPainter {
  const _SaturationValuePainter({
    required this.hsv,
    required this.borderColor,
  });

  final HSVColor hsv;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.save();
    canvas.clipRRect(rrect);

    final hueColor = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor();
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white, hueColor],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );
    canvas.restore();

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = borderColor,
    );

    final thumb = Offset(
      hsv.saturation * size.width,
      (1 - hsv.value) * size.height,
    );
    canvas.drawCircle(thumb, 8, Paint()..color = Colors.white);
    canvas.drawCircle(
      thumb,
      6,
      Paint()..color = hsv.toColor(),
    );
  }

  @override
  bool shouldRepaint(covariant _SaturationValuePainter oldDelegate) {
    return oldDelegate.hsv != hsv || oldDelegate.borderColor != borderColor;
  }
}

class _HueSlider extends StatelessWidget {
  const _HueSlider({
    required this.hue,
    required this.borderColor,
    required this.onChanged,
  });

  final double hue;
  final Color borderColor;
  final ValueChanged<double> onChanged;

  static const _hues = <Color>[
    Color(0xFFFF0000),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF00FFFF),
    Color(0xFF0000FF),
    Color(0xFFFF00FF),
    Color(0xFFFF0000),
  ];

  void _update(Offset local, double width) {
    if (width <= 0) return;
    onChanged((local.dx / width).clamp(0.0, 1.0) * 360);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 22.0;
        final size = Size(width, height);
        return GestureDetector(
          onPanDown: (details) => _update(details.localPosition, width),
          onPanUpdate: (details) => _update(details.localPosition, width),
          child: CustomPaint(
            size: size,
            painter: _HueSliderPainter(
              hue: hue,
              borderColor: borderColor,
              hues: _hues,
            ),
          ),
        );
      },
    );
  }
}

class _HueSliderPainter extends CustomPainter {
  const _HueSliderPainter({
    required this.hue,
    required this.borderColor,
    required this.hues,
  });

  final double hue;
  final Color borderColor;
  final List<Color> hues;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(999));
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(colors: hues).createShader(rect),
    );
    canvas.restore();
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = borderColor,
    );

    final x = (hue / 360).clamp(0.0, 1.0) * size.width;
    final thumb = Offset(x, size.height / 2);
    canvas.drawCircle(thumb, 9, Paint()..color = Colors.white);
    canvas.drawCircle(
      thumb,
      6,
      Paint()..color = HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
    );
  }

  @override
  bool shouldRepaint(covariant _HueSliderPainter oldDelegate) {
    return oldDelegate.hue != hue || oldDelegate.borderColor != borderColor;
  }
}
