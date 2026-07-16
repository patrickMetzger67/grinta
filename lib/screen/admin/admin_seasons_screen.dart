import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/season.dart';
import 'package:grinta/services/seasonService.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';

class AdminSeasonsScreen extends StatefulWidget {
  const AdminSeasonsScreen({super.key});

  @override
  State<AdminSeasonsScreen> createState() => _AdminSeasonsScreenState();
}

class _AdminSeasonsScreenState extends State<AdminSeasonsScreen> {
  final SeasonService _service = SeasonService();
  bool _sheetOpen = false;

  List<Season> _sortSeasons(List<Season> seasons) {
    final sorted = List<Season>.from(seasons);
    sorted.sort((a, b) {
      final aCurrent = a.isCurrent == true;
      final bCurrent = b.isCurrent == true;
      if (aCurrent != bCurrent) {
        return aCurrent ? -1 : 1;
      }
      final aStart = a.startDate?.millisecondsSinceEpoch ?? 0;
      final bStart = b.startDate?.millisecondsSinceEpoch ?? 0;
      return bStart.compareTo(aStart);
    });
    return sorted;
  }

  Future<void> _openFormSheet(
    BuildContext context, {
    Season? existing,
  }) async {
    setState(() => _sheetOpen = true);
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.appColors.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) => _SeasonFormSheet(
          existing: existing,
          service: _service,
          onSuccess: () {
            if (!mounted) return;
            AppSnackbar.show(
              context,
              existing == null
                  ? context.l10n.adminSeasonCreated
                  : context.l10n.adminSeasonUpdated,
            );
          },
        ),
      );
    } finally {
      if (mounted) setState(() => _sheetOpen = false);
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
          l10n.adminSeasonsTitle,
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.adminSeasonCreate,
        onPressed: _sheetOpen ? null : () => _openFormSheet(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Season>>(
        stream: _service.watchAllSeasons(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.adminSeasonsLoadError,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final seasons = _sortSeasons(snapshot.data ?? const <Season>[]);
          if (seasons.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.adminSeasonsEmpty,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            itemCount: seasons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final season = seasons[index];
              return _SeasonCard(
                season: season,
                onTap: () => _openFormSheet(context, existing: season),
              );
            },
          );
        },
      ),
    );
  }
}

class _SeasonCard extends StatelessWidget {
  const _SeasonCard({
    required this.season,
    required this.onTap,
  });

  final Season season;
  final VoidCallback onTap;

