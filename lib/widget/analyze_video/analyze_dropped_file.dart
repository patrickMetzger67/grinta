import 'dart:typed_data';

class DebugDroppedFile {
  const DebugDroppedFile({
    required this.name,
    required this.bytes,
  });

  final String name;
  final Uint8List bytes;
}
