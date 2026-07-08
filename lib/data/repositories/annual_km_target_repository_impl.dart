import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/annual_km_target.dart';
import '../../domain/repositories/annual_km_target_repository.dart';
import '../database/database_helper.dart';

class AnnualKmTargetRepositoryImpl implements AnnualKmTargetRepository {
  final DatabaseHelper _dbHelper;
  final _uuid = const Uuid();

  AnnualKmTargetRepositoryImpl(this._dbHelper);

  @override
  Future<AnnualKmTarget?> getTarget(String vehicleId, int year) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'annual_km_targets',
      where: 'vehicleId = ? AND year = ?',
      whereArgs: [vehicleId, year],
    );
    if (maps.isEmpty) return null;
    return AnnualKmTarget.fromMap(maps.first);
  }

  @override
  Future<List<AnnualKmTarget>> getAllTargets(String vehicleId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'annual_km_targets',
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
      orderBy: 'year DESC',
    );
    return maps.map((m) => AnnualKmTarget.fromMap(m)).toList();
  }

  @override
  Future<void> setTarget(AnnualKmTarget target) async {
    final db = await _dbHelper.database;
    final withId = target.id.isEmpty ? target.copyWith(id: _uuid.v4()) : target;
    await db.insert(
      'annual_km_targets',
      withId.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteTarget(String id) async {
    final db = await _dbHelper.database;
    await db.delete('annual_km_targets', where: 'id = ?', whereArgs: [id]);
  }
}
