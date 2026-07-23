import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/tracker_field.dart';
import 'package:grinta/services/tracker_field_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/field_gps_localization_helper.dart';

/// Admin entry point to map / edit pitch GPS corners (`TRACKER_Fields`).
class AdminTrackerFieldsScreen extends StatefulWidget {
  const AdminTrackerFieldsScreen({super.key});

  @override
  State<AdminTrackerFieldsScreen> createState() =>
      _AdminTrackerFieldsScreenState();
}

class _AdminTrackerFieldsScreenState extends State<AdminTrackerFieldsScreen> {
  final _service = TrackerFieldService();
  late Future<List<TrackerField>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.listAll();
  }

  void _reload() {
    setState(() => _future = _service.listAll());
  }

  Future<void> _openLocalization({
    TrackerField? existing,
  }) async {
    final result = await FieldGpsLocalizationHelper.openLocalizationScreen(
      context,
      initialName: existing?.terrainNom ?? '',
      initialAddress: existing == null
          ? ''
          : [
              if (existing.adresse.trim().isNotEmpty) existing.adresse.trim(),
              if (existing.ville.trim().isNotEmpty) existing.ville.trim(),
            ].join(', '),
    );
    if (result == null || !mounted) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      AppSnackbar.show(context, context.l10n.adminTrackerFieldsAuthRequired);
      return;
    }

    try {
      await FieldGpsLocalizationHelper.saveLocalizationResult(
        result: result,
        uid: uid,
        trackerFieldService: _service,
      );
      if (!mounted) return;
      AppSnackbar.show(
        context,
        context.l10n.adminTrackerFieldsSaved,
        isError: false,
      );
      _reload();
    } catch (e, st) {
      debugPrint('admin tracker field save failed: $e\n$st');
      if (!mounted) return;
      AppSnackbar.show(context, context.l10n.adminTrackerFieldsSaveFailed);
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
          l10n.adminTrackerFieldsTitle,
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openLocalization(),
        icon: const Icon(Icons.map_outlined),
        label: Text(l10n.adminTrackerFieldsCreate),
      ),
      body: FutureBuilder<List<TrackerField>>(
        future: _future,
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

          final fields = snapshot.data ?? const <TrackerField>[];
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: fields.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final field = fields[index];
              final subtitle = [
                if (field.adresse.trim().isNotEmpty) field.adresse.trim(),
                if (field.ville.trim().isNotEmpty) field.ville.trim(),
                field.id,
              ].join(' · ');
              return Material(
                color: colors.card,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: colors.border),
                  ),
                  leading: Icon(Icons.stadium_outlined, color: colors.primary),
                  title: Text(
                    field.terrainNom.trim().isNotEmpty
                        ? field.terrainNom
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
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textSecondary,
                  ),
                  onTap: () => _openLocalization(existing: field),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
