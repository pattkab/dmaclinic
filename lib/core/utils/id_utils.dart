class IdUtils {
  static String formatPatientId(int n) {
    final padded = n.toString().padLeft(6, '0');
    return 'DMA-$padded';
  }

  static String visitDocId(String patientId, String dateKey) => '${patientId}_$dateKey';
}
