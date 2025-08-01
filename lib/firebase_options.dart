// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
    apiKey: 'AIzaSyCKXaWJI7kjuB6NF8JHld4IzQDq2tEyVZo',
    appId: '1:417986149944:web:ad47ae8f70f23c0a5530cd',
    messagingSenderId: '417986149944',
    projectId: 'lighting-company-app',
    authDomain: 'lighting-company-app.firebaseapp.com',
    storageBucket: 'lighting-company-app.firebasestorage.app',
    measurementId: 'G-BBDEESJQC5',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAKLZWEuREd3AYflwee7N6H5H-wBze7iyo',
    appId: '1:417986149944:android:ab8f29725f5db7b95530cd',
    messagingSenderId: '417986149944',
    projectId: 'lighting-company-app',
    storageBucket: 'lighting-company-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC7DZRh-_po_Gnc-V3h2N-xsRtQZGBJlnk',
    appId: '1:417986149944:ios:21471149de51cf125530cd',
    messagingSenderId: '417986149944',
    projectId: 'lighting-company-app',
    storageBucket: 'lighting-company-app.firebasestorage.app',
    iosBundleId: 'com.example.lightingCompanyApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC7DZRh-_po_Gnc-V3h2N-xsRtQZGBJlnk',
    appId: '1:417986149944:ios:21471149de51cf125530cd',
    messagingSenderId: '417986149944',
    projectId: 'lighting-company-app',
    storageBucket: 'lighting-company-app.firebasestorage.app',
    iosBundleId: 'com.example.lightingCompanyApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCKXaWJI7kjuB6NF8JHld4IzQDq2tEyVZo',
    appId: '1:417986149944:web:01959c9716a554945530cd',
    messagingSenderId: '417986149944',
    projectId: 'lighting-company-app',
    authDomain: 'lighting-company-app.firebaseapp.com',
    storageBucket: 'lighting-company-app.firebasestorage.app',
    measurementId: 'G-TP9CYYR1BW',
  );
}
