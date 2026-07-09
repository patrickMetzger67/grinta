import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/config/subscription_config.dart';
import 'package:grinta/services/eshop_config_service.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/notification.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/match_detail_screen.dart';
import 'package:grinta/services/analytics_service.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/match_convocation_service.dart';
import 'package:grinta/services/internal_notification_navigation.dart';
import 'package:grinta/services/notificationService.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/settings_menu_style.dart';
import 'package:grinta/util/match_compo_pitch_mapper.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/widget/nav_icon_count_badge.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

String? _selectedPlayerMemberId(AppSession session) {
  final player = session.selectedPlayer;
  if (player == null) return null;
  final memberId = effectiveMemberId(player);
  if (memberId == null || memberId.trim().isEmpty) return null;
  return memberId;
}

int _visibleNotificationCount(List<NotificationApp> notifications) {
  return filterCommerceNotifications(notifications).length;
}

void _logNotificationsStreamError({
  required String source,
  required String? playerId,
  required Object error,
}) {
  if (error is FirebaseException) {
    debugPrint(
      'Notifications stream failed in $source: '
      'playerId=$playerId code=${error.code} message=${error.message}',
    );
    if (error.code == 'failed-precondition') {
      debugPrint(
        'Firestore index may be missing for notification query '
        '(playerId filter). Full error: $error',
      );
    }
  } else {
    debugPrint(
      'Notifications stream failed in $source: playerId=$playerId $error',
    );
  }
}

Future<void> showNotificationsPanel(BuildContext context) async {
  AnalyticsService.instance.logScreenView(
    screenName: AnalyticsScreenNames.notifications,
  );

  if (kIsWeb) {
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => const _NotificationsDialog(),
    );
    return;
  }

  final colors = context.appColors;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: colors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => const _NotificationsSheet(),
  );
}

class NotificationSidebarEntry extends StatelessWidget {
  const NotificationSidebarEntry({
    super.key,
    required this.collapsed,
    this.itemHeight = 48,
  });

  final bool collapsed;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    final playerId = context.select<AppSession, String?>(
      _selectedPlayerMemberId,
    );

    if (playerId == null) {
      return _NotificationSidebarTile(
        collapsed: collapsed,
        count: 0,
        itemHeight: itemHeight,
        onTap: () => showNotificationsPanel(context),
      );
    }

    return ListenableBuilder(
      listenable: EshopConfigService.instance,
      builder: (context, _) {
        return StreamBuilder<List<NotificationApp>>(
          stream: NotificationService()
              .streamUnviewedNotificationsByPlayerId(playerId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              _logNotificationsStreamError(
                source: 'NotificationSidebarEntry',
                playerId: playerId,
                error: snapshot.error!,
              );
            }
            final count = snapshot.hasError
                ? 0
                : _visibleNotificationCount(snapshot.data ?? const []);
            return _NotificationSidebarTile(
              collapsed: collapsed,
              count: count,
              itemHeight: itemHeight,
              onTap: () => showNotificationsPanel(context),
            );
          },
        );
      },
    );
  }
}

class NotificationAppBarButton extends StatelessWidget {
  const NotificationAppBarButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final playerId = context.select<AppSession, String?>(
      _selectedPlayerMemberId,
    );

    if (playerId == null) {
      return IconButton(
        tooltip: context.l10n.navNotifications,
        onPressed: () => showNotificationsPanel(context),
        icon: NavIconCountBadge(
          icon: Icons.notifications_outlined,
          count: 0,
          iconColor: colors.textPrimary,
        ),
      );
    }

    return ListenableBuilder(
      listenable: EshopConfigService.instance,
      builder: (context, _) {
        return StreamBuilder<List<NotificationApp>>(
          stream: NotificationService()
              .streamUnviewedNotificationsByPlayerId(playerId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              _logNotificationsStreamError(
                source: 'NotificationAppBarButton',
                playerId: playerId,
                error: snapshot.error!,
              );
            }
            final count = snapshot.hasError
                ? 0
                : _visibleNotificationCount(snapshot.data ?? const []);
            return IconButton(
              tooltip: context.l10n.navNotifications,
              onPressed: () => showNotificationsPanel(context),
              icon: NavIconCountBadge(
                icon: Icons.notifications_outlined,
                count: count,
                iconColor: colors.textPrimary,
              ),
            );
          },
        );
      },
    );
  }
}

class _NotificationSidebarTile extends StatefulWidget {
  const _NotificationSidebarTile({
    required this.collapsed,
    required this.count,
    required this.itemHeight,
    required this.onTap,
  });

  final bool collapsed;
  final int count;
  final double itemHeight;
  final VoidCallback onTap;

  @override
  State<_NotificationSidebarTile> createState() =>
      _NotificationSidebarTileState();
}

