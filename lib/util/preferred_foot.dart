import 'package:grinta/l10n/app_localizations.dart';

/// Canonical preferred-foot codes stored on roster entries.
abstract final class PreferredFootCodes {
  static const String left = 'left';
  static const String right = 'right';
  static const String both = 'both';

  static const List<String> selectable = <String>[left, right, both];
}

/// Normalizes legacy / free-text preferred-foot values to a canonical code.
String? normalizePreferredFoot(String? raw) {
  final String value = raw?.trim().toLowerCase() ?? '';
  if (value.isEmpty) {
    return null;
  }

  switch (value) {
    case PreferredFootCodes.left:
    case 'l':
    case 'gauche':
    case 'g':
    case 'left foot':
    case 'pied gauche':
      return PreferredFootCodes.left;
    case PreferredFootCodes.right:
    case 'r':
    case 'droit':
    case 'droite':
    case 'd':
    case 'right foot':
    case 'pied droit':
      return PreferredFootCodes.right;
    case PreferredFootCodes.both:
    case 'b':
    case 'ambidextre':
    case 'ambidextrous':
    case 'two-footed':
    case 'les deux':
    case 'deux':
      return PreferredFootCodes.both;
    default:
      return value;
  }
}

String preferredFootLabel(AppLocalizations l10n, String? raw) {
  final String? code = normalizePreferredFoot(raw);
  if (code == null) {
    return '-';
  }

  switch (code) {
    case PreferredFootCodes.left:
      return l10n.preferredFootLeft;
    case PreferredFootCodes.right:
      return l10n.preferredFootRight;
    case PreferredFootCodes.both:
      return l10n.preferredFootBoth;
    default:
      return raw?.trim().isNotEmpty == true ? raw!.trim() : '-';
  }
}
