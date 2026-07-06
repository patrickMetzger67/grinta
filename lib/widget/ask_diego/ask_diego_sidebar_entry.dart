import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/ask_diego/ask_diego_access.dart';
import 'package:grinta/widget/ask_diego/ask_diego_avatar.dart';

/// Web sidebar tile for Ask Diego (premium-gated).
class AskDiegoSidebarEntry extends StatefulWidget {
  const AskDiegoSidebarEntry({
    super.key,
    required this.collapsed,
    this.itemHeight = 48,
  });

  final bool collapsed;
  final double itemHeight;

  @override
  State<AskDiegoSidebarEntry> createState() => _AskDiegoSidebarEntryState();
}

class _AskDiegoSidebarEntryState extends State<AskDiegoSidebarEntry> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => openAskDiegoFromTap(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            height: widget.itemHeight,
            padding: EdgeInsets.symmetric(
              horizontal: widget.collapsed ? 0 : 14,
            ),
            decoration: BoxDecoration(
              color: _hovered ? colors.card : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: widget.collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                AskDiegoAvatar(size: widget.collapsed ? 22 : 26),
                if (!widget.collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.askDiegoTitle,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
