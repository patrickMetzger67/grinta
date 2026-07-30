import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/widget/youtube_embed_view_stub.dart'
    if (dart.library.html) 'package:grinta/widget/youtube_embed_view_web.dart'
    as youtube_embed;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// In-app YouTube player: iframe on web, WebView embed on iOS/Android.
///
/// YouTube Error 153 ("Video player configuration error") happens when the
/// embed request has no valid HTTP Referer. On iOS WKWebView, loading an
/// HTML shell with an iframe often strips that header (WebKit bug 169846).
/// Loading the `/embed/` URL as the main document with an explicit Referer
/// is the reliable fix.
class YoutubeEmbedPlayer extends StatefulWidget {
  const YoutubeEmbedPlayer({
    super.key,
    required this.videoId,
    this.autoplay = true,
  });

  final String videoId;
  final bool autoplay;

  /// Origin / Referer YouTube uses to verify the embed client.
  static const String embedOrigin = 'https://www.grinta.io';

  /// Bundle-style origin used as a secondary Referer fallback on iOS.
  static const String bundleOrigin = 'https://io.grinta.app';

  @override
  State<YoutubeEmbedPlayer> createState() => _YoutubeEmbedPlayerState();
}

class _YoutubeEmbedPlayerState extends State<YoutubeEmbedPlayer> {
  static const String _ytChannelName = 'GrintaYt';

  WebViewController? _controller;
  Widget? _webView;
  bool _loading = true;
  String? _error;
  bool _showOpenExternally = false;

  String get _watchUrl =>
      'https://www.youtube.com/watch?v=${widget.videoId}';

  String get _embedSrc {
    final autoplay = widget.autoplay ? '1' : '0';
    return 'https://www.youtube.com/embed/${widget.videoId}'
        '?autoplay=$autoplay'
        '&playsinline=1'
        '&rel=0'
        '&modestbranding=1'
        '&fs=1'
        '&enablejsapi=1'
        '&origin=${Uri.encodeComponent(YoutubeEmbedPlayer.embedOrigin)}'
        '&widget_referrer=${Uri.encodeComponent(YoutubeEmbedPlayer.embedOrigin)}';
  }

  Map<String, String> get _embedHeaders => const <String, String>{
        'Referer': '${YoutubeEmbedPlayer.embedOrigin}/',
        'Referrer-Policy': 'strict-origin-when-cross-origin',
      };

