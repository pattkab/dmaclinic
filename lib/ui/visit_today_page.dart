import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/patient.dart';
import '../models/visit.dart';
import '../services/auth_service.dart';
import '../services/visit_service.dart';
import 'audit_trail_page.dart';
import 'receipt_page.dart';

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

class _ThousandsFormatter extends TextInputFormatter {
  String _formatWithCommas(String digits) {
    if (digits.isEmpty) return '';
    final chars = digits.split('');
    final b = StringBuffer();
    int count = 0;
    for (int i = chars.length - 1; i >= 0; i--) {
      b.write(chars[i]);
      count++;
      if (count == 3 && i != 0) {
        b.write(',');
        count = 0;
      }
    }
    return b.toString().split('').reversed.join();
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Keep only digits
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final formatted = _formatWithCommas(digits);

    // Put cursor at end (simple + stable for finance entry)
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _FeeFieldState {
  final TextEditingController controller;
  final FocusNode focusNode;
  int lastSaved;
  bool dirty;

  _FeeFieldState({
    required this.controller,
    required this.focusNode,
    required this.lastSaved,
    this.dirty = false,
  });
}

class _VisitTodayPageState extends State<VisitTodayPage> {
  final _db = FirebaseFirestore.instance;
  final _auth = AuthService();
  final _visits = VisitService();

  final _thousands = _ThousandsFormatter();

  /// Only admin/reception can close/reopen visits (fees can still be edited by any signed-in role while open).
  bool isAdminOrReception() => widget.role == 'admin' || widget.role == 'reception';

  final Map<String, _FeeFieldState> _feeFields = {};

  String _formatInt(int v) {
    final s = v.toString();
    if (s.length <= 3) return s;
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final left = s.length - i;
      b.write(s[i]);
      if (left > 1 && left % 3 == 1) b.write(',');
    }
    // The above inserts commas one char too early for some lengths; use a safer approach:
    // We'll just reuse the formatter's logic.
    return _thousands.formatEditUpdate(
      const TextEditingValue(text: ''),
      TextEditingValue(text: s),
    ).text;
  }

  int _parseAmount(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    return int.tryParse(digits) ?? -1;
  }

  _FeeFieldState _ensureFeeField(String key, int savedValue) {
    final existing = _feeFields[key];
    final savedText = _formatInt(savedValue);

    if (existing == null) {
      final c = TextEditingController(text: savedText);
      final f = FocusNode();

      final st = _FeeFieldState(controller: c, focusNode: f, lastSaved: savedValue);

      // UX: when user taps into a field that is "0", clear it so they can type immediately.
      f.addListener(() {
        if (!mounted) return;

        if (f.hasFocus) {
          // If currently showing 0 (or empty), clear on focus
          final v = _parseAmount(st.controller.text);
          if (v == 0) {
            st.controller.clear();
          } else {
            // Select all on focus for fast overwrite
            st.controller.selection = TextSelection(baseOffset: 0, extentOffset: st.controller.text.length);
          }
        } else {
          // On blur: if empty, restore 0 (formatted)
          if (st.controller.text.trim().isEmpty) {
            st.controller.text = _formatInt(0);
            st.dirty = true; // still considered edited until saved/reset
            setState(() {});
          }
        }
      });

      _feeFields[key] = st;
      return st;
    }

    // Sync external updates only if user is NOT currently editing the field.
    if (!existing.dirty && existing.lastSaved != savedValue) {
      existing.lastSaved = savedValue;
      existing.controller.text = savedText;
    }

    return existing;
  }

  @override
  void dispose() {
    for (final f in _feeFields.values) {
      f.controller.dispose();
      f.focusNode.dispose();
    }
    super.dispose();
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

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _feeEntryCard({
    required String fieldKey,
    required String title,
    required IconData icon,
    required int savedAmount,
    required bool locked,
    required Future<void> Function(int value) onSave,
  }) {
    final f = _ensureFeeField(fieldKey, savedAmount);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (locked) const Icon(Icons.lock, color: Colors.grey, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: f.controller,
              focusNode: f.focusNode,
              enabled: !locked,
              keyboardType: TextInputType.number,
              inputFormatters: [
                // allow typing digits only, but display as 1,234,567
                _thousands,
              ],
              decoration: InputDecoration(
                labelText: 'UGX',
                isDense: true,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.payments_outlined, size: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              onChanged: (_) {
                if (!f.dirty) setState(() => f.dirty = true);
              },
              onSubmitted: (_) async {
                if (locked) return;
                final v = _parseAmount(f.controller.text);
                if (v < 0) {
                  _snack('Enter a valid number for $title.');
                  return;
                }
                await onSave(v);
                if (!mounted) return;
                setState(() {
                  f.lastSaved = v;
                  f.dirty = false;
                  f.controller.text = _formatInt(v);
                });
                _snack('$title saved.');
              },
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: locked
                        ? null
                        : () {
                      setState(() {
                        f.controller.text = _formatInt(f.lastSaved);
                        f.dirty = false;
                      });
                      _snack('$title reset.');
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: locked
                        ? null
                        : () async {
                      final v = _parseAmount(f.controller.text);
                      if (v < 0) {
                        _snack('Enter a valid number for $title.');
                        return;
                      }
                      await onSave(v);
                      if (!mounted) return;
                      setState(() {
                        f.lastSaved = v;
                        f.dirty = false;
                        f.controller.text = _formatInt(v);
                      });
                      _snack('$title saved.');
                    },
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
                      'UGX ${_formatInt(total)}',
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

              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Text(
                  'Enter fees',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),

              LayoutBuilder(
                builder: (context, c) {
                  final width = c.maxWidth;
                  final crossAxisCount = width >= 900 ? 3 : (width >= 560 ? 2 : 1);

                  final cards = <Widget>[
                    _feeEntryCard(
                      fieldKey: 'consultationFee',
                      title: 'Consultation Fee',
                      icon: Icons.medical_services,
                      savedAmount: visit.consultationFee,
                      locked: isClosed,
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
                    _feeEntryCard(
                      fieldKey: 'labFee',
                      title: 'Lab Fee',
                      icon: Icons.science,
                      savedAmount: visit.labFee,
                      locked: isClosed,
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
                    _feeEntryCard(
                      fieldKey: 'pharmacyFee',
                      title: 'Pharmacy Fee',
                      icon: Icons.local_pharmacy,
                      savedAmount: visit.pharmacyFee,
                      locked: isClosed,
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
                    _feeEntryCard(
                      fieldKey: 'pharmacyFeeOther',
                      title: 'Pharmacy (Other)',
                      icon: Icons.local_pharmacy_outlined,
                      savedAmount: visit.pharmacyFeeOther,
                      locked: isClosed,
                      onSave: (v) async {
                        if (uid == null) return;
                        await _visits.updateFees(
                          visitId: visit.visitId,
                          pharmacyFeeOther: v,
                          updatedByUid: uid,
                          updatedByEmail: email,
                          updatedByRole: widget.role,
                        );
                      },
                    ),
                    _feeEntryCard(
                      fieldKey: 'inpatientFee',
                      title: 'Inpatient',
                      icon: Icons.hotel,
                      savedAmount: visit.inpatientFee,
                      locked: isClosed,
                      onSave: (v) async {
                        if (uid == null) return;
                        await _visits.updateFees(
                          visitId: visit.visitId,
                          inpatientFee: v,
                          updatedByUid: uid,
                          updatedByEmail: email,
                          updatedByRole: widget.role,
                        );
                      },
                    ),
                    _feeEntryCard(
                      fieldKey: 'proceduresFee',
                      title: 'Procedures',
                      icon: Icons.healing,
                      savedAmount: visit.proceduresFee,
                      locked: isClosed,
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
                  ];

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      // Controls the grey card height
                      mainAxisExtent: 168,
                    ),
                    itemCount: cards.length,
                    itemBuilder: (context, index) => cards[index],
                  );
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
