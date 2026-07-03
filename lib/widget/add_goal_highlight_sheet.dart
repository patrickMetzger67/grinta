import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/matchCompo.dart';
import 'package:grinta/services/matchCompoService.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/highlight_minute_helper.dart';
import 'package:grinta/util/match_compo_pitch_mapper.dart';
import 'package:grinta/util/match_goal_helper.dart';

/// Goal highlight entry: team → scorer/assister or opponent jersey → save.
Future<bool?> showAddGoalHighlightSheet(
  BuildContext context, {
  required models.Match match,
  required List<String> managedTeamIds,
  required List<Highlights> existingHighlights,
}) {
  if (kIsWeb) {
    return showDialog<bool>(
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
          child: AddGoalHighlightSheet(
            match: match,
            managedTeamIds: managedTeamIds,
            existingHighlights: existingHighlights,
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useRootNavigator: true,
    backgroundColor: context.appColors.card,
    builder: (_) => AddGoalHighlightSheet(
      match: match,
      managedTeamIds: managedTeamIds,
      existingHighlights: existingHighlights,
    ),
  );
}

class AddGoalHighlightSheet extends StatefulWidget {
  const AddGoalHighlightSheet({
    super.key,
    required this.match,
    required this.managedTeamIds,
    required this.existingHighlights,
  });

  final models.Match match;
  final List<String> managedTeamIds;
  final List<Highlights> existingHighlights;

  @override
  State<AddGoalHighlightSheet> createState() => _AddGoalHighlightSheetState();
}

class _AddGoalHighlightSheetState extends State<AddGoalHighlightSheet> {
  final _jerseyController = TextEditingController();
  final _minuteController = TextEditingController();
  final _matchCompoService = MatchCompoService();

  MatchSide? _selectedSide;
  MatchCompo? _matchCompo;
  List<PlayerCompo> _players = const <PlayerCompo>[];
  PlayerCompo? _scorer;
  PlayerCompo? _assister;
  bool _loadingCompo = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final suggestion = suggestedMinuteForAction(
      match: widget.match,
      highlights: widget.existingHighlights,
    );
    _minuteController.text = suggestion.minute.toString();
  }

  @override
  void dispose() {
    _jerseyController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  bool get _isManagedSelected =>
      _selectedSide != null &&
      isManagedSide(widget.match, _selectedSide!, widget.managedTeamIds);

  bool get _usePlayerPicker =>
      _isManagedSelected && compoHasPlayers(_matchCompo);

  Future<void> _selectSide(MatchSide side) async {
    setState(() {
      _selectedSide = side;
      _scorer = null;
      _assister = null;
      _matchCompo = null;
      _players = const <PlayerCompo>[];
      _error = null;
      _jerseyController.clear();
    });

    if (!isManagedSide(widget.match, side, widget.managedTeamIds)) {
      return;
    }

    final String? teamId = teamIdForSide(widget.match, side);
    final String? matchId = widget.match.id?.trim();
    if (teamId == null || matchId == null || matchId.isEmpty) {
      return;
    }

    setState(() => _loadingCompo = true);

    try {
      final MatchCompo? compo =
          await _matchCompoService.getMatchCompoByMatchAndTeamId(
        matchId,
        teamId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _matchCompo = compo;
        _players = compo == null ? const <PlayerCompo>[] : allPlayersFromCompo(compo);
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loadingCompo = false);
      }
    }
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final MatchSide? side = _selectedSide;
    if (side == null || _saving) {
      return;
    }

    final int? minute = parseHighlightMinute(_minuteController.text);
    if (minute == null) {
      setState(() => _error = l10n.matchGoalInvalidMinute);
      return;
    }

    if (_usePlayerPicker && _scorer == null) {
      setState(() => _error = l10n.matchGoalScorerRequired);
      return;
    }

    int? opponentNumber;
    if (!_usePlayerPicker) {
      final String raw = _jerseyController.text.trim();
      if (raw.isNotEmpty) {
        opponentNumber = int.tryParse(raw);
        if (opponentNumber == null) {
          setState(() => _error = l10n.matchGoalInvalidJerseyNumber);
          return;
        }
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final Goal goal = Goal(
        affiliationTeam: affiliationTeamForSide(widget.match, side),
        goalType: GoalType.normal,
        playerId: _scorer?.playerID,
        playerName: _scorer?.playerNameDisplayed ?? _scorer?.customName,
        decisivePasserPlayerId: _assister?.playerID,
      )..playerNumber = _usePlayerPicker ? _scorer?.number : opponentNumber;

      final String? highlightTeamId = resolveTeamIdForMatch(
        widget.match,
        managedTeamIds: widget.managedTeamIds,
      );

      await saveGoalHighlightAndUpdateScore(
        match: widget.match,
        side: side,
        goal: goal,
        teamId: highlightTeamId,
        minute: minute,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.toString();
        });
      }
    }
  }

  InputDecoration _dropdownDecoration(BuildContext context, String label) {
    final colors = context.appColors;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colors.textSecondary),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return SafeArea(
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
              l10n.matchGoalAddTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _minuteController,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.matchGoalMinuteTitle,
                hintText: l10n.matchGoalMinuteHint,
                labelStyle: TextStyle(color: colors.textSecondary),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.matchGoalPickTeamTitle,
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TeamChoiceChip(
                    label: teamDisplayNameForSide(widget.match, MatchSide.team1),
                    selected: _selectedSide == MatchSide.team1,
                    onTap: _saving ? null : () => _selectSide(MatchSide.team1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TeamChoiceChip(
                    label: teamDisplayNameForSide(widget.match, MatchSide.team2),
                    selected: _selectedSide == MatchSide.team2,
                    onTap: _saving ? null : () => _selectSide(MatchSide.team2),
                  ),
                ),
              ],
            ),
            if (_selectedSide != null) ...[
              const SizedBox(height: 18),
              if (_loadingCompo)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_usePlayerPicker) ...[
                DropdownButtonFormField<PlayerCompo>(
                  value: _scorer != null &&
                          _players.any(
                            (p) => p.playerID == _scorer!.playerID,
                          )
                      ? _scorer
                      : null,
                  isExpanded: true,
                  dropdownColor: colors.surface,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: _dropdownDecoration(
                    context,
                    l10n.matchGoalPickScorerTitle,
                  ),
                  hint: Text(l10n.matchGoalSelectScorer),
                  items: _players
                      .map(
                        (player) => DropdownMenuItem<PlayerCompo>(
                          value: player,
                          child: Text(displayLabelForPlayerCompo(player)),
                        ),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (player) => setState(() {
                            _scorer = player;
                            if (_assister?.playerID == player?.playerID) {
                              _assister = null;
                            }
                          }),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<PlayerCompo?>(
                  value: _assister != null &&
                          _players.any(
                            (p) => p.playerID == _assister!.playerID,
                          )
                      ? _assister
                      : null,
                  isExpanded: true,
                  dropdownColor: colors.surface,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: _dropdownDecoration(
                    context,
                    l10n.matchGoalPickAssisterTitle,
                  ),
                  items: [
                    DropdownMenuItem<PlayerCompo?>(
                      value: null,
                      child: Text(l10n.matchGoalNoAssister),
                    ),
                    for (final player in _players)
                      if (player.playerID != _scorer?.playerID)
                        DropdownMenuItem<PlayerCompo?>(
                          value: player,
                          child: Text(displayLabelForPlayerCompo(player)),
                        ),
                  ],
                  onChanged: _saving
                      ? null
                      : (player) => setState(() => _assister = player),
                ),
              ] else ...[
                Text(
                  l10n.matchGoalOpponentJerseyTitle,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _jerseyController,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: l10n.matchGoalOpponentJerseyHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: colors.danger, fontSize: 13),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _selectedSide == null || _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.actionSave),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamChoiceChip extends StatelessWidget {
  const _TeamChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final String display = label.isNotEmpty ? label : '—';

    return Material(
      color: selected ? colors.primary.withValues(alpha: 0.12) : colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Text(
            display,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? colors.primary : colors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
