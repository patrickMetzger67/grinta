import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

String unavailabilityTypeLabel(AppLocalizations l10n, UnavailabilityType type) {
  switch (type) {
    case UnavailabilityType.holiday:
      return l10n.unavailabilityTypeHoliday;
    case UnavailabilityType.unwell:
      return l10n.unavailabilityTypeUnwell;
    case UnavailabilityType.injured:
      return l10n.unavailabilityTypeInjured;
    case UnavailabilityType.other:
      return l10n.unavailabilityTypeOther;
  }
}

/// Shows the unavailability manager (bottom sheet on mobile, dialog on web).
Future<bool?> showManageUnavailabilitiesSheet(
  BuildContext context, {
  required Player player,
  required String? seasonId,
  required bool isManager,
  VoidCallback? onChanged,
}) {
  final Widget sheet = ManageUnavailabilitiesSheet(
    player: player,
    seasonId: seasonId,
    isManager: isManager,
    onChanged: onChanged,
  );

  if (kIsWeb) {
    return showDialog<bool>(
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
          child: sheet,
        ),
      ),
    );
  }

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useRootNavigator: true,
    backgroundColor: context.appColors.card,
    builder: (_) => sheet,
  );
}

class ManageUnavailabilitiesSheet extends StatefulWidget {
  const ManageUnavailabilitiesSheet({
    super.key,
    required this.player,
    required this.seasonId,
    required this.isManager,
    this.onChanged,
    this.embeddedInScreen = false,
    this.showCloseButton = true,
  });

  final Player player;
  final String? seasonId;
  final bool isManager;
  final VoidCallback? onChanged;
  final bool embeddedInScreen;
  final bool showCloseButton;

  @override
  State<ManageUnavailabilitiesSheet> createState() =>
      _ManageUnavailabilitiesSheetState();
}

class _ManageUnavailabilitiesSheetState extends State<ManageUnavailabilitiesSheet> {
  static const Uuid _uuid = Uuid();

  final PlayerService _playerService = PlayerService();
  bool _loading = true;
  List<Unavailability> _entries = const [];

  String? get _playerId {
    final fromKey = widget.player.keyMember?.trim();
    if (fromKey != null && fromKey.isNotEmpty) return fromKey;
    return widget.player.ref?.id;
  }

