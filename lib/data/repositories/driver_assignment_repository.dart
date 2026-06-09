import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/models.dart';
import '../database/database_helper.dart';

class DriverAssignmentRepository {
  final DatabaseHelper _dbHelper;
  final Uuid _uuid = const Uuid();

  DriverAssignmentRepository(this._dbHelper);

  /// Assigns a driver to a vehicle on a given date (upsert by vehicleId+date).
  Future<void> assignDriver(DriverAssignment assignment) async {
    final db = await _dbHelper.database;
    final effectiveAssignment = assignment.id.isEmpty
        ? assignment.copyWith(id: _uuid.v4())
        : assignment;

    await db.insert(
      'driver_assignments',
      effectiveAssignment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Gets the driver assignment for a vehicle on a specific date.
  Future<DriverAssignment?> getAssignment(
      String vehicleId, DateTime date) async {
    final db = await _dbHelper.database;
    final dateStr = _dateToString(date);
    final results = await db.query(
      'driver_assignments',
      where: 'vehicleId = ? AND date = ?',
      whereArgs: [vehicleId, dateStr],
    );
    if (results.isEmpty) return null;
    return DriverAssignment.fromMap(results.first);
  }

  /// Gets assignment history for a vehicle, optionally filtered by date range.
  Future<List<DriverAssignment>> getAssignmentHistory(
    String vehicleId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await _dbHelper.database;
    String where = 'vehicleId = ?';
    List<dynamic> whereArgs = [vehicleId];

    if (from != null) {
      where += ' AND date >= ?';
      whereArgs.add(_dateToString(from));
    }
    if (to != null) {
      where += ' AND date <= ?';
      whereArgs.add(_dateToString(to));
    }

    final results = await db.query(
      'driver_assignments',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
    return results.map((map) => DriverAssignment.fromMap(map)).toList();
  }

  /// Gets all assignments for a specific driver, optionally filtered by date range.
  Future<List<DriverAssignment>> getDriverAssignments(
    String driverId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await _dbHelper.database;
    String where = 'driverId = ?';
    List<dynamic> whereArgs = [driverId];

    if (from != null) {
      where += ' AND date >= ?';
      whereArgs.add(_dateToString(from));
    }
    if (to != null) {
      where += ' AND date <= ?';
      whereArgs.add(_dateToString(to));
    }

    final results = await db.query(
      'driver_assignments',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
    return results.map((map) => DriverAssignment.fromMap(map)).toList();
  }

  /// Gets today's assignments across all vehicles.
  Future<List<DriverAssignment>> getCurrentAssignments() async {
    final db = await _dbHelper.database;
    final today = _dateToString(DateTime.now());
    final results = await db.query(
      'driver_assignments',
      where: 'date = ?',
      whereArgs: [today],
      orderBy: 'vehicleId ASC',
    );
    return results.map((map) => DriverAssignment.fromMap(map)).toList();
  }

  /// Formats date as yyyy-MM-dd for storage
  String _dateToString(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