  String _formatDate(BuildContext context, Timestamp? timestamp) {
    if (timestamp == null) return '—';
    return MaterialLocalizations.of(context).formatShortDate(
      timestamp.toDate(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final isCurrent = season.isCurrent == true;
    final title = season.name?.trim().isNotEmpty == true
        ? season.name!.trim()
        : season.ref?.id ?? l10n.adminSeasonUnnamed;

    return Material(
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCurrent ? colors.primary.withValues(alpha: 0.45) : colors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                child: Icon(Icons.calendar_today_outlined, color: colors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              l10n.adminSeasonCurrentBadge,
                              style: textTheme.labelSmall?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.adminSeasonDateRange(
                        _formatDate(context, season.startDate),
                        _formatDate(context, season.endDate),
                      ),
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    if (season.clubName?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.adminSeasonClubLabel(season.clubName!.trim()),
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                    if (season.affiliateNumber?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.adminSeasonAffiliateLabel(
                          season.affiliateNumber!.trim(),
                        ),
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                    if (season.newVersion == true) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.adminSeasonNewVersionBadge,
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeasonFormSheet extends StatefulWidget {
  const _SeasonFormSheet({
    this.existing,
    required this.service,
    required this.onSuccess,
  });

  final Season? existing;
  final SeasonService service;
  final VoidCallback onSuccess;

  bool get isEdit => existing != null;

  @override
  State<_SeasonFormSheet> createState() => _SeasonFormSheetState();
}

class _SeasonFormSheetState extends State<_SeasonFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _clubNameController;
  late final TextEditingController _affiliateNumberController;

  DateTime? _startDate;
  DateTime? _endDate;
  late bool _isCurrent;
  late bool _newVersion;
  bool _busy = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _clubNameController = TextEditingController(text: existing?.clubName ?? '');
    _affiliateNumberController = TextEditingController(
      text: existing?.affiliateNumber ?? '',
    );
    _startDate = existing?.startDate?.toDate();
    _endDate = existing?.endDate?.toDate();
    _isCurrent = existing?.isCurrent ?? false;
    _newVersion = existing?.newVersion ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clubNameController.dispose();
    _affiliateNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isEdit = widget.isEdit;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isEdit ? l10n.adminSeasonEditTitle : l10n.adminSeasonCreate,
                  style: textTheme.titleLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  readOnly: isEdit,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.adminSeasonFieldName,
                    helperText: isEdit ? l10n.adminSeasonFieldNameReadOnly : null,
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return l10n.adminSeasonFieldRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pickDate(isStart: true),
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    _startDate == null
                        ? l10n.adminSeasonFieldStartDate
                        : l10n.adminSeasonDateSelected(
                            MaterialLocalizations.of(context).formatShortDate(
                              _startDate!,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pickDate(isStart: false),
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    _endDate == null
                        ? l10n.adminSeasonFieldEndDate
                        : l10n.adminSeasonDateSelected(
                            MaterialLocalizations.of(context).formatShortDate(
                              _endDate!,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _clubNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.adminSeasonFieldClubName,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _affiliateNumberController,
                  decoration: InputDecoration(
                    labelText: l10n.adminSeasonFieldAffiliateNumber,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.adminSeasonFieldCurrent,
                    style: textTheme.bodyLarge?.copyWith(color: colors.textPrimary),
                  ),
                  subtitle: Text(
                    l10n.adminSeasonFieldCurrentHint,
                    style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                  ),
                  value: _isCurrent,
                  onChanged: _busy ? null : (value) => setState(() => _isCurrent = value),
                  activeThumbColor: Colors.white,
                  activeTrackColor: colors.primary,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.adminSeasonFieldNewVersion,
                    style: textTheme.bodyLarge?.copyWith(color: colors.textPrimary),
                  ),
                  value: _newVersion,
                  onChanged: _busy ? null : (value) => setState(() => _newVersion = value),
                  activeThumbColor: Colors.white,
                  activeTrackColor: colors.primary,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colors.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.danger.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: colors.danger,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isEdit ? l10n.actionSave : l10n.adminSeasonCreate),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_startDate ?? now)
        : (_endDate ?? _startDate ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<bool> _confirmChangeDefault(Season currentSeason) async {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final currentName = currentSeason.name?.trim().isNotEmpty == true
        ? currentSeason.name!.trim()
        : currentSeason.ref?.id ?? l10n.adminSeasonUnnamed;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        title: Text(
          l10n.adminSeasonChangeDefaultTitle,
          style: textTheme.titleLarge?.copyWith(color: colors.textPrimary),
        ),
        content: Text(
          l10n.adminSeasonChangeDefaultMessage(currentName),
          style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.adminSeasonChangeDefaultConfirm),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      final existingId = widget.existing?.ref?.id;
      if (_isCurrent) {
        final current = await widget.service.getCurrentSeason();
        if (current != null && current.ref?.id != existingId) {
          final confirmed = await _confirmChangeDefault(current);
          if (!confirmed) {
            if (mounted) setState(() => _busy = false);
            return;
          }
        }
      }

      final season = Season(
        name: _nameController.text.trim(),
        startDate: _startDate == null ? null : Timestamp.fromDate(_startDate!),
        endDate: _endDate == null ? null : Timestamp.fromDate(_endDate!),
        isCurrent: _isCurrent,
        clubName: _clubNameController.text.trim(),
        affiliateNumber: _affiliateNumberController.text.trim(),
        newVersion: _newVersion,
      );

      late final String seasonId;
      if (widget.isEdit) {
        seasonId = existingId!;
        await widget.service.updateSeason(seasonId: seasonId, season: season);
      } else {
        seasonId = await widget.service.createSeason(season);
      }

      if (_isCurrent) {
        await widget.service.setOnlyOneCurrentSeason(seasonId);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = widget.isEdit
            ? context.l10n.adminSeasonUpdateFailed
            : context.l10n.adminSeasonCreateFailed;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
