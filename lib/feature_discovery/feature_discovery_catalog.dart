import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/feature_discovery_ids.dart';

enum FeatureDiscoveryBannerScope {
  /// Main shell tabs (agenda, dashboard, chat, …).
  baseScreens,

  /// Features linked to [parentScreenId] (other tabs, sub-tabs, flows).
  relatedFeatures,
}

class FeatureDiscoveryPromptCopy {
  const FeatureDiscoveryPromptCopy({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;
}

typedef FeatureDiscoveryCopyBuilder = FeatureDiscoveryPromptCopy Function(
  AppLocalizations l10n,
);

class FeatureDiscoveryCatalogContext {
  const FeatureDiscoveryCatalogContext({
    required this.isWeb,
    required this.isManager,
    required this.availableShellTabIds,
    required this.currentParentScreenId,
    this.excludeCurrentBaseScreen = false,
    this.matchHasTracker = false,
  });

  final bool isWeb;
  final bool isManager;
  final Set<String> availableShellTabIds;
  final String currentParentScreenId;
  final bool excludeCurrentBaseScreen;
  final bool matchHasTracker;
}

class FeatureDiscoveryEntry {
  const FeatureDiscoveryEntry({
    required this.id,
    required this.scope,
    required this.copyBuilder,
    this.parentScreenId,
    this.requiresManager = false,
    this.requiresWebShellTab = false,
    this.requiresMatchTracker = false,
  });

  final String id;
  final FeatureDiscoveryBannerScope scope;
  final String? parentScreenId;
  final FeatureDiscoveryCopyBuilder copyBuilder;
  final bool requiresManager;
  final bool requiresWebShellTab;
  final bool requiresMatchTracker;

  bool isAvailable(FeatureDiscoveryCatalogContext ctx) {
    if (requiresManager && !ctx.isManager) return false;
    if (requiresMatchTracker && !ctx.matchHasTracker) return false;

    if (scope == FeatureDiscoveryBannerScope.baseScreens) {
      if (ctx.excludeCurrentBaseScreen && id == ctx.currentParentScreenId) {
        return false;
      }
      if (requiresWebShellTab) {
        return ctx.isWeb && ctx.availableShellTabIds.contains(id);
      }
      return ctx.availableShellTabIds.contains(id) ||
          _mobileOffShellIds.contains(id);
    }

    if (parentScreenId != ctx.currentParentScreenId) return false;

    if (_shellTabIds.contains(id)) {
      return ctx.availableShellTabIds.contains(id) ||
          (!ctx.isWeb && _mobileOffShellIds.contains(id));
    }

    if (_matchDetailTabIds.contains(id)) {
      if (id == FeatureDiscoveryIds.matchDetailTabStats &&
          !ctx.matchHasTracker) {
        return false;
      }
      return parentScreenId == FeatureDiscoveryIds.screenMatchDetail;
    }

    return true;
  }
}

const Set<String> _shellTabIds = <String>{
  FeatureDiscoveryIds.tabAgenda,
  FeatureDiscoveryIds.tabDashboard,
  FeatureDiscoveryIds.tabChat,
  FeatureDiscoveryIds.tabSync,
  FeatureDiscoveryIds.tabTeams,
  FeatureDiscoveryIds.tabFields,
  FeatureDiscoveryIds.tabCompo,
};

const Set<String> _mobileOffShellIds = <String>{
  FeatureDiscoveryIds.tabSync,
  FeatureDiscoveryIds.tabTeams,
  FeatureDiscoveryIds.tabFields,
  FeatureDiscoveryIds.tabCompo,
};

const Set<String> _matchDetailTabIds = <String>{
  FeatureDiscoveryIds.matchDetailTabCompo,
  FeatureDiscoveryIds.matchDetailTabTacticalSchema,
  FeatureDiscoveryIds.matchDetailTabHighlights,
  FeatureDiscoveryIds.matchDetailTabStats,
};

/// Extend this list to add new discovery targets.
abstract final class FeatureDiscoveryCatalog {
  static const List<FeatureDiscoveryEntry> entries = <FeatureDiscoveryEntry>[
    FeatureDiscoveryEntry(
      id: FeatureDiscoveryIds.tabDashboard,
      scope: FeatureDiscoveryBannerScope.baseScreens,
      copyBuilder: _dashboardCopy,
    ),
    FeatureDiscoveryEntry(
      id: FeatureDiscoveryIds.tabAgenda,
      scope: FeatureDiscoveryBannerScope.baseScreens,
      copyBuilder: _agendaCopy,
    ),
    FeatureDiscoveryEntry(
      id: FeatureDiscoveryIds.tabChat,
      scope: FeatureDiscoveryBannerScope.baseScreens,
      copyBuilder: _chatCopy,
    ),
    FeatureDiscoveryEntry(
      id: FeatureDiscoveryIds.tabSync,
      scope: FeatureDiscoveryBannerScope.baseScreens,
      requiresManager: true,
      requiresWebShellTab: true,
      copyBuilder: _syncCopy,
    ),
    FeatureDiscoveryEntry(
      id: FeatureDiscoveryIds.tabTeams,
      scope: FeatureDiscoveryBannerScope.baseScreens,
      requiresManager: true,
      requiresWebShellTab: true,
      copyBuilder: _teamsCopy,
    ),
    FeatureDiscoveryEntry(
      id: FeatureDiscoveryIds.tabFields,
      scope: FeatureDiscoveryBannerScope.baseScreens,
      requiresManager: true,
      requiresWebShellTab: true,
      copyBuilder: _fieldsCopy,
    ),
    FeatureDiscoveryEntry(
      id: FeatureDiscoveryIds.tabCompo,
      scope: FeatureDiscoveryBannerScope.baseScreens,
      requiresManager: true,
      requiresWebShellTab: true,
      copyBuilder: _compoCopy,
    ),

    FeatureDiscoveryEntry(
      id: FeatureDiscoveryIds.tabAgenda,
      scope: FeatureDiscoveryBannerScope.relatedFeatures,
      parentScreenId: FeatureDiscoveryIds.tabDashboard,
      copyBuilder: _agendaCopy,
    ),
    FeatureDiscoveryEntry(
      id: FeatureDiscoveryIds.tabSync,
      scope: FeatureDiscoveryBannerScope.relatedFeatures,
      parentScreenId: FeatureDiscoveryIds.tabDashboard,
      requiresManager: true,
      requiresWebShellTab: true,
      copyBuilder: _syncCopy,
    ),
    FeatureDiscoveryEntry(
      id: FeatureDiscoveryIds.tabChat,
      scope: FeatureDiscoveryBannerScope.relatedFeatures,
      parentScreenId: FeatureDiscoveryIds.tabDashboard,
      copyBuilder: _chatCopy,
    ),

    FeatureDiscoveryEntry(
      id: FeatureDiscoveryIds.tabDashboard,
      scope: FeatureDiscoveryBannerScope.relatedFeatures,
      parentScreenId: FeatureDiscoveryIds.tabAgenda,
      copyBuilder: _dashboardCopy,
    ),
    FeatureDiscoveryEntry(
      id: FeatureDiscoveryIds.tabSync,
      scope: FeatureDiscoveryBannerScope.relatedFeatures,
      parentScreenId: FeatureDiscoveryIds.tabAgenda,
      requiresManager: true,
      copyBuilder: _syncCopy,
    ),
    FeatureDiscoveryEntry(
      id: FeatureDiscoveryIds.tabChat,
      scope: FeatureDiscoveryBannerScope.relatedFeatures,
      parentScreenId: FeatureDiscoveryIds.tabAgenda,
      copyBuilder: _chatCopy,
    ),

    FeatureDiscoveryEntry(
      id: FeatureDiscoveryIds.tabAgenda,
      scope: FeatureDiscoveryBannerScope.relatedFeatures,
      parentScreenId: FeatureDiscoveryIds.tabChat,
      copyBuilder: _agendaCopy,
    ),
    FeatureDiscoveryEntry(
      id: FeatureDiscoveryIds.tabDashboard,
      scope: FeatureDiscoveryBannerScope.relatedFeatures,
      parentScreenId: FeatureDiscoveryIds.tabChat,
      copyBuilder: _dashboardCopy,
    ),

    FeatureDiscoveryEntry(
      id: FeatureDiscoveryIds.tabAgenda,
      scope: FeatureDiscoveryBannerScope.relatedFeatures,
      parentScreenId: FeatureDiscoveryIds.tabSync,
      requiresManager: true,
      copyBuilder: _agendaCopy,
    ),

    FeatureDiscoveryEntry(
      id: FeatureDiscoveryIds.matchDetailTabTacticalSchema,
      scope: FeatureDiscoveryBannerScope.relatedFeatures,
      parentScreenId: FeatureDiscoveryIds.screenMatchDetail,
      copyBuilder: _matchTacticalCopy,
    ),
    FeatureDiscoveryEntry(
      id: FeatureDiscoveryIds.matchDetailTabHighlights,
      scope: FeatureDiscoveryBannerScope.relatedFeatures,
      parentScreenId: FeatureDiscoveryIds.screenMatchDetail,
      copyBuilder: _matchHighlightsCopy,
    ),
    FeatureDiscoveryEntry(
      id: FeatureDiscoveryIds.matchDetailTabStats,
      scope: FeatureDiscoveryBannerScope.relatedFeatures,
      parentScreenId: FeatureDiscoveryIds.screenMatchDetail,
      requiresMatchTracker: true,
      copyBuilder: _matchStatsCopy,
    ),
    FeatureDiscoveryEntry(
      id: FeatureDiscoveryIds.matchDetailTabCompo,
      scope: FeatureDiscoveryBannerScope.relatedFeatures,
      parentScreenId: FeatureDiscoveryIds.screenMatchDetail,
      copyBuilder: _matchCompoCopy,
    ),
  ];

  static List<FeatureDiscoveryEntry> candidatesFor({
    required FeatureDiscoveryBannerScope scope,
    required FeatureDiscoveryCatalogContext context,
  }) {
    return entries
        .where(
          (FeatureDiscoveryEntry e) =>
              e.scope == scope && e.isAvailable(context),
        )
        .toList();
  }

  /// Eligible targets for one random banner (base + related, deduped by id).
  static List<FeatureDiscoveryEntry> combinedCandidatesFor({
    required FeatureDiscoveryCatalogContext context,
    bool includeBaseScreens = true,
    bool includeRelated = true,
  }) {
    final seen = <String>{};
    final result = <FeatureDiscoveryEntry>[];

    void addScope(FeatureDiscoveryBannerScope scope) {
      for (final entry in candidatesFor(scope: scope, context: context)) {
        if (seen.add(entry.id)) result.add(entry);
      }
    }

    if (includeBaseScreens) {
      addScope(FeatureDiscoveryBannerScope.baseScreens);
    }
    if (includeRelated) {
      addScope(FeatureDiscoveryBannerScope.relatedFeatures);
    }
    return result;
  }
}

FeatureDiscoveryPromptCopy _agendaCopy(AppLocalizations l10n) =>
    FeatureDiscoveryPromptCopy(
      title: l10n.featureDiscoveryAgendaTitle,
      message: l10n.featureDiscoveryAgendaMessage,
    );

FeatureDiscoveryPromptCopy _dashboardCopy(AppLocalizations l10n) =>
    FeatureDiscoveryPromptCopy(
      title: l10n.featureDiscoveryDashboardTitle,
      message: l10n.featureDiscoveryDashboardMessage,
    );

FeatureDiscoveryPromptCopy _chatCopy(AppLocalizations l10n) =>
    FeatureDiscoveryPromptCopy(
      title: l10n.featureDiscoveryChatTitle,
      message: l10n.featureDiscoveryChatMessage,
    );

FeatureDiscoveryPromptCopy _syncCopy(AppLocalizations l10n) =>
    FeatureDiscoveryPromptCopy(
      title: l10n.featureDiscoverySyncTitle,
      message: l10n.featureDiscoverySyncMessage,
    );

FeatureDiscoveryPromptCopy _teamsCopy(AppLocalizations l10n) =>
    FeatureDiscoveryPromptCopy(
      title: l10n.featureDiscoveryTeamsTitle,
      message: l10n.featureDiscoveryTeamsMessage,
    );

FeatureDiscoveryPromptCopy _fieldsCopy(AppLocalizations l10n) =>
    FeatureDiscoveryPromptCopy(
      title: l10n.featureDiscoveryFieldsTitle,
      message: l10n.featureDiscoveryFieldsMessage,
    );

FeatureDiscoveryPromptCopy _compoCopy(AppLocalizations l10n) =>
    FeatureDiscoveryPromptCopy(
      title: l10n.featureDiscoveryCompoTitle,
      message: l10n.featureDiscoveryCompoMessage,
    );

FeatureDiscoveryPromptCopy _matchCompoCopy(AppLocalizations l10n) =>
    FeatureDiscoveryPromptCopy(
      title: l10n.featureDiscoveryMatchCompoTitle,
      message: l10n.featureDiscoveryMatchCompoMessage,
    );

FeatureDiscoveryPromptCopy _matchTacticalCopy(AppLocalizations l10n) =>
    FeatureDiscoveryPromptCopy(
      title: l10n.featureDiscoveryMatchTacticalTitle,
      message: l10n.featureDiscoveryMatchTacticalMessage,
    );

FeatureDiscoveryPromptCopy _matchHighlightsCopy(AppLocalizations l10n) =>
    FeatureDiscoveryPromptCopy(
      title: l10n.featureDiscoveryMatchHighlightsTitle,
      message: l10n.featureDiscoveryMatchHighlightsMessage,
    );

FeatureDiscoveryPromptCopy _matchStatsCopy(AppLocalizations l10n) =>
    FeatureDiscoveryPromptCopy(
      title: l10n.featureDiscoveryMatchStatsTitle,
      message: l10n.featureDiscoveryMatchStatsMessage,
    );
