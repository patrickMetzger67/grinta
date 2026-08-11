import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/oura_sync_config.dart';
import 'package:grinta/services/oura_sync_service.dart';
import 'package:grinta/util/app_theme.dart';

/// Per-metric toggles for coach visibility (player flow).
class OuraCoachVisibilitySection extends StatelessWidget {
  const OuraCoachVisibilitySection({
    super.key,
    required this.uid,
    required this.playerId,
    required this.visibility,
    this.contentPadding,
    this.dense = false,
  });

  final String uid;
  final String playerId;
  final OuraCoachVisibility visibility;
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
            l10n.ouraCoachVisibilityTitle,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: dense ? 12 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        for (final key in OuraCoachVisibility.metricKeys)
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
              l10n.ouraCoachVisibilitySubtitle,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
              ),
            ),
            value: visibility.valueForKey(key),
            onChanged: (value) async {
              final updated = visibility.withKey(key, value);
              final ok = await OuraSyncService.instance.updateCoachVisibility(
                uid: uid,
                playerId: playerId,
                visibility: updated,
              );
              if (!context.mounted) return;
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.ouraCoachVisibilitySaveFailed)),
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
      case 'workout':
        return l10n.ouraMetricWorkout;
      case 'heartrate':
        return l10n.ouraMetricHeartrate;
      case 'daily':
        return l10n.ouraMetricDaily;
      case 'personal':
        return l10n.ouraMetricPersonal;
      case 'email':
        return l10n.ouraMetricEmail;
      default:
        return key;
    }
  }
}
