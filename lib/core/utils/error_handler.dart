import 'dart:async';

/// Indonesian error messages for user-facing errors.
class AppErrorMessages {
  static const String databaseFailure = 'Gagal menyimpan data. Coba lagi.';
  static const String networkError =
      'Terjadi kesalahan. Silakan coba lagi.';
  static const String vehicleNotFound = 'Kendaraan tidak ditemukan';
  static const String invalidInput = 'Input tidak valid';
}

/// Exception thrown when a database operation fails after all retries.
class DatabaseOperationException implements Exception {
  final String message;
  final Object? originalError;

  DatabaseOperationException(this.message, [this.originalError]);

  @override
  String toString() => message;
}

/// Wraps database operations with retry logic (3 retries with exponential backoff).
///
/// Usage:
/// ```dart
/// final result = await SafeDatabaseOperation<Vehicle>(
///   operation: () => db.query('vehicles'),
/// ).execute();
/// ```
class SafeDatabaseOperation<T> {
  final Future<T> Function() operation;
  final int maxRetries;
  final Duration initialDelay;

  SafeDatabaseOperation({
    required this.operation,
    this.maxRetries = 3,
    this.initialDelay = const Duration(milliseconds: 200),
  });

  /// Executes the operation with retry logic.
  ///
  /// Retries up to [maxRetries] times with exponential backoff starting at
  /// [initialDelay]. Throws [DatabaseOperationException] if all retries fail.
  Future<T> execute() async {
    Object? lastError;
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        lastError = e;
        if (attempt < maxRetries) {
          final delay = initialDelay * (1 << attempt); // exponential backoff
          await Future.delayed(delay);
        }
      }
    }
    throw DatabaseOperationException(
      AppErrorMessages.databaseFailure,
      lastError,
    );
  }
}

/// Helper to get a user-friendly error message from an exception.
String getUserFriendlyError(Object error) {
  if (error is DatabaseOperationException) {
    return AppErrorMessages.databaseFailure;
  }
  final msg = error.toString().toLowerCase();
  if (msg.contains('kendaraan tidak ditemukan') ||
      msg.contains('vehicle not found')) {
    return AppErrorMessages.vehicleNotFound;
  }
  if (msg.contains('input tidak valid') ||
      msg.contains('invalid') ||
      msg.contains('argument')) {
    return AppErrorMessages.invalidInput;
  }
  return AppErrorMessages.networkError;
}
