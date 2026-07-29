import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/services/youtube_config_service.dart';
import 'package:grinta/services/youtube_top_video_seen_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/youtube_embed_player.dart';

/// Shows the weekly YouTube tip once per unseen [YoutubeConfig.topVideo].
///
/// No prompt when `topVideo` is empty. Playback is in-app (embed), not an
/// external browser tab.
class YoutubeTopVideoPrompt {
  YoutubeTopVideoPrompt._();

  static bool _dialogOpen = false;

  /// Call after the main shell is ready. Safe to invoke multiple times.
  static Future<void> maybeShow() async {
    if (_dialogOpen) return;

    final rootContext = appNavigatorKey.currentContext;
    if (rootContext == null || !rootContext.mounted) return;

    await YoutubeConfigService.instance.ensureInitialized();
    await YoutubeTopVideoSeenService.instance.ensureInitialized();

    final config = YoutubeConfigService.instance.config;
    // Bypass entirely when no featured video is configured.
    final topVideoId =
        YoutubeConfigService.normalizeVideoId(config.topVideo) ?? '';
    if (topVideoId.isEmpty) return;

    if (!YoutubeTopVideoSeenService.instance.shouldShow(topVideoId)) {
      return;
    }

    final video = config.findVideo(topVideoId);
    final title = (video?.title ?? '').trim();

    if (!rootContext.mounted) return;
    _dialogOpen = true;
    try {
      await showDialog<void>(
        context: rootContext,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (ctx) => _YoutubeTopVideoDialog(
          videoId: topVideoId,
          videoTitle: title.isEmpty ? null : title,
        ),
      );
    } finally {
      _dialogOpen = false;
    }
  }
}

class _YoutubeTopVideoDialog extends StatefulWidget {
  const _YoutubeTopVideoDialog({
    required this.videoId,
    this.videoTitle,
  });

  final String videoId;
  final String? videoTitle;

  @override
  State<_YoutubeTopVideoDialog> createState() => _YoutubeTopVideoDialogState();
}

class _YoutubeTopVideoDialogState extends State<_YoutubeTopVideoDialog> {
  bool _busy = false;

  Future<void> _closeAndMarkSeen() async {
    if (_busy) return;
    setState(() => _busy = true);
    await YoutubeTopVideoSeenService.instance.markSeen(widget.videoId);
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
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
                      l10n.youtubeTopVideoTitle,
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
                l10n.youtubeTopVideoMessage,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              YoutubeEmbedPlayer(videoId: widget.videoId),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy ? null : _closeAndMarkSeen,
                  child: Text(l10n.youtubeTopVideoSkip),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
