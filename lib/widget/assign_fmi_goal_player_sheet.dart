import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/matchStats.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/highlightsService.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/match_compo_pitch_mapper.dart';
import 'package:grinta/util/match_creation_helper.dart';
import 'package:grinta/util/match_goal_helper.dart';
import 'package:grinta/util/player_cards_helper.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/widget/player_name_filter_field.dart';
import 'package:provider/provider.dart';

/// Result of the FMI goal scorer + optional assister picker.
class AssignFmiGoalPlayerSelection {
  const AssignFmiGoalPlayerSelection({
    required this.scorerMemberId,
    this.assisterMemberId,
  });

  final String scorerMemberId;
  final String? assisterMemberId;
}

/// Manager-only: pick scorer then optional decisive passer for an FMI goal.
Future<AssignFmiGoalPlayerSelection?> showAssignFmiGoalPlayerSheet(
  BuildContext context, {
  required GoalType goalType,
  required int minute,
  List<AssignFmiCardPlayerOption>? players,
  Future<List<AssignFmiCardPlayerOption>>? playersFuture,
}) {
  assert(players != null || playersFuture != null);

  Widget buildSheet() {
    return AssignFmiGoalPlayerSheet(
      goalType: goalType,
      minute: minute,
      players: players,
      playersFuture: playersFuture,
    );
  }

  if (kIsWeb) {
    return showDialog<AssignFmiGoalPlayerSelection>(
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

  return showModalBottomSheet<AssignFmiGoalPlayerSelection>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useRootNavigator: true,
    backgroundColor: context.appColors.card,
    builder: (_) => buildSheet(),
  );
}

/// Full FMI write path: load convocations, pick scorer/assister, add Grinta goal.
Future<void> assignFmiGoalHighlightToPlayer(
  BuildContext context, {
  required models.Match match,
  required MatchStatHighLight highlight,
  HighlightsService? highlightsService,
  Future<List<AssignFmiCardPlayerOption>>? playersFuture,
}) async {
  if (!context.mounted) {
    return;
  }

  if (!isFmiGoalHighlight(highlight)) {
    return;
  }

  final matchId = match.id?.trim() ?? '';
  if (matchId.isEmpty) {
    AppSnackbar.show(context, context.l10n.errorMatchIdMissing);
    return;
  }

  final session = context.read<AppSession>();
  final managedTeamIds = managedMatchTeamIds(match, session);
  final clubIdByTeamId =
      clubIdByTeamIdFromTeams(session.teamsForAgendaSelectedSeason);
  if (!isManagedTeamFmiGoal(
    match,
    highlight,
    managedTeamIds,
    clubIdByTeamId: clubIdByTeamId,
  )) {
    return;
  }

  final MatchSide? side = sideForFmiHighlightTeam(match, highlight);
  if (side == null) {
    return;
  }

  final future = playersFuture ??
      loadConvokedPlayersForCardAssignment(
        match: match,
        managedTeamIds: managedTeamIds,
      );

  final goalType = goalTypeFromFmiHighlight(highlight);
  final selection = await showAssignFmiGoalPlayerSheet(
    context,
    goalType: goalType,
    minute: highlight.time ?? 0,
    playersFuture: future,
  );
  if (!context.mounted || selection == null) {
    return;
  }

  final scorerId = selection.scorerMemberId.trim();
  if (scorerId.isEmpty) {
    return;
  }

  List<AssignFmiCardPlayerOption> players;
  try {
    players = await future;
  } catch (_) {
    players = const <AssignFmiCardPlayerOption>[];
  }

  final scorerLabel = _labelForSelectedPlayer(players, scorerId);
  final assisterId = selection.assisterMemberId?.trim();
  final String? decisivePasserId =
      (assisterId == null || assisterId.isEmpty || assisterId == scorerId)
          ? null
          : assisterId;

  final teamId = teamIdForSide(match, side, clubIdByTeamId: clubIdByTeamId) ??
      resolveTeamIdForMatch(match, managedTeamIds: managedTeamIds);

  final goal = Goal(
    affiliationTeam: affiliationTeamForSide(match, side),
    goalType: goalType,
    playerId: scorerId,
    playerName: scorerLabel,
    decisivePasserPlayerId: decisivePasserId,
  );

  try {
    await saveFmiAssignedGoalHighlight(
      match: match,
      side: side,
      goal: goal,
      teamId: teamId,
      minute: highlight.time ?? 0,
      highlightsService: highlightsService,
      updateScore: false,
    );
    if (!context.mounted) {
      return;
    }
    AppSnackbar.show(
      context,
      context.l10n.fmiGoalAssigned(scorerLabel),
      isError: false,
    );
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    AppSnackbar.show(
      context,
      context.l10n.fmiGoalAssignError(error.toString()),
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

class AssignFmiGoalPlayerSheet extends StatefulWidget {
  const AssignFmiGoalPlayerSheet({
    super.key,
    required this.goalType,
    required this.minute,
    this.players,
    this.playersFuture,
  });

  static const Key sheetKey = Key('assignFmiGoalPlayerSheet');
  static const Key noAssisterKey = Key('assignFmiGoalNoAssister');
  static const Key backToScorerKey = Key('assignFmiGoalBackToScorer');

  static Key scorerKey(String memberId) =>
      Key('assignFmiGoalScorer-$memberId');

  static Key assisterKey(String memberId) =>
      Key('assignFmiGoalAssister-$memberId');

  final GoalType goalType;
  final int minute;
  final List<AssignFmiCardPlayerOption>? players;
  final Future<List<AssignFmiCardPlayerOption>>? playersFuture;

  @override
  State<AssignFmiGoalPlayerSheet> createState() =>
      _AssignFmiGoalPlayerSheetState();
}

enum _AssignFmiGoalStep { scorer, assister }

class _AssignFmiGoalPlayerSheetState extends State<AssignFmiGoalPlayerSheet> {
  final TextEditingController _nameFilterCtrl = TextEditingController();
  final FocusNode _nameFilterFocus = FocusNode();
  List<AssignFmiCardPlayerOption>? _players;
  Object? _error;
  bool _loading = false;
  _AssignFmiGoalStep _step = _AssignFmiGoalStep.scorer;
  String? _scorerMemberId;

  @override
  void initState() {
    super.initState();
    if (widget.players != null) {
      _players = widget.players;
      return;
    }
    _load();
  }

  @override
  void dispose() {
    _nameFilterCtrl.dispose();
    _nameFilterFocus.dispose();
    super.dispose();
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
    switch (widget.goalType) {
      case GoalType.penalty:
        return l10n.highlightTypePenalty;
      case GoalType.freeKick:
      case GoalType.normal:
        return l10n.highlightTypeGoal;
    }
  }

  void _selectScorer(String memberId) {
    setState(() {
      _scorerMemberId = memberId;
      _step = _AssignFmiGoalStep.assister;
      _nameFilterCtrl.clear();
    });
  }

  void _backToScorer() {
    setState(() {
      _step = _AssignFmiGoalStep.scorer;
      _scorerMemberId = null;
      _nameFilterCtrl.clear();
    });
  }

  void _finish({String? assisterMemberId}) {
    final scorerId = _scorerMemberId?.trim() ?? '';
    if (scorerId.isEmpty) {
      return;
    }
    Navigator.of(context).pop(
      AssignFmiGoalPlayerSelection(
        scorerMemberId: scorerId,
        assisterMemberId: assisterMemberId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final players = _players;
    final pickingAssister = _step == _AssignFmiGoalStep.assister;

    return SafeArea(
      key: AssignFmiGoalPlayerSheet.sheetKey,
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
            if (pickingAssister) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: AssignFmiGoalPlayerSheet.backToScorerKey,
                  onPressed: _backToScorer,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text(l10n.fmiGoalPickScorerTitle),
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              pickingAssister
                  ? l10n.fmiGoalPickAssisterTitle
                  : l10n.fmiGoalPickScorerTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              pickingAssister
                  ? l10n.fmiGoalPickAssisterSubtitle(
                      _labelForSelectedPlayer(
                        players ?? const <AssignFmiCardPlayerOption>[],
                        _scorerMemberId ?? '',
                      ),
                      widget.minute,
                    )
                  : l10n.fmiGoalPickScorerSubtitle(
                      _typeLabel(l10n),
                      widget.minute,
                    ),
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
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
                  l10n.fmiGoalNoConvokedPlayers,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              )
            else ...[
              if (pickingAssister) ...[
                ListTile(
                  key: AssignFmiGoalPlayerSheet.noAssisterKey,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.fmiGoalNoAssister,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () => _finish(),
                ),
                const SizedBox(height: 4),
              ],
              PlayerNameFilterField(
                controller: _nameFilterCtrl,
                focusNode: _nameFilterFocus,
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _nameFilterCtrl,
                builder: (context, value, _) {
                  final scorerId = _scorerMemberId;
                  final filtered = players
                      .where((player) {
                        if (pickingAssister &&
                            scorerId != null &&
                            player.memberId == scorerId) {
                          return false;
                        }
                        return playerLabelMatchesNameQuery(
                          player.label,
                          value.text,
                        );
                      })
                      .toList(growable: false);

                  if (filtered.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        l10n.emptyNoPlayerForTeam,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }

                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 360),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final player = filtered[index];
                        return ListTile(
                          key: pickingAssister
                              ? AssignFmiGoalPlayerSheet.assisterKey(
                                  player.memberId,
                                )
                              : AssignFmiGoalPlayerSheet.scorerKey(
                                  player.memberId,
                                ),
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            player.label,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onTap: () {
                            if (pickingAssister) {
                              _finish(assisterMemberId: player.memberId);
                            } else {
                              _selectScorer(player.memberId);
                            }
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
