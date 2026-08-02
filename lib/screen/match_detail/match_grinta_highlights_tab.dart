import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/highlightsService.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/highlight_type_icons.dart';
import 'package:grinta/util/highlight_minute_helper.dart';
import 'package:grinta/util/match_compo_pitch_mapper.dart';
import 'package:grinta/util/match_creation_helper.dart';
import 'package:grinta/util/match_card_helper.dart';
import 'package:grinta/util/match_goal_helper.dart';
import 'package:grinta/util/match_substitution_helper.dart';
import 'package:grinta/util/match_intense_finish_helper.dart';
import 'package:grinta/util/match_time_event_helper.dart';
import 'package:grinta/widget/add_card_highlight_sheet.dart';
import 'package:grinta/widget/add_goal_highlight_sheet.dart';
import 'package:grinta/widget/add_substitution_highlight_sheet.dart';
import 'package:provider/provider.dart';

class MatchGrintaHighlightsTab extends StatefulWidget {
  const MatchGrintaHighlightsTab({
    super.key,
    required this.match,
    required this.isManager,
  });

  final models.Match match;
  final bool isManager;

  @override
  State<MatchGrintaHighlightsTab> createState() =>
      _MatchGrintaHighlightsTabState();
}

class _MatchGrintaHighlightsTabState extends State<MatchGrintaHighlightsTab> {
  bool _saving = false;
  bool _healingScore = false;
  String? _scoreHealedForMatchId;

  String get _matchCalendarId => (widget.match.id ?? '').trim();

  bool get _canEdit =>
      widget.isManager && widget.match.isMatchPlayed != true;

  /// Repairs match.homeScore/outSideScore when they drifted from goal highlights.
  void _maybeHealScoreFromHighlights(List<Highlights> highlights) {
    if (!widget.isManager || _healingScore) {
      return;
    }
    final matchId = _matchCalendarId;
    if (matchId.isEmpty || _scoreHealedForMatchId == matchId) {
      return;
    }
    final hasGoals =
        highlights.any((h) => h.actionType == ActionType.goal);
    if (!hasGoals) {
      return;
    }

    final computed = scoreFromGoalHighlights(widget.match, highlights);
    final storedHome = widget.match.homeScore ?? 0;
    final storedAway = widget.match.outSideScore ?? 0;
    if (computed.homeScore == storedHome &&
        computed.outsideScore == storedAway) {
      _scoreHealedForMatchId = matchId;
      return;
    }

    _healingScore = true;
    _scoreHealedForMatchId = matchId;
    // Fetch unfiltered goals for the match, then rewrite the scoreboard.
    syncMatchScoreFromGoalHighlights(widget.match).whenComplete(() {
      _healingScore = false;
    });
  }

