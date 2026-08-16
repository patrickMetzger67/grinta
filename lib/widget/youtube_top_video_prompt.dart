import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/tips_screen.dart';
import 'package:grinta/services/youtube_config_service.dart';
import 'package:grinta/services/youtube_top_video_seen_service.dart';
import 'package:grinta/services/social_onboarding_coordinator.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/youtube_embed_player.dart';
import 'package:provider/provider.dart';

/// Shows welcome / tip-of-the-week YouTube prompts when unseen (or snooze expired).
///
/// Priority: welcome (coach or player) → then [YoutubeConfig.topVideo].
/// Playback is in-app (embed).
///
/// Must not run during signup profile creation — only after the member profile
/// is created and validated ([AppSession.selectedPlayer] available).
class YoutubeTopVideoPrompt {
  YoutubeTopVideoPrompt._();

  static bool _dialogOpen = false;

  /// Whether the tip/welcome dialog is currently visible (for UI stacking only).
  static bool get isDialogOpen => _dialogOpen;

  /// Call after the main shell is ready **and** the member profile is validated.
  /// Safe to invoke multiple times.
  static Future<void> maybeShow() async {
    if (_dialogOpen) return;

    if (SocialOnboardingCoordinator.instance.isProfileOnboardingActive) {
      debugPrint('youtube_prompt: skip — profile onboarding in progress');
      return;
    }

    final rootContext = appNavigatorKey.currentContext;
    if (rootContext == null || !rootContext.mounted) return;

    Player? player;
    try {
      player = rootContext.read<AppSession>().selectedPlayer;
    } catch (_) {
      player = null;
    }
    if (player == null) {
      debugPrint('youtube_prompt: skip — no validated member profile yet');
      return;
    }

    await YoutubeConfigService.instance.ensureInitialized();
    await YoutubeTopVideoSeenService.instance.ensureInitialized();

    if (SocialOnboardingCoordinator.instance.isProfileOnboardingActive) {
      return;
    }
    if (!rootContext.mounted) return;

    final prompt = _resolvePrompt(rootContext);
    if (prompt == null) return;

    if (!rootContext.mounted) return;
    _dialogOpen = true;
    try {
      await showDialog<void>(
        context: rootContext,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (ctx) => _YoutubePromptDialog(
          videoId: prompt.videoId,
          videoTitle: prompt.videoTitle,
          slot: prompt.slot,
          dialogTitle: prompt.dialogTitle,
          dialogMessage: prompt.dialogMessage,
        ),
      );
    } finally {
      _dialogOpen = false;
    }
  }

  static _ResolvedPrompt? _resolvePrompt(BuildContext context) {
    final config = YoutubeConfigService.instance.config;
    final seen = YoutubeTopVideoSeenService.instance;
    final l10n = context.l10n;

    Player? player;
    try {
      player = context.read<AppSession>().selectedPlayer;
    } catch (_) {
      player = null;
    }

    final isCoach = player?.isEducatorOrCoach == true;
    final welcomeId = YoutubeConfigService.normalizeVideoId(
          isCoach ? config.welcomeCoach : config.welcomePlayer,
        ) ??
        '';
    final welcomeSlot = isCoach
        ? YoutubePromptSlot.welcomeCoach
        : YoutubePromptSlot.welcomePlayer;

    if (welcomeId.isNotEmpty && seen.shouldShow(welcomeId, slot: welcomeSlot)) {
      final video = config.findVideo(welcomeId);
      final title = (video?.title ?? '').trim();
      return _ResolvedPrompt(
        videoId: welcomeId,
        videoTitle: title.isEmpty ? null : title,
        slot: welcomeSlot,
        dialogTitle: isCoach
            ? l10n.youtubeWelcomeCoachTitle
            : l10n.youtubeWelcomePlayerTitle,
        dialogMessage: isCoach
            ? l10n.youtubeWelcomeCoachMessage
            : l10n.youtubeWelcomePlayerMessage,
      );
    }

    final topVideoId =
        YoutubeConfigService.normalizeVideoId(config.topVideo) ?? '';
    if (topVideoId.isEmpty) return null;
    if (!seen.shouldShow(topVideoId, slot: YoutubePromptSlot.topVideo)) {
      return null;
    }

    final video = config.findVideo(topVideoId);
    final title = (video?.title ?? '').trim();
    return _ResolvedPrompt(
      videoId: topVideoId,
      videoTitle: title.isEmpty ? null : title,
      slot: YoutubePromptSlot.topVideo,
      dialogTitle: l10n.youtubeTopVideoTitle,
      dialogMessage: l10n.youtubeTopVideoMessage,
    );
  }
}

class _ResolvedPrompt {
  const _ResolvedPrompt({
    required this.videoId,
    required this.slot,
    required this.dialogTitle,
    required this.dialogMessage,
    this.videoTitle,
  });

  final String videoId;
  final String? videoTitle;
  final YoutubePromptSlot slot;
  final String dialogTitle;
  final String dialogMessage;
}

class _YoutubePromptDialog extends StatefulWidget {
  const _YoutubePromptDialog({
    required this.videoId,
    required this.slot,
    required this.dialogTitle,
    required this.dialogMessage,
    this.videoTitle,
  });

  final String videoId;
  final String? videoTitle;
  final YoutubePromptSlot slot;
  final String dialogTitle;
  final String dialogMessage;

  @override
  State<_YoutubePromptDialog> createState() => _YoutubePromptDialogState();
}

class _YoutubePromptDialogState extends State<_YoutubePromptDialog> {
  bool _busy = false;

  Future<void> _closeAndMarkSeen() async {
    if (_busy) return;
    setState(() => _busy = true);
    await YoutubeTopVideoSeenService.instance.markSeen(
      widget.videoId,
      slot: widget.slot,
    );
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _closeAndSnoozeUntilTomorrow() async {
    if (_busy) return;
    setState(() => _busy = true);
    await YoutubeTopVideoSeenService.instance.snoozeUntilTomorrow(
      widget.videoId,
      slot: widget.slot,
    );
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _openTips() async {
    if (_busy) return;
    // Keep the prompt un-seen so it can come back tomorrow if user only browses.
    await YoutubeTopVideoSeenService.instance.snoozeUntilTomorrow(
      widget.videoId,
      slot: widget.slot,
    );
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    final rootContext = appNavigatorKey.currentContext;
    if (rootContext == null || !rootContext.mounted) return;
    await openTipsScreen(rootContext);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final subtitle = widget.videoTitle;
    final maxWidth = MediaQuery.sizeOf(context).width.clamp(280.0, 560.0);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.ondemand_video_outlined, color: colors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.dialogTitle,
                      style: textTheme.titleLarge?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.youtubeTopVideoSkip,
                    onPressed: _busy ? null : _closeAndMarkSeen,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: textTheme.titleSmall?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                widget.dialogMessage,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.youtubePromptTipsHint,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              YoutubeEmbedPlayer(videoId: widget.videoId),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _busy ? null : _openTips,
                  icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                  label: Text(l10n.settingsTipsTitle),
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton(
                    onPressed: _busy ? null : _closeAndSnoozeUntilTomorrow,
                    child: Text(l10n.youtubePromptRemindTomorrow),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _closeAndMarkSeen,
                    child: Text(l10n.youtubeTopVideoSkip),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
