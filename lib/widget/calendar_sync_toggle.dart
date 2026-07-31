import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/calendar_sync_config.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/calendar_sync_repository.dart';
import 'package:grinta/services/calendar_sync_service.dart';
import 'package:grinta/services/grinta_device_calendar_platform.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:provider/provider.dart';

class CalendarSyncToggle extends StatefulWidget {
  const CalendarSyncToggle({
    super.key,
    this.contentPadding,
    this.dense = false,
  });

  final EdgeInsetsGeometry? contentPadding;
  final bool dense;

  @override
  State<CalendarSyncToggle> createState() => _CalendarSyncToggleState();
}

class _CalendarSyncToggleState extends State<CalendarSyncToggle>
    with SingleTickerProviderStateMixin {
  final CalendarSyncRepository _repository = CalendarSyncRepository();
  bool _busy = false;
  bool _forceSyncInProgress = false;
  late final AnimationController _syncSpinController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void dispose() {
    _syncSpinController.dispose();
    super.dispose();
  }

  String _calendarNameForSession(AppSession appSession) {
    final player = appSession.selectedPlayer;
    if (player == null) return 'Grinta';
    return CalendarSyncService.instance.calendarDisplayNameForPlayer(player);
  }

  Future<void> _showLocalCalendarHelp(
    String calendarName, {
    String? calendarId,
  }) async {
    if (!mounted || kIsWeb) return;
    final l10n = context.l10n;
    final colors = context.appColors;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.card,
          title: Text(l10n.calendarSyncEnabledTitle),
          content: SingleChildScrollView(
            child: Text(
              l10n.calendarSyncEnabledMessage(calendarName),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.calendarSyncHelpUnderstood),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final opened = await GrintaDeviceCalendarPlatform.openCalendarApp(
                  calendarId: calendarId,
                );
                if (!opened.ok && mounted) {
                  debugPrint(
                    'Open calendar failed via=${opened.via} detail=${opened.detail}',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.calendarSyncOpenCalendarFailed)),
                  );
                }
              },
              child: Text(l10n.calendarSyncOpenCalendar),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onChanged(bool value) async {
    if (_busy) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final appSession = context.read<AppSession>();
    final playerId = appSession.selectedPlayerId;
    final player = appSession.selectedPlayer;

    if (uid == null || playerId == null || player == null) return;

    setState(() => _busy = true);

    try {
      if (value) {
        final result = await CalendarSyncService.instance.enableSync(
          uid: uid,
          playerId: playerId,
          player: player,
          appSession: appSession,
        );

        if (!mounted) return;

        if (result.success && kIsWeb) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.calendarSyncWebDownloaded)),
          );
        } else if (result.success && !kIsWeb) {
          final config = await _repository.getConfig(uid, playerId);
          if (!mounted) return;
          await _showLocalCalendarHelp(
            config?.calendarDisplayName ?? _calendarNameForSession(appSession),
            calendarId: config?.calendarExternalId,
          );
        } else if (!result.success) {
          final message = switch (result) {
            CalendarSyncResult.permissionDenied =>
              context.l10n.calendarSyncPermissionDenied,
            CalendarSyncResult.calendarCreationFailed =>
              context.l10n.calendarSyncCalendarCreationFailed,
            _ => context.l10n.calendarSyncEnableFailed,
          };
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      } else {
        await CalendarSyncService.instance.disableSync(
          uid: uid,
          playerId: playerId,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.calendarSyncEnableFailed),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _forceSyncNow() async {
    if (_forceSyncInProgress || _busy) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final appSession = context.read<AppSession>();
    final playerId = appSession.selectedPlayerId;

    if (uid == null || playerId == null) return;

    setState(() => _forceSyncInProgress = true);
    _syncSpinController.repeat();
    try {
      final result = kIsWeb
          ? await CalendarSyncService.instance.redownloadWebCalendar(
              uid: uid,
              playerId: playerId,
              appSession: appSession,
            )
          : await CalendarSyncService.instance.syncForPlayer(
              uid: uid,
              playerId: playerId,
              appSession: appSession,
              force: true,
            );

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb
                  ? context.l10n.calendarSyncWebDownloaded
                  : context.l10n.calendarSyncForceSuccess,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.calendarSyncForceFailed)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.calendarSyncForceFailed)),
      );
    } finally {
      if (mounted) {
        _syncSpinController.stop();
        _syncSpinController.reset();
        setState(() => _forceSyncInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final playerId = context.select<AppSession, String?>(
      (session) => session.selectedPlayerId,
    );
    final appSession = context.read<AppSession>();

    if (uid == null || playerId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<CalendarSyncConfig?>(
      stream: _repository.watchConfig(uid, playerId),
      builder: (context, snapshot) {
        final enabled = snapshot.data?.enabled == true;
        final calendarName = snapshot.data?.calendarDisplayName ??
            _calendarNameForSession(appSession);
        final calendarId = snapshot.data?.calendarExternalId;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: widget.contentPadding,
              dense: widget.dense,
              leading: _busy
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: colors.primary,
                      ),
                    )
                  : Icon(
                      Icons.calendar_month_outlined,
                      color: colors.primary,
                    ),
              title: Text(
                l10n.calendarSyncToggleLabel,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                kIsWeb
                    ? l10n.calendarSyncWebSubtitle
                    : l10n.calendarSyncToggleSubtitle,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                ),
              ),
              trailing: Switch(
                value: enabled,
                onChanged: (_busy || _forceSyncInProgress) ? null : _onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: colors.primary,
                inactiveThumbColor: colors.textSecondary,
                inactiveTrackColor: colors.border,
              ),
            ),
            if (enabled)
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 16, bottom: 4),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 0,
                  children: [
                    TextButton.icon(
                      onPressed: _forceSyncNow,
                      icon: RotationTransition(
                        turns: _syncSpinController,
                        child: Icon(
                          Icons.sync,
                          size: 18,
                          color: colors.primary,
                        ),
                      ),
                      label: Text(l10n.calendarSyncForceNow),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    if (!kIsWeb)
                      TextButton.icon(
                        onPressed: () => _showLocalCalendarHelp(
                          calendarName,
                          calendarId: calendarId,
                        ),
                        icon: Icon(
                          Icons.help_outline,
                          size: 18,
                          color: colors.primary,
                        ),
                        label: Text(l10n.calendarSyncHelpButton),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
