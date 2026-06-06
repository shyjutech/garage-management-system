import 'package:flutter/material.dart';
import 'package:garage_management_system/src/auth/auth_gate.dart';
import 'package:garage_management_system/src/theme/app_theme.dart';

class GarageManagementApp extends StatelessWidget {
  const GarageManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sarathi Garage',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}
