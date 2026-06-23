import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/social_auth_service.dart';
import '../util/app_theme.dart';

class SocialAuthButton extends StatelessWidget {
  final SocialAuthProvider provider;
  final String label;
  final VoidCallback? onPressed;

  const SocialAuthButton({
    super.key,
    required this.provider,
    required this.label,
    this.onPressed,
  });

  String get _assetPath {
    switch (provider) {
      case SocialAuthProvider.google:
        return 'assets/images/google_logo.svg';
      case SocialAuthProvider.apple:
        return 'assets/images/apple_logo.svg';
    }
  }

  Color? _iconColor(BuildContext context) {
    if (provider == SocialAuthProvider.apple) {
      return context.appColors.textPrimary;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _iconColor(context);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              _assetPath,
              width: 20,
              height: 20,
              colorFilter: iconColor == null
                  ? null
                  : ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
