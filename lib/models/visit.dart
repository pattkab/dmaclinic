class Visit {
  // Core identifiers
  final String visitId;
  final String patientId;
  final String visitDate; // yyyy-MM-dd

  // Fees (UGX)
  final int consultationFee;
  final int labFee;
  final int pharmacyFee;
  final int proceduresFee;
  final int pharmacyFeeOther;
  final int inpatientFee;

  // Status control
  final String status; // "open" | "closed"

  // Audit / lifecycle fields (optional but recommended)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final DateTime? closedAt;
  final String? closedBy;

  final DateTime? reopenedAt;
  final String? reopenedBy;

  final String? updatedBy;

  Visit({
    required this.visitId,
    required this.patientId,
    required this.visitDate,
    required this.consultationFee,
    required this.labFee,
    required this.pharmacyFee,
    required this.proceduresFee,
    required this.pharmacyFeeOther,
    required this.inpatientFee,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.closedAt,
    this.closedBy,
    this.reopenedAt,
    this.reopenedBy,
    this.updatedBy,
  });

  /// Computed total (UGX)
  int get total =>
      consultationFee + labFee + pharmacyFee + proceduresFee + pharmacyFeeOther + inpatientFee;

  /// Whether visit is locked
  bool get isClosed => status == 'closed';

  /// Convert to Firestore map
  Map<String, dynamic> toMap() => {
    'visitId': visitId,
    'patientId': patientId,
    'visitDate': visitDate,
    'consultationFee': consultationFee,
    'labFee': labFee,
    'pharmacyFee': pharmacyFee,
    'proceduresFee': proceduresFee,
    'pharmacyFeeOther': pharmacyFeeOther,
    'inpatientFee': inpatientFee,
    'status': status,

    // audit fields (nullable)
    if (createdAt != null) 'createdAt': createdAt,
    if (updatedAt != null) 'updatedAt': updatedAt,
    if (closedAt != null) 'closedAt': closedAt,
    if (closedBy != null) 'closedBy': closedBy,
    if (reopenedAt != null) 'reopenedAt': reopenedAt,
    if (reopenedBy != null) 'reopenedBy': reopenedBy,
    if (updatedBy != null) 'updatedBy': updatedBy,
  };

  /// Create Visit from Firestore map (safe for older docs)
  static Visit fromMap(Map<String, dynamic> m) {
    DateTime? _dt(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      return v.toDate(); // Firestore Timestamp
    }

    return Visit(
      visitId: m['visitId'] as String,
      patientId: m['patientId'] as String,
      visitDate: m['visitDate'] as String,

      consultationFee: (m['consultationFee'] ?? 0) as int,
      labFee: (m['labFee'] ?? 0) as int,
      pharmacyFee: (m['pharmacyFee'] ?? 0) as int,
      proceduresFee: (m['proceduresFee'] ?? 0) as int,
      pharmacyFeeOther: (m['pharmacyFeeOther'] ?? 0) as int,
      inpatientFee: (m['inpatientFee'] ?? 0) as int,

      status: (m['status'] ?? 'open') as String,

      createdAt: _dt(m['createdAt']),
      updatedAt: _dt(m['updatedAt']),
      closedAt: _dt(m['closedAt']),
      closedBy: m['closedBy'] as String?,
      reopenedAt: _dt(m['reopenedAt']),
      reopenedBy: m['reopenedBy'] as String?,
      updatedBy: m['updatedBy'] as String?,
    );
  }

  /// Copy helper (useful later for local edits)
  Visit copyWith({
    int? consultationFee,
    int? labFee,
    int? pharmacyFee,
    int? proceduresFee,
    int? pharmacyFeeOther,
    int? inpatientFee,
    String? status,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return Visit(
      visitId: visitId,
      patientId: patientId,
      visitDate: visitDate,
      consultationFee: consultationFee ?? this.consultationFee,
      labFee: labFee ?? this.labFee,
      pharmacyFee: pharmacyFee ?? this.pharmacyFee,
      proceduresFee: proceduresFee ?? this.proceduresFee,
      pharmacyFeeOther: pharmacyFeeOther ?? this.pharmacyFeeOther,
      inpatientFee: inpatientFee ?? this.inpatientFee,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      closedAt: closedAt,
      closedBy: closedBy,
      reopenedAt: reopenedAt,
      reopenedBy: reopenedBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
