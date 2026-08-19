/// Classification of delete/remove failures for in-dialog error copy.
///
/// Kept free of Flutter/Firebase types so unit tests can lock the
/// permission-denied wording without a Firebase runtime.
abstract final class DeleteErrorMessage {
  DeleteErrorMessage._();

  /// True when Firestore (or another backend) rejected the write as unauthorized.
  static bool isPermissionDenied(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('permission-denied') ||
        text.contains('insufficient permissions');
  }
}
