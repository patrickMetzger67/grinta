import 'package:flutter/material.dart';
import 'package:grinta/widget/analyze_video/analyze_dropped_file.dart';

/// Non-web: visual drop target only. Use the file picker button to import.
class DebugVideoDropZone extends StatelessWidget {
  const DebugVideoDropZone({
    super.key,
    required this.child,
    required this.onFilesDropped,
  });

  final Widget child;
  final ValueChanged<List<DebugDroppedFile>> onFilesDropped;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