  Future<void> _onAddPressed(List<Highlights> existing) async {
    if (!_canEdit || _saving || _matchCalendarId.isEmpty) {
      return;
    }

    final l10n = context.l10n;
    final requiresKickOff = existing.isEmpty;

    final selected = await showModalBottomSheet<ActionType>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  l10n.matchGrintaHighlightsPickTypeTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (requiresKickOff)
                _HighlightPickerTile(
                  label: l10n.highlightKickoff,
                  style: HighlightTypeIcons.forTimeType(
                    context,
                    TimeType.kickOff,
                  ),
                  onTap: () =>
                      Navigator.of(context).pop(ActionType.timeEvent),
                )
              else
                for (final actionType in ActionType.values)
                  _ActionTypeTile(
                    actionType: actionType,
                    enabled: true,
                    onTap: () => Navigator.of(context).pop(actionType),
                  ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }

    if (requiresKickOff) {
      await _createKickOffHighlight(existing);
      return;
    }

    if (selected == ActionType.timeEvent) {
      await _showTimeEventPicker(existing);
      return;
    }

    if (selected == ActionType.goal) {
      await _showGoalEntryFlow(existing);
      return;
    }

    if (selected == ActionType.yellowCard || selected == ActionType.redCard) {
      await _showCardEntryFlow(existing, selected);
      return;
    }

    if (selected == ActionType.substitution) {
      await _showSubstitutionEntryFlow(existing);
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.matchGrintaHighlightsDetailsComingSoon)),
    );
  }

  String? _highlightTeamId(AppSession session) {
    final profileTeamIds = profileTeamIdsForMatch(
      profileTeamIds: session.teamIdsForSelectedSeason,
      match: widget.match,
    );

    if (widget.isManager) {
      final resolved = resolveTeamIdForMatch(
        widget.match,
        managedTeamIds: managedMatchTeamIds(widget.match, session),
      );
      if (resolved != null && resolved.isNotEmpty) {
        return resolved;
      }
    }

    if (profileTeamIds.isEmpty) {
      return null;
    }

    return profileTeamIds.first;
  }

  Future<void> _showGoalEntryFlow(List<Highlights> existing) async {
    if (_saving || _matchCalendarId.isEmpty) {
      return;
    }

    final session = context.read<AppSession>();
    final managedTeamIds = managedMatchTeamIds(widget.match, session);

    await showAddGoalHighlightSheet(
      context,
      match: widget.match,
      managedTeamIds: managedTeamIds,
      existingHighlights: existing,
    );
  }

  Future<void> _showSubstitutionEntryFlow(List<Highlights> existing) async {
    if (_saving || _matchCalendarId.isEmpty) {
      return;
    }

    final session = context.read<AppSession>();
    final managedTeamIds = managedMatchTeamIds(widget.match, session);

    await showAddSubstitutionHighlightSheet(
      context,
      match: widget.match,
      managedTeamIds: managedTeamIds,
      existingHighlights: existing,
    );
  }

  Future<void> _showCardEntryFlow(
    List<Highlights> existing,
    ActionType actionType,
  ) async {
    if (_saving || _matchCalendarId.isEmpty) {
      return;
    }

    final session = context.read<AppSession>();
    final managedTeamIds = managedMatchTeamIds(widget.match, session);

    await showAddCardHighlightSheet(
      context,
      match: widget.match,
      actionType: actionType,
      managedTeamIds: managedTeamIds,
      existingHighlights: existing,
    );
  }

  Future<void> _showTimeEventPicker(List<Highlights> existing) async {
    final l10n = context.l10n;
    final availableTypes = availableTimeTypes(existing);

    final selectedTimeType = await showModalBottomSheet<TimeType>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  l10n.matchGrintaHighlightsPickTimeEventTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (availableTypes.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Text(
                    l10n.matchGrintaHighlightsAllTimeEventsRecorded,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                  ),
                )
              else
                for (final timeType in availableTypes)
                  _HighlightPickerTile(
                    label: _timeTypeLabel(l10n, timeType),
                    style: HighlightTypeIcons.forTimeType(context, timeType),
                    onTap: () => Navigator.of(context).pop(timeType),
                  ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!mounted || selectedTimeType == null) {
      return;
    }

    await _createTimeEventHighlight(selectedTimeType, existing);
  }

  Future<void> _createKickOffHighlight(List<Highlights> existing) async {
    await _createTimeEventHighlight(TimeType.kickOff, existing);
  }

  Future<void> _createTimeEventHighlight(
    TimeType timeType,
    List<Highlights> existing,
  ) async {
    if (_saving || _matchCalendarId.isEmpty) {
      return;
    }

    final session = context.read<AppSession>();
    final teamId = _highlightTeamId(session);
    if (teamId == null || teamId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorMatchIdMissing)),
        );
      }
      return;
    }

    setState(() => _saving = true);

    try {
      final suggestion = suggestedMinuteForTimeEvent(
        match: widget.match,
        highlights: existing,
        timeType: timeType,
      );

      final highlight = Highlights(
        matchCalendarId: _matchCalendarId,
        teamId: teamId,
        minute: suggestion.minute,
        extraTime: suggestion.extraTime,
        actionType: ActionType.timeEvent,
        value: TimeEvent(type: timeType),
        dateTime: Timestamp.now(),
      );

      await HighlightsService().addHighlight(highlight);

      if (timeType == TimeType.end) {
        final updatedHighlights = <Highlights>[...existing, highlight];
        await updateMatchAfterEndTimeEventHighlight(match: widget.match);
        if (!mounted) return;

        final useIntense =
            await shouldUseIntenseMatchFinishFlow(widget.match);
        if (useIntense && mounted) {
          await finishMatchIntenseSync(
            context,
            match: widget.match,
            highlights: updatedHighlights,
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _onHighlightLongPress(Highlights highlight) async {
    if (!_canEdit || _saving) {
      return;
    }

    final l10n = context.l10n;
    final colors = context.appColors;
    final highlightLabel = _highlightLabel(l10n, highlight);

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: colors.danger),
                title: Text(
                  l10n.actionDelete,
                  style: TextStyle(
                    color: colors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => Navigator.of(sheetContext).pop('delete'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!mounted || action != 'delete') {
      return;
    }

    final confirmed = await confirmDeleteHighlight(
      context,
      highlightLabel: highlightLabel,
    );
    if (!mounted || !confirmed) {
      return;
    }

    setState(() => _saving = true);

    try {
      await deleteHighlightAndMaybeUpdateScore(
        match: widget.match,
        highlight: highlight,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.matchGrintaHighlightDeleted)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final matchCalendarId = _matchCalendarId;
    final session = context.watch<AppSession>();
    final highlightTeamId = _highlightTeamId(session);

    if (matchCalendarId.isEmpty) {
      return _GrintaHighlightsEmptyState(
        title: l10n.matchHighlightsSourceGrinta,
        message: l10n.errorMatchIdMissing,
      );
    }

    if (highlightTeamId == null || highlightTeamId.isEmpty) {
      return _GrintaHighlightsEmptyState(
        title: l10n.matchHighlightsSourceGrinta,
        message: l10n.matchHighlightsGrintaPlaceholderMessage,
      );
    }

    return StreamBuilder<List<Highlights>>(
      stream: HighlightsService().streamHighlightsByMatchCalendarId(
        matchCalendarId,
        teamId: highlightTeamId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return _GrintaHighlightsEmptyState(
            title: l10n.matchHighlightsSourceGrinta,
            message: snapshot.error.toString(),
          );
        }

        final highlights = snapshot.data ?? const <Highlights>[];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _maybeHealScoreFromHighlights(highlights);
        });

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: _canEdit
              ? FloatingActionButton(
                  tooltip: l10n.matchGrintaHighlightsAddAction,
                  onPressed:
                      _saving ? null : () => _onAddPressed(highlights),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_rounded),
                )
              : null,
          body: highlights.isEmpty
              ? _GrintaHighlightsEmptyState(
                  title: l10n.matchHighlightsSourceGrinta,
                  message: _canEdit
                      ? l10n.matchGrintaHighlightsEmptyMessage
                      : l10n.matchHighlightsGrintaPlaceholderMessage,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 88),
                  itemCount: highlights.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _GrintaHighlightTile(
                      match: widget.match,
                      highlight: highlights[index],
                      onLongPress: _canEdit
                          ? () => _onHighlightLongPress(highlights[index])
                          : null,
                    );
                  },
                ),
        );
      },
    );
  }
}

class _ActionTypeTile extends StatelessWidget {
  const _ActionTypeTile({
    required this.actionType,
    required this.enabled,
    required this.onTap,
  });

  final ActionType actionType;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return _HighlightPickerTile(
      label: _actionTypeLabel(l10n, actionType),
      style: HighlightTypeIcons.forActionType(context, actionType),
      enabled: enabled,
      onTap: onTap,
    );
  }
}

class _HighlightPickerTile extends StatelessWidget {
  const _HighlightPickerTile({
    required this.label,
    required this.style,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final HighlightTypeIconStyle style;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: enabled,
      leading: HighlightTypeIconBadge(style: style),
      title: Text(label),
      onTap: enabled ? onTap : null,
    );
  }
}

class _GrintaHighlightTile extends StatelessWidget {
  const _GrintaHighlightTile({
    required this.match,
    required this.highlight,
    this.onLongPress,
  });

  final models.Match match;
  final Highlights highlight;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final label = _highlightLabel(l10n, highlight);
    final iconStyle = HighlightTypeIcons.forHighlight(context, highlight);
    final minute = highlight.minute ?? 0;
    final extraTime = highlight.extraTime ?? 0;
    final minuteLabel = extraTime > 0 ? "$minute'+$extraTime" : "$minute'";
    final clubInfo = clubInfoForHighlight(match, highlight);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              if (clubInfo != null) ...[
                _HighlightClubLeading(
                  logoUrl: clubInfo.logoUrl,
                  name: clubInfo.name,
                ),
                const SizedBox(width: 8),
              ],
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  minuteLabel,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              HighlightTypeIconBadge(style: iconStyle),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightClubLeading extends StatelessWidget {
  const _HighlightClubLeading({
    required this.logoUrl,
    required this.name,
  });

  final String? logoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final safeUrl = logoUrl?.trim() ?? '';

    if (safeUrl.isNotEmpty) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: colors.border),
        ),
        child: Center(
          child: ClipOval(
            child: Image.network(
              safeUrl,
              width: 20,
              height: 20,
              fit: BoxFit.contain,
              webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
              errorBuilder: (_, __, ___) => Icon(
                Icons.broken_image_outlined,
                size: 14,
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    if (name.isEmpty) {
      return const SizedBox.shrink();
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 72),
      child: Text(
        name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colors.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _GrintaHighlightsEmptyState extends StatelessWidget {
  const _GrintaHighlightsEmptyState({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.edit_note_rounded,
            color: colors.textSecondary,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

String _actionTypeLabel(AppLocalizations l10n, ActionType actionType) {
  switch (actionType) {
    case ActionType.timeEvent:
      return l10n.matchGrintaHighlightsActionTimeEvent;
    case ActionType.goal:
      return l10n.highlightTypeGoal;
    case ActionType.yellowCard:
      return l10n.highlightTypeYellowCard;
    case ActionType.redCard:
      return l10n.highlightTypeRedCard;
    case ActionType.substitution:
      return l10n.highlightTypeSubstitution;
  }
}

String _timeTypeLabel(AppLocalizations l10n, TimeType timeType) {
  switch (timeType) {
    case TimeType.kickOff:
      return l10n.highlightKickoff;
    case TimeType.halTime:
      return l10n.highlightTimeHalfTime;
    case TimeType.secondHalf:
      return l10n.highlightTimeSecondHalf;
    case TimeType.startExtraTime:
      return l10n.highlightTimeStartExtraTime;
    case TimeType.end:
      return l10n.highlightFullTime;
  }
}

String _highlightLabel(AppLocalizations l10n, Highlights highlight) {
  switch (highlight.actionType) {
    case ActionType.timeEvent:
      final timeEvent = highlight.value as TimeEvent?;
      return _timeTypeLabel(l10n, timeEvent?.type ?? TimeType.kickOff);
    case ActionType.goal:
      final goal = highlight.value as Goal?;
      if (goal == null || !goalHasAssociatedPlayer(goal)) {
        return l10n.highlightTypeGoal;
      }
      return l10n.highlightGoalScored(
        goalHighlightLabel(
          goal: goal,
          fallback: l10n.highlightTypeGoal,
        ),
      );
    case ActionType.yellowCard:
      final yellowCard = highlight.value as YellowRedCard?;
      if (yellowCard == null || !cardHasAssociatedPlayer(yellowCard)) {
        return l10n.highlightTypeYellowCard;
      }
      return l10n.highlightYellowCardShown(
        cardHighlightLabel(
          card: yellowCard,
          fallback: l10n.highlightTypeYellowCard,
        ),
      );
    case ActionType.redCard:
      final redCard = highlight.value as YellowRedCard?;
      if (redCard == null || !cardHasAssociatedPlayer(redCard)) {
        return l10n.highlightTypeRedCard;
      }
      return l10n.highlightRedCardShown(
        cardHighlightLabel(
          card: redCard,
          fallback: l10n.highlightTypeRedCard,
        ),
      );
    case ActionType.substitution:
      final substitution = highlight.value as Substitution?;
      if (substitution == null ||
          !substitutionHasAssociatedPlayers(substitution)) {
        return l10n.highlightTypeSubstitution;
      }
      final String? outgoing = substitutionOutgoingLabel(substitution);
      final String? incoming = substitutionIncomingLabel(substitution);
      if (incoming != null &&
          incoming.isNotEmpty &&
          outgoing != null &&
          outgoing.isNotEmpty) {
        return l10n.highlightSubstitutionIn(incoming, outgoing);
      }
      if (outgoing != null && outgoing.isNotEmpty) {
        return l10n.highlightSubstitutionOut(outgoing);
      }
      if (incoming != null && incoming.isNotEmpty) {
        return l10n.highlightSubstitutionIn(
          incoming,
          l10n.entityPlayerNotSet,
        );
      }
      return l10n.highlightTypeSubstitution;
    case null:
      return l10n.highlightTypeGeneric;
  }
}
