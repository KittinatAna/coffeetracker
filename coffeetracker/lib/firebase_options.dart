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
    apiKey: 'AIzaSyDvKkkCO5nRZAqic26qDP54xJp0y3UjMhk',
    appId: '1:659834791918:web:2cefe3de24d20b235d10ff',
    messagingSenderId: '659834791918',
    projectId: 'coffeetracker-01',
    authDomain: 'coffeetracker-01.firebaseapp.com',
    storageBucket: 'coffeetracker-01.appspot.com',
    measurementId: 'G-8905JVXP1N',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAbh7SwxtlfHLE6BVU32WOhvDu68h_vxkw',
    appId: '1:659834791918:android:f1301d389f72100a5d10ff',
    messagingSenderId: '659834791918',
    projectId: 'coffeetracker-01',
    storageBucket: 'coffeetracker-01.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBclFPStvEnHgvZFiRHJ8xcSYLRdUZ-PmY',
    appId: '1:659834791918:ios:79ab72cf8f446da25d10ff',
    messagingSenderId: '659834791918',
    projectId: 'coffeetracker-01',
    storageBucket: 'coffeetracker-01.appspot.com',
    iosBundleId: 'com.example.coffeetracker',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBclFPStvEnHgvZFiRHJ8xcSYLRdUZ-PmY',
    appId: '1:659834791918:ios:79ab72cf8f446da25d10ff',
    messagingSenderId: '659834791918',
    projectId: 'coffeetracker-01',
    storageBucket: 'coffeetracker-01.appspot.com',
    iosBundleId: 'com.example.coffeetracker',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDvKkkCO5nRZAqic26qDP54xJp0y3UjMhk',
    appId: '1:659834791918:web:4becf7a35f8be3005d10ff',
    messagingSenderId: '659834791918',
    projectId: 'coffeetracker-01',
    authDomain: 'coffeetracker-01.firebaseapp.com',
    storageBucket: 'coffeetracker-01.appspot.com',
    measurementId: 'G-5SNSW8Y9J9',
  );
}
