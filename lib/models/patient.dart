class Patient {
  final String patientId;
  final String fullName;
  final String phone;
  final String firstVisitDate; // yyyy-MM-dd
  final DateTime createdAt;

  Patient({
    required this.patientId,
    required this.fullName,
    required this.phone,
    required this.firstVisitDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'patientId': patientId,
    'fullName': fullName,
    'phone': phone,
    'firstVisitDate': firstVisitDate,
    'createdAt': createdAt,
  };

  static Patient fromMap(Map<String, dynamic> m) => Patient(
    patientId: m['patientId'] as String,
    fullName: (m['fullName'] ?? '') as String,
    phone: (m['phone'] ?? '') as String,
    firstVisitDate: (m['firstVisitDate'] ?? '') as String,
    createdAt: (m['createdAt'] as dynamic).toDate(),
  );
}
