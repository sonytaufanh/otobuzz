import 'package:sqflite/sqflite.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../database/database_helper.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  final DatabaseHelper _dbHelper;

  VehicleRepositoryImpl(this._dbHelper);

  @override
  Future<List<Vehicle>> getAllVehicles() async {
    final db = await _dbHelper.database;
    final maps = await db.query('vehicles', orderBy: 'name ASC');
    return maps.map((map) => Vehicle.fromMap(map)).toList();
  }

  @override
  Future<Vehicle?> getVehicleById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('vehicles', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Vehicle.fromMap(maps.first);
  }

  @override
  Future<void> addVehicle(Vehicle vehicle) async {
    final db = await _dbHelper.database;
    await db.insert('vehicles', vehicle.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> updateVehicle(Vehicle vehicle) async {
    final db = await _dbHelper.database;
    await db.update(
      'vehicles',
      vehicle.toMap(),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
  }

  @override
  Future<void> deleteVehicle(String id) async {
    final db = await _dbHelper.database;
    await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
    await db.delete('mileage_records', where: 'vehicleId = ?', whereArgs: [id]);
    await db.delete('maintenance_records',
        where: 'vehicleId = ?', whereArgs: [id]);
    await db.delete('maintenance_schedules',
        where: 'vehicleId = ?', whereArgs: [id]);
  }

  @override
  Future<void> updateTotalMileage(String vehicleId, double totalKm) async {
    final db = await _dbHelper.database;
    await db.update(
      'vehicles',
      {'totalMileageKm': totalKm},
      where: 'id = ?',
      whereArgs: [vehicleId],
    );
  }
}
