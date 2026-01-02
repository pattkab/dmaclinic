import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/date_utils.dart';
import '../core/utils/id_utils.dart';
import '../models/visit.dart';

class VisitService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _auditRef(String visitId) {
    return _db.collection('visits').doc(visitId).collection('audit');
  }

  Future<void> _logAudit({
    required String visitId,
    required String uid,
    required String action,
    Map<String, dynamic>? changes,
    Map<String, dynamic>? meta,
  }) async {
    await _auditRef(visitId).add({
      'ts': FieldValue.serverTimestamp(),
      'uid': uid,
      'action': action,
      if (changes != null) 'changes': changes,
      if (meta != null) 'meta': meta,
    });
  }

  Future<Visit> openOrCreateTodayVisit({
    required String patientId,
    required String updatedByUid,
  }) async {
    final today = DateUtilsX.todayKey();
    final docId = IdUtils.visitDocId(patientId, today);
    final ref = _db.collection('visits').doc(docId);

    final snap = await ref.get();
    if (snap.exists) {
      return Visit.fromMap(snap.data()!);
    }

    final visit = Visit(
      visitId: docId,
      patientId: patientId,
      visitDate: today,
      consultationFee: 0,
      labFee: 0,
      pharmacyFee: 0,
      proceduresFee: 0,
      status: 'open',
    );

    await ref.set({
      ...visit.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedByUid,
    });

    await _logAudit(
      visitId: docId,
      uid: updatedByUid,
      action: 'create_visit',
      meta: {'visitDate': today},
    );

    return visit;
  }

  Future<void> updateFees({
    required String visitId,
    int? consultationFee,
    int? labFee,
    int? pharmacyFee,
    int? proceduresFee,
    required String updatedByUid,
  }) async {
    final ref = _db.collection('visits').doc(visitId);

    // Read current first (so we can store old->new changes)
    final snap = await ref.get();
    if (!snap.exists) return;

    final current = snap.data()!;
    final status = (current['status'] as String?) ?? 'open';
    if (status == 'closed') return;

    final oldConsult = (current['consultationFee'] ?? 0) as int;
    final oldLab = (current['labFee'] ?? 0) as int;
    final oldPharm = (current['pharmacyFee'] ?? 0) as int;
    final oldProc = (current['proceduresFee'] ?? 0) as int;

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedByUid,
    };

    final changes = <String, dynamic>{};

    if (consultationFee != null && consultationFee != oldConsult) {
      updates['consultationFee'] = consultationFee;
      changes['consultationFee'] = {'old': oldConsult, 'new': consultationFee};
    }
    if (labFee != null && labFee != oldLab) {
      updates['labFee'] = labFee;
      changes['labFee'] = {'old': oldLab, 'new': labFee};
    }
    if (pharmacyFee != null && pharmacyFee != oldPharm) {
      updates['pharmacyFee'] = pharmacyFee;
      changes['pharmacyFee'] = {'old': oldPharm, 'new': pharmacyFee};
    }
    if (proceduresFee != null && proceduresFee != oldProc) {
      updates['proceduresFee'] = proceduresFee;
      changes['proceduresFee'] = {'old': oldProc, 'new': proceduresFee};
    }

    // Nothing changed
    if (changes.isEmpty) return;

    // Write visit update then audit log
    await ref.update(updates);

    await _logAudit(
      visitId: visitId,
      uid: updatedByUid,
      action: 'update_fees',
      changes: changes,
    );
  }

  Future<void> closeVisit({
    required String visitId,
    required String updatedByUid,
  }) async {
    final ref = _db.collection('visits').doc(visitId);

    final snap = await ref.get();
    if (!snap.exists) return;

    final status = (snap.data()?['status'] as String?) ?? 'open';
    if (status == 'closed') return;

    await ref.update({
      'status': 'closed',
      'closedAt': FieldValue.serverTimestamp(),
      'closedBy': updatedByUid,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedByUid,
    });

    await _logAudit(
      visitId: visitId,
      uid: updatedByUid,
      action: 'close_visit',
    );
  }

  Future<void> reopenVisit({
    required String visitId,
    required String updatedByUid,
  }) async {
    final ref = _db.collection('visits').doc(visitId);

    final snap = await ref.get();
    if (!snap.exists) return;

    final status = (snap.data()?['status'] as String?) ?? 'open';
    if (status != 'closed') return;

    await ref.update({
      'status': 'open',
      'reopenedAt': FieldValue.serverTimestamp(),
      'reopenedBy': updatedByUid,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedByUid,
    });

    await _logAudit(
      visitId: visitId,
      uid: updatedByUid,
      action: 'reopen_visit',
    );
  }

  Future<int> closeAllOpenVisitsForDate({
    required String dateKey,
    required String updatedByUid,
  }) async {
    final q = await _db
        .collection('visits')
        .where('visitDate', isEqualTo: dateKey)
        .where('status', isEqualTo: 'open')
        .get();

    if (q.docs.isEmpty) return 0;

    final batch = _db.batch();
    for (final d in q.docs) {
      batch.update(d.reference, {
        'status': 'closed',
        'closedAt': FieldValue.serverTimestamp(),
        'closedBy': updatedByUid,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': updatedByUid,
      });
    }
    await batch.commit();

    // Optional: log one “bulk close” entry per visit
    for (final d in q.docs) {
      await _logAudit(
        visitId: d.id,
        uid: updatedByUid,
        action: 'close_visit_bulk',
        meta: {'dateKey': dateKey},
      );
    }

    return q.docs.length;
  }
}
