import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC9Ngk4zM3Qw3kPYRSUoUSaEN2hZzMVMUI',
    appId: '1:935968037047:android:f443277268e3b44deb9532',
    messagingSenderId: '935968037047',
    projectId: 'laporin-raihan-sandbox',
    storageBucket: 'laporin-raihan-sandbox.firebasestorage.app',
  );
}