part of 'team_param_screen.dart';

class _EditableSpeedZone {
  _EditableSpeedZone({
    required this.zoneIdController,
    required this.labelController,
    required this.minKmhController,
    required this.maxKmhController,
  });

  final TextEditingController zoneIdController;
  final TextEditingController labelController;
  final TextEditingController minKmhController;
  final TextEditingController maxKmhController;

  factory _EditableSpeedZone.fromModel(TeamSpeedZone zone) {
    return _EditableSpeedZone(
      zoneIdController: TextEditingController(text: zone.zoneId),
      labelController: TextEditingController(text: zone.label),
      minKmhController: TextEditingController(text: _fmt(zone.minKmh)),
      maxKmhController: TextEditingController(
        text: zone.maxKmh == null ? '' : _fmt(zone.maxKmh!),
      ),
    );
  }

  void dispose() {
    zoneIdController.dispose();
    labelController.dispose();
    minKmhController.dispose();
    maxKmhController.dispose();
  }

  static String _fmt(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.headerAction,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? headerAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: colors.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (headerAction != null) headerAction!,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _ResponsiveFieldsWrap extends StatelessWidget {
  const _ResponsiveFieldsWrap({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth =
        constraints.maxWidth < 700 ? constraints.maxWidth : (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: children
              .map(
                (child) => SizedBox(
              width: itemWidth,
              child: child,
            ),
          )
              .toList(),
        );
      },
    );
  }
}

class _ParamField extends StatelessWidget {
  const _ParamField({
    required this.controller,
    required this.label,
    this.hintText,
    this.suffixText,
    this.isInteger = false,
    this.isRequired = false,
    this.enabled = true,
    this.isNumeric = true,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final String? suffixText;
  final bool isInteger;
  final bool isRequired;
  final bool enabled;
  final bool isNumeric;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: isNumeric
          ? TextInputType.numberWithOptions(
        decimal: !isInteger,
        signed: false,
      )
          : TextInputType.text,
      validator: enabled
          ? (value) {
        final text = (value ?? '').trim();

        if (text.isEmpty) {
          return isRequired ? l10n.hintRequiredField : null;
        }

        if (!isNumeric) {
          return null;
        }

        if (isInteger) {
          if (int.tryParse(text) == null) {
            return l10n.teamParamsInvalidInteger;
          }
          return null;
        }

        final parsed = double.tryParse(text.replaceAll(',', '.'));

        if (parsed == null) {
          return l10n.teamParamsInvalidNumber;
        }

        return null;
      }
          : null,
      style: TextStyle(
        color: enabled ? colors.textPrimary : colors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        suffixText: suffixText,
        filled: true,
        fillColor: enabled
            ? colors.surface.withValues(alpha: 0.55)
            : colors.background.withValues(alpha: 0.55),
        labelStyle: TextStyle(
          color: enabled ? colors.textSecondary : colors.textSecondary,
        ),
        suffixStyle: TextStyle(
          color: enabled ? colors.textSecondary : colors.textSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.border),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colors.border.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF232A3B),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: const Color(0xFFFFB27A),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}