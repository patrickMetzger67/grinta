import 'package:flutter/material.dart';

import '../core/extensions/l10n_extension.dart';
import '../model/member_profile_data.dart';
import '../util/nationalities.dart';
import '../util/player_positions.dart';
import '../util/app_theme.dart';

typedef MemberProfileChanged = void Function(MemberProfileData? profile);

class MemberProfileForm extends StatefulWidget {
  final bool enabled;
  final MemberProfileChanged? onChanged;

  const MemberProfileForm({
    super.key,
    required this.enabled,
    this.onChanged,
  });

  @override
  State<MemberProfileForm> createState() => MemberProfileFormState();
}

class MemberProfileFormState extends State<MemberProfileForm> {
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _birthPlaceCtrl = TextEditingController();

  DateTime? _birthDate;
  String? _nationalityCountryCode;
  final Set<int> _selectedPositionCodes = {};
  List<NationalityOption> _nationalityOptions = const [];

  bool _initializedDefaults = false;
  String? _cachedLocaleLanguageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;

    if (!_initializedDefaults) {
      _initializedDefaults = true;
      _nationalityCountryCode = defaultNationalityCountryCode(locale);
      WidgetsBinding.instance.addPostFrameCallback((_) => _notifyChanged());
    }

    if (_cachedLocaleLanguageCode != languageCode) {
      _cachedLocaleLanguageCode = languageCode;
      _nationalityOptions = sortedNationalityOptions(locale);
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _birthPlaceCtrl.dispose();
    super.dispose();
  }

  MemberProfileData? buildProfile() {
    final profile = MemberProfileData(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      birthPlace: _trimOrNull(_birthPlaceCtrl.text),
      nationality: _nationalityCountryCode?.trim() ?? '',
      birthDay: _formatBirthDay(_birthDate),
      positions: _selectedPositionCodes.toList()..sort(),
    );

    return profile.isValid ? profile : null;
  }

  String? validateAndGetError() {
    if (_firstNameCtrl.text.trim().isEmpty) {
      return context.l10n.memberFirstNameRequired;
    }
    if (_lastNameCtrl.text.trim().isEmpty) {
      return context.l10n.memberLastNameRequired;
    }
    if (_nationalityCountryCode == null ||
        _nationalityCountryCode!.trim().isEmpty) {
      return context.l10n.memberNationalityRequired;
    }
    return null;
  }

  void _notifyChanged() {
    widget.onChanged?.call(buildProfile());
  }

  String? _trimOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _formatBirthDay(DateTime? date) {
    if (date == null) return null;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _nationalityDisplayLabel(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final label = nationalityLabelForCountryCode(
      _nationalityCountryCode,
      locale,
    );
    return label ?? context.l10n.memberNationalityHint;
  }

  void _togglePosition(int code) {
    setState(() {
      if (_selectedPositionCodes.contains(code)) {
        _selectedPositionCodes.remove(code);
      } else {
        _selectedPositionCodes.add(code);
      }
    });
    _notifyChanged();
  }

  Future<void> _pickBirthDate() async {
    if (!widget.enabled) return;

    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 20, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: context.l10n.memberBirthDate,
    );

    if (!mounted || picked == null) return;

    setState(() => _birthDate = picked);
    _notifyChanged();
  }

  Future<void> _pickNationality() async {
    if (!widget.enabled) return;

    final selected = await showNationalityPicker(
      context: context,
      options: _nationalityOptions,
      searchHint: context.l10n.memberNationalitySearch,
      selectedCountryCode: _nationalityCountryCode,
    );

    if (!mounted || selected == null) return;

    setState(() => _nationalityCountryCode = selected);
    _notifyChanged();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final birthDayLabel = _birthDate == null
        ? l10n.memberBirthDateOptional
        : _formatBirthDay(_birthDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.memberProfileTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _firstNameCtrl,
          enabled: widget.enabled,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: l10n.memberFirstName,
            prefixIcon: const Icon(Icons.person_outline_rounded),
          ),
          onChanged: (_) => _notifyChanged(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _lastNameCtrl,
          enabled: widget.enabled,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: l10n.memberLastName,
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
          onChanged: (_) => _notifyChanged(),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: widget.enabled ? _pickBirthDate : null,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.memberBirthDate,
              prefixIcon: const Icon(Icons.cake_outlined),
              suffixIcon: _birthDate != null
                  ? IconButton(
                      onPressed: widget.enabled
                          ? () {
                              setState(() => _birthDate = null);
                              _notifyChanged();
                            }
                          : null,
                      icon: const Icon(Icons.clear_rounded),
                    )
                  : null,
            ),
            child: Text(
              birthDayLabel ?? '',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: _birthDate == null
                        ? colors.textSecondary
                        : colors.textPrimary,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _birthPlaceCtrl,
          enabled: widget.enabled,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: l10n.memberBirthPlaceOptional,
            prefixIcon: const Icon(Icons.place_outlined),
          ),
          onChanged: (_) => _notifyChanged(),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: widget.enabled ? _pickNationality : null,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.memberNationality,
              prefixIcon: const Icon(Icons.flag_outlined),
              suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
            ),
            child: Text(
              _nationalityDisplayLabel(context),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.memberPositions,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final code in selectablePlayerPositionCodes)
              FilterChip(
                label: Text(playerPositionLabel(code, l10n)),
                selected: _selectedPositionCodes.contains(code),
                onSelected: widget.enabled ? (_) => _togglePosition(code) : null,
                showCheckmark: true,
              ),
          ],
        ),
        if (_selectedPositionCodes.isEmpty) ...[
          const SizedBox(height: 6),
          Text(
            l10n.memberPositionsHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
        ],
      ],
    );
  }
}
