
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web Firebase options are not configured. Use flutterfire configure.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'Add GoogleService-Info.plist and run flutterfire configure for Apple platforms.',
        );
      default:
        throw UnsupportedError(
          'This app only initializes Firebase on Android in firebase_options.dart.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAyO0xK84hlhNa-w-Czz82yZ_5vyqxW-7w',
    appId: '1:962185848641:android:2cb897634bfd58a57d23c0',
    messagingSenderId: '962185848641',
    projectId: 'b-teck',
    storageBucket: 'b-teck.firebasestorage.app',
    databaseURL: 'https://b-teck-default-rtdb.firebaseio.com',
  );
}
