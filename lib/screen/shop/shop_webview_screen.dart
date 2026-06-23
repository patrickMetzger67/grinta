import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/config/shopify_config.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// In-app browser for shop.grinta.io or a specific product URL.
class ShopWebViewScreen extends StatefulWidget {
  const ShopWebViewScreen({
    super.key,
    this.initialUrl,
    this.title,
  });

  /// Defaults to [kShopifyShopUrl] when omitted.
  final String? initialUrl;

  /// App bar title; falls back to localized shop title.
  final String? title;

  static Future<void> open(
    BuildContext context, {
    String? url,
    String? title,
  }) {
    final targetUrl = url ?? kShopifyShopUrl;
    if (kIsWeb) {
      return launchUrl(
        Uri.parse(targetUrl),
        mode: LaunchMode.externalApplication,
      );
    }
    return Navigator.of(context).push<void>(
      analyticsMaterialRoute<void>(
        screenName: AnalyticsScreenNames.shop,
        builder: (_) => ShopWebViewScreen(initialUrl: targetUrl, title: title),
      ),
    );
  }

  @override
  State<ShopWebViewScreen> createState() => _ShopWebViewScreenState();
}

class _ShopWebViewScreenState extends State<ShopWebViewScreen> {
  WebViewController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initWebView();
    }
  }

  void _initWebView() {
    final url = widget.initialUrl ?? kShopifyShopUrl;
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _loading = true;
              _error = null;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _loading = false);
          },
          onWebResourceError: (details) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _error = details.description;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(url));

    setState(() => _controller = controller);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final title = widget.title ?? l10n.shopTitle;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: colors.card,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      body: _controller == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                WebViewWidget(controller: _controller!),
                if (_loading)
                  const Center(child: CircularProgressIndicator()),
                if (_error != null && !_loading)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.shopLoadError,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _error = null;
                                _loading = true;
                              });
                              _controller?.reload();
                            },
                            child: Text(l10n.shopRetry),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
