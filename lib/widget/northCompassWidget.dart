import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

class NorthCompassWidget extends StatefulWidget {
  const NorthCompassWidget({
    super.key,
    this.size = 220,
    this.backgroundColor = Colors.white,
    this.borderColor = const Color(0xFFE0E0E0),
    this.textColor = Colors.black87,
    this.northColor = Colors.red,
  });

  final double size;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color northColor;

  @override
  State<NorthCompassWidget> createState() => _NorthCompassWidgetState();
}

class _NorthCompassWidgetState extends State<NorthCompassWidget> {
  double? _heading;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }

        if (snapshot.hasData && snapshot.data?.heading != null) {
          _heading = snapshot.data!.heading!;
        }

        if (_heading == null) {
          return _buildUnavailable();
        }

        final heading = _heading!;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: heading),
                duration: const Duration(milliseconds: 250),
                builder: (context, animatedHeading, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildCompassFace(),
                      Transform.rotate(
                        angle: -animatedHeading * (math.pi / 180),
                        child: _buildNeedle(),
                      ),
                      _buildCenterDot(),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Nord • ${heading.toStringAsFixed(0)}°",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: widget.textColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoading() {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildUnavailable() {
    return Container(
      width: widget.size,
      height: widget.size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: widget.borderColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          "Boussole indisponible",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: widget.textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildCompassFace() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.backgroundColor,
        border: Border.all(color: widget.borderColor, width: 2),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            spreadRadius: 1,
            offset: Offset(0, 4),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...List.generate(36, (index) {
            final isMainMark = index % 9 == 0;
            final angle = (index * 10) * math.pi / 180;

            return Transform.rotate(
              angle: angle,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: isMainMark ? 3 : 1.5,
                  height: isMainMark ? 18 : 10,
                  decoration: BoxDecoration(
                    color: isMainMark
                        ? widget.textColor
                        : widget.textColor.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            );
          }),
          _buildDirectionLabel("N", Alignment.topCenter, widget.northColor, true),
          _buildDirectionLabel("E", Alignment.centerRight, widget.textColor, false),
          _buildDirectionLabel("S", Alignment.bottomCenter, widget.textColor, false),
          _buildDirectionLabel("O", Alignment.centerLeft, widget.textColor, false),
        ],
      ),
    );
  }

  Widget _buildDirectionLabel(
      String text,
      Alignment alignment,
      Color color,
      bool isNorth,
      ) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsets.only(
          top: alignment == Alignment.topCenter ? 18 : 0,
          bottom: alignment == Alignment.bottomCenter ? 18 : 0,
          left: alignment == Alignment.centerLeft ? 18 : 0,
          right: alignment == Alignment.centerRight ? 18 : 0,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: isNorth ? 26 : 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildNeedle() {
    return SizedBox(
      width: widget.size * 0.16,
      height: widget.size * 0.72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Icon(
              Icons.navigation,
              size: widget.size * 0.18,
              color: widget.northColor,
            ),
          ),
          Positioned(
            top: widget.size * 0.11,
            child: Container(
              width: 4,
              height: widget.size * 0.22,
              decoration: BoxDecoration(
                color: widget.northColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterDot() {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.textColor,
        border: Border.all(color: Colors.white, width: 3),
      ),
    );
  }
}