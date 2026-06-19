import '../l10n/app_localizations.dart';

/// Player field position codes (aligned with goaltimefootball / effectives).
const int positionCodeGoalkeeper = 3;
const int positionCodeDefender = 4;
const int positionCodeMidfielder = 5;
const int positionCodeForward = 6;

const List<int> selectablePlayerPositionCodes = [
  positionCodeGoalkeeper,
  positionCodeDefender,
  positionCodeMidfielder,
  positionCodeForward,
];

String playerPositionLabel(int code, AppLocalizations l10n) {
  switch (code) {
    case positionCodeGoalkeeper:
      return l10n.positionGoalkeeper;
    case positionCodeDefender:
      return l10n.positionDefender;
    case positionCodeMidfielder:
      return l10n.positionMidfielder;
    case positionCodeForward:
      return l10n.positionForward;
    default:
      return l10n.entityPlayer;
  }
}
