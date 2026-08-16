import 'dart:async';

import 'package:flutter/material.dart';

import '../core/extensions/l10n_extension.dart';
import '../model/player.dart';
import '../util/account_age_gate.dart';
import '../util/nationalities.dart';
import '../util/player_positions.dart';
import '../util/player_profile_validator.dart';
import '../util/app_theme.dart';
import 'international_phone_field.dart';

typedef MemberProfileChanged = void Function(Player? profile);
typedef MemberProfileValidityChanged = void Function(bool isValid);
typedef MemberProfileFormStateCreated = void Function(
  MemberProfileFormState state,
);

class MemberProfileForm extends StatefulWidget {
  final bool enabled;
  final MemberProfileChanged? onChanged;
  final MemberProfileValidityChanged? onValidityChanged;
  final MemberProfileFormStateCreated? onFormStateCreated;
  final Player? initialProfile;
  final bool showTitle;

  /// When true (email signup), email is mandatory for Firebase Auth.
  final bool requireEmail;

  /// When true, first/last name and email from Sign in with Apple / Google
  /// are not shown or requested (App Store Guideline 4). They are taken from
  /// [initialProfile] instead.
  final bool lockIdentityFromAuth;

  const MemberProfileForm({
    super.key,
    required this.enabled,
    this.onChanged,
    this.onValidityChanged,
    this.onFormStateCreated,
    this.initialProfile,
    this.showTitle = true,
    this.requireEmail = false,
    this.lockIdentityFromAuth = false,
  });

  @override
  State<MemberProfileForm> createState() => MemberProfileFormState();
}

class MemberProfileFormState extends State<MemberProfileForm> {
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _birthPlaceCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();

  DateTime? _birthDate;
  String? _nationalityCountryCode;
  String? _phoneE164;
  String? _phoneCountryCode;
  String? _seedPhoneE164;
  String? _seedPhoneCountryCode;
  final Set<int> _selectedPositionCodes = {};
  List<NationalityOption> _nationalityOptions = const [];

  bool _initializedDefaults = false;
  bool _appliedInitialProfile = false;
  String? _cachedLocaleLanguageCode;
  Timer? _notifyDebounce;
  final Key _phoneFieldKey = const ValueKey('member-profile-phone');

