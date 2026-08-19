import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_features.dart';
import 'package:grinta/analytics/analytics_interactions.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/member_unsubscribe.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/widget/app_session_player_avatar.dart';
import 'package:provider/provider.dart';

/// Opens the multi-profile management screen (leave / unsubscribe).
Future<void> openManageProfilesScreen(BuildContext context) async {
  final appSession = context.read<AppSession>();
  if (!canManageLinkedProfiles(appSession.currentUserPlayers.length)) {
    return;
  }

  await Navigator.of(context, rootNavigator: true).push(
    analyticsMaterialRoute<void>(
      screenName: AnalyticsScreenNames.manageProfiles,
      builder: (_) => const ManageProfilesScreen(),
    ),
  );
}

class ManageProfilesScreen extends StatefulWidget {
  const ManageProfilesScreen({
    super.key,
    this.playerService,
  });

  final PlayerService? playerService;

  @override
  State<ManageProfilesScreen> createState() => _ManageProfilesScreenState();
}

class _ManageProfilesScreenState extends State<ManageProfilesScreen> {
  late final PlayerService _playerService;
  String? _unsubscribingMemberId;
  final Set<String> _locallyUnsubscribedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _playerService = widget.playerService ?? PlayerService();
  }

  List<Player> _sortedProfiles(AppSession session) {
    final unknownLabel = context.l10n.entityPlayer;
    final players = session.currentUserPlayers.values.where((player) {
      final id = effectiveMemberId(player);
      return id == null || !_locallyUnsubscribedIds.contains(id);
    }).toList();
    players.sort((a, b) {
      return playerDisplayName(a, unknownLabel: unknownLabel)
          .toLowerCase()
          .compareTo(
            playerDisplayName(b, unknownLabel: unknownLabel).toLowerCase(),
          );
    });
    return players;
  }

  Future<void> _unsubscribe(Player player) async {
    if (_unsubscribingMemberId != null) return;

    final l10n = context.l10n;
    final appSession = context.read<AppSession>();
    final uid = appSession.user?.uid.trim() ?? '';
    final memberId = effectiveMemberId(player)?.trim() ?? '';
    final name = playerDisplayName(player, unknownLabel: l10n.entityPlayer);

    if (uid.isEmpty || memberId.isEmpty) {
      AppSnackbar.show(
        context,
        l10n.errorUnsubscribeFromProfile(l10n.myUnavailabilitiesNoPlayer),
      );
      return;
    }

    if (!canManageLinkedProfiles(appSession.currentUserPlayers.length)) {
      return;
    }

    final confirmed = await _confirmUnsubscribe(name);
    if (!mounted || confirmed != true) return;

    setState(() => _unsubscribingMemberId = memberId);

    try {
      await _playerService.unsubscribeUserFromMember(
        memberId: memberId,
        uid: uid,
      );
      AnalyticsInteractions.logFeature(AnalyticsFeatures.unsubscribeFromProfile);
      if (!mounted) return;
      setState(() => _locallyUnsubscribedIds.add(memberId));
      AppSnackbar.show(
        context,
        l10n.successUnsubscribedFromProfile(name),
        isError: false,
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        l10n.errorUnsubscribeFromProfile(error.toString()),
      );
    } finally {
      if (mounted) {
        setState(() => _unsubscribingMemberId = null);
      }
    }
  }

  Future<bool?> _confirmUnsubscribe(String name) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.card,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: colors.border),
          ),
          title: Text(
            l10n.actionUnsubscribeFromProfileConfirmTitle,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            l10n.actionUnsubscribeFromProfileConfirmMessage(name),
            style: TextStyle(
              color: colors.textSecondary,
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.actionCancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.actionUnsubscribeFromProfile),
            ),
          ],
        );
      },
    );
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
          l10n.settingsManageProfiles,
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Consumer<AppSession>(
        builder: (context, session, _) {
          final profiles = _sortedProfiles(session);
          final canUnsubscribe = canManageLinkedProfiles(profiles.length);
          final selectedId = session.selectedPlayerId;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text(
                l10n.settingsManageProfilesHint,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              for (final player in profiles) ...[
                _ManageProfileTile(
                  player: player,
                  isCurrent: effectiveMemberId(player) == selectedId,
                  canUnsubscribe: canUnsubscribe,
                  isBusy: _unsubscribingMemberId != null &&
                      _unsubscribingMemberId == effectiveMemberId(player),
                  onUnsubscribe: _unsubscribingMemberId == null
                      ? () => _unsubscribe(player)
                      : null,
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ManageProfileTile extends StatelessWidget {
  const _ManageProfileTile({
    required this.player,
    required this.isCurrent,
    required this.canUnsubscribe,
    required this.isBusy,
    required this.onUnsubscribe,
  });

  final Player player;
  final bool isCurrent;
  final bool canUnsubscribe;
  final bool isBusy;
  final VoidCallback? onUnsubscribe;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final name = playerDisplayName(player, unknownLabel: l10n.entityPlayer);

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppSessionPlayerAvatar(
                player: player,
                radius: 22,
                watchSessionForStaleWebAvatar: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.settingsManageProfilesCurrentBadge,
                        style: textTheme.labelMedium?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (canUnsubscribe) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: isBusy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : TextButton.icon(
                      onPressed: onUnsubscribe,
                      icon: Icon(
                        Icons.person_remove_outlined,
                        color: colors.danger,
                      ),
                      label: Text(
                        l10n.actionUnsubscribeFromProfile,
                        style: TextStyle(
                          color: colors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
