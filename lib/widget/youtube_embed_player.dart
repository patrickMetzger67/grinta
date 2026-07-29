import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:grinta/widget/youtube_embed_view_stub.dart'
    if (dart.library.html) 'package:grinta/widget/youtube_embed_view_web.dart'
    as youtube_embed;
import 'package:webview_flutter/webview_flutter.dart';

/// In-app YouTube player: iframe on web, WebView embed on iOS/Android.
class YoutubeEmbedPlayer extends StatefulWidget {
  const YoutubeEmbedPlayer({
    super.key,
    required this.videoId,
    this.autoplay = true,
  });

  final String videoId;
  final bool autoplay;

  @override
  State<YoutubeEmbedPlayer> createState() => _YoutubeEmbedPlayerState();
}

class _YoutubeEmbedPlayerState extends State<YoutubeEmbedPlayer> {
  WebViewController? _controller;
  Widget? _webView;
  bool _loading = true;
  String? _error;

  String get _embedUrl {
    final autoplay = widget.autoplay ? '1' : '0';
    return 'https://www.youtube.com/embed/${widget.videoId}'
        '?autoplay=$autoplay&playsinline=1&rel=0';
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

  void _initMobileWebView() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
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
      ..loadRequest(Uri.parse(_embedUrl));

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
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
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
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
