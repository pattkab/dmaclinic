import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/date_utils.dart';
import '../core/utils/id_utils.dart';
import '../models/patient.dart';

class PatientService {
  final _db = FirebaseFirestore.instance;

  Future<String> _nextPatientId() async {
    final ref = _db.collection('counters').doc('patient');

    final newId = await _db.runTransaction<int>((tx) async {
      final snap = await tx.get(ref);
      final current = (snap.data()?['next'] as int?) ?? 1;
      tx.set(ref, {'next': current + 1}, SetOptions(merge: true));
      return current;
    });

    return IdUtils.formatPatientId(newId);
  }

  Future<Patient> createPatient({
    required String fullName,
    required String phone,
  }) async {
    final today = DateUtilsX.todayKey();
    final patientId = await _nextPatientId();

    final patient = Patient(
      patientId: patientId,
      fullName: fullName.trim(),
      phone: phone.trim(),
      firstVisitDate: today,
      createdAt: DateTime.now(),
    );

    await _db.collection('patients').doc(patientId).set(patient.toMap());
    return patient;
  }

  Future<List<Patient>> searchPatients(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    // 1) Try exact patientId
    final byId = await _db.collection('patients').doc(q).get();
    if (byId.exists) {
      return [Patient.fromMap(byId.data()!)];
    }

    // 2) Try phone exact match
    final byPhone = await _db
        .collection('patients')
        .where('phone', isEqualTo: q)
        .limit(10)
        .get();

    if (byPhone.docs.isNotEmpty) {
      return byPhone.docs.map((d) => Patient.fromMap(d.data())).toList();
    }

    // 3) Name prefix search (simple MVP: fullNameLower + range)
    // For this to work, store fullNameLower in patient docs. (We’ll add it later if you want.)
    // For now: fallback to fetching a small list and filtering client-side (OK for MVP small clinics)
    final recent = await _db.collection('patients').orderBy('createdAt', descending: true).limit(200).get();
    final matches = recent.docs
        .map((d) => Patient.fromMap(d.data()))
        .where((p) => p.fullName.toLowerCase().contains(q.toLowerCase()))
        .toList();

    return matches.take(20).toList();
  }
}
