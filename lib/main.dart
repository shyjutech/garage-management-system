import 'package:flutter/material.dart';
import 'package:garage_management_system/src/app_root.dart';
import 'package:garage_management_system/src/services/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();
  runApp(const GarageManagementApp());
}
