import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';

import '../model/player.dart';
import '../util/app_theme.dart';
import '../util/player_age.dart';
import 'playerPhoto.dart';

/// Bulle d'info joueur (nom, prénom, âge, capteur optionnel) au tap sur l'avatar.
Future<void> showPlayerInfoBubble(
  BuildContext context,
  Player player, {
  String? sensorLabel,
}) {
  final colors = context.appColors;
  final l10n = context.l10n;

  final lastName = (player.lastName ?? '').trim();
  final firstName = (player.firstName ?? '').trim();
  final ageYears = playerAgeYears(player);
  final ageLabel = ageYears != null
      ? l10n.playerAgeYears(ageYears)
      : l10n.playerAgeUnknown;
  final trimmedSensor = sensorLabel?.trim();
  final bool showSensor =
      trimmedSensor != null && trimmedSensor.isNotEmpty;

  return showDialog<void>(
    context: context,
    barrierColor: Colors.black38,
    builder: (ctx) {
      return Dialog(
        backgroundColor: colors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colors.primary.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: PlayerPhoto(player: player, radius: 40)),
              const SizedBox(height: 14),
              if (lastName.isNotEmpty)
                Text(
                  lastName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              if (firstName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  firstName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (lastName.isEmpty && firstName.isEmpty)
                Text(
                  l10n.entityPlayer,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                ageLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (showSensor) ...[
                const SizedBox(height: 6),
                Text(
                  '${l10n.trainingPlayersSelectTracker} $trimmedSensor',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.trainingPlayersClose),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
