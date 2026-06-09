import '../../data/database/database_helper.dart';

/// Utility class for verifying and repairing data integrity in the database.
class DataIntegrity {
  final DatabaseHelper _dbHelper;

  DataIntegrity(this._dbHelper);

  /// Verifies that vehicle.totalMileageKm equals the sum of all mileage records.
  ///
  /// Returns `true` if the total matches, `false` otherwise.
  Future<bool> verifyMileageTotal(String vehicleId) async {
    final db = await _dbHelper.database;

    final vehicleResult = await db.query(
      'vehicles',
      columns: ['totalMileageKm'],
      where: 'id = ?',
      whereArgs: [vehicleId],
    );
    if (vehicleResult.isEmpty) return false;

    final storedTotal =
        (vehicleResult.first['totalMileageKm'] as num).toDouble();

    final sumResult = await db.rawQuery(
      'SELECT COALESCE(SUM(km), 0) as total FROM mileage_records WHERE vehicleId = ?',
      [vehicleId],
    );
    final calculatedTotal = (sumResult.first['total'] as num).toDouble();

    return (storedTotal - calculatedTotal).abs() < 0.001;
  }

  /// Checks for orphaned records whose vehicleId doesn't match any existing vehicle.
  ///
  /// Returns a map with keys 'mileage_records' and 'maintenance_records',
  /// each containing a list of orphaned record IDs.
  Future<Map<String, List<String>>> checkOrphanedRecords() async {
    final db = await _dbHelper.database;

    final orphanedMileage = await db.rawQuery('''
      SELECT mr.id FROM mileage_records mr
      LEFT JOIN vehicles v ON mr.vehicleId = v.id
      WHERE v.id IS NULL
    ''');

    final orphanedMaintenance = await db.rawQuery('''
      SELECT mr.id FROM maintenance_records mr
      LEFT JOIN vehicles v ON mr.vehicleId = v.id
      WHERE v.id IS NULL
    ''');

    return {
      'mileage_records':
          orphanedMileage.map((r) => r['id'] as String).toList(),
      'maintenance_records':
          orphanedMaintenance.map((r) => r['id'] as String).toList(),
    };
  }

  /// Recalculates and updates the vehicle's totalMileageKm from actual mileage records.
  ///
  /// Returns the corrected total, or `null` if the vehicle doesn't exist.
  Future<double?> repairMileageTotal(String vehicleId) async {
    final db = await _dbHelper.database;

    final vehicleResult = await db.query(
      'vehicles',
      where: 'id = ?',
      whereArgs: [vehicleId],
    );
    if (vehicleResult.isEmpty) return null;

    final sumResult = await db.rawQuery(
      'SELECT COALESCE(SUM(km), 0) as total FROM mileage_records WHERE vehicleId = ?',
      [vehicleId],
    );
    final correctTotal = (sumResult.first['total'] as num).toDouble();

    await db.update(
      'vehicles',
      {'totalMileageKm': correctTotal},
      where: 'id = ?',
      whereArgs: [vehicleId],
    );

    return correctTotal;
  }
}
