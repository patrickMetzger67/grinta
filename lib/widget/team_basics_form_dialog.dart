import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/teams_per_club.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/countries_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/club_picker_sheet.dart';
import 'package:grinta/widget/country_flag_image.dart';
import 'package:grinta/widget/equipe_picker_sheet.dart';
import 'package:provider/provider.dart';

/// Result of the shared create/edit team basics form.
class TeamBasicsFormResult {
  const TeamBasicsFormResult({
    required this.name,
    required this.soccerType,
    required this.country,
    this.clubAffiliation,
    this.selectedEquipes = const <Equipe>[],
  });

  final String name;
  final int soccerType;
  /// ISO country code (never empty; defaults to France).
  final String country;
  final String? clubAffiliation;
  final List<Equipe> selectedEquipes;
}

/// Opens the team basics form (name, soccer type, club, club teams/competitions).
Future<TeamBasicsFormResult?> showTeamBasicsFormDialog(
  BuildContext context, {
  required String title,
  required String submitLabel,
  String initialName = '',
  int initialSoccerType = 11,
  String? initialCountry,
  String? initialClubAffiliation,
  String? initialClubName,
  String? initialClubLogo,
  List<Equipe> initialEquipes = const <Equipe>[],
  bool warnIfNoClub = true,
}) {
  return showDialog<TeamBasicsFormResult>(
    context: context,
    builder: (dialogContext) => TeamBasicsFormDialog(
      title: title,
      submitLabel: submitLabel,
      initialName: initialName,
      initialSoccerType: initialSoccerType,
      initialCountry: initialCountry,
      initialClubAffiliation: initialClubAffiliation,
      initialClubName: initialClubName,
      initialClubLogo: initialClubLogo,
      initialEquipes: initialEquipes,
      warnIfNoClub: warnIfNoClub,
    ),
  );
}

class TeamBasicsFormDialog extends StatefulWidget {
  const TeamBasicsFormDialog({
    super.key,
    required this.title,
    required this.submitLabel,
    this.initialName = '',
    this.initialSoccerType = 11,
    this.initialCountry,
    this.initialClubAffiliation,
    this.initialClubName,
    this.initialClubLogo,
    this.initialEquipes = const <Equipe>[],
    this.warnIfNoClub = true,
  });

  final String title;
  final String submitLabel;
  final String initialName;
  final int initialSoccerType;
  final String? initialCountry;
  final String? initialClubAffiliation;
  final String? initialClubName;
  final String? initialClubLogo;
  final List<Equipe> initialEquipes;
  final bool warnIfNoClub;

  @override
  State<TeamBasicsFormDialog> createState() => _TeamBasicsFormDialogState();
}

