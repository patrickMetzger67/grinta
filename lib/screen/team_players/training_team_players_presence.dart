import 'package:flutter/material.dart';

import '../../model/player.dart';
import '../../model/training.dart';
import '../../util/app_theme.dart';

class TrainingPresenceStyle {
  const TrainingPresenceStyle({
    required this.cardColor,
    required this.accentColor,
    required this.badgeBackground,
    required this.badgeForeground,
    required this.label,
  });

  /// Fond de la ligne — toujours la carte du thème.
  final Color cardColor;

  /// Bordure / indicateur de statut.
  final Color accentColor;

  /// Fond du badge de présence.
  final Color badgeBackground;

  /// Texte du badge de présence.
  final Color badgeForeground;

  final String label;
}

TrainingPresenceStyle presenceStyleFor(
  AppColors colors,
  PresenceType? type, {
  required String labelPresent,
  required String labelInjured,
  required String labelExcused,
  required String labelAbsent,
  required String labelLate,
  required String labelUnknown,
}) {
  final Color accent;
  final String label;

  switch (type) {
    case PresenceType.present:
      accent = colors.success;
      label = labelPresent;
    case PresenceType.blesse:
      accent = colors.danger;
      label = labelInjured;
    case PresenceType.excuse:
      accent = colors.warning;
      label = labelExcused;
    case PresenceType.absent:
      accent = colors.textSecondary;
      label = labelAbsent;
    case PresenceType.late:
      accent = colors.primary;
      label = labelLate;
    case null:
      accent = colors.textSecondary;
      label = labelUnknown;
  }

  return TrainingPresenceStyle(
    cardColor: colors.card,
    accentColor: accent,
    badgeBackground: accent.withValues(alpha: 0.14),
    badgeForeground: accent,
    label: label,
  );
}

/// Teinte légère pour les puces récap (lisible en clair et en sombre).
Color presenceTint(AppColors colors, PresenceType? type) {
  switch (type) {
    case PresenceType.present:
      return colors.success.withValues(alpha: 0.12);
    case PresenceType.blesse:
      return colors.danger.withValues(alpha: 0.12);
    case PresenceType.excuse:
      return colors.warning.withValues(alpha: 0.12);
    case PresenceType.absent:
      return colors.textSecondary.withValues(alpha: 0.12);
    case PresenceType.late:
      return colors.primary.withValues(alpha: 0.12);
    case null:
      return colors.border;
  }
}

Color presenceAccent(AppColors colors, PresenceType? type) {
  switch (type) {
    case PresenceType.present:
      return colors.success;
    case PresenceType.blesse:
      return colors.danger;
    case PresenceType.excuse:
      return colors.warning;
    case PresenceType.absent:
      return colors.textSecondary;
    case PresenceType.late:
      return colors.primary;
    case null:
      return colors.textSecondary;
  }
}

bool _isPlayerUnavailableAtMs(
  Player player,
  int eventMs, {
  String? seasonId,
  bool managerView = true,
}) {
  final Iterable<Unavailability> entries;
  if (seasonId != null && seasonId.trim().isNotEmpty) {
    entries = player.unavailabilitiesForSeason(seasonId);
  } else {
    entries = player.allUnavailabilities;
  }

  final visibleEntries = managerView
      ? entries
      : entries.where((entry) => entry.isVisible ?? true);
  if (visibleEntries.isEmpty) return false;

  for (final entry in visibleEntries) {
    final from = entry.from?.millisecondsSinceEpoch;
    final to = entry.to?.millisecondsSinceEpoch;
    if (from == null || to == null) continue;
    if (from <= eventMs && to >= eventMs) {
      return true;
    }
  }

  return false;
}

/// Whether [player] has a visible unavailability covering [date] for [seasonId].
bool isPlayerUnavailableOnDate(
  Player player,
  String? seasonId,
  DateTime? date, {
  bool managerView = true,
}) {
  if (date == null) return false;

  return _isPlayerUnavailableAtMs(
    player,
    date.millisecondsSinceEpoch,
    seasonId: seasonId,
    managerView: managerView,
  );
}

bool isPlayerUnavailableOnTrainingDate(
  Player player,
  DateTime? trainingDate, {
  String? seasonId,
}) {
  return isPlayerUnavailableOnDate(
    player,
    seasonId,
    trainingDate,
  );
}

bool isPlayerCurrentlyUnavailable(
  Player player,
  String? seasonId, {
  bool managerView = false,
  DateTime? at,
}) {
  return _isPlayerUnavailableAtMs(
    player,
    (at ?? DateTime.now()).millisecondsSinceEpoch,
    seasonId: seasonId,
    managerView: managerView,
  );
}

PresenceType defaultPresenceForPlayer(
  Player player,
  DateTime? trainingDate, {
  String? seasonId,
}) {
  if (isPlayerUnavailableOnTrainingDate(
    player,
    trainingDate,
    seasonId: seasonId,
  )) {
    return PresenceType.absent;
  }
  return PresenceType.present;
}
