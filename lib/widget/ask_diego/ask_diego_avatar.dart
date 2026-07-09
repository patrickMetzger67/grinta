import 'package:flutter/material.dart';
import 'package:grinta/util/app_theme.dart';

const String kAskDiegoAvatarAsset = 'assets/images/ask_gio_avatar.png';

class AskDiegoAvatar extends StatelessWidget {
  const AskDiegoAvatar({
    super.key,
    this.size = 40,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.light.primary,
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
