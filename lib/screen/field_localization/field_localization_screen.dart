import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../core/extensions/l10n_extension.dart';
import '../../model/fieldGpsCorners.dart';
import '../../util/app_theme.dart';

part 'field_localization_models.dart';
part 'field_localization_widgets.dart';

class FootballFieldLocalizationScreen extends StatefulWidget {
  final String initialName;
  final String initialAddress;
  final FieldGpsCorners? initialFieldGpsCorners;
  final LatLng initialTarget;
  final double initialZoom;
  final String googleMapsApiKey;

  /// Dimensions visuelles de référence pour un terrain à 11.
  /// Les vraies dimensions finales sont calculées depuis les 4 coins GPS.
  final double referenceFieldLengthMeters;
  final double referenceFieldWidthMeters;

  const FootballFieldLocalizationScreen({
    super.key,
    this.initialName = '',
    this.initialAddress = '',
    this.initialFieldGpsCorners,
    this.initialTarget = const LatLng(46.227638, 2.213749),
    this.initialZoom = 18.0,
    this.googleMapsApiKey = kGoogleMapsApiKey,
    this.referenceFieldLengthMeters = 105.0,
    this.referenceFieldWidthMeters = 68.0,
  });

  @override
  State<FootballFieldLocalizationScreen> createState() =>
      _FootballFieldLocalizationScreenState();
}

