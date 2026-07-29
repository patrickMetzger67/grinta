import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/services/youtube_config_service.dart';
import 'package:grinta/services/youtube_top_video_seen_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows the weekly YouTube tip once per unseen [YoutubeConfig.topVideo].
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
    final topVideoId = config.topVideo.trim();
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

  Future<void> _markSeen() {
    return YoutubeTopVideoSeenService.instance.markSeen(widget.videoId);
  }

  Future<void> _onSkip() async {
    if (_busy) return;
    setState(() => _busy = true);
    await _markSeen();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _onWatch() async {
    if (_busy) return;
    setState(() => _busy = true);
    await _markSeen();
    final uri = Uri.parse('https://www.youtube.com/watch?v=${widget.videoId}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Still close — video was marked seen.
    }
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final subtitle = widget.videoTitle;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      title: Row(
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
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.youtubeTopVideoMessage,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              height: 1.35,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.play_circle_fill, color: colors.primary, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: textTheme.titleSmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : _onSkip,
          child: Text(l10n.youtubeTopVideoSkip),
        ),
        ElevatedButton(
          onPressed: _busy ? null : _onWatch,
          child: Text(l10n.youtubeTopVideoWatch),
        ),
      ],
    );
  }
}
