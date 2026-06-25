import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Initialize Firebase using the generated platform options.
///
/// `firebase_options.dart` is produced by `flutterfire configure`. Initializing
/// with [DefaultFirebaseOptions] means push works without needing the native
/// google-services Gradle plugin. Guarded so the app still runs if Firebase is
/// unreachable for any reason.
Future<bool> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } catch (e) {
    debugPrint('Firebase not initialized (push disabled): $e');
    return false;
  }
}
