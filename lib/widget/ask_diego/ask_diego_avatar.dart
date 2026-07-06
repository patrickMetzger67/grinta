import 'package:flutter/material.dart';

const String kAskDiegoAvatarAsset = 'assets/images/ask_diego_avatar.png';

class AskDiegoAvatar extends StatelessWidget {
  const AskDiegoAvatar({
    super.key,
    this.size = 40,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      kAskDiegoAvatarAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