  @override
  void initState() {
    super.initState();
    _applyInitialProfileIfNeeded();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onFormStateCreated?.call(this);
      }
    });
  }

  @override
  void didUpdateWidget(covariant MemberProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_initialProfileChanged(
      oldWidget.initialProfile,
      widget.initialProfile,
    )) {
      _appliedInitialProfile = false;
      _applyInitialProfileIfNeeded();
    }
  }

  bool _initialProfileChanged(Player? previous, Player? next) {
    if (identical(previous, next)) return false;
    if (_profileMemberId(previous) != _profileMemberId(next)) return true;
    // Auth seed profiles often have no member id — compare identity fields.
    return (previous?.firstName ?? '') != (next?.firstName ?? '') ||
        (previous?.lastName ?? '') != (next?.lastName ?? '') ||
        (previous?.email ?? '') != (next?.email ?? '');
  }

  String _profileMemberId(Player? profile) =>
      profile?.keyMember?.trim() ?? '';

  bool get _hideIdentityFields => widget.lockIdentityFromAuth;

  String get _identityFirstName {
    final typed = _firstNameCtrl.text.trim();
    if (typed.isNotEmpty) return typed;
    return widget.initialProfile?.firstName?.trim() ?? '';
  }

  String get _identityLastName {
    final typed = _lastNameCtrl.text.trim();
    if (typed.isNotEmpty) return typed;
    return widget.initialProfile?.lastName?.trim() ?? '';
  }

  String? get _identityEmail {
    final typed = _trimOrNull(_emailCtrl.text);
    if (typed != null) return typed;
    return _trimOrNull(widget.initialProfile?.email ?? '');
  }

  void _applyInitialProfileIfNeeded() {
    if (_appliedInitialProfile) return;
    final initial = widget.initialProfile;
    if (initial == null) return;

    _appliedInitialProfile = true;
    _firstNameCtrl.text = initial.firstName?.trim() ?? '';
    _lastNameCtrl.text = initial.lastName?.trim() ?? '';
    _birthPlaceCtrl.text = initial.birthPlace?.trim() ?? '';
    _emailCtrl.text = initial.email?.trim() ?? '';
    _birthDate = Player.parseBirthDay(initial.birthDay);
    _nationalityCountryCode = initial.nationality?.trim().isNotEmpty == true
        ? initial.nationality!.trim()
        : null;
    _phoneE164 = initial.phoneE164?.trim().isNotEmpty == true
        ? initial.phoneE164!.trim()
        : null;
    _phoneCountryCode = initial.phoneCountryCode?.trim().isNotEmpty == true
        ? initial.phoneCountryCode!.trim()
        : null;
    _seedPhoneE164 = _phoneE164;
    _seedPhoneCountryCode = _phoneCountryCode;
    _selectedPositionCodes
      ..clear()
      ..addAll(initial.positionCodes);
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyChanged());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;

    if (!_initializedDefaults) {
      _initializedDefaults = true;
      if (widget.initialProfile == null) {
        _nationalityCountryCode = defaultNationalityCountryCode(locale);
      } else if (_nationalityCountryCode == null ||
          _nationalityCountryCode!.trim().isEmpty) {
        _nationalityCountryCode = defaultNationalityCountryCode(locale);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _notifyChanged());
    }

    if (_cachedLocaleLanguageCode != languageCode) {
      _cachedLocaleLanguageCode = languageCode;
      _nationalityOptions = sortedNationalityOptions(locale);
    }
  }

  @override
  void dispose() {
    _notifyDebounce?.cancel();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _birthPlaceCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Player? buildProfile() {
    final profile = Player(
      firstName: _identityFirstName,
      lastName: _identityLastName,
      birthPlace: _trimOrNull(_birthPlaceCtrl.text),
      nationality: _nationalityCountryCode?.trim() ?? '',
      birthDay: _formatBirthDay(_birthDate),
      positions: _selectedPositionCodes.toList()..sort(),
      email: _identityEmail,
      phoneE164: _phoneE164,
      phoneCountryCode: _phoneCountryCode,
    );

    if (_hideIdentityFields) {
      final hasIdentity =
          _identityFirstName.isNotEmpty && _identityLastName.isNotEmpty;
      final hasBirth = profile.birthDay?.trim().isNotEmpty ?? false;
      final hasNationality = profile.nationality?.trim().isNotEmpty ?? false;
      if (hasIdentity &&
          hasBirth &&
          hasNationality &&
          isValidEmailFormat(profile.email) &&
          isValidE164Phone(profile.phoneE164)) {
        return profile;
      }
      return null;
    }
    return profile.isProfileAndContactValid ? profile : null;
  }

  String? validateAndGetError() {
    if (!_hideIdentityFields) {
      if (_identityFirstName.isEmpty) {
        return context.l10n.memberFirstNameRequired;
      }
      if (_identityLastName.isEmpty) {
        return context.l10n.memberLastNameRequired;
      }
    }
    if (_birthDate == null) {
      return context.l10n.memberBirthDateRequired;
    }
    final ageYears = ageYearsFromBirthDate(_birthDate!);
    if (classifyAccountAge(ageYears) == AccountAgeGateResult.blockedUnderage) {
      return context.l10n.accountAgeBlockedUnderage;
    }
    if (_nationalityCountryCode == null ||
        _nationalityCountryCode!.trim().isEmpty) {
      return context.l10n.memberNationalityRequired;
    }
    final email = _identityEmail ?? '';
    if (widget.requireEmail && !_hideIdentityFields) {
      if (email.isEmpty) {
        return context.l10n.signupEmailRequired;
      }
      if (!isValidEmailFormat(email)) {
        return context.l10n.memberEmailInvalid;
      }
    }
    final draftProfile = Player(
      email: _identityEmail,
      phoneE164: _phoneE164,
    );
    if (!widget.requireEmail &&
        !_hideIdentityFields &&
        !hasContactInfo(draftProfile)) {
      return context.l10n.memberContactRequired;
    }
    if (!widget.requireEmail && !isValidEmailFormat(_identityEmail)) {
      return context.l10n.memberEmailInvalid;
    }
    if (!isValidE164Phone(_phoneE164)) {
      return context.l10n.memberPhoneInvalid;
    }
    return null;
  }

  void _notifyChanged() {
    _notifyDebounce?.cancel();
    _notifyDebounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      final profile = buildProfile();
      final isValid = profile?.isProfileAndContactValid == true;
      widget.onValidityChanged?.call(isValid);
      widget.onChanged?.call(profile);
    });
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

  /// Standard profile roles plus staff codes already stored on the member
  /// (e.g. medical) so existing selections stay visible when editing.
  List<int> get _selectableProfilePositionCodes {
    final codes = <int>{...selectableMemberProfilePositionCodes};
    for (final code in _selectedPositionCodes) {
      if (isStaffProfilePositionCode(code)) {
        codes.add(code);
      }
    }
    return codes.toList()..sort();
  }

  Future<void> _pickBirthDate() async {
    if (!widget.enabled) return;

    final now = DateTime.now();
    // Allow declaring any age (including under 13) so the age gate can block
    // honestly — Google/Apple already created Auth before this form.
    final lastDate = DateTime(now.year, now.month, now.day);
    final initial = _birthDate ??
        DateTime(now.year - kSelfServeAccountAgeYears, now.month, now.day);
    final safeInitial = initial.isAfter(lastDate) ? lastDate : initial;

    final picked = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: DateTime(1900),
      lastDate: lastDate,
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
        ? l10n.memberBirthDate
        : _formatBirthDay(_birthDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) ...[
          Text(
            l10n.memberProfileTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
        ],
        if (_hideIdentityFields) ...[
          Text(
            l10n.memberIdentityFromAuthHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
        ] else ...[
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
          TextField(
            controller: _emailCtrl,
            enabled: widget.enabled,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: widget.requireEmail
                  ? l10n.memberEmail
                  : l10n.memberEmailOptional,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            onChanged: (_) => _notifyChanged(),
          ),
          const SizedBox(height: 12),
        ],
        InternationalPhoneField(
          key: _phoneFieldKey,
          enabled: widget.enabled,
          initialPhoneE164: _seedPhoneE164,
          initialPhoneCountryCode: _seedPhoneCountryCode,
          onChanged: ({
            required phoneE164,
            required phoneCountryCode,
          }) {
            _phoneE164 = phoneE164;
            _phoneCountryCode = phoneCountryCode;
            _notifyChanged();
          },
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
        const SizedBox(height: 6),
        Text(
          l10n.memberBirthDateAgeHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
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
            for (final code in _selectableProfilePositionCodes)
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
