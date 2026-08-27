import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/services/shop_ads_preferences_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/settings_menu_style.dart';

/// Settings toggle for [ShopAdsPreferencesService.eshopAds].
class ShopAdsSettingsTile extends StatefulWidget {
  const ShopAdsSettingsTile({
    super.key,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.webCardStyle = false,
  });

  final EdgeInsetsGeometry contentPadding;
  final bool webCardStyle;

  @override
  State<ShopAdsSettingsTile> createState() => _ShopAdsSettingsTileState();
}

class _ShopAdsSettingsTileState extends State<ShopAdsSettingsTile> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(ShopAdsPreferencesService.instance.ensureInitialized());
  }

  Future<void> _onChanged(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ShopAdsPreferencesService.instance.setEshopAds(value);
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, context.l10n.shopAdsSaveFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    return ListenableBuilder(
      listenable: ShopAdsPreferencesService.instance,
      builder: (context, _) {
        final enabled = ShopAdsPreferencesService.instance.eshopAds;

        if (widget.webCardStyle) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.storefront_outlined,
                    color: colors.primary,
                    size: kWebMenuIconSize,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.settingsShopAdsLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: settingsMenuTitleStyle(context),
                    ),
                  ),
                  Switch(
                    value: enabled,
                    onChanged: _busy ? null : _onChanged,
                    activeThumbColor: Colors.white,
                    activeTrackColor: colors.primary,
                    inactiveThumbColor: colors.textSecondary,
                    inactiveTrackColor: colors.border,
                  ),
                ],
              ),
            ),
          );
        }

        return SwitchListTile(
          contentPadding: widget.contentPadding,
          secondary: Icon(Icons.storefront_outlined, color: colors.primary),
          title: Text(
            l10n.settingsShopAdsLabel,
            style: settingsMenuTitleStyle(context),
          ),
          value: enabled,
          onChanged: _busy ? null : _onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: colors.primary,
          inactiveThumbColor: colors.textSecondary,
          inactiveTrackColor: colors.border,
        );
      },
    );
  }
}
