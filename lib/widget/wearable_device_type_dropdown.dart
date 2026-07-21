import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/wearable_device_type.dart';
import 'package:grinta/util/app_theme.dart';

/// Dropdown to pick a wearable device type (Whoop, Strava; extensible later).
class WearableDeviceTypeDropdown extends StatelessWidget {
  const WearableDeviceTypeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.types,
    this.dense = false,
  });

  final WearableDeviceType value;
  final ValueChanged<WearableDeviceType?> onChanged;
  /// When set, only these types appear in the menu (already sorted by caller).
  final List<WearableDeviceType>? types;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final items = types ?? WearableDeviceType.selectableSorted(l10n);
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final effectiveValue = items.contains(value) ? value : items.first;

    return DropdownButtonFormField<WearableDeviceType>(
      value: effectiveValue,
      isExpanded: true,
      dropdownColor: colors.surface,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: colors.textSecondary,
      ),
      decoration: InputDecoration(
        labelText: l10n.wearableDeviceTypeLabel,
        labelStyle: TextStyle(
          color: colors.textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: dense ? 13 : null,
        ),
        filled: true,
        fillColor: colors.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: dense ? 10 : 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
      style: textTheme.bodyLarge?.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: dense ? 14 : null,
      ),
      items: items.map((type) {
        return DropdownMenuItem<WearableDeviceType>(
          value: type,
          child: Row(
            children: [
              Icon(
                type.icon,
                size: dense ? 18 : 20,
                color: colors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  type.label(l10n),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
