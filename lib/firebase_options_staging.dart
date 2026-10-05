// File generated for RioDent Staging environment.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase options for the STAGING environment (`riodent-staging`).
class StagingFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'StagingFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBwgEznqjkcAzQpYpfegLlEzYUzVbZMPX4',
    appId: '1:731874500291:web:ab6150899e703e7e834c76',
    messagingSenderId: '731874500291',
    projectId: 'riodent-staging',
    authDomain: 'riodent-staging.firebaseapp.com',
    storageBucket: 'riodent-staging.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAD6P7uKiigWGRoYa-ju4NxV_AXeNwMDsc',
    appId: '1:731874500291:android:29362e1f5f7d4650834c76',
    messagingSenderId: '731874500291',
    projectId: 'riodent-staging',
    storageBucket: 'riodent-staging.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAD6P7uKiigWGRoYa-ju4NxV_AXeNwMDsc',
    appId: '1:731874500291:android:29362e1f5f7d4650834c76',
    messagingSenderId: '731874500291',
    projectId: 'riodent-staging',
    storageBucket: 'riodent-staging.firebasestorage.app',
    iosBundleId: 'com.riodent.riodent',
  );
}
