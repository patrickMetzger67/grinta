import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/extensions/l10n_extension.dart';
import '../model/player.dart';
import '../util/app_snackbar.dart';
import '../util/app_theme.dart';
import 'playerPhoto.dart';

typedef MemberProfilePhotoBytesChanged = void Function(Uint8List? bytes);

class MemberProfilePhotoEditor extends StatefulWidget {
  const MemberProfilePhotoEditor({
    super.key,
    required this.player,
    required this.enabled,
    this.onPhotoBytesChanged,
  });

  final Player player;
  final bool enabled;
  final MemberProfilePhotoBytesChanged? onPhotoBytesChanged;

  @override
  State<MemberProfilePhotoEditor> createState() =>
      _MemberProfilePhotoEditorState();
}

class _MemberProfilePhotoEditorState extends State<MemberProfilePhotoEditor> {
  static const double _avatarRadius = 48;

  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _pendingPhotoBytes;
  bool _isPicking = false;

  Uint8List? get pendingPhotoBytes => _pendingPhotoBytes;

  void clearPendingPhoto() {
    if (_pendingPhotoBytes == null) return;
    setState(() => _pendingPhotoBytes = null);
    widget.onPhotoBytesChanged?.call(null);
  }

  Future<void> _pickPhoto() async {
    if (!widget.enabled || _isPicking) return;

    setState(() => _isPicking = true);
    try {
      if (kIsWeb) {
        await _pickFromFiles();
        return;
      }

      final source = await _showMobileSourcePicker();
      if (!mounted || source == null) return;

      final picked = await _imagePicker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 88,
      );
      if (!mounted || picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted || bytes.isEmpty) return;

      setState(() => _pendingPhotoBytes = bytes);
      widget.onPhotoBytesChanged?.call(bytes);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        context.l10n.memberProfilePhotoUploadError('$e'),
      );
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _pickFromFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (!mounted) return;

    final file = result?.files.single;
    final bytes = file?.bytes;
    if (bytes == null || bytes.isEmpty) return;

    setState(() => _pendingPhotoBytes = bytes);
    widget.onPhotoBytesChanged?.call(bytes);
  }

  Future<ImageSource?> _showMobileSourcePicker() async {
    final l10n = context.l10n;
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.appColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l10n.memberProfileTakePhoto),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.memberProfileChooseFromGallery),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            if (_pendingPhotoBytes != null)
              CircleAvatar(
                radius: _avatarRadius,
                backgroundColor: colors.primary.withValues(alpha: 0.12),
                backgroundImage: MemoryImage(_pendingPhotoBytes!),
              )
            else
              PlayerPhoto(
                player: widget.player,
                radius: _avatarRadius,
              ),
            if (widget.enabled)
              Material(
                color: colors.primary,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _isPicking ? null : _pickPhoto,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: _isPicking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: widget.enabled && !_isPicking ? _pickPhoto : null,
          child: Text(l10n.memberProfileChangePhoto),
        ),
      ],
    );
  }
}
