import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:garage_management_system/src/app_root.dart';
import 'package:garage_management_system/src/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Allows local UI development before firebase configuration is finalized.
  }
  runApp(const GarageManagementApp());
}
