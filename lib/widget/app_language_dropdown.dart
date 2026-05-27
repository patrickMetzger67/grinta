import 'package:flutter/material.dart';

import '../core/extensions/l10n_extension.dart';
import '../main.dart';
import '../util/app_theme.dart';

class AppLanguageOption {
  final Locale locale;
  final String flag;
  final String label;

  const AppLanguageOption({
    required this.locale,
    required this.flag,
    required this.label,
  });
}

/// Sélecteur de langue (FR, EN, DE, ES, IT) — même liste que l'écran de connexion.
class AppLanguageDropdown extends StatelessWidget {
  const AppLanguageDropdown({
    super.key,
    this.compact = false,
    this.showCardDecoration = true,
  });

  /// Mode sidebar repliée : bouton drapeau + menu contextuel.
  final bool compact;

  /// Désactiver quand le parent fournit déjà le cadre (ex. [AppLanguageSidebarTile]).
  final bool showCardDecoration;

  static const List<AppLanguageOption> languages = [
    AppLanguageOption(locale: Locale('fr'), flag: '🇫🇷', label: 'FR'),
    AppLanguageOption(locale: Locale('en'), flag: '🇬🇧', label: 'EN'),
    AppLanguageOption(locale: Locale('de'), flag: '🇩🇪', label: 'DE'),
    AppLanguageOption(locale: Locale('es'), flag: '🇪🇸', label: 'ES'),
    AppLanguageOption(locale: Locale('it'), flag: '🇮🇹', label: 'IT'),
  ];

  static AppLanguageOption selectedFor(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    return languages.firstWhere(
      (e) => e.locale.languageCode == currentLocale.languageCode,
      orElse: () => languages.first,
    );
  }

  void _applyLocale(BuildContext context, String languageCode) {
    final locale = languages
        .firstWhere((e) => e.locale.languageCode == languageCode)
        .locale;
    MyApp.of(context).changeLocale(locale);

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final selected = selectedFor(context);

    if (compact) {
      return Tooltip(
        message: context.l10n.settingsLanguageLabel,
        child: PopupMenuButton<String>(
          tooltip: '',
          padding: EdgeInsets.zero,
          offset: const Offset(0, -8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: colors.border),
          ),
          color: colors.card,
          onSelected: (value) => _applyLocale(context, value),
          itemBuilder: (context) {
            return languages
                .map(
                  (language) => PopupMenuItem<String>(
                    value: language.locale.languageCode,
                    child: Row(
                      children: [
                        Text(
                          language.flag,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          language.label,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList();
          },
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Center(
              child: Text(
                selected.flag,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
        ),
      );
    }

    final dropdown = DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        value: selected.locale.languageCode,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: colors.textSecondary,
        ),
        borderRadius: BorderRadius.circular(14),
        dropdownColor: colors.card,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
        items: languages.map((language) {
          return DropdownMenuItem<String>(
            value: language.locale.languageCode,
            child: Row(
              children: [
                Text(
                  language.flag,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Text(language.label),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value == null) return;
          _applyLocale(context, value);
        },
      ),
    );

    if (!showCardDecoration) {
      return dropdown;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 132.0;
        return SizedBox(
          width: width,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: dropdown,
          ),
        );
      },
    );
  }
}

/// Variante sidebar étendue : icône + libellé + liste déroulante (au-dessus du mode sombre).
class AppLanguageSidebarTile extends StatelessWidget {
  const AppLanguageSidebarTile({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.language_rounded,
                color: colors.primary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.settingsLanguageLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const AppLanguageDropdown(showCardDecoration: false),
        ],
      ),
    );
  }
}
