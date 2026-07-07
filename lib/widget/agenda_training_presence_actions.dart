import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/answer.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/training.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/answerService.dart';
import 'package:grinta/services/opponent_stats_view_tracker.dart';
import 'package:grinta/services/trainingService.dart';
import 'package:grinta/screen/team_players/training_team_players_presence.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:provider/provider.dart';

/// Quick presence confirmation for players on agenda training cards.
class AgendaTrainingPresenceActions extends StatefulWidget {
  const AgendaTrainingPresenceActions({
    super.key,
    required this.training,
    required this.trainingDate,
    this.seasonId,
  });

  final Training training;
  final DateTime trainingDate;
  final String? seasonId;

  @override
  State<AgendaTrainingPresenceActions> createState() =>
      _AgendaTrainingPresenceActionsState();
}

class _AgendaTrainingPresenceActionsState
    extends State<AgendaTrainingPresenceActions> {
  bool _saving = false;
  bool? _confirmedPresent;

  Future<void> _confirmPresence({required bool present}) async {
    if (_saving) return;

    final session = context.read<AppSession>();
    final player = session.selectedPlayer;
    final playerId = player?.ref?.id?.trim() ?? '';
    final trainingId = widget.training.trainingId?.trim() ?? '';
    if (player == null || playerId.isEmpty || trainingId.isEmpty) return;

    if (isPlayerUnavailableOnTrainingDate(
      player,
      widget.trainingDate,
      seasonId: widget.seasonId,
    )) {
      return;
    }

    setState(() => _saving = true);
    try {
      final answerService = AnswerService();
      final existing = await answerService.getFirstAnswerByObjectIdAndUserId(
        objectId: trainingId,
        userId: playerId,
      );

      final presenceType =
          present ? PresenceType.present : PresenceType.absent;
      final playerTraining = PlayerTraining(
        playerId: playerId,
        presenceType: presenceType,
      );

      final answer = existing ??
          Answer(
            objectId: trainingId,
            userId: playerId,
            createDateTime: Timestamp.now(),
            isTraining: true,
            isPresent: present,
            playerTraining: playerTraining,
            dateTimEvent: Timestamp.fromDate(widget.trainingDate),
          );

      answer.isPresent = present;
      answer.playerTraining = playerTraining;
      answer.updateDateTime = Timestamp.now();
      answer.dateTimEvent = Timestamp.fromDate(widget.trainingDate);

      if (answer.ref != null) {
        await answerService.updateAnswer(answer);
      } else {
        final ref = await answerService.addAnswer(answer);
        answer.ref = ref;
      }

      final docId = widget.training.docId?.trim() ?? '';
      if (docId.isNotEmpty) {
        await TrainingService().upsertOnePlayerTraining(
          trainingId: docId,
          player: playerTraining,
        );
      }

      if (mounted) {
        setState(() => _confirmedPresent = present);
      }
      await InternalReminderServiceBridge.notifyPresenceConfirmed();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorGeneric('presence'))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    if (_confirmedPresent != null) {
      return Text(
        _confirmedPresent!
            ? l10n.trainingPresenceConfirmedPresent
            : l10n.trainingPresenceConfirmedAbsent,
        style: TextStyle(color: colors.success, fontWeight: FontWeight.w600),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _saving ? null : () => _confirmPresence(present: true),
            child: Text(l10n.trainingPresenceConfirmPresent),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: _saving ? null : () => _confirmPresence(present: false),
            child: Text(l10n.trainingPresenceConfirmAbsent),
          ),
        ),
      ],
    );
  }
}
