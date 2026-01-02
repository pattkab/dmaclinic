import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/clinic_settings.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  final ClinicSettings settings;
  const LoginPage({super.key, required this.settings});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _loadLastEmail();
  }

  Future<void> _loadLastEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getString('last_email');
      if (last != null && last.trim().isNotEmpty) {
        _email.text = last.trim();
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _saveLastEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_email', email.trim());
    } catch (_) {}
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter email and password.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _saveLastEmail(email);
      await _auth.signInEmail(email, password);
    } catch (e) {
      setState(() => _error = 'Login failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _brandHeader() {
    final name = widget.settings.clinicName;
    final logo = widget.settings.logoUrl.trim();

    return Column(
      children: [
        if (logo.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              logo,
              height: 84,
              width: 84,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(height: 84, width: 84),
            ),
          )
        else
          Container(
            height: 84,
            width: 84,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Icon(
              Icons.local_hospital,
              size: 46,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Sign in to continue',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final maxWidth = w > 520 ? 520.0 : w;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _brandHeader(),
                    const SizedBox(height: 18),

                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          tooltip: _obscure ? 'Show password' : 'Hide password',
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(_error!, style: const TextStyle(color: Colors.red)),
                      ),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _loading ? null : _login,
                        child: _loading
                            ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Text('Login'),
                      ),
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
}
