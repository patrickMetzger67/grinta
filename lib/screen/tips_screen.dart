import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/services/youtube_config_service.dart';
import 'package:grinta/services/youtube_playlist_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/youtube_embed_player.dart';

/// Opens the Tips / Astuces list (YouTube playlist + curated fallback).
Future<void> openTipsScreen(BuildContext context) async {
  await Navigator.of(context, rootNavigator: true).push(
    analyticsMaterialRoute<void>(
      screenName: AnalyticsScreenNames.tips,
      builder: (_) => const TipsScreen(),
    ),
  );
}

/// Lists every video available on the Astuces YouTube playlist.
class TipsScreen extends StatefulWidget {
  const TipsScreen({
    super.key,
    this.playlistService,
  });

  final YoutubePlaylistService? playlistService;

  /// Filters [videos] by case-insensitive tokens against title + description.
  @visibleForTesting
  static List<YoutubeVideoEntry> filterVideos(
    List<YoutubeVideoEntry> videos,
    String query,
  ) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return videos;

    final tokens = normalized
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList(growable: false);
    if (tokens.isEmpty) return videos;

    return videos.where((video) {
      final haystack = '${video.title} ${video.description ?? ''}'.toLowerCase();
      for (final token in tokens) {
        if (!haystack.contains(token)) return false;
      }
      return true;
    }).toList(growable: false);
  }

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  late Future<YoutubePlaylistResult> _future;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  YoutubePlaylistService get _service =>
      widget.playlistService ?? YoutubePlaylistService.instance;

  @override
  void initState() {
    super.initState();
    _future = _service.loadTipsVideos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.loadTipsVideos(forceRefresh: true);
    });
    await _future;
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  Future<void> _openVideo(YoutubeVideoEntry video) async {
    if (!mounted) return;
    final l10n = context.l10n;
    final colors = context.appColors;
    final maxWidth = MediaQuery.sizeOf(context).width.clamp(280.0, 720.0);

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          backgroundColor: colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.border),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          video.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.actionClose,
                        onPressed: () =>
                            Navigator.of(ctx, rootNavigator: true).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: YoutubeEmbedPlayer(
                        videoId: video.id,
                        autoplay: true,
                      ),
                    ),
                  ),
                  if ((video.description ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      video.description!.trim(),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      textInputAction: TextInputAction.search,
      style: TextStyle(color: colors.textPrimary),
      decoration: InputDecoration(
        hintText: l10n.settingsTipsSearchHint,
        prefixIcon: Icon(
          Icons.search_rounded,
          color: colors.textSecondary,
        ),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                onPressed: _clearSearch,
                icon: Icon(
                  Icons.close_rounded,
                  color: colors.textSecondary,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(l10n.settingsTipsTitle),
        actions: [
          IconButton(
            tooltip: l10n.actionRetry,
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<YoutubePlaylistResult>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _TipsMessage(
              icon: Icons.cloud_off_outlined,
              title: l10n.settingsTipsLoadError,
              actionLabel: l10n.actionRetry,
              onAction: _reload,
            );
          }

          final result = snapshot.data;
          final videos = result?.videos ?? const <YoutubeVideoEntry>[];
          if (videos.isEmpty) {
            final hasPlaylist = (result?.playlistId ?? '').trim().isNotEmpty;
            return _TipsMessage(
              icon: Icons.lightbulb_outline_rounded,
              title: hasPlaylist
                  ? l10n.settingsTipsLoadError
                  : l10n.settingsTipsEmpty,
              actionLabel: l10n.actionRetry,
              onAction: _reload,
            );
          }

          final filtered = TipsScreen.filterVideos(videos, _searchQuery);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _buildSearchField(context),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _reload,
                  child: filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 40,
                              color: colors.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.settingsTipsSearchEmpty,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: filtered.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  l10n.settingsTipsSubtitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                ),
                              );
                            }

                            final video = filtered[index - 1];
                            return _TipVideoTile(
                              video: video,
                              onTap: () => _openVideo(video),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TipVideoTile extends StatelessWidget {
  const _TipVideoTile({
    required this.video,
    required this.onTap,
  });

  final YoutubeVideoEntry video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final thumb = (video.thumbnailUrl ?? '').trim().isNotEmpty
        ? video.thumbnailUrl!.trim()
        : 'https://i.ytimg.com/vi/${video.id}/hqdefault.jpg';

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 128,
                height: 80,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: thumb,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: colors.border),
                      errorWidget: (_, __, ___) => Container(
                        color: colors.border,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.play_circle_outline_rounded,
                          color: colors.primary,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white.withValues(alpha: 0.92),
                        size: 36,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      if ((video.description ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          video.description!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                        ),
                      ],
                    ],
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

class _TipsMessage extends StatelessWidget {
  const _TipsMessage({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: colors.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
