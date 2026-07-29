import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/personal_sport_activity.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/personal_sport_activity_helper.dart';
import 'package:grinta/widget/create_personal_sport_activity_sheet.dart';
import 'package:grinta/widget/sport_metric_pickers.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:grinta/provider/appSession.dart';

/// Logo for the connected wearable / import source of a personal activity.
class PersonalSportSourceLogo extends StatelessWidget {
  const PersonalSportSourceLogo({
    super.key,
    required this.externalSource,
    this.size = 22,
  });

  final String? externalSource;
  final double size;

  @override
  Widget build(BuildContext context) {
    final source = (externalSource ?? '').trim().toLowerCase();
    final l10n = context.l10n;
    final colors = context.appColors;

    Widget? logo;
    String? tooltip;
    switch (source) {
      case 'strava':
        tooltip = l10n.wearableDeviceStrava;
        logo = SvgPicture.asset(
          'assets/images/strava_logo.svg',
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
      case 'polar':
        tooltip = l10n.wearableDevicePolar;
        logo = ClipOval(
          child: Image.asset(
            'assets/images/polar_logo.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );
      case 'whoop':
        tooltip = l10n.wearableDeviceWhoop;
        logo = SvgPicture.asset(
          'assets/images/whoop_logo.svg',
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
      case 'applehealth':
        tooltip = l10n.wearableDeviceAppleHealth;
        logo = SvgPicture.asset(
          'assets/images/apple_forme_logo.svg',
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
      case 'googlehealth':
        tooltip = l10n.wearableDeviceGoogleHealthConnect;
        logo = SvgPicture.asset(
          'assets/images/google_fit_logo.svg',
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
      case 'intensegps':
        tooltip = l10n.createPersonalSportUseMyGps;
        logo = Icon(
          Icons.gps_fixed_rounded,
          size: size,
          color: colors.primary,
        );
      default:
        logo = Icon(
          Icons.directions_run_rounded,
          size: size,
          color: colors.success,
        );
        tooltip = l10n.agendaAddEventPersonalSport;
    }

    return Tooltip(message: tooltip, child: logo);
  }
}

/// Compact synthesis chips for a personal sport activity (device-aware).
class PersonalSportActivitySummaryChips extends StatelessWidget {
  const PersonalSportActivitySummaryChips({
    super.key,
    required this.activity,
  });

  final PersonalSportActivity activity;

  @override
  Widget build(BuildContext context) {
    final chips = buildPersonalSportSummaryChips(context, activity);
    if (chips.isEmpty) return const SizedBox.shrink();

    final colors = context.appColors;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final chip in chips)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colors.border.withValues(alpha: 0.45)),
            ),
            child: Text(
              chip,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

/// Dashboard / list row: logo, date, title, synthesis, tap → detail.
class PersonalSportActivityDashboardTile extends StatelessWidget {
  const PersonalSportActivityDashboardTile({
    super.key,
    required this.activity,
  });

  final PersonalSportActivity activity;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final dateLabel = DateFormat.yMMMd(locale).add_Hm().format(activity.startAt);
    final title = (activity.title ?? '').trim().isEmpty
        ? l10n.agendaAddEventPersonalSport
        : activity.title!.trim();
    final session = context.read<AppSession>();
    final canManage = canManagePersonalSportActivity(activity, session);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          showCreatePersonalSportActivitySheet(
            context,
            activityToEdit: activity,
            readOnly: !canManage,
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PersonalSportSourceLogo(
                externalSource: activity.externalSource,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    PersonalSportActivitySummaryChips(activity: activity),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<String> buildPersonalSportSummaryChips(
  BuildContext context,
  PersonalSportActivity activity,
) {
  final l10n = context.l10n;
  final source = (activity.externalSource ?? '').trim().toLowerCase();
  final chips = <String>[];

  void add(String? label, String? value) {
    if (value == null || value.trim().isEmpty) return;
    chips.add(label == null || label.isEmpty ? value : '$label $value');
  }

  if (source == 'whoop') {
    if (activity.strain != null && activity.strain! > 0) {
      add(l10n.whoopAnalysisStrain, activity.strain!.toStringAsFixed(1));
    }
    if (activity.averageHeartRateBpm != null &&
        activity.averageHeartRateBpm! > 0) {
      add(
        l10n.personalSportMetricAvgHeartRate,
        '${activity.averageHeartRateBpm} ${l10n.personalSportUnitBpm}',
      );
    }
    if (activity.maxHeartRateBpm != null && activity.maxHeartRateBpm! > 0) {
      add(
        l10n.whoopAnalysisMaxHr,
        '${activity.maxHeartRateBpm} ${l10n.personalSportUnitBpm}',
      );
    }
    if (activity.altitudeGainMeters != null &&
        activity.altitudeGainMeters! > 0) {
      add(
        null,
        '+${activity.altitudeGainMeters!.round()} m',
      );
    }
  }

  if (activity.durationSeconds != null && activity.durationSeconds! > 0) {
    add(
      l10n.personalSportMetricDuration,
      formatSportDurationClock(Duration(seconds: activity.durationSeconds!)),
    );
  }

  if (activity.distanceMeters != null && activity.distanceMeters! > 0) {
    add(
      l10n.personalSportMetricDistance,
      formatSportDistanceKm(
        activity.distanceMeters! / 1000,
        activity.distanceUnit,
      ),
    );
  }

  if (activity.paceSecondsPerKm != null && activity.paceSecondsPerKm! > 0) {
    add(
      l10n.personalSportMetricAvgPace,
      formatSportPace(activity.paceSecondsPerKm!, activity.paceUnit),
    );
  }

  if (activity.caloriesKcal != null && activity.caloriesKcal! > 0) {
    add(
      l10n.personalSportMetricCalories,
      '${activity.caloriesKcal!.round()} ${l10n.personalSportUnitKcal}',
    );
  }

  // Polar / generic HR if not already added for Whoop.
  if (source != 'whoop' &&
      activity.averageHeartRateBpm != null &&
      activity.averageHeartRateBpm! > 0) {
    add(
      l10n.personalSportMetricAvgHeartRate,
      '${activity.averageHeartRateBpm} ${l10n.personalSportUnitBpm}',
    );
  }

  if (source == 'polar' &&
      activity.maxHeartRateBpm != null &&
      activity.maxHeartRateBpm! > 0) {
    add(
      l10n.polarAnalysisMaxHr,
      '${activity.maxHeartRateBpm} ${l10n.personalSportUnitBpm}',
    );
  }

  // Cap to keep dashboard rows readable.
  if (chips.length > 4) {
    return chips.take(4).toList(growable: false);
  }
  return chips;
}
