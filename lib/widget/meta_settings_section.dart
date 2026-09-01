import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/meta_share_strings.dart';
import 'package:grinta/model/meta_sync_config.dart';
import 'package:grinta/services/meta_connect_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/settings_menu_style.dart';

/// Optional Instagram / Facebook connect. Never required to share.
class MetaSettingsSection extends StatelessWidget {
  const MetaSettingsSection({
    super.key,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.webCardStyle = false,
  });

  final EdgeInsetsGeometry contentPadding;
  final bool webCardStyle;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<MetaSyncConfig?>(
      stream: MetaConnectService.instance.repository.watchConfig(uid),
      builder: (context, snapshot) {
        final config = snapshot.data;
        final connected = config?.connected == true;
        return _MetaSettingsTile(
          contentPadding: contentPadding,
          webCardStyle: webCardStyle,
          connected: connected,
          accountHint: config?.instagramUsername ?? config?.pageName,
        );
      },
    );
  }
}

class _MetaSettingsTile extends StatelessWidget {
  const _MetaSettingsTile({
    required this.contentPadding,
    required this.webCardStyle,
    required this.connected,
    this.accountHint,
  });

  final EdgeInsetsGeometry contentPadding;
  final bool webCardStyle;
  final bool connected;
  final String? accountHint;

  @override
  Widget build(BuildContext context) {
    final strings = MetaShareStrings.of(context.l10n);
    final colors = context.appColors;
    final subtitle = connected
        ? strings.connectedStatus(accountHint ?? '')
        : strings.settingsSubtitle;

    void open() => _openSheet(context);

    if (webCardStyle) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: open,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.public_outlined, color: colors.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.settingsTitle,
                          style: settingsMenuTitleStyle(context),
                        ),
                        Text(subtitle, style: settingsMenuSubtitleStyle(context)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ListTile(
      contentPadding: contentPadding,
      leading: Icon(Icons.public_outlined, color: colors.primary),
      title: Text(strings.settingsTitle, style: settingsMenuTitleStyle(context)),
      subtitle: Text(subtitle, style: settingsMenuSubtitleStyle(context)),
      trailing: Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
      onTap: open,
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    final strings = MetaShareStrings.of(context.l10n);
    final colors = context.appColors;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(strings.settingsTitle, style: settingsMenuTitleStyle(context)),
                const SizedBox(height: 8),
                Text(
                  connected
                      ? strings.connectedStatus(accountHint ?? '')
                      : strings.settingsSubtitle,
                  style: settingsMenuSubtitleStyle(context),
                ),
                const SizedBox(height: 16),
                if (connected)
                  FilledButton(
                    onPressed: () async {
                      final ok = await MetaConnectService.instance.disconnect();
                      if (!sheetContext.mounted) return;
                      Navigator.pop(sheetContext);
                      if (context.mounted && !ok) {
                        AppSnackbar.show(
                          context,
                          strings.connectFailed,
                          isError: true,
                        );
                      }
                    },
                    child: Text(strings.disconnectButton),
                  )
                else
                  FilledButton(
                    onPressed: () async {
                      final result =
                          await MetaConnectService.instance.startOAuth();
                      if (!sheetContext.mounted) return;
                      Navigator.pop(sheetContext);
                      if (!context.mounted) return;
                      if (result == MetaConnectResult.failed ||
                          result == MetaConnectResult.launchFailed ||
                          result == MetaConnectResult.unauthenticated) {
                        AppSnackbar.show(
                          context,
                          strings.connectFailed,
                          isError: true,
                        );
                      }
                    },
                    child: Text(strings.connectButton),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