class _NotificationSidebarTileState extends State<_NotificationSidebarTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    final tile = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          height: widget.itemHeight,
          padding: EdgeInsets.symmetric(
            horizontal: widget.collapsed ? 0 : 14,
          ),
          decoration: BoxDecoration(
            color: _hovered ? colors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: widget.collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              NavIconCountBadge(
                icon: Icons.notifications_outlined,
                count: widget.count,
                iconColor: colors.textSecondary,
                iconSize: kWebMenuIconSize,
              ),
              if (!widget.collapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.navNotifications,
                    overflow: TextOverflow.ellipsis,
                    style: webSidebarNavLabelStyle(
                      context,
                      selected: false,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (widget.collapsed) {
      return MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Tooltip(
          message: l10n.navNotifications,
          child: tile,
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: tile,
    );
  }
}

class _NotificationsDialog extends StatelessWidget {
  const _NotificationsDialog();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Dialog(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: const _NotificationsListBody(showDragHandle: false),
      ),
    );
  }
}

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: const _NotificationsListBody(showDragHandle: true),
      ),
    );
  }
}

class _NotificationsListBody extends StatelessWidget {
  const _NotificationsListBody({required this.showDragHandle});

  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final playerId = context.select<AppSession, String?>(
      _selectedPlayerMemberId,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDragHandle) ...[
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.notificationsTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              IconButton(
                tooltip: l10n.featureDiscoveryDismiss,
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close_rounded, color: colors.textSecondary),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: colors.border),
        Expanded(
          child: playerId == null
              ? _NotificationsEmptyState(message: l10n.notificationsEmptyMessage)
              : ListenableBuilder(
                  listenable: EshopConfigService.instance,
                  builder: (context, _) {
                    return StreamBuilder<List<NotificationApp>>(
                      stream: NotificationService()
                          .streamUnviewedNotificationsByPlayerId(playerId),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          _logNotificationsStreamError(
                            source: '_NotificationsListBody',
                            playerId: playerId,
                            error: snapshot.error!,
                          );
                          return _NotificationsEmptyState(
                            message: l10n.notificationsEmptyMessage,
                          );
                        }

                        final notifications = filterCommerceNotifications(
                          snapshot.data ?? const [],
                        );
                        if (notifications.isEmpty) {
                          return _NotificationsEmptyState(
                            message: l10n.notificationsEmptyMessage,
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                          itemCount: notifications.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            return _NotificationListTile(
                              notification: notifications[index],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _NotificationListTile extends StatefulWidget {
  const _NotificationListTile({required this.notification});

  final NotificationApp notification;

  @override
  State<_NotificationListTile> createState() => _NotificationListTileState();
}

class _NotificationListTileState extends State<_NotificationListTile> {
  final NotificationService _notificationService = NotificationService();
  final MatchConvocationService _matchConvocationService =
      MatchConvocationService();
  final MatchService _matchService = MatchService();
  bool _isMarkingRead = false;
  bool _isConvocationActionInProgress = false;

  static const _readCheckboxTypes = {NotifType.match, NotifType.highlights};

  bool get _showsReadCheckbox =>
      _readCheckboxTypes.contains(widget.notification.type);

  bool get _showsConvocationActions =>
      widget.notification.type == NotifType.convocation;

  bool get _isTappableReminder =>
      widget.notification.type == NotifType.trainingReminder ||
      widget.notification.type == NotifType.matchOpponentStatsReminder;

  Future<void> _openReminderTarget() async {
    if (_isConvocationActionInProgress) return;

    final objectId = widget.notification.objectId?.trim() ?? '';
    if (objectId.isEmpty) return;

    final typeName = widget.notification.type == NotifType.trainingReminder
        ? 'trainingReminder'
        : 'matchOpponentStatsReminder';

    setState(() => _isConvocationActionInProgress = true);
    try {
      await InternalNotificationNavigation.handlePayload(<String, dynamic>{
        'type': typeName,
        'id': objectId,
        if (widget.notification.type == NotifType.trainingReminder)
          'trainingId': objectId
        else
          'matchId': objectId,
        if (widget.notification.playerId != null)
          'playerId': widget.notification.playerId,
      });
      await _markAsRead();
    } finally {
      if (mounted) {
        setState(() => _isConvocationActionInProgress = false);
      }
    }
  }

  String? _formatCreatedAt(BuildContext context) {
    final created = widget.notification.dateTimeCreated?.toDate();
    if (created == null) return null;

    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).add_Hm().format(created.toLocal());
  }

  Future<void> _markAsRead() async {
    final notificationId = widget.notification.ref?.id;
    if (notificationId == null || _isMarkingRead) return;

    setState(() => _isMarkingRead = true);
    try {
      await _notificationService.markNotificationAsViewed(notificationId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isMarkingRead = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.notificationsMarkAsReadError)),
      );
    }
  }

  List<String> _sessionTeamIds(AppSession session) {
    return normalizeTeamIdList(session.teamIdsForSelectedSeason);
  }

  void _showConvocationActionError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.notificationsConvocationActionError)),
    );
  }

