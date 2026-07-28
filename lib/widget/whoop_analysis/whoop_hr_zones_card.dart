import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/personal_sport_activity.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/whoop_hr_zones.dart';

/// Whoop-style activity Strain + HR zones card, restyled with Grinta colours.
///
/// Mirrors the Whoop workout detail (effort, duration, zone bars with hatch),
/// on a dark canvas using Grinta primary / secondary / success / warning.
class WhoopHrZonesCard extends StatelessWidget {
  const WhoopHrZonesCard({
    super.key,
    required this.activity,
  });

  final PersonalSportActivity activity;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final dark = AppColors.dark;
    final bands = whoopHrZoneBandsBpm(hrMaxBpm: activity.hrMaxUsedBpm);
    final zoneColors = whoopGrintaZoneColors();
    final zonesDesc = kWhoopHrZoneKeys.reversed.toList(growable: false);

    final totals = kWhoopHrZoneKeys
        .map((z) => activity.hrZoneSeconds[z] ?? 0)
        .fold<int>(0, (a, b) => a + b);
    final durationSeconds = activity.durationSeconds ?? totals;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: dark.background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: dark.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.monitor_heart_outlined,
                color: AppColors.light.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.whoopAnalysisTitle,
                  style: TextStyle(
                    color: dark.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (durationSeconds > 0)
                Text(
                  '${l10n.whoopAnalysisDuration} '
                  '${formatWhoopDuration(durationSeconds)}',
                  style: TextStyle(
                    color: dark.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricBlock(
                  value: activity.strain != null
                      ? formatWhoopStrain(activity.strain!, locale: locale)
                      : '—',
                  label: l10n.whoopAnalysisStrain,
                  valueColor: AppColors.light.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricBlock(
                  value: activity.averageHeartRateBpm?.toString() ?? '—',
                  label: l10n.whoopAnalysisAvgHr,
                  valueColor: dark.textPrimary,
                ),
              ),
            ],
          ),
          if (activity.maxHeartRateBpm != null ||
              activity.caloriesKcal != null ||
              activity.altitudeGainMeters != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (activity.maxHeartRateBpm != null)
                  Expanded(
                    child: _SecondaryMetric(
                      label: l10n.whoopAnalysisMaxHr,
                      value:
                          '${activity.maxHeartRateBpm} ${l10n.personalSportUnitBpm}',
                    ),
                  ),
                if (activity.caloriesKcal != null)
                  Expanded(
                    child: _SecondaryMetric(
                      label: l10n.whoopAnalysisCalories,
                      value:
                          '${activity.caloriesKcal!.round()} ${l10n.personalSportUnitKcal}',
                    ),
                  ),
                if (activity.altitudeGainMeters != null)
                  Expanded(
                    child: _SecondaryMetric(
                      label: l10n.whoopAnalysisAltitude,
                      value:
                          '+${activity.altitudeGainMeters!.round()} m',
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Text(
            l10n.whoopAnalysisHrZonesTitle,
            style: TextStyle(
              color: dark.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (totals <= 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                l10n.whoopAnalysisNoZones,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: dark.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            for (final zone in zonesDesc) ...[
              _WhoopZoneRow(
                zoneIndex: int.parse(zone.substring(1)),
                seconds: activity.hrZoneSeconds[zone] ?? 0,
                totalSeconds: totals,
                color: zoneColors[int.parse(zone.substring(1))],
                band: bands.firstWhere((b) => b.zone == zone),
                isTopZone: zone == 'z5',
              ),
              if (zone != zonesDesc.last) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: dark.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _SecondaryMetric extends StatelessWidget {
  const _SecondaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: dark.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: dark.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _WhoopZoneRow extends StatelessWidget {
  const _WhoopZoneRow({
    required this.zoneIndex,
    required this.seconds,
    required this.totalSeconds,
    required this.color,
    required this.band,
    required this.isTopZone,
  });

  final int zoneIndex;
  final int seconds;
  final int totalSeconds;
  final Color color;
  final WhoopHrZoneBand band;
  final bool isTopZone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dark = AppColors.dark;
    final pct = totalSeconds <= 0 ? 0.0 : seconds / totalSeconds;
    final bpmLabel = isTopZone
        ? l10n.whoopAnalysisZoneAboveBpm(band.minBpm)
        : l10n.whoopAnalysisZoneBpmRange(band.minBpm, band.maxBpm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: 5,
              child: Text(
                '${l10n.whoopAnalysisZoneLabel(zoneIndex)}   $bpmLabel',
                style: TextStyle(
                  color: dark.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${(pct * 100).round()}%',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: dark.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                formatWhoopDuration(seconds),
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: dark.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 12,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: CustomPaint(
              painter: _HatchedZoneBarPainter(
                fillFraction: pct.clamp(0.0, 1.0),
                fillColor: color,
                hatchColor: dark.border.withValues(alpha: 0.85),
                trackColor: dark.card,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Solid fill + diagonal hatch for the remaining portion (Whoop look).
class _HatchedZoneBarPainter extends CustomPainter {
  _HatchedZoneBarPainter({
    required this.fillFraction,
    required this.fillColor,
    required this.hatchColor,
    required this.trackColor,
  });

  final double fillFraction;
  final Color fillColor;
  final Color hatchColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final track = Paint()..color = trackColor;
    canvas.drawRect(Offset.zero & size, track);

    final fillWidth = size.width * fillFraction;
    if (fillWidth > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, fillWidth, size.height),
        Paint()..color = fillColor,
      );
    }

    final hatchStart = fillWidth;
    if (hatchStart >= size.width - 0.5) return;

    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(hatchStart, 0, size.width - hatchStart, size.height),
    );
    final hatchPaint = Paint()
      ..color = hatchColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const spacing = 6.0;
    final extent = size.width + size.height;
    for (var x = -size.height; x < extent; x += spacing) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        hatchPaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HatchedZoneBarPainter oldDelegate) {
    return oldDelegate.fillFraction != fillFraction ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.hatchColor != hatchColor ||
        oldDelegate.trackColor != trackColor;
  }
}
