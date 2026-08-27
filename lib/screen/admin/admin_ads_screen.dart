import 'dart:async' show unawaited;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/shop_ad.dart';
import 'package:grinta/services/eshop_config_service.dart';
import 'package:grinta/services/shop_ads_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/shop_ad_logic.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class AdminAdsScreen extends StatefulWidget {
  const AdminAdsScreen({super.key});

  @override
  State<AdminAdsScreen> createState() => _AdminAdsScreenState();
}

class _AdminAdsScreenState extends State<AdminAdsScreen> {
  final EshopConfigService _config = EshopConfigService.instance;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    unawaited(_config.ensureInitialized());
  }

  Future<void> _setAdsEnabled(bool enabled) async {
    if (_toggling) return;
    setState(() => _toggling = true);
    final l10n = context.l10n;
    try {
      await _config.saveShopAdsEnabled(enabled);
      if (!mounted) return;
      AppSnackbar.show(context, l10n.adminAdsSaved, isError: false);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('permission-denied')
          ? l10n.adminAdsPermissionDenied
          : l10n.adminAdsSaveFailed;
      AppSnackbar.show(context, message);
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _openEditor({ShopAd? existing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _AdFormSheet(existing: existing),
    );
  }

  Future<void> _confirmDelete(ShopAd ad) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.adminAdsDeleteTitle),
        content: Text(l10n.adminAdsDeleteMessage(ad.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.adminAdsDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ShopAdsService.instance.delete(ad.id);
      if (!mounted) return;
      AppSnackbar.show(context, l10n.adminAdsSaved, isError: false);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, l10n.adminAdsSaveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.adminAdsTitle,
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: Text(l10n.adminAdsAdd),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Text(
            l10n.adminAdsSubtitle,
            style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 16),
          ListenableBuilder(
            listenable: _config,
            builder: (context, _) {
              return Material(
                color: colors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colors.border),
                ),
                child: SwitchListTile(
                  title: Text(
                    l10n.adminAdsEnabledLabel,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(l10n.adminAdsEnabledSubtitle),
                  value: _config.shopAdsEnabled,
                  onChanged: _toggling ? null : _setAdsEnabled,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<ShopAd>>(
            stream: ShopAdsService.instance.watchAll(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    l10n.adminAdsLoadError,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final ads = snapshot.data!;
              if (ads.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    l10n.adminAdsListEmpty,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < ads.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _AdTile(
                      ad: ads[i],
                      onEdit: () => _openEditor(existing: ads[i]),
                      onDelete: () => _confirmDelete(ads[i]),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdTile extends StatelessWidget {
  const _AdTile({
    required this.ad,
    required this.onEdit,
    required this.onDelete,
  });

  final ShopAd ad;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final current = shopAdIsCurrent(
      startDate: ad.startDate,
      endDate: ad.endDate,
      now: now,
    );
    final upcoming =
        ad.startDate != null && now.isBefore(ad.startDate!);
    final badge = current
        ? l10n.adminAdsCurrentBadge
        : upcoming
            ? l10n.adminAdsUpcomingBadge
            : l10n.adminAdsExpiredBadge;
    final dateFmt = DateFormat.yMMMd(Localizations.localeOf(context).toString());

    return Material(
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AdThumb(imageUrl: ad.resolvedImageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.name,
                    style: textTheme.titleSmall?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    adminAdsTargetLabel(l10n, ad.target),
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (ad.startDate != null) dateFmt.format(ad.startDate!),
                      if (ad.endDate != null) dateFmt.format(ad.endDate!),
                    ].join(' → '),
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.adminAdsStats(ad.nbDisplay, ad.nbClicks),
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge,
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.adminAdsEdit,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: l10n.adminAdsDelete,
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, color: colors.danger),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdThumb extends StatelessWidget {
  const _AdThumb({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 64,
        height: 64,
        child: imageUrl == null
            ? ColoredBox(
                color: colors.background,
                child: Icon(Icons.image_outlined, color: colors.textSecondary),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => ColoredBox(
                  color: colors.background,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: colors.textSecondary,
                  ),
                ),
              ),
      ),
    );
  }
}

class _AdFormSheet extends StatefulWidget {
  const _AdFormSheet({this.existing});

  final ShopAd? existing;

  @override
  State<_AdFormSheet> createState() => _AdFormSheetState();
}

class _AdFormSheetState extends State<_AdFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  late ShopAdTarget _target;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _imageUrl;
  String? _storagePath;
  Uint8List? _pendingBytes;
  String _pendingExt = 'jpg';
  String _pendingContentType = 'image/jpeg';
  bool _saving = false;
  String? _nameError;
  String? _urlError;
  String? _datesError;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _urlController = TextEditingController(text: existing?.url ?? '');
    _target = existing?.target ?? ShopAdTarget.all;
    _startDate = existing?.startDate;
    _endDate = existing?.endDate;
    _imageUrl = existing?.imageUrl;
    _storagePath = existing?.storagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final initial = (start ? _startDate : _endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _startDate = DateTime(picked.year, picked.month, picked.day);
      } else {
        _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59, 999);
      }
    });
  }

  Future<void> _pickVisual() async {
    try {
      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );
        final file = result?.files.single;
        final bytes = file?.bytes;
        if (bytes == null || bytes.isEmpty || !mounted) return;
        setState(() {
          _pendingBytes = bytes;
          _pendingExt = (file?.extension ?? 'jpg').toLowerCase();
          _pendingContentType = _contentTypeForExt(_pendingExt);
        });
        return;
      }

      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty || !mounted) return;
      final name = picked.name.toLowerCase();
      final ext = name.contains('.') ? name.split('.').last : 'jpg';
      setState(() {
        _pendingBytes = bytes;
        _pendingExt = ext;
        _pendingContentType = _contentTypeForExt(ext);
      });
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, context.l10n.adminAdsSaveFailed);
    }
  }

  String _contentTypeForExt(String ext) {
    switch (ext.replaceAll('.', '').toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _submit() async {
    if (_saving) return;
    final l10n = context.l10n;
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    setState(() {
      _nameError = name.isEmpty ? l10n.adminAdsNameRequired : null;
      _urlError = url.isEmpty ? l10n.adminAdsUrlRequired : null;
      _datesError = _startDate != null &&
              _endDate != null &&
              _endDate!.isBefore(_startDate!)
          ? l10n.adminAdsDatesInvalid
          : null;
    });
    if (_nameError != null || _urlError != null || _datesError != null) {
      return;
    }

    setState(() => _saving = true);
    try {
      final id = widget.existing?.id ?? ShopAdsService.instance.newAdId();
      var storagePath = _storagePath;
      var imageUrl = _imageUrl;
      final pending = _pendingBytes;
      if (pending != null && pending.isNotEmpty) {
        final uploaded = await ShopAdsService.instance.uploadVisual(
          adId: id,
          bytes: pending,
          contentType: _pendingContentType,
          fileExtension: _pendingExt,
        );
        storagePath = uploaded.storagePath;
        imageUrl = uploaded.imageUrl;
      }

      await ShopAdsService.instance.save(
        ShopAd(
          id: id,
          name: name,
          url: url,
          target: _target,
          startDate: _startDate,
          endDate: _endDate,
          storagePath: storagePath,
          imageUrl: imageUrl,
          nbDisplay: widget.existing?.nbDisplay ?? 0,
          nbClicks: widget.existing?.nbClicks ?? 0,
        ),
      );
      if (!mounted) return;
      AppSnackbar.show(context, l10n.adminAdsSaved, isError: false);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('permission-denied')
          ? l10n.adminAdsPermissionDenied
          : l10n.adminAdsSaveFailed;
      AppSnackbar.show(context, message);
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final editing = widget.existing != null;
    final dateFmt = DateFormat.yMMMd(Localizations.localeOf(context).toString());

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing ? l10n.adminAdsEditTitle : l10n.adminAdsAddTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.adminAdsFieldName,
                errorText: _nameError,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: l10n.adminAdsFieldUrl,
                hintText: 'https://shop.grinta.io/…',
                errorText: _urlError,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.adminAdsFieldTarget,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ShopAdTarget>(
                  isExpanded: true,
                  value: _target,
                  items: [
                    for (final target in ShopAdTarget.values)
                      DropdownMenuItem(
                        value: target,
                        child: Text(adminAdsTargetLabel(l10n, target)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _target = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(start: true),
                    child: Text(
                      _startDate == null
                          ? l10n.adminAdsFieldStartDate
                          : dateFmt.format(_startDate!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(start: false),
                    child: Text(
                      _endDate == null
                          ? l10n.adminAdsFieldEndDate
                          : dateFmt.format(_endDate!),
                    ),
                  ),
                ),
              ],
            ),
            if (_datesError != null) ...[
              const SizedBox(height: 6),
              Text(
                _datesError!,
                style: TextStyle(color: colors.danger, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickVisual,
              icon: const Icon(Icons.image_outlined),
              label: Text(l10n.adminAdsUploadVisual),
            ),
            if (_pendingBytes != null || _imageUrl != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 120,
                  child: _pendingBytes != null
                      ? Image.memory(_pendingBytes!, fit: BoxFit.cover)
                      : CachedNetworkImage(
                          imageUrl: _imageUrl!,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(editing ? l10n.adminAdsUpdate : l10n.adminAdsAdd),
            ),
          ],
        ),
      ),
    );
  }
}

String adminAdsTargetLabel(AppLocalizations l10n, ShopAdTarget target) {
  switch (target) {
    case ShopAdTarget.all:
      return l10n.adminAdsTargetAll;
    case ShopAdTarget.coach:
      return l10n.adminAdsTargetCoach;
    case ShopAdTarget.player:
      return l10n.adminAdsTargetPlayer;
    case ShopAdTarget.coachWithoutTracker:
      return l10n.adminAdsTargetCoachWithoutTracker;
    case ShopAdTarget.playerWithoutTracker:
      return l10n.adminAdsTargetPlayerWithoutTracker;
  }
}
