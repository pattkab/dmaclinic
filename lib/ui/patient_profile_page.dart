import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/auth_service.dart';
import '../services/visit_service.dart';
import 'visit_today_page.dart';

class PatientProfilePage extends StatefulWidget {
  final Patient patient;
  final String role;

  const PatientProfilePage({super.key, required this.patient, required this.role});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  final _auth = AuthService();
  final _visits = VisitService();
  bool _loading = false;
  String? _error;

  Future<void> _openTodayVisit() async {
    final user = _auth.user;
    if (user == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final visit = await _visits.openOrCreateTodayVisit(
        patientId: widget.patient.patientId,
        updatedByUid: user.uid,
      );

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VisitTodayPage(
            patient: widget.patient,
            role: widget.role,
            visitId: visit.visitId,
          ),
        ),
      );
    } catch (e) {
      setState(() => _error = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;

    return Scaffold(
      appBar: AppBar(title: Text(p.fullName)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              title: Text(p.fullName),
              subtitle: Text('ID: ${p.patientId}\nPhone: ${p.phone}\nFirst visit: ${p.firstVisitDate}'),
            ),
          ),
          const SizedBox(height: 10),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.today),
              label: const Text('Open / Start Today Visit'),
              onPressed: _loading ? null : _openTodayVisit,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Tip: Fees can be updated at different times today. Each staff updates their section.\n'
                    'This is stored as one visit per patient per day.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
