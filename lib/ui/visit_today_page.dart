import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/patient.dart';
import '../models/visit.dart';
import '../services/auth_service.dart';
import '../services/visit_service.dart';
import 'receipt_page.dart';
import 'audit_trail_page.dart';

class VisitTodayPage extends StatefulWidget {
  final Patient patient;
  final String role;
  final String visitId;

  const VisitTodayPage({
    super.key,
    required this.patient,
    required this.role,
    required this.visitId,
  });

  @override
  State<VisitTodayPage> createState() => _VisitTodayPageState();
}

class _VisitTodayPageState extends State<VisitTodayPage> {
  final _db = FirebaseFirestore.instance;
  final _auth = AuthService();
  final _visits = VisitService();

  bool isAdminOrReception() => widget.role == 'admin' || widget.role == 'reception';

  bool canEditConsultation() => widget.role == 'admin' || widget.role == 'reception';
  bool canEditLab() => widget.role == 'admin' || widget.role == 'lab';
  bool canEditPharmacy() => widget.role == 'admin' || widget.role == 'pharmacy';
  bool canEditProcedures() => widget.role == 'admin' || widget.role == 'procedure';

  Future<int?> _askAmount(String title, int current) async {
    final c = TextEditingController(text: current.toString());
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount (UGX)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(c.text.trim());
              Navigator.pop(context, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirm(String title, String message) async {
    return (await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    )) ??
        false;
  }

  Widget _feeTile({
    required String title,
    required int amount,
    required bool enabled,
    required bool locked,
    required IconData icon,
    required Future<void> Function(int newValue) onSave,
  }) {
    final tileEnabled = enabled && !locked;

    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text('UGX $amount'),
        trailing: locked
            ? const Icon(Icons.lock, color: Colors.grey)
            : (tileEnabled ? const Icon(Icons.edit) : const Icon(Icons.lock)),
        onTap: !tileEnabled
            ? null
            : () async {
          final newVal = await _askAmount('Update $title', amount);
          if (newVal == null) return;
          if (newVal < 0) return;
          await onSave(newVal);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ref = _db.collection('visits').doc(widget.visitId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snap.data!.exists) {
          return const Scaffold(body: Center(child: Text('Visit not found')));
        }

        final data = snap.data!.data()!;
        final visit = Visit.fromMap(data);

        final total = visit.total;
        final isClosed = visit.status == 'closed';

        final user = _auth.user;
        final uid = user?.uid;
        final email = user?.email ?? '';

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today Visit • ${widget.patient.patientId}'),
                const SizedBox(height: 2),
                Text(
                  widget.patient.fullName,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Receipt',
                icon: const Icon(Icons.receipt_long),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReceiptPage(patient: widget.patient, visit: visit),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Audit trail',
                icon: const Icon(Icons.history),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AuditTrailPage(visitId: visit.visitId),
                    ),
                  );
                },
              ),
              if (isClosed)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.grey.shade300,
                      ),
                      child: const Text(
                        'CLOSED',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('TOTAL', style: TextStyle(fontSize: 10)),
                    Text(
                      'UGX $total',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(widget.patient.fullName),
                  subtitle: Text('Visit date: ${visit.visitDate}\nRole: ${widget.role}'),
                ),
              ),
              const SizedBox(height: 10),

              if (isAdminOrReception())
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            icon: Icon(isClosed ? Icons.lock_open : Icons.lock),
                            label: Text(isClosed ? 'Reopen Visit' : 'Close Visit'),
                            onPressed: () async {
                              if (uid == null) return;

                              if (!isClosed) {
                                final ok = await _confirm(
                                  'Close this visit?',
                                  'Once closed, fees cannot be edited unless you reopen.',
                                );
                                if (!ok) return;

                                await _visits.closeVisit(
                                  visitId: visit.visitId,
                                  updatedByUid: uid,
                                  updatedByEmail: email,
                                  updatedByRole: widget.role,
                                );
                              } else {
                                final ok = await _confirm(
                                  'Reopen this visit?',
                                  'This will allow editing fees again.',
                                );
                                if (!ok) return;

                                await _visits.reopenVisit(
                                  visitId: visit.visitId,
                                  updatedByUid: uid,
                                  updatedByEmail: email,
                                  updatedByRole: widget.role,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (isClosed)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'This visit is CLOSED. Fees are locked to prevent changes after end-of-day.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),

              const SizedBox(height: 10),

              _feeTile(
                title: 'Consultation Fee',
                amount: visit.consultationFee,
                enabled: canEditConsultation(),
                locked: isClosed,
                icon: Icons.medical_services,
                onSave: (v) async {
                  if (uid == null) return;
                  await _visits.updateFees(
                    visitId: visit.visitId,
                    consultationFee: v,
                    updatedByUid: uid,
                    updatedByEmail: email,
                    updatedByRole: widget.role,
                  );
                },
              ),
              _feeTile(
                title: 'Lab Fee',
                amount: visit.labFee,
                enabled: canEditLab(),
                locked: isClosed,
                icon: Icons.science,
                onSave: (v) async {
                  if (uid == null) return;
                  await _visits.updateFees(
                    visitId: visit.visitId,
                    labFee: v,
                    updatedByUid: uid,
                    updatedByEmail: email,
                    updatedByRole: widget.role,
                  );
                },
              ),
              _feeTile(
                title: 'Pharmacy Fee',
                amount: visit.pharmacyFee,
                enabled: canEditPharmacy(),
                locked: isClosed,
                icon: Icons.local_pharmacy,
                onSave: (v) async {
                  if (uid == null) return;
                  await _visits.updateFees(
                    visitId: visit.visitId,
                    pharmacyFee: v,
                    updatedByUid: uid,
                    updatedByEmail: email,
                    updatedByRole: widget.role,
                  );
                },
              ),
              _feeTile(
                title: 'Procedures Fee',
                amount: visit.proceduresFee,
                enabled: canEditProcedures(),
                locked: isClosed,
                icon: Icons.healing,
                onSave: (v) async {
                  if (uid == null) return;
                  await _visits.updateFees(
                    visitId: visit.visitId,
                    proceduresFee: v,
                    updatedByUid: uid,
                    updatedByEmail: email,
                    updatedByRole: widget.role,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
