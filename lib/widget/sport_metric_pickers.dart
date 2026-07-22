import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/util/app_theme.dart';

/// Duration picker: hours / minutes / seconds (Temps).
Future<Duration?> showSportDurationPicker(
  BuildContext context, {
  Duration initial = Duration.zero,
}) async {
  var hours = initial.inHours.clamp(0, 23);
  var minutes = initial.inMinutes.remainder(60).clamp(0, 59);
  var seconds = initial.inSeconds.remainder(60).clamp(0, 59);

  return showDialog<Duration>(
    context: context,
    builder: (dialogContext) {
      final colors = dialogContext.appColors;
      final l10n = dialogContext.l10n;
      return AlertDialog(
        backgroundColor: colors.card,
        title: Text(
          l10n.createPersonalSportDuration,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SizedBox(
          height: 180,
          width: 300,
          child: Row(
            children: [
              Expanded(
                child: CupertinoPicker(
                  scrollController:
                      FixedExtentScrollController(initialItem: hours),
                  itemExtent: 36,
                  onSelectedItemChanged: (v) => hours = v,
                  children: [
                    for (var i = 0; i < 24; i++)
                      Center(
                        child: Text(
                          '$i h',
                          style: TextStyle(color: colors.textPrimary),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController:
                      FixedExtentScrollController(initialItem: minutes),
                  itemExtent: 36,
                  onSelectedItemChanged: (v) => minutes = v,
                  children: [
                    for (var i = 0; i < 60; i++)
                      Center(
                        child: Text(
                          '$i min',
                          style: TextStyle(color: colors.textPrimary),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController:
                      FixedExtentScrollController(initialItem: seconds),
                  itemExtent: 36,
                  onSelectedItemChanged: (v) => seconds = v,
                  children: [
                    for (var i = 0; i < 60; i++)
                      Center(
                        child: Text(
                          '$i s',
                          style: TextStyle(color: colors.textPrimary),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(
              Duration(hours: hours, minutes: minutes, seconds: seconds),
            ),
            child: Text(
              l10n.actionOk,
              style: TextStyle(color: colors.primary),
            ),
          ),
        ],
      );
    },
  );
}

class SportDistanceValue {
  const SportDistanceValue({
    required this.kilometers,
    required this.unit,
  });

  /// Distance expressed in kilometers (even if unit display is mi).
  final double kilometers;
  final String unit; // km | mi
}

/// Distance picker: integer / decimal / unit.
Future<SportDistanceValue?> showSportDistancePicker(
  BuildContext context, {
  SportDistanceValue? initial,
}) async {
  final unitIndexInitial = (initial?.unit == 'mi') ? 1 : 0;
  final initialDisplay = unitIndexInitial == 1
      ? (initial?.kilometers ?? 0) / 1.609344
      : (initial?.kilometers ?? 0);
  var whole = initialDisplay.floor().clamp(0, 299);
  var tenths = ((initialDisplay - whole) * 10).round().clamp(0, 9);
  var unitIndex = unitIndexInitial;

  return showDialog<SportDistanceValue>(
    context: context,
    builder: (dialogContext) {
      final colors = dialogContext.appColors;
      final l10n = dialogContext.l10n;
      return AlertDialog(
        backgroundColor: colors.card,
        title: Text(
          l10n.createPersonalSportDistance,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SizedBox(
          height: 180,
          width: 300,
          child: Row(
            children: [
              Expanded(
                child: CupertinoPicker(
                  scrollController:
                      FixedExtentScrollController(initialItem: whole),
                  itemExtent: 36,
                  onSelectedItemChanged: (v) => whole = v,
                  children: [
                    for (var i = 0; i < 300; i++)
                      Center(
                        child: Text(
                          '$i',
                          style: TextStyle(color: colors.textPrimary),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController:
                      FixedExtentScrollController(initialItem: tenths),
                  itemExtent: 36,
                  onSelectedItemChanged: (v) => tenths = v,
                  children: [
                    for (var i = 0; i < 10; i++)
                      Center(
                        child: Text(
                          '0,$i',
                          style: TextStyle(color: colors.textPrimary),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController:
                      FixedExtentScrollController(initialItem: unitIndex),
                  itemExtent: 36,
                  onSelectedItemChanged: (v) => unitIndex = v,
                  children: [
                    Center(
                      child: Text(
                        'km',
                        style: TextStyle(color: colors.textPrimary),
                      ),
                    ),
                    Center(
                      child: Text(
                        'mi',
                        style: TextStyle(color: colors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () {
              final display = whole + tenths / 10.0;
              final unit = unitIndex == 1 ? 'mi' : 'km';
              final km = unit == 'mi' ? display * 1.609344 : display;
              Navigator.of(dialogContext).pop(
                SportDistanceValue(kilometers: km, unit: unit),
              );
            },
            child: Text(
              l10n.actionOk,
              style: TextStyle(color: colors.primary),
            ),
          ),
        ],
      );
    },
  );
}

class SportPaceValue {
  const SportPaceValue({
    required this.secondsPerKm,
    required this.unit,
  });

  final int secondsPerKm;
  final String unit; // /km | /mi
}

/// Pace picker: minutes / seconds / unit.
Future<SportPaceValue?> showSportPacePicker(
  BuildContext context, {
  SportPaceValue? initial,
}) async {
  final total = initial?.secondsPerKm ?? 0;
  var minutes = (total ~/ 60).clamp(0, 59);
  var seconds = (total % 60).clamp(0, 59);
  var unitIndex = (initial?.unit == '/mi') ? 1 : 0;

  return showDialog<SportPaceValue>(
    context: context,
    builder: (dialogContext) {
      final colors = dialogContext.appColors;
      final l10n = dialogContext.l10n;
      return AlertDialog(
        backgroundColor: colors.card,
        title: Text(
          l10n.createPersonalSportPace,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SizedBox(
          height: 180,
          width: 300,
          child: Row(
            children: [
              Expanded(
                child: CupertinoPicker(
                  scrollController:
                      FixedExtentScrollController(initialItem: minutes),
                  itemExtent: 36,
                  onSelectedItemChanged: (v) => minutes = v,
                  children: [
                    for (var i = 0; i < 60; i++)
                      Center(
                        child: Text(
                          '$i',
                          style: TextStyle(color: colors.textPrimary),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController:
                      FixedExtentScrollController(initialItem: seconds),
                  itemExtent: 36,
                  onSelectedItemChanged: (v) => seconds = v,
                  children: [
                    for (var i = 0; i < 60; i++)
                      Center(
                        child: Text(
                          '$i',
                          style: TextStyle(color: colors.textPrimary),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController:
                      FixedExtentScrollController(initialItem: unitIndex),
                  itemExtent: 36,
                  onSelectedItemChanged: (v) => unitIndex = v,
                  children: [
                    Center(
                      child: Text(
                        '/km',
                        style: TextStyle(color: colors.textPrimary),
                      ),
                    ),
                    Center(
                      child: Text(
                        '/mi',
                        style: TextStyle(color: colors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () {
              final unit = unitIndex == 1 ? '/mi' : '/km';
              var perKm = minutes * 60 + seconds;
              if (unit == '/mi') {
                // Convert min/mi → min/km for storage.
                perKm = (perKm / 1.609344).round();
              }
              Navigator.of(dialogContext).pop(
                SportPaceValue(secondsPerKm: perKm, unit: unit),
              );
            },
            child: Text(
              l10n.actionOk,
              style: TextStyle(color: colors.primary),
            ),
          ),
        ],
      );
    },
  );
}

String formatSportDuration(Duration value) {
  final h = value.inHours;
  final m = value.inMinutes.remainder(60);
  final s = value.inSeconds.remainder(60);
  if (h > 0) {
    return '${h}h ${m.toString().padLeft(2, '0')}min ${s.toString().padLeft(2, '0')}s';
  }
  return '${m}min ${s.toString().padLeft(2, '0')}s';
}

String formatSportDistanceKm(double kilometers, String unit) {
  if (unit == 'mi') {
    final miles = kilometers / 1.609344;
    return '${miles.toStringAsFixed(1).replaceAll('.', ',')} mi';
  }
  return '${kilometers.toStringAsFixed(1).replaceAll('.', ',')} km';
}

String formatSportPace(int secondsPerKm, String unit) {
  var seconds = secondsPerKm;
  if (unit == '/mi') {
    seconds = (secondsPerKm * 1.609344).round();
  }
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')} $unit';
}
