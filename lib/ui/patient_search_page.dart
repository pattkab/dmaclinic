import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/patient_service.dart';
import 'patient_register_page.dart';
import 'patient_profile_page.dart';

class PatientSearchPage extends StatefulWidget {
  final String role;
  const PatientSearchPage({super.key, required this.role});

  @override
  State<PatientSearchPage> createState() => _PatientSearchPageState();
}

class _PatientSearchPageState extends State<PatientSearchPage> {
  final _patients = PatientService();
  final _q = TextEditingController();
  bool _loading = false;
  List<Patient> _results = [];

  @override
  void initState() {
    super.initState();
    _q.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _q.text.trim();
    if (query.isEmpty) return;
    setState(() => _loading = true);
    final res = await _patients.searchPatients(query);
    if (!mounted) return;
    setState(() {
      _results = res;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canRegister = widget.role == 'admin' || widget.role == 'reception';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Search'),
        actions: [
          if (canRegister)
            IconButton(
              tooltip: 'Register new patient',
              icon: const Icon(Icons.person_add),
              onPressed: () async {
                final created = await Navigator.push<Patient?>(
                  context,
                  MaterialPageRoute(builder: (_) => const PatientRegisterPage()),
                );
                if (created != null) {
                  if (!mounted) return;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PatientProfilePage(patient: created, role: widget.role)),
                  );
                }
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _q,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: 'Search by Patient ID / Phone / Name',
                  border: InputBorder.none,
                  icon: const Icon(Icons.search),
                  suffixIcon: _q.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _q.clear();
                            setState(() {
                              _results = [];
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (canRegister)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('Register New Patient'),
                onPressed: () async {
                  final created = await Navigator.push<Patient?>(
                    context,
                    MaterialPageRoute(builder: (_) => const PatientRegisterPage()),
                  );
                  if (created != null) {
                    if (!mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PatientProfilePage(patient: created, role: widget.role)),
                    );
                  }
                },
              ),
            ),
          const SizedBox(height: 10),
          if (_loading) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
          if (!_loading && _results.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('No results yet. Search by ID, phone, or name.'),
            ),
          ..._results.map(
                (p) => Card(
              child: ListTile(
                title: Text(p.fullName),
                subtitle: Text('${p.patientId} • ${p.phone}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PatientProfilePage(patient: p, role: widget.role)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