  String? get _resolvedSeasonId {
    final passed = widget.seasonId?.trim();
    if (passed != null && passed.isNotEmpty) return passed;
    return context.read<AppSession>().selectedSeason?.ref?.id;
  }

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _loading = true);

    final String? playerId = _playerId;
    final String? seasonId = _resolvedSeasonId;
    if (playerId == null || playerId.isEmpty || seasonId == null) {
      if (mounted) {
        setState(() {
          _entries = const [];
          _loading = false;
        });
      }
      return;
    }

    try {
      final Player? fresh = await _playerService.getPlayerById(playerId);
      if (!mounted) return;
      setState(() {
        _entries = _filteredEntries(
          fresh?.unavailabilitiesForSeason(seasonId) ?? const [],
        );
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _entries = _filteredEntries(
          widget.player.unavailabilitiesForSeason(seasonId),
        );
        _loading = false;
      });
    }
  }

  List<Unavailability> _filteredEntries(List<Unavailability> entries) {
    final visibleOnly = widget.isManager
        ? entries
        : entries.where((entry) => entry.isVisible ?? true);
    final sorted = visibleOnly.toList()
      ..sort((Unavailability a, Unavailability b) {
        final int aMs = a.from?.millisecondsSinceEpoch ?? 0;
        final int bMs = b.from?.millisecondsSinceEpoch ?? 0;
        return bMs.compareTo(aMs);
      });
    return sorted;
  }

  Future<void> _onAddPressed() async {
    if (!widget.isManager) return;
    final bool? saved = await _showFormSheet(context);
    if (saved == true) {
      await _loadEntries();
      widget.onChanged?.call();
    }
  }

  Future<void> _onEditPressed(Unavailability entry) async {
    if (!widget.isManager) return;
    final bool? saved = await _showFormSheet(context, existing: entry);
    if (saved == true) {
      await _loadEntries();
      widget.onChanged?.call();
    }
  }

  Future<void> _onDeletePressed(Unavailability entry) async {
    if (!widget.isManager) return;
    final l10n = context.l10n;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.manageUnavailabilitiesDeleteConfirmTitle),
        content: Text(l10n.manageUnavailabilitiesDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final String? playerId = _playerId;
    final String? entryId = entry.id?.trim();
    if (playerId == null || entryId == null || entryId.isEmpty) return;

    try {
      await _playerService.removeUnavailability(
        playerId: playerId,
        unavailabilityId: entryId,
      );
      if (!mounted) return;
      await _loadEntries();
      widget.onChanged?.call();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final BuildContext? rootContext = appNavigatorKey.currentContext;
        if (rootContext != null && rootContext.mounted) {
          AppSnackbar.show(rootContext, l10n.manageUnavailabilitiesDeleted);
        }
      });
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        l10n.manageUnavailabilitiesDeleteError,
        isError: true,
      );
    }
  }

  Future<bool?> _showFormSheet(
    BuildContext context, {
    Unavailability? existing,
  }) {
    final Widget form = _UnavailabilityFormSheet(
      playerId: _playerId!,
      seasonId: _resolvedSeasonId!,
      existing: existing,
      onSubmit: _saveEntry,
    );

    if (kIsWeb) {
      return showDialog<bool>(
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: form,
          ),
        ),
      );
    }

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useRootNavigator: true,
      backgroundColor: context.appColors.card,
      builder: (_) => form,
    );
  }

  Future<bool> _saveEntry(Unavailability entry, {required bool isEdit}) async {
    final String? playerId = _playerId;
    final String? seasonId = _resolvedSeasonId;
    if (playerId == null || seasonId == null) return false;

    entry.seasonId = seasonId;

    if (isEdit) {
      final Player? player = await _playerService.getPlayerById(playerId);
      if (player == null) return false;

      final List<Unavailability> seasonEntries =
          List<Unavailability>.from(player.unavailabilitiesForSeason(seasonId));
      final int index =
          seasonEntries.indexWhere((item) => item.id == entry.id);
      if (index < 0) return false;
      seasonEntries[index] = entry;
      player.unavailableMap[seasonId] = seasonEntries;

      await _playerService.updateUnavailabilityMap(
        playerId: playerId,
        unavailableMap: player.unavailableMap,
      );
      return true;
    }

    entry.id ??= _uuid.v4();
    await _playerService.addUnavailability(
      playerId: playerId,
      unavailability: entry,
    );
    return true;
  }

  String _formatDateRange(BuildContext context, Unavailability entry) {
    final locale = context.l10n.localeName;
    final from = entry.from?.toDate();
    final to = entry.to?.toDate();
    if (from == null || to == null) return '-';
    final fromLabel = DateFormat.yMMMd(locale).format(from);
    final toLabel = DateFormat.yMMMd(locale).format(to);
    return context.l10n.manageUnavailabilitiesDateRange(fromLabel, toLabel);
  }

  void _close() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  Widget _buildEntryTile(
    BuildContext context, {
    required Unavailability entry,
    required ThemeData theme,
    required AppColors colors,
    required AppLocalizations l10n,
  }) {
    final type = entry.unavailabilityType;
    final typeLabel =
        type == null ? '-' : unavailabilityTypeLabel(l10n, type);
    final isHidden = entry.isVisible == false;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.isManager ? () => _onEditPressed(entry) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateRange(context, entry),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    if (entry.details?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        entry.details!.trim(),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    if (isHidden && widget.isManager) ...[
                      const SizedBox(height: 6),
                      Text(
                        l10n.manageUnavailabilitiesHidden,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.isManager) ...[
                IconButton(
                  tooltip: l10n.actionEditPlayer,
                  icon: Icon(
                    Icons.edit_outlined,
                    color: colors.primary,
                  ),
                  onPressed: () => _onEditPressed(entry),
                ),
                IconButton(
                  tooltip: l10n.actionDelete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: colors.danger,
                  ),
                  onPressed: () => _onDeletePressed(entry),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntriesList(
    BuildContext context, {
    required ThemeData theme,
    required AppColors colors,
    required AppLocalizations l10n,
  }) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_entries.isEmpty) {
      return Center(
        child: Text(
          l10n.manageUnavailabilitiesEmpty,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildEntryTile(
        context,
        entry: _entries[index],
        theme: theme,
        colors: colors,
        l10n: l10n,
      ),
    );
  }

  Widget? _buildFab(AppLocalizations l10n) {
    if (!widget.isManager) return null;
    return FloatingActionButton(
      onPressed:
          _playerId == null || _resolvedSeasonId == null ? null : _onAddPressed,
      tooltip: l10n.manageUnavailabilitiesAdd,
      child: const Icon(Icons.add_rounded),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final String playerName =
        '${widget.player.firstName ?? ''} ${widget.player.lastName ?? ''}'
            .trim();
    final double listHeight = kIsWeb
        ? 360
        : MediaQuery.sizeOf(context).height * 0.55;
    final fab = _buildFab(l10n);

    if (widget.embeddedInScreen) {
      return Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              widget.isManager ? 88 : 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (playerName.isNotEmpty)
                  Text(
                    playerName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                if (playerName.isNotEmpty) const SizedBox(height: 12),
                Expanded(
                  child: _buildEntriesList(
                    context,
                    theme: theme,
                    colors: colors,
                    l10n: l10n,
                  ),
                ),
              ],
            ),
          ),
          if (fab != null)
            Positioned(
              right: 20,
              bottom: 20,
              child: fab,
            ),
        ],
      );
    }

    return SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              widget.isManager ? 72 : 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.manageUnavailabilitiesTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (widget.showCloseButton)
                      IconButton(
                        onPressed: _close,
                        icon: const Icon(Icons.close_rounded),
                        tooltip: l10n.actionClose,
                      ),
                  ],
                ),
                if (playerName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    playerName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  height: listHeight,
                  child: _buildEntriesList(
                    context,
                    theme: theme,
                    colors: colors,
                    l10n: l10n,
                  ),
                ),
              ],
            ),
          ),
          if (fab != null)
            Positioned(
              right: 20,
              bottom: 20,
              child: fab,
            ),
        ],
      ),
    );
  }
}

