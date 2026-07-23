import 'package:flutter/material.dart';
import 'package:grinta/util/app_theme.dart';

const String kAskDiegoAvatarAsset = 'assets/images/ask_gio_avatar.png';

class AskDiegoAvatar extends StatelessWidget {
  const AskDiegoAvatar({
    super.key,
    this.size = 40,
    this.backgroundColor,
  });

  final double size;

  /// Defaults to brand orange. Pass [Colors.white] for speed-dial mini FABs.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.light.primary,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Image.asset(
            kAskDiegoAvatarAsset,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
