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

  /// 1.0 = taille théorique réelle par rapport au zoom Google Maps.
  /// 0.70 = affichage plus petit et plus confortable à l'ouverture.
  static const double _initialFieldVisualScale = 0.60;

  bool _overlayInitialized = false;
  bool _isComputingCorners = false;
  bool _isSearchingAddress = false;
  /// Sur mobile, la carte doit recevoir les gestes par défaut (mode carte).
  /// Sur web, on garde l’édition du terrain en priorité.
  bool _fieldEditMode = kIsWeb;

  Size _mapSize = Size.zero;
  Offset _fieldCenter = Offset.zero;

  /// Largeur visuelle du terrain à l'écran.
  double _fieldWidth = 190.0;

  /// Longueur visuelle du terrain à l'écran.
  /// Elle est volontairement indépendante de [_fieldWidth] pour pouvoir
  /// ajuster séparément la longueur et la largeur.
  double _fieldLength = 293.0;

  double _rotationRadians = -18.0 * math.pi / 180.0;

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
    // Affiche la carte tout de suite (évite blocage géoloc sur simulateur).
    _initialMapTarget = widget.initialTarget;
    _currentMapTarget = widget.initialTarget;
    _currentMapZoom = widget.initialZoom;
    if (!_hasInitialAddress) {
      unawaited(_tryRefineLocationFromGps());
    }
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

    if (_hasInitialAddress) {
      unawaited(_searchAddress());
    }
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

      _centerOverlayInMap(resizeFromCurrentZoom: true);
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

      _centerOverlayInMap(resizeFromCurrentZoom: true);
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

  double _metersPerPixel({
    required double latitude,
    required double zoom,
  }) {
    return 156543.03392 *
        math.cos(latitude * math.pi / 180.0) /
        math.pow(2.0, zoom);
  }

  Size _fieldPixelSizeForCamera(
      Size mapSize, {
        LatLng? target,
        double? zoom,
        double visualScale = _initialFieldVisualScale,
      }) {
    final cameraTarget =
        target ?? _currentMapTarget ?? _initialMapTarget ?? widget.initialTarget;

    final cameraZoom = zoom ?? _currentMapZoom;

    final metersPerPixel = _metersPerPixel(
      latitude: cameraTarget.latitude,
      zoom: cameraZoom,
    );

    final widthPixels =
        widget.referenceFieldWidthMeters / metersPerPixel * visualScale;

    final lengthPixels =
        widget.referenceFieldLengthMeters / metersPerPixel * visualScale;

    final maxWidth = math.max(70.0, mapSize.width * 0.45);
    final maxLength = math.max(100.0, mapSize.height * 0.60);

    return Size(
      widthPixels.clamp(60.0, maxWidth).toDouble(),
      lengthPixels.clamp(90.0, maxLength).toDouble(),
    );
  }

  void _initializeOverlayIfNeeded(Size size) {
    if (_overlayInitialized || size.width <= 0 || size.height <= 0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _overlayInitialized) return;

      final fieldSize = _fieldPixelSizeForCamera(
        size,
        target: _initialMapTarget ?? widget.initialTarget,
        zoom: widget.initialZoom,
        visualScale: _initialFieldVisualScale,
      );

      setState(() {
        _mapSize = size;
        _fieldWidth = fieldSize.width;
        _fieldLength = fieldSize.height;
        _fieldCenter = Offset(size.width / 2.0, size.height / 2.0 + 20.0);
        _overlayInitialized = true;
      });
    });
  }


  void _centerOverlayInMap({bool resizeFromCurrentZoom = false}) {
    if (!mounted || _mapSize == Size.zero) return;

    setState(() {
      if (resizeFromCurrentZoom) {
        final fieldSize = _fieldPixelSizeForCamera(
          _mapSize,
          visualScale: _initialFieldVisualScale,
        );

        _fieldWidth = fieldSize.width;
        _fieldLength = fieldSize.height;
      }

      _fieldCenter = Offset(_mapSize.width / 2.0, _mapSize.height / 2.0 + 20.0);
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
          });
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
              label: '${widget.referenceFieldLengthMeters.round()} x '
                  '${widget.referenceFieldWidthMeters.round()} m',
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

    setState(() {
      _fieldWidth = (_fieldWidth * factor).clamp(60.0, _maxFieldWidth()).toDouble();
      _fieldLength = (_fieldLength * factor).clamp(90.0, _maxFieldLength()).toDouble();
      _fieldCenter = _clampFieldCenter(_fieldCenter);
    });
  }

  void _resizeFieldWidth(double factor) {
    if (_mapSize == Size.zero) return;

    setState(() {
      _fieldWidth = (_fieldWidth * factor).clamp(60.0, _maxFieldWidth()).toDouble();
      _fieldCenter = _clampFieldCenter(_fieldCenter);
    });
  }

  void _resizeFieldLength(double factor) {
    if (_mapSize == Size.zero) return;

    setState(() {
      _fieldLength = (_fieldLength * factor).clamp(90.0, _maxFieldLength()).toDouble();
      _fieldCenter = _clampFieldCenter(_fieldCenter);
    });
  }

  void _moveFieldBy(double dx, double dy) {
    if (_mapSize == Size.zero) return;

    setState(() {
      _fieldCenter = _clampFieldCenter(_fieldCenter + Offset(dx, dy));
    });
  }

  void _resetOverlay() {
    if (_mapSize == Size.zero) return;

    final fieldSize = _fieldPixelSizeForCamera(
      _mapSize,
      visualScale: _initialFieldVisualScale,
    );

    setState(() {
      _fieldWidth = fieldSize.width;
      _fieldLength = fieldSize.height;
      _fieldCenter = Offset(_mapSize.width / 2.0, _mapSize.height / 2.0 + 20.0);
      _rotationRadians = -18.0 * math.pi / 180.0;
    });
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
      final latLng = await controller.getLatLng(
        ScreenCoordinate(
          x: point.dx.round(),
          y: point.dy.round(),
        ),
      );

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

      return FieldGpsCorners(
        topLeft: topLeft,
        topRight: topRight,
        bottomLeft: bottomLeft,
        bottomRight: bottomRight,
      );
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
