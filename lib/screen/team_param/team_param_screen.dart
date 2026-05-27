import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/services/teamParamService.dart';
import '../../util/app_theme.dart';

import '../../model/teamParam.dart';

part 'team_param_widgets.dart';

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

  String _teamName(BuildContext context) {
    final value = (widget.team.name ?? '').trim();
    return value.isEmpty ? context.l10n.entityTeam : value;
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

      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorTeamParamsLoad(e.toString())),
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
        SnackBar(
          content: Text(context.l10n.errorSaveTeamIdEmpty),
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
        SnackBar(
          content: Text(context.l10n.successSettingsSaved),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.errorSaving(e.toString())),
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
        SnackBar(
          content: Text(context.l10n.teamParamsAddSpeedZone),
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
              context.l10n.teamParamsZoneMaxGreaterThanMin(label),
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
          SnackBar(
            content: Text(context.l10n.teamParamsOnlyLastZoneEmptyMax),
          ),
        );
        return null;
      }

      if (current.maxKmh! > next.minKmh) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.teamParamsZonesOverlap(current.label, next.label),
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
      SnackBar(
        content: Text(context.l10n.successDefaultsLoaded),
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

        final dialogL10n = dialogContext.l10n;
        return AlertDialog(
          backgroundColor: colors.card,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colors.border),
          ),
          title: Text(
            dialogL10n.dialogDeleteCustomizationTitle,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            dialogL10n.teamParamsDeleteCustomizationBody,
            style: TextStyle(
              color: colors.textSecondary,
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(dialogL10n.actionCancel),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: colors.danger,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(dialogL10n.actionDelete),
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
        SnackBar(
          content: Text(context.l10n.teamParamsCustomizationRemoved),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.errorGeneric(e.toString())),
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
        SnackBar(
          content: Text(context.l10n.teamParamsMinOneZone),
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
    final l10n = context.l10n;
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
                      l10n.teamParamsPerformanceTitle,
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
                        _HeaderChip(label: _teamName(context)),
                        _HeaderChip(
                          label: _hasCustomParams
                              ? l10n.teamParamsCustomThresholds
                              : l10n.teamParamsDefaultThresholds,
                        ),
                        if (!_canEdit) _HeaderChip(label: l10n.infoReadOnly),
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
                              l10n.teamParamsBackToTeam,
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
                        label: Text(l10n.actionDefaultValues),
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
                          label: Text(l10n.actionRemoveCustomization),
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
                          _saving ? l10n.actionSaving : l10n.actionSave,
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
    final l10n = context.l10n;
    return _SectionCard(
      title: l10n.teamParamsSpeedSprints,
      icon: Icons.speed_rounded,
      child: _ResponsiveFieldsWrap(
        children: [
          _ParamField(
            controller: _sprintThresholdKmhCtrl,
            label: l10n.teamParamsSprintThreshold,
            suffixText: 'km/h',
            isRequired: true,
            enabled: _canEdit,
          ),
          _ParamField(
            controller: _minSprintAccelerationMps2Ctrl,
            label: l10n.teamParamsSprintMinAccel,
            suffixText: 'm/s²',
            isRequired: true,
            enabled: _canEdit,
          ),
          _ParamField(
            controller: _sprintMinDurationMsCtrl,
            label: l10n.teamParamsSprintMinDuration,
            suffixText: 'ms',
            isInteger: true,
            isRequired: true,
            enabled: _canEdit,
          ),
          _ParamField(
            controller: _validatedSpeedMinDurationMsCtrl,
            label: l10n.teamParamsSpeedMinDuration,
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
    final l10n = context.l10n;
    return _SectionCard(
      title: l10n.teamParamsIntensity,
      icon: Icons.flash_on_rounded,
      child: _ResponsiveFieldsWrap(
        children: [
          _ParamField(
            controller: _highAccelerationThresholdMps2Ctrl,
            label: l10n.teamParamsHighAccelThreshold,
            suffixText: 'm/s²',
            isRequired: true,
            enabled: _canEdit,
          ),
          _ParamField(
            controller: _highAccelerationMinDurationMsCtrl,
            label: l10n.teamParamsHighAccelMinDuration,
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
    final l10n = context.l10n;
    return _SectionCard(
      title: l10n.teamParamsGpsTimeline,
      icon: Icons.tune_rounded,
      child: _ResponsiveFieldsWrap(
        children: [
          _ParamField(
            controller: _maxAcceptedStepDistanceMetersCtrl,
            label: l10n.teamParamsMaxStepDistance,
            suffixText: 'm',
            isRequired: true,
            enabled: _canEdit,
          ),
          _ParamField(
            controller: _maxPlausibleSpeedMpsCtrl,
            label: l10n.teamParamsMaxPlausibleSpeed,
            suffixText: 'm/s',
            isRequired: true,
            enabled: _canEdit,
          ),
          _ParamField(
            controller: _maxPlausibleAccelerationMps2Ctrl,
            label: l10n.teamParamsMaxPlausibleAccel,
            suffixText: 'm/s²',
            isRequired: true,
            enabled: _canEdit,
          ),
          _ParamField(
            controller: _minDtMsCtrl,
            label: l10n.teamParamsMinDeltaTime,
            suffixText: 'ms',
            isInteger: true,
            isRequired: true,
            enabled: _canEdit,
          ),
          _ParamField(
            controller: _maxDtMsCtrl,
            label: l10n.teamParamsMaxDeltaTime,
            suffixText: 'ms',
            isInteger: true,
            isRequired: true,
            enabled: _canEdit,
          ),
          _ParamField(
            controller: _smoothingWindowCtrl,
            label: l10n.teamParamsSmoothingWindow,
            isInteger: true,
            isRequired: true,
            enabled: _canEdit,
          ),
          _ParamField(
            controller: _timelineBucketMsCtrl,
            label: l10n.teamParamsTimelineBucket,
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
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return _SectionCard(
      title: l10n.teamParamsSpeedZones,
      icon: Icons.stacked_line_chart_rounded,
      headerAction: _canEdit
          ? FilledButton.icon(
        onPressed: _addZone,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.actionAddZone),
      )
          : null,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _canEdit
                  ? l10n.teamParamsCustomizeZonesHint
                  : l10n.teamParamsZonesReadOnly,
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
    final l10n = context.l10n;
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
                  l10n.teamParamsZoneTitle(index + 1),
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
                label: l10n.entityCode,
                isRequired: true,
                enabled: _canEdit,
                isNumeric: false,
              ),
              _ParamField(
                controller: zone.labelController,
                label: l10n.entityLabel,
                isRequired: true,
                enabled: _canEdit,
                isNumeric: false,
              ),
              _ParamField(
                controller: zone.minKmhController,
                label: l10n.entityMinSpeed,
                suffixText: 'km/h',
                isRequired: true,
                enabled: _canEdit,
              ),
              _ParamField(
                controller: zone.maxKmhController,
                label: l10n.entityMaxSpeed,
                suffixText: 'km/h',
                hintText: l10n.hintSpeedZoneMaxEmpty,
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
