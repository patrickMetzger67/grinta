import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/pred_game_day.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/pred_game_day_service.dart';
import 'package:grinta/services/teamService.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/prediction_game_helper.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PredictionGameScreen extends StatefulWidget {
  const PredictionGameScreen({
    super.key,
    this.team,
    this.predGameDayId,
    this.seasonId,
  });

  final Team? team;
  final String? predGameDayId;
  final String? seasonId;

  @override
  State<PredictionGameScreen> createState() => _PredictionGameScreenState();
}

class _PredictionGameScreenState extends State<PredictionGameScreen> {
  final PredGameDayService _service = PredGameDayService();
  final TeamService _teamService = TeamService();

  Team? _team;
  PredGameDay? _contest;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  final Map<String, int> _picks = <String, int>{};

  String get _contestId =>
      (widget.predGameDayId ?? _contest?.id ?? '').trim();

  @override
  void initState() {
    super.initState();
    _team = widget.team;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      PredGameDay? contest;
      final explicitId = widget.predGameDayId?.trim() ?? '';
      if (explicitId.isNotEmpty) {
        contest = await _service.getById(explicitId);
      } else {
        final teamId = (_team?.keyTeam ?? '').trim();
        if (teamId.isNotEmpty) {
          contest = await _service.getLatestForTeam(
            teamId: teamId,
            engagementId: _team?.predictionGameEngagementd,
          );
        }
      }

      Team? team = _team;
      final contestTeamId = contest?.teamId.trim() ?? '';
      if (team == null && contestTeamId.isNotEmpty) {
        team = await _teamService.getTeamById(contestTeamId);
      }

      if (!mounted) return;
      setState(() {
        _contest = contest;
        _team = team;
        _loading = false;
        _hydratePicks(contest);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.l10n.predictionGameLoadError;
      });
    }
  }

  void _hydratePicks(PredGameDay? contest) {
    _picks.clear();
    if (contest == null) return;

    final playerId = _playerIdForSubmit();
    final existing = contest.entryForPlayer(playerId);
    if (existing != null) {
      _picks.addAll(existing.picks);
    }
  }

  String _playerIdForSubmit() {
    final session = context.read<AppSession>();
    final selected = session.selectedPlayer;
    if (selected != null) {
      final memberId = effectiveMemberId(selected)?.trim() ?? '';
      if (memberId.isNotEmpty) return memberId;
    }
    return session.selectedPlayerId?.trim() ??
        FirebaseAuth.instance.currentUser?.uid.trim() ??
        '';
  }

  String _userIdForSubmit() {
    return context.read<AppSession>().user?.uid.trim() ??
        FirebaseAuth.instance.currentUser?.uid.trim() ??
        '';
  }

  Future<void> _submit() async {
    final contest = _contest;
    final contestId = (contest?.id ?? _contestId).trim();
    if (contest == null || contestId.isEmpty) return;

    final l10n = context.l10n;
    final playerId = _playerIdForSubmit();
    final userId = _userIdForSubmit();
    if (playerId.isEmpty || userId.isEmpty) {
      AppSnackbar.show(context, l10n.predictionGameSubmitError);
      return;
    }

    if (!contest.isOpenAt(DateTime.now())) {
      AppSnackbar.show(context, l10n.predictionGameDeadlinePassed);
      return;
    }

    final matchIds = contest.matchIds.isNotEmpty
        ? contest.matchIds
        : contest.fixtures.map((f) => f.matchId).toList();
    for (final matchId in matchIds) {
      if (!isValidPredictionPick(_picks[matchId])) {
        AppSnackbar.show(context, l10n.predictionGameIncompletePicks);
        return;
      }
    }

    setState(() => _saving = true);
    try {
      await _service.submitEntry(
        contestId: contestId,
        playerId: playerId,
        userId: userId,
        picks: Map<String, int>.from(_picks),
      );
      if (!mounted) return;
      AppSnackbar.show(context, l10n.predictionGameSubmitted, isError: false);
      await _load();
    } on PredGameDayClosedException {
      if (!mounted) return;
      AppSnackbar.show(context, l10n.predictionGameDeadlinePassed);
    } on PredGameDayIncompletePicksException {
      if (!mounted) return;
      AppSnackbar.show(context, l10n.predictionGameIncompletePicks);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(context, l10n.predictionGameSubmitError);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final contest = _contest;
    final isOpen = contest?.isOpenAt(DateTime.now()) ?? false;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(l10n.predictionGameTitle),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : _error != null
              ? _MessageState(
                  message: _error!,
                  onRetry: _load,
                  retryLabel: l10n.adminAdsRetry,
                )
              : contest == null
                  ? _MessageState(
                      message: l10n.predictionGameEmpty,
                      detail: l10n.predictionGameEmptyHint,
                    )
                  : _buildContest(context, contest, isOpen),
    );
  }

  Widget _buildContest(
    BuildContext context,
    PredGameDay contest,
    bool isOpen,
  ) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.yMMMd(locale).add_Hm();
    final alreadySubmitted =
        contest.entryForPlayer(_playerIdForSubmit()) != null;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text(
                l10n.predictionGameMatchdayTitle(contest.day.toString()),
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isOpen && contest.closesAt != null
                    ? l10n.predictionGameDeadline(
                        dateFormat.format(contest.closesAt!),
                      )
                    : l10n.predictionGameClosed,
                style: textTheme.bodyMedium?.copyWith(
                  color: isOpen ? colors.textSecondary : colors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (alreadySubmitted) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.predictionGameAlreadySubmitted,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              for (final fixture in contest.fixtures) ...[
                _FixtureCard(
                  fixture: fixture,
                  pick: _picks[fixture.matchId],
                  enabled: isOpen && !_saving,
                  dateFormat: dateFormat,
                  onChanged: (value) {
                    setState(() => _picks[fixture.matchId] = value);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isOpen && !_saving ? _submit : null,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.predictionGameSubmit),
            ),
          ),
        ),
      ],
    );
  }
}

