import 'package:cloud_firestore/cloud_firestore.dart';

class Device {
  final String id;
  final DateTime? createdAt;
  final String? customName;
  final String? deviceName;
  final String? deviceType;
  final String? firmwareVersion;
  final String? hardwareVersion;
  final String? ownerId;
  final String? provider;
  final String? serialNumber;
  final DateTime? updatedAt;

  Device({
    required this.id,
    this.createdAt,
    this.customName,
    this.deviceName,
    this.deviceType,
    this.firmwareVersion,
    this.hardwareVersion,
    this.ownerId,
    this.provider,
    this.serialNumber,
    this.updatedAt,
  });

  Device copyWith({
    String? id,
    DateTime? createdAt,
    String? customName,
    String? deviceName,
    String? deviceType,
    String? firmwareVersion,
    String? hardwareVersion,
    String? ownerId,
    String? provider,
    String? serialNumber,
    DateTime? updatedAt,
  }) {
    return Device(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      customName: customName ?? this.customName,
      deviceName: deviceName ?? this.deviceName,
      deviceType: deviceType ?? this.deviceType,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      hardwareVersion: hardwareVersion ?? this.hardwareVersion,
      ownerId: ownerId ?? this.ownerId,
      provider: provider ?? this.provider,
      serialNumber: serialNumber ?? this.serialNumber,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'custom_name': customName,
      'device_name': deviceName,
      'device_type': deviceType,
      'firmware_version': firmwareVersion,
      'hardware_version': hardwareVersion,
      'ownerId': ownerId,
      'provider': provider,
      'serial_number': serialNumber,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory Device.fromMap(Map<String, dynamic> map) {
    return Device(
      id: (map['id'] ?? '').toString(),
      createdAt: _toDateTime(map['createdAt']),
      customName: map['custom_name']?.toString(),
      deviceName: map['device_name']?.toString(),
      deviceType: map['device_type']?.toString(),
      firmwareVersion: map['firmware_version']?.toString(),
      hardwareVersion: map['hardware_version']?.toString(),
      ownerId: map['ownerId']?.toString(),
      provider: map['provider']?.toString(),
      serialNumber: map['serial_number']?.toString(),
      updatedAt: _toDateTime(map['updatedAt']),
    );
  }

  factory Device.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return Device(
      id: data['id']?.toString().isNotEmpty == true
          ? data['id'].toString()
          : doc.id,
      createdAt: _toDateTime(data['createdAt']),
      customName: data['custom_name']?.toString(),
      deviceName: data['device_name']?.toString(),
      deviceType: data['device_type']?.toString(),
      firmwareVersion: data['firmware_version']?.toString(),
      hardwareVersion: data['hardware_version']?.toString(),
      ownerId: data['ownerId']?.toString(),
      provider: data['provider']?.toString(),
      serialNumber: data['serial_number']?.toString(),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}