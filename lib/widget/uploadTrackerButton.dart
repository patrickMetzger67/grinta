import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';

class UploadTrackerButton extends StatefulWidget {
  final Future<void> Function() onPressed;

  const UploadTrackerButton({
    super.key,
    required this.onPressed,
  });

  @override
  State<UploadTrackerButton> createState() => _UploadTrackerButtonState();
}

class _UploadTrackerButtonState extends State<UploadTrackerButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading
          ? null
          : () async {
        setState(() {
          _isLoading = true;
        });

        try {
          await widget.onPressed();
        } finally {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
          });
        }
      },
      icon: _isLoading
          ? const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      )
          : const Icon(Icons.cloud_upload),
      label: Text(
        _isLoading
            ? context.l10n.uploadTrackerLoading
            : context.l10n.uploadTrackerDownloadData,
      ),
    );
  }
}