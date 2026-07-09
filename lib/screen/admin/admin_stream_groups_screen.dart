import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/services/stream_channel_admin_service.dart';
import 'package:grinta/services/stream_channel_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:intl/intl.dart';

class AdminStreamGroupsScreen extends StatefulWidget {
  const AdminStreamGroupsScreen({super.key});

  @override
  State<AdminStreamGroupsScreen> createState() =>
      _AdminStreamGroupsScreenState();
}

class _AdminStreamGroupsScreenState extends State<AdminStreamGroupsScreen> {
  final StreamChannelAdminService _service =
      StreamChannelAdminService.instance;

  bool _isLoading = true;
  Object? _loadError;
  List<AdminStreamChannel> _channels = const <AdminStreamChannel>[];
  final Set<String> _deletingTeamIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final channels = await _service.listTeamStreamChannels();
      if (!mounted) return;
      setState(() {
        _channels = channels;
        _isLoading = false;
      });
    } on StateError catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message == 'permission-denied'
            ? 'permission-denied'
            : e;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDelete(AdminStreamChannel channel) async {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final displayName = channel.teamName?.isNotEmpty == true
        ? channel.teamName!
        : channel.name;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        title: Text(
          l10n.adminStreamGroupsDeleteConfirmTitle,
          style: textTheme.titleLarge?.copyWith(color: colors.textPrimary),
        ),
        content: Text(
          l10n.adminStreamGroupsDeleteConfirmMessage(displayName, channel.cid),
          style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.adminStreamGroupsCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.adminStreamGroupsDelete,
              style: TextStyle(color: colors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _deleteChannel(channel);
  }

  Future<void> _deleteChannel(AdminStreamChannel channel) async {
    final l10n = context.l10n;

    setState(() => _deletingTeamIds.add(channel.teamId));

    try {
      await _service.deleteTeamStreamChannel(teamId: channel.teamId);
      if (!mounted) return;

      setState(() {
        _channels = _channels
            .where((entry) => entry.teamId != channel.teamId)
            .toList();
      });

      AppSnackbar.show(
        context,
        l10n.adminStreamGroupsDeleted,
        isError: false,
      );
    } on StateError catch (e) {
      if (e.message == 'permission-denied' && mounted) {
        AppSnackbar.show(context, l10n.adminStreamGroupsPermissionDenied);
      }
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        StreamChannelService.userFacingError(e),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        l10n.adminStreamGroupsDeleteFailed,
      );
    } finally {
      if (mounted) {
        setState(() => _deletingTeamIds.remove(channel.teamId));
      }
    }
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
          l10n.adminStreamGroupsTitle,
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: l10n.adminStreamGroupsRefresh,
            onPressed: _isLoading ? null : _loadChannels,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = context.l10n;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      final message = _loadError == 'permission-denied'
          ? l10n.adminStreamGroupsPermissionDenied
          : l10n.adminStreamGroupsLoadError;

      return _emptyState(
        context,
        message,
        _loadError == 'permission-denied'
            ? ''
            : _loadError.toString(),
        showRetry: true,
      );
    }

    if (_channels.isEmpty) {
      return _emptyState(
        context,
        l10n.adminStreamGroupsEmpty,
        l10n.adminStreamGroupsEmptySubtitle,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChannels,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _channels.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) =>
            _buildChannelTile(context, _channels[index]),
      ),
    );
  }

  Widget _buildChannelTile(BuildContext context, AdminStreamChannel channel) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final isDeleting = _deletingTeamIds.contains(channel.teamId);
    final title = channel.teamName?.isNotEmpty == true
        ? channel.teamName!
        : channel.name;
    final subtitleName = channel.teamName?.isNotEmpty == true &&
            channel.name.isNotEmpty &&
            channel.name != channel.teamName
        ? channel.name
        : null;
    final lastMessageAt = channel.lastMessageAt == null
        ? ''
        : DateFormat.yMd(Localizations.localeOf(context).toString())
            .add_Hm()
            .format(channel.lastMessageAt!.toLocal());

    return Material(
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.forum_outlined, color: colors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitleName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitleName,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    l10n.adminStreamGroupsCid(channel.cid),
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.adminStreamGroupsMemberCount(channel.memberCount),
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  if (lastMessageAt.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      l10n.adminStreamGroupsLastMessageAt(lastMessageAt),
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            isDeleting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    tooltip: l10n.adminStreamGroupsDelete,
                    onPressed: () => _confirmDelete(channel),
                    icon: Icon(Icons.delete_outline, color: colors.danger),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(
    BuildContext context,
    String title,
    String subtitle, {
    bool showRetry = false,
  }) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 42, color: colors.textSecondary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
            if (showRetry) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadChannels,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.adminStreamGroupsRefresh),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
