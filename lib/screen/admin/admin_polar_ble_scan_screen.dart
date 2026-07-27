import 'dart:async';

import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/services/polar_mobile_ble.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';

/// Result of a successful Polar mobile BLE pick (before kit assignment).
class AdminPolarBlePickResult {
  const AdminPolarBlePickResult({
    required this.deviceId,
    required this.deviceType,
    required this.displayName,
  });

  final String deviceId;
  final String deviceType;
  final String displayName;
}

/// Lists nearby Polar sensors via BLE and lets the admin connect one by one.
Future<AdminPolarBlePickResult?> showAdminPolarBleScanScreen(
  BuildContext context,
) {
  return Navigator.of(context).push<AdminPolarBlePickResult>(
    MaterialPageRoute(
      builder: (_) => const AdminPolarBleScanScreen(),
    ),
  );
}

class AdminPolarBleScanScreen extends StatefulWidget {
  const AdminPolarBleScanScreen({super.key});

  @override
  State<AdminPolarBleScanScreen> createState() =>
      _AdminPolarBleScanScreenState();
}

class _AdminPolarBleScanScreenState extends State<AdminPolarBleScanScreen> {
  final PolarMobileBleService _ble = PolarMobileBleService.instance;
  final Map<String, PolarBleFoundDevice> _devices = {};
  final Set<String> _connectedIds = {};
  final Set<String> _connectingIds = {};

  StreamSubscription<PolarBleFoundDevice>? _searchSub;
  StreamSubscription<String>? _connectedSub;
  StreamSubscription<String>? _disconnectedSub;

  bool _scanning = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _connectedSub = _ble.deviceConnectedIds.listen((id) {
      if (!mounted) return;
      setState(() {
        _connectedIds.add(id);
        _connectingIds.remove(id);
      });
    });
    _disconnectedSub = _ble.deviceDisconnectedIds.listen((id) {
      if (!mounted) return;
      setState(() {
        _connectedIds.remove(id);
        _connectingIds.remove(id);
      });
    });
    _startScan();
  }

  @override
  void dispose() {
    _searchSub?.cancel();
    _connectedSub?.cancel();
    _disconnectedSub?.cancel();
    unawaited(_ble.stopSearch());
    super.dispose();
  }

  Future<void> _startScan() async {
    await _searchSub?.cancel();
    await _ble.stopSearch();
    if (!mounted) return;

    setState(() {
      _scanning = true;
      _error = null;
      _devices.clear();
    });

    if (!_ble.isSupported) {
      setState(() {
        _scanning = false;
        _error = context.l10n.adminPolarBleScanUnsupported;
      });
      return;
    }

    _searchSub = _ble.searchForDevices().listen(
      (device) {
        if (!mounted) return;
        setState(() => _devices[device.deviceId] = device);
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _scanning = false;
          _error = e.toString();
        });
      },
    );
  }

  Future<void> _stopScan() async {
    await _searchSub?.cancel();
    _searchSub = null;
    await _ble.stopSearch();
    if (mounted) setState(() => _scanning = false);
  }

  Future<void> _onConnect(PolarBleFoundDevice device) async {
    final id = device.deviceId;
    if (_connectingIds.contains(id)) return;

    setState(() => _connectingIds.add(id));
    try {
      await _ble.connect(id);
      if (!mounted) return;
      // Wait briefly for connected callback; still allow proceed if connect
      // returns without error (some firmware paths are quiet).
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _connectedIds.add(id);
        _connectingIds.remove(id);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _connectingIds.remove(id));
      AppSnackbar.show(
        context,
        context.l10n.adminPolarBleScanConnectError(e.toString()),
      );
    }
  }

  Future<void> _onUseDevice(PolarBleFoundDevice device) async {
    // Prefer a short connect so the sensor is validated, then hand off.
    if (!_connectedIds.contains(device.deviceId)) {
      await _onConnect(device);
      if (!mounted) return;
      if (!_connectedIds.contains(device.deviceId) &&
          !_connectingIds.contains(device.deviceId)) {
        // Connect failed — still allow adding from scan identity if user wants?
        // Require successful connect for mobile inventory.
        return;
      }
    }

    await _ble.stopSearch();
    if (!mounted) return;

    // Disconnect after identity capture — inventory doesn't need a live session.
    unawaited(_ble.disconnect(device.deviceId));

    Navigator.of(context).pop(
      AdminPolarBlePickResult(
        deviceId: device.deviceId,
        deviceType: device.deviceType,
        displayName: device.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final devices = _devices.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.adminPolarBleScanTitle,
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _scanning
                ? l10n.adminPolarBleScanStop
                : l10n.adminPolarBleScanRestart,
            onPressed: _scanning ? _stopScan : _startScan,
            icon: Icon(_scanning ? Icons.stop : Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                l10n.adminPolarBleScanHint,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
            if (_scanning)
              const LinearProgressIndicator(minHeight: 2)
            else
              const SizedBox(height: 2),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _error!,
                  style: textTheme.bodyMedium?.copyWith(color: colors.danger),
                ),
              ),
            Expanded(
              child: devices.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _scanning
                              ? l10n.adminPolarBleScanSearching
                              : l10n.adminPolarBleScanEmpty,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: devices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        final connected =
                            _connectedIds.contains(device.deviceId);
                        final connecting =
                            _connectingIds.contains(device.deviceId);

                        return Material(
                          color: colors.card,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: colors.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.bluetooth,
                                      color: connected
                                          ? colors.primary
                                          : colors.textSecondary,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            device.name,
                                            style: textTheme.titleMedium
                                                ?.copyWith(
                                              color: colors.textPrimary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${device.deviceId} · ${device.deviceType} · ${device.rssi} dBm',
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                              color: colors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    if (!connected)
                                      TextButton.icon(
                                        onPressed: connecting
                                            ? null
                                            : () => _onConnect(device),
                                        icon: connecting
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Icon(Icons.link, size: 18),
                                        label: Text(
                                          connecting
                                              ? l10n.adminPolarBleScanConnecting
                                              : l10n.adminPolarBleScanConnect,
                                        ),
                                      )
                                    else
                                      TextButton.icon(
                                        onPressed: () => _onUseDevice(device),
                                        icon: const Icon(
                                          Icons.check_circle,
                                          size: 18,
                                        ),
                                        label: Text(
                                          l10n.adminPolarBleScanAddToKit,
                                        ),
                                      ),
                                    if (connected) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.adminPolarBleScanConnected,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
