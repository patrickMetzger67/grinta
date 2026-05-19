import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../model/fieldGpsCorners.dart';
import '../util/app_theme.dart';


const String kGoogleMapsApiKey = String.fromEnvironment(
  'GOOGLE_MAPS_API_KEY',
  defaultValue: 'AIzaSyDyHHcP9py2HCyx18Ssels7qqygKxeUZG0',
);

class FieldLocalizationResult {
  final String fieldName;
  final int playersPerTeam;
  final FieldGpsCorners fieldGpsCorners;
  final FieldGeometry? geometry;

  const FieldLocalizationResult({
    required this.fieldName,
    required this.playersPerTeam,
    required this.fieldGpsCorners,
    required this.geometry,
  });

  Map<String, dynamic> toMap() {
    return {
      'fieldName': fieldName,
      'playersPerTeam': playersPerTeam,
      'fieldGpsCorners': fieldGpsCorners.toMap(),
      'geometry': geometry?.toMap(),
    };
  }
}

class FootballFieldLocalizationScreen extends StatefulWidget {
  final String initialName;
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

  bool _isPreparingInitialLocation = true;
  bool _locationPermissionGranted = false;
  bool _overlayInitialized = false;
  bool _isComputingCorners = false;
  bool _isSearchingAddress = false;
  bool _fieldEditMode = true;

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

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName;
    unawaited(_prepareInitialLocation());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _prepareInitialLocation() async {
    LatLng target = widget.initialTarget;
    bool granted = false;

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();

      if (enabled) {
        LocationPermission permission = await Geolocator.checkPermission();

        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        granted = permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse;

        if (granted) {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          target = LatLng(position.latitude, position.longitude);
        }
      }
    } catch (_) {
      target = widget.initialTarget;
    }

    if (!mounted) return;

    setState(() {
      _initialMapTarget = target;
      _currentMapTarget = target;
      _currentMapZoom = widget.initialZoom;
      _locationPermissionGranted = granted;
      _isPreparingInitialLocation = false;
    });
  }

  Future<void> _goToCurrentLocation() async {
    final controller = _mapController;
    if (controller == null) return;

    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      _showSnackBar('La localisation est désactivée.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    final granted = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    if (!mounted) return;

    setState(() => _locationPermissionGranted = granted);

    if (!granted) {
      _showSnackBar('Autorise la localisation pour centrer la carte.');
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
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
      _showSnackBar('Impossible de récupérer la position actuelle.');
    }
  }

  Future<void> _searchAddress() async {
    final query = _addressController.text.trim();
    final controller = _mapController;

    if (query.isEmpty) {
      _showSnackBar('Saisis une adresse ou un nom de stade.');
      return;
    }

    if (controller == null) {
      _showSnackBar('La carte n’est pas encore prête.');
      return;
    }

    final apiKey = widget.googleMapsApiKey.trim();

    if (apiKey.isEmpty || apiKey == 'TA_CLE_GOOGLE_MAPS_ICI') {
      _showSnackBar(
        'Clé Google Maps manquante pour la recherche d’adresse.',
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
        _showSnackBar('Adresse introuvable : $status');
        return;
      }

      final results = data['results'] as List<dynamic>;
      if (results.isEmpty) {
        _showSnackBar('Adresse introuvable.');
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
        'Impossible de rechercher cette adresse. Vérifie la clé et l’API Geocoding.',
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
                decoration: const InputDecoration(
                  hintText: 'Nom du terrain',
                ),
              ),
            ),
            _AddressSearchField(
              controller: _addressController,
              isSearching: _isSearchingAddress,
              onSearch: _searchAddress,
            ),
            Expanded(
              child: _isPreparingInitialLocation || _initialMapTarget == null
                  ? Center(
                child: CircularProgressIndicator(
                  color: colors.primary,
                ),
              )
                  : Container(
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                ),
                padding: const EdgeInsets.all(2),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    _mapSize = size;
                    _initializeOverlayIfNeeded(size);

                    return Listener(
                      onPointerSignal: _handlePointerSignal,
                      child: Stack(
                        children: [
                          GoogleMap(
                            mapType: _mapType,
                            initialCameraPosition: CameraPosition(
                              target: _initialMapTarget!,
                              zoom: widget.initialZoom,
                            ),
                            myLocationEnabled: _locationPermissionGranted,
                            myLocationButtonEnabled: false,
                            compassEnabled: false,
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                            tiltGesturesEnabled: false,
                            rotateGesturesEnabled: false,
                            scrollGesturesEnabled: !_fieldEditMode,
                            zoomGesturesEnabled: !_fieldEditMode,
                            onMapCreated: (controller) {
                              _mapController = controller;
                            },
                            onCameraMove: (position) {
                              _currentMapTarget = position.target;
                              _currentMapZoom = position.zoom;
                            },
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
      _showSnackBar('La carte n’est pas encore prête.');
      return null;
    }

    final points = _fieldCornerOffsets();
    if (!_cornersAreInsideMap(points)) {
      _showSnackBar('Place le terrain entièrement dans la carte.');
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
      _showSnackBar('Impossible de convertir les coins en positions GPS.');
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
                          'Positions GPS du terrain',
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
                                const SnackBar(content: Text('GPS copié.')),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copier'),
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
                          label: const Text('Valider'),
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

class _HeaderBar extends StatelessWidget {
  final bool isBusy;
  final VoidCallback onBack;
  final VoidCallback onValidate;

  const _HeaderBar({
    required this.isBusy,
    required this.onBack,
    required this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 12, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          const Spacer(),
          FilledButton(
            onPressed: isBusy ? null : onValidate,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: colors.border,
              disabledForegroundColor: colors.textSecondary,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: isBusy
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text(
              'Enregistrer',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressSearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool isSearching;
  final VoidCallback onSearch;

  const _AddressSearchField({
    required this.controller,
    required this.isSearching,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) {
                if (!isSearching) onSearch();
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Rechercher une adresse ou un stade',
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: isSearching ? null : onSearch,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isSearching
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopMapControls extends StatelessWidget {
  final int playersPerTeam;
  final VoidCallback onPreviewGps;

  const _TopMapControls({
    required this.playersPerTeam,
    required this.onPreviewGps,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _DarkMapButton(
                icon: Icons.my_location_rounded,
                label: 'Localiser les coins',
                onTap: onPreviewGps,
                foregroundColor: colors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldQuickControls extends StatelessWidget {
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onLengthIn;
  final VoidCallback onLengthOut;
  final VoidCallback onWidthIn;
  final VoidCallback onWidthOut;
  final VoidCallback onReset;

  const _FieldQuickControls({
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onLengthIn,
    required this.onLengthOut,
    required this.onWidthIn,
    required this.onWidthOut,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SmallTextButton(
                label: '+',
                tooltip: 'Agrandir tout le terrain',
                onPressed: onZoomIn,
              ),
              _SmallTextButton(
                label: '-',
                tooltip: 'Réduire tout le terrain',
                onPressed: onZoomOut,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SmallTextButton(
                label: 'L+',
                tooltip: 'Augmenter la longueur',
                onPressed: onLengthIn,
              ),
              _SmallTextButton(
                label: 'L-',
                tooltip: 'Réduire la longueur',
                onPressed: onLengthOut,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SmallTextButton(
                label: 'l+',
                tooltip: 'Augmenter la largeur',
                onPressed: onWidthIn,
              ),
              _SmallTextButton(
                label: 'l-',
                tooltip: 'Réduire la largeur',
                onPressed: onWidthOut,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SmallIconButton(
                icon: Icons.rotate_left,
                tooltip: 'Tourner à gauche',
                onPressed: onRotateLeft,
              ),
              _SmallIconButton(
                icon: Icons.rotate_right,
                tooltip: 'Tourner à droite',
                onPressed: onRotateRight,
              ),
            ],
          ),
          const SizedBox(height: 4),
          _SmallIconButton(
            icon: Icons.refresh,
            tooltip: 'Réinitialiser',
            onPressed: onReset,
          ),
        ],
      ),
    );
  }
}

class _FieldGestureHint extends StatelessWidget {
  final bool fieldEditMode;
  final VoidCallback onToggleMode;

  const _FieldGestureHint({
    required this.fieldEditMode,
    required this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              fieldEditMode
                  ? 'Terrain : glisser déplacer • 2 doigts zoom/tourner • trackpad : scroll zoom, ⇧ tourner, ⌥ largeur, ⇧⌥ longueur'
                  : 'Mode carte : déplace ou zoome la carte',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onToggleMode,
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: fieldEditMode ? colors.primary : colors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  fieldEditMode ? Icons.touch_app_rounded : Icons.map_rounded,
                  color: fieldEditMode ? Colors.white : colors.primary,
                  size: 17,
                ),
                const SizedBox(width: 6),
                Text(
                  fieldEditMode ? 'Terrain' : 'Carte',
                  style: TextStyle(
                    color: fieldEditMode ? Colors.white : colors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomMapControls extends StatelessWidget {
  final MapType mapType;
  final VoidCallback onToggleMapType;
  final VoidCallback onLocate;

  const _BottomMapControls({
    required this.mapType,
    required this.onToggleMapType,
    required this.onLocate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SmallIconButton(
                icon: Icons.map_outlined,
                tooltip: 'Carte',
                isSelected: mapType == MapType.normal,
                onPressed: onToggleMapType,
              ),
              _SmallIconButton(
                icon: Icons.satellite_alt_rounded,
                tooltip: 'Satellite',
                isSelected: mapType != MapType.normal,
                onPressed: onToggleMapType,
              ),
            ],
          ),
        ),
        const Spacer(),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onLocate,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.navigation_rounded,
              color: colors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DarkMapButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? foregroundColor;

  const _DarkMapButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = foregroundColor ?? Colors.white;

    return Material(
      color: Colors.black.withValues(alpha: 0.68),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: effectiveColor),
              const SizedBox(width: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: effectiveColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isSelected;
  final String? tooltip;

  const _SmallIconButton({
    required this.icon,
    required this.onPressed,
    this.isSelected = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final child = InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onPressed,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.24)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isSelected ? colors.primary : Colors.white,
          size: 18,
        ),
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) return child;
    return Tooltip(message: tooltip!, child: child);
  }
}

class _SmallTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final String? tooltip;

  const _SmallTextButton({
    required this.label,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final child = InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onPressed,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: colors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) return child;
    return Tooltip(message: tooltip!, child: child);
  }
}

class _GeometrySummary extends StatelessWidget {
  final FieldGeometry geometry;

  const _GeometrySummary({required this.geometry});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    Widget item(String label, String value) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.5,
      children: [
        item(
          'Longueur moyenne',
          '${geometry.averageLengthMeters.toStringAsFixed(1)} m',
        ),
        item(
          'Largeur moyenne',
          '${geometry.averageWidthMeters.toStringAsFixed(1)} m',
        ),
        item(
          'Côté gauche',
          '${geometry.leftLengthMeters.toStringAsFixed(1)} m',
        ),
        item(
          'Côté droit',
          '${geometry.rightLengthMeters.toStringAsFixed(1)} m',
        ),
      ],
    );
  }
}

class _FootballPitchPainter extends CustomPainter {
  final Color lineColor;
  final Color fillColor;
  final String label;
  final Color labelColor;

  const _FootballPitchPainter({
    required this.lineColor,
    required this.fillColor,
    required this.label,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round;

    final boldLinePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;

    final rect = Offset.zero & size;
    final fieldRect = rect.deflate(1.2);

    canvas.drawRect(fieldRect, fillPaint);
    canvas.drawRect(fieldRect, boldLinePaint);

    final w = size.width;
    final h = size.height;

    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), linePaint);
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.145, linePaint);
    canvas.drawCircle(Offset(w / 2, h / 2), 1.8, Paint()..color = lineColor);

    final penaltyWidth = w * 0.62;
    final penaltyDepth = h * 0.155;
    final goalAreaWidth = w * 0.34;
    final goalAreaDepth = h * 0.06;

    final topPenalty = Rect.fromLTWH(
      (w - penaltyWidth) / 2,
      0,
      penaltyWidth,
      penaltyDepth,
    );
    final bottomPenalty = Rect.fromLTWH(
      (w - penaltyWidth) / 2,
      h - penaltyDepth,
      penaltyWidth,
      penaltyDepth,
    );

    final topGoalArea = Rect.fromLTWH(
      (w - goalAreaWidth) / 2,
      0,
      goalAreaWidth,
      goalAreaDepth,
    );
    final bottomGoalArea = Rect.fromLTWH(
      (w - goalAreaWidth) / 2,
      h - goalAreaDepth,
      goalAreaWidth,
      goalAreaDepth,
    );

    canvas.drawRect(topPenalty, linePaint);
    canvas.drawRect(bottomPenalty, linePaint);
    canvas.drawRect(topGoalArea, linePaint);
    canvas.drawRect(bottomGoalArea, linePaint);

    canvas.drawCircle(
      Offset(w / 2, penaltyDepth * 0.68),
      1.4,
      Paint()..color = lineColor,
    );
    canvas.drawCircle(
      Offset(w / 2, h - penaltyDepth * 0.68),
      1.4,
      Paint()..color = lineColor,
    );

    final arcRadius = w * 0.14;
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(w / 2, penaltyDepth * 0.68),
        radius: arcRadius,
      ),
      math.pi * 0.18,
      math.pi * 0.64,
      false,
      linePaint,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(w / 2, h - penaltyDepth * 0.68),
        radius: arcRadius,
      ),
      -math.pi * 0.82,
      math.pi * 0.64,
      false,
      linePaint,
    );

    final goalWidth = w * 0.2;
    canvas.drawLine(
      Offset((w - goalWidth) / 2, 0),
      Offset((w + goalWidth) / 2, 0),
      boldLinePaint,
    );
    canvas.drawLine(
      Offset((w - goalWidth) / 2, h),
      Offset((w + goalWidth) / 2, h),
      boldLinePaint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: labelColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          shadows: const [
            Shadow(
              blurRadius: 3,
              color: Colors.black54,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        (w - textPainter.width) / 2,
        h / 2 + 8,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _FootballPitchPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.label != label ||
        oldDelegate.labelColor != labelColor;
  }
}
class _AddressPreviewCard extends StatelessWidget {
  final String? address;

  const _AddressPreviewCard({
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final hasAddress = address != null && address!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.location_on_outlined,
            color: colors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adresse estimée',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  hasAddress
                      ? address!
                      : 'Adresse postale indisponible pour cette position.',
                  style: TextStyle(
                    color: hasAddress
                        ? colors.textPrimary
                        : colors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}