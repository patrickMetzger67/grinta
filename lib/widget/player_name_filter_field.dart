import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/util/app_theme.dart';

/// Mobile-safe player name filter.
///
/// The [TextField] itself is never rebuilt when the query changes. The clear
/// control lives in a [ValueListenableBuilder] and the suffix slot is always
/// reserved so the first keystroke cannot steal focus on mobile.
class PlayerNameFilterField extends StatelessWidget {
  const PlayerNameFilterField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.padding = const EdgeInsets.only(bottom: 12),
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return Padding(
      padding: padding,
      child: TextField(
        key: const ValueKey('player-name-filter-field'),
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.search,
        autocorrect: false,
        enableSuggestions: false,
        smartDashesType: SmartDashesType.disabled,
        smartQuotesType: SmartQuotesType.disabled,
        keyboardType: TextInputType.text,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          isDense: true,
          hintText: l10n.teamDetailFilterPlayerHint,
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: colors.textSecondary,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final bool hasQuery = value.text.trim().isNotEmpty;
              return IconButton(
                tooltip: l10n.actionCancel,
                onPressed: hasQuery
                    ? () {
                        controller.clear();
                        focusNode.requestFocus();
                      }
                    : null,
                icon: Icon(
                  Icons.clear_rounded,
                  size: 18,
                  color: hasQuery
                      ? colors.textSecondary
                      : colors.textSecondary.withValues(alpha: 0),
                ),
              );
            },
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
