import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/fitbit_sync_config.dart';
import 'package:grinta/services/fitbit_sync_service.dart';
import 'package:grinta/util/app_theme.dart';

/// Per-metric toggles for coach visibility (player flow).
class FitbitCoachVisibilitySection extends StatelessWidget {
  const FitbitCoachVisibilitySection({
    super.key,
    required this.uid,
    required this.playerId,
    required this.visibility,
    this.contentPadding,
    this.dense = false,
  });

  final String uid;
  final String playerId;
  final FitbitCoachVisibility visibility;
  final EdgeInsetsGeometry? contentPadding;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: contentPadding ?? const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            l10n.fitbitCoachVisibilityTitle,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: dense ? 12 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        for (final key in FitbitCoachVisibility.metricKeys)
          SwitchListTile(
            contentPadding: contentPadding,
            dense: dense,
            title: Text(
              _labelForMetric(l10n, key),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: dense ? 14 : 15,
              ),
            ),
            subtitle: Text(
              l10n.fitbitCoachVisibilitySubtitle,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
              ),
            ),
            value: visibility.valueForKey(key),
            onChanged: (value) async {
              final updated = visibility.withKey(key, value);
              final ok = await FitbitSyncService.instance.updateCoachVisibility(
                uid: uid,
                playerId: playerId,
                visibility: updated,
              );
              if (!context.mounted) return;
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.fitbitCoachVisibilitySaveFailed)),
                );
              }
            },
            activeThumbColor: Colors.white,
            activeTrackColor: colors.primary,
            inactiveThumbColor: colors.textSecondary,
            inactiveTrackColor: colors.border,
          ),
      ],
    );
  }

  String _labelForMetric(AppLocalizations l10n, String key) {
    switch (key) {
      case 'activity':
        return l10n.fitbitMetricActivity;
      case 'heartrate':
        return l10n.fitbitMetricHeartrate;
      case 'sleep':
        return l10n.fitbitMetricSleep;
      case 'profile':
        return l10n.fitbitMetricProfile;
      case 'body':
        return l10n.fitbitMetricBody;
      default:
        return key;
    }
  }
}
