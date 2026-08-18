import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/services/analyze_player_detection.dart';
import 'package:grinta/services/analyze_video_analysis.dart';
import 'package:grinta/widget/analyze_video/analyze_video_manual_select_overlay.dart';
import 'package:grinta/widget/analyze_video/analyze_video_pitch_minimap.dart';
import 'package:grinta/widget/analyze_video/player_detection_overlay.dart';
import 'package:video_player/video_player.dart';

String formatDebugVideoTime(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

class DebugMp4Player extends StatefulWidget {
  const DebugMp4Player({
    super.key,
    required this.controller,
    this.showSurface = true,
    this.isFullscreen = false,
    this.onEnterFullscreen,
    this.onExitFullscreen,
    this.detections = const <PlayerDetectionBox>[],
    this.detectionColor,
    this.associatedColor,
    this.manualLabelingAllowed = false,
    this.onManualBox,
    this.videoBoundaryKey,
    this.draftBox,
    this.onDraftMoved,
    this.stillFrameBytes,
    this.onBeforePlay,
    this.onSeek,
    this.analysisSamples = const <PlayerDistanceSample>[],
    this.pitch,
    this.quad,
    this.team1Id,
    this.team2Id,
    this.team1KitColor,
    this.team2KitColor,
    this.rosterJerseyByPlayerId = const <String, int>{},
    this.rosterTeamByPlayerId = const <String, String>{},
  });

  final VideoPlayerController controller;
  final bool showSurface;
  final bool isFullscreen;
  final VoidCallback? onEnterFullscreen;
  final VoidCallback? onExitFullscreen;
  final List<PlayerDetectionBox> detections;
  final Color? detectionColor;
  final Color? associatedColor;
  final bool manualLabelingAllowed;
  final ValueChanged<PlayerDetectionBox>? onManualBox;
  final Key? videoBoundaryKey;
  final PlayerDetectionBox? draftBox;
  final ValueChanged<PlayerDetectionBox>? onDraftMoved;
  final Uint8List? stillFrameBytes;
  final Future<void> Function()? onBeforePlay;
  final VoidCallback? onSeek;
  final List<PlayerDistanceSample> analysisSamples;
  final PitchRegion? pitch;
  final PitchQuad? quad;
  final String? team1Id;
  final String? team2Id;
  final int? team1KitColor;
  final int? team2KitColor;
  final Map<String, int> rosterJerseyByPlayerId;
  final Map<String, String> rosterTeamByPlayerId;

  @override
  State<DebugMp4Player> createState() => _DebugMp4PlayerState();
}

class _DebugMp4PlayerState extends State<DebugMp4Player> {
  static const List<double> _speeds = <double>[0.5, 1.0, 1.5, 2.0];

  double _volumeBeforeMute = 1;

  VideoPlayerController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerTick);
  }

  @override
  void didUpdateWidget(covariant DebugMp4Player oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerTick);
      widget.controller.addListener(_onControllerTick);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerTick);
    super.dispose();
  }

  void _onControllerTick() {
    if (mounted) setState(() {});
  }

  Future<void> _togglePlay() async {
    if (!_controller.value.isInitialized) return;
    if (_controller.value.isPlaying) {
      await _controller.pause();
      return;
    }
    await widget.onBeforePlay?.call();
    if (!mounted) return;
    await _controller.play();
  }

  Future<void> _seekTo(Duration target) async {
    if (!_controller.value.isInitialized) return;
    final duration = _controller.value.duration;
    if (duration <= Duration.zero) return;
    final clampedMs =
        target.inMilliseconds.clamp(0, duration.inMilliseconds).toInt();
    await _controller.seekTo(Duration(milliseconds: clampedMs));
    widget.onSeek?.call();
  }

  Future<void> _seekFraction(double fraction) async {
    if (!_controller.value.isInitialized) return;
    final duration = _controller.value.duration;
    if (duration <= Duration.zero) return;
    final clamped = fraction.clamp(0.0, 1.0);
    await _seekTo(
      Duration(milliseconds: (duration.inMilliseconds * clamped).round()),
    );
  }

  Future<void> _seekBy(Duration offset) async {
    await _seekTo(_controller.value.position + offset);
  }

  Future<void> _stopToStart() async {
    if (!_controller.value.isInitialized) return;
    await _controller.pause();
    if (!mounted) return;
    await _seekTo(Duration.zero);
  }

  Future<void> _toggleMute() async {
    final current = _controller.value.volume;
    if (current > 0) {
      _volumeBeforeMute = current;
      await _controller.setVolume(0);
    } else {
      await _controller.setVolume(_volumeBeforeMute <= 0 ? 1 : _volumeBeforeMute);
    }
  }

  Future<void> _setSpeed(double speed) async {
    await _controller.setPlaybackSpeed(speed);
  }

  @override
  Widget build(BuildContext context) {
    final value = _controller.value;
    final aspect = value.isInitialized && value.aspectRatio > 0
        ? value.aspectRatio
        : 16 / 9;
    final hideHtmlVideo =
        kIsWeb && widget.draftBox != null && widget.stillFrameBytes != null;

    return ColoredBox(
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: aspect,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.showSurface && value.isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: aspect,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hideHtmlVideo)
                        Positioned.fill(
                          child: widget.stillFrameBytes == null
                              ? const ColoredBox(color: Colors.black)
                              : Image.memory(
                                  widget.stillFrameBytes!,
                                  fit: BoxFit.contain,
                                  gaplessPlayback: true,
                                ),
                        )
                      else
                        RepaintBoundary(
                          key: widget.videoBoundaryKey,
                          child: VideoPlayer(_controller),
                        ),
                      PlayerDetectionOverlay(
                        boxes: overlayDetectionBoxes(
                          widget.detections,
                          showAssociatedPlayers: !value.isPlaying,
                        ),
                        color: widget.detectionColor ?? const Color(0xFFF95C1B),
                        associatedColor: widget.associatedColor,
                        draftBox: widget.draftBox,
                        onDraftMoved: widget.onDraftMoved,
                      ),
                      if (!kIsWeb &&
                          widget.manualLabelingAllowed &&
                          !value.isPlaying &&
                          widget.onManualBox != null)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          bottom: 88,
                          child: DebugVideoManualSelectOverlay(
                            enabled: true,
                            onBox: widget.onManualBox!,
                            color: widget.associatedColor ??
                                const Color(0xFF1FA971),
                          ),
                        ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IgnorePointer(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final insetWidth = (constraints.maxWidth * 0.28)
                                  .clamp(168.0, 228.0);
                              return DebugVideoPitchMinimap(
                                detections: widget.detections,
                                analysisSamples: widget.analysisSamples,
                                atMs: value.position.inMilliseconds,
                                preferLiveDetections: value.isPlaying,
                                pitch: widget.pitch,
                                quad: widget.quad,
                                team1Id: widget.team1Id,
                                team2Id: widget.team2Id,
                                team1KitColor: widget.team1KitColor,
                                team2KitColor: widget.team2KitColor,
                                rosterJerseyByPlayerId:
                                    widget.rosterJerseyByPlayerId,
                                rosterTeamByPlayerId:
                                    widget.rosterTeamByPlayerId,
                                width: insetWidth,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (!value.isInitialized)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            if (value.hasError)
              const Center(
                child: Icon(Icons.error_outline, color: Colors.white70, size: 36),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildControls(context, value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, VideoPlayerValue value) {
    final duration = value.duration;
    final position = value.position;
    final played = duration.inMilliseconds <= 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    var buffered = 0.0;
    if (value.buffered.isNotEmpty && duration.inMilliseconds > 0) {
      buffered = (value.buffered.last.end.inMilliseconds / duration.inMilliseconds)
          .clamp(0.0, 1.0);
    }
    final muted = value.volume <= 0;
    final volumeIcon = muted
        ? Icons.volume_off
        : value.volume < 0.4
            ? Icons.volume_down
            : Icons.volume_up;
    final l10n = context.l10n;
    final canTransport = value.isInitialized && widget.draftBox == null;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0x00000000),
            Color(0xCC000000),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SeekBar(
              played: played,
              buffered: buffered,
              onSeek: widget.draftBox == null ? _seekFraction : (_) {},
            ),
            Row(
              children: [
                IconButton(
                  tooltip: l10n.debugVideoSkipPrevious,
                  onPressed: canTransport
                      ? () => _seekTo(Duration.zero)
                      : null,
                  icon: const Icon(Icons.skip_previous, color: Colors.white),
                ),
                IconButton(
                  tooltip: l10n.debugVideoRewind,
                  onPressed: canTransport
                      ? () => _seekBy(const Duration(seconds: -5))
                      : null,
                  icon: const Icon(Icons.fast_rewind, color: Colors.white),
                ),
                IconButton(
                  tooltip:
                      value.isPlaying ? l10n.debugVideoPause : l10n.debugVideoPlay,
                  onPressed: canTransport ? _togglePlay : null,
                  icon: Icon(
                    value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  tooltip: l10n.debugVideoStop,
                  onPressed: canTransport ? _stopToStart : null,
                  icon: const Icon(Icons.stop, color: Colors.white),
                ),
                IconButton(
                  tooltip: l10n.debugVideoFastForward,
                  onPressed: canTransport
                      ? () => _seekBy(const Duration(seconds: 5))
                      : null,
                  icon: const Icon(Icons.fast_forward, color: Colors.white),
                ),
                IconButton(
                  tooltip: l10n.debugVideoSkipNext,
                  onPressed: canTransport
                      ? () => _seekTo(_controller.value.duration)
                      : null,
                  icon: const Icon(Icons.skip_next, color: Colors.white),
                ),
                Text(
                  '${formatDebugVideoTime(position)} / ${formatDebugVideoTime(duration)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: muted ? 'Unmute' : 'Mute',
                  onPressed: value.isInitialized ? _toggleMute : null,
                  icon: Icon(volumeIcon, color: Colors.white),
                ),
                SizedBox(
                  width: 88,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 10,
                      ),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      value: value.volume.clamp(0.0, 1.0),
                      onChanged: value.isInitialized
                          ? (next) {
                              if (next > 0) _volumeBeforeMute = next;
                              _controller.setVolume(next);
                            }
                          : null,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: widget.isFullscreen ? 'Exit fullscreen' : 'Fullscreen',
                  onPressed: widget.isFullscreen
                      ? widget.onExitFullscreen
                      : widget.onEnterFullscreen,
                  icon: Icon(
                    widget.isFullscreen
                        ? Icons.fullscreen_exit
                        : Icons.fullscreen,
                    color: Colors.white,
                  ),
                ),
                PopupMenuButton<double>(
                  tooltip: context.l10n.debugVideoPlaybackSpeed,
                  color: const Color(0xFF2A2A2A),
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: _setSpeed,
                  itemBuilder: (context) {
                    final current = value.playbackSpeed;
                    return [
                      PopupMenuItem<double>(
                        enabled: false,
                        child: Text(
                          context.l10n.debugVideoPlaybackSpeed,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      ..._speeds.map((speed) {
                        final selected = (current - speed).abs() < 0.01;
                        return PopupMenuItem<double>(
                          value: speed,
                          child: Text(
                            '${speed}x',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        );
                      }),
                    ];
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SeekBar extends StatelessWidget {
  const _SeekBar({
    required this.played,
    required this.buffered,
    required this.onSeek,
  });

  final double played;
  final double buffered;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        activeTrackColor: Colors.white,
        inactiveTrackColor: Colors.transparent,
        thumbColor: Colors.white,
        overlayColor: Colors.white24,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox(
                    height: 3,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const ColoredBox(color: Color(0xFF5A5A5A)),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: buffered.clamp(0.0, 1.0),
                          child: const ColoredBox(color: Color(0xFFBDBDBD)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Slider(
                value: played.clamp(0.0, 1.0),
                onChanged: onSeek,
              ),
            ],
          );
        },
      ),
    );
  }
}

class DebugMp4FullscreenPage extends StatefulWidget {
  const DebugMp4FullscreenPage({
    super.key,
    required this.controller,
    this.detections = const <PlayerDetectionBox>[],
    this.detectionsListenable,
    this.detectionColor,
    this.associatedColor,
    this.manualLabelingAllowed = false,
    this.onManualBox,
    this.videoBoundaryKey,
    this.draftBox,
    this.onSeek,
    this.analysisSamples = const <PlayerDistanceSample>[],
    this.pitch,
    this.quad,
    this.team1Id,
    this.team2Id,
    this.team1KitColor,
    this.team2KitColor,
    this.rosterJerseyByPlayerId = const <String, int>{},
    this.rosterTeamByPlayerId = const <String, String>{},
  });

  final VideoPlayerController controller;
  final List<PlayerDetectionBox> detections;
  final ValueListenable<List<PlayerDetectionBox>>? detectionsListenable;
  final Color? detectionColor;
  final Color? associatedColor;
  final bool manualLabelingAllowed;
  final ValueChanged<PlayerDetectionBox>? onManualBox;
  final Key? videoBoundaryKey;
  final PlayerDetectionBox? draftBox;
  final VoidCallback? onSeek;
  final List<PlayerDistanceSample> analysisSamples;
  final PitchRegion? pitch;
  final PitchQuad? quad;
  final String? team1Id;
  final String? team2Id;
  final int? team1KitColor;
  final int? team2KitColor;
  final Map<String, int> rosterJerseyByPlayerId;
  final Map<String, String> rosterTeamByPlayerId;

  @override
  State<DebugMp4FullscreenPage> createState() => _DebugMp4FullscreenPageState();
}

class _DebugMp4FullscreenPageState extends State<DebugMp4FullscreenPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _exit() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: widget.detectionsListenable == null
              ? DebugMp4Player(
                  controller: widget.controller,
                  isFullscreen: true,
                  onExitFullscreen: _exit,
                  detections: widget.detections,
                  detectionColor: widget.detectionColor,
                  associatedColor: widget.associatedColor,
                  manualLabelingAllowed: widget.manualLabelingAllowed,
                  onManualBox: widget.onManualBox,
                  videoBoundaryKey: widget.videoBoundaryKey,
                  draftBox: widget.draftBox,
                  onSeek: widget.onSeek,
                  analysisSamples: widget.analysisSamples,
                  pitch: widget.pitch,
                  quad: widget.quad,
                  team1Id: widget.team1Id,
                  team2Id: widget.team2Id,
                  team1KitColor: widget.team1KitColor,
                  team2KitColor: widget.team2KitColor,
                  rosterJerseyByPlayerId: widget.rosterJerseyByPlayerId,
                  rosterTeamByPlayerId: widget.rosterTeamByPlayerId,
                )
              : ValueListenableBuilder<List<PlayerDetectionBox>>(
                  valueListenable: widget.detectionsListenable!,
                  builder: (context, boxes, _) {
                    return DebugMp4Player(
                      controller: widget.controller,
                      isFullscreen: true,
                      onExitFullscreen: _exit,
                      detections: boxes,
                      detectionColor: widget.detectionColor,
                      associatedColor: widget.associatedColor,
                      manualLabelingAllowed: widget.manualLabelingAllowed,
                      onManualBox: widget.onManualBox,
                      videoBoundaryKey: widget.videoBoundaryKey,
                      draftBox: widget.draftBox,
                      onSeek: widget.onSeek,
                      analysisSamples: widget.analysisSamples,
                      pitch: widget.pitch,
                      quad: widget.quad,
                      team1Id: widget.team1Id,
                      team2Id: widget.team2Id,
                      team1KitColor: widget.team1KitColor,
                      team2KitColor: widget.team2KitColor,
                      rosterJerseyByPlayerId: widget.rosterJerseyByPlayerId,
                      rosterTeamByPlayerId: widget.rosterTeamByPlayerId,
                    );
                  },
                ),
        ),
      ),
    );
  }
}
