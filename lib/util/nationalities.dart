import 'dart:ui';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';

import '../data/nationality_labels.dart';

/// A nationality entry: ISO 3166-1 alpha-2 code with a localized demonym label.
class NationalityOption {
  final String countryCode;
  final String label;

  const NationalityOption({
    required this.countryCode,
    required this.label,
  });
}

String _languageCodeFor(Locale locale) {
  final code = locale.languageCode;
  if (nationalityLabelsByLocale.containsKey(code)) {
    return code;
  }
  return 'en';
}

/// Returns the localized nationality adjective for [countryCode], or null if unknown.
String? nationalityLabelForCountryCode(
  String? countryCode,
  Locale locale,
) {
  if (countryCode == null || countryCode.isEmpty) {
    return null;
  }

  final normalizedCode = countryCode.toUpperCase();
  if (_looksLikeCountryCode(normalizedCode)) {
    final languageCode = _languageCodeFor(locale);
    final label = nationalityLabelsByLocale[languageCode]?[normalizedCode];
    if (label != null && label.isNotEmpty) {
      return label;
    }

    try {
      return Country.parse(normalizedCode).name;
    } catch (_) {
      return null;
    }
  }

  // Legacy Firestore values stored as localized strings.
  return countryCode;
}

/// Default nationality ISO code from device or app locale.
String defaultNationalityCountryCode([Locale? locale]) {
  final resolvedLocale = locale ?? PlatformDispatcher.instance.locale;
  final countryCode = resolvedLocale.countryCode?.toUpperCase();

  if (countryCode != null &&
      countryCode.isNotEmpty &&
      nationalityLabelsByLocale['en']!.containsKey(countryCode)) {
    return countryCode;
  }

  return 'FR';
}

/// All nationalities sorted by localized label for [locale].
List<NationalityOption> sortedNationalityOptions(Locale locale) {
  final languageCode = _languageCodeFor(locale);
  final labels = nationalityLabelsByLocale[languageCode]!;

  final options = labels.entries
      .map(
        (entry) => NationalityOption(
          countryCode: entry.key,
          label: entry.value,
        ),
      )
      .toList()
    ..sort((a, b) => a.label.compareTo(b.label));

  return options;
}

bool _looksLikeCountryCode(String value) {
  return value.length == 2 && value == value.toUpperCase();
}

Future<String?> showNationalityPicker({
  required BuildContext context,
  required List<NationalityOption> options,
  required String searchHint,
  String? selectedCountryCode,
}) async {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return _NationalityPickerSheet(
        options: options,
        searchHint: searchHint,
        selectedCountryCode: selectedCountryCode,
      );
    },
  );
}

class _NationalityPickerSheet extends StatefulWidget {
  final List<NationalityOption> options;
  final String searchHint;
  final String? selectedCountryCode;

  const _NationalityPickerSheet({
    required this.options,
    required this.searchHint,
    this.selectedCountryCode,
  });

  @override
  State<_NationalityPickerSheet> createState() =>
      _NationalityPickerSheetState();
}

class _NationalityPickerSheetState extends State<_NationalityPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  late List<NationalityOption> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.options;
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final query = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.options;
        return;
      }

      _filtered = widget.options
          .where((option) => option.label.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: widget.searchHint,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final option = _filtered[index];
                final selected =
                    option.countryCode == widget.selectedCountryCode;

                return ListTile(
                  title: Text(option.label),
                  trailing: selected
                      ? Icon(
                          Icons.check_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () =>
                      Navigator.of(context).pop(option.countryCode),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
