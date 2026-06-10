import 'package:sqflite/sqflite.dart';
import '../../domain/models/mileage_record.dart';
import '../../domain/repositories/mileage_repository.dart';
import '../database/database_helper.dart';

class MileageRepositoryImpl implements MileageRepository {
  final DatabaseHelper _dbHelper;

  MileageRepositoryImpl(this._dbHelper);

  @override
  Future<void> addMileageRecord(MileageRecord record) async {
    final db = await _dbHelper.database;
    await db.insert('mileage_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  @override
  Future<void> upsertMileageRecord(MileageRecord record) async {
    final db = await _dbHelper.database;
    await db.insert('mileage_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<MileageRecord?> getRecordByVehicleAndDate(
      String vehicleId, DateTime date) async {
    final db = await _dbHelper.database;
    final dateStr = DateTime(date.year, date.month, date.day).toIso8601String();
    final maps = await db.query(
      'mileage_records',
      where: 'vehicleId = ? AND date = ?',
      whereArgs: [vehicleId, dateStr],
    );
    if (maps.isEmpty) return null;
    return MileageRecord.fromMap(maps.first);
  }

  @override
  Future<List<MileageRecord>> getMileageHistory(String vehicleId,
      {DateTime? from, DateTime? to}) async {
    final db = await _dbHelper.database;
    String where = 'vehicleId = ?';
    List<dynamic> args = [vehicleId];

    if (from != null) {
      where += ' AND date >= ?';
      args.add(from.toIso8601String());
    }
    if (to != null) {
      where += ' AND date <= ?';
      args.add(to.toIso8601String());
    }

    final maps = await db.query(
      'mileage_records',
      where: where,
      whereArgs: args,
      orderBy: 'date DESC',
    );
    return maps.map((map) => MileageRecord.fromMap(map)).toList();
  }

  @override
  Future<double> getTotalMileage(String vehicleId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(km), 0) as total FROM mileage_records WHERE vehicleId = ?',
      [vehicleId],
    );
    return (result.first['total'] as num).toDouble();
  }

  @override
  Future<double> getAverageDailyMileage(String vehicleId,
      {int lastDays = 30}) async {
    final db = await _dbHelper.database;
    final fromDate =
        DateTime.now().subtract(Duration(days: lastDays)).toIso8601String();
    final result = await db.rawQuery(
      'SELECT COALESCE(AVG(km), 0) as avg FROM mileage_records WHERE vehicleId = ? AND date >= ?',
      [vehicleId, fromDate],
    );
    return (result.first['avg'] as num).toDouble();
  }

  @override
  Future<List<MileageRecord>> getRecordsByDateRange(
      DateTime start, DateTime end,
      {String? vehicleId}) async {
    final db = await _dbHelper.database;
    String where = 'date >= ? AND date <= ?';
    List<dynamic> args = [start.toIso8601String(), end.toIso8601String()];

    if (vehicleId != null) {
      where += ' AND vehicleId = ?';
      args.add(vehicleId);
    }

    final maps = await db.query(
      'mileage_records',
      where: where,
      whereArgs: args,
      orderBy: 'date ASC',
    );
    return maps.map((map) => MileageRecord.fromMap(map)).toList();
  }
}
