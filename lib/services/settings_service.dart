import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../models/clinic_settings.dart';

class SettingsService {
  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _ref() {
    final parts = AppConstants.settingsDocPath.split('/');
    return _db.collection(parts[0]).doc(parts[1]);
  }

  Stream<ClinicSettings> streamSettings() {
    return _ref().snapshots().map((snap) => ClinicSettings.fromMap(snap.data()));
  }

  Future<ClinicSettings> getSettingsOnce() async {
    final snap = await _ref().get();
    return ClinicSettings.fromMap(snap.data());
  }

  Future<void> saveSettings(ClinicSettings settings) async {
    await _ref().set(
      {
        ...settings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
