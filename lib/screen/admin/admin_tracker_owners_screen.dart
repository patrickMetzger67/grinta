import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/tracker_owner.dart';
import 'package:grinta/screen/admin/admin_tracker_owner_edit_screen.dart';
import 'package:grinta/services/tracker_owner_service.dart';
import 'package:grinta/util/app_theme.dart';

class AdminTrackerOwnersScreen extends StatelessWidget {
  const AdminTrackerOwnersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.adminTrackerOwnersTitle,
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.adminTrackerOwnerCreate,
        onPressed: () => _openEditor(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<TrackerOwner>>(
        stream: TrackerOwnerService.instance.watchOwners(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.adminTrackerOwnersLoadError,
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

          final owners = snapshot.data ?? const <TrackerOwner>[];
          if (owners.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.adminTrackerOwnersEmpty,
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
            itemCount: owners.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final owner = owners[index];
              return _TrackerOwnerCard(
                owner: owner,
                onTap: () => _openEditor(context, existing: owner),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context, {
    TrackerOwner? existing,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminTrackerOwnerEditScreen(owner: existing),
      ),
    );
  }

}

class _TrackerOwnerCard extends StatelessWidget {
  const _TrackerOwnerCard({
    required this.owner,
    required this.onTap,
  });

  final TrackerOwner owner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final statusColor = owner.isActive ? colors.success : colors.textSecondary;

    return Material(
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.gps_fixed, color: colors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owner.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (owner.email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        owner.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (owner.typeTracker.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              l10n.adminTrackerOwnerTypeLabel(
                                owner.typeTracker,
                              ),
                              style: textTheme.labelSmall?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          owner.isActive
                              ? l10n.adminTrackerOwnerStatusActive
                              : l10n.adminTrackerOwnerStatusInactive,
                          style: textTheme.labelMedium?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
