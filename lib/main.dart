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
                appBar: AppBar(title: const Text('DMA Clinic')),
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
                appBar: AppBar(title: const Text('DMA Clinic')),
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
                                onPressed: () async {
                                  await auth.signOut();
                                },
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

            return DashboardPage(role: role);
          },
        );
      },
    );
  }
}
