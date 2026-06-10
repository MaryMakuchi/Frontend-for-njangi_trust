import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Initializes Firebase when configured. Skips gracefully in mock/dev mode.
Future<bool> initializeFirebase({bool useFirebase = false}) async {
  if (!useFirebase) return false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } catch (_) {
    return false;
  }
}
