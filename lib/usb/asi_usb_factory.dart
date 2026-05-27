import 'asi_usb_client.dart';
import 'impl/asi_usb_stub.dart' if (dart.library.html) 'impl/asi_usb_web.dart';

AsiUsbClient createAsiUsbClient() => createAsiUsbClientImpl();
