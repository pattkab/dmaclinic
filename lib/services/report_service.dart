import 'package:cloud_firestore/cloud_firestore.dart';

class DailyReport {
  final int patientsSeen;
  final int newPatients;
  final int oldPatients;

  final int consultationTotal;
  final int labTotal;
  final int pharmacyTotal;
  final int pharmacyOtherTotal;
  final int inpatientTotal;
  final int proceduresTotal;

  final int grandTotal;

  DailyReport({
    required this.patientsSeen,
    required this.newPatients,
    required this.oldPatients,
    required this.consultationTotal,
    required this.labTotal,
    required this.pharmacyTotal,
    required this.pharmacyOtherTotal,
    required this.inpatientTotal,
    required this.proceduresTotal,
    required this.grandTotal,
  });
}

class TrendPoint {
  final String dateKey; // yyyy-MM-dd
  final int consultation;
  final int lab;
  final int pharmacy;
  final int pharmacyOther;
  final int inpatient;
  final int procedures;

  TrendPoint({
    required this.dateKey,
    required this.consultation,
    required this.lab,
    required this.pharmacy,
    required this.pharmacyOther,
    required this.inpatient,
    required this.procedures,
  });

  int get total => consultation + lab + pharmacy + pharmacyOther + inpatient + procedures;
}

class ReportService {
  final _db = FirebaseFirestore.instance;

  Future<DailyReport> getDailyReport(String dateKey) async {
    final visitsSnap = await _db
        .collection('visits')
        .where('visitDate', isEqualTo: dateKey)
        .get();

    int consult = 0, lab = 0, pharm = 0, pharmOther = 0, inpatient = 0, proc = 0;

    for (final d in visitsSnap.docs) {
      final m = d.data();
      consult += (m['consultationFee'] ?? 0) as int;
      lab += (m['labFee'] ?? 0) as int;
      pharm += (m['pharmacyFee'] ?? 0) as int;
      pharmOther += (m['pharmacyFeeOther'] ?? 0) as int;
      inpatient += (m['inpatientFee'] ?? 0) as int;
      proc += (m['proceduresFee'] ?? 0) as int;
    }

    // New vs old patients
    final patientsToday = await _db
        .collection('patients')
        .where('firstVisitDate', isEqualTo: dateKey)
        .get();

    final newPatients = patientsToday.docs.length;
    final patientsSeen = visitsSnap.docs.length;
    final oldPatients = (patientsSeen - newPatients) < 0 ? 0 : (patientsSeen - newPatients);

    final grand = consult + lab + pharm + pharmOther + inpatient + proc;

    return DailyReport(
      patientsSeen: patientsSeen,
      newPatients: newPatients,
      oldPatients: oldPatients,
      consultationTotal: consult,
      labTotal: lab,
      pharmacyTotal: pharm,
      pharmacyOtherTotal: pharmOther,
      inpatientTotal: inpatient,
      proceduresTotal: proc,
      grandTotal: grand,
    );
  }

  /// Trends over a date range (inclusive).
  /// visitDate is stored as "yyyy-MM-dd" string so lexicographic ordering works.
  Future<List<TrendPoint>> getTrends(String startDateKey, String endDateKey) async {
    final snap = await _db
        .collection('visits')
        .where('visitDate', isGreaterThanOrEqualTo: startDateKey)
        .where('visitDate', isLessThanOrEqualTo: endDateKey)
        .get();

    // Aggregate by date
    final Map<String, Map<String, int>> byDate = {};

    for (final d in snap.docs) {
      final m = d.data();
      final date = (m['visitDate'] as String?) ?? '';
      if (date.isEmpty) continue;

      byDate.putIfAbsent(date, () => {
        'consultation': 0,
        'lab': 0,
        'pharmacy': 0,
        'pharmacyOther': 0,
        'inpatient': 0,
        'procedures': 0,
      });

      byDate[date]!['consultation'] =
          (byDate[date]!['consultation'] ?? 0) + ((m['consultationFee'] ?? 0) as int);

      byDate[date]!['lab'] =
          (byDate[date]!['lab'] ?? 0) + ((m['labFee'] ?? 0) as int);

      byDate[date]!['pharmacy'] =
          (byDate[date]!['pharmacy'] ?? 0) + ((m['pharmacyFee'] ?? 0) as int);

      byDate[date]!['pharmacyOther'] =
          (byDate[date]!['pharmacyOther'] ?? 0) + ((m['pharmacyFeeOther'] ?? 0) as int);

      byDate[date]!['inpatient'] =
          (byDate[date]!['inpatient'] ?? 0) + ((m['inpatientFee'] ?? 0) as int);

      byDate[date]!['procedures'] =
          (byDate[date]!['procedures'] ?? 0) + ((m['proceduresFee'] ?? 0) as int);
    }

    final keys = byDate.keys.toList()..sort();
    return keys
        .map(
          (k) => TrendPoint(
        dateKey: k,
        consultation: byDate[k]!['consultation'] ?? 0,
        lab: byDate[k]!['lab'] ?? 0,
        pharmacy: byDate[k]!['pharmacy'] ?? 0,
        pharmacyOther: byDate[k]!['pharmacyOther'] ?? 0,
        inpatient: byDate[k]!['inpatient'] ?? 0,
        procedures: byDate[k]!['procedures'] ?? 0,
      ),
    )
        .toList();
  }
}
