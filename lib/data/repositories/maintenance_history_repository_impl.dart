import 'package:sqflite/sqflite.dart';
import '../../domain/models/maintenance_record.dart';
import '../../domain/models/maintenance_type.dart';
import '../../domain/repositories/maintenance_history_repository.dart';
import '../database/database_helper.dart';

class MaintenanceHistoryRepositoryImpl implements MaintenanceHistoryRepository {
  final DatabaseHelper _dbHelper;

  MaintenanceHistoryRepositoryImpl(this._dbHelper);

  @override
  Future<void> addMaintenanceRecord(MaintenanceRecord record) async {
    final db = await _dbHelper.database;
    await db.insert('maintenance_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<MaintenanceRecord>> getHistory(String vehicleId,
      {MaintenanceType? type}) async {
    final db = await _dbHelper.database;
    String where = 'vehicleId = ?';
    List<dynamic> args = [vehicleId];

    if (type != null) {
      where += ' AND type = ?';
      args.add(type.index);
    }

    final maps = await db.query(
      'maintenance_records',
      where: where,
      whereArgs: args,
      orderBy: 'serviceDate DESC',
    );
    return maps.map((map) => MaintenanceRecord.fromMap(map)).toList();
  }

  @override
  Future<MaintenanceRecord?> getLastMaintenance(
      String vehicleId, MaintenanceType type) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'maintenance_records',
      where: 'vehicleId = ? AND type = ?',
      whereArgs: [vehicleId, type.index],
      orderBy: 'serviceDate DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return MaintenanceRecord.fromMap(maps.first);
  }

  @override
  Future<Map<MaintenanceType, MaintenanceRecord>> getLastMaintenanceByType(
      String vehicleId) async {
    final db = await _dbHelper.database;
    final result = <MaintenanceType, MaintenanceRecord>{};

    for (final type in MaintenanceType.values) {
      final maps = await db.query(
        'maintenance_records',
        where: 'vehicleId = ? AND type = ?',
        whereArgs: [vehicleId, type.index],
        orderBy: 'serviceDate DESC',
        limit: 1,
      );
      if (maps.isNotEmpty) {
        result[type] = MaintenanceRecord.fromMap(maps.first);
      }
    }
    return result;
  }
}
