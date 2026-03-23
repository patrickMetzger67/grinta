import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:grinta/services/trackerDeviceRawFirestoreService.dart';
import 'model/trackerDeviceRaw.dart';
import 'usb/asi_models.dart';
import 'usb/asi_usb_factory.dart';
import 'usb/asi_usb_client.dart';

class AsiDownloaderScreen extends StatefulWidget {
  const AsiDownloaderScreen({super.key});

  @override
  State<AsiDownloaderScreen> createState() => _AsiDownloaderScreenState();
}

class _AsiDownloaderScreenState extends State<AsiDownloaderScreen> {
  late final AsiUsbClient client;
  AsiDeviceInfo? selectedDevice;
  AsiSession? session;

  String logs = '';
  bool loading = false;

  String? deviceId;

  @override
  void initState() {
    super.initState();
    client = createAsiUsbClient();
  }

  void appendLog(String text) {
    setState(() {
      logs = '$logs$text\n';
    });
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

  Future<void> connectDevice() async {
    setState(() => loading = true);
    try {
      final devices = await client.listDevices();
      if (devices.isEmpty) {
        appendLog('Aucun périphérique trouvé');
        return;
      }

      selectedDevice = devices.first;
      session = await client.open(selectedDevice!);

      appendLog(
        'Connecté: ${selectedDevice!.productName ?? selectedDevice!.id}',
      );

      // Ne pas lire le UUID ici :
      // ce device est sensible et cela perturbe DATA_READ.
    } catch (e) {
      print('$e');
      appendLog('Erreur connexion: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<String?> readDeviceIdInFreshSession() async {
    if (selectedDevice == null) return null;

    AsiSession? tempSession;

    try {
      tempSession = await client.open(selectedDevice!);
      final uuid = await client.readDeviceId(tempSession);
      return uuid;
    } catch (e) {
      appendLog('Lecture UUID impossible: $e');
      return null;
    } finally {
      if (tempSession != null) {
        try {
          await client.close(tempSession);
        } catch (_) {}
      }
    }
  }

  Future<void> download() async {
    if (session == null) {
      appendLog('Aucune session ouverte');
      return;
    }

    setState(() => loading = true);

    try {
      appendLog('Téléchargement en cours...');
      appendLog('Lecture RAW en cours...');

      Uint8List data;
      try {
        data = await client
            .downloadData(session!)
            .timeout(const Duration(seconds: 8));
      } on TimeoutException {
        appendLog('Aucune donnée à transférer');
        return;
      }

      appendLog('Téléchargé: ${data.length} octets');

      if (data.isEmpty) {
        appendLog('Pas de données');
        return;
      }

      appendLog('Hash OK');

      // On garde la session ouverte
      // UUID lu sur la session existante si possible
      if (deviceId == null || deviceId!.trim().isEmpty) {
        try {
          final uuid = await readDeviceIdInFreshSession();
          if (uuid != null && uuid.trim().isNotEmpty) {
            setState(() {
              deviceId = uuid;
            });
            appendLog('UUID: $uuid');
          }
        } catch (e) {
          appendLog('Lecture UUID impossible: $e');
        }
      }

      if (deviceId == null || deviceId!.trim().isEmpty) {
        appendLog('UUID introuvable, parsing annulé');
        return;
      }

      final String csv = await convertAsiToCsv(data);
      appendLog('CSV reçu (${csv.length} caractères)');

      final rawLines = csv
          .split(RegExp(r'\r\n|\n|\r'))
          .where((e) => e.trim().isNotEmpty)
          .toList();

      appendLog('Lignes brutes non vides: ${rawLines.length}');

      final previewLines = rawLines.take(20).toList();
      for (final line in previewLines) {
        print('CSV_PREVIEW: [$line]');
      }

      final rows = TrackerDeviceRawNoHeaderParser.parseCsv(
        csv: csv,
        deviceId: deviceId!,
      );

      appendLog('${rows.length} point(s) brut(s) parsé(s)');

      if (rows.isEmpty) {
        appendLog('Aucune donnée exploitable trouvée dans le CSV');
        return;
      }

      final uniqueIds = rows.map((e) => e.id).toSet();
      appendLog('DocId uniques: ${uniqueIds.length}');

      final start = rows.first.timestamp.toDate();
      final end = rows.last.timestamp.toDate();
      final duration = end.difference(start);

      appendLog('Début: ${start.toIso8601String()}');
      appendLog('Fin: ${end.toIso8601String()}');
      appendLog(
        'Durée: ${duration.inMinutes} min ${duration.inSeconds % 60} s',
      );

      if (duration.inMilliseconds > 0 && rows.length > 1) {
        final hz =
        ((rows.length - 1) / (duration.inMilliseconds / 1000))
            .toStringAsFixed(2);
        appendLog('Fréquence estimée: $hz Hz');
      }

      for (final row in rows.take(20)) {
        print(
          '${row.id} | '
              '${row.timestamp.toDate().toIso8601String()} | '
              '${row.latitude} | ${row.longitude} | ${row.altitude} | ${row.speed} | ${row.hr}',
        );
      }

      appendLog('Sauvegarde Firestore en cours...');
      await TrackerDeviceRawFirestoreService().saveAll(rows);
      appendLog('Sauvegarde Firestore terminée');
    } catch (e, st) {
      appendLog('Erreur download: $e');
      print('DOWNLOAD_ERROR: $e');
      print(st);
    } finally {
      setState(() => loading = false);
    }
  }
  /*
  Future<void> download() async {
    if (session == null) {
      appendLog('Aucune session ouverte');
      return;
    }

    setState(() => loading = true);

    try {
      appendLog('Téléchargement en cours...');
      appendLog('Lecture RAW en cours...');

      final Uint8List data = await client.downloadData(session!);
      appendLog('Téléchargé: ${data.length} octets');

      if (data.isEmpty) {
        appendLog('Pas de données');
        return;
      }

      appendLog('Hash OK');

      // On ferme la session de download pour repartir proprement
      await client.close(session!);
      session = null;

      // UUID dans une nouvelle session séparée
      final uuid = await readDeviceIdInFreshSession();
      if (uuid != null && uuid.trim().isNotEmpty) {
        setState(() {
          deviceId = uuid;
        });
        appendLog('UUID: $uuid');
      }

      if (deviceId == null || deviceId!.trim().isEmpty) {
        appendLog('UUID introuvable, parsing annulé');
        return;
      }

      final String csv = await convertAsiToCsv(data);
      appendLog('CSV reçu (${csv.length} caractères)');

      final rawLines = csv
          .split(RegExp(r'\r\n|\n|\r'))
          .where((e) => e.trim().isNotEmpty)
          .toList();

      appendLog('Lignes brutes non vides: ${rawLines.length}');

      final previewLines = rawLines.take(20).toList();
      for (final line in previewLines) {
        print('CSV_PREVIEW: [$line]');
      }

      final rows = TrackerDeviceRawNoHeaderParser.parseCsv(
        csv: csv,
        deviceId: deviceId!,
      );

      appendLog('${rows.length} point(s) brut(s) parsé(s)');

      if (rows.isEmpty) {
        appendLog('Aucune donnée exploitable trouvée dans le CSV');
        return;
      }

      final uniqueIds = rows.map((e) => e.id).toSet();
      appendLog('DocId uniques: ${uniqueIds.length}');

      final start = rows.first.timestamp.toDate();
      final end = rows.last.timestamp.toDate();
      final duration = end.difference(start);

      appendLog('Début: ${start.toIso8601String()}');
      appendLog('Fin: ${end.toIso8601String()}');
      appendLog(
        'Durée: ${duration.inMinutes} min ${duration.inSeconds % 60} s',
      );

      if (duration.inMilliseconds > 0 && rows.length > 1) {
        final hz =
        ((rows.length - 1) / (duration.inMilliseconds / 1000))
            .toStringAsFixed(2);
        appendLog('Fréquence estimée: $hz Hz');
      }

      for (final row in rows.take(20)) {
        print(
          '${row.id} | '
              '${row.timestamp.toDate().toIso8601String()} | '
              '${row.latitude} | ${row.longitude} | ${row.altitude} | ${row.speed} | ${row.hr}',
        );
      }

      appendLog('Sauvegarde Firestore en cours...');
      await TrackerDeviceRawFirestoreService().saveAll(rows);
      appendLog('Sauvegarde Firestore terminée');

      // Réouvre une session si tu veux continuer à utiliser les boutons ensuite
      if (selectedDevice != null) {
        session = await client.open(selectedDevice!);
        appendLog('Session USB rouverte');
      }
    } catch (e, st) {
      appendLog('Erreur download: $e');
      print('DOWNLOAD_ERROR: $e');
      print(st);
    } finally {
      setState(() => loading = false);
    }
  }
  */

  Future<void> eraseData() async {
    if (session == null) {
      appendLog('Aucune session ouverte');
      return;
    }

    setState(() => loading = true);

    try {
      appendLog('Effacement en cours...');
      await client.eraseData(session!);
      appendLog('Effacement terminé ou aucune donnée à effacer');
    } catch (e, st) {
      appendLog('Erreur erase data: $e');
      print('ERASE_ERROR: $e');
      print(st);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> eraseAll() async {
    if (session == null) return;
    setState(() => loading = true);
    try {
      await client.eraseAll(session!);
      appendLog('Pod fully erased');
    } catch (e) {
      appendLog('Erreur erase all: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> disconnect() async {
    if (session == null) return;
    setState(() => loading = true);
    try {
      await client.close(session!);
      appendLog('Déconnecté');
      session = null;
    } catch (e) {
      appendLog('Erreur déconnexion: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ASI USB Downloader'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton(
                  onPressed: loading ? null : connectDevice,
                  child: const Text('Connecter'),
                ),
                ElevatedButton(
                  onPressed: loading ? null : download,
                  child: const Text('Télécharger'),
                ),
                ElevatedButton(
                  onPressed: loading ? null : eraseData,
                  child: const Text('Erase data'),
                ),
                ElevatedButton(
                  onPressed: loading ? null : eraseAll,
                  child: const Text('Erase all'),
                ),
                ElevatedButton(
                  onPressed: loading ? null : disconnect,
                  child: const Text('Déconnecter'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.black12,
                child: SingleChildScrollView(
                  child: Text(logs),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}