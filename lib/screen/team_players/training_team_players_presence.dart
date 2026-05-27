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

bool isPlayerUnavailableOnTrainingDate(Player player, DateTime? trainingDate) {
  if (trainingDate == null) return false;
  final unavailable = player.unavailable;
  if (unavailable == null || unavailable.isEmpty) return false;

  final eventMs = trainingDate.millisecondsSinceEpoch;

  for (final entry in unavailable) {
    if (entry is! Unavailability) continue;
    final from = entry.from?.millisecondsSinceEpoch;
    final to = entry.to?.millisecondsSinceEpoch;
    if (from == null || to == null) continue;
    if (from <= eventMs && to >= eventMs) {
      return true;
    }
  }

  return false;
}

PresenceType defaultPresenceForPlayer(Player player, DateTime? trainingDate) {
  if (isPlayerUnavailableOnTrainingDate(player, trainingDate)) {
    return PresenceType.excuse;
  }
  return PresenceType.present;
}