class _TeamBasicsFormDialogState extends State<TeamBasicsFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  late bool _attachToClub;
  String? _selectedAffiliation;
  String? _selectedClubName;
  String? _selectedClubLogo;
  String? _clubValidationError;
  List<Equipe> _selectedEquipes = <Equipe>[];
  late int _selectedSoccerType;
  late String _selectedCountry;
  List<CountryDefinition> _availableCountries = const <CountryDefinition>[];
  bool _countriesLoading = true;
  String? _autoFilledTeamName;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _selectedSoccerType = widget.initialSoccerType;
    _selectedCountry =
        CountriesService.normalizeCountryCode(widget.initialCountry);
    final affiliation = widget.initialClubAffiliation?.trim();
    _attachToClub = affiliation != null && affiliation.isNotEmpty;
    _selectedAffiliation = _attachToClub ? affiliation : null;
    _selectedClubName = widget.initialClubName?.trim();
    _selectedClubLogo = widget.initialClubLogo?.trim();
    _selectedEquipes = List<Equipe>.from(widget.initialEquipes);
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    await CountriesService.instance.ensureInitialized();
    if (!mounted) return;
    final locale = Localizations.localeOf(context);
    final available =
        CountriesService.instance.availableSorted(locale);
    setState(() {
      _availableCountries = available;
      _countriesLoading = false;
      if (available.isEmpty) {
        _selectedCountry = kDefaultCountryCode;
        return;
      }
      final codes = available.map((c) => c.code).toSet();
      if (!codes.contains(_selectedCountry)) {
        _selectedCountry = codes.contains(kDefaultCountryCode)
            ? kDefaultCountryCode
            : available.first.code;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _clearAutoFilledTeamNameIfNeeded() {
    if (_autoFilledTeamName == null) return;
    if (_nameController.text.trim() == _autoFilledTeamName) {
      _nameController.text = '';
    }
    _autoFilledTeamName = null;
  }

  void _syncTeamNameFromEquipes(List<Equipe> equipes) {
    if (!_attachToClub || equipes.isEmpty) {
      _clearAutoFilledTeamNameIfNeeded();
      return;
    }

    final defaultName = equipes.first.name?.trim() ?? '';
    if (defaultName.isEmpty) return;

    final currentTrimmed = _nameController.text.trim();
    if (currentTrimmed.isEmpty ||
        (_autoFilledTeamName != null &&
            currentTrimmed == _autoFilledTeamName)) {
      _nameController.text = defaultName;
      _autoFilledTeamName = defaultName;
    }
  }

  String? _defaultNameFromSelectedEquipes() {
    if (!_attachToClub || _selectedEquipes.isEmpty) return null;
    final name = _selectedEquipes.first.name?.trim() ?? '';
    return name.isEmpty ? null : name;
  }

  Future<void> _pickClub() async {
    final club = await showClubPickerSheet(context);
    if (!mounted || club == null) return;
    setState(() {
      _selectedAffiliation = club.affiliation?.trim();
      _selectedClubName = club.name?.trim();
      _selectedClubLogo = club.logo?.trim();
      _selectedEquipes = <Equipe>[];
      _clubValidationError = null;
      _clearAutoFilledTeamNameIfNeeded();
    });
  }

  Future<void> _pickEquipes() async {
    final affiliation = _selectedAffiliation?.trim();
    final seasonId =
        context.read<AppSession>().selectedSeason?.ref?.id.trim();
    if (affiliation == null ||
        affiliation.isEmpty ||
        seasonId == null ||
        seasonId.isEmpty) {
      return;
    }

    final equipes = await showEquipePickerSheet(
      context,
      clubId: affiliation,
      seasonId: seasonId,
      initialSelection: _selectedEquipes,
    );
    if (!mounted || equipes == null) return;
    setState(() {
      _selectedEquipes = equipes;
      _syncTeamNameFromEquipes(equipes);
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    final l10n = context.l10n;

    if (_attachToClub &&
        (_selectedAffiliation == null || _selectedAffiliation!.isEmpty)) {
      setState(() {
        _clubValidationError = l10n.teamCreationClubRequired;
      });
      return;
    }

    final trimmedName = _nameController.text.trim();
    final resolvedName = trimmedName.isNotEmpty
        ? trimmedName
        : (_defaultNameFromSelectedEquipes() ?? '');

    if (resolvedName.isEmpty) {
      _formKey.currentState?.validate();
      return;
    }

    final hasClubLinked = _attachToClub &&
        _selectedAffiliation != null &&
        _selectedAffiliation!.trim().isNotEmpty;

    if (widget.warnIfNoClub && !hasClubLinked) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (warningContext) {
          final warningColors = warningContext.appColors;
          return AlertDialog(
            title: Text(l10n.teamCreationNoClubWarningTitle),
            content: Text(l10n.teamCreationNoClubWarning),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: warningColors.border),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(warningContext).pop(false),
                child: Text(l10n.actionCancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(warningContext).pop(true),
                child: Text(l10n.actionOk),
              ),
            ],
          );
        },
      );

      if (proceed != true || !mounted) return;
    }

    if (!mounted) return;
    Navigator.of(context).pop(
      TeamBasicsFormResult(
        name: resolvedName,
        soccerType: _selectedSoccerType,
        country: CountriesService.normalizeCountryCode(_selectedCountry),
        clubAffiliation: _attachToClub ? _selectedAffiliation : null,
        selectedEquipes:
            _attachToClub ? _selectedEquipes : const <Equipe>[],
      ),
    );
  }

  Widget _buildCountryDropdown(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);

    if (_countriesLoading) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.teamCreationSelectCountry,
        ),
        child: const SizedBox(
          height: 24,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    final items = _availableCountries;
    if (items.isEmpty) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.teamCreationSelectCountry,
        ),
        child: Text(
          CountriesService.instance
                  .byCode(kDefaultCountryCode)
                  ?.labelForLocale(locale) ??
              'France',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: _selectedCountry,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.teamCreationSelectCountry,
      ),
      selectedItemBuilder: (context) {
        return items.map((country) {
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              children: [
                CountryFlagImage(country: country),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    country.labelForLocale(locale),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      items: items
          .map(
            (country) => DropdownMenuItem<String>(
              value: country.code,
              child: Row(
                children: [
                  CountryFlagImage(country: country),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(country.labelForLocale(locale)),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          if (_selectedCountry != value) {
            _selectedCountry = value;
            _selectedAffiliation = null;
            _selectedClubName = null;
            _selectedClubLogo = null;
            _selectedEquipes = <Equipe>[];
            _clubValidationError = null;
            _clearAutoFilledTeamNameIfNeeded();
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.entityTeam,
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isNotEmpty) return null;
                      if (_defaultNameFromSelectedEquipes() != null) {
                        return null;
                      }
                      return l10n.hintRequiredField;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    // ignore: deprecated_member_use
                    value: _selectedSoccerType,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.teamCreationSoccerType,
                    ),
                    items: const <int>[5, 8, 11]
                        .map(
                          (value) => DropdownMenuItem<int>(
                            value: value,
                            child: Text('$value'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedSoccerType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.teamCreationAttachClubQuestion,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment<bool>(
                        value: false,
                        label: Text(l10n.actionNo),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text(l10n.actionYes),
                      ),
                    ],
                    selected: {_attachToClub},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _attachToClub = selection.first;
                        _clubValidationError = null;
                        if (!_attachToClub) {
                          _selectedAffiliation = null;
                          _selectedClubName = null;
                          _selectedClubLogo = null;
                          _selectedEquipes = <Equipe>[];
                          _clearAutoFilledTeamNameIfNeeded();
                        }
                      });
                    },
                  ),
                  if (_attachToClub) ...[
                    const SizedBox(height: 12),
                    _buildCountryDropdown(context),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickClub,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.teamCreationSelectClub,
                          errorText: _clubValidationError,
                          suffixIcon:
                              const Icon(Icons.arrow_drop_down_rounded),
                        ),
                        child: Row(
                          children: [
                            if (_selectedClubName != null) ...[
                              ClubLogo(url: _selectedClubLogo ?? ''),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Text(
                                _selectedClubName ??
                                    l10n.teamCreationSelectClub,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: _selectedClubName == null
                                          ? colors.textSecondary
                                          : colors.textPrimary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_selectedAffiliation != null &&
                        _selectedAffiliation!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _pickEquipes,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: l10n.teamCreationSelectClubTeams,
                            suffixIcon:
                                const Icon(Icons.arrow_drop_down_rounded),
                          ),
                          child: _selectedEquipes.isEmpty
                              ? Text(
                                  l10n.teamCreationSelectClubTeams,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.teamCreationSelectedClubTeamsCount(
                                        _selectedEquipes.length,
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: colors.textSecondary,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: _selectedEquipes
                                          .map(
                                            (equipe) => Chip(
                                              label: Text(
                                                equipe.name?.trim() ?? '',
                                              ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(widget.submitLabel),
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
    );
  }
}
