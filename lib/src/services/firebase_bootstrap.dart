import 'package:garage_management_system/src/firebase_options.dart';

class FirebaseBootstrap {
  static bool get isConfigured {
    final options = DefaultFirebaseOptions.currentPlatform;
    return !options.projectId.startsWith('REPLACE_WITH');
  }
}
