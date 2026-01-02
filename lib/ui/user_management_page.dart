import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserManagementPage extends StatefulWidget {
  final String currentRole;
  const UserManagementPage({super.key, required this.currentRole});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final _db = FirebaseFirestore.instance;

  bool get _canManage => widget.currentRole == 'ceo' || widget.currentRole == 'admin';

  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send reset email: $e')),
      );
    }
  }

  Future<void> _addOrLinkUserDialog() async {
    final uidC = TextEditingController();
    final emailC = TextEditingController();
    final nameC = TextEditingController();
    String role = 'reception';
    bool active = true;

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add / Link user (by UID)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Step 1: Create the user in Firebase Auth (Console) with Email/Password.\n'
                    'Step 2: Copy the user UID and paste here.\n'
                    'Step 3: Save to create/update users/{uid} profile (role, name, active).',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: uidC,
                decoration: const InputDecoration(
                  labelText: 'User UID (required)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailC,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameC,
                decoration: const InputDecoration(
                  labelText: 'Display name (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'ceo', child: Text('CEO')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'reception', child: Text('Reception')),
                  DropdownMenuItem(value: 'lab', child: Text('Lab')),
                  DropdownMenuItem(value: 'pharmacy', child: Text('Pharmacy')),
                  DropdownMenuItem(value: 'procedure', child: Text('Procedure')),
                ],
                onChanged: (v) => role = v ?? role,
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                value: active,
                onChanged: (v) => active = v,
                title: const Text('Active'),
                subtitle: const Text('Disable to block access'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final uid = uidC.text.trim();
              final email = emailC.text.trim().toLowerCase();
              final name = nameC.text.trim();

              if (uid.isEmpty) return;

              try {
                await _db.collection('users').doc(uid).set({
                  'uid': uid,
                  'email': email,
                  'displayName': name,
                  'role': role,
                  'active': active,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                if (!mounted) return;
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User saved in Firestore.')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _editUserDialog(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data() ?? {};
    final uid = doc.id;

    final emailC = TextEditingController(text: (data['email'] ?? '').toString());
    final nameC = TextEditingController(text: (data['displayName'] ?? '').toString());
    String role = (data['role'] as String?) ?? 'reception';
    bool active = (data['active'] as bool?) ?? true;

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit user'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text('UID: $uid', style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailC,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameC,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'ceo', child: Text('CEO')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'reception', child: Text('Reception')),
                  DropdownMenuItem(value: 'lab', child: Text('Lab')),
                  DropdownMenuItem(value: 'pharmacy', child: Text('Pharmacy')),
                  DropdownMenuItem(value: 'procedure', child: Text('Procedure')),
                ],
                onChanged: (v) => role = v ?? role,
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                value: active,
                onChanged: (v) => active = v,
                title: const Text('Active'),
                subtitle: const Text('Disable to block access'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final email = emailC.text.trim().toLowerCase();
              final name = nameC.text.trim();

              try {
                await _db.collection('users').doc(uid).set({
                  'uid': uid,
                  'email': email,
                  'displayName': name,
                  'role': role,
                  'active': active,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                if (!mounted) return;
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User updated.')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_canManage) {
      return Scaffold(
        appBar: AppBar(title: const Text('User Management')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('You do not have permission to manage users.'),
          ),
        ),
      );
    }

    final query = _db.collection('users').orderBy('email');

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            tooltip: 'Add / Link user',
            icon: const Icon(Icons.person_add),
            onPressed: _addOrLinkUserDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                labelText: 'Search (email or name)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;

                final term = _search.text.trim().toLowerCase();
                final filtered = term.isEmpty
                    ? docs
                    : docs.where((d) {
                  final m = d.data();
                  final email = (m['email'] ?? '').toString().toLowerCase();
                  final name = (m['displayName'] ?? '').toString().toLowerCase();
                  return email.contains(term) || name.contains(term);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final doc = filtered[i];
                    final m = doc.data();

                    final email = (m['email'] ?? '').toString();
                    final name = (m['displayName'] ?? '').toString();
                    final role = (m['role'] ?? '').toString();
                    final active = (m['active'] as bool?) ?? true;

                    return Card(
                      child: ListTile(
                        leading: Icon(active ? Icons.verified_user : Icons.block),
                        title: Text(name.isEmpty ? (email.isEmpty ? doc.id : email) : name),
                        subtitle: Text(
                          'Email: ${email.isEmpty ? '(not set)' : email}\n'
                              'Role: ${role.isEmpty ? '(not set)' : role}\n'
                              'UID: ${doc.id}',
                        ),
                        isThreeLine: true,
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              tooltip: 'Send password reset',
                              icon: const Icon(Icons.lock_reset),
                              onPressed: email.isEmpty ? null : () => _sendResetEmail(email),
                            ),
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editUserDialog(doc),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
