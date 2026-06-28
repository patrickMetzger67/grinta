import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/grinta_player.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_positions.dart';
import 'package:grinta/util/player_profile_validator.dart';
import 'package:grinta/widget/international_phone_field.dart';

/// Role, email, and phone collected when adding or editing Grinta staff.
class AddGrintaStaffDetails {
  const AddGrintaStaffDetails({
    required this.roleCode,
    required this.phoneE164,
    this.email,
  });

  final int roleCode;
  final String phoneE164;
  final String? email;
}

Future<AddGrintaStaffDetails?> showAddGrintaStaffSheet(
  BuildContext context, {
  required Player member,
  GrintaPlayer? existingGrintaStaff,
}) {
  return showModalBottomSheet<AddGrintaStaffDetails>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useRootNavigator: false,
    builder: (_) => AddGrintaStaffSheet(
      member: member,
      existingGrintaStaff: existingGrintaStaff,
    ),
  );
}

class AddGrintaStaffSheet extends StatefulWidget {
  const AddGrintaStaffSheet({
    super.key,
    required this.member,
    this.existingGrintaStaff,
  });

  final Player member;
  final GrintaPlayer? existingGrintaStaff;

  bool get isEditMode => existingGrintaStaff != null;

  @override
  State<AddGrintaStaffSheet> createState() => _AddGrintaStaffSheetState();
}

class _AddGrintaStaffSheetState extends State<AddGrintaStaffSheet> {
  final TextEditingController _emailCtrl = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int? _selectedRoleCode;
  String? _phoneE164;
  String? _emailError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    final GrintaPlayer? existing = widget.existingGrintaStaff;

    _emailCtrl.text = existing?.email?.trim() ??
        widget.member.email?.trim() ??
        '';
    _phoneE164 = existing?.phoneE164?.trim() ??
        widget.member.phoneE164?.trim();

    if (existing != null && existing.positions.isNotEmpty) {
      final int code = existing.positions.first;
      if (grintaStaffRoleCodes.contains(code)) {
        _selectedRoleCode = code;
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (!isValidEmailFormat(trimmed)) {
      return context.l10n.memberEmailInvalid;
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return context.l10n.memberPhoneRequired;
    }
    if (!isValidE164Phone(trimmed)) {
      return context.l10n.memberPhoneInvalid;
    }
    return null;
  }

  void _onConfirm() {
    final l10n = context.l10n;

    if (_selectedRoleCode == null) {
      setState(() {
        _emailError = null;
        _phoneError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addStaffRoleRequired)),
      );
      return;
    }

    final email = _emailCtrl.text.trim();
    final emailError = _validateEmail(email);
    final phoneError = _validatePhone(_phoneE164);

    if (emailError != null || phoneError != null) {
      setState(() {
        _emailError = emailError;
        _phoneError = phoneError;
      });
      return;
    }

    final phoneE164 = _phoneE164!.trim();
    Navigator.of(context).pop(
      AddGrintaStaffDetails(
        roleCode: _selectedRoleCode!,
        phoneE164: phoneE164,
        email: email.isEmpty ? null : email,
      ),
    );
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
                      ? l10n.actionEditStaff
                      : l10n.actionAddStaff,
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
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.addStaffRoleLabel,
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _selectedRoleCode,
                      hint: Text(
                        l10n.addStaffRoleHint,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: colors.textSecondary,
                            ),
                      ),
                      items: [
                        for (final int code in grintaStaffRoleCodes)
                          DropdownMenuItem<int>(
                            value: code,
                            child: Text(
                              grintaStaffRoleLabel(code, l10n),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedRoleCode = value);
                      },
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
                  labelText: l10n.memberPhone,
                  initialPhoneE164: widget.existingGrintaStaff?.phoneE164 ??
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
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.actionCancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _onConfirm,
                        child: Text(
                          widget.isEditMode
                              ? l10n.actionSave
                              : l10n.actionAddStaff,
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
