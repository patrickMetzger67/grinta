import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/services/youtube_config_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';

class AdminYoutubeScreen extends StatefulWidget {
  const AdminYoutubeScreen({super.key});

  @override
  State<AdminYoutubeScreen> createState() => _AdminYoutubeScreenState();
}

class _AdminYoutubeScreenState extends State<AdminYoutubeScreen> {
  final YoutubeConfigService _service = YoutubeConfigService.instance;

  final _channelIdController = TextEditingController();
  final _channelUrlController = TextEditingController();
  final _playlistIdController = TextEditingController();
  final _topVideoController = TextEditingController();
  final _welcomePlayerController = TextEditingController();
  final _welcomeCoachController = TextEditingController();

  List<YoutubeVideoEntry> _videos = <YoutubeVideoEntry>[];
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _channelIdController.dispose();
    _channelUrlController.dispose();
    _playlistIdController.dispose();
    _topVideoController.dispose();
    _welcomePlayerController.dispose();
    _welcomeCoachController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final config = await _service.fetch();
      if (!mounted) return;
      _applyConfigToForm(config);
      setState(() {
        _loading = false;
        _dirty = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  void _applyConfigToForm(YoutubeConfig config) {
    _channelIdController.text = config.channelId;
    _channelUrlController.text = config.channelUrl;
    _playlistIdController.text = config.playlistId;
    _topVideoController.text = config.topVideo;
    _welcomePlayerController.text = config.welcomePlayer;
    _welcomeCoachController.text = config.welcomeCoach;
    _videos = List<YoutubeVideoEntry>.from(config.videos);
  }

  void _markDirty() {
    setState(() => _dirty = true);
  }

  YoutubeConfig _buildConfigFromForm() {
    return YoutubeConfig(
      channelId: _channelIdController.text,
      channelUrl: _channelUrlController.text,
      playlistId: _playlistIdController.text,
      topVideo: _topVideoController.text,
      welcomePlayer: _welcomePlayerController.text,
      welcomeCoach: _welcomeCoachController.text,
      videos: _videos,
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final l10n = context.l10n;
    try {
      await _service.save(_buildConfigFromForm());
      if (!mounted) return;
      setState(() {
        _saving = false;
        _dirty = false;
      });
      AppSnackbar.show(context, l10n.adminYoutubeSaved);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final message = e.toString().contains('permission-denied')
          ? l10n.adminYoutubePermissionDenied
          : l10n.adminYoutubeSaveFailed;
      AppSnackbar.show(context, message);
    }
  }

  Future<void> _openVideoSheet({YoutubeVideoEntry? existing, int? index}) async {
    final result = await showModalBottomSheet<YoutubeVideoEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _VideoFormSheet(existing: existing),
    );
    if (result == null || !mounted) return;

    setState(() {
      if (index != null && index >= 0 && index < _videos.length) {
        _videos[index] = result;
      } else {
        final existingIndex =
            _videos.indexWhere((video) => video.id == result.id);
        if (existingIndex >= 0) {
          _videos[existingIndex] = result;
        } else {
          _videos = [..._videos, result];
        }
      }
      _dirty = true;
    });
  }

  Future<void> _confirmDeleteVideo(int index) async {
    final l10n = context.l10n;
    final video = _videos[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.adminYoutubeDeleteVideoTitle),
        content: Text(l10n.adminYoutubeDeleteVideoMessage(video.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.adminYoutubeDeleteVideo),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final removedId = video.id;
    setState(() {
      _videos = List<YoutubeVideoEntry>.from(_videos)..removeAt(index);
      if (_topVideoController.text.trim() == removedId) {
        _topVideoController.clear();
      }
      if (_welcomePlayerController.text.trim() == removedId) {
        _welcomePlayerController.clear();
      }
      if (_welcomeCoachController.text.trim() == removedId) {
        _welcomeCoachController.clear();
      }
      _dirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.adminYoutubeTitle,
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_dirty)
            TextButton(
              onPressed: _saving ? null : _save,
              child: Text(l10n.adminYoutubeSave),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving || _loading ? null : _save,
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_outlined),
        label: Text(l10n.adminYoutubeSave),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.adminYoutubeLoadError,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
                          child: Text(l10n.adminYoutubeRetry),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: [
                    Text(
                      l10n.adminYoutubeSubtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: l10n.adminYoutubeChannelSection,
                      child: Column(
                        children: [
                          _Field(
                            controller: _channelIdController,
                            label: l10n.adminYoutubeFieldChannelId,
                            hint: l10n.adminYoutubeFieldChannelIdHint,
                            onChanged: (_) => _markDirty(),
                          ),
                          const SizedBox(height: 12),
                          _Field(
                            controller: _channelUrlController,
                            label: l10n.adminYoutubeFieldChannelUrl,
                            hint: l10n.adminYoutubeFieldChannelUrlHint,
                            onChanged: (_) => _markDirty(),
                          ),
                          const SizedBox(height: 12),
                          _Field(
                            controller: _playlistIdController,
                            label: l10n.adminYoutubeFieldPlaylistId,
                            hint: l10n.adminYoutubeFieldPlaylistIdHint,
                            onChanged: (_) => _markDirty(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: l10n.adminYoutubeFeaturedSection,
                      child: Column(
                        children: [
                          _FeaturedVideoField(
                            controller: _topVideoController,
                            label: l10n.adminYoutubeFieldTopVideo,
                            hint: l10n.adminYoutubeFieldVideoIdHint,
                            videos: _videos,
                            onChanged: _markDirty,
                          ),
                          const SizedBox(height: 12),
                          _FeaturedVideoField(
                            controller: _welcomePlayerController,
                            label: l10n.adminYoutubeFieldWelcomePlayer,
                            hint: l10n.adminYoutubeFieldVideoIdHint,
                            videos: _videos,
                            onChanged: _markDirty,
                          ),
                          const SizedBox(height: 12),
                          _FeaturedVideoField(
                            controller: _welcomeCoachController,
                            label: l10n.adminYoutubeFieldWelcomeCoach,
                            hint: l10n.adminYoutubeFieldVideoIdHint,
                            videos: _videos,
                            onChanged: _markDirty,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: l10n.adminYoutubeVideosSection,
                      trailing: TextButton.icon(
                        onPressed: () => _openVideoSheet(),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l10n.adminYoutubeAddVideo),
                      ),
                      child: _videos.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                l10n.adminYoutubeVideosEmpty,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                for (var i = 0; i < _videos.length; i++) ...[
                                  if (i > 0) const SizedBox(height: 8),
                                  _VideoTile(
                                    video: _videos[i],
                                    isTop:
                                        _videos[i].id ==
                                        _topVideoController.text.trim(),
                                    isWelcomePlayer:
                                        _videos[i].id ==
                                        _welcomePlayerController.text.trim(),
                                    isWelcomeCoach:
                                        _videos[i].id ==
                                        _welcomeCoachController.text.trim(),
                                    onEdit: () => _openVideoSheet(
                                      existing: _videos[i],
                                      index: i,
                                    ),
                                    onDelete: () => _confirmDeleteVideo(i),
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _FeaturedVideoField extends StatelessWidget {
  const _FeaturedVideoField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.videos,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final List<YoutubeVideoEntry> videos;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = controller.text.trim();
    final knownIds = videos.map((v) => v.id).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: knownIds.contains(current) ? current : '',
              items: [
                DropdownMenuItem<String>(
                  value: '',
                  child: Text(l10n.adminYoutubeFeaturedNone),
                ),
                for (final video in videos)
                  DropdownMenuItem<String>(
                    value: video.id,
                    child: Text(
                      video.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) {
                controller.text = value ?? '';
                onChanged();
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: l10n.adminYoutubeFieldVideoIdOrUrl,
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({
    required this.video,
    required this.isTop,
    required this.isWelcomePlayer,
    required this.isWelcomeCoach,
    required this.onEdit,
    required this.onDelete,
  });

  final YoutubeVideoEntry video;
  final bool isTop;
  final bool isWelcomePlayer;
  final bool isWelcomeCoach;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final badges = <String>[
      if (isTop) l10n.adminYoutubeBadgeTop,
      if (isWelcomePlayer) l10n.adminYoutubeBadgeWelcomePlayer,
      if (isWelcomeCoach) l10n.adminYoutubeBadgeWelcomeCoach,
    ];

    return Material(
      color: colors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.play_circle_outline, color: colors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: textTheme.titleSmall?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    video.id,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  if (badges.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final badge in badges)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              badge,
                              style: textTheme.labelSmall?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.adminYoutubeEditVideo,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: l10n.adminYoutubeDeleteVideo,
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, color: colors.danger),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoFormSheet extends StatefulWidget {
  const _VideoFormSheet({this.existing});

  final YoutubeVideoEntry? existing;

  @override
  State<_VideoFormSheet> createState() => _VideoFormSheetState();
}

class _VideoFormSheetState extends State<_VideoFormSheet> {
  late final TextEditingController _idController;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _thumbnailController;
  String? _idError;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _idController = TextEditingController(text: existing?.id ?? '');
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');
    _thumbnailController =
        TextEditingController(text: existing?.thumbnailUrl ?? '');
  }

  @override
  void dispose() {
    _idController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _thumbnailController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = context.l10n;
    final normalized = YoutubeConfigService.normalizeVideoId(_idController.text);
    final title = _titleController.text.trim();
    setState(() {
      _idError = normalized == null || normalized.isEmpty
          ? l10n.adminYoutubeFieldVideoIdInvalid
          : null;
      _titleError =
          title.isEmpty ? l10n.adminYoutubeFieldTitleRequired : null;
    });
    if (_idError != null || _titleError != null) return;

    Navigator.of(context).pop(
      YoutubeVideoEntry(
        id: normalized!,
        title: title,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        thumbnailUrl: _thumbnailController.text.trim().isEmpty
            ? null
            : _thumbnailController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final editing = widget.existing != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing
                  ? l10n.adminYoutubeEditVideoTitle
                  : l10n.adminYoutubeAddVideoTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _idController,
              decoration: InputDecoration(
                labelText: l10n.adminYoutubeFieldVideoIdOrUrl,
                hintText: l10n.adminYoutubeFieldVideoIdHint,
                errorText: _idError,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.adminYoutubeFieldTitle,
                errorText: _titleError,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.adminYoutubeFieldDescription,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _thumbnailController,
              decoration: InputDecoration(
                labelText: l10n.adminYoutubeFieldThumbnailUrl,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submit,
              child: Text(
                editing ? l10n.adminYoutubeUpdateVideo : l10n.adminYoutubeAddVideo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
