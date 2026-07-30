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
/// On iOS, YouTube Error 153 appears when the embed lacks a valid Referer /
/// origin. We load a local HTML shell with `referrerpolicy` and a HTTPS
/// [baseUrl], and block navigations that leave the embed iframe.
class YoutubeEmbedPlayer extends StatefulWidget {
  const YoutubeEmbedPlayer({
    super.key,
    required this.videoId,
    this.autoplay = true,
  });

  final String videoId;
  final bool autoplay;

  /// Origin used as Referer / HTML baseUrl for YouTube embed verification.
  static const String embedOrigin = 'https://www.grinta.io';

  @override
  State<YoutubeEmbedPlayer> createState() => _YoutubeEmbedPlayerState();
}

class _YoutubeEmbedPlayerState extends State<YoutubeEmbedPlayer> {
  WebViewController? _controller;
  Widget? _webView;
  bool _loading = true;
  String? _error;

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
        '&origin=${Uri.encodeComponent(YoutubeEmbedPlayer.embedOrigin)}';
  }

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

  void _initMobileWebView() {
    final controller = WebViewController.fromPlatformCreationParams(
      _platformParams(),
    )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;

            // Allow the initial HTML document / about:blank / embed frames.
            final host = uri.host.toLowerCase();
            final path = uri.path.toLowerCase();
            final isEmbed = host.contains('youtube.com') &&
                (path.contains('/embed/') || path.contains('/embed'));
            final isYoutubeCdn = host.contains('youtube.com') ||
                host.contains('youtu.be') ||
                host.contains('ytimg.com') ||
                host.contains('googlevideo.com') ||
                host.contains('google.com') ||
                host.contains('gstatic.com');
            final isLocalDoc = uri.scheme == 'about' ||
                uri.scheme == 'data' ||
                request.url == 'about:blank';

            if (isLocalDoc || isEmbed) {
              return NavigationDecision.navigate;
            }

            // Block leaving the embed for the full YouTube mobile site.
            if (path.contains('/watch') ||
                path.contains('/shorts') ||
                host == 'm.youtube.com' ||
                (host.contains('youtu.be') && !isEmbed)) {
              return NavigationDecision.prevent;
            }

            // Allow ancillary YouTube/Google resources for the player.
            if (isYoutubeCdn) {
              return NavigationDecision.navigate;
            }

            return NavigationDecision.prevent;
          },
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
            // Ignore subframe noise; surface only main-frame failures.
            if (details.isForMainFrame == false) return;
            setState(() {
              _loading = false;
              _error = details.description;
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

  Future<void> _loadEmbed(WebViewController controller) async {
    try {
      // HTML shell + HTTPS baseUrl supplies the Referer YouTube requires
      // (avoids Error 153 on iOS WKWebView).
      await controller.loadHtmlString(
        _embedHtml,
        baseUrl: YoutubeEmbedPlayer.embedOrigin,
      );
    } catch (e) {
      // Fallback: direct embed URL with explicit Referer header.
      try {
        await controller.loadRequest(
          Uri.parse(_embedSrc),
          headers: const <String, String>{
            'Referer': YoutubeEmbedPlayer.embedOrigin,
          },
        );
      } catch (e2) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = e2.toString();
        });
      }
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
            ],
          ),
        ),
      ),
    );
  }
}
