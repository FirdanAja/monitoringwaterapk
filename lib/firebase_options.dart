import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
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
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD6ArV24LZW_w_CNzMS09jDqlF2SLIUugE',
    appId: '1:558626168804:web:324e4caf76dede126ab1f1',
    messagingSenderId: '558626168804',
    projectId: 'monitoring-air-pdam-8d0a8',
    authDomain: 'monitoring-air-pdam-8d0a8.firebaseapp.com',
    databaseURL: 'https://monitoring-air-pdam-8d0a8-default-rtdb.firebaseio.com',
    storageBucket: 'monitoring-air-pdam-8d0a8.firebasestorage.app',
    measurementId: 'G-MBK1XV1RVK',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB9MMUBh-YR8uOkhk8hZISWCWLVaRHXttY',
    appId: '1:558626168804:android:2491ca7259d087cf6ab1f1',
    messagingSenderId: '558626168804',
    projectId: 'monitoring-air-pdam-8d0a8',
    databaseURL: 'https://monitoring-air-pdam-8d0a8-default-rtdb.firebaseio.com',
    storageBucket: 'monitoring-air-pdam-8d0a8.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB7yTyaHQ4oNlPnLTx45nRRsxuFPS6Dvgw',
    appId: '1:558626168804:ios:066d5e5dff234d3e6ab1f1',
    messagingSenderId: '558626168804',
    projectId: 'monitoring-air-pdam-8d0a8',
    databaseURL: 'https://monitoring-air-pdam-8d0a8-default-rtdb.firebaseio.com',
    storageBucket: 'monitoring-air-pdam-8d0a8.firebasestorage.app',
    iosClientId: '558626168804-4151pcivfi09rdm2e1b7cfjau8ofkc3t.apps.googleusercontent.com',
    iosBundleId: 'com.example.monitoringwaterapk',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB7yTyaHQ4oNlPnLTx45nRRsxuFPS6Dvgw',
    appId: '1:558626168804:ios:066d5e5dff234d3e6ab1f1',
    messagingSenderId: '558626168804',
    projectId: 'monitoring-air-pdam-8d0a8',
    databaseURL: 'https://monitoring-air-pdam-8d0a8-default-rtdb.firebaseio.com',
    storageBucket: 'monitoring-air-pdam-8d0a8.firebasestorage.app',
    iosClientId: '558626168804-4151pcivfi09rdm2e1b7cfjau8ofkc3t.apps.googleusercontent.com',
    iosBundleId: 'com.example.monitoringwaterapk',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD6ArV24LZW_w_CNzMS09jDqlF2SLIUugE',
    appId: '1:558626168804:web:459fdf084ef6ead86ab1f1',
    messagingSenderId: '558626168804',
    projectId: 'monitoring-air-pdam-8d0a8',
    authDomain: 'monitoring-air-pdam-8d0a8.firebaseapp.com',
    databaseURL: 'https://monitoring-air-pdam-8d0a8-default-rtdb.firebaseio.com',
    storageBucket: 'monitoring-air-pdam-8d0a8.firebasestorage.app',
    measurementId: 'G-40R2YBFV4M',
  );
}
