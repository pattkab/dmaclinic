class ClinicSettings {
  final String clinicName;
  final String logoUrl;

  const ClinicSettings({
    required this.clinicName,
    required this.logoUrl,
  });

  factory ClinicSettings.defaults() => const ClinicSettings(
    clinicName: 'DMA Clinic',
    logoUrl: '',
  );

  factory ClinicSettings.fromMap(Map<String, dynamic>? map) {
    final m = map ?? {};
    return ClinicSettings(
      clinicName: (m['clinicName'] as String?)?.trim().isNotEmpty == true
          ? (m['clinicName'] as String).trim()
          : 'DMA Clinic',
      logoUrl: (m['logoUrl'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'clinicName': clinicName.trim(),
    'logoUrl': logoUrl.trim(),
  };
}
