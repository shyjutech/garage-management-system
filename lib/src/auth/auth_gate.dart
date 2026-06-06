import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:garage_management_system/src/app.dart';
import 'package:garage_management_system/src/auth/login_page.dart';
import 'package:garage_management_system/src/repositories/garage_repository.dart';
import 'package:garage_management_system/src/services/firebase_bootstrap.dart';
import 'package:garage_management_system/src/store/garage_store.dart';
import 'package:garage_management_system/src/theme/app_theme.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!FirebaseBootstrap.isConfigured) {
      return ChangeNotifierProvider(
        create: (_) => GarageStore.memory()..seed(),
        child: MaterialApp(
          title: 'Sarathi Garage',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const HomeShell(),
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.data == null) {
          return MaterialApp(
            title: 'Sarathi Garage',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: const LoginPage(),
          );
        }

        return ChangeNotifierProvider(
          create: (_) => GarageStore.firestore(GarageRepository())..initialize(),
          child: Consumer<GarageStore>(
            builder: (context, store, _) {
              if (store.loading) {
                return MaterialApp(
                  theme: AppTheme.light,
                  home: const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              return MaterialApp(
                title: 'Sarathi Garage',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                home: const HomeShell(),
              );
            },
          ),
        );
      },
    );
  }
}
