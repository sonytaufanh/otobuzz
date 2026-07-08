/// Jenis transmisi kendaraan.
///
/// Menentukan jenis-jenis perawatan yang berlaku:
/// - [manual]: motor manual / mobil manual
/// - [matic]: motor matic / mobil otomatis (CVT/torque converter)
/// - [semiAuto]: motor semi-otomatis (copling semi)
enum TransmissionType {
  manual,
  matic,
  semiAuto,
}

extension TransmissionTypeExtension on TransmissionType {
  String get displayName {
    switch (this) {
      case TransmissionType.manual:
        return 'Manual';
      case TransmissionType.matic:
        return 'Matic';
      case TransmissionType.semiAuto:
        return 'Semi-Otomatis';
    }
  }

  String get shortName {
    switch (this) {
      case TransmissionType.manual:
        return 'Manual';
      case TransmissionType.matic:
        return 'Matic';
      case TransmissionType.semiAuto:
        return 'Semi';
    }
  }

  /// Apakah transmisi ini menggunakan sistem CVT (roller, v-belt, dll).
  bool get hasCvt => this == TransmissionType.matic;

  /// Apakah transmisi ini punya kampas kopling manual.
  bool get hasClutch =>
      this == TransmissionType.manual || this == TransmissionType.semiAuto;
}
