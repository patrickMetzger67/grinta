import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/coach_workload_analysis_access.dart';
import 'package:grinta/widget/account_create_profile_entry.dart';
import 'package:grinta/widget/settings_menu_style.dart';
import 'package:provider/provider.dart';

/// Web sidebar tile for coach workload analysis (Coach Pro gated).
class CoachWorkloadAnalysisSidebarEntry extends StatefulWidget {
  const CoachWorkloadAnalysisSidebarEntry({
    super.key,
    required this.collapsed,
    this.itemHeight = 48,
  });

  final bool collapsed;
  final double itemHeight;

  @override
  State<CoachWorkloadAnalysisSidebarEntry> createState() =>
      _CoachWorkloadAnalysisSidebarEntryState();
}

class _CoachWorkloadAnalysisSidebarEntryState
    extends State<CoachWorkloadAnalysisSidebarEntry> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hasManagedTeams =
        context.watch<AppSession>().hasManagedTeamsInSelectedSeason;
    if (!hasManagedTeams) return const SizedBox.shrink();

    final colors = context.appColors;
    final l10n = context.l10n;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => openCoachWorkloadAnalysis(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            height: widget.itemHeight,
            padding: EdgeInsets.symmetric(
              horizontal: widget.collapsed ? 0 : 14,
            ),
            decoration: BoxDecoration(
              color: _hovered ? colors.card : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: widget.collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                SubscriptionPremiumBadge.withIconOverlay(
                  context: context,
                  colors: colors,
                  showPremium: true,
                  icon: Icon(
                    Icons.insights_rounded,
                    size: kWebMenuIconSize,
                    color: colors.textSecondary,
                  ),
                ),
                if (!widget.collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.coachWorkloadAnalysisTitle,
                      overflow: TextOverflow.ellipsis,
                      style: webSidebarNavLabelStyle(
                        context,
                        selected: false,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
