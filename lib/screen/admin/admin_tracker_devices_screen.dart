import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/tracker/deviceOwner.dart';
import 'package:grinta/model/tracker_owner.dart';
import 'package:grinta/services/polar_web_bluetooth.dart';
import 'package:grinta/services/tracker_device_admin_service.dart';
import 'package:grinta/services/tracker_device_sync_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:intl/intl.dart';

class AdminTrackerDevicesScreen extends StatefulWidget {
  const AdminTrackerDevicesScreen({super.key, this.ownerId});

  /// When set, pre-selects this owner in the filter dropdown.
  final String? ownerId;

  @override
  State<AdminTrackerDevicesScreen> createState() =>
      _AdminTrackerDevicesScreenState();
}

class _AdminTrackerDevicesScreenState extends State<AdminTrackerDevicesScreen> {
  final TrackerDeviceSyncService _sync = TrackerDeviceSyncService();

  bool _isSyncingInspirit = false;
  bool _showUnassignedDevices = false;
  bool _isDataLoaded = false;

  final Map<String, TrackerOwner> _ownerMap = <String, TrackerOwner>{};
  final Map<String, DeviceOwner> _deviceOwnerMap = <String, DeviceOwner>{};
  final Map<String, DeviceOwner> _deviceOwnerByDeviceId =
      <String, DeviceOwner>{};

  String? _selectedOwnerId;

  bool get _hasParamOwner =>
      widget.ownerId != null && widget.ownerId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadDeviceOwnersForOwner(String ownerId) async {
    _deviceOwnerMap.clear();
    final devices = await DeviceOwnerService().listByOwnerId(ownerId);
    for (final d in devices) {
      _deviceOwnerMap[d.deviceId] = d;
    }
  }

