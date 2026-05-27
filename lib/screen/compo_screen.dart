import 'package:flutter/material.dart';

import '../model/compoType.dart';
import '../services/compoTypeService.dart';
import '../core/extensions/l10n_extension.dart';
import '../util/app_theme.dart';
import '../widget/half_pitch_compo_widget.dart';

class CompoScreen extends StatefulWidget {
  final int? soccerType;

  const CompoScreen({
    super.key,
    this.soccerType,
  });

  @override
  State<CompoScreen> createState() => _CompoScreenState();
}

class _CompoScreenState extends State<CompoScreen> {
  final CompoTypeService _compoTypeService = CompoTypeService();

  String? _selectedCompoTypeKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: StreamBuilder<List<CompoType>>(
          stream: _compoTypeService.streamCompoTypes(
            soccerType: widget.soccerType,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              final l10n = context.l10n;
              return _CompoStateMessage(
                icon: Icons.error_outline_rounded,
                title: l10n.errorCompoTitle,
                message: snapshot.error.toString(),
              );
            }

            final compoTypes = snapshot.data ?? <CompoType>[];

            if (compoTypes.isEmpty) {
              final l10n = context.l10n;
              return _CompoStateMessage(
                icon: Icons.sports_soccer_rounded,
                title: l10n.compoTypeEmptyTitle,
                message: l10n.emptyNoCompoType,
              );
            }

            final selectedCompoType = _resolveSelectedCompoType(compoTypes);
            final selectedKey = _compoTypeKey(selectedCompoType);

            return LayoutBuilder(
              builder: (context, constraints) {
                final bool isLarge = constraints.maxWidth >= 900;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isLarge ? 32 : 16,
                    16,
                    isLarge ? 32 : 16,
                    24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeaderCard(
                            selectedCompoType: selectedCompoType,
                          ),
                          const SizedBox(height: 16),

                          _CompoTypeDropdown(
                            compoTypes: compoTypes,
                            selectedKey: selectedKey,
                            onChanged: (value) {
                              if (value == null) return;

                              setState(() {
                                _selectedCompoTypeKey = value;
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          HalfPitchCompoWidget(
                            compoType: selectedCompoType,
                            selectedPlayers: const {},
                            onSlotTap: (slot) {
                              debugPrint(
                                'Sélection joueur pour slot=${slot.id} '
                                    'role=${slot.role} index=${slot.index}',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  CompoType _resolveSelectedCompoType(List<CompoType> compoTypes) {
    if (_selectedCompoTypeKey == null) {
      return compoTypes.first;
    }

    for (final compoType in compoTypes) {
      if (_compoTypeKey(compoType) == _selectedCompoTypeKey) {
        return compoType;
      }
    }

    return compoTypes.first;
  }

  String _compoTypeKey(CompoType compoType) {
    return compoType.ref?.path ?? compoType.name ?? '';
  }
}

class _HeaderCard extends StatelessWidget {
  final CompoType selectedCompoType;

  const _HeaderCard({
    required this.selectedCompoType,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.groups_rounded,
            color: colors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Composition',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _CompoSummaryPill(
            label: _formatCompoName(selectedCompoType),
          ),
        ],
      ),
    );
  }
}

class _CompoTypeDropdown extends StatelessWidget {
  final List<CompoType> compoTypes;
  final String selectedKey;
  final ValueChanged<String?> onChanged;

  const _CompoTypeDropdown({
    required this.compoTypes,
    required this.selectedKey,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedKey,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: context.l10n.hintCompoType,
          prefixIcon: Icon(
            Icons.tune_rounded,
            color: colors.primary,
          ),
          filled: true,
          fillColor: colors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: colors.primary,
              width: 1.4,
            ),
          ),
        ),
        items: compoTypes.map((compoType) {
          final key = compoType.ref?.path ?? compoType.name ?? '';

          return DropdownMenuItem<String>(
            value: key,
            child: Text(
              _formatCompoName(compoType),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _CompoSummaryPill extends StatelessWidget {
  final String label;

  const _CompoSummaryPill({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CompoStateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _CompoStateMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: colors.textSecondary,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatCompoName(CompoType compoType) {
  final name = compoType.name?.trim() ?? '';

  if (name.isNotEmpty) {
    return name;
  }

  final defender = compoType.defender ?? 0;
  final midfielder = compoType.midfielder ?? 0;
  final midfielderDefensive = compoType.midfielderDefensive ?? 0;
  final midfielderAttacking = compoType.midfielderAttacking ?? 0;
  final stricker = compoType.stricker ?? 0;

  final parts = <String>[
    if (defender > 0) '$defender',
    if (midfielderDefensive > 0) '$midfielderDefensive',
    if (midfielder > 0) '$midfielder',
    if (midfielderAttacking > 0) '$midfielderAttacking',
    if (stricker > 0) '$stricker',
  ];

  if (parts.isEmpty) {
    return 'Composition';
  }

  return parts.join('-');
}