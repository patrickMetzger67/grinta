import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/calendar_sync_config.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/calendar_sync_repository.dart';
import 'package:grinta/services/calendar_sync_service.dart';
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

class _CalendarSyncToggleState extends State<CalendarSyncToggle> {
  final CalendarSyncRepository _repository = CalendarSyncRepository();
  bool _busy = false;

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

  Future<void> _redownloadWebCalendar() async {
    if (_busy || !kIsWeb) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final appSession = context.read<AppSession>();
    final playerId = appSession.selectedPlayerId;

    if (uid == null || playerId == null) return;

    setState(() => _busy = true);
    try {
      final result = await CalendarSyncService.instance.redownloadWebCalendar(
        uid: uid,
        playerId: playerId,
        appSession: appSession,
      );

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.calendarSyncWebDownloaded)),
        );
      } else if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.calendarSyncEnableFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
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

    if (uid == null || playerId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<CalendarSyncConfig?>(
      stream: _repository.watchConfig(uid, playerId),
      builder: (context, snapshot) {
        final enabled = snapshot.data?.enabled == true;

        return ListTile(
          contentPadding: widget.contentPadding,
          dense: widget.dense,
          onTap: kIsWeb && enabled && !_busy ? _redownloadWebCalendar : null,
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
                ? (enabled
                    ? l10n.calendarSyncWebRedownloadHint
                    : l10n.calendarSyncWebSubtitle)
                : l10n.calendarSyncToggleSubtitle,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
            ),
          ),
          trailing: Switch(
            value: enabled,
            onChanged: _busy ? null : _onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: colors.primary,
            inactiveThumbColor: colors.textSecondary,
            inactiveTrackColor: colors.border,
          ),
        );
      },
    );
  }
}
