import 'dart:async';

import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/services/analyze_video_tactics.dart';
import 'package:grinta/widget/analyze_video/analyze_mp4_player.dart';
import 'package:grinta/widget/analyze_video/analyze_video_pitch_minimap.dart';
import 'package:grinta/widget/gps_field.dart';

Future<void> showAnalyzeVideoTacticsReplay({
  required BuildContext context,
  required AnalyzeTacticsRecording recording,
  required String? team1Id,
  required String? team2Id,
  required int? team1KitColor,
  required int? team2KitColor,
  required Map<String, int> rosterJerseyByPlayerId,
  required Map<String, String> rosterTeamByPlayerId,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (context) => AnalyzeVideoTacticsReplayPage(
        recording: recording,
        team1Id: team1Id,
        team2Id: team2Id,
        team1KitColor: team1KitColor,
        team2KitColor: team2KitColor,
        rosterJerseyByPlayerId: rosterJerseyByPlayerId,
        rosterTeamByPlayerId: rosterTeamByPlayerId,
      ),
    ),
  );
}

class AnalyzeVideoTacticsReplayPage extends StatefulWidget {
  const AnalyzeVideoTacticsReplayPage({
    super.key,
    required this.recording,
    this.team1Id,
    this.team2Id,
    this.team1KitColor,
    this.team2KitColor,
    this.rosterJerseyByPlayerId = const <String, int>{},
    this.rosterTeamByPlayerId = const <String, String>{},
  });

  final AnalyzeTacticsRecording recording;
  final String? team1Id;
  final String? team2Id;
  final int? team1KitColor;
  final int? team2KitColor;
  final Map<String, int> rosterJerseyByPlayerId;
  final Map<String, String> rosterTeamByPlayerId;

  @override
  State<AnalyzeVideoTacticsReplayPage> createState() =>
      _AnalyzeVideoTacticsReplayPageState();
}

class _AnalyzeVideoTacticsReplayPageState
    extends State<AnalyzeVideoTacticsReplayPage> {
  static const List<double> _speeds = <double>[0.5, 1.0, 1.5, 2.0];

  late int _atMs;
  var _playing = false;
  var _speed = 1.0;
  Timer? _timer;

  AnalyzeTacticsRecording get _recording => widget.recording;

  int get _startMs => _recording.startMs;
  int get _endMs => _recording.endMs < _startMs ? _startMs : _recording.endMs;

  @override
  void initState() {
    super.initState();
    _atMs = _startMs;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _seekTo(int atMs) {
    final clamped = atMs.clamp(_startMs, _endMs);
    setState(() => _atMs = clamped);
    if (clamped >= _endMs) _pause();
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
    if (_playing) setState(() => _playing = false);
  }

  void _play() {
    if (_endMs <= _startMs) return;
    if (_atMs >= _endMs) _atMs = _startMs;
    setState(() => _playing = true);
    _timer?.cancel();
    var last = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || !_playing) return;
      final now = DateTime.now();
      final dt = now.difference(last).inMilliseconds;
      last = now;
      _seekTo(_atMs + (dt * _speed).round());
    });
  }

  void _togglePlay() {
    if (_playing) {
      _pause();
    } else {
      _play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final duration = Duration(milliseconds: _endMs - _startMs);
    final position = Duration(milliseconds: _atMs - _startMs);
    final played = duration.inMilliseconds <= 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    final markers = tacticsReplayMarkersAt(
      recording: _recording,
      atMs: _atMs,
      rosterJerseyByPlayerId: widget.rosterJerseyByPlayerId,
      rosterTeamByPlayerId: widget.rosterTeamByPlayerId,
    );
    final trails = tacticsTrailsAt(
      samples: _recording.players,
      atMs: _atMs,
      pitch: _recording.pitch,
      quad: _recording.quad,
      rosterTeamByPlayerId: widget.rosterTeamByPlayerId,
    );
    final ball = interpolateBallAlongSamples(
      balls: _recording.balls,
      atMs: _atMs,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1220),
        foregroundColor: Colors.white,
        title: Text(l10n.debugVideoTacticsTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l10n.debugVideoTacticsHelp,
                style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: kDebugVideoPitchMinimapAspect,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1220),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x66FFFFFF)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const GpsFieldWidget(
                              field: kDebugVideoHeatmapPitchField,
                              drawHeatmap: false,
                              drawGoals: true,
                              padding: kDebugVideoMinimapPitchPadding,
                              borderWidth: 2,
                            ),
                            CustomPaint(
                              painter: DebugVideoPitchMinimapPainter(
                                markers: markers,
                                trails: trails,
                                ball: ball,
                                team1Id: widget.team1Id,
                                team2Id: widget.team2Id,
                                team1KitColor: widget.team1KitColor,
                                team2KitColor: widget.team2KitColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Column(
                children: [
                  Slider(
                    value: played,
                    onChanged: (value) {
                      _pause();
                      _seekTo(
                        _startMs +
                            (( _endMs - _startMs) * value).round(),
                      );
                    },
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: l10n.debugVideoSkipPrevious,
                        onPressed: () {
                          _pause();
                          _seekTo(_startMs);
                        },
                        icon: const Icon(Icons.skip_previous, color: Colors.white),
                      ),
                      IconButton(
                        tooltip: l10n.debugVideoRewind,
                        onPressed: () => _seekTo(_atMs - 5000),
                        icon: const Icon(Icons.fast_rewind, color: Colors.white),
                      ),
                      IconButton(
                        tooltip: _playing
                            ? l10n.debugVideoPause
                            : l10n.debugVideoPlay,
                        onPressed: _togglePlay,
                        icon: Icon(
                          _playing ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.debugVideoStop,
                        onPressed: () {
                          _pause();
                          _seekTo(_startMs);
                        },
                        icon: const Icon(Icons.stop, color: Colors.white),
                      ),
                      IconButton(
                        tooltip: l10n.debugVideoFastForward,
                        onPressed: () => _seekTo(_atMs + 5000),
                        icon: const Icon(Icons.fast_forward, color: Colors.white),
                      ),
                      IconButton(
                        tooltip: l10n.debugVideoSkipNext,
                        onPressed: () {
                          _pause();
                          _seekTo(_endMs);
                        },
                        icon: const Icon(Icons.skip_next, color: Colors.white),
                      ),
                      Text(
                        '${formatDebugVideoTime(Duration(milliseconds: _atMs))} / ${formatDebugVideoTime(Duration(milliseconds: _endMs))}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFeatures: <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                      const Spacer(),
                      PopupMenuButton<double>(
                        tooltip: l10n.debugVideoPlaybackSpeed,
                        initialValue: _speed,
                        onSelected: (value) => setState(() => _speed = value),
                        color: const Color(0xFF1A2333),
                        itemBuilder: (context) => [
                          for (final speed in _speeds)
                            PopupMenuItem<double>(
                              value: speed,
                              child: Text(
                                '${speed}x',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '${_speed}x',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
