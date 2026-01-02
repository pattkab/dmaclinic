import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/patient_service.dart';

class PatientRegisterPage extends StatefulWidget {
  const PatientRegisterPage({super.key});

  @override
  State<PatientRegisterPage> createState() => _PatientRegisterPageState();
}

class _PatientRegisterPageState extends State<PatientRegisterPage> {
  final _patients = PatientService();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _age = TextEditingController();
  String? _sex;
  final _address = TextEditingController();
  final _nextOfKin = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _age.dispose();
    _address.dispose();
    _nextOfKin.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final age = _age.text.trim();
    final address = _address.text.trim();
    final nextOfKin = _nextOfKin.text.trim();

    if (name.length < 2) {
      setState(() => _error = 'Enter a valid name.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final p = await _patients.createPatient(
        fullName: name,
        phone: phone,
        age: int.tryParse(age),
        sex: _sex,
        address: address,
        nextOfKin: nextOfKin,
      );
      if (!mounted) return;
      Navigator.pop(context, p);
    } catch (e) {
      setState(() => _error = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register New Patient')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Full name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _age,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _sex,
                          decoration: const InputDecoration(labelText: 'Sex', border: OutlineInputBorder()),
                          items: const ['Male', 'Female']
                              .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                              .toList(),
                          onChanged: (value) => setState(() => _sex = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _address,
                    decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nextOfKin,
                    decoration: const InputDecoration(labelText: 'Next of Kin', border: OutlineInputBorder()),
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
                      onPressed: _loading ? null : _create,
                      child: _loading
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Create Patient'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
