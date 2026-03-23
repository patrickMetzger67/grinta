class AsiDeviceInfo {
  final String id;
  final int vendorId;
  final int productId;
  final String? productName;
  final Object? raw;

  AsiDeviceInfo({
    required this.id,
    required this.vendorId,
    required this.productId,
    this.productName,
    this.raw,
  });
}

class AsiSession {
  final AsiDeviceInfo device;
  final Object? raw;

  AsiSession({
    required this.device,
    this.raw,
  });
}