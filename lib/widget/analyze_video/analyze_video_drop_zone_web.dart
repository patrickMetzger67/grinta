import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:grinta/widget/analyze_video/analyze_dropped_file.dart';
import 'package:web/web.dart' as web;

/// Web: transparent HTML overlay that accepts OS file drag-and-drop.
class DebugVideoDropZone extends StatefulWidget {
  const DebugVideoDropZone({
    super.key,
    required this.child,
    required this.onFilesDropped,
  });

  final Widget child;
  final ValueChanged<List<DebugDroppedFile>> onFilesDropped;

  @override
  State<DebugVideoDropZone> createState() => _DebugVideoDropZoneState();
}

class _DebugVideoDropZoneState extends State<DebugVideoDropZone> {
  static int _nextViewId = 0;

  late final String _viewType;
  late ValueChanged<List<DebugDroppedFile>> _onFilesDropped;
  bool _highlighted = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'grinta-debug-video-drop-${_nextViewId++}';
    _onFilesDropped = widget.onFilesDropped;
    _registerViewFactory();
  }

  @override
  void didUpdateWidget(covariant DebugVideoDropZone oldWidget) {
    super.didUpdateWidget(oldWidget);
    _onFilesDropped = widget.onFilesDropped;
  }

  void _setHighlighted(bool value) {
    if (!mounted || _highlighted == value) return;
    setState(() => _highlighted = value);
  }

  void _registerViewFactory() {
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final div = web.HTMLDivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..style.backgroundColor = 'transparent';

      void prevent(web.Event event) {
        event.preventDefault();
        event.stopPropagation();
      }

      div.addEventListener(
        'dragenter',
        (web.Event event) {
          prevent(event);
          _setHighlighted(true);
        }.toJS,
      );
      div.addEventListener(
        'dragover',
        (web.Event event) {
          prevent(event);
          final drag = event as web.DragEvent;
          drag.dataTransfer?.dropEffect = 'copy';
          _setHighlighted(true);
        }.toJS,
      );
      div.addEventListener(
        'dragleave',
        (web.Event event) {
          prevent(event);
          _setHighlighted(false);
        }.toJS,
      );
      div.addEventListener(
        'drop',
        (web.Event event) {
          prevent(event);
          _setHighlighted(false);
          final drag = event as web.DragEvent;
          final files = drag.dataTransfer?.files;
          if (files == null || files.length == 0) return;
          _readDroppedFiles(files);
        }.toJS,
      );

      return div;
    });
  }

  Future<void> _readDroppedFiles(web.FileList files) async {
    final dropped = <DebugDroppedFile>[];
    for (var i = 0; i < files.length; i++) {
      final file = files.item(i);
      if (file == null) continue;
      try {
        final JSArrayBuffer buffer = await file.arrayBuffer().toDart;
        final bytes = buffer.toDart.asUint8List();
        dropped.add(DebugDroppedFile(name: file.name, bytes: bytes));
      } catch (_) {
        // Skip unreadable files; the screen shows a generic pick/upload error
        // if nothing usable remains.
      }
    }
    if (dropped.isEmpty || !mounted) return;
    _onFilesDropped(dropped);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: HtmlElementView(viewType: _viewType),
        ),
        if (_highlighted)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
