import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';

class ExportService {
  final _db = FirebaseFirestore.instance;

  Future<String> exportVisitsCsv({
    required String fromDateKey, // YYYY-MM-DD
    required String toDateKey, // YYYY-MM-DD
  }) async {
    // Query visits by visitDate range (string range works with YYYY-MM-DD)
    final q = await _db
        .collection('visits')
        .where('visitDate', isGreaterThanOrEqualTo: fromDateKey)
        .where('visitDate', isLessThanOrEqualTo: toDateKey)
        .orderBy('visitDate')
        .get();

    final visits = q.docs.map((d) => d.data()).toList();

    // Build CSV header
    final rows = <List<String>>[];
    rows.add([
      'visitId',
      'visitDate',
      'patientId',
      'patientName',
      'patientPhone',
      'consultationFee',
      'labFee',
      'pharmacyFee',
      'proceduresFee',
      'total',
      'status',
      'updatedBy',
    ]);

    // Fetch patient details per visit (simple + reliable for MVP)
    for (final v in visits) {
      final patientId = (v['patientId'] ?? '').toString();
      String patientName = '';
      String patientPhone = '';

      if (patientId.isNotEmpty) {
        try {
          final pSnap = await _db.collection('patients').doc(patientId).get();
          final p = pSnap.data();
          if (p != null) {
            patientName = (p['fullName'] ?? p['name'] ?? '').toString();
            patientPhone = (p['phone'] ?? '').toString();
          }
        } catch (_) {
          // ignore patient fetch errors for export
        }
      }

      final consult = (v['consultationFee'] ?? 0).toString();
      final lab = (v['labFee'] ?? 0).toString();
      final pharm = (v['pharmacyFee'] ?? 0).toString();
      final proc = (v['proceduresFee'] ?? 0).toString();

      int total = 0;
      try {
        total = (int.parse(consult)) + (int.parse(lab)) + (int.parse(pharm)) + (int.parse(proc));
      } catch (_) {}

      rows.add([
        (v['visitId'] ?? '').toString(),
        (v['visitDate'] ?? '').toString(),
        patientId,
        patientName,
        patientPhone,
        consult,
        lab,
        pharm,
        proc,
        total.toString(),
        (v['status'] ?? '').toString(),
        (v['updatedBy'] ?? '').toString(),
      ]);
    }

    final csv = _toCsv(rows);

    final dir = await getApplicationDocumentsDirectory();
    final safeFrom = fromDateKey.replaceAll('-', '');
    final safeTo = toDateKey.replaceAll('-', '');
    final fileName = 'DMA_Clinic_Visits_${safeFrom}_to_${safeTo}.csv';

    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsString(csv, flush: true);

    return file.path;
  }

  String _toCsv(List<List<String>> rows) {
    String esc(String s) {
      final needs = s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r');
      final v = s.replaceAll('"', '""');
      return needs ? '"$v"' : v;
    }

    return rows.map((r) => r.map(esc).join(',')).join('\n');
  }
}
