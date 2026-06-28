import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/util/google_profile_image_url.dart';
import 'package:http/http.dart' as http;

/// Web: native `<img>` via [HtmlElementView], then HTTP bytes + [Image.memory].
/// Bypasses Flutter's network image decoder (EncodingError on Google lh3 URLs).
class WebCircleNetworkImage extends StatefulWidget {
  const WebCircleNetworkImage({
    super.key,
    required this.url,
    required this.size,
    required this.errorChild,
    this.onError,
  });

  final String url;
  final double size;
  final Widget errorChild;
  final VoidCallback? onError;

  @override
  State<WebCircleNetworkImage> createState() => _WebCircleNetworkImageState();
}

enum _LoadMode { htmlElement, memory, failed }

class _WebCircleNetworkImageState extends State<WebCircleNetworkImage> {
  static final Set<String> _registeredViewTypes = <String>{};

  late List<String> _urlCandidates;
  int _urlIndex = 0;
  _LoadMode _mode = _LoadMode.htmlElement;
  int _memoryAttempt = 0;

  @override
  void initState() {
    super.initState();
    _urlCandidates = expandGoogleProfileImageUrls(widget.url);
  }

  @override
  void didUpdateWidget(covariant WebCircleNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _urlCandidates = expandGoogleProfileImageUrls(widget.url);
      _urlIndex = 0;
      _mode = _LoadMode.htmlElement;
      _memoryAttempt = 0;
    }
  }

  String get _currentUrl =>
      _urlCandidates.isEmpty ? widget.url.trim() : _urlCandidates[_urlIndex];

  String get _htmlViewType =>
      'grinta-circle-img-${_currentUrl.hashCode}-$_urlIndex';

  void _registerHtmlView() {
    final viewType = _htmlViewType;
    if (_registeredViewTypes.contains(viewType)) return;

    final url = _currentUrl;
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final img = html.ImageElement()
        ..src = url
        ..referrerPolicy = 'no-referrer'
        ..style.border = 'none'
        ..style.margin = '0'
        ..style.padding = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';

      img.onError.listen((_) => _onHtmlLoadFailed(url));

      return img;
    });
    _registeredViewTypes.add(viewType);
  }

  void _onHtmlLoadFailed(String failedUrl) {
    if (!mounted || _mode != _LoadMode.htmlElement) return;

    if (kDebugMode) {
      debugPrint(
        'WebCircleNetworkImage html img failed url=$failedUrl '
        'index=$_urlIndex/${_urlCandidates.length}',
      );
    }

    if (_urlIndex < _urlCandidates.length - 1) {
      setState(() => _urlIndex++);
      return;
    }

    setState(() {
      _urlIndex = 0;
      _mode = _LoadMode.memory;
      _memoryAttempt = 0;
    });
  }

  void _onMemoryLoadFailed(String failedUrl) {
    if (!mounted || _mode != _LoadMode.memory) return;

    if (kDebugMode) {
      debugPrint(
        'WebCircleNetworkImage memory decode failed url=$failedUrl '
        'index=$_urlIndex/${_urlCandidates.length}',
      );
    }

    if (_urlIndex < _urlCandidates.length - 1) {
      setState(() {
        _urlIndex++;
        _memoryAttempt++;
      });
      return;
    }

    setState(() => _mode = _LoadMode.failed);
    widget.onError?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_urlCandidates.isEmpty || _mode == _LoadMode.failed) {
      return widget.errorChild;
    }

    if (_mode == _LoadMode.memory) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: ClipOval(
          child: _MemoryNetworkCircleImage(
            key: ValueKey('memory-${_currentUrl}-$_memoryAttempt'),
            url: _currentUrl,
            size: widget.size,
            errorChild: widget.errorChild,
            onError: () => _onMemoryLoadFailed(_currentUrl),
          ),
        ),
      );
    }

    _registerHtmlView();
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ClipOval(
        child: HtmlElementView(
          key: ValueKey(_htmlViewType),
          viewType: _htmlViewType,
        ),
      ),
    );
  }
}

class _MemoryNetworkCircleImage extends StatefulWidget {
  const _MemoryNetworkCircleImage({
    super.key,
    required this.url,
    required this.size,
    required this.errorChild,
    required this.onError,
  });

  final String url;
  final double size;
  final Widget errorChild;
  final VoidCallback onError;

  @override
  State<_MemoryNetworkCircleImage> createState() =>
      _MemoryNetworkCircleImageState();
}

class _MemoryNetworkCircleImageState extends State<_MemoryNetworkCircleImage> {
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(covariant _MemoryNetworkCircleImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _bytes = null;
      _failed = false;
      _fetch();
    }
  }

  Future<void> _fetch() async {
    try {
      final response = await http.get(
        Uri.parse(widget.url),
        headers: const {'Referer': 'https://accounts.google.com/'},
      );
      if (!mounted) return;
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        setState(() => _bytes = response.bodyBytes);
      } else {
        _fail();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'WebCircleNetworkImage http fetch failed url=${widget.url} error=$e',
        );
      }
      _fail();
    }
  }

  void _fail() {
    if (!mounted || _failed) return;
    setState(() => _failed = true);
    widget.onError();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return widget.errorChild;
    final bytes = _bytes;
    if (bytes == null) {
      return SizedBox(width: widget.size, height: widget.size);
    }

    return Image.memory(
      bytes,
      key: ValueKey('memory-img-${widget.url}'),
      fit: BoxFit.cover,
      width: widget.size,
      height: widget.size,
      errorBuilder: (context, error, stackTrace) {
        if (kDebugMode) {
          debugPrint(
            'WebCircleNetworkImage Image.memory failed url=${widget.url} '
            'error=$error',
          );
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => _fail());
        return widget.errorChild;
      },
    );
  }
}
