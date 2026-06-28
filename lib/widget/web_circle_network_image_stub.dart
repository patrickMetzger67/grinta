import 'package:flutter/material.dart';

/// Non-web: standard [Image.network] inside a circle clip.
class WebCircleNetworkImage extends StatelessWidget {
  const WebCircleNetworkImage({
    super.key,
    required this.url,
    required this.size,
    required this.errorChild,
    this.onError,
  });

  final String url;
  final double size;
  final Widget errorChild;
  final VoidCallback? onError;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Image.network(
          url,
          key: ValueKey('network-circle-$url'),
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) {
            onError?.call();
            return errorChild;
          },
        ),
      ),
    );
  }
}