class _FixtureCard extends StatelessWidget {
  const _FixtureCard({
    required this.fixture,
    required this.pick,
    required this.enabled,
    required this.dateFormat,
    required this.onChanged,
  });

  final PredGameDayFixture fixture;
  final int? pick;
  final bool enabled;
  final DateFormat dateFormat;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final kickoff = fixture.kickoffAt;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${fixture.team1}  ${l10n.predictionGameVs}  ${fixture.team2}',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (kickoff != null) ...[
            const SizedBox(height: 6),
            Text(
              dateFormat.format(kickoff),
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              _PickChip(
                label: l10n.predictionGamePickHome,
                selected: pick == predGameDayPickHome,
                enabled: enabled,
                onTap: () => onChanged(predGameDayPickHome),
              ),
              const SizedBox(width: 8),
              _PickChip(
                label: l10n.predictionGamePickDraw,
                selected: pick == predGameDayPickDraw,
                enabled: enabled,
                onTap: () => onChanged(predGameDayPickDraw),
              ),
              const SizedBox(width: 8),
              _PickChip(
                label: l10n.predictionGamePickAway,
                selected: pick == predGameDayPickAway,
                enabled: enabled,
                onTap: () => onChanged(predGameDayPickAway),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PickChip extends StatelessWidget {
  const _PickChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Expanded(
      child: Material(
        color: selected ? colors.primary : colors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? colors.primary : colors.border,
              ),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: selected ? Colors.white : colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.message,
    this.detail,
    this.onRetry,
    this.retryLabel,
  });

  final String message;
  final String? detail;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: Text(retryLabel ?? 'OK'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shared navigation helper used by notifications and team detail.
Future<void> openPredictionGameScreen(
  BuildContext context, {
  Team? team,
  String? predGameDayId,
  String? seasonId,
}) {
  return Navigator.of(context).push<void>(
    analyticsMaterialRoute<void>(
      screenName: AnalyticsScreenNames.predictionGame,
      builder: (_) => PredictionGameScreen(
        team: team,
        predGameDayId: predGameDayId,
        seasonId: seasonId,
      ),
    ),
  );
}
