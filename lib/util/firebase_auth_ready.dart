import 'package:firebase_auth/firebase_auth.dart';

/// Waits until Firebase Auth has finished restoring a persisted session.
///
/// On hot restart the first [authStateChanges] event can be `null` before
/// local persistence rehydrates [FirebaseAuth.currentUser].
Future<void> waitForFirebaseAuthReady(
  FirebaseAuth auth, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  if (auth.currentUser != null) return;

  final DateTime deadline = DateTime.now().add(timeout);

  final User? firstEvent = await auth.authStateChanges().first
      .timeout(timeout, onTimeout: () => auth.currentUser);
  if (firstEvent != null || auth.currentUser != null) return;

  // Persistence may populate currentUser shortly after the first null emission.
  while (DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (auth.currentUser != null) return;
  }
}

/// True when there is no signed-in user after [waitForFirebaseAuthReady].
bool isFirebaseAuthDefinitelySignedOut(FirebaseAuth auth) {
  return auth.currentUser == null;
}
