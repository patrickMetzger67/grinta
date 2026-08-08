import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/grinta_player.dart';
import 'package:grinta/model/grinta_player_hw.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/services/player_positions_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_profile_validator.dart';
import 'package:grinta/util/preferred_foot.dart';
import 'package:grinta/widget/international_phone_field.dart';

/// Contact, birthday, and body metrics collected when adding a player to a team.
class AddGrintaPlayerDetails {
  const AddGrintaPlayerDetails({
    required this.positions,
    required this.phoneE164,
    this.email,
    this.birthday,
    this.initialMeasurement,
    this.preferredFoot,
  });

  final List<int> positions;
  final String phoneE164;
  final String? email;
  final DateTime? birthday;
  final GrintaPlayerHW? initialMeasurement;
  final String? preferredFoot;
}

/// Shows position, contact, birthday, and body metrics before adding a member
/// to a Grinta roster.
Future<AddGrintaPlayerDetails?> showAddGrintaPlayerSheet(
  BuildContext context, {
  required Player member,
  GrintaPlayer? existingGrintaPlayer,
  bool showManagerToggle = false,
  ValueNotifier<bool>? isManagerListenable,
  Future<bool> Function()? onToggleManager,
  Future<void> Function(AddGrintaPlayerDetails details)? onSubmit,
}) {
  return showModalBottomSheet<AddGrintaPlayerDetails>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useRootNavigator: false,
    builder: (_) => AddGrintaPlayerSheet(
      member: member,
      existingGrintaPlayer: existingGrintaPlayer,
      showManagerToggle: showManagerToggle,
      isManagerListenable: isManagerListenable,
      onToggleManager: onToggleManager,
      onSubmit: onSubmit,
    ),
  );
}

class AddGrintaPlayerSheet extends StatefulWidget {
  const AddGrintaPlayerSheet({
    super.key,
    required this.member,
    this.existingGrintaPlayer,
    this.showManagerToggle = false,
    this.isManagerListenable,
    this.onToggleManager,
    this.onSubmit,
  });

  final Player member;
  final GrintaPlayer? existingGrintaPlayer;
  final bool showManagerToggle;
  final ValueNotifier<bool>? isManagerListenable;
  final Future<bool> Function()? onToggleManager;
  final Future<void> Function(AddGrintaPlayerDetails details)? onSubmit;

  bool get isEditMode => existingGrintaPlayer != null;

  @override
  State<AddGrintaPlayerSheet> createState() => _AddGrintaPlayerSheetState();
}

class _AddGrintaPlayerSheetState extends State<AddGrintaPlayerSheet> {
  static const int _minHeightCm = 50;
  static const int _maxHeightCm = 250;
  static const double _minWeightKg = 20;
  static const double _maxWeightKg = 200;

  final PlayerPositionsService _playerPositionsService =
      PlayerPositionsService.instance;
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _heightCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int? _selectedPositionCode;
  String? _phoneE164;
  String? _emailError;
  String? _phoneError;
  String? _heightError;
  String? _weightError;
  DateTime? _birthday;
  String? _preferredFoot;
  bool _positionsReady = false;
  bool _isTogglingManager = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final GrintaPlayer? existing = widget.existingGrintaPlayer;
    final GrintaPlayerHW? latestHw = existing?.latestHw;

    _emailCtrl.text = existing?.email?.trim() ??
        widget.member.email?.trim() ??
        '';
    _phoneE164 = existing?.phoneE164?.trim() ??
        widget.member.phoneE164?.trim();
    _birthday = existing?.birthday ?? Player.parseBirthDay(widget.member.birthDay);

    if (existing != null && existing.positions.isNotEmpty) {
      _selectedPositionCode = existing.positions.first;
    }

    if (latestHw != null && latestHw.height > 0) {
      _heightCtrl.text = latestHw.height.toString();
    }
    if (latestHw != null && latestHw.weight > 0) {
      final double weight = latestHw.weight;
      _weightCtrl.text = weight == weight.roundToDouble()
          ? weight.round().toString()
          : weight.toString();
    }

    _preferredFoot = normalizePreferredFoot(existing?.preferredFoot);

    _initPositions();
  }

  Future<void> _initPositions() async {
    await _playerPositionsService.ensureInitialized();
    if (!mounted) return;
    setState(() => _positionsReady = true);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    // Email is always optional when adding/convoking a player; invitation is
    // skipped when empty (see MemberInvitationService.inviteMember).
    if (trimmed.isEmpty) {
      return null;
    }
    if (!isValidEmailFormat(trimmed)) {
      return context.l10n.memberEmailInvalid;
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    if (!isValidE164Phone(trimmed)) {
      return context.l10n.memberPhoneInvalid;
    }
    return null;
  }

  String? _validateHeight(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;

    final int? height = int.tryParse(trimmed);
    if (height == null ||
        height < _minHeightCm ||
        height > _maxHeightCm) {
      return context.l10n.addPlayerHeightInvalid;
    }
    return null;
  }

  String? _validateWeight(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;

    final double? weight = double.tryParse(trimmed.replaceAll(',', '.'));
    if (weight == null ||
        weight < _minWeightKg ||
        weight > _maxWeightKg) {
      return context.l10n.addPlayerWeightInvalid;
    }
    return null;
  }

  String? _formatBirthDay(DateTime? date) {
    if (date == null) return null;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final initial = _birthday ?? DateTime(now.year - 20, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: context.l10n.memberBirthDate,
    );

    if (!mounted || picked == null) return;

    setState(() => _birthday = picked);
  }

  GrintaPlayerHW? _buildInitialMeasurement() {
    final String heightText = _heightCtrl.text.trim();
    final String weightText = _weightCtrl.text.trim();
    if (heightText.isEmpty && weightText.isEmpty) {
      return null;
    }

    final int? height = int.tryParse(heightText);
    final double? weight =
        double.tryParse(weightText.replaceAll(',', '.'));
    if (height == null || weight == null) {
      return null;
    }

    return GrintaPlayerHW(
      height: height,
      weight: weight,
      dateTime: DateTime.now(),
    );
  }

  Future<void> _onConfirm() async {
    final l10n = context.l10n;

    if (_isSubmitting) return;

    if (_selectedPositionCode == null) {
      setState(() {
        _emailError = null;
        _phoneError = null;
        _heightError = null;
        _weightError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addPlayerPositionRequired)),
      );
      return;
    }

    final email = _emailCtrl.text.trim();
    final emailError = _validateEmail(email);
    final phoneError = _validatePhone(_phoneE164);
    final heightError = _validateHeight(_heightCtrl.text);
    final weightError = _validateWeight(_weightCtrl.text);

    if (emailError != null ||
        phoneError != null ||
        heightError != null ||
        weightError != null) {
      setState(() {
        _emailError = emailError;
        _phoneError = phoneError;
        _heightError = heightError;
        _weightError = weightError;
      });
      return;
    }

    final phoneE164 = (_phoneE164?.trim().isNotEmpty ?? false)
        ? _phoneE164!.trim()
        : '';
    final details = AddGrintaPlayerDetails(
      positions: <int>[_selectedPositionCode!],
      phoneE164: phoneE164,
      email: email.isEmpty ? null : email,
      birthday: _birthday,
      initialMeasurement: _buildInitialMeasurement(),
      preferredFoot: _preferredFoot,
    );

    final submit = widget.onSubmit;
    if (submit != null) {
      setState(() => _isSubmitting = true);
      try {
        await submit(details);
        if (!mounted) return;
        Navigator.of(context).pop(details);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric(e.toString()))),
        );
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
      return;
    }

    Navigator.of(context).pop(details);
  }

  Future<void> _onToggleManagerPressed() async {
    final toggle = widget.onToggleManager;
    if (toggle == null || _isTogglingManager) return;

    setState(() => _isTogglingManager = true);
    try {
      final bool isManager = await toggle();
      widget.isManagerListenable?.value = isManager;
    } finally {
      if (mounted) {
        setState(() => _isTogglingManager = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final memberName = playerDisplayName(
      widget.member,
      unknownLabel: l10n.entityPlayerUnknown,
    );
    final birthdayLabel = _birthday == null
        ? l10n.memberBirthDateOptional
        : _formatBirthDay(_birthday);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.isEditMode
                      ? l10n.actionEditPlayer
                      : l10n.actionAddPlayer,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  memberName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
                const SizedBox(height: 20),
                if (!_positionsReady)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.memberPositions,
                      prefixIcon: const Icon(Icons.sports_soccer_outlined),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: _selectedPositionCode,
                        hint: Text(
                          l10n.memberPositionsHint,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: colors.textSecondary,
                              ),
                        ),
                        items: [
                          for (final code
                              in _playerPositionsService.selectableCodes)
                            DropdownMenuItem<int>(
                              value: code,
                              child: Text(
                                _playerPositionsService.labelForCode(code, l10n),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedPositionCode = value);
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.preferredFootLabel,
                    prefixIcon: const Icon(Icons.directions_walk_outlined),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      isExpanded: true,
                      value: _preferredFoot,
                      hint: Text(
                        l10n.preferredFootHint,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: colors.textSecondary,
                            ),
                      ),
                      items: <DropdownMenuItem<String?>>[
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(l10n.preferredFootUnspecified),
                        ),
                        for (final String code in PreferredFootCodes.selectable)
                          DropdownMenuItem<String?>(
                            value: code,
                            child: Text(preferredFootLabel(l10n, code)),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() => _preferredFoot = value);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickBirthday,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.memberBirthDate,
                      prefixIcon: const Icon(Icons.cake_outlined),
                      suffixIcon: _birthday != null
                          ? IconButton(
                              onPressed: () {
                                setState(() => _birthday = null);
                              },
                              icon: const Icon(Icons.clear_rounded),
                            )
                          : null,
                    ),
                    child: Text(
                      birthdayLabel ?? '',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: _birthday == null
                                ? colors.textSecondary
                                : colors.textPrimary,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: l10n.memberEmailOptional,
                    prefixIcon: const Icon(Icons.email_outlined),
                    errorText: _emailError,
                  ),
                  onChanged: (_) {
                    if (_emailError != null) {
                      setState(() => _emailError = null);
                    }
                  },
                ),
                const SizedBox(height: 12),
                InternationalPhoneField(
                  enabled: true,
                  labelText: l10n.memberPhoneOptional,
                  initialPhoneE164: widget.existingGrintaPlayer?.phoneE164 ??
                      widget.member.phoneE164,
                  initialPhoneCountryCode: widget.member.phoneCountryCode,
                  onChanged: ({
                    required phoneE164,
                    required phoneCountryCode,
                  }) {
                    _phoneE164 = phoneE164;
                    if (_phoneError != null) {
                      setState(() => _phoneError = null);
                    }
                  },
                ),
                if (_phoneError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _phoneError!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _heightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.addPlayerHeightCmOptional,
                          prefixIcon: const Icon(Icons.height_outlined),
                          errorText: _heightError,
                        ),
                        onChanged: (_) {
                          if (_heightError != null) {
                            setState(() => _heightError = null);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.addPlayerWeightKgOptional,
                          prefixIcon: const Icon(Icons.monitor_weight_outlined),
                          errorText: _weightError,
                        ),
                        onChanged: (_) {
                          if (_weightError != null) {
                            setState(() => _weightError = null);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                if (widget.isEditMode &&
                    widget.showManagerToggle &&
                    widget.onToggleManager != null &&
                    widget.isManagerListenable != null) ...[
                  const SizedBox(height: 20),
                  ValueListenableBuilder<bool>(
                    valueListenable: widget.isManagerListenable!,
                    builder: (context, isManager, _) {
                      return OutlinedButton.icon(
                        onPressed:
                            _isTogglingManager ? null : _onToggleManagerPressed,
                        icon: _isTogglingManager
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.primary,
                                ),
                              )
                            : Icon(
                                Icons.verified_rounded,
                                color: isManager ? colors.success : null,
                              ),
                        label: Text(
                          isManager
                              ? l10n.teamDetailRevokeManager
                              : l10n.teamDetailGrantManager,
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(l10n.actionCancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed:
                            _positionsReady && !_isSubmitting ? _onConfirm : null,
                        child: _isSubmitting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                widget.isEditMode
                                    ? l10n.actionSave
                                    : l10n.actionAddPlayer,
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
