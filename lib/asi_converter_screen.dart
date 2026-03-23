import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'util/app_theme.dart';

class AsiConverterScreen extends StatefulWidget {
  const AsiConverterScreen({super.key});

  @override
  State<AsiConverterScreen> createState() => _AsiConverterScreenState();
}

class _AsiConverterScreenState extends State<AsiConverterScreen> {
  final TextEditingController _sensorIdCtrl = TextEditingController();

  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  String? _csvResult;
  bool _isLoading = false;

  @override
  void dispose() {
    _sensorIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAsiFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['asi'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;

      if (file.bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de lire le fichier sélectionné'),
          ),
        );
        return;
      }

      setState(() {
        _selectedFileBytes = file.bytes!;
        _selectedFileName = file.name;
      });
    } catch (e) {
      debugPrint('Erreur file picker: $e');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection du fichier : $e'),
        ),
      );
    }
  }

  Future<String> convertAsiToCsv(Uint8List asiBytes) async {
    final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('insidersConvertAsiToCsv');

    final result = await callable.call({
      'asiBase64': base64Encode(asiBytes),
      'filename': 'inspirit_data.ASI',
    });

    final data = Map<String, dynamic>.from(result.data['data'] as Map);

    return data['csv'] as String;
  }

  Future<void> _convertFile() async {
    FocusScope.of(context).unfocus();

    final sensorId = _sensorIdCtrl.text.trim();

    if (_selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un fichier .asi'),
        ),
      );
      return;
    }

    if (sensorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez renseigner le sensorId'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _csvResult = null;
    });

    try {


      final String csv = await convertAsiToCsv(_selectedFileBytes!);
      if (!mounted) return;

      setState(() {
        _csvResult = csv;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conversion terminée'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur pendant la conversion : $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedFileBytes = null;
      _selectedFileName = null;
      _csvResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversion ASI vers CSV'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Importer un fichier .asi',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sélectionne un fichier, renseigne le capteur, puis lance la conversion.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Paramètres',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _sensorIdCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Sensor ID',
                              hintText: 'Exemple : 12345',
                              prefixIcon: Icon(Icons.sensors_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fichier sélectionné',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.insert_drive_file_outlined,
                                      color: colors.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _selectedFileName ??
                                            'Aucun fichier sélectionné',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                          color: _selectedFileName == null
                                              ? colors.textSecondary
                                              : colors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed:
                                      _isLoading ? null : _pickAsiFile,
                                      icon: const Icon(Icons.upload_file),
                                      label: const Text('Choisir un fichier .asi'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: _isLoading ||
                                          _selectedFileName == null
                                          ? null
                                          : _clearSelection,
                                      icon: const Icon(Icons.delete_outline),
                                      label: const Text('Réinitialiser'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _convertFile,
                              icon: _isLoading
                                  ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Icon(Icons.sync_alt_rounded),
                              label: Text(
                                _isLoading
                                    ? 'Conversion en cours...'
                                    : 'Convertir en CSV',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_csvResult != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Résultat CSV',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: _csvResult!),
                                    );

                                    if (!mounted) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('CSV copié dans le presse-papiers'),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.copy_rounded),
                                  label: const Text('Copier'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(
                                minHeight: 220,
                                maxHeight: 420,
                              ),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: colors.background,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: colors.border),
                              ),
                              child: SingleChildScrollView(
                                child: SelectableText(
                                  _csvResult!,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    color: colors.textPrimary,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}