import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Initialize Firebase if the platform has been configured.
///
/// Returns true on success. Guarded so the app still runs when Firebase hasn't
/// been set up yet (run `flutterfire configure` to generate the native config).
Future<bool> initializeFirebase() async {
  try {
    await Firebase.initializeApp();
    return true;
  } catch (e) {
    debugPrint('Firebase not initialized (push disabled): $e');
    return false;
  }
}
