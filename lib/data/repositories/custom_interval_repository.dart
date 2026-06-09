import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/models.dart';
import '../database/database_helper.dart';

class CustomIntervalRepository {
  final DatabaseHelper _dbHelper;
  final Uuid _uuid = const Uuid();

  CustomIntervalRepository(this._dbHelper);

  /// Returns the custom interval for a specific vehicle and maintenance type,
  /// or null if no custom interval is set.
  Future<CustomInterval?> getCustomInterval(
      String vehicleId, MaintenanceType type) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'custom_intervals',
      where: 'vehicleId = ? AND type = ?',
      whereArgs: [vehicleId, type.index],
    );
    if (results.isEmpty) return null;
    return CustomInterval.fromMap(results.first);
  }

  /// Returns all custom intervals for a vehicle.
  Future<List<CustomInterval>> getCustomIntervals(String vehicleId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'custom_intervals',
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
    );
    return results.map((map) => CustomInterval.fromMap(map)).toList();
  }

  /// Saves (upserts) a custom interval. If no id is provided, generates one.
  Future<void> saveCustomInterval(CustomInterval interval) async {
    final db = await _dbHelper.database;
    final effectiveInterval = interval.id.isEmpty
        ? interval.copyWith(id: _uuid.v4())
        : interval;

    await db.insert(
      'custom_intervals',
      effectiveInterval.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Deletes a custom interval, reverting to the default for that type.
  Future<void> deleteCustomInterval(
      String vehicleId, MaintenanceType type) async {
    final db = await _dbHelper.database;
    await db.delete(
      'custom_intervals',
      where: 'vehicleId = ? AND type = ?',
      whereArgs: [vehicleId, type.index],
    );
  }

  /// Checks if a custom interval exists for the given vehicle and type.
  Future<bool> hasCustomInterval(
      String vehicleId, MaintenanceType type) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'custom_intervals',
      where: 'vehicleId = ? AND type = ?',
      whereArgs: [vehicleId, type.index],
    );
    return results.isNotEmpty;
  }
}
