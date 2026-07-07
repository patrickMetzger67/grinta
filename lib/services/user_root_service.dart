import 'dart:async' show Future, unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/services/userService.dart'
    show UserDocumentFields, UserService;

/// Loads `isRoot` from `users/{uid}` for platform admin access.
class UserRootService extends ChangeNotifier {
  UserRootService._() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  static final UserRootService instance = UserRootService._();

  bool _isRoot = false;
  bool _initialized = false;
  Future<void>? _initFuture;
  String? _loadedUid;

  bool get isRoot => _isRoot;

  void _onAuthChanged(User? user) {
    final uid = user?.uid;
    if (uid == _loadedUid) return;
    _isRoot = false;
    _initialized = false;
    _initFuture = null;
    _loadedUid = null;
    notifyListeners();
    if (uid != null) {
      unawaited(ensureInitialized());
    }
  }

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initFuture ??= _load();
    await _initFuture;
  }

  Future<void> reload() async {
    _initialized = false;
    _initFuture = null;
    await ensureInitialized();
    notifyListeners();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _initialized = true;
      notifyListeners();
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection(UserService.collectionName)
          .doc(uid)
          .get();
      if (FirebaseAuth.instance.currentUser?.uid != uid) {
        _initFuture = null;
        return;
      }

      _isRoot = doc.data()?[UserDocumentFields.isRoot] == true;
      _loadedUid = uid;
    } catch (e, st) {
      debugPrint('UserRootService load failed: $e\n$st');
    } finally {
      if (FirebaseAuth.instance.currentUser?.uid == uid) {
        _initialized = true;
        notifyListeners();
      } else {
        _initFuture = null;
      }
    }
  }
}
