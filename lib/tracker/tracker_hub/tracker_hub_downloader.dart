part of 'tracker_hub_page.dart';

class AsiDownloaderPanel extends StatefulWidget {
  final String trackerId;
  final List<TimeRange> periods;
  final bool isMatch;
  final String eventId;
  final FieldGpsCorners? fieldGpsCorners;
  final String playerId;
  final EventSync eventSync;
  final String? ownerId;

  const AsiDownloaderPanel({
    super.key,
    required this.trackerId,
    required this.periods,
    required this.isMatch,
    required this.eventId,
    required this.fieldGpsCorners,
    required this.playerId,
    required this.eventSync,
    required this.ownerId,
  });

  @override
  State<AsiDownloaderPanel> createState() => _AsiDownloaderPanelState();
}

class _AsiDownloaderPanelState extends State<AsiDownloaderPanel> {
  late final AsiUsbClient client;
  List<AsiDeviceInfo> availableDevices = [];
  AsiDeviceInfo? selectedDevice;
  AsiSession? session;

  String logs = '';
  bool loading = false;
  bool deviceConnected = false;
  bool dataDownloaded = false;
  bool dataErased = false;
  String? deviceId;

  FootballFieldGps? footballFieldGps;
  EventSync? eventSync;


  static const double _sprintThresholdKmh = 20.0;
  static const int _minSprintPoints = 4;

  @override
  void initState() {
    super.initState();
    eventSync = widget.eventSync;
    client = createAsiUsbClient();
    appendLog('Tracker sélectionné: ${widget.trackerId}');
  }

  @override
  void didUpdateWidget(covariant AsiDownloaderPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.trackerId == widget.trackerId) return;

    final previousSession = session;
    session = null;

    if (previousSession != null) {
      client.close(previousSession).catchError((e) {
        debugPrint(
          'Erreur fermeture session lors du changement de tracker: $e',
        );
      });
    }

    setState(() {
      logs = '';
      loading = false;
      availableDevices = [];
      selectedDevice = null;
      deviceId = null;
      deviceConnected = false;
      dataDownloaded = false;
      dataErased = false;
      footballFieldGps = null;
      eventSync = widget.eventSync;
    });

