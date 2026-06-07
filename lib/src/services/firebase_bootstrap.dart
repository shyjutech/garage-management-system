import 'package:firebase_core/firebase_core.dart';
import 'package:garage_management_system/firebase_options.dart';

class FirebaseBootstrap {
  static bool initialized = false;
  static String? initError;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      initialized = true;
      initError = null;
    } catch (error) {
      initialized = false;
      initError = error.toString();
    }
  }

  static bool get isConfigured {
    if (!initialized) {
      return false;
    }
    final options = DefaultFirebaseOptions.currentPlatform;
    return !options.projectId.startsWith('REPLACE_WITH');
  }
}
