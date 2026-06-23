import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for Windows with Firebase Analytics.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB2b2jmuizBpCXtE5lNfV-YoXmq4Ec2WRk',
    appId: '1:626293600533:web:cd2bb4abec1eeef2a8791c',
    messagingSenderId: '626293600533',
    projectId: 'aserstein-2453e',
    authDomain: 'auth.grinta.io',
    storageBucket: 'aserstein-2453e.appspot.com',
    measurementId: 'G-DWZBSPWQH8',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDVH6-cWa529FOnCYPE4166rpxOSX2i7HY',
    appId: '1:626293600533:android:e2d12e06bd907a92a8791c',
    messagingSenderId: '626293600533',
    projectId: 'aserstein-2453e',
    storageBucket: 'aserstein-2453e.appspot.com',
    databaseURL: 'https://aserstein-2453e.firebaseio.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD_pjnsmxdTyvaaINWW1Z8xRDbG2t1xLAU',
    appId: '1:626293600533:ios:48ed2a621067eddda8791c',
    messagingSenderId: '626293600533',
    projectId: 'aserstein-2453e',
    storageBucket: 'aserstein-2453e.appspot.com',
    databaseURL: 'https://aserstein-2453e.firebaseio.com',
    iosBundleId: 'io.grinta.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD_pjnsmxdTyvaaINWW1Z8xRDbG2t1xLAU',
    appId: '1:626293600533:ios:48ed2a621067eddda8791c',
    messagingSenderId: '626293600533',
    projectId: 'aserstein-2453e',
    storageBucket: 'aserstein-2453e.appspot.com',
    databaseURL: 'https://aserstein-2453e.firebaseio.com',
    iosBundleId: 'io.grinta.app',
  );
}
