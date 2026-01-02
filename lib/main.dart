// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'ui/login_page.dart';
import 'ui/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const DmaClinicApp());
}

class DmaClinicApp extends StatelessWidget {
  const DmaClinicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DMA Clinic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

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

        if (user == null) return const LoginPage();

        // Stream the user role doc so it never "hangs" like a Future can,
        // and show meaningful errors if rules block it.
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (roleSnap.hasError) {
              return Scaffold(
                appBar: AppBar(title: const Text('DMA Clinic')),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Failed to load your role from Firestore.\n\n'
                          'Error:\n${roleSnap.error}\n\n'
                          'Check Firestore rules and that users/{uid} exists.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            final data = roleSnap.data?.data();
            final role = (data?['role'] as String?) ?? 'reception';

            return DashboardPage(role: role);
          },
        );
      },
    );
  }
}
