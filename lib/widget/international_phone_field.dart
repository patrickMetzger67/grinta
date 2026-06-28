import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/extensions/l10n_extension.dart';
import '../util/app_theme.dart';

typedef PhoneValueChanged = void Function({
  required String? phoneE164,
  required String? phoneCountryCode,
});

/// Fits 4-digit dial codes such as +1684 on one line.
const _kDialCodeColumnWidth = 64.0;
const _kCountryButtonWidth = 148.0;

class InternationalPhoneField extends StatefulWidget {
  const InternationalPhoneField({
    super.key,
    required this.enabled,
    this.initialPhoneE164,
    this.initialPhoneCountryCode,
    this.labelText,
    this.onChanged,
  });

  final bool enabled;
  final String? initialPhoneE164;
  final String? initialPhoneCountryCode;
  final String? labelText;
  final PhoneValueChanged? onChanged;

  @override
  State<InternationalPhoneField> createState() =>
      _InternationalPhoneFieldState();
}

class _InternationalPhoneFieldState extends State<InternationalPhoneField> {
  late Country _country;
  final TextEditingController _nationalNumberCtrl = TextEditingController();
  bool _appliedInitial = false;
  String? _appliedSeedE164;
  String? _appliedSeedCountryCode;

  @override
  void initState() {
    super.initState();
    _country = _resolveInitialCountry();
    _applyInitialIfNeeded();
  }

  @override
  void didUpdateWidget(covariant InternationalPhoneField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextE164 = _normalizeSeed(widget.initialPhoneE164);
    final nextCountryCode = _normalizeSeed(widget.initialPhoneCountryCode);
    if (nextE164 == _appliedSeedE164 &&
        nextCountryCode == _appliedSeedCountryCode) {
      return;
    }
    _appliedInitial = false;
    _applyInitialIfNeeded();
  }

  String? _normalizeSeed(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  void _applyInitialIfNeeded() {
    if (_appliedInitial) return;
    _appliedInitial = true;
    _appliedSeedE164 = _normalizeSeed(widget.initialPhoneE164);
    _appliedSeedCountryCode = _normalizeSeed(widget.initialPhoneCountryCode);

    final e164 = _appliedSeedE164;
    if (e164 != null && e164.isNotEmpty) {
      _country = _resolveInitialCountry();
      final dialCode = '+${_country.phoneCode}';
      if (e164.startsWith(dialCode)) {
        _nationalNumberCtrl.text = e164.substring(dialCode.length);
      } else if (e164.startsWith('+')) {
        _nationalNumberCtrl.text = e164.replaceFirst('+', '');
      } else {
        _nationalNumberCtrl.text = e164;
      }
    } else {
      _nationalNumberCtrl.clear();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyChanged());
  }

  Country _resolveInitialCountry() {
    final code = widget.initialPhoneCountryCode?.trim().toUpperCase();
    if (code != null && code.isNotEmpty) {
      try {
        return Country.parse(code);
      } catch (_) {}
    }

    final e164 = widget.initialPhoneE164?.trim();
    if (e164 != null && e164.startsWith('+')) {
      final digits = e164.substring(1);
      for (final country in CountryService().getAll()) {
        final phoneCode = country.phoneCode;
        if (digits.startsWith(phoneCode)) {
          return country;
        }
      }
    }

    return Country.parse('FR');
  }

  @override
  void dispose() {
    _nationalNumberCtrl.dispose();
    super.dispose();
  }

  String? _buildE164() {
    final digits = _nationalNumberCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return '+${_country.phoneCode}$digits';
  }

  void _notifyChanged() {
    widget.onChanged?.call(
      phoneE164: _buildE164(),
      phoneCountryCode: _nationalNumberCtrl.text.trim().isEmpty
          ? null
          : _country.countryCode,
    );
  }

  void _pickCountry() {
    if (!widget.enabled) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _CountryPickerSheet(
        onSelect: (country) {
          setState(() => _country = country);
          _notifyChanged();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _kCountryButtonWidth,
          child: InkWell(
            onTap: widget.enabled ? _pickCountry : null,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                isDense: true,
              ),
              child: Row(
                children: [
                  Text(
                    _country.flagEmoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: _kDialCodeColumnWidth,
                    child: Text(
                      '+${_country.phoneCode}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: colors.textPrimary,
                          ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _nationalNumberCtrl,
            enabled: widget.enabled,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: widget.labelText ?? l10n.memberPhoneOptional,
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            onChanged: (_) => _notifyChanged(),
          ),
        ),
      ],
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({required this.onSelect});

  final ValueChanged<Country> onSelect;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  late final List<Country> _allCountries;
  List<Country> _filteredCountries = const [];

  @override
  void initState() {
    super.initState();
    _allCountries = CountryService().getAll();
    _filteredCountries = List.of(_allCountries);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    final localizations = CountryLocalizations.of(context);
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = List.of(_allCountries);
      } else {
        _filteredCountries = _allCountries
            .where((country) => country.startsWith(query, localizations))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.sizeOf(context).height;
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final height = deviceHeight - (statusBarHeight + (kToolbarHeight / 1.5));
    final searchLabel =
        CountryLocalizations.of(context)?.countryName(countryCode: 'search') ??
            'Search';
    final textStyle =
        Theme.of(context).textTheme.bodyLarge ?? const TextStyle(fontSize: 16);

    return SizedBox(
      height: height,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: searchLabel,
                hintText: searchLabel,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: const Color(0xFF8C98A8).withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                final countryName = CountryLocalizations.of(context)
                        ?.countryName(countryCode: country.countryCode)
                        ?.replaceAll(RegExp(r'\s+'), ' ') ??
                    country.name;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      widget.onSelect(country);
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          const SizedBox(width: 20),
                          Text(
                            country.flagEmoji,
                            style: const TextStyle(fontSize: 25),
                          ),
                          const SizedBox(width: 15),
                          SizedBox(
                            width: _kDialCodeColumnWidth,
                            child: Text(
                              '+${country.phoneCode}',
                              style: textStyle,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              countryName,
                              style: textStyle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
