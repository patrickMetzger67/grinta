import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Displays the app version at the bottom of the settings menu.
class AppVersionLabel extends StatefulWidget {
  const AppVersionLabel({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 16),
    this.alignment = Alignment.center,
  });

  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;

  @override
  State<AppVersionLabel> createState() => _AppVersionLabelState();
}

class _AppVersionLabelState extends State<AppVersionLabel> {
  late final Future<PackageInfo> _packageInfoFuture =
      PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return FutureBuilder<PackageInfo>(
      future: _packageInfoFuture,
      builder: (context, snapshot) {
        final info = snapshot.data;
        if (info == null) {
          return const SizedBox.shrink();
        }

        final label = info.buildNumber.isEmpty
            ? info.version
            : '${info.version} (${info.buildNumber})';

        return Align(
          alignment: widget.alignment,
          child: Padding(
            padding: widget.padding,
            child: Text(
              l10n.settingsVersionLabel(label),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ),
        );
      },
    );
  }
}
