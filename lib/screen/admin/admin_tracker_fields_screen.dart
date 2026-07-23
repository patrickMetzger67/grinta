import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/club.dart';
import 'package:grinta/model/field_club.dart';
import 'package:grinta/services/field_club_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/field_gps_localization_helper.dart';
import 'package:grinta/widget/club_picker_sheet.dart';

/// Admin entry point to map / edit pitch GPS corners (`fieldClub`).
class AdminTrackerFieldsScreen extends StatefulWidget {
  const AdminTrackerFieldsScreen({super.key});

  @override
  State<AdminTrackerFieldsScreen> createState() =>
      _AdminTrackerFieldsScreenState();
}

class _AdminTrackerFieldsScreenState extends State<AdminTrackerFieldsScreen> {
  final _service = FieldClubService();

  Club? _selectedClub;
  Future<List<FieldClub>>? _fieldsFuture;

  String? get _selectedClubId {
    final id = _selectedClub?.affiliation?.trim();
    if (id == null || id.isEmpty) return null;
    return id;
  }

  Future<void> _pickClub() async {
    final club = await showClubPickerSheet(context);
    if (club == null || !mounted) return;

    final clubId = club.affiliation?.trim();
    if (clubId == null || clubId.isEmpty) return;

    setState(() {
      _selectedClub = club;
      _fieldsFuture = _service.listByClubId(clubId);
    });
  }

  void _reload() {
    final clubId = _selectedClubId;
    if (clubId == null) return;
    setState(() {
      _fieldsFuture = _service.listByClubId(clubId);
    });
  }

  void _clearSelectedClub() {
    setState(() {
      _selectedClub = null;
      _fieldsFuture = null;
    });
  }

  /// Field list → club selection. Club selection → admin menu.
  void _handleBack() {
    if (_selectedClubId != null) {
      _clearSelectedClub();
      return;
    }
    Navigator.of(context).maybePop();
  }

  Future<void> _openLocalization({FieldClub? existing}) async {
    final clubId = _selectedClubId;
    if (clubId == null) {
      await _pickClub();
      return;
    }

    final result = await FieldGpsLocalizationHelper.openLocalizationScreen(
      context,
      initialName: existing?.name ?? '',
      initialAddress: existing?.address ?? '',
    );
    if (result == null || !mounted) return;

    if (FirebaseAuth.instance.currentUser == null) {
      AppSnackbar.show(context, context.l10n.adminTrackerFieldsAuthRequired);
      return;
    }

    final name = result.fieldName.trim().isNotEmpty
        ? result.fieldName.trim()
        : (existing?.name.trim().isNotEmpty == true
            ? existing!.name.trim()
            : result.fieldAddress.trim());
    final address = result.fieldAddress.trim().isNotEmpty
        ? result.fieldAddress.trim()
        : (existing?.address ?? '');

    try {
      await FieldGpsLocalizationHelper.saveLocalizationResultToFieldClub(
        result: result,
        clubId: clubId,
        existing: existing,
        name: name,
        address: address,
        fieldClubService: _service,
      );
      if (!mounted) return;
      AppSnackbar.show(
        context,
        context.l10n.adminTrackerFieldsSaved,
        isError: false,
      );
      _reload();
    } catch (e, st) {
      debugPrint('admin fieldClub save failed: $e\n$st');
      if (!mounted) return;
      AppSnackbar.show(context, context.l10n.adminTrackerFieldsSaveFailed);
    }
  }

  Future<void> _confirmAndDelete(FieldClub field) async {
    final l10n = context.l10n;
    final colors = context.appColors;
    final fieldName = field.name.trim().isNotEmpty ? field.name.trim() : field.id;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.adminTrackerFieldsDeleteConfirmTitle),
        content: Text(l10n.adminTrackerFieldsDeleteConfirmMessage(fieldName)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.actionDelete,
              style: TextStyle(
                color: colors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _service.delete(field.id);
      if (!mounted) return;
      AppSnackbar.show(
        context,
        l10n.adminTrackerFieldsDeleted,
        isError: false,
      );
      _reload();
    } catch (e, st) {
      debugPrint('admin fieldClub delete failed: $e\n$st');
      if (!mounted) return;
      AppSnackbar.show(context, l10n.adminTrackerFieldsDeleteFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final clubSelected = _selectedClubId != null;

    return PopScope(
      canPop: !clubSelected,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_selectedClubId != null) {
          _clearSelectedClub();
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          leading: IconButton(
            tooltip: l10n.actionBack,
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _handleBack,
          ),
          title: Text(
            l10n.adminTrackerFieldsTitle,
            style: textTheme.titleLarge?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            if (clubSelected)
              TextButton(
                onPressed: _pickClub,
                child: Text(l10n.adminTrackerFieldsChangeClub),
              ),
          ],
        ),
        floatingActionButton: clubSelected
            ? FloatingActionButton.extended(
                onPressed: () => _openLocalization(),
                icon: const Icon(Icons.map_outlined),
                label: Text(l10n.adminTrackerFieldsCreate),
              )
            : null,
        body: !clubSelected
            ? _ClubSelectionPrompt(onSelectClub: _pickClub)
            : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: InkWell(
                    onTap: _pickClub,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: l10n.teamCreationSelectClub,
                        suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                      ),
                      child: Row(
                        children: [
                          ClubLogo(url: _selectedClub?.logo ?? ''),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedClub?.name?.trim().isNotEmpty == true
                                  ? _selectedClub!.name!.trim()
                                  : _selectedClubId!,
                              style: textTheme.bodyLarge?.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<FieldClub>>(
                    future: _fieldsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.adminTrackerFieldsLoadError,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: colors.textSecondary),
                                ),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: _reload,
                                  child: Text(l10n.actionRetry),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final fields = snapshot.data ?? const <FieldClub>[];
                      if (fields.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              l10n.adminTrackerFieldsEmpty,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colors.textSecondary),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: fields.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final field = fields[index];
                          final subtitle = [
                            if (field.address.trim().isNotEmpty)
                              field.address.trim(),
                            if (field.surface?.trim().isNotEmpty == true)
                              field.surface!.trim(),
                            if (field.hasFieldGpsCorners)
                              l10n.adminTrackerFieldsGpsReady
                            else
                              l10n.adminTrackerFieldsGpsMissing,
                          ].join(' · ');
                          return Material(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(14),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: colors.border),
                              ),
                              leading: Icon(
                                field.hasFieldGpsCorners
                                    ? Icons.gps_fixed
                                    : Icons.gps_not_fixed,
                                color: field.hasFieldGpsCorners
                                    ? colors.primary
                                    : colors.textSecondary,
                              ),
                              title: Text(
                                field.name.trim().isNotEmpty
                                    ? field.name
                                    : field.id,
                                style: textTheme.titleSmall?.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                subtitle,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: l10n.actionDelete,
                                    onPressed: () => _confirmAndDelete(field),
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      color: colors.danger,
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: colors.textSecondary,
                                  ),
                                ],
                              ),
                              onTap: () => _openLocalization(existing: field),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

class _ClubSelectionPrompt extends StatelessWidget {
  const _ClubSelectionPrompt({required this.onSelectClub});

  final VoidCallback onSelectClub;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, size: 48, color: colors.textSecondary),
            const SizedBox(height: 16),
            Text(
              l10n.adminTrackerFieldsSelectClubFirst,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onSelectClub,
              icon: const Icon(Icons.search),
              label: Text(l10n.teamCreationSelectClub),
            ),
          ],
        ),
      ),
    );
  }
}
