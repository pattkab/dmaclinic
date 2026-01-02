import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AccountPage extends StatefulWidget {
  final String role;
  const AccountPage({super.key, required this.role});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _auth = AuthService();

  final _currentPw = TextEditingController();
  final _newPw = TextEditingController();
  final _confirmPw = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _loading = false;
  String? _msg;
  String? _err;

  @override
  void dispose() {
    _currentPw.dispose();
    _newPw.dispose();
    _confirmPw.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Only email/password users can change password using this flow
    final hasPasswordProvider = user.providerData.any((p) => p.providerId == 'password');
    if (!hasPasswordProvider) {
      setState(() {
        _err = 'This account does not use Email/Password sign-in.';
        _msg = null;
      });
      return;
    }

    final current = _currentPw.text.trim();
    final nw = _newPw.text.trim();
    final confirm = _confirmPw.text.trim();

    if (current.isEmpty || nw.isEmpty || confirm.isEmpty) {
      setState(() {
        _err = 'Fill in all password fields.';
        _msg = null;
      });
      return;
    }

    if (nw.length < 6) {
      setState(() {
        _err = 'New password must be at least 6 characters.';
        _msg = null;
      });
      return;
    }

    if (nw != confirm) {
      setState(() {
        _err = 'New password and confirm password do not match.';
        _msg = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _err = null;
      _msg = null;
    });

    try {
      final email = user.email;
      if (email == null || email.isEmpty) {
        throw Exception('No email found for this user.');
      }

      // Explain: Firebase requires recent login for password change
      final cred = EmailAuthProvider.credential(email: email, password: current);
      await user.reauthenticateWithCredential(cred);

      await user.updatePassword(nw);

      _currentPw.clear();
      _newPw.clear();
      _confirmPw.clear();

      if (!mounted) return;
      setState(() {
        _msg = 'Password updated successfully.';
        _err = null;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _err = _friendlyAuthError(e);
        _msg = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = 'Failed: $e';
        _msg = null;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
        return 'Current password is wrong.';
      case 'weak-password':
        return 'New password is too weak.';
      case 'requires-recent-login':
        return 'Please log in again and retry.';
      case 'user-mismatch':
      case 'user-not-found':
        return 'User not found. Please log in again.';
      case 'invalid-credential':
        return 'Invalid credentials. Check your current password.';
      default:
        return e.message ?? 'Authentication error.';
    }
  }

  Future<void> _sendResetEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;

    if (email == null || email.isEmpty) {
      setState(() {
        _err = 'No email found for this user.';
        _msg = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _err = null;
      _msg = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      setState(() {
        _msg = 'Password reset email sent to $email.';
        _err = null;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _err = _friendlyAuthError(e);
        _msg = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = 'Failed: $e';
        _msg = null;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    final name = user?.displayName ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _loading ? null : () async => _auth.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.account_circle),
                  title: Text(name.isEmpty ? 'Signed in' : name),
                  subtitle: Text('$email\nRole: ${widget.role}'),
                  isThreeLine: true,
                ),
              ),

              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Change Password',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _currentPw,
                        obscureText: _obscureCurrent,
                        decoration: InputDecoration(
                          labelText: 'Current password',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureCurrent ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: _newPw,
                        obscureText: _obscureNew,
                        decoration: InputDecoration(
                          labelText: 'New password',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscureNew = !_obscureNew),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: _confirmPw,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm new password',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (_err != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(_err!, style: const TextStyle(color: Colors.red)),
                        ),
                      if (_msg != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(_msg!, style: const TextStyle(color: Colors.green)),
                        ),

                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              icon: _loading
                                  ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                                  : const Icon(Icons.lock_reset),
                              label: const Text('Update Password'),
                              onPressed: _loading ? null : _changePassword,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.email),
                              label: const Text('Send reset email'),
                              onPressed: _loading ? null : _sendResetEmail,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      Text(
                        'Tip: If you forgot the current password, use “Send reset email”.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
