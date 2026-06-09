import 'package:sqflite/sqflite.dart';
import '../../domain/models/maintenance_schedule.dart';
import '../../domain/repositories/maintenance_schedule_repository.dart';
import '../database/database_helper.dart';

class MaintenanceScheduleRepositoryImpl
    implements MaintenanceScheduleRepository {
  final DatabaseHelper _dbHelper;

  MaintenanceScheduleRepositoryImpl(this._dbHelper);

  @override
  Future<void> updateSchedules(
      String vehicleId, List<MaintenanceSchedule> schedules) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('maintenance_schedules',
          where: 'vehicleId = ?', whereArgs: [vehicleId]);
      for (final schedule in schedules) {
        await txn.insert('maintenance_schedules', schedule.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  @override
  Future<List<MaintenanceSchedule>> getSchedules(String vehicleId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'maintenance_schedules',
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
      orderBy: 'isOverdue DESC, remainingKm ASC',
    );
    return maps.map((map) => MaintenanceSchedule.fromMap(map)).toList();
  }

  @override
  Future<void> deleteSchedulesForVehicle(String vehicleId) async {
    final db = await _dbHelper.database;
    await db.delete('maintenance_schedules',
        where: 'vehicleId = ?', whereArgs: [vehicleId]);
  }
}
