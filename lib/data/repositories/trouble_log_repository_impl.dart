import 'package:uuid/uuid.dart';
import '../../domain/models/trouble_log.dart';
import '../../domain/repositories/trouble_log_repository.dart';
import '../database/database_helper.dart';

class TroubleLogRepositoryImpl implements TroubleLogRepository {
  final DatabaseHelper _dbHelper;
  final _uuid = const Uuid();

  TroubleLogRepositoryImpl(this._dbHelper);

  @override
  Future<List<TroubleLog>> getTroubleLogsByVehicle(String vehicleId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'trouble_logs',
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
      orderBy: 'reportedDate DESC',
    );
    return maps.map((m) => TroubleLog.fromMap(m)).toList();
  }

  @override
  Future<List<TroubleLog>> getUnresolvedLogs(String vehicleId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'trouble_logs',
      where: 'vehicleId = ? AND isResolved = 0',
      whereArgs: [vehicleId],
      orderBy: 'severity DESC, reportedDate DESC',
    );
    return maps.map((m) => TroubleLog.fromMap(m)).toList();
  }

  @override
  Future<TroubleLog?> getTroubleLogById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'trouble_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return TroubleLog.fromMap(maps.first);
  }

  @override
  Future<void> insertTroubleLog(TroubleLog log) async {
    final db = await _dbHelper.database;
    final withId = log.id.isEmpty
        ? log.copyWith(id: _uuid.v4())
        : log;
    await db.insert('trouble_logs', withId.toMap());
  }

  @override
  Future<void> updateTroubleLog(TroubleLog log) async {
    final db = await _dbHelper.database;
    await db.update(
      'trouble_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  @override
  Future<void> deleteTroubleLog(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'trouble_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> markAsResolved(
    String id,
    DateTime resolvedDate,
    String? resolutionNotes,
    String? maintenanceRecordId,
  ) async {
    final db = await _dbHelper.database;
    await db.update(
      'trouble_logs',
      {
        'isResolved': 1,
        'resolvedDate': resolvedDate.toIso8601String(),
        'resolutionNotes': resolutionNotes,
        'maintenanceRecordId': maintenanceRecordId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
