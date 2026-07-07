import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/services/internal_reminder_service.dart';
import 'package:grinta/services/notification_preferences_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/settings_menu_style.dart';

/// Opens reminder preferences in a dialog on web and a bottom sheet on mobile.
Future<void> showNotificationPreferencesSheet(BuildContext context) {
  if (kIsWeb) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: context.appColors.card,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: context.appColors.border),
        ),
        child: const SizedBox(
          width: 520,
          height: 580,
          child: NotificationPreferencesContent(),
        ),
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useRootNavigator: true,
    backgroundColor: context.appColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) => NotificationPreferencesContent(
        scrollController: scrollController,
      ),
    ),
  );
}

/// Settings row that opens [showNotificationPreferencesSheet].
class NotificationPreferencesSection extends StatelessWidget {
  const NotificationPreferencesSection({
    super.key,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.webCardStyle = false,
  });

  final EdgeInsetsGeometry contentPadding;
  final bool webCardStyle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    void openPreferences() => showNotificationPreferencesSheet(context);

    if (webCardStyle) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: openPreferences,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: colors.primary,
                    size: kWebMenuIconSize,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.settingsNotificationsSection,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: settingsMenuTitleStyle(context),
                        ),
                        Text(
                          l10n.settingsRemindersSubtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: settingsMenuSubtitleStyle(context),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textSecondary,
                    size: kWebMenuIconSize,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ListTile(
      contentPadding: contentPadding,
      leading: Icon(
        Icons.notifications_outlined,
        color: colors.primary,
      ),
      title: Text(
        l10n.settingsNotificationsSection,
        style: settingsMenuTitleStyle(context),
      ),
      subtitle: Text(
        l10n.settingsRemindersSubtitle,
        style: settingsMenuSubtitleStyle(context),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colors.textSecondary,
      ),
      onTap: openPreferences,
    );
  }
}

class NotificationPreferencesContent extends StatefulWidget {
  const NotificationPreferencesContent({
    super.key,
    this.scrollController,
  });

  final ScrollController? scrollController;

  @override
  State<NotificationPreferencesContent> createState() =>
      _NotificationPreferencesContentState();
}

class _NotificationPreferencesContentState
    extends State<NotificationPreferencesContent> {
  bool _loading = true;
  bool _saving = false;
  late NotificationPreferences _draft;

  @override
  void initState() {
    super.initState();
    _draft = NotificationPreferencesService.instance.preferences;
    _load();
  }

  Future<void> _load() async {
    await NotificationPreferencesService.instance.ensureInitialized();
    if (!mounted) return;
    setState(() {
      _draft = NotificationPreferencesService.instance.preferences;
      _loading = false;
    });
  }

  Future<void> _persist(NotificationPreferences next) async {
    setState(() {
      _draft = next;
      _saving = true;
    });

    try {
      await NotificationPreferencesService.instance.save(next);
      InternalReminderService.instance.onPreferencesSaved();
      if (mounted) {
        AppSnackbar.show(
          context,
          context.l10n.successSettingsSaved,
          isError: false,
          preferDialog: true,
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          context.l10n.errorGeneric('preferences'),
          preferDialog: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickHour({
    required int current,
    required ValueChanged<int> onSelected,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current, minute: 0),
    );
    if (picked == null) return;
    onSelected(picked.hour);
  }

  List<({int day, String label})> _weekdayOptions(BuildContext context) {
    final l10n = context.l10n;
    return [
      (day: DateTime.monday, label: l10n.reminderWeekdayMon),
      (day: DateTime.tuesday, label: l10n.reminderWeekdayTue),
      (day: DateTime.wednesday, label: l10n.reminderWeekdayWed),
      (day: DateTime.thursday, label: l10n.reminderWeekdayThu),
      (day: DateTime.friday, label: l10n.reminderWeekdayFri),
      (day: DateTime.saturday, label: l10n.reminderWeekdaySat),
      (day: DateTime.sunday, label: l10n.reminderWeekdaySun),
    ];
  }

  Widget _buildBody(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            l10n.settingsRemindersEnabled,
            style: TextStyle(color: colors.textPrimary),
          ),
          value: _draft.remindersEnabled,
          onChanged: _saving
              ? null
              : (value) => _persist(_draft.copyWith(remindersEnabled: value)),
          activeThumbColor: Colors.white,
          activeTrackColor: colors.primary,
        ),
        Text(
          l10n.settingsQuietDaysLabel,
          style: TextStyle(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final option in _weekdayOptions(context))
              FilterChip(
                label: Text(option.label),
                selected: _draft.quietDays.contains(option.day),
                showCheckmark: true,
                checkmarkColor: colors.primary,
                selectedColor: colors.primary.withValues(alpha: 0.18),
                side: BorderSide(
                  color: _draft.quietDays.contains(option.day)
                      ? colors.primary
                      : colors.border,
                ),
                labelStyle: TextStyle(
                  color: _draft.quietDays.contains(option.day)
                      ? colors.primary
                      : colors.textPrimary,
                ),
                onSelected: _saving
                    ? null
                    : (selected) {
                        final nextDays = List<int>.from(_draft.quietDays);
                        if (selected) {
                          nextDays.add(option.day);
                        } else {
                          nextDays.remove(option.day);
                        }
                        nextDays.sort();
                        _persist(_draft.copyWith(quietDays: nextDays));
                      },
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          l10n.settingsQuietHoursLabel,
          style: TextStyle(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            l10n.settingsQuietHoursStart,
            style: TextStyle(color: colors.textPrimary),
          ),
          trailing: Text(
            '${_draft.quietHoursStart.toString().padLeft(2, '0')}:00',
            style: TextStyle(color: colors.primary),
          ),
          onTap: _saving
              ? null
              : () => _pickHour(
                    current: _draft.quietHoursStart,
                    onSelected: (hour) =>
                        _persist(_draft.copyWith(quietHoursStart: hour)),
                  ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            l10n.settingsQuietHoursEnd,
            style: TextStyle(color: colors.textPrimary),
          ),
          trailing: Text(
            '${_draft.quietHoursEnd.toString().padLeft(2, '0')}:00',
            style: TextStyle(color: colors.primary),
          ),
          onTap: _saving
              ? null
              : () => _pickHour(
                    current: _draft.quietHoursEnd,
                    onSelected: (hour) =>
                        _persist(_draft.copyWith(quietHoursEnd: hour)),
                  ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            l10n.settingsMorningReminderHour,
            style: TextStyle(color: colors.textPrimary),
          ),
          trailing: Text(
            '${_draft.morningReminderHour.toString().padLeft(2, '0')}:00',
            style: TextStyle(color: colors.primary),
          ),
          onTap: _saving
              ? null
              : () => _pickHour(
                    current: _draft.morningReminderHour,
                    onSelected: (hour) =>
                        _persist(_draft.copyWith(morningReminderHour: hour)),
                  ),
        ),
        if (_saving) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(
            minHeight: 2,
            color: colors.primary,
            backgroundColor: colors.border,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_outlined, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.settingsNotificationsSection,
                    style: textTheme.titleLarge?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                ),
              ],
            ),
            Text(
              l10n.settingsRemindersSubtitle,
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                controller: widget.scrollController,
                child: _buildBody(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