  String get _embedHtml {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <meta name="referrer" content="strict-origin-when-cross-origin">
  <style>
    html, body {
      margin: 0;
      padding: 0;
      width: 100%;
      height: 100%;
      background: #000;
      overflow: hidden;
    }
    iframe {
      border: 0;
      position: absolute;
      inset: 0;
      width: 100%;
      height: 100%;
    }
  </style>
</head>
<body>
  <iframe
    id="player"
    src="$_embedSrc"
    title="YouTube"
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
    allowfullscreen
    referrerpolicy="strict-origin-when-cross-origin"
  ></iframe>
</body>
</html>
''';
  }

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      final viewType =
          'grinta-youtube-embed-${widget.videoId}-${identityHashCode(this)}';
      _webView = youtube_embed.buildYoutubeEmbedView(
        videoId: widget.videoId,
        viewType: viewType,
      );
      _loading = false;
    } else {
      _initMobileWebView();
    }
  }

  @override
  void didUpdateWidget(covariant YoutubeEmbedPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!kIsWeb &&
        oldWidget.videoId != widget.videoId &&
        _controller != null) {
      _loadEmbed(_controller!);
    }
  }

  PlatformWebViewControllerCreationParams _platformParams() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserGesture: const <PlaybackMediaTypes>{},
      );
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return AndroidWebViewControllerCreationParams();
    }
    return const PlatformWebViewControllerCreationParams();
  }

  bool _isEmbedUrl(Uri uri) {
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    final isYoutubeHost = host.contains('youtube.com') ||
        host.contains('youtube-nocookie.com');
    return isYoutubeHost && path.contains('/embed');
  }

  bool _isPlayerResource(Uri uri) {
    final host = uri.host.toLowerCase();
    return host.contains('youtube.com') ||
        host.contains('youtube-nocookie.com') ||
        host.contains('youtu.be') ||
        host.contains('ytimg.com') ||
        host.contains('googlevideo.com') ||
        host.contains('google.com') ||
        host.contains('gstatic.com') ||
        host.contains('ggpht.com');
  }

  bool _isForbiddenMainFrame(Uri uri) {
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    if (host == 'm.youtube.com') return true;
    if (path.contains('/watch')) return true;
    if (path.contains('/shorts')) return true;
    if (path.contains('/feed') || path == '/' || path.isEmpty) {
      if (host.contains('youtube.com')) return true;
    }
    return false;
  }

  void _initMobileWebView() {
    final controller = WebViewController.fromPlatformCreationParams(
      _platformParams(),
    )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..addJavaScriptChannel(
        _ytChannelName,
        onMessageReceived: (message) {
          if (!mounted) return;
          if (message.message == 'error153') {
            setState(() {
              _loading = false;
              _showOpenExternally = true;
            });
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;

            final isLocalDoc = uri.scheme == 'about' ||
                uri.scheme == 'data' ||
                request.url == 'about:blank';

            if (isLocalDoc || _isEmbedUrl(uri)) {
              return NavigationDecision.navigate;
            }

            // Main frame must stay on the embed — never the full mobile site.
            if (request.isMainFrame) {
              if (_isForbiddenMainFrame(uri)) {
                return NavigationDecision.prevent;
              }
              // Any other top-level navigation leaves the player.
              return NavigationDecision.prevent;
            }

            // Subframe / CDN resources needed by the player.
            if (_isPlayerResource(uri)) {
              return NavigationDecision.navigate;
            }

            return NavigationDecision.prevent;
          },
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _loading = true;
              _error = null;
              _showOpenExternally = false;
            });
          },
          onPageFinished: (_) async {
            if (!mounted) return;
            setState(() => _loading = false);
            await _injectError153Watcher();
          },
          onWebResourceError: (details) {
            if (!mounted) return;
            // Ignore subframe noise; surface only main-frame failures.
            if (details.isForMainFrame == false) return;
            setState(() {
              _loading = false;
              _error = details.description;
              _showOpenExternally = true;
            });
          },
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;
    _loadEmbed(controller);
  }

  Future<void> _injectError153Watcher() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.runJavaScript('''
(function() {
  if (window.__grintaYtWatch) return;
  window.__grintaYtWatch = true;
  function check() {
    try {
      var t = (document.body && document.body.innerText) || '';
      if (t.indexOf('Error 153') !== -1 || t.indexOf('Erreur 153') !== -1) {
        if (window.$_ytChannelName && window.$_ytChannelName.postMessage) {
          window.$_ytChannelName.postMessage('error153');
        }
      }
    } catch (e) {}
  }
  check();
  setInterval(check, 800);
})();
''');
    } catch (_) {
      // Best-effort; ignore if the page blocks script injection.
    }
  }

  Future<void> _loadEmbed(WebViewController controller) async {
    // 1) Preferred: embed as main document with explicit Referer.
    //    This is what fixes Error 153 on iOS WKWebView.
    try {
      await controller.loadRequest(
        Uri.parse(_embedSrc),
        headers: _embedHeaders,
      );
      return;
    } catch (_) {
      // Continue to fallbacks.
    }

    // 2) HTML shell + HTTPS baseUrl (helps Android / some iOS builds).
    try {
      await controller.loadHtmlString(
        _embedHtml,
        baseUrl: YoutubeEmbedPlayer.embedOrigin,
      );
      return;
    } catch (_) {
      // Continue.
    }

    // 3) Last resort: HTML shell with bundle-id style origin.
    try {
      await controller.loadHtmlString(
        _embedHtml,
        baseUrl: YoutubeEmbedPlayer.bundleOrigin,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
        _showOpenExternally = true;
      });
    }
  }

  Future<void> _openExternally() async {
    final uri = Uri.parse(_watchUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (kIsWeb && _webView != null)
                _webView!
              else if (!kIsWeb && _controller != null)
                WebViewWidget(controller: _controller!)
              else
                const SizedBox.shrink(),
              if (_loading)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _openExternally,
                          child: Text(l10n.youtubeTopVideoWatch),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_showOpenExternally && _error == null)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(8),
                    child: TextButton.icon(
                      onPressed: _openExternally,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(l10n.youtubeTopVideoWatch),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