  Future<void> _applyOwnerSelection(String? ownerId) async {
    setState(() {
      _selectedOwnerId = ownerId;
      _deviceOwnerMap.clear();
    });

    if (ownerId != null && ownerId.isNotEmpty) {
      await _loadDeviceOwnersForOwner(ownerId);
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadAllDeviceOwners() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('TRACKER_DeviceOwner')
        .get();

    _deviceOwnerByDeviceId.clear();
    for (final doc in snapshot.docs) {
      final deviceOwner = DeviceOwner.fromDoc(doc);
      final existing = _deviceOwnerByDeviceId[deviceOwner.deviceId];
      if (existing == null ||
          deviceOwner.affectedAt.compareTo(existing.affectedAt) > 0) {
        _deviceOwnerByDeviceId[deviceOwner.deviceId] = deviceOwner;
      }
    }
  }

  Future<void> _loadData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection(kTrackerOwnerCollection)
        .get();

    _ownerMap.clear();
    for (final doc in snapshot.docs) {
      final owner = TrackerOwner.fromDoc(doc);
      if (owner.isActive) {
        _ownerMap[owner.id] = owner;
      }
    }

    await _loadAllDeviceOwners();

    if (_hasParamOwner) {
      _showUnassignedDevices = false;
      _selectedOwnerId = widget.ownerId;
      await _loadDeviceOwnersForOwner(_selectedOwnerId!);
    }

    if (mounted) {
      setState(() => _isDataLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.adminTrackerDevicesTitle,
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: _buildFloatingButtons(context),
      body: SafeArea(
        child: !_isDataLoaded
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSyncStatus(context),
                    const SizedBox(height: 12),
                    _buildFilters(context),
                    const SizedBox(height: 12),
                    Expanded(child: _buildDeviceList(context)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSyncStatus(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    if (!_isSyncingInspirit) return const SizedBox.shrink();

    final label = l10n.adminTrackerDevicesSyncInspiritInProgress;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colors.card,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () async {
            final nextValue = !_showUnassignedDevices;
            setState(() => _showUnassignedDevices = nextValue);

            if (_showUnassignedDevices) {
              setState(() {
                _selectedOwnerId = null;
                _deviceOwnerMap.clear();
              });
            } else if (_hasParamOwner) {
              await _applyOwnerSelection(widget.ownerId);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: _showUnassignedDevices,
                onChanged: (v) async {
                  final nextValue = v == true;
                  setState(() => _showUnassignedDevices = nextValue);

                  if (_showUnassignedDevices) {
                    setState(() {
                      _selectedOwnerId = null;
                      _deviceOwnerMap.clear();
                    });
                  } else if (_hasParamOwner) {
                    await _applyOwnerSelection(widget.ownerId);
                  }
                },
              ),
              Expanded(
                child: Text(
                  l10n.adminTrackerDevicesShowUnassigned,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: _showUnassignedDevices ? 0.45 : 1,
          child: IgnorePointer(
            ignoring: _showUnassignedDevices,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: colors.card,
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedOwnerId,
                      dropdownColor: colors.card,
                      isExpanded: true,
                      decoration: const InputDecoration(border: InputBorder.none),
                      hint: Text(
                        l10n.adminTrackerDevicesSelectOwner,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      items: _ownerMap.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(
                            entry.value.name,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        setState(() {
                          _selectedOwnerId = value;
                          _deviceOwnerMap.clear();
                        });

                        if (_selectedOwnerId != null) {
                          await _loadDeviceOwnersForOwner(_selectedOwnerId!);
                          if (mounted) setState(() {});
                        }
                      },
                    ),
                  ),
                  if (_selectedOwnerId != null)
                    IconButton(
                      icon: Icon(Icons.close, color: colors.textSecondary),
                      tooltip: l10n.adminTrackerDevicesResetFilter,
                      onPressed: () {
                        setState(() {
                          _selectedOwnerId = null;
                          _deviceOwnerMap.clear();
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceList(BuildContext context) {
    final l10n = context.l10n;

    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: TrackerDeviceAdminService.instance.watchDevicesOrdered(),
      builder: (context, snap) {
        if (snap.hasError) {
          return _emptyState(
            context,
            l10n.adminTrackerDevicesLoadError,
            snap.error.toString(),
          );
        }

        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!;

        if (docs.isEmpty) {
          return _emptyState(
            context,
            l10n.adminTrackerDevicesEmpty,
            l10n.adminTrackerDevicesEmptySubtitle,
          );
        }

        final visibleDocs = docs.where((d) {
          final data = d.data();
          final ownerId = (data['ownerId'] ?? '').toString().trim();

          if (_selectedOwnerId != null && _selectedOwnerId!.isNotEmpty) {
            // Prefer DeviceOwner assignment; also accept TRACKER_Device.ownerId
            // so Polar sensors just written to the kit remain visible.
            final assignedViaOwnerTable = _deviceOwnerMap[d.id] != null;
            final assignedOnDevice = ownerId == _selectedOwnerId;
            if (!assignedViaOwnerTable && !assignedOnDevice) return false;
          }

          if (_showUnassignedDevices && ownerId.isNotEmpty) {
            return false;
          }

          return true;
        }).toList();

        if (visibleDocs.isEmpty) {
          return _emptyState(
            context,
            l10n.adminTrackerDevicesEmpty,
            l10n.adminTrackerDevicesEmptySubtitle,
          );
        }

        return ListView.separated(
          itemCount: visibleDocs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) =>
              _buildDeviceTile(context, visibleDocs[i]),
        );
      },
    );
  }

  Widget _buildDeviceTile(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final data = doc.data();

    final serial = _serialFromMap(data);
    final deviceId = _idFromMap(data, doc.id);
    final provider = _providerFromMap(data);
    final deviceName = (data['device_name'] ?? data['deviceName'] ?? '')
        .toString()
        .trim();
    final isActive = (data['isActive'] ?? true) == true;
    final ownerId = (data['ownerId'] ?? '').toString();
    final updatedAt = _formatTimestamp(context, data['updatedAt']);
    final ownerName = ownerId.isNotEmpty ? _ownerMap[ownerId]?.name : null;
    final customName = (_deviceOwnerMap[doc.id] ?? _deviceOwnerByDeviceId[doc.id])
            ?.customName ??
        (data['custom_name'] ?? data['customName'])?.toString();
    final titleText = customName != null && customName.trim().isNotEmpty
        ? '$deviceId (${customName.trim()})'
        : (deviceName.isNotEmpty ? deviceName : deviceId);

    return Material(
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.devices, color: colors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleText,
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (provider.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.adminTrackerDevicesSource(provider),
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                  if (serial.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      l10n.adminTrackerDevicesSerial(serial),
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                  if (updatedAt.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      l10n.adminTrackerDevicesUpdatedAt(updatedAt),
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                  if (ownerName != null && ownerName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      ownerName,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: isActive
                        ? colors.success.withValues(alpha: 0.15)
                        : colors.textSecondary.withValues(alpha: 0.15),
                  ),
                  child: Text(
                    isActive
                        ? l10n.adminTrackerDevicesStatusActive
                        : l10n.adminTrackerDevicesStatusInactive,
                    style: textTheme.labelSmall?.copyWith(
                      color: isActive ? colors.success : colors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => ownerId.isEmpty
                      ? _showAssignDialog(
                          context: context,
                          deviceId: doc.id,
                        )
                      : _unassignDevice(context, doc.id),
                  icon: Icon(
                    ownerId.isEmpty ? Icons.link : Icons.link_off,
                    size: 16,
                  ),
                  label: Text(
                    ownerId.isEmpty
                        ? l10n.adminTrackerDevicesAssign
                        : l10n.adminTrackerDevicesUnassign,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unassignDevice(BuildContext context, String deviceId) async {
    final l10n = context.l10n;

    try {
      await TrackerDeviceAdminService.instance.unassignDevice(deviceId);
      _deviceOwnerMap.remove(deviceId);
      _deviceOwnerByDeviceId.remove(deviceId);
      if (mounted) {
        AppSnackbar.show(
          context,
          l10n.adminTrackerDevicesUnassignSuccess,
          isError: false,
        );
      }
    } on StateError catch (e) {
      if (e.message == 'permission-denied' && mounted) {
        AppSnackbar.show(context, l10n.adminTrackerDevicesPermissionDenied);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          l10n.adminTrackerDevicesError(e.toString()),
        );
      }
    }
  }

  Future<void> _showAssignDialog({
    required BuildContext context,
    required String deviceId,
  }) async {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    String? dialogOwnerId;
    final nameCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.card,
          title: Text(
            l10n.adminTrackerDevicesAssignTitle,
            style: textTheme.titleLarge?.copyWith(color: colors.textPrimary),
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.border),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: dialogOwnerId,
                        dropdownColor: colors.card,
                        isExpanded: true,
                        decoration:
                            const InputDecoration(border: InputBorder.none),
                        hint: Text(
                          l10n.adminTrackerDevicesSelectOwner,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        items: _ownerMap.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(
                              entry.value.name,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setStateDialog(() => dialogOwnerId = value);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.adminTrackerDevicesCustomName,
                        labelStyle: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.adminTrackerDevicesCancel),
            ),
            TextButton(
              onPressed: () async {
                if (dialogOwnerId == null || dialogOwnerId!.isEmpty) {
                  AppSnackbar.show(
                    context,
                    l10n.adminTrackerDevicesSelectOwnerRequired,
                  );
                  return;
                }

                final custom = nameCtrl.text.trim();

                try {
                  await TrackerDeviceAdminService.instance.assignDeviceToOwner(
                    deviceId: deviceId,
                    ownerId: dialogOwnerId!,
                    customName: custom.isEmpty ? null : custom,
                  );

                  final deviceOwner =
                      await DeviceOwnerService().getByDeviceId(deviceId);
                  if (deviceOwner != null) {
                    _deviceOwnerByDeviceId[deviceId] = deviceOwner;
                    if (_selectedOwnerId == dialogOwnerId) {
                      _deviceOwnerMap[deviceId] = deviceOwner;
                    }
                  }

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    AppSnackbar.show(
                      context,
                      l10n.adminTrackerDevicesAssignSuccess,
                      isError: false,
                    );
                  }
                } on StateError catch (e) {
                  if (e.message == 'permission-denied' && context.mounted) {
                    AppSnackbar.show(
                      context,
                      l10n.adminTrackerDevicesPermissionDenied,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    AppSnackbar.show(
                      context,
                      l10n.adminTrackerDevicesError(e.toString()),
                    );
                  }
                }
              },
              child: Text(l10n.adminTrackerDevicesValidate),
            ),
          ],
        );
      },
    );

    nameCtrl.dispose();
  }

  Widget _buildFloatingButtons(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          heroTag: 'add_polar',
          onPressed: () => _onAddPolarPressed(context),
          icon: const Icon(Icons.bluetooth_searching),
          label: Text(l10n.adminTrackerDevicesAddPolar),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: 'sync_inspirit',
          onPressed: _isSyncingInspirit ? null : () => _onSyncInspirit(context),
          icon: const Icon(Icons.sync),
          label: Text(l10n.adminTrackerDevicesSyncInspirit),
        ),
      ],
    );
  }

  Future<void> _onAddPolarPressed(BuildContext context) async {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    if (!kIsWeb) {
      await _showAddPolarDialog(context);
      return;
    }

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.adminTrackerDevicesAddPolarTitle,
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Icon(Icons.bluetooth, color: colors.primary),
                  title: Text(l10n.adminTrackerDevicesAddPolarChrome),
                  onTap: () => Navigator.pop(ctx, 'chrome'),
                ),
                ListTile(
                  leading: Icon(Icons.edit, color: colors.textSecondary),
                  title: Text(l10n.adminTrackerDevicesAddPolarManual),
                  onTap: () => Navigator.pop(ctx, 'manual'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!context.mounted || choice == null) return;
    if (choice == 'chrome') {
      await _addPolarViaChrome(context);
    } else {
      await _showAddPolarDialog(context);
    }
  }

  Future<void> _addPolarViaChrome(BuildContext context) async {
    final l10n = context.l10n;
    final bluetooth = PolarWebBluetoothService.instance;

    if (!bluetooth.isSupported) {
      AppSnackbar.show(context, l10n.adminTrackerDevicesAddPolarChromeUnsupported);
      return;
    }

    try {
      // Bluetooth first — keeps the user gesture for Chrome's chooser.
      final pick = await bluetooth.pickPolarDevice();
      if (!context.mounted) return;

      if (pick == null) {
        AppSnackbar.show(
          context,
          l10n.adminTrackerDevicesAddPolarChromeCancelled,
        );
        return;
      }

      final identity = pick.identity;
      // Then association: owner + customName (jersey / label).
      final assignment = await _promptPolarAssignment(
        context,
        suggestedCustomName: '',
        deviceLabel: identity.displayName,
      );
      if (!context.mounted) return;
      if (assignment == null) {
        AppSnackbar.show(context, l10n.adminTrackerDevicesSelectOwnerRequired);
        return;
      }

      await _registerPolarDeviceInInventory(
        polarDeviceId: identity.deviceId,
        deviceType: identity.deviceType,
        deviceName: identity.displayName,
        ownerId: assignment.ownerId,
        customName: assignment.customName,
      );

      if (!context.mounted) return;
      AppSnackbar.show(
        context,
        l10n.adminTrackerDevicesAddPolarChromeSuccess(
          identity.deviceId,
          identity.deviceType,
        ),
        isError: false,
      );
    } on StateError catch (e) {
      if (!context.mounted) return;
      if (e.message == 'owner-required') {
        AppSnackbar.show(context, l10n.adminTrackerDevicesSelectOwnerRequired);
        return;
      }
      if (e.message == 'permission-denied') {
        AppSnackbar.show(context, l10n.adminTrackerDevicesPermissionDenied);
        return;
      }
      if (e.message.startsWith('polar-id-not-in-name') ||
          e.message == 'web-bluetooth-unsupported') {
        AppSnackbar.show(
          context,
          e.message == 'web-bluetooth-unsupported'
              ? l10n.adminTrackerDevicesAddPolarChromeUnsupported
              : l10n.adminTrackerDevicesAddPolarChromeNoId,
        );
        await _showAddPolarDialog(context);
        return;
      }
      AppSnackbar.show(context, l10n.adminTrackerDevicesError(e.toString()));
    } catch (e) {
      if (!context.mounted) return;
      AppSnackbar.show(context, l10n.adminTrackerDevicesError(e.toString()));
    }
  }

  /// Creates the Polar device and assigns it with [customName] on DeviceOwner.
  Future<void> _registerPolarDeviceInInventory({
    required String polarDeviceId,
    required String ownerId,
    String? deviceType,
    String? deviceName,
    String? customName,
  }) async {
    final kitOwnerId = ownerId.trim();
    if (kitOwnerId.isEmpty) {
      throw StateError('owner-required');
    }

    final label = customName?.trim();
    final deviceId =
        await TrackerDeviceAdminService.instance.createPolarDevice(
      polarDeviceId: polarDeviceId,
      ownerId: kitOwnerId,
      deviceType: deviceType,
      deviceName: deviceName,
      customName: label,
    );

    await TrackerDeviceAdminService.instance.assignDeviceToOwner(
      deviceId: deviceId,
      ownerId: kitOwnerId,
      customName: label,
    );
    await _loadDeviceOwnersForOwner(kitOwnerId);
    await _loadAllDeviceOwners();
    if (mounted) {
      setState(() {
        _showUnassignedDevices = false;
        _selectedOwnerId = kitOwnerId;
      });
    }
  }

  /// Dialog: kit owner + [customName] (jersey / label) at association time.
  Future<_PolarAssignment?> _promptPolarAssignment(
    BuildContext context, {
    String suggestedCustomName = '',
    String? deviceLabel,
  }) async {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    if (_ownerMap.isEmpty) {
      AppSnackbar.show(context, l10n.adminTrackerDevicesSelectOwnerRequired);
      return null;
    }

    final polarOwners = _ownerMap.entries
        .where((e) => TrackerOwner.isPolarType(e.value.typeTracker))
        .toList();
    final otherOwners = _ownerMap.entries
        .where((e) => !TrackerOwner.isPolarType(e.value.typeTracker))
        .toList();
    final entries = <MapEntry<String, TrackerOwner>>[
      ...polarOwners,
      ...otherOwners,
    ];

    final preselected = (_selectedOwnerId ?? widget.ownerId)?.trim();
    String? dialogOwnerId = (preselected != null &&
            preselected.isNotEmpty &&
            _ownerMap.containsKey(preselected))
        ? preselected
        : (polarOwners.isNotEmpty ? polarOwners.first.key : entries.first.key);

    final nameCtrl = TextEditingController(text: suggestedCustomName);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: colors.card,
              title: Text(
                l10n.adminTrackerDevicesAssignTitle,
                style: textTheme.titleLarge?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (deviceLabel != null && deviceLabel.trim().isNotEmpty) ...[
                      Text(
                        deviceLabel.trim(),
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    DropdownButtonFormField<String>(
                      value: dialogOwnerId,
                      dropdownColor: colors.card,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l10n.adminTrackerDevicesSelectOwner,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: entries
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e.key,
                              child: Text(
                                '${e.value.name} (${l10n.adminTrackerOwnerTypeLabel(e.value.typeTracker)})',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setStateDialog(() => dialogOwnerId = value),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.adminTrackerDevicesCustomName,
                        hintText: l10n.adminTrackerDevicesCustomNameHint,
                        labelStyle: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.adminTrackerDevicesCancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.adminTrackerDevicesValidate),
                ),
              ],
            );
          },
        );
      },
    );

    final custom = nameCtrl.text.trim();
    nameCtrl.dispose();

    if (confirmed != true) return null;
    final picked = dialogOwnerId?.trim();
    if (picked == null || picked.isEmpty) {
      if (context.mounted) {
        AppSnackbar.show(context, l10n.adminTrackerDevicesSelectOwnerRequired);
      }
      return null;
    }
    return _PolarAssignment(
      ownerId: picked,
      customName: custom.isEmpty ? null : custom,
    );
  }

  Future<void> _showAddPolarDialog(BuildContext context) async {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final idCtrl = TextEditingController();
    var deviceType = 'H10';

    final draft = await showDialog<_PolarManualDraft>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: colors.card,
              title: Text(
                l10n.adminTrackerDevicesAddPolarTitle,
                style: textTheme.titleLarge?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: idCtrl,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.adminTrackerDevicesAddPolarDeviceId,
                        hintText: l10n.adminTrackerDevicesAddPolarDeviceIdHint,
                        labelStyle: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: deviceType,
                      dropdownColor: colors.card,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l10n.adminTrackerDevicesAddPolarDeviceType,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: <MapEntry<String, String>>[
                        MapEntry('H10', l10n.adminTrackerDevicesPolarTypeH10),
                        MapEntry('H9', l10n.adminTrackerDevicesPolarTypeH9),
                        MapEntry(
                          'Verity Sense',
                          l10n.adminTrackerDevicesPolarTypeVeritySense,
                        ),
                        MapEntry('OH1', l10n.adminTrackerDevicesPolarTypeOh1),
                        MapEntry(
                          'other',
                          l10n.adminTrackerDevicesPolarTypeOther,
                        ),
                      ]
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e.key,
                              child: Text(
                                e.value,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setStateDialog(
                        () => deviceType = value ?? 'H10',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.adminTrackerDevicesCancel),
                ),
                TextButton(
                  onPressed: () {
                    final polarId = idCtrl.text.trim();
                    if (polarId.isEmpty) {
                      AppSnackbar.show(
                        context,
                        l10n.adminTrackerDevicesAddPolarDeviceIdRequired,
                      );
                      return;
                    }
                    Navigator.pop(
                      ctx,
                      _PolarManualDraft(
                        polarDeviceId: polarId,
                        deviceType: deviceType,
                      ),
                    );
                  },
                  child: Text(l10n.adminTrackerDevicesValidate),
                ),
              ],
            );
          },
        );
      },
    );

    idCtrl.dispose();
    if (draft == null || !context.mounted) return;

    final assignment = await _promptPolarAssignment(
      context,
      deviceLabel: draft.polarDeviceId,
    );
    if (!context.mounted) return;
    if (assignment == null) {
      AppSnackbar.show(context, l10n.adminTrackerDevicesSelectOwnerRequired);
      return;
    }

    try {
      await _registerPolarDeviceInInventory(
        polarDeviceId: draft.polarDeviceId,
        ownerId: assignment.ownerId,
        deviceType: draft.deviceType,
        customName: assignment.customName,
      );
      if (!context.mounted) return;
      AppSnackbar.show(
        context,
        l10n.adminTrackerDevicesAddPolarSuccess,
        isError: false,
      );
    } on StateError catch (e) {
      if (!context.mounted) return;
      if (e.message == 'owner-required') {
        AppSnackbar.show(context, l10n.adminTrackerDevicesSelectOwnerRequired);
      } else if (e.message == 'permission-denied') {
        AppSnackbar.show(context, l10n.adminTrackerDevicesPermissionDenied);
      } else {
        AppSnackbar.show(context, l10n.adminTrackerDevicesError(e.toString()));
      }
    } catch (e) {
      if (!context.mounted) return;
      AppSnackbar.show(context, l10n.adminTrackerDevicesError(e.toString()));
    }
  }

  Future<void> _onSyncInspirit(BuildContext context) async {
    final l10n = context.l10n;
    setState(() => _isSyncingInspirit = true);

    try {
      final devices = await _sync.fetchInspiritInsidersDevices();
      final count = await TrackerDeviceAdminService.instance.upsertSyncedDevices(
        devices,
        provider: 'inspirit',
      );

      if (!mounted) return;
      AppSnackbar.show(
        context,
        l10n.adminTrackerDevicesSyncInspiritSuccess(count),
        isError: false,
      );
    } on StateError catch (e) {
      if (e.message == 'permission-denied' && mounted) {
        AppSnackbar.show(context, l10n.adminTrackerDevicesPermissionDenied);
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        l10n.adminTrackerDevicesSyncInspiritError(e.toString()),
      );
    } finally {
      if (mounted) setState(() => _isSyncingInspirit = false);
    }
  }

  Widget _emptyState(BuildContext context, String title, String subtitle) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.devices, size: 42, color: colors.textSecondary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _serialFromMap(Map<String, dynamic> data) {
    return (data['serial'] ??
            data['serialNumber'] ??
            data['serial_number'] ??
            '')
        .toString();
  }

  String _idFromMap(Map<String, dynamic> data, String docId) {
    final id = (data['id'] ?? '').toString().trim();
    if (id.isNotEmpty) return id;
    return docId;
  }

  String _providerFromMap(Map<String, dynamic> data) {
    return (data['provider'] ?? data['source'] ?? '').toString();
  }

  String _formatTimestamp(BuildContext context, dynamic value) {
    if (value is! Timestamp) return '';
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMd(locale).add_Hm().format(value.toDate());
  }
}

class _PolarAssignment {
  const _PolarAssignment({
    required this.ownerId,
    this.customName,
  });

  final String ownerId;
  final String? customName;
}

class _PolarManualDraft {
  const _PolarManualDraft({
    required this.polarDeviceId,
    required this.deviceType,
  });

  final String polarDeviceId;
  final String deviceType;
}
