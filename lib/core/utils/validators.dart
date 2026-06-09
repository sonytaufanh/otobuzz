// Reusable validator functions for the OtoBuzz application.

/// Validates an Indonesian vehicle plate number format.
///
/// Valid formats: 1-2 uppercase letters, space, 1-4 digits, space, 1-3 uppercase letters.
/// Examples: "B 1234 XYZ", "AB 12 A", "D 1 ABC"
///
/// Returns `null` if valid, or an error message (in Indonesian) if invalid.
String? validatePlateNumber(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Nomor plat wajib diisi';
  }
  final regex = RegExp(r'^[A-Z]{1,2}\s\d{1,4}\s[A-Z]{1,3}$');
  if (!regex.hasMatch(value.trim().toUpperCase())) {
    return 'Format plat tidak valid (contoh: B 1234 XYZ)';
  }
  return null;
}

/// Checks if a plate number string matches the Indonesian format.
///
/// Returns `true` if the plate number is valid, `false` otherwise.
bool isValidPlateNumber(String plateNumber) {
  final regex = RegExp(r'^[A-Z]{1,2}\s\d{1,4}\s[A-Z]{1,3}$');
  return regex.hasMatch(plateNumber.trim().toUpperCase());
}