class _FootballFieldLocalizationScreenState
    extends State<FootballFieldLocalizationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  GoogleMapController? _mapController;
  MapType _mapType = MapType.hybrid;

  LatLng? _initialMapTarget;

  LatLng? _currentMapTarget;
  double _currentMapZoom = 18.0;

  /// Geographic size of the overlay (kept in sync with map zoom).
  late double _fieldWidthMeters;
  late double _fieldLengthMeters;

  bool _overlayInitialized = false;
  bool _isRestoringInitialCorners = false;
  /// When false, overlay pixels come from GPS screen projection (restore).
  /// When true, overlay pixels follow [_fieldWidthMeters]/[_fieldLengthMeters].
  bool _metersDrivePixelSize = true;
  bool _isComputingCorners = false;
  bool _isSearchingAddress = false;
  /// Sur mobile, la carte doit recevoir les gestes par défaut (mode carte).
  /// Sur web, on garde l’édition du terrain en priorité.
  bool _fieldEditMode = kIsWeb;

  bool get _hasInitialCorners =>
      widget.initialFieldGpsCorners?.isComplete == true;

  /// Ignore previously saved corners when they are geometrically broken.
  bool get _hasUsableInitialCorners {
    final corners = widget.initialFieldGpsCorners;
    if (corners == null || !corners.isComplete) return false;
    return _cornersLookRectangular(corners);
  }

  /// Android `getLatLng` / `getScreenCoordinate` use physical pixels.
  /// iOS and web use logical pixels (Flutter layout space).
  double get _mapPixelRatio {
    if (kIsWeb) return 1.0;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return MediaQuery.devicePixelRatioOf(context);
    }
    return 1.0;
  }

  ScreenCoordinate _toScreenCoordinate(Offset point) {
    final ratio = _mapPixelRatio;
    return ScreenCoordinate(
      x: (point.dx * ratio).round(),
      y: (point.dy * ratio).round(),
    );
  }

  Offset _fromScreenCoordinate(ScreenCoordinate coordinate) {
    final ratio = _mapPixelRatio;
    return Offset(coordinate.x / ratio, coordinate.y / ratio);
  }

  Size _mapSize = Size.zero;
  Offset _fieldCenter = Offset.zero;

  /// Largeur visuelle du terrain à l'écran.
  double _fieldWidth = 190.0;

  /// Longueur visuelle du terrain à l'écran.
  /// Elle est volontairement indépendante de [_fieldWidth] pour pouvoir
  /// ajuster séparément la longueur et la largeur.
  double _fieldLength = 293.0;

  double _rotationRadians = 0.0;

  Offset _gestureStartCenter = Offset.zero;
  Offset _gestureStartFocal = Offset.zero;
  double _gestureStartWidth = 190.0;
  double _gestureStartLength = 293.0;
  double _gestureStartRotation = 0.0;

  int _playersPerTeam = 11;

  double get _fieldAspectRatio =>
      widget.referenceFieldLengthMeters / widget.referenceFieldWidthMeters;

  double get _fieldHeight => _fieldLength;

  bool get _hasInitialAddress => widget.initialAddress.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName;
    _addressController.text = widget.initialAddress;
    _fieldWidthMeters = widget.referenceFieldWidthMeters;
    _fieldLengthMeters = widget.referenceFieldLengthMeters;
    // Affiche la carte tout de suite (évite blocage géoloc sur simulateur).
    final initialCorners = widget.initialFieldGpsCorners;
    final cornersCenter = _hasUsableInitialCorners
        ? _fieldCenterLatLngFromCorners(initialCorners!)
        : null;
    _initialMapTarget = cornersCenter ?? widget.initialTarget;
    _currentMapTarget = cornersCenter ?? widget.initialTarget;
    _currentMapZoom = widget.initialZoom;
    if (!_hasUsableInitialCorners &&
        !_hasInitialAddress &&
        _isDefaultFranceTarget(widget.initialTarget)) {
      unawaited(_tryRefineLocationFromGps());
    }
  }

  bool _isDefaultFranceTarget(LatLng target) {
    return (target.latitude - 46.227638).abs() < 0.0001 &&
        (target.longitude - 2.213749).abs() < 0.0001;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    final target = _initialMapTarget ?? _currentMapTarget;
    if (target == null) return;

    try {
      await controller.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: target,
            zoom: _currentMapZoom,
          ),
        ),
      );
    } catch (_) {
      // La carte native peut ne pas être prête immédiatement sur iOS/Android.
    }

    if (_hasUsableInitialCorners) {
      unawaited(_restoreOverlayFromInitialCorners());
    } else if (!_isDefaultFranceTarget(widget.initialTarget)) {
      // Prefer fieldClub.location over address geocoding for map center.
      unawaited(_focusInitialTargetAndPlaceOverlay());
    } else if (_hasInitialAddress) {
      unawaited(_searchAddress());
    } else {
      // Re-measure scale once the native map projection is ready.
      unawaited(() async {
        await Future<void>.delayed(const Duration(milliseconds: 220));
        if (!mounted || !_overlayInitialized || !_metersDrivePixelSize) {
          return;
        }
        await _applyPixelSizeFromMeters();
        if (mounted) {
          setState(() {
            _fieldCenter = Offset(_mapSize.width / 2.0, _mapSize.height / 2.0);
          });
        }
      }());
    }
  }

  Future<void> _focusInitialTargetAndPlaceOverlay() async {
    final controller = _mapController;
    if (controller == null) return;

    const zoom = 18.8;
    final target = widget.initialTarget;
    _currentMapTarget = target;
    _currentMapZoom = zoom;

    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: zoom),
        ),
      );
    } catch (_) {
      // Map may not be ready yet.
    }

    await _centerOverlayInMap(resizeFromCurrentZoom: true);
  }

  /// Ne demande pas la permission à l'ouverture (bloquant sur simulateur).
  /// Recentre seulement si l'utilisateur a déjà autorisé la localisation.
  Future<void> _tryRefineLocationFromGps() async {
    try {
      final permission = await Geolocator.checkPermission();
      final granted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      if (!granted || !await Geolocator.isLocationServiceEnabled()) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );

      if (!mounted) return;

      final target = LatLng(position.latitude, position.longitude);
      setState(() {
        _initialMapTarget = target;
        _currentMapTarget = target;
      });

      final controller = _mapController;
      if (controller != null) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(target, _currentMapZoom),
        );
      }
    } catch (_) {
      // Simulateur sans position simulée : on garde la France par défaut.
    }
  }

  Future<void> _goToCurrentLocation() async {
    final controller = _mapController;
    if (controller == null) return;

    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      _showSnackBar(context.l10n.fieldSnackbarLocationDisabled);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    final granted = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    if (!mounted) return;

    if (!granted) {
      _showSnackBar(context.l10n.fieldSnackbarAllowLocation);
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      final target = LatLng(position.latitude, position.longitude);
      const zoom = 18.8;

      _currentMapTarget = target;
      _currentMapZoom = zoom;

      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: target,
            zoom: zoom,
          ),
        ),
      );

      unawaited(_centerOverlayInMap(resizeFromCurrentZoom: true));
    } catch (_) {
      _showSnackBar(context.l10n.fieldSnackbarGpsFailed);
    }
  }

  Future<void> _searchAddress() async {
    final query = _addressController.text.trim();
    final controller = _mapController;

    if (query.isEmpty) {
      _showSnackBar(context.l10n.fieldSnackbarEnterAddress);
      return;
    }

    if (controller == null) {
      _showSnackBar(context.l10n.fieldSnackbarMapNotReady);
      return;
    }

    final apiKey = widget.googleMapsApiKey.trim();

    if (apiKey.isEmpty || apiKey == 'TA_CLE_GOOGLE_MAPS_ICI') {
      _showSnackBar(
        context.l10n.fieldSnackbarGoogleMapsKeyMissing,
      );
      return;
    }

    setState(() => _isSearchingAddress = true);

    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/geocode/json',
        {
          'address': query,
          'key': apiKey,
          'language': 'fr',
          'region': 'fr',
        },
      );

      final response = await http.get(uri);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status']?.toString() ?? 'UNKNOWN';

      if (response.statusCode != 200 || status != 'OK') {
        _showSnackBar(context.l10n.fieldSnackbarAddressNotFoundWithStatus(status));
        return;
      }

      final results = data['results'] as List<dynamic>;
      if (results.isEmpty) {
        _showSnackBar(context.l10n.fieldSnackbarAddressNotFound);
        return;
      }

      final first = results.first as Map<String, dynamic>;
      final geometry = first['geometry'] as Map<String, dynamic>;
      final location = geometry['location'] as Map<String, dynamic>;

      final target = LatLng(
        (location['lat'] as num).toDouble(),
        (location['lng'] as num).toDouble(),
      );

      const zoom = 18.8;

      _currentMapTarget = target;
      _currentMapZoom = zoom;

      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: target,
            zoom: zoom,
          ),
        ),
      );

      unawaited(_centerOverlayInMap(resizeFromCurrentZoom: true));
    } catch (_) {
      _showSnackBar(
        context.l10n.fieldSnackbarGeocodingFailed,
      );
    } finally {
      if (mounted) {
        setState(() => _isSearchingAddress = false);
      }
    }
  }

  LatLng? _fieldCenterLatLngFromCorners(FieldGpsCorners corners) {
    final points = <FieldCornerGps?>[
      corners.topLeft,
      corners.topRight,
      corners.bottomLeft,
      corners.bottomRight,
    ].whereType<FieldCornerGps>().toList();

    if (points.isEmpty) return null;

    final latitude = points
        .map((p) => p.latitude)
        .reduce((a, b) => a + b) /
        points.length;

    final longitude = points
        .map((p) => p.longitude)
        .reduce((a, b) => a + b) /
        points.length;

    return LatLng(latitude, longitude);
  }
  Future<String?> _reverseGeocodeAddressFromCorners(
      FieldGpsCorners corners,
      ) async {
    final apiKey = widget.googleMapsApiKey.trim();

    if (apiKey.isEmpty || apiKey == 'TA_CLE_GOOGLE_MAPS_ICI') {
      return null;
    }

    final center = _fieldCenterLatLngFromCorners(corners);
    if (center == null) return null;

    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/geocode/json',
        {
          'latlng': '${center.latitude},${center.longitude}',
          'key': apiKey,
          'language': 'fr',
          'region': 'fr',
        },
      );

      final response = await http.get(uri);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status']?.toString() ?? 'UNKNOWN';

      if (response.statusCode != 200 || status != 'OK') {
        debugPrint('Reverse geocoding error: $status');
        return null;
      }

      final results = data['results'] as List<dynamic>;
      if (results.isEmpty) return null;

      final first = results.first as Map<String, dynamic>;

      return first['formatted_address']?.toString();
    } catch (e) {
      debugPrint('Reverse geocoding exception: $e');
      return null;
    }
  }

  /// Fallback only — prefer [_metersPerLogicalPixelFromMap].
  double _metersPerPixelFormula({
    required double latitude,
    required double zoom,
  }) {
    return 156543.03392 *
        math.cos(latitude * math.pi / 180.0) /
        math.pow(2.0, zoom);
  }

  /// Ground-truth scale using the same projection as overlay save/restore.
  Future<double?> _metersPerLogicalPixelFromProjection() async {
    final controller = _mapController;
    if (controller == null || _mapSize.width <= 0 || _mapSize.height <= 0) {
      return null;
    }

    try {
      final center = Offset(_mapSize.width / 2.0, _mapSize.height / 2.0);
      const sampleLogicalPx = 100.0;

      final left = await controller.getLatLng(
        _toScreenCoordinate(center.translate(-sampleLogicalPx / 2.0, 0)),
      );
      final right = await controller.getLatLng(
        _toScreenCoordinate(center.translate(sampleLogicalPx / 2.0, 0)),
      );
      final top = await controller.getLatLng(
        _toScreenCoordinate(center.translate(0, -sampleLogicalPx / 2.0)),
      );
      final bottom = await controller.getLatLng(
        _toScreenCoordinate(center.translate(0, sampleLogicalPx / 2.0)),
      );

      final widthMeters = Geolocator.distanceBetween(
        left.latitude,
        left.longitude,
        right.latitude,
        right.longitude,
      );
      final heightMeters = Geolocator.distanceBetween(
        top.latitude,
        top.longitude,
        bottom.latitude,
        bottom.longitude,
      );

      final mppX = widthMeters / sampleLogicalPx;
      final mppY = heightMeters / sampleLogicalPx;
      if (mppX <= 0 || mppY <= 0 || !mppX.isFinite || !mppY.isFinite) {
        return null;
      }

      return (mppX + mppY) / 2.0;
    } catch (e) {
      debugPrint('metersPerLogicalPixelFromProjection failed: $e');
      return null;
    }
  }

  Future<double> _resolveMetersPerLogicalPixel() async {
    final fromProjection = await _metersPerLogicalPixelFromProjection();
    if (fromProjection != null) return fromProjection;

    final target =
        _currentMapTarget ?? _initialMapTarget ?? widget.initialTarget;
    return _metersPerPixelFormula(
      latitude: target.latitude,
      zoom: _currentMapZoom,
    );
  }

  Size _fieldPixelSizeForMetersPerPixel(
    Size mapSize,
    double metersPerPixel, {
    double? widthMeters,
    double? lengthMeters,
  }) {
    if (metersPerPixel <= 0) {
      return const Size(60, 90);
    }

    final widthPixels = (widthMeters ?? _fieldWidthMeters) / metersPerPixel;
    final lengthPixels = (lengthMeters ?? _fieldLengthMeters) / metersPerPixel;

    final maxWidth = math.max(60.0, mapSize.width * 0.98);
    final maxLength = math.max(90.0, mapSize.height * 0.98);

    return Size(
      widthPixels.clamp(40.0, maxWidth).toDouble(),
      lengthPixels.clamp(40.0, maxLength).toDouble(),
    );
  }

  Future<void> _applyPixelSizeFromMeters() async {
    if (_mapSize == Size.zero || !mounted) return;

    final metersPerPixel = await _resolveMetersPerLogicalPixel();
    if (!mounted) return;

    final fieldSize = _fieldPixelSizeForMetersPerPixel(
      _mapSize,
      metersPerPixel,
    );

    setState(() {
      _fieldWidth = fieldSize.width;
      _fieldLength = fieldSize.height;
    });
  }

  Future<void> _syncMetersFromPixels() async {
    final metersPerPixel = await _resolveMetersPerLogicalPixel();
    if (metersPerPixel <= 0) return;
    _fieldWidthMeters = _fieldWidth * metersPerPixel;
    _fieldLengthMeters = _fieldLength * metersPerPixel;
  }

  void _initializeOverlayIfNeeded(Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    _mapSize = size;
    if (_overlayInitialized || _isRestoringInitialCorners) return;

    if (_hasUsableInitialCorners) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _overlayInitialized || _isRestoringInitialCorners) {
          return;
        }
        unawaited(_restoreOverlayFromInitialCorners());
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _overlayInitialized || _hasUsableInitialCorners) return;

      final metersPerPixel = await _resolveMetersPerLogicalPixel();
      if (!mounted || _overlayInitialized || _hasUsableInitialCorners) return;

      final fieldSize = _fieldPixelSizeForMetersPerPixel(size, metersPerPixel);

      setState(() {
        _mapSize = size;
        _fieldWidth = fieldSize.width;
        _fieldLength = fieldSize.height;
        _fieldCenter = Offset(size.width / 2.0, size.height / 2.0);
        _overlayInitialized = true;
      });
    });
  }

  Future<void> _restoreOverlayFromInitialCorners({bool force = false}) async {
    final corners = widget.initialFieldGpsCorners;
    final controller = _mapController;
    if (corners == null ||
        !corners.isComplete ||
        !_cornersLookRectangular(corners) ||
        controller == null ||
        _isRestoringInitialCorners ||
        (_overlayInitialized && !force)) {
      return;
    }

    _isRestoringInitialCorners = true;
    try {
      final center = _fieldCenterLatLngFromCorners(corners);
      if (center == null) return;

      final lats = <double>[
        corners.topLeft!.latitude,
        corners.topRight!.latitude,
        corners.bottomLeft!.latitude,
        corners.bottomRight!.latitude,
      ];
      final lngs = <double>[
        corners.topLeft!.longitude,
        corners.topRight!.longitude,
        corners.bottomLeft!.longitude,
        corners.bottomRight!.longitude,
      ];

      try {
        await controller.moveCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(
                lats.reduce(math.min),
                lngs.reduce(math.min),
              ),
              northeast: LatLng(
                lats.reduce(math.max),
                lngs.reduce(math.max),
              ),
            ),
            72,
          ),
        );
      } catch (_) {
        await controller.moveCamera(
          CameraUpdate.newLatLngZoom(center, _currentMapZoom),
        );
      }

      // Let the camera + layout settle before reading screen coordinates.
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (!mounted || _mapController == null) return;

      if (_mapSize == Size.zero) {
        _isRestoringInitialCorners = false;
        return;
      }

      Future<Offset> screenOf(FieldCornerGps corner) async {
        final coordinate = await controller.getScreenCoordinate(
          LatLng(corner.latitude, corner.longitude),
        );
        return _fromScreenCoordinate(coordinate);
      }

      final tl = await screenOf(corners.topLeft!);
      final tr = await screenOf(corners.topRight!);
      final br = await screenOf(corners.bottomRight!);
      final bl = await screenOf(corners.bottomLeft!);

      final fieldCenter = Offset(
        (tl.dx + tr.dx + br.dx + bl.dx) / 4.0,
        (tl.dy + tr.dy + br.dy + bl.dy) / 4.0,
      );

      final topEdge = tr - tl;
      final bottomEdge = br - bl;
      final leftEdge = bl - tl;
      final rightEdge = br - tr;

      final width = (topEdge.distance + bottomEdge.distance) / 2.0;
      final length = (leftEdge.distance + rightEdge.distance) / 2.0;
      final rotation = math.atan2(topEdge.dy, topEdge.dx);

      final topM = FieldCornerGps.distanceMeters(
        corners.topLeft!,
        corners.topRight!,
      );
      final bottomM = FieldCornerGps.distanceMeters(
        corners.bottomLeft!,
        corners.bottomRight!,
      );
      final leftM = FieldCornerGps.distanceMeters(
        corners.topLeft!,
        corners.bottomLeft!,
      );
      final rightM = FieldCornerGps.distanceMeters(
        corners.topRight!,
        corners.bottomRight!,
      );

      // Prefer projection-based size from measured meters (more stable than
      // noisy screen-edge lengths when DPR conversion is slightly off).
      _fieldWidthMeters = (topM + bottomM) / 2.0;
      _fieldLengthMeters = (leftM + rightM) / 2.0;
      final metersPerPixel = await _resolveMetersPerLogicalPixel();
      final sized = _fieldPixelSizeForMetersPerPixel(
        _mapSize,
        metersPerPixel,
      );

      if (!mounted) return;
      setState(() {
        _fieldCenter = fieldCenter;
        // Use screen-projected size when it is close to meter-based size;
        // otherwise trust the projection meter scale (avoids tiny overlays).
        final screenSize = Size(
          width.clamp(40.0, _mapSize.width * 0.98).toDouble(),
          length.clamp(40.0, _mapSize.height * 0.98).toDouble(),
        );
        final screenDiag = screenSize.longestSide;
        final meterDiag = sized.longestSide;
        final useScreen = screenDiag > 0 &&
            meterDiag > 0 &&
            (screenDiag / meterDiag - 1.0).abs() < 0.35;
        _fieldWidth = useScreen ? screenSize.width : sized.width;
        _fieldLength = useScreen ? screenSize.height : sized.height;
        _rotationRadians = rotation;
        _currentMapTarget = center;
        _overlayInitialized = true;
        _metersDrivePixelSize = true;
      });
    } catch (e, st) {
      debugPrint('restore overlay from corners failed: $e\n$st');
      if (!mounted || (_overlayInitialized && !force)) return;
      // Fallback: default centered overlay on the field center.
      final metersPerPixel = await _resolveMetersPerLogicalPixel();
      if (!mounted) return;
      final fieldSize = _fieldPixelSizeForMetersPerPixel(
        _mapSize,
        metersPerPixel,
      );
      setState(() {
        _fieldWidth = fieldSize.width;
        _fieldLength = fieldSize.height;
        _fieldCenter = Offset(
          _mapSize.width / 2.0,
          _mapSize.height / 2.0 + 20.0,
        );
        _overlayInitialized = true;
        _metersDrivePixelSize = true;
      });
    } finally {
      _isRestoringInitialCorners = false;
    }
  }


  Future<void> _centerOverlayInMap({bool resizeFromCurrentZoom = false}) async {
    if (!mounted || _mapSize == Size.zero) return;

    if (resizeFromCurrentZoom) {
      // Wait for the camera to settle so getVisibleRegion is accurate.
      await Future<void>.delayed(const Duration(milliseconds: 160));
      if (!mounted) return;
      final metersPerPixel = await _resolveMetersPerLogicalPixel();
      if (!mounted) return;
      final fieldSize = _fieldPixelSizeForMetersPerPixel(
        _mapSize,
        metersPerPixel,
      );
      setState(() {
        _fieldWidth = fieldSize.width;
        _fieldLength = fieldSize.height;
        _fieldCenter = Offset(_mapSize.width / 2.0, _mapSize.height / 2.0);
      });
      return;
    }

    setState(() {
      _fieldCenter = Offset(_mapSize.width / 2.0, _mapSize.height / 2.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _HeaderBar(
              isBusy: _isComputingCorners,
              onBack: () => Navigator.of(context).maybePop(),
              onValidate: _validateAndReturn,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: context.l10n.hintFieldName,
                ),
              ),
            ),
            _AddressSearchField(
              controller: _addressController,
              isSearching: _isSearchingAddress,
              onSearch: _searchAddress,
            ),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  border: Border(
                    top: BorderSide(color: colors.border),
                    left: BorderSide(color: colors.border),
                    right: BorderSide(color: colors.border),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    _initializeOverlayIfNeeded(size);

                    return Listener(
                      onPointerSignal: _handlePointerSignal,
                      child: Stack(
                        fit: StackFit.expand,
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: GoogleMap(
                              mapType: _mapType,
                              initialCameraPosition: CameraPosition(
                                target: _initialMapTarget ?? widget.initialTarget,
                                zoom: _currentMapZoom,
                              ),
                              myLocationEnabled: false,
                              myLocationButtonEnabled: false,
                              compassEnabled: false,
                              zoomControlsEnabled: false,
                              mapToolbarEnabled: false,
                              tiltGesturesEnabled: false,
                              rotateGesturesEnabled: false,
                              scrollGesturesEnabled: !_fieldEditMode,
                              zoomGesturesEnabled: !_fieldEditMode,
                              onMapCreated: _onMapCreated,
                              onCameraMove: (position) {
                                _currentMapTarget = position.target;
                                _currentMapZoom = position.zoom;
                              },
                              onCameraIdle: () {
                                if (!_overlayInitialized ||
                                    _isRestoringInitialCorners ||
                                    _fieldEditMode) {
                                  return;
                                }
                                // Keep overlay geographic size aligned after
                                // map zoom/pan in map mode.
                                if (_metersDrivePixelSize) {
                                  unawaited(_applyPixelSizeFromMeters());
                                } else if (_hasUsableInitialCorners) {
                                  unawaited(
                                    _restoreOverlayFromInitialCorners(
                                      force: true,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          if (_overlayInitialized && _fieldEditMode)
                            _buildFieldGestureLayer(),
                          Positioned(
                            top: 8,
                            left: 8,
                            right: 8,
                            child: _TopMapControls(
                              playersPerTeam: _playersPerTeam,
                              onPreviewGps: _showGpsPreview,
                            ),
                          ),
                          if (_overlayInitialized) _buildFieldOverlay(),
                          Positioned(
                            top: 54,
                            right: 8,
                            child: _FieldQuickControls(
                              onRotateLeft: () => _rotateByDegrees(-2),
                              onRotateRight: () => _rotateByDegrees(2),
                              onZoomIn: () => _resizeField(1.04),
                              onZoomOut: () => _resizeField(0.96),
                              onLengthIn: () => _resizeFieldLength(1.04),
                              onLengthOut: () => _resizeFieldLength(0.96),
                              onWidthIn: () => _resizeFieldWidth(1.04),
                              onWidthOut: () => _resizeFieldWidth(0.96),
                              onReset: _resetOverlay,
                            ),
                          ),
                          Positioned(
                            left: 10,
                            right: 10,
                            bottom: 58,
                            child: _FieldGestureHint(
                              fieldEditMode: _fieldEditMode,
                              onToggleMode: () {
                                setState(() {
                                  _fieldEditMode = !_fieldEditMode;
                                });
                              },
                            ),
                          ),
                          Positioned(
                            left: 10,
                            right: 10,
                            bottom: 10,
                            child: _BottomMapControls(
                              mapType: _mapType,
                              onToggleMapType: () {
                                setState(() {
                                  _mapType = _mapType == MapType.normal
                                      ? MapType.hybrid
                                      : MapType.normal;
                                });
                              },
                              onLocate: _goToCurrentLocation,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (!_fieldEditMode || _mapSize == Size.zero) return;
    if (event is! PointerScrollEvent) return;

    final dy = event.scrollDelta.dy;
    if (dy == 0) return;

    final pressedKeys = HardwareKeyboard.instance.logicalKeysPressed;

    final isShiftPressed =
        pressedKeys.contains(LogicalKeyboardKey.shiftLeft) ||
            pressedKeys.contains(LogicalKeyboardKey.shiftRight);

    final isAltPressed = pressedKeys.contains(LogicalKeyboardKey.altLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.altRight) ||
        pressedKeys.contains(LogicalKeyboardKey.metaLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.metaRight);

    final factor = dy > 0 ? 0.96 : 1.04;

    if (isShiftPressed && isAltPressed) {
      _resizeFieldLength(factor);
    } else if (isAltPressed) {
      _resizeFieldWidth(factor);
    } else if (isShiftPressed) {
      _rotateByDegrees(dy > 0 ? 1.4 : -1.4);
    } else {
      _resizeField(factor);
    }
  }

  Widget _buildFieldGestureLayer() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onScaleStart: (details) {
          _gestureStartCenter = _fieldCenter;
          _gestureStartWidth = _fieldWidth;
          _gestureStartLength = _fieldLength;
          _gestureStartRotation = _rotationRadians;
          _gestureStartFocal = details.localFocalPoint;
        },
        onScaleUpdate: (details) {
          final delta = details.localFocalPoint - _gestureStartFocal;
          final nextCenter = _clampFieldCenter(_gestureStartCenter + delta);

          final maxWidth = _maxFieldWidth();
          final maxLength = _maxFieldLength();

          final nextWidth = (_gestureStartWidth * details.scale)
              .clamp(60.0, maxWidth)
              .toDouble();

          final nextLength = (_gestureStartLength * details.scale)
              .clamp(90.0, maxLength)
              .toDouble();

          setState(() {
            _fieldCenter = nextCenter;
            _fieldWidth = nextWidth;
            _fieldLength = nextLength;
            _rotationRadians = _gestureStartRotation + details.rotation;
            _metersDrivePixelSize = true;
          });
          unawaited(_syncMetersFromPixels());
        },
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildFieldOverlay() {
    final colors = context.appColors;
    final rect = Rect.fromCenter(
      center: _fieldCenter,
      width: _fieldWidth,
      height: _fieldHeight,
    );

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: _rotationRadians,
          child: CustomPaint(
            painter: _FootballPitchPainter(
              lineColor: Colors.white,
              fillColor: colors.success.withValues(alpha: 0.18),
              label: '${_fieldLengthMeters.round()} x '
                  '${_fieldWidthMeters.round()} m',
              labelColor: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Offset _clampFieldCenter(Offset center) {
    if (_mapSize == Size.zero) return center;

    return Offset(
      center.dx.clamp(0.0, _mapSize.width).toDouble(),
      center.dy.clamp(0.0, _mapSize.height).toDouble(),
    );
  }

  double _maxFieldWidth() {
    if (_mapSize == Size.zero) return 300.0;
    return math.max(90.0, _mapSize.width * 0.95);
  }

  double _maxFieldLength() {
    if (_mapSize == Size.zero) return 440.0;
    return math.max(120.0, _mapSize.height * 0.95);
  }

  void _rotateByDegrees(double degrees) {
    setState(() {
      _rotationRadians += degrees * math.pi / 180.0;
    });
  }

  void _resizeField(double factor) {
    if (_mapSize == Size.zero) return;
    _metersDrivePixelSize = true;
    _fieldWidthMeters = (_fieldWidthMeters * factor).clamp(15.0, 160.0);
    _fieldLengthMeters = (_fieldLengthMeters * factor).clamp(15.0, 160.0);
    unawaited(_applyPixelSizeFromMeters().then((_) {
      if (!mounted) return;
      setState(() => _fieldCenter = _clampFieldCenter(_fieldCenter));
    }));
  }

  void _resizeFieldWidth(double factor) {
    if (_mapSize == Size.zero) return;
    _metersDrivePixelSize = true;
    _fieldWidthMeters = (_fieldWidthMeters * factor).clamp(15.0, 160.0);
    unawaited(_applyPixelSizeFromMeters().then((_) {
      if (!mounted) return;
      setState(() => _fieldCenter = _clampFieldCenter(_fieldCenter));
    }));
  }

  void _resizeFieldLength(double factor) {
    if (_mapSize == Size.zero) return;
    _metersDrivePixelSize = true;
    _fieldLengthMeters = (_fieldLengthMeters * factor).clamp(15.0, 160.0);
    unawaited(_applyPixelSizeFromMeters().then((_) {
      if (!mounted) return;
      setState(() => _fieldCenter = _clampFieldCenter(_fieldCenter));
    }));
  }

  void _moveFieldBy(double dx, double dy) {
    if (_mapSize == Size.zero) return;

    setState(() {
      _fieldCenter = _clampFieldCenter(_fieldCenter + Offset(dx, dy));
    });
  }

  void _resetOverlay() {
    if (_mapSize == Size.zero) return;

    _metersDrivePixelSize = true;
    _fieldWidthMeters = widget.referenceFieldWidthMeters;
    _fieldLengthMeters = widget.referenceFieldLengthMeters;
    _rotationRadians = 0.0;
    unawaited(_applyPixelSizeFromMeters().then((_) {
      if (!mounted) return;
      setState(() {
        _fieldCenter = Offset(
          _mapSize.width / 2.0,
          _mapSize.height / 2.0,
        );
      });
    }));
  }

  List<Offset> _fieldCornerOffsets() {
    final halfWidth = _fieldWidth / 2.0;
    final halfHeight = _fieldHeight / 2.0;

    final corners = [
      Offset(_fieldCenter.dx - halfWidth, _fieldCenter.dy - halfHeight),
      Offset(_fieldCenter.dx + halfWidth, _fieldCenter.dy - halfHeight),
      Offset(_fieldCenter.dx + halfWidth, _fieldCenter.dy + halfHeight),
      Offset(_fieldCenter.dx - halfWidth, _fieldCenter.dy + halfHeight),
    ];

    return corners
        .map(
          (corner) => _rotateOffset(
        corner,
        _fieldCenter,
        _rotationRadians,
      ),
    )
        .toList();
  }

  Offset _rotateOffset(Offset point, Offset center, double angle) {
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);

    return Offset(
      center.dx + dx * cosA - dy * sinA,
      center.dy + dx * sinA + dy * cosA,
    );
  }

  bool _cornersAreInsideMap(List<Offset> points) {
    return points.every(
          (p) =>
      p.dx >= 0 &&
          p.dy >= 0 &&
          p.dx <= _mapSize.width &&
          p.dy <= _mapSize.height,
    );
  }

  /// Soft rectangle check (opposite sides / diagonals within 25%).
  bool _cornersLookRectangular(FieldGpsCorners corners) {
    if (!corners.isComplete) return false;

    final tl = corners.topLeft!;
    final tr = corners.topRight!;
    final bl = corners.bottomLeft!;
    final br = corners.bottomRight!;

    final top = FieldCornerGps.distanceMeters(tl, tr);
    final bottom = FieldCornerGps.distanceMeters(bl, br);
    final left = FieldCornerGps.distanceMeters(tl, bl);
    final right = FieldCornerGps.distanceMeters(tr, br);
    final diagonal1 = FieldCornerGps.distanceMeters(tl, br);
    final diagonal2 = FieldCornerGps.distanceMeters(tr, bl);

    bool closeEnough(double a, double b) {
      final maxValue = math.max(a, b);
      if (maxValue <= 0) return false;
      return (a - b).abs() / maxValue <= 0.25;
    }

    final minSide = [top, bottom, left, right].reduce(math.min);
    final maxSide = [top, bottom, left, right].reduce(math.max);

    return minSide >= 15 &&
        maxSide <= 160 &&
        closeEnough(top, bottom) &&
        closeEnough(left, right) &&
        closeEnough(diagonal1, diagonal2);
  }

  Future<FieldGpsCorners?> _computeFieldGpsCorners() async {
    final controller = _mapController;
    if (controller == null) {
      _showSnackBar(context.l10n.fieldSnackbarMapNotReady);
      return null;
    }

    final points = _fieldCornerOffsets();
    if (!_cornersAreInsideMap(points)) {
      _showSnackBar(context.l10n.fieldSnackbarPlaceInMap);
      return null;
    }

    Future<FieldCornerGps> cornerFromOffset(Offset point) async {
      final latLng = await controller.getLatLng(_toScreenCoordinate(point));

      return FieldCornerGps(
        latitude: latLng.latitude,
        longitude: latLng.longitude,
      );
    }

    try {
      final topLeft = await cornerFromOffset(points[0]);
      final topRight = await cornerFromOffset(points[1]);
      final bottomRight = await cornerFromOffset(points[2]);
      final bottomLeft = await cornerFromOffset(points[3]);

      final corners = FieldGpsCorners(
        topLeft: topLeft,
        topRight: topRight,
        bottomLeft: bottomLeft,
        bottomRight: bottomRight,
      );

      // Reject clearly broken projections before persisting.
      if (!_cornersLookRectangular(corners)) {
        _showSnackBar(context.l10n.fieldSnackbarGpsConvertFailed);
        return null;
      }

      return corners;
    } catch (_) {
      _showSnackBar(context.l10n.fieldSnackbarGpsConvertFailed);
      return null;
    }
  }

  Future<FieldLocalizationResult?> _buildResult() async {
    setState(() => _isComputingCorners = true);

    final corners = await _computeFieldGpsCorners();

    if (!mounted) return null;

    setState(() => _isComputingCorners = false);

    if (corners == null) return null;

    final geometry = corners.computeGeometry();

    return FieldLocalizationResult(
      fieldName: _nameController.text.trim(),
      fieldAddress: _addressController.text.trim(),
      playersPerTeam: _playersPerTeam,
      fieldGpsCorners: corners,
      geometry: geometry,
    );
  }

  Future<void> _validateAndReturn() async {
    final result = await _buildResult();
    if (!mounted || result == null) return;

    Navigator.of(context).pop(result);
  }

  Future<void> _showGpsPreview() async {
    final result = await _buildResult();
    if (!mounted || result == null) return;

    final postalAddress = await _reverseGeocodeAddressFromCorners(
      result.fieldGpsCorners,
    );

    if (!mounted) return;

    final colors = context.appColors;
    final dartMap = _formatCornersAsDartMap(result.fieldGpsCorners);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        final l10n = context.l10n;
        final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + bottomPadding),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.fieldGpsPositionsTitle,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    dartMap,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _AddressPreviewCard(
                    address: postalAddress,
                  ),
                  if (result.geometry != null) ...[
                    const SizedBox(height: 16),
                    _GeometrySummary(geometry: result.geometry!),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: dartMap));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.successGpsCopied)),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy),
                          label: Text(l10n.actionCopy),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop(result);
                          },
                          icon: const Icon(Icons.check),
                          label: Text(l10n.actionValidate),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatCornersAsDartMap(FieldGpsCorners corners) {
    String point(FieldCornerGps? p) {
      if (p == null) return 'null';
      return "{'latitude': ${p.latitude.toStringAsFixed(8)}, "
          "'longitude': ${p.longitude.toStringAsFixed(8)}}";
    }

    return "fieldGpsCorners: {\n"
        "  'topLeft': ${point(corners.topLeft)},\n"
        "  'topRight': ${point(corners.topRight)},\n"
        "  'bottomLeft': ${point(corners.bottomLeft)},\n"
        "  'bottomRight': ${point(corners.bottomRight)},\n"
        "}";
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
