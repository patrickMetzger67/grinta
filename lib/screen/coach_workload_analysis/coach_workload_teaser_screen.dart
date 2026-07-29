import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/services/subscription_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/team_tracker_access.dart';
import 'package:grinta/widget/account_create_profile_entry.dart';
import 'package:grinta/widget/subscription_paywall.dart';

/// Frozen preview of coach workload analysis for non–Coach Pro users.
class CoachWorkloadTeaserScreen extends StatelessWidget {
  const CoachWorkloadTeaserScreen({super.key});

  Future<void> _openPaywall(BuildContext context) async {
    final subscription = SubscriptionService.instance;
    await subscription.refreshForActiveSession();
    if (!context.mounted) return;

    if (TeamTrackerAccess.hasCoachProTrackerAccess()) {
      Navigator.of(context).pop();
      return;
    }

    final hasPaidCoachSubscription =
        subscription.hasActivePaidSubscription && subscription.coachTier != null;

    await SubscriptionPaywall.show(
      context,
      changePlanMode: hasPaidCoachSubscription,
      initialKind: SubscriptionOfferingKind.coach,
    );

    await subscription.refreshForActiveSession();
    if (!context.mounted) return;
    if (TeamTrackerAccess.hasCoachProTrackerAccess()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        title: Row(
          children: [
            Expanded(
              child: Text(
                l10n.coachWorkloadAnalysisTitle,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SubscriptionPremiumBadge(colors: colors, compact: true),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                IgnorePointer(
                  child: Opacity(
                    opacity: 0.5,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        _FakePeriodBar(colors: colors),
                        const SizedBox(height: 14),
                        for (var i = 0; i < 5; i++) ...[
                          _FakePlayerCard(colors: colors, index: i),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colors.background.withValues(alpha: 0.15),
                          colors.background.withValues(alpha: 0.92),
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.border),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.10),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.insights_rounded,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.coachWorkloadTeaserHeadline,
                                  style: textTheme.titleMedium?.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.coachWorkloadTeaserBody,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => _openPaywall(context),
                              style: FilledButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(l10n.coachWorkloadTeaserCta),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FakePeriodBar extends StatelessWidget {
  const _FakePeriodBar({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final label in ['7j', '30j', 'Perso']) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: label == '30j' ? colors.primary : colors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: label == '30j' ? colors.primary : colors.border,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: label == '30j' ? Colors.white : colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _FakePlayerCard extends StatelessWidget {
  const _FakePlayerCard({required this.colors, required this.index});
  final AppColors colors;
  final int index;

  @override
  Widget build(BuildContext context) {
    final names = ['Martin L.', 'Dupont A.', 'Bernard C.', 'Petit M.', 'Moreau J.'];
    final sessions = [12, 10, 9, 8, 7];
    final loads = [78, 71, 65, 58, 52];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colors.primary.withValues(alpha: 0.18),
            child: Icon(Icons.person, color: colors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  names[index % names.length],
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _chip(colors, '${sessions[index]} séances'),
                    const SizedBox(width: 6),
                    _chip(colors, 'Charge ${loads[index]}'),
                    const SizedBox(width: 6),
                    _chip(colors, '92%'),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
        ],
      ),
    );
  }

  Widget _chip(AppColors colors, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
