// Production Firebase options for riodent-prod (Project Number: 963410305787)
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// [FirebaseOptions] for the verified Production Firebase project (riodent-prod).
class ProdFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'ProdFirebaseOptions are currently configured for Android and Web.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBrlBkVPNd6nWPBLW10lAJ7ZVk02O9RWTM',
    appId: '1:963410305787:web:ee6630f8e14c082f58465e',
    messagingSenderId: '963410305787',
    projectId: 'riodent-prod',
    authDomain: 'riodent-prod.firebaseapp.com',
    storageBucket: 'riodent-prod.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA2OXf5wIFgTtlSQC6XBQgKamRg5oLEj88',
    appId: '1:963410305787:android:94ac4ea9e555c4f558465e',
    messagingSenderId: '963410305787',
    projectId: 'riodent-prod',
    storageBucket: 'riodent-prod.firebasestorage.app',
  );
}
