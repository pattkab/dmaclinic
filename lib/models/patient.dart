class Patient {
  final String patientId;
  final String fullName;
  final String phone;
  final int? age;
  final String? sex;
  final String? address;
  final String? nextOfKin;
  final String firstVisitDate; // yyyy-MM-dd
  final DateTime createdAt;

  Patient({
    required this.patientId,
    required this.fullName,
    required this.phone,
    this.age,
    this.sex,
    this.address,
    this.nextOfKin,
    required this.firstVisitDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'patientId': patientId,
    'fullName': fullName,
    'phone': phone,
    'age': age,
    'sex': sex,
    'address': address,
    'nextOfKin': nextOfKin,
    'firstVisitDate': firstVisitDate,
    'createdAt': createdAt,
  };

  static Patient fromMap(Map<String, dynamic> m) => Patient(
    patientId: m['patientId'] as String,
    fullName: (m['fullName'] ?? '') as String,
    phone: (m['phone'] ?? '') as String,
    age: m['age'] as int?,
    sex: m['sex'] as String?,
    address: m['address'] as String?,
    nextOfKin: m['nextOfKin'] as String?,
    firstVisitDate: (m['firstVisitDate'] ?? '') as String,
    createdAt: (m['createdAt'] as dynamic).toDate(),
  );
}
