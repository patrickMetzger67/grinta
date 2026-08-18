import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/match_video.dart';
import 'package:grinta/util/app_theme.dart';

class DebugVideoKitColorRow extends StatelessWidget {
  const DebugVideoKitColorRow({
    super.key,
    required this.team1Name,
    required this.team2Name,
    required this.team1Color,
    required this.team2Color,
    required this.refereeColor,
    required this.onTeam1Color,
    required this.onTeam2Color,
    required this.onRefereeColor,
  });

  final String team1Name;
  final String team2Name;
  final int? team1Color;
  final int? team2Color;
  final int? refereeColor;
  final ValueChanged<int> onTeam1Color;
  final ValueChanged<int> onTeam2Color;
  final ValueChanged<int> onRefereeColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        _KitColorTile(
          title: l10n.debugVideoTeamKitColor(team1Name),
          color: team1Color,
          onColor: onTeam1Color,
        ),
        const SizedBox(height: 8),
        _KitColorTile(
          title: l10n.debugVideoTeamKitColor(team2Name),
          color: team2Color,
          onColor: onTeam2Color,
        ),
        const SizedBox(height: 8),
        _KitColorTile(
          title: l10n.debugVideoRefereeKitColor,
          color: refereeColor,
          onColor: onRefereeColor,
        ),
      ],
    );
  }
}

class _KitColorTile extends StatelessWidget {
  const _KitColorTile({
    required this.title,
    required this.color,
    required this.onColor,
  });

  final String title;
  final int? color;
  final ValueChanged<int> onColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colors.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _pickColor(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _KitSwatch(color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      l10n.debugVideoPickKitColor,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickColor(BuildContext context) async {
    final picked = await showDebugVideoKitColorPicker(
      context,
      selected: color,
    );
    if (picked != null) onColor(picked);
  }
}

class _KitSwatch extends StatelessWidget {
  const _KitSwatch({required this.color});

  final int? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color == null ? colors.card : Color(color!),
        shape: BoxShape.circle,
        border: Border.all(color: colors.border, width: 1.5),
      ),
      child: color == null
          ? Icon(Icons.palette_outlined, size: 16, color: colors.textSecondary)
          : null,
    );
  }
}

Future<int?> showDebugVideoKitColorPicker(
  BuildContext context, {
  int? selected,
}) {
  final l10n = context.l10n;
  return showDialog<int>(
    context: context,
    builder: (dialogContext) {
      final colors = dialogContext.appColors;
      return AlertDialog(
        title: Text(l10n.debugVideoPickKitColor),
        content: SizedBox(
          width: 320,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: kMatchVideoKitColorPresets.map((preset) {
              final isSelected = selected == preset;
              return InkWell(
                onTap: () => Navigator.of(dialogContext).pop(preset),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(preset),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? colors.primary : colors.border,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    },
  );
}
