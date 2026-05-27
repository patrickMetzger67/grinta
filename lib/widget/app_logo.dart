import 'package:flutter/material.dart';

/// Logo Grinta selon le thème : clair → noir sur fond blanc, sombre → logo fond blanc.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
  });

  final double? height;
  final double? width;
  final BoxFit fit;

  static const String _lightAsset = 'assets/images/logoNoirFondBlanc.png';
  static const String _darkAsset = 'assets/images/logoFondBlanc.png';

  static String assetPathFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? _darkAsset
        : _lightAsset;
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPathFor(context),
      height: height,
      width: width,
      fit: fit,
    );
  }
}
