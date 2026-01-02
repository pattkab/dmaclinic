// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/settings_service.dart';
import 'models/clinic_settings.dart';

import 'ui/login_page.dart';
import 'ui/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const DmaClinicApp());
}

class DmaClinicApp extends StatelessWidget {
  const DmaClinicApp({super.key});

  ThemeData _theme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.blue.shade900,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,

      // ✅ FIX: CardThemeData (not CardTheme)
      cardTheme: CardThemeData(
        elevation: 1.5,
        surfaceTintColor: scheme.surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withOpacity(0.45),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.blue.shade900,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),

      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surfaceTint,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsSvc = SettingsService();

    return StreamBuilder<ClinicSettings>(
      stream: settingsSvc.streamSettings(),
      builder: (context, snap) {
        final settings = snap.data ?? ClinicSettings.defaults();

        return MaterialApp(
          title: settings.clinicName,
          debugShowCheckedModeBanner: false,
          theme: _theme(),
          home: AuthGate(settings: settings),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  final ClinicSettings settings;
  const AuthGate({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return StreamBuilder(
      stream: auth.authState(),
      builder: (context, snapshot) {
        final user = auth.user;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (user == null) return LoginPage(settings: settings);

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (roleSnap.hasError) {
              return Scaffold(
                appBar: AppBar(title: Text(settings.clinicName)),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Failed to load your profile from Firestore.\n\n'
                          'Error:\n${roleSnap.error}\n\n'
                          'Check Firestore rules and that users/{uid} exists.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            final data = roleSnap.data?.data();
            if (data == null) {
              return Scaffold(
                appBar: AppBar(title: Text(settings.clinicName)),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Your user profile was not found.\n\n'
                          'Ask the admin to create users/${user.uid} in Firestore.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            final active = (data['active'] as bool?) ?? true;
            final role = (data['role'] as String?) ?? 'reception';

            // ✅ Active enforcement
            if (!active) {
              return Scaffold(
                appBar: AppBar(title: Text(settings.clinicName)),
                body: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.block, size: 48),
                              const SizedBox(height: 10),
                              const Text(
                                'Account Disabled',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'This account has been disabled by an administrator.\n\n'
                                    'Email: ${user.email ?? ''}',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 14),
                              FilledButton.icon(
                                icon: const Icon(Icons.logout),
                                label: const Text('Logout'),
                                onPressed: () async => auth.signOut(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return DashboardPage(role: role, settings: settings);
          },
        );
      },
    );
  }
}
