import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/player_feeling.dart';
import 'package:grinta/model/tracker/team_workload_summary.dart';
import 'package:grinta/services/matchCompoService.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/teamWorkloadSummaryService.dart';
import 'package:grinta/services/trainingService.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/match_goal_helper.dart';
import 'package:grinta/util/session_feeling_rings.dart';
import 'package:grinta/widget/activity_rings_card.dart';

enum SessionFeelingScreenEventType { training, match }

/// Player session recap + "Comment te sens-tu ?" smiley picker.
class SessionPlayerFeelingScreen extends StatefulWidget {
  const SessionPlayerFeelingScreen({
    super.key,
    required this.eventId,
    required this.playerId,
    this.eventType,
    this.teamId,
  });

  final String eventId;
  final String playerId;

  /// When null, resolved during load (training doc first, then match).
  final SessionFeelingScreenEventType? eventType;
  final String? teamId;

  static const String analyticsName = AnalyticsScreenNames.sessionPlayerFeeling;

  @override
  State<SessionPlayerFeelingScreen> createState() =>
      _SessionPlayerFeelingScreenState();
}

class _SessionPlayerFeelingScreenState
    extends State<SessionPlayerFeelingScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  TeamWorkloadSummary? _summary;
  TeamPlayerMetricScores? _playerScore;
  PlayerFeeling? _selected;
  int? _existingFeelingAfter;
  SessionFeelingScreenEventType? _eventType;
  String? _teamId;

  @override
  void initState() {
    super.initState();
    _eventType = widget.eventType;
    _teamId = widget.teamId;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Show rings as soon as summary is ready — don't wait on training/match.
      final summaryFuture =
          TeamWorkloadSummaryService().getByEventId(widget.eventId);
      final typeFuture = _resolveEventType();

      final summary = await summaryFuture;
      final playerScore = findPlayerScoreInSummary(
        summary: summary,
        playerId: widget.playerId,
      );

      if (!mounted) return;
      setState(() {
        _summary = summary;
        _playerScore = playerScore;
        _loading = false;
      });

      final resolvedType = await typeFuture;
      final existing = await _loadExistingFeeling(resolvedType);

      if (!mounted) return;
      setState(() {
        _eventType = resolvedType;
        _existingFeelingAfter = existing;
        _selected ??= PlayerFeeling.fromValue(
          (existing != null && existing > 0) ? existing : null,
        );
      });
    } catch (e, st) {
      debugPrint('SessionPlayerFeelingScreen load failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<SessionFeelingScreenEventType> _resolveEventType() async {
    if (_eventType != null) return _eventType!;

    final training = await TrainingService().getTrainingById(widget.eventId);
    if (training != null) {
      return SessionFeelingScreenEventType.training;
    }
    return SessionFeelingScreenEventType.match;
  }

  Future<int?> _loadExistingFeeling(
    SessionFeelingScreenEventType eventType,
  ) async {
    final playerId = widget.playerId.trim();
    if (eventType == SessionFeelingScreenEventType.training) {
      final training = await TrainingService().getTrainingById(widget.eventId);
      for (final pt in training?.playerTraining ?? const []) {
        final id = pt.playerId?.trim() ?? '';
        if (id == playerId) return pt.feelingAfter;
      }
      return null;
    }

    var teamId = _teamId?.trim() ?? '';
    if (teamId.isEmpty) {
      final match = await MatchService().getMatchById(widget.eventId);
      teamId = match?.teamID?.trim() ?? '';
      _teamId = teamId;
    }
    if (teamId.isEmpty) return null;

    final compo = await MatchCompoService()
        .getMatchCompoByMatchAndTeamId(widget.eventId, teamId);
    if (compo == null) return null;
    for (final p in allPlayersFromCompo(compo)) {
      if ((p.playerID?.trim() ?? '') == playerId) {
        return p.feelingAfter;
      }
    }
    return null;
  }

  Future<void> _submit() async {
    final selected = _selected;
    if (selected == null || _saving) return;

    final eventType = _eventType;
    if (eventType == null) {
      AppSnackbar.show(context, context.l10n.playerFeelingSaveError);
      return;
    }

    setState(() => _saving = true);
    try {
      if (eventType == SessionFeelingScreenEventType.training) {
        await TrainingService().updatePlayerFeeling(
          trainingId: widget.eventId,
          playerId: widget.playerId,
          feelingAfter: selected.value,
        );
      } else {
        final teamId = _teamId?.trim() ?? '';
        if (teamId.isEmpty) {
          throw StateError('teamId required for match feeling');
        }
        await MatchCompoService().updatePlayerFeeling(
          matchId: widget.eventId,
          teamId: teamId,
          playerId: widget.playerId,
          feelingAfter: selected.value,
        );
      }

      if (!mounted) return;
      AppSnackbar.show(
        context,
        context.l10n.playerFeelingSaved,
        isError: false,
      );
      Navigator.of(context).pop(true);
    } catch (e, st) {
      debugPrint('SessionPlayerFeelingScreen save failed: $e\n$st');
      if (!mounted) return;
      AppSnackbar.show(context, context.l10n.playerFeelingSaveError);
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
    final rings = buildSessionFeelingRings(
      l10n: l10n,
      colors: colors,
      summary: _summary,
      playerScore: _playerScore,
    );
    final workload = sessionFeelingWorkloadScore(
      summary: _summary,
      playerScore: _playerScore,
    );
    final alreadyAnswered =
        _existingFeelingAfter != null && _existingFeelingAfter! > 0;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(l10n.playerFeelingRecapTitle),
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.playerFeelingLoadError,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.playerFeelingRecapSubtitle,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 220,
                          child: ActivityRingsCard.detailed(
                            showWorkload: true,
                            workloadScore: workload,
                            workloadLabel: l10n.statsWorkload,
                            workloadUnit: 'pts',
                            workloadColor: Colors.orange,
                            showLegend: true,
                            embedded: true,
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.all(12),
                            withgoal: false,
                            animationDuration:
                                const Duration(milliseconds: 350),
                            rings: rings,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          l10n.playerFeelingPrompt,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (final feeling in PlayerFeeling.values)
                              _FeelingFaceButton(
                                feeling: feeling,
                                selected: _selected == feeling,
                                enabled: !_saving,
                                onTap: () {
                                  setState(() => _selected = feeling);
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        FilledButton(
                          onPressed: _selected == null ||
                                  _saving ||
                                  _eventType == null
                              ? null
                              : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  alreadyAnswered
                                      ? l10n.playerFeelingUpdateAction
                                      : l10n.playerFeelingSubmitAction,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _FeelingFaceButton extends StatelessWidget {
  const _FeelingFaceButton({
    required this.feeling,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final PlayerFeeling feeling;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? const Color(0xFFE53935) : context.appColors.textPrimary;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: CustomPaint(
          size: const Size(48, 48),
          painter: _FeelingFacePainter(
            feeling: feeling,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _FeelingFacePainter extends CustomPainter {
  _FeelingFacePainter({
    required this.feeling,
    required this.color,
  });

  final PlayerFeeling feeling;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 2;
    canvas.drawCircle(center, radius, stroke);

    final leftEye = Offset(center.dx - radius * 0.32, center.dy - radius * 0.18);
    final rightEye =
        Offset(center.dx + radius * 0.32, center.dy - radius * 0.18);

    switch (feeling) {
      case PlayerFeeling.veryBad:
        _drawArcEye(canvas, leftEye, radius * 0.16, stroke, smile: false);
        _drawArcEye(canvas, rightEye, radius * 0.16, stroke, smile: false);
        _drawMouth(canvas, center, radius, stroke, curve: -0.55);
        break;
      case PlayerFeeling.bad:
        canvas.drawCircle(leftEye, 2.2, fill);
        canvas.drawCircle(rightEye, 2.2, fill);
        canvas.drawLine(
          Offset(leftEye.dx - 4, leftEye.dy - 6),
          Offset(leftEye.dx + 4, leftEye.dy - 3),
          stroke,
        );
        canvas.drawLine(
          Offset(rightEye.dx - 4, rightEye.dy - 3),
          Offset(rightEye.dx + 4, rightEye.dy - 6),
          stroke,
        );
        _drawMouth(canvas, center, radius, stroke, curve: -0.35);
        break;
      case PlayerFeeling.neutral:
        canvas.drawCircle(leftEye, 2.2, fill);
        canvas.drawCircle(rightEye, 2.2, fill);
        canvas.drawLine(
          Offset(center.dx - radius * 0.35, center.dy + radius * 0.32),
          Offset(center.dx + radius * 0.35, center.dy + radius * 0.32),
          stroke,
        );
        break;
      case PlayerFeeling.good:
        canvas.drawCircle(leftEye, 2.2, fill);
        canvas.drawCircle(rightEye, 2.2, fill);
        _drawMouth(canvas, center, radius, stroke, curve: 0.35);
        break;
      case PlayerFeeling.veryGood:
        _drawArcEye(canvas, leftEye, radius * 0.16, stroke, smile: true);
        _drawArcEye(canvas, rightEye, radius * 0.16, stroke, smile: true);
        _drawMouth(canvas, center, radius, stroke, curve: 0.55);
        break;
    }
  }

  void _drawArcEye(
    Canvas canvas,
    Offset center,
    double r,
    Paint paint, {
    required bool smile,
  }) {
    final rect = Rect.fromCircle(center: center, radius: r);
    canvas.drawArc(
      rect,
      smile ? 3.6 : 0.4,
      smile ? -2.2 : 2.2,
      false,
      paint,
    );
  }

  void _drawMouth(
    Canvas canvas,
    Offset faceCenter,
    double radius,
    Paint paint, {
    required double curve,
  }) {
    final mouthCenter = Offset(faceCenter.dx, faceCenter.dy + radius * 0.28);
    final width = radius * 0.7;
    final path = Path();
    path.moveTo(mouthCenter.dx - width / 2, mouthCenter.dy);
    path.quadraticBezierTo(
      mouthCenter.dx,
      mouthCenter.dy + radius * curve,
      mouthCenter.dx + width / 2,
      mouthCenter.dy,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FeelingFacePainter oldDelegate) {
    return oldDelegate.feeling != feeling || oldDelegate.color != color;
  }
}
