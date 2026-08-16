import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/services/biometric_login_credentials_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> memory;
  late BiometricLoginCredentialsStore store;

  setUp(() {
    memory = <String, String>{};
    FlutterSecureStoragePlatform.instance =
        TestFlutterSecureStoragePlatform(memory);
    store = BiometricLoginCredentialsStore(
      storage: const FlutterSecureStorage(),
    );
  });

  test('save / read / clear round-trip', () async {
    expect(await store.hasCredentials(), isFalse);

    await store.save(
      uid: 'uid-1',
      email: 'coach@grinta.io',
      password: 'Secret1!',
    );

    expect(await store.hasCredentials(), isTrue);
    expect(await store.peekEmail(), 'coach@grinta.io');

    final credentials = await store.read();
    expect(credentials, isNotNull);
    expect(credentials!.uid, 'uid-1');
    expect(credentials.email, 'coach@grinta.io');
    expect(credentials.password, 'Secret1!');

    await store.clear();
    expect(await store.hasCredentials(), isFalse);
    expect(await store.read(), isNull);
  });

  test('read returns null when incomplete', () async {
    memory['biometric_login_email_v1'] = 'only@email.io';
    expect(await store.hasCredentials(), isFalse);
    expect(await store.read(), isNull);
  });
}
