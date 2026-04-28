import 'package:flutter/material.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/services/teamParamService.dart';
import 'package:grinta/util/app_theme.dart';

import '../model/teamParam.dart';

class TeamParamScreen extends StatefulWidget {
  const TeamParamScreen({
    super.key,
    required this.team,
    this.isManager = false,
  });

  final Team team;
  final bool isManager;

  @override
  State<TeamParamScreen> createState() => _TeamParamScreenState();
}

class _TeamParamScreenState extends State<TeamParamScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _sprintThresholdKmhCtrl = TextEditingController();
  final TextEditingController _minSprintAccelerationMps2Ctrl =
  TextEditingController();
  final TextEditingController _maxAcceptedStepDistanceMetersCtrl =
  TextEditingController();

  final TextEditingController _sprintMinDurationMsCtrl =
  TextEditingController();
  final TextEditingController _highAccelerationThresholdMps2Ctrl =
  TextEditingController();
  final TextEditingController _highAccelerationMinDurationMsCtrl =
  TextEditingController();

  final TextEditingController _maxPlausibleSpeedMpsCtrl =
  TextEditingController();
  final TextEditingController _maxPlausibleAccelerationMps2Ctrl =
  TextEditingController();

  final TextEditingController _minDtMsCtrl = TextEditingController();
  final TextEditingController _maxDtMsCtrl = TextEditingController();
  final TextEditingController _smoothingWindowCtrl = TextEditingController();
  final TextEditingController _validatedSpeedMinDurationMsCtrl =
  TextEditingController();
  final TextEditingController _timelineBucketMsCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _hasCustomParams = false;

  TeamParam? _defaultParams;
  final List<_EditableSpeedZone> _zones = [];

  bool get _canEdit => widget.isManager;

  String get _teamId => (widget.team.keyTeam ?? '').trim();

  String get _teamName {
    final value = (widget.team.name ?? '').trim();
    return value.isEmpty ? 'Équipe' : value;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _sprintThresholdKmhCtrl.dispose();
    _minSprintAccelerationMps2Ctrl.dispose();
    _maxAcceptedStepDistanceMetersCtrl.dispose();
    _sprintMinDurationMsCtrl.dispose();
    _highAccelerationThresholdMps2Ctrl.dispose();
    _highAccelerationMinDurationMsCtrl.dispose();
    _maxPlausibleSpeedMpsCtrl.dispose();
    _maxPlausibleAccelerationMps2Ctrl.dispose();
    _minDtMsCtrl.dispose();
    _maxDtMsCtrl.dispose();
    _smoothingWindowCtrl.dispose();
    _validatedSpeedMinDurationMsCtrl.dispose();
    _timelineBucketMsCtrl.dispose();

    for (final zone in _zones) {
      zone.dispose();
    }

    super.dispose();
  }

  Future<void> _load() async {
    try {
      await TeamParamService.ensureDefaultParams();

      final TeamParam effectiveParam =
      await TeamParamService.getEffectiveTeamParam(_teamId);

      final TeamParam? customParam =
      await TeamParamService.getTeamParamByTeamId(_teamId);

      final TeamParam? defaultParam =
      await TeamParamService.getTeamParamByTeamId(TeamParam.defaultTeamId);

      _defaultParams = defaultParam ?? TeamParam.defaultConfig();

      _fillForm(effectiveParam);

      if (!mounted) return;

      setState(() {
        _hasCustomParams =
            customParam != null && _teamId != TeamParam.defaultTeamId;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement des paramètres : $e'),
        ),
      );
    }
  }

  void _fillForm(TeamParam params) {
    _sprintThresholdKmhCtrl.text = _formatDouble(params.sprintThresholdKmh);
    _minSprintAccelerationMps2Ctrl.text =
        _formatDouble(params.minSprintAccelerationMps2);
    _maxAcceptedStepDistanceMetersCtrl.text =
        _formatDouble(params.maxAcceptedStepDistanceMeters);

    _sprintMinDurationMsCtrl.text = params.sprintMinDurationMs.toString();
    _highAccelerationThresholdMps2Ctrl.text =
        _formatDouble(params.highAccelerationThresholdMps2);
    _highAccelerationMinDurationMsCtrl.text =
        params.highAccelerationMinDurationMs.toString();

    _maxPlausibleSpeedMpsCtrl.text =
        _formatDouble(params.maxPlausibleSpeedMps);
    _maxPlausibleAccelerationMps2Ctrl.text =
        _formatDouble(params.maxPlausibleAccelerationMps2);

    _minDtMsCtrl.text = params.minDtMs.toString();
    _maxDtMsCtrl.text = params.maxDtMs.toString();
    _smoothingWindowCtrl.text = params.smoothingWindow.toString();
    _validatedSpeedMinDurationMsCtrl.text =
        params.validatedSpeedMinDurationMs.toString();
    _timelineBucketMsCtrl.text = params.timelineBucketMs.toString();

    for (final zone in _zones) {
      zone.dispose();
    }

    _zones.clear();

    final orderedZones = params.orderedSpeedZones;

    for (final zone in orderedZones) {
      _zones.add(_EditableSpeedZone.fromModel(zone));
    }
  }

  Future<void> _save() async {
    if (!_canEdit) return;

    if (_teamId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de sauvegarder : teamId vide.'),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final builtZones = _buildZones();
    if (builtZones == null) return;

    setState(() {
      _saving = true;
    });

    try {
      final param = TeamParam(
        teamId: _teamId,
        sprintThresholdKmh: _parseDouble(_sprintThresholdKmhCtrl.text),
        minSprintAccelerationMps2:
        _parseDouble(_minSprintAccelerationMps2Ctrl.text),
        maxAcceptedStepDistanceMeters:
        _parseDouble(_maxAcceptedStepDistanceMetersCtrl.text),
        sprintMinDurationMs: _parseInt(_sprintMinDurationMsCtrl.text),
        highAccelerationThresholdMps2:
        _parseDouble(_highAccelerationThresholdMps2Ctrl.text),
        highAccelerationMinDurationMs:
        _parseInt(_highAccelerationMinDurationMsCtrl.text),
        maxPlausibleSpeedMps: _parseDouble(_maxPlausibleSpeedMpsCtrl.text),
        maxPlausibleAccelerationMps2:
        _parseDouble(_maxPlausibleAccelerationMps2Ctrl.text),
        minDtMs: _parseInt(_minDtMsCtrl.text),
        maxDtMs: _parseInt(_maxDtMsCtrl.text),
        smoothingWindow: _parseInt(_smoothingWindowCtrl.text),
        validatedSpeedMinDurationMs:
        _parseInt(_validatedSpeedMinDurationMsCtrl.text),
        timelineBucketMs: _parseInt(_timelineBucketMsCtrl.text),
        speedZones: builtZones,
      );

      await TeamParamService.saveTeamParam(param);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paramètres enregistrés avec succès.'),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l’enregistrement : $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  List<TeamSpeedZone>? _buildZones() {
    if (_zones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoute au moins une zone de vitesse.'),
        ),
      );
      return null;
    }

    final List<TeamSpeedZone> result = [];

    for (int i = 0; i < _zones.length; i++) {
      final zone = _zones[i];

      final String zoneId = zone.zoneIdController.text.trim().isEmpty
          ? 'Z${i + 1}'
          : zone.zoneIdController.text.trim();

      final String label = zone.labelController.text.trim().isEmpty
          ? 'Zone ${i + 1}'
          : zone.labelController.text.trim();

      final double minKmh = _parseDouble(zone.minKmhController.text);
      final String maxRaw = zone.maxKmhController.text.trim();
      final double? maxKmh = maxRaw.isEmpty ? null : _parseDouble(maxRaw);

      if (maxKmh != null && maxKmh <= minKmh) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'La zone "$label" doit avoir une borne max supérieure à la borne min.',
            ),
          ),
        );
        return null;
      }

      result.add(
        TeamSpeedZone(
          zoneId: zoneId,
          label: label,
          minKmh: minKmh,
          maxKmh: maxKmh,
        ),
      );
    }

    result.sort((a, b) => a.minKmh.compareTo(b.minKmh));

    for (int i = 0; i < result.length - 1; i++) {
      final current = result[i];
      final next = result[i + 1];

      if (current.maxKmh == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Seule la dernière zone peut avoir une borne max vide.',
            ),
          ),
        );
        return null;
      }

      if (current.maxKmh! > next.minKmh) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Les zones "${current.label}" et "${next.label}" se chevauchent.',
            ),
          ),
        );
        return null;
      }
    }

    return result;
  }

  Future<void> _restoreDefaultValues() async {
    if (!_canEdit) return;

    final TeamParam defaults = _defaultParams ?? TeamParam.defaultConfig();

    _fillForm(defaults);

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Valeurs par défaut chargées dans le formulaire.'),
      ),
    );
  }

  Future<void> _deleteCustomParams() async {
    if (!_canEdit) return;

    if (_teamId.isEmpty ||
        _teamId == TeamParam.defaultTeamId ||
        !_hasCustomParams) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = dialogContext.appColors;

        return AlertDialog(
          backgroundColor: colors.card,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colors.border),
          ),
          title: Text(
            'Supprimer la personnalisation ?',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Les paramètres spécifiques de cette équipe seront supprimés. '
                'L’équipe utilisera alors les paramètres par défaut.',
            style: TextStyle(
              color: colors.textSecondary,
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: colors.danger,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await TeamParamService.deleteTeamParam(_teamId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Personnalisation supprimée. Les paramètres par défaut seront utilisés.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
        ),
      );
    }
  }

  void _addZone() {
    if (!_canEdit) return;

    setState(() {
      final index = _zones.length + 1;

      _zones.add(
        _EditableSpeedZone(
          zoneIdController: TextEditingController(text: 'Z$index'),
          labelController: TextEditingController(text: 'Zone $index'),
          minKmhController: TextEditingController(text: '0'),
          maxKmhController: TextEditingController(),
        ),
      );
    });
  }

  void _removeZone(int index) {
    if (!_canEdit) return;

    if (_zones.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Il faut conserver au moins une zone.'),
        ),
      );
      return;
    }

    setState(() {
      _zones[index].dispose();
      _zones.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: _loading
            ? Center(
          child: CircularProgressIndicator(
            color: colors.primary,
          ),
        )
            : Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildSpeedSection(context),
                const SizedBox(height: 24),
                _buildIntensitySection(context),
                const SizedBox(height: 24),
                _buildGpsSection(context),
                const SizedBox(height: 24),
                _buildZonesSection(context),
                const SizedBox(height: 24),
                _buildBottomActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildHeader(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: <Color>[
            colors.primary,
            colors.secondary.withValues(alpha: 0.9),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.secondary.withValues(alpha: 0.20),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool stacked = constraints.maxWidth < 980;

          return Flex(
            direction: stacked ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: stacked ? 0 : 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paramètres performance',
                      style: textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _HeaderChip(label: _teamName),
                        _HeaderChip(
                          label: _hasCustomParams
                              ? 'Seuils personnalisés'
                              : 'Seuils par défaut',
                        ),
                        if (!_canEdit) const _HeaderChip(label: 'Lecture seule'),
                      ],
                    ),
                    const SizedBox(height: 18),
                    InkWell(
                      onTap: () => Navigator.of(context).maybePop(),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Retour à l’équipe',
                              style: textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: stacked ? 0 : 24, height: stacked ? 20 : 0),
              Expanded(
                flex: stacked ? 0 : 4,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: stacked ? WrapAlignment.start : WrapAlignment.end,
                  children: [
                    if (_canEdit) ...[
                      OutlinedButton.icon(
                        onPressed: _saving ? null : _restoreDefaultValues,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                        ),
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: const Text('Valeurs par défaut'),
                      ),
                      if (_hasCustomParams)
                        FilledButton.icon(
                          onPressed: _saving ? null : _deleteCustomParams,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF232A3B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Supprimer la personnalisation'),
                        ),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF232A3B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                        ),
                        icon: _saving
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          _saving ? 'Enregistrement...' : 'Enregistrer',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSpeedSection(BuildContext context) {
    return _SectionCard(
      title: 'Vitesse & sprints',
      icon: Icons.speed_rounded,
      child: _ResponsiveFieldsWrap(
        children: [
          _ParamField(
            controller: _sprintThresholdKmhCtrl,
            label: 'Seuil sprint (km/h)',
            suffixText: 'km/h',
            isRequired: true,
            enabled: _canEdit,
          ),
          _ParamField(
            controller: _minSprintAccelerationMps2Ctrl,
            label: 'Accélération mini pour sprint',
            suffixText: 'm/s²',
            isRequired: true,
            enabled: _canEdit,
          ),
          _ParamField(
            controller: _sprintMinDurationMsCtrl,
            label: 'Durée mini sprint',
            suffixText: 'ms',
            isInteger: true,
            isRequired: true,
            enabled: _canEdit,
          ),
          _ParamField(
            controller: _validatedSpeedMinDurationMsCtrl,
            label: 'Durée mini vitesse validée',
            suffixText: 'ms',
            isInteger: true,
            isRequired: true,
            enabled: _canEdit,
          ),
        ],
      ),
    );
  }

  Widget _buildIntensitySection(BuildContext context) {
    return _SectionCard(
      title: 'Intensité',
      icon: Icons.flash_on_rounded,
      child: _ResponsiveFieldsWrap(
        children: [
          _ParamField(
            controller: _highAccelerationThresholdMps2Ctrl,
            label: 'Seuil forte accélération',
            suffixText: 'm/s²',
            isRequired: true,
            enabled: _canEdit,
          ),
          _ParamField(
            controller: _highAccelerationMinDurationMsCtrl,
            label: 'Durée mini forte accélération',
            suffixText: 'ms',
            isInteger: true,
            isRequired: true,
            enabled: _canEdit,
          ),
        ],
      ),
    );
  }

  Widget _buildGpsSection(BuildContext context) {
    return _SectionCard(
      title: 'GPS / validation / timeline',
      icon: Icons.tune_rounded,
      child: _ResponsiveFieldsWrap(
        children: [
          _ParamField(
            controller: _maxAcceptedStepDistanceMetersCtrl,
            label: 'Distance max acceptée par pas',
            suffixText: 'm',
            isRequired: true,
            enabled: _canEdit,
          ),
          _ParamField(
            controller: _maxPlausibleSpeedMpsCtrl,
            label: 'Vitesse max plausible',
            suffixText: 'm/s',
            isRequired: true,
            enabled: _canEdit,
          ),
          _ParamField(
            controller: _maxPlausibleAccelerationMps2Ctrl,
            label: 'Accélération max plausible',
            suffixText: 'm/s²',
            isRequired: true,
            enabled: _canEdit,
          ),
          _ParamField(
            controller: _minDtMsCtrl,
            label: 'Delta temps mini',
            suffixText: 'ms',
            isInteger: true,
            isRequired: true,
            enabled: _canEdit,
          ),
          _ParamField(
            controller: _maxDtMsCtrl,
            label: 'Delta temps maxi',
            suffixText: 'ms',
            isInteger: true,
            isRequired: true,
            enabled: _canEdit,
          ),
          _ParamField(
            controller: _smoothingWindowCtrl,
            label: 'Fenêtre de lissage',
            isInteger: true,
            isRequired: true,
            enabled: _canEdit,
          ),
          _ParamField(
            controller: _timelineBucketMsCtrl,
            label: 'Bucket timeline',
            suffixText: 'ms',
            isInteger: true,
            isRequired: true,
            enabled: _canEdit,
          ),
        ],
      ),
    );
  }

  Widget _buildZonesSection(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return _SectionCard(
      title: 'Zones de vitesse',
      icon: Icons.stacked_line_chart_rounded,
      headerAction: _canEdit
          ? FilledButton.icon(
        onPressed: _addZone,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter une zone'),
      )
          : null,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _canEdit
                  ? 'Tu peux personnaliser librement les zones utilisées pour le calcul du temps passé dans chaque zone.'
                  : 'Consultation seule : les zones de vitesse ne sont pas modifiables.',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          ...List.generate(
            _zones.length,
                (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildZoneCard(context, _zones[index], index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneCard(
      BuildContext context,
      _EditableSpeedZone zone,
      int index,
      ) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Zone ${index + 1}',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_canEdit)
                IconButton(
                  onPressed: () => _removeZone(index),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: colors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _ResponsiveFieldsWrap(
            children: [
              _ParamField(
                controller: zone.zoneIdController,
                label: 'Code',
                isRequired: true,
                enabled: _canEdit,
                isNumeric: false,
              ),
              _ParamField(
                controller: zone.labelController,
                label: 'Libellé',
                isRequired: true,
                enabled: _canEdit,
                isNumeric: false,
              ),
              _ParamField(
                controller: zone.minKmhController,
                label: 'Vitesse min',
                suffixText: 'km/h',
                isRequired: true,
                enabled: _canEdit,
              ),
              _ParamField(
                controller: zone.maxKmhController,
                label: 'Vitesse max',
                suffixText: 'km/h',
                hintText: 'Laisser vide pour la dernière zone',
                enabled: _canEdit,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
            icon: Icon(
              _canEdit ? Icons.close_rounded : Icons.arrow_back_rounded,
            ),
            label: Text(_canEdit ? 'Annuler' : 'Retour'),
          ),
          if (_canEdit)
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.save_rounded),
              label: Text(_saving ? 'Enregistrement...' : 'Enregistrer'),
            ),
        ],
      ),
    );
  }

  int _parseInt(String value) {
    return int.tryParse(value.trim()) ?? 0;
  }

  double _parseDouble(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0.0;
  }

  String _formatDouble(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}

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
          return isRequired ? 'Champ requis' : null;
        }

        if (!isNumeric) {
          return null;
        }

        if (isInteger) {
          if (int.tryParse(text) == null) {
            return 'Valeur entière invalide';
          }
          return null;
        }

        final parsed = double.tryParse(text.replaceAll(',', '.'));

        if (parsed == null) {
          return 'Valeur numérique invalide';
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