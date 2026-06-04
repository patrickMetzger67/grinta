import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_features.dart';
import 'package:grinta/analytics/analytics_interactions.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/match.dart' as grinta_match;
import 'package:grinta/model/team.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/ownerService.dart';
import 'package:grinta/services/teamService.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/match_compo_pitch_mapper.dart';
import 'package:provider/provider.dart';

typedef TrackerKitStatusChanged = void Function({
  required bool withTracker,
  String? ownerId,
});

void showTrackerKitDialog(
  BuildContext context, {
  String? matchId,
  bool initialWithTracker = false,
  String? initialOwnerId,
  List<TeamOwnerRef> teamOwners = const [],
  TrackerKitStatusChanged? onStatusChanged,
}) {
  AnalyticsInteractions.logFeature(AnalyticsFeatures.trackerKitTap);

  if (matchId == null || matchId.trim().isEmpty) {
    _showTrackerKitComingSoonDialog(context);
    return;
  }

  showDialog<void>(
    context: context,
    builder: (ctx) => _TrackerKitSelectionDialog(
      matchId: matchId.trim(),
      initialWithTracker: initialWithTracker,
      initialOwnerId: _normalizeOwnerId(initialOwnerId),
      teamOwners: teamOwners,
      onStatusChanged: onStatusChanged,
    ),
  );
}

void _showTrackerKitComingSoonDialog(BuildContext context) {
  final colors = context.appColors;
  final l10n = context.l10n;

  showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.border),
        ),
        title: Text(
          l10n.matchDetailTrackerKitTitle,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          l10n.matchDetailTrackerKitComingSoon,
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.actionClose),
          ),
        ],
      );
    },
  );
}

String? _normalizeOwnerId(String? ownerId) {
  final trimmed = ownerId?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

class _TrackerKitSelectionDialog extends StatefulWidget {
  final String matchId;
  final bool initialWithTracker;
  final String? initialOwnerId;
  final List<TeamOwnerRef> teamOwners;
  final TrackerKitStatusChanged? onStatusChanged;

  const _TrackerKitSelectionDialog({
    required this.matchId,
    required this.initialWithTracker,
    this.initialOwnerId,
    required this.teamOwners,
    this.onStatusChanged,
  });

  @override
  State<_TrackerKitSelectionDialog> createState() =>
      _TrackerKitSelectionDialogState();
}

class _TrackerKitSelectionDialogState extends State<_TrackerKitSelectionDialog> {
  late bool _withTracker;
  String? _selectedOwnerId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _withTracker = widget.initialWithTracker;
    _selectedOwnerId = _resolveInitialOwnerId();
  }

  String? _resolveInitialOwnerId() {
    final initialId = widget.initialOwnerId;
    if (initialId != null) {
      for (final owner in widget.teamOwners) {
        if (owner.id == initialId) {
          return owner.id;
        }
      }
    } else if (widget.teamOwners.length == 1) {
      return widget.teamOwners.first.id;
    }
    return null;
  }

  bool get _canConfirm {
    if (!_withTracker) return true;
    final id = _selectedOwnerId;
    return id != null && id.isNotEmpty;
  }

  Future<void> _confirm() async {
    if (!_canConfirm || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      if (_withTracker) {
        final ownerId = _selectedOwnerId!;
        await MatchService().updateTrackerStatus(
          matchId: widget.matchId,
          ownerId: ownerId,
          withTracker: true,
          isTrackerDataUploaded: false,
        );
        widget.onStatusChanged?.call(
          withTracker: true,
          ownerId: ownerId,
        );
      } else {
        await MatchService().updateTrackerStatus(
          matchId: widget.matchId,
          withTracker: false,
          isTrackerDataUploaded: false,
          clearOwnerId: true,
        );
        widget.onStatusChanged?.call(
          withTracker: false,
          ownerId: null,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.unexpectedError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildOwnerDropdown(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final owners = widget.teamOwners;

    if (owners.isEmpty) {
      return Text(
        l10n.matchDetailTrackerKitNoOwners,
        style: TextStyle(color: colors.textSecondary),
      );
    }

    return InputDecorator(
      decoration: InputDecoration(
        labelText: l10n.matchDetailTrackerKitSelectLabel,
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedOwnerId,
          hint: Text(
            l10n.matchDetailTrackerKitSelectLabel,
            style: TextStyle(color: colors.textSecondary),
          ),
          items: [
            for (final owner in owners)
              DropdownMenuItem<String>(
                value: owner.id,
                child: Text(
                  owner.displayLabel,
                  style: TextStyle(color: colors.textPrimary),
                ),
              ),
          ],
          selectedItemBuilder: (context) => [
            for (final owner in owners)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  owner.displayLabel,
                  style: TextStyle(color: colors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: _isSaving
              ? null
              : (ownerId) {
                  setState(() {
                    _selectedOwnerId = _normalizeOwnerId(ownerId);
                  });
                },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return AlertDialog(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.border),
      ),
      title: Text(
        l10n.matchDetailTrackerKitTitle,
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RadioListTile<bool>(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.matchDetailTrackerKitWithTracker,
              style: TextStyle(color: colors.textPrimary),
            ),
            value: true,
            groupValue: _withTracker,
            onChanged: _isSaving
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() => _withTracker = value);
                  },
          ),
          if (_withTracker) ...[
            const SizedBox(height: 4),
            _buildOwnerDropdown(context),
          ],
          RadioListTile<bool>(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.matchDetailTrackerKitWithoutTracker,
              style: TextStyle(color: colors.textPrimary),
            ),
            value: false,
            groupValue: _withTracker,
            onChanged: _isSaving
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() => _withTracker = value);
                  },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        TextButton(
          onPressed: _isSaving || !_canConfirm ? null : _confirm,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.actionValidate),
        ),
      ],
    );
  }
}

/// Visual treatment for [TextPillButton].
enum TextPillStyle {
  /// Tinted fill on neutral backgrounds (e.g. match detail header).
  tinted,

  /// Opaque surface pill with status-colored text on colored cards.
  onColoredBackground,
}

/// Compact tappable text control for tracker kit status.
class TextPillButton extends StatelessWidget {
  static const double _radius = 13;
  static const double _fontSize = 12.5;
  static const EdgeInsets _padding =
      EdgeInsets.symmetric(horizontal: 10, vertical: 6);

  final String label;
  final Color color;
  final VoidCallback? onTap;
  final TextPillStyle style;

  const TextPillButton({
    super.key,
    required this.label,
    required this.color,
    this.onTap,
    this.style = TextPillStyle.tinted,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    final borderRadius = BorderRadius.circular(_radius);
    final colors = context.appColors;

    final Color backgroundColor;
    final Color borderColor;
    final Color textColor;
    final Color splashColor;
    final Color highlightColor;

    switch (style) {
      case TextPillStyle.tinted:
        backgroundColor = color.withValues(alpha: 0.14);
        borderColor = color.withValues(alpha: 0.5);
        textColor = color;
        splashColor = color.withValues(alpha: 0.22);
        highlightColor = color.withValues(alpha: 0.1);
      case TextPillStyle.onColoredBackground:
        backgroundColor = colors.surface;
        borderColor = color;
        textColor = color;
        splashColor = color.withValues(alpha: 0.18);
        highlightColor = color.withValues(alpha: 0.08);
    }

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          splashColor: splashColor,
          highlightColor: highlightColor,
          child: Padding(
            padding: _padding,
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: _fontSize,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Where the tracker kit pill is shown; drives contrast styling.
enum TrackerKitPillVariant {
  /// Neutral header (tinted pill).
  header,

  /// Agenda card on a type-colored background.
  agendaCard,
}

/// Match is linked to at least one Grinta team document id.
bool trackerKitHasTeamContext(grinta_match.Match match) {
  if ((match.teamID?.trim() ?? '').isNotEmpty) return true;
  for (final raw in match.teams ?? const <dynamic>[]) {
    if ((raw?.toString().trim() ?? '').isNotEmpty) return true;
  }
  return false;
}

/// Candidate team ids for tracker owners (managed linked teams first).
List<String> trackerKitTeamIdCandidates(
  grinta_match.Match match,
  List<String> managedTeamIds,
) {
  final ids = <String>[];
  void add(String? raw) {
    final id = raw?.trim() ?? '';
    if (id.isNotEmpty && !ids.contains(id)) ids.add(id);
  }

  for (final raw in match.teams ?? <dynamic>[]) {
    final id = raw?.toString().trim() ?? '';
    if (id.isNotEmpty && managedTeamIds.contains(id)) add(id);
  }
  add(match.teamID);
  add(resolveTeamIdForMatch(match, managedTeamIds: managedTeamIds));
  for (final raw in match.teams ?? <dynamic>[]) {
    add(raw?.toString());
  }
  return ids;
}

Future<List<TeamOwnerRef>> fetchTrackerKitTeamOwners({
  required grinta_match.Match match,
  required List<String> managedTeamIds,
}) async {
  final candidateIds = trackerKitTeamIdCandidates(match, managedTeamIds);
  if (candidateIds.isEmpty) return const [];

  try {
    for (final teamId in candidateIds) {
      final team = await TeamService().getTeamById(teamId);
      if (team == null || !team.hasAnyTrackerOwners) continue;
      var refs = team.ownerRefs;
      if (refs.isEmpty) continue;
      try {
        refs = await OwnerService().enrichTeamOwnerRefs(refs);
      } catch (_) {}
      return refs;
    }
  } catch (_) {}
  return const [];
}

bool _trackerKitMatchTeamsEqual(List<dynamic>? a, List<dynamic>? b) {
  final la = a ?? const <dynamic>[];
  final lb = b ?? const <dynamic>[];
  if (la.length != lb.length) return false;
  for (var i = 0; i < la.length; i++) {
    if (la[i]?.toString() != lb[i]?.toString()) return false;
  }
  return true;
}

/// Loads team owners and opens [showTrackerKitDialog] for a match-linked pill.
class MatchTrackerKitPillHost extends StatefulWidget {
  final grinta_match.Match match;
  final bool isManager;
  final TrackerKitPillVariant variant;

  /// When true, non-managers still see a read-only pill if the match uses trackers.
  final bool showForNonManagerWithTracker;

  const MatchTrackerKitPillHost({
    super.key,
    required this.match,
    required this.isManager,
    this.variant = TrackerKitPillVariant.header,
    this.showForNonManagerWithTracker = false,
  });

  @override
  State<MatchTrackerKitPillHost> createState() => _MatchTrackerKitPillHostState();
}

class _MatchTrackerKitPillHostState extends State<MatchTrackerKitPillHost> {
  late grinta_match.Match _match;
  List<TeamOwnerRef> _teamOwners = const [];

  bool get _managerPillVisible =>
      widget.isManager && trackerKitHasTeamContext(_match);

  bool get _shouldShow {
    if (_managerPillVisible) return true;
    return widget.showForNonManagerWithTracker &&
        !widget.isManager &&
        _match.withTracker == true;
  }

  @override
  void initState() {
    super.initState();
    _match = widget.match;
    _prefetchTeamOwners();
  }

  @override
  void didUpdateWidget(covariant MatchTrackerKitPillHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    final teamLinkChanged = trackerKitHasTeamContext(oldWidget.match) !=
            trackerKitHasTeamContext(widget.match) ||
        oldWidget.match.teamID != widget.match.teamID ||
        !_trackerKitMatchTeamsEqual(oldWidget.match.teams, widget.match.teams);
    if (oldWidget.match.id != widget.match.id ||
        oldWidget.isManager != widget.isManager ||
        oldWidget.showForNonManagerWithTracker !=
            widget.showForNonManagerWithTracker ||
        teamLinkChanged) {
      _match = widget.match;
      _prefetchTeamOwners();
    } else if (oldWidget.match.withTracker != widget.match.withTracker ||
        oldWidget.match.ownerId != widget.match.ownerId) {
      _match = widget.match;
    }
  }

  Future<void> _prefetchTeamOwners() async {
    if (!_managerPillVisible) {
      if (mounted) setState(() => _teamOwners = const []);
      return;
    }
    final managedTeamIds =
        context.read<AppSession>().managedTeamsIdsForSelectedSeason;
    final refs = await fetchTrackerKitTeamOwners(
      match: widget.match,
      managedTeamIds: managedTeamIds,
    );
    if (!mounted) return;
    setState(() => _teamOwners = refs);
  }

  Future<void> _openTrackerKitDialog() async {
    var owners = _teamOwners;
    if (owners.isEmpty) {
      final managedTeamIds =
          context.read<AppSession>().managedTeamsIdsForSelectedSeason;
      owners = await fetchTrackerKitTeamOwners(
        match: widget.match,
        managedTeamIds: managedTeamIds,
      );
      if (!mounted) return;
      setState(() => _teamOwners = owners);
    }
    if (!mounted) return;
    final matchId = _match.id?.trim() ?? '';
    if (matchId.isEmpty) return;
    showTrackerKitDialog(
      context,
      matchId: matchId,
      initialWithTracker: _match.withTracker == true,
      initialOwnerId: _match.ownerId,
      teamOwners: owners,
      onStatusChanged: ({required withTracker, ownerId}) {
        setState(() {
          _match.withTracker = withTracker;
          _match.ownerId = ownerId;
          _match.isTrackerDataUploaded = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();

    return TrackerKitGpsPill(
      withTracker: _match.withTracker == true,
      isManager: widget.isManager,
      variant: widget.variant,
      matchId: _match.id,
      initialWithTracker: _match.withTracker == true,
      ownerId: _match.ownerId,
      teamOwners: _teamOwners,
      onManagerTap: _managerPillVisible ? _openTrackerKitDialog : null,
    );
  }
}

class TrackerKitGpsPill extends StatelessWidget {
  final bool withTracker;
  final bool isManager;
  final TrackerKitPillVariant variant;
  final String? matchId;
  final bool initialWithTracker;
  final String? ownerId;
  final List<TeamOwnerRef> teamOwners;
  final TrackerKitStatusChanged? onStatusChanged;

  /// When set, invoked instead of the default [showTrackerKitDialog] (e.g. load owners first).
  final VoidCallback? onManagerTap;

  const TrackerKitGpsPill({
    super.key,
    required this.withTracker,
    required this.isManager,
    this.variant = TrackerKitPillVariant.header,
    this.matchId,
    this.initialWithTracker = false,
    this.ownerId,
    this.teamOwners = const [],
    this.onStatusChanged,
    this.onManagerTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final statusColor = withTracker ? colors.success : colors.warning;
    return TextPillButton(
      label: l10n.matchDetailTrackerKitLabel,
      color: statusColor,
      style: variant == TrackerKitPillVariant.agendaCard
          ? TextPillStyle.onColoredBackground
          : TextPillStyle.tinted,
      onTap: isManager
          ? (onManagerTap ??
              () => showTrackerKitDialog(
                    context,
                    matchId: matchId,
                    initialWithTracker: initialWithTracker || withTracker,
                    initialOwnerId: ownerId,
                    teamOwners: teamOwners,
                    onStatusChanged: onStatusChanged,
                  ))
          : null,
    );
  }
}