class _UnavailabilityFormSheet extends StatefulWidget {
  const _UnavailabilityFormSheet({
    required this.playerId,
    required this.seasonId,
    required this.onSubmit,
    this.existing,
  });

  final String playerId;
  final String seasonId;
  final Unavailability? existing;
  final Future<bool> Function(Unavailability entry, {required bool isEdit})
      onSubmit;

  bool get isEditMode => existing != null;

  @override
  State<_UnavailabilityFormSheet> createState() =>
      _UnavailabilityFormSheetState();
}

class _UnavailabilityFormSheetState extends State<_UnavailabilityFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late DateTime _fromDate;
  late DateTime _toDate;
  UnavailabilityType? _type;
  late TextEditingController _detailsController;
  bool _isVisible = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final DateTime now = DateUtils.dateOnly(DateTime.now());
    if (existing != null) {
      _fromDate = DateUtils.dateOnly(existing.from?.toDate() ?? now);
      _toDate = DateUtils.dateOnly(existing.to?.toDate() ?? now);
      _type = existing.unavailabilityType;
      _isVisible = existing.isVisible ?? true;
      _detailsController =
          TextEditingController(text: existing.details?.trim() ?? '');
    } else {
      _fromDate = now;
      _toDate = now;
      _type = UnavailabilityType.holiday;
      _detailsController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Timestamp _fromTimestamp(DateTime date) =>
      Timestamp.fromDate(DateUtils.dateOnly(date));

  Timestamp _toTimestamp(DateTime date) {
    final day = DateUtils.dateOnly(date);
    return Timestamp.fromDate(
      DateTime(day.year, day.month, day.day, 23, 59, 59, 999),
    );
  }

  Future<void> _pickFromDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: context.l10n.manageUnavailabilitiesFromDate,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _fromDate = DateUtils.dateOnly(picked);
      if (_toDate.isBefore(_fromDate)) {
        _toDate = _fromDate;
      }
    });
  }

  Future<void> _pickToDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _toDate.isBefore(_fromDate) ? _fromDate : _toDate,
      firstDate: _fromDate,
      lastDate: DateTime(2100),
      helpText: context.l10n.manageUnavailabilitiesToDate,
    );
    if (picked == null || !mounted) return;
    setState(() => _toDate = DateUtils.dateOnly(picked));
  }

  void _closeWithoutSaving() {
    Navigator.of(context, rootNavigator: true).pop(false);
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;
    if (_toDate.isBefore(_fromDate)) {
      AppSnackbar.show(
        context,
        l10n.manageUnavailabilitiesInvalidRange,
        isError: true,
      );
      return;
    }

    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    final String successMessage = l10n.manageUnavailabilitiesSaved;
    final String errorMessage = l10n.manageUnavailabilitiesError;

    setState(() => _isSubmitting = true);

    var didPop = false;
    try {
      final entry = Unavailability(
        id: widget.existing?.id,
        from: _fromTimestamp(_fromDate),
        to: _toTimestamp(_toDate),
        unavailabilityType: _type,
        details: _detailsController.text.trim(),
        isVisible: _isVisible,
        seasonId: widget.seasonId,
      );

      final saved = await widget.onSubmit(
        entry,
        isEdit: widget.isEditMode,
      );
      if (!mounted) return;
      if (saved) {
        navigator.pop(true);
        didPop = true;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final BuildContext? rootContext = appNavigatorKey.currentContext;
          if (rootContext != null && rootContext.mounted) {
            AppSnackbar.show(rootContext, successMessage, isError: false);
          }
        });
      } else {
        AppSnackbar.show(context, errorMessage, isError: true);
      }
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(context, errorMessage, isError: true);
    } finally {
      if (mounted && !didPop) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = l10n.localeName;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.isEditMode
                      ? l10n.manageUnavailabilitiesEditTitle
                      : l10n.manageUnavailabilitiesAdd,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.manageUnavailabilitiesFromDate),
                  subtitle: Text(DateFormat.yMMMd(locale).format(_fromDate)),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: _pickFromDate,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.manageUnavailabilitiesToDate),
                  subtitle: Text(DateFormat.yMMMd(locale).format(_toDate)),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: _pickToDate,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<UnavailabilityType>(
                  value: _type,
                  decoration: InputDecoration(
                    labelText: l10n.manageUnavailabilitiesType,
                    border: const OutlineInputBorder(),
                  ),
                  items: UnavailabilityType.values
                      .map(
                        (type) => DropdownMenuItem<UnavailabilityType>(
                          value: type,
                          child: Text(unavailabilityTypeLabel(l10n, type)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _type = value),
                  validator: (value) =>
                      value == null ? l10n.manageUnavailabilitiesTypeRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _detailsController,
                  decoration: InputDecoration(
                    labelText: l10n.manageUnavailabilitiesDetails,
                    hintText: l10n.manageUnavailabilitiesDetailsHint,
                    border: const OutlineInputBorder(),
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.manageUnavailabilitiesVisible),
                  subtitle: Text(l10n.manageUnavailabilitiesVisibleHint),
                  value: _isVisible,
                  onChanged: (value) => setState(() => _isVisible = value),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : _closeWithoutSaving,
                        child: Text(l10n.actionCancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(l10n.actionSave),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
