import 'package:flutter/material.dart';
import 'package:grinta/services/countries_service.dart';

/// Renders a country flag from bundled asset, then [flagUrl], then CDN.
class CountryFlagImage extends StatelessWidget {
  const CountryFlagImage({
    super.key,
    required this.country,
    this.width = 24,
    this.height = 16,
  });

  final CountryDefinition country;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;

    Widget placeholder() => Icon(
          Icons.flag_outlined,
          size: height + 2,
          color: secondary,
        );

    Widget networkFlag(String url) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => placeholder(),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Image.asset(
        country.flagAssetPath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) {
          final storageUrl = country.flagUrl?.trim() ?? '';
          if (storageUrl.isNotEmpty) {
            return Image.network(
              storageUrl,
              width: width,
              height: height,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => networkFlag(country.flagCdnUrl),
            );
          }
          return networkFlag(country.flagCdnUrl);
        },
      ),
    );
  }
}
