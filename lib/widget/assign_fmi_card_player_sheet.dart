import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/matchStats.dart';
import 'package:grinta/model/player_cards.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/cards_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/match_creation_helper.dart';
import 'package:grinta/util/player_cards_helper.dart';
import 'package:provider/provider.dart';

/// Manager-only: pick a convoked player for an FMI card highlight.
Future<String?> showAssignFmiCardPlayerSheet(
  BuildContext context, {
  required String cardType,
  required int minute,
  List<AssignFmiCardPlayerOption>? players,
  Future<List<AssignFmiCardPlayerOption>>? playersFuture,
}) {
  assert(players != null || playersFuture != null);

  Widget buildSheet() {
    return AssignFmiCardPlayerSheet(
      cardType: cardType,
      minute: minute,
      players: players,
      playersFuture: playersFuture,
    );
  }

  if (kIsWeb) {
    return showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: context.appColors.card,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: context.appColors.border),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
          child: buildSheet(),
        ),
      ),
    );
  }

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useRootNavigator: true,
    backgroundColor: context.appColors.card,
    builder: (_) => buildSheet(),
  );
}

/// Full FMI write path: load convocations, pick a player, upsert `cards`.
Future<void> assignFmiCardHighlightToPlayer(
  BuildContext context, {
  required models.Match match,
  required MatchStatHighLight highlight,
  CardsService? cardsService,
  Future<List<AssignFmiCardPlayerOption>>? playersFuture,
}) async {
  if (!context.mounted) {
    return;
  }

  final cardType = playerCardTypeFromFmiHighlight(highlight);
  if (cardType == null) {
    return;
  }

  final matchId = match.id?.trim() ?? '';
  if (matchId.isEmpty) {
    AppSnackbar.show(context, context.l10n.errorMatchIdMissing);
    return;
  }

  final session = context.read<AppSession>();
  final managedTeamIds = managedMatchTeamIds(match, session);
  final future = playersFuture ??
      loadConvokedPlayersForCardAssignment(
        match: match,
        managedTeamIds: managedTeamIds,
      );

  final memberId = await showAssignFmiCardPlayerSheet(
    context,
    cardType: cardType,
    minute: highlight.time ?? 0,
    playersFuture: future,
  );
  if (!context.mounted || memberId == null || memberId.isEmpty) {
    return;
  }

  final entry = playerCardEntryFromFmiHighlight(
    matchId: matchId,
    highlight: highlight,
    memberId: memberId,
  );
  if (entry == null) {
    return;
  }

  try {
    await (cardsService ?? CardsService.instance).addEntry(
      memberId: memberId,
      entry: entry,
    );
    List<AssignFmiCardPlayerOption> players;
    try {
      players = await future;
    } catch (_) {
      players = const <AssignFmiCardPlayerOption>[];
    }
    if (!context.mounted) {
      return;
    }
    AppSnackbar.show(
      context,
      context.l10n.fmiCardAssigned(
        _labelForSelectedPlayer(players, memberId),
      ),
      isError: false,
    );
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    AppSnackbar.show(
      context,
      context.l10n.fmiCardAssignError(error.toString()),
    );
  }
}

String _labelForSelectedPlayer(
  List<AssignFmiCardPlayerOption> players,
  String memberId,
) {
  for (final player in players) {
    if (player.memberId == memberId) {
      return player.label;
    }
  }
  return memberId;
}

class AssignFmiCardPlayerSheet extends StatefulWidget {
  const AssignFmiCardPlayerSheet({
    super.key,
    required this.cardType,
    required this.minute,
    this.players,
    this.playersFuture,
  });

  static const Key sheetKey = Key('assignFmiCardPlayerSheet');

  static Key playerKey(String memberId) =>
      Key('assignFmiCardPlayer-$memberId');

  final String cardType;
  final int minute;
  final List<AssignFmiCardPlayerOption>? players;
  final Future<List<AssignFmiCardPlayerOption>>? playersFuture;

  @override
  State<AssignFmiCardPlayerSheet> createState() =>
      _AssignFmiCardPlayerSheetState();
}

class _AssignFmiCardPlayerSheetState extends State<AssignFmiCardPlayerSheet> {
  List<AssignFmiCardPlayerOption>? _players;
  Object? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.players != null) {
      _players = widget.players;
      return;
    }
    _load();
  }

  Future<void> _load() async {
    final future = widget.playersFuture;
    if (future == null) {
      setState(() => _players = const <AssignFmiCardPlayerOption>[]);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final players = await future;
      if (!mounted) {
        return;
      }
      setState(() {
        _players = players;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  String _typeLabel(AppLocalizations l10n) {
    switch (widget.cardType) {
      case playerCardTypeYellow:
        return l10n.highlightTypeYellowCard;
      case playerCardTypeRed:
        return l10n.highlightTypeRedCard;
      default:
        return widget.cardType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final players = _players;

    return SafeArea(
      key: AssignFmiCardPlayerSheet.sheetKey,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.fmiCardPickPlayerTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.fmiCardPickPlayerSubtitle(_typeLabel(l10n), widget.minute),
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Text(
                _error.toString(),
                style: TextStyle(color: colors.danger, fontSize: 13),
              )
            else if (players == null || players.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  l10n.fmiCardNoConvokedPlayers,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: players.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final player = players[index];
                    return ListTile(
                      key: AssignFmiCardPlayerSheet.playerKey(player.memberId),
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        player.label,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onTap: () => Navigator.of(context).pop(player.memberId),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