  Future<void> _openMatchDetails() async {
    if (_isConvocationActionInProgress) return;

    final matchId = widget.notification.objectId?.trim() ?? '';
    if (matchId.isEmpty) {
      _showConvocationActionError();
      return;
    }

    setState(() => _isConvocationActionInProgress = true);
    try {
      final match = await _matchService.getMatchById(matchId);
      if (!mounted) return;
      if (match == null) {
        setState(() => _isConvocationActionInProgress = false);
        _showConvocationActionError();
        return;
      }

      final session = context.read<AppSession>();
      final playerId = _selectedPlayerMemberId(session);
      final managedIds = session.managedTeamsIdsForSelectedSeason;
      final matchTeams = match.teams ?? const <dynamic>[];
      final isManager = matchTeams.any(
        (teamId) => managedIds.contains(teamId?.toString()),
      );

      await Navigator.of(context, rootNavigator: true).push(
        analyticsMaterialRoute<void>(
          screenName: AnalyticsScreenNames.matchDetail,
          fullscreenDialog: true,
          builder: (_) => MatchDetailScreen(
            match: match,
            isManager: isManager,
            playerId: playerId,
            initialTabIndex: 0,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        _showConvocationActionError();
      }
    } finally {
      if (mounted) {
        setState(() => _isConvocationActionInProgress = false);
      }
    }
  }

  Future<void> _respondPresent() async {
    if (_isConvocationActionInProgress) return;

    final notificationId = widget.notification.ref?.id;
    if (notificationId == null) {
      _showConvocationActionError();
      return;
    }

    setState(() => _isConvocationActionInProgress = true);
    try {
      final session = context.read<AppSession>();
      await _matchConvocationService.respondPresentToConvocation(
        notificationId: notificationId,
        notification: widget.notification,
        profileTeamIds: _sessionTeamIds(session),
      );
    } catch (_) {
      if (mounted) {
        _showConvocationActionError();
      }
    } finally {
      if (mounted) {
        setState(() => _isConvocationActionInProgress = false);
      }
    }
  }

  Future<String?> _promptAbsentMessage() async {
    final l10n = context.l10n;
    final controller = TextEditingController();

    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.notificationsConvocationAbsentDialogTitle),
          content: TextField(
            controller: controller,
            maxLines: 4,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.notificationsConvocationAbsentMessageHint,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.actionCancel),
            ),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.notificationsConvocationAbsentMessageRequired,
                      ),
                    ),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(text);
              },
              child: Text(l10n.notificationsConvocationAbsentConfirm),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return message;
  }

  Future<void> _respondAbsent() async {
    if (_isConvocationActionInProgress) return;

    final notificationId = widget.notification.ref?.id;
    if (notificationId == null) {
      _showConvocationActionError();
      return;
    }

    final feedbackMessage = await _promptAbsentMessage();
    if (feedbackMessage == null || feedbackMessage.trim().isEmpty) {
      return;
    }

    if (!mounted) return;
    final l10n = context.l10n;

    final respondingUserId =
        FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (respondingUserId.isEmpty) {
      _showConvocationActionError();
      return;
    }

    setState(() => _isConvocationActionInProgress = true);
    try {
      final session = context.read<AppSession>();
      await _matchConvocationService.respondAbsentToConvocation(
        l10n: l10n,
        notificationId: notificationId,
        notification: widget.notification,
        profileTeamIds: _sessionTeamIds(session),
        feedbackMessage: feedbackMessage,
        respondingUserId: respondingUserId,
      );
    } catch (_) {
      if (mounted) {
        _showConvocationActionError();
      }
    } finally {
      if (mounted) {
        setState(() => _isConvocationActionInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final createdLabel = _formatCreatedAt(context);
    final title = widget.notification.title?.trim();
    final body = widget.notification.body?.trim();

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _isTappableReminder ? _openReminderTarget : null,
        child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null && title.isNotEmpty)
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    if (body != null && body.isNotEmpty) ...[
                      if (title != null && title.isNotEmpty)
                        const SizedBox(height: 6),
                      Text(
                        body,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                      ),
                    ],
                    if (createdLabel != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        createdLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary.withValues(alpha: 0.85),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_showsReadCheckbox)
                Tooltip(
                  message: l10n.notificationsMarkAsRead,
                  child: Semantics(
                    label: l10n.notificationsMarkAsRead,
                    checked: false,
                    child: Checkbox(
                      value: false,
                      activeColor: colors.primary,
                      onChanged: _isMarkingRead ? null : (_) => _markAsRead(),
                    ),
                  ),
                ),
            ],
          ),
          if (_showsConvocationActions) ...[
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton(
                  onPressed: _isConvocationActionInProgress
                      ? null
                      : _openMatchDetails,
                  child: Text(l10n.notificationsConvocationMatchDetails),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.success,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              colors.success.withValues(alpha: 0.45),
                        ),
                        onPressed: _isConvocationActionInProgress
                            ? null
                            : _respondPresent,
                        child: Text(l10n.notificationsConvocationPresent),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.danger,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              colors.danger.withValues(alpha: 0.45),
                        ),
                        onPressed: _isConvocationActionInProgress
                            ? null
                            : _respondAbsent,
                        child: Text(l10n.notificationsConvocationAbsent),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
        ),
      ),
    );
  }
}

class _NotificationsEmptyState extends StatelessWidget {
  const _NotificationsEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 48,
              color: colors.textSecondary.withValues(alpha: 0.65),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.notificationsEmptyTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