    appendLog('Tracker sélectionné: ${widget.trackerId}');
  }

  void appendLog(String text) {
    if (!mounted) return;
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



  Future<void> loadAuthorizedDevices() async {
    setState(() => loading = true);

    try {
      final devices = await client.listDevices();

      setState(() {
        availableDevices = devices;
        if (devices.isNotEmpty && selectedDevice == null) {
          selectedDevice = devices.first;
        }
      });

      if (devices.isEmpty) {
        appendLog('Aucun périphérique autorisé');
      } else {
        appendLog('${devices.length} périphérique(s) autorisé(s) trouvé(s)');
        for (final d in devices) {
          appendLog('- ${d.productName ?? "Sans nom"} (${d.id})');
        }
      }
    } catch (e) {
      appendLog('Erreur lecture périphériques: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
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
  Future<void> connectDevice() async {
    if (loading) return;

    setState(() => loading = true);

    AsiSession? identificationSession;
    AsiSession? downloadSession;

    try {
      final AsiDeviceInfo initialDevice;

      final currentSelectedDevice = selectedDevice;
      if (currentSelectedDevice != null) {
        initialDevice = currentSelectedDevice;
      } else {
        final grantedDevice = await client.requestDevicePermission();

        if (grantedDevice == null) {
          appendLog('Aucun périphérique sélectionné dans la popup Chrome');
          return;
        }

        initialDevice = grantedDevice;
        appendLog(
          'Autorisation accordée: '
              '${initialDevice.productName ?? initialDevice.id}',
        );
      }

      final previousSession = session;
      session = null;
      deviceConnected = false;

      if (previousSession != null) {
        try {
          await client.close(previousSession);
        } catch (e) {
          debugPrint('Fermeture ancienne session ignorée: $e');
        }

        await Future<void>.delayed(
          const Duration(milliseconds: 500),
        );
      }

      // 1. Première session : lecture et validation de l'identifiant.
      appendLog('Ouverture de la session d’identification...');

      identificationSession = await client.open(initialDevice);

      await Future<void>.delayed(
        const Duration(milliseconds: 1200),
      );

      final uuid = await client.readDeviceId(identificationSession);
      appendLog('UUID détecté: $uuid');

      final deviceTmp = await DeviceService().getDeviceByDeviceName(uuid);

      if (deviceTmp == null) {
        appendLog('Tracker ${widget.trackerId} inexistant !');
        return;
      }

      final deviceOwner =
      await DeviceOwnerService().getByDeviceId(deviceTmp.id);

      if (deviceOwner == null ||
          (deviceOwner.customName?.trim() ?? '') !=
              widget.trackerId.trim()) {
        appendLog(
          'Le tracker branché ne correspond pas à celui sélectionné',
        );
        return;
      }

      // 2. Reproduit automatiquement la déconnexion qui débloque
      // actuellement le premier téléchargement.
      appendLog('Réinitialisation de la connexion USB...');

      await client.close(identificationSession);
      identificationSession = null;

      // Le capteur a besoin d'un vrai temps de libération après la
      // première commande GET_ID.
      await Future<void>.delayed(
        const Duration(milliseconds: 1800),
      );

      // 3. Récupère de nouveau le device déjà autorisé.
      // Avec l'index.html corrigé, getDevices() restaure également
      // window.asiUsb._device après le close().
      final authorizedDevices = await client.listDevices();

      appendLog(
        '${authorizedDevices.length} périphérique(s) ASI autorisé(s)',
      );

      AsiDeviceInfo? reopenedDevice;

      for (final device in authorizedDevices) {
        if (device.id == initialDevice.id) {
          reopenedDevice = device;
          break;
        }
      }

      if (reopenedDevice == null && authorizedDevices.length == 1) {
        reopenedDevice = authorizedDevices.first;
      }

      if (reopenedDevice == null) {
        appendLog(
          'Impossible de retrouver automatiquement le périphérique USB',
        );

        final grantedAgain = await client.requestDevicePermission();

        if (grantedAgain == null) {
          throw const AsiUsbDeviceNotFoundException(
            'Le périphérique USB doit être sélectionné à nouveau',
          );
        }

        reopenedDevice = grantedAgain;
      }

      // 4. Deuxième session : uniquement pour downloadData/eraseData.
      appendLog('Ouverture de la session de téléchargement...');

      downloadSession = await client.open(reopenedDevice);

      await Future<void>.delayed(
        const Duration(milliseconds: 1200),
      );

      if (!mounted) {
        await client.close(downloadSession);
        downloadSession = null;
        return;
      }

      final activeDownloadSession = downloadSession;

      setState(() {
        session = activeDownloadSession;
        selectedDevice = reopenedDevice;
        deviceConnected = true;
        deviceId = uuid;
        dataDownloaded = false;
        dataErased = false;
      });

      downloadSession = null;

      appendLog(
        'Connecté: '
            '${reopenedDevice.productName ?? reopenedDevice.id}',
      );
      appendLog('Session USB prête pour le téléchargement');
    } catch (e, st) {
      if (identificationSession != null) {
        try {
          await client.close(identificationSession);
        } catch (_) {}
      }

      if (downloadSession != null) {
        try {
          await client.close(downloadSession);
        } catch (_) {}
      }

      final activeSession = session;
      session = null;

      if (activeSession != null) {
        try {
          await client.close(activeSession);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          deviceConnected = false;
          deviceId = null;
        });
      }

      appendLog('Erreur connexion: $e');
      debugPrint('CONNECT_ERROR: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }


  Future<Uint8List> _downloadWithAutomaticReconnect() async {
    final firstSession = session;

    if (firstSession == null) {
      throw const AsiUsbConnectionException(
        message: 'Aucune session USB ouverte',
      );
    }

    try {
      appendLog('Premier essai de téléchargement...');
      return await client.downloadData(firstSession);
    } on AsiDownloadTimeoutException catch (firstError) {
      appendLog('Premier essai sans réponse');
      appendLog('Réinitialisation automatique du capteur USB...');

      debugPrint('FIRST_DOWNLOAD_TIMEOUT: $firstError');

      final currentDevice = selectedDevice;

      if (currentDevice == null) {
        rethrow;
      }

      /*
       * Reproduit exactement le cycle manuel qui fonctionne :
       * téléchargement en échec -> déconnexion -> connexion ->
       * lecture UUID -> nouveau téléchargement.
       */
      try {
        await client.close(firstSession);
      } catch (e) {
        debugPrint('AUTO_RECONNECT_CLOSE_ERROR: $e');
      }

      if (mounted) {
        setState(() {
          session = null;
          deviceConnected = false;
        });
      } else {
        session = null;
        deviceConnected = false;
      }

      await Future<void>.delayed(
        const Duration(milliseconds: 1500),
      );

      final authorizedDevices = await client.listDevices();

      AsiDeviceInfo? deviceToReopen;

      for (final device in authorizedDevices) {
        if (device.id == currentDevice.id) {
          deviceToReopen = device;
          break;
        }
      }

      if (deviceToReopen == null && authorizedDevices.length == 1) {
        deviceToReopen = authorizedDevices.first;
      }

      if (deviceToReopen == null) {
        throw const AsiUsbDeviceNotFoundException(
          'Impossible de retrouver le capteur après la réinitialisation USB',
        );
      }

      appendLog('Réouverture automatique de la connexion USB...');

      final reopenedSession = await client.open(deviceToReopen);

      try {
        await Future<void>.delayed(
          const Duration(milliseconds: 1200),
        );

        /*
         * Le cycle manuel repasse par connectDevice(), qui relit l'UUID.
         * On reproduit également cette commande avant le second download.
         */
        final reopenedUuid = await client.readDeviceId(reopenedSession);

        if (reopenedUuid.trim().isNotEmpty) {
          deviceId = reopenedUuid;
          appendLog('UUID après reconnexion: $reopenedUuid');
        }

        if (mounted) {
          setState(() {
            session = reopenedSession;
            selectedDevice = deviceToReopen;
            deviceConnected = true;
          });
        } else {
          session = reopenedSession;
          selectedDevice = deviceToReopen;
          deviceConnected = true;
        }

        await Future<void>.delayed(
          const Duration(milliseconds: 500),
        );

        appendLog('Deuxième essai de téléchargement...');

        return await client.downloadData(reopenedSession);
      } catch (_) {
        /*
         * En cas d'échec, la session reste référencée dans session afin que
         * le bouton Déconnecter puisse encore la fermer proprement.
         */
        if (session == null) {
          session = reopenedSession;
        }
        rethrow;
      }
    }
  }

  Future<void> download() async {
    if (session == null) {
      appendLog('Aucune session ouverte');
      return;
    }

    setState(() => loading = true);

    bool success = false;

    try {
      final watch = Stopwatch()..start();

      await Future.delayed(const Duration(milliseconds: 500));

      final Uint8List data = await _downloadWithAutomaticReconnect();

      watch.stop();
      appendLog('Lecture RAW terminée en ${watch.elapsed.inSeconds}s');
      appendLog('Téléchargé: ${data.length} octets');
      appendLog('Hash OK');

      if (data.isEmpty) {
        appendLog('Pas de données');
        return;
      }

      if (deviceId == null || deviceId!.trim().isEmpty) {
        try {
          final uuid = await client.readDeviceId(session!);
          if (uuid.trim().isNotEmpty) {
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

      final rows = TrackerDeviceRawNoHeaderParser.parseCsv(
        csv: csv,
        deviceId: deviceId!,
        periods: widget.periods,
      );

      appendLog('${rows.length} point(s) brut(s) parsé(s)');

      if (rows.isEmpty) {
        appendLog('Aucune donnée exploitable trouvée dans le CSV');
        return;
      }

      final trackerSamples = rows.map((row) {
        return TrackerRaw(
          trackerId: widget.trackerId,
          timeMs: row.timestamp.millisecondsSinceEpoch,
          latitude: row.latitude!,
          longitude: row.longitude!,
          speedMps: row.speed ?? 0,
        );
      }).toList(growable: false);

      if (widget.isMatch == true && widget.fieldGpsCorners != null) {
        footballFieldGps = FootballFieldGps.fromFieldGpsCorners(
          widget.fieldGpsCorners!,
        );
      } else {
        footballFieldGps = null;
      }

      final analysisResult = SensorAnalysisService.analyzeSensorData(
        trackerId: widget.trackerId,
        allSamples: trackerSamples,
        isMatch: widget.isMatch,
        playerId: widget.playerId,
        fieldGps: footballFieldGps,
        eventId: widget.eventId,
      );

      await TrackerAnalysisService.saveAnalysis(
        docId: '${widget.eventId}_${widget.trackerId}',
        analysisResult,
        eventId: widget.eventId,
        isMatch: widget.isMatch,
      );

      if (widget.isMatch == true && footballFieldGps != null) {
        final String svgFullMatch = HeatmapSvgGenerator.generateSvg(
          field: footballFieldGps!,
          heatmapPoints: analysisResult.heatmapPoints,
          flipX: false,
          flipY: false,
          svgWidth: 1600,
          svgHeight: 1000,
        );

        await HeatmapSvgGenerator.saveSvgToFirestore(
          fileName: '${widget.trackerId}-${widget.eventId}_fullMatch',
          svg: svgFullMatch,
        );

        final fullMatchSprintPolylines = _buildSprintPolylines(trackerSamples);

        final String svgFullMatchWithSprints = HeatmapSvgGenerator.generateSvg(
          field: footballFieldGps!,
          heatmapPoints: analysisResult.heatmapPoints,
          sprintPolylines: fullMatchSprintPolylines,
          flipX: false,
          flipY: false,
          svgWidth: 1600,
          svgHeight: 1000,
        );

        await HeatmapSvgGenerator.saveSvgToFirestore(
          fileName: '${widget.trackerId}-${widget.eventId}_fullMatchWithSprints',
          svg: svgFullMatchWithSprints,
        );

        final firstHalfSamples = _getSamplesForPeriod(
          period: _firstHalfPeriod,
          allTrackerSamples: trackerSamples,
        );

        final secondHalfSamples = _getSamplesForPeriod(
          period: _secondHalfPeriod,
          allTrackerSamples: trackerSamples,
        );

        TrackerAnalysisResult? firstHalfAnalysis;
        TrackerAnalysisResult? secondHalfAnalysis;

        if (firstHalfSamples.isNotEmpty) {
          firstHalfAnalysis = SensorAnalysisService.analyzeSensorData(
            trackerId: widget.trackerId,
            allSamples: firstHalfSamples,
            isMatch: widget.isMatch,
            playerId: widget.playerId,
            fieldGps: footballFieldGps,
            eventId: widget.eventId,
          );
        }

        if (secondHalfSamples.isNotEmpty) {
          secondHalfAnalysis = SensorAnalysisService.analyzeSensorData(
            trackerId: widget.trackerId,
            allSamples: secondHalfSamples,
            isMatch: widget.isMatch,
            playerId: widget.playerId,
            fieldGps: footballFieldGps,
            eventId: widget.eventId,
          );
        }

        const bool flipFirstHalfY = false;
        const bool flipSecondHalfY = false;

        if (firstHalfAnalysis != null) {
          final firstHalfPointsForDisplay = flipFirstHalfY
              ? _flipHeatmapPointsY(
            points: firstHalfAnalysis.heatmapPoints,
            field: footballFieldGps!,
          )
              : firstHalfAnalysis.heatmapPoints;

          final firstHalfSprintsRaw = _buildSprintPolylines(firstHalfSamples);

          final firstHalfSprintsForDisplay = flipFirstHalfY
              ? _flipPolylinesY(
            polylines: firstHalfSprintsRaw,
            field: footballFieldGps!,
          )
              : firstHalfSprintsRaw;

          final String svgFirstHalf = HeatmapSvgGenerator.generateSvg(
            field: footballFieldGps!,
            heatmapPoints: firstHalfPointsForDisplay,
            sprintPolylines: const [],
            flipX: false,
            flipY: false,
            svgWidth: 1600,
            svgHeight: 1000,
          );

          await HeatmapSvgGenerator.saveSvgToFirestore(
            fileName: '${widget.trackerId}-${widget.eventId}_firstHalf',
            svg: svgFirstHalf,
          );

          final String svgFirstHalfWithSprints = HeatmapSvgGenerator.generateSvg(
            field: footballFieldGps!,
            heatmapPoints: firstHalfPointsForDisplay,
            sprintPolylines: firstHalfSprintsForDisplay,
            flipX: false,
            flipY: false,
            svgWidth: 1600,
            svgHeight: 1000,
          );

          await HeatmapSvgGenerator.saveSvgToFirestore(
            fileName: '${widget.trackerId}-${widget.eventId}_firstHalfWithSprints',
            svg: svgFirstHalfWithSprints,
          );
        }

        if (secondHalfAnalysis != null) {
          final secondHalfPointsForDisplay = flipSecondHalfY
              ? _flipHeatmapPointsY(
            points: secondHalfAnalysis.heatmapPoints,
            field: footballFieldGps!,
          )
              : secondHalfAnalysis.heatmapPoints;

          final secondHalfSprintsRaw = _buildSprintPolylines(secondHalfSamples);

          final secondHalfSprintsForDisplay = flipSecondHalfY
              ? _flipPolylinesY(
            polylines: secondHalfSprintsRaw,
            field: footballFieldGps!,
          )
              : secondHalfSprintsRaw;

          final String svgSecondHalf = HeatmapSvgGenerator.generateSvg(
            field: footballFieldGps!,
            heatmapPoints: secondHalfPointsForDisplay,
            sprintPolylines: const [],
            flipX: false,
            flipY: false,
            svgWidth: 1600,
            svgHeight: 1000,
          );

          await HeatmapSvgGenerator.saveSvgToFirestore(
            fileName: '${widget.trackerId}-${widget.eventId}_secondHalf',
            svg: svgSecondHalf,
          );

          final String svgSecondHalfWithSprints = HeatmapSvgGenerator.generateSvg(
            field: footballFieldGps!,
            heatmapPoints: secondHalfPointsForDisplay,
            sprintPolylines: secondHalfSprintsForDisplay,
            flipX: false,
            flipY: false,
            svgWidth: 1600,
            svgHeight: 1000,
          );

          await HeatmapSvgGenerator.saveSvgToFirestore(
            fileName: '${widget.trackerId}-${widget.eventId}_secondHalfWithSprints',
            svg: svgSecondHalfWithSprints,
          );
        }
      }

      final start = rows.first.timestamp.toDate();
      final end = rows.last.timestamp.toDate();
      final duration = end.difference(start);

      appendLog('Début: ${start.toIso8601String()}');
      appendLog('Fin: ${end.toIso8601String()}');
      appendLog(
        'Durée: ${duration.inMinutes} min ${duration.inSeconds % 60} s',
      );

      if (duration.inMilliseconds > 0 && rows.length > 1) {
        final hz = ((rows.length - 1) / (duration.inMilliseconds / 1000))
            .toStringAsFixed(2);
        appendLog('Fréquence estimée: $hz Hz');
      }
      success = true;

      if(eventSync != null) {
        Map<String, DeviceSync> devices = eventSync!.devices;
        DeviceSync? deviceSync = devices[widget.trackerId];
        if(deviceSync != null) {
          deviceSync.dataDownloaded = true;
          deviceSync.dataDownloadedAt = Timestamp.now();
          deviceSync.dataDownloadedUid = FirebaseAuth.instance.currentUser?.uid;
          devices[widget.trackerId] = deviceSync;
          await EventSyncService().createOrUpdateEventSync(eventSync!);
        }
      }


    } on AsiDownloadTimeoutException catch (e) {
      appendLog(e.message);
      appendLog(e.userInstructions);
      debugPrint('DOWNLOAD_TIMEOUT: $e');
    } catch (e, st) {
      appendLog('Erreur download: $e');
      debugPrint('DOWNLOAD_ERROR: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
          dataDownloaded = success;
        });
      }
    }
  }

  List<HeatmapPoint> _flipHeatmapPointsY({
    required List<HeatmapPoint> points,
    required FootballFieldGps field,
  }) {
    return points.map((p) {
      return HeatmapPoint(
        xMeters: p.xMeters,
        yMeters: field.fieldWidthMeters - p.yMeters,
        timeMs: p.timeMs,
        intensity: p.intensity,
      );
    }).toList(growable: false);
  }

  List<PitchPolyline> _flipPolylinesY({
    required List<PitchPolyline> polylines,
    required FootballFieldGps field,
  }) {
    return polylines.map((polyline) {
      return PitchPolyline(
        pointsM: polyline.pointsM.map((p) {
          return Offset(p.dx, field.fieldWidthMeters - p.dy);
        }).toList(growable: false),
        segmentIntensity01: polyline.segmentIntensity01,
        strokeWidth: polyline.strokeWidth,
        showArrow: polyline.showArrow,
        showStartEndDots: polyline.showStartEndDots,
      );
    }).toList(growable: false);
  }

  List<TimeRange> get _sortedPeriods {
    final list = [...widget.periods];
    list.sort((a, b) {
      final aMs = a.start.toDate().millisecondsSinceEpoch ?? 0;
      final bMs = b.start.toDate().millisecondsSinceEpoch ?? 0;
      return aMs.compareTo(bMs);
    });
    return list;
  }

  TimeRange? get _firstHalfPeriod {
    if (_sortedPeriods.isEmpty) return null;
    return _sortedPeriods.first;
  }

  TimeRange? get _secondHalfPeriod {
    if (_sortedPeriods.length < 2) return null;
    return _sortedPeriods[1];
  }

  List<TrackerRaw> _getSamplesForPeriod({required TimeRange? period, required List<TrackerRaw> allTrackerSamples}) {
    if (period == null || allTrackerSamples.isEmpty) return const [];

    final startMs = period.start.toDate().millisecondsSinceEpoch;
    final endMs = period.end.toDate().millisecondsSinceEpoch;

    return allTrackerSamples.where((sample) {
      return sample.timeMs >= startMs && sample.timeMs <= endMs;
    }).toList(growable: false);
  }

  List<List<TrackerRaw>> _extractSprintSegments(List<TrackerRaw> samples) {
    final List<List<TrackerRaw>> segments = [];
    List<TrackerRaw> current = [];

    for (final sample in samples) {
      final speedKmh = sample.speedMps * 3.6;

      if (speedKmh >= _sprintThresholdKmh) {
        current.add(sample);
      } else {
        if (current.length >= _minSprintPoints) {
          segments.add(List<TrackerRaw>.from(current));
        }
        current = [];
      }
    }

    if (current.length >= _minSprintPoints) {
      segments.add(List<TrackerRaw>.from(current));
    }

    return segments;
  }

  List<PitchPolyline> _buildSprintPolylines(List<TrackerRaw> samples) {
    final segments = _extractSprintSegments(samples);
    if (segments.isEmpty) return const [];

    final List<PitchPolyline> polylines = [];

    for (final segment in segments) {
      final sprintAnalysis = SensorAnalysisService.analyzeSensorData(
        trackerId: widget.trackerId,
        allSamples: segment,
        isMatch: widget.isMatch,
        playerId: widget.playerId,
        fieldGps: footballFieldGps,
        eventId: widget.eventId,
      );

      if (sprintAnalysis.heatmapPoints.length < 2) continue;

      polylines.add(
        PitchPolyline(
          pointsM: PitchHeatmapBuilder.polylineFromHeatmapPoints(
            sprintAnalysis.heatmapPoints,
          ),
          segmentIntensity01:
          PitchHeatmapBuilder.segmentIntensityFromHeatmapPoints(
            sprintAnalysis.heatmapPoints,
          ),
          strokeWidth: 3.2,
          showArrow: true,
          showStartEndDots: false,
        ),
      );
    }

    return polylines;
  }

  Future<void> eraseData() async {
    if (session == null) {
      appendLog('Aucune session ouverte');
      return;
    }

    setState(() => loading = true);

    bool success = false;



    try {
      appendLog('Effacement en cours...');
      await client.eraseData(session!);
      appendLog('Effacement terminé ou aucune donnée à effacer');
      success = true;
    } catch (e, st) {
      appendLog('Erreur erase data: $e');
      debugPrint('ERASE_ERROR: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      if (mounted) {
        if(success == true) {
          if(eventSync != null) {
            Map<String, DeviceSync> devices = eventSync!.devices;
            DeviceSync? deviceSync = devices[widget.trackerId];
            if(deviceSync != null) {
              deviceSync.erased = true;
              deviceSync.erasedAt = Timestamp.now();
              deviceSync.erasedUid = FirebaseAuth.instance.currentUser?.uid;
              devices[widget.trackerId] = deviceSync;
              await EventSyncService().createOrUpdateEventSync(eventSync!);
            }
          }

        }
        setState(() {
          loading = false;
          dataErased = success;
        });
      }
    }
  }
  Future<void> eraseAll() async {
    if (session == null) {
      appendLog('Aucune session ouverte');
      return;
    }

    setState(() => loading = true);
    try {
      await client.eraseAll(session!);
      appendLog('Pod fully erased');
    } catch (e) {
      appendLog('Erreur erase all: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }



  @override
  void dispose() {
    final currentSession = session;
    if (currentSession != null) {
      client.close(currentSession).catchError((_) {});
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      color: colors.background,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tracker sélectionné',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.trackerId,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final safeDeviceId = widget.trackerId;
                  final safePeriods = widget.periods ?? <TimeRange>[];
                  if (safeDeviceId.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Aucun deviceId disponible'),
                      ),
                    );
                    return;
                  }
                  showAsiConverterDialog(
                    context: context,
                    deviceId: safeDeviceId,
                    periods: safePeriods,
                    isMatch: widget.isMatch,
                    eventId: widget.eventId,
                    fieldGpsCorners: widget.fieldGpsCorners,
                    playerId: widget.playerId,
                    eventSync: widget.eventSync,
                    ownerId: widget.ownerId,
                  );
                },
                icon: const Icon(Icons.insert_drive_file),
                label: const Text('Fichier .asi'),
              )
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: (deviceConnected) ? null : connectDevice,
                icon: const Icon(Icons.usb_rounded),
                label: const Text('Connecter'),
              ),

              ElevatedButton.icon(
                onPressed: (deviceConnected && !loading) ? download : null,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Télécharger'),
              ),

              ElevatedButton.icon(
                onPressed: (deviceConnected && dataDownloaded && !loading) ? eraseData : null,
                icon: const Icon(Icons.delete_sweep_rounded),
                label: const Text('Effacer les données'),
              ),

              ElevatedButton.icon(
                onPressed: (deviceConnected && !loading) ? disconnect : null,
                icon: const Icon(Icons.link_off_rounded),
                label: const Text('Déconnecter'),
              ),

            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(
                  loading ? Icons.sync_rounded : Icons.memory_rounded,
                  color: loading ? colors.primary : colors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectedDevice == null
                        ? 'Aucun périphérique connecté'
                        : 'Périphérique: ${selectedDevice!.productName ?? selectedDevice!.id}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (loading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.border),
              ),
              child: logs.trim().isEmpty
                  ? Center(
                child: Text(
                  'Les logs apparaîtront ici.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              )
                  : SingleChildScrollView(
                child: SelectableText(
                  logs,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> disconnect() async {
    try {
      if (session != null) {
        await client.close(session!);
      }

      appendLog('Device déconnecté');

      if (mounted) {
        setState(() {
          session = null;
          deviceConnected = false;
          deviceId = null;
          loading = false;
          selectedDevice = null;
          dataDownloaded = false;
          dataErased = false;
          footballFieldGps = null;
        });
      }
    } catch (e) {
      appendLog('Erreur déconnexion: $e');
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

}