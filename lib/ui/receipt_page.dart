import 'package:flutter/material.dart';

import '../models/patient.dart';
import '../models/visit.dart';

class ReceiptPage extends StatelessWidget {
  final Patient patient;
  final Visit visit;

  const ReceiptPage({
    super.key,
    required this.patient,
    required this.visit,
  });

  String _fmt(int v) {
    final s = v.toString();
    if (s.length <= 3) return s;
    final out = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      out.write(s[i]);
      count++;
      if (count == 3 && i != 0) {
        out.write(',');
        count = 0;
      }
    }
    return out.toString().split('').reversed.join();
  }

  Widget _lineItem({
    required BuildContext context,
    required String label,
    required int amount,
    IconData? icon,
    bool showIfZero = true,
  }) {
    if (!showIfZero && amount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'UGX ${_fmt(amount)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = visit.total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DMA CLINIC',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.receipt_long, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Visit ID: ${visit.visitId}',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Date: ${visit.visitDate}',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: visit.status == 'closed' ? Colors.grey.shade300 : Colors.green.shade100,
                        ),
                        child: Text(
                          visit.status.toUpperCase(),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 22),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          patient.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.badge, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Patient ID: ${patient.patientId}',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          _sectionTitle('Charges'),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _lineItem(
                    context: context,
                    label: 'Consultation',
                    amount: visit.consultationFee,
                    icon: Icons.medical_services,
                    showIfZero: true,
                  ),
                  _lineItem(
                    context: context,
                    label: 'Laboratory',
                    amount: visit.labFee,
                    icon: Icons.science,
                    showIfZero: true,
                  ),
                  _lineItem(
                    context: context,
                    label: 'Pharmacy',
                    amount: visit.pharmacyFee,
                    icon: Icons.local_pharmacy,
                    showIfZero: true,
                  ),

                  // ✅ NEW
                  _lineItem(
                    context: context,
                    label: 'Pharmacy (Other)',
                    amount: visit.pharmacyFeeOther,
                    icon: Icons.local_pharmacy_outlined,
                    showIfZero: true,
                  ),

                  // ✅ NEW
                  _lineItem(
                    context: context,
                    label: 'Inpatient',
                    amount: visit.inpatientFee,
                    icon: Icons.hotel,
                    showIfZero: true,
                  ),

                  _lineItem(
                    context: context,
                    label: 'Procedures',
                    amount: visit.proceduresFee,
                    icon: Icons.healing,
                    showIfZero: true,
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'TOTAL',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(
                        'UGX ${_fmt(total)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Thank you'),
              subtitle: Text(
                'Please keep this receipt for your records.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
