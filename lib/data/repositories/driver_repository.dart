import 'package:uuid/uuid.dart';
import '../../domain/models/models.dart';
import '../database/database_helper.dart';

class DriverRepository {
  final DatabaseHelper _dbHelper;
  final Uuid _uuid = const Uuid();

  DriverRepository(this._dbHelper);

  Future<List<Driver>> getAllDrivers() async {
    final db = await _dbHelper.database;
    final results = await db.query('drivers', orderBy: 'name ASC');
    return results.map((map) => Driver.fromMap(map)).toList();
  }

  Future<Driver?> getDriverById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'drivers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return Driver.fromMap(results.first);
  }

  Future<void> addDriver(Driver driver) async {
    final db = await _dbHelper.database;
    final effectiveDriver = driver.id.isEmpty
        ? driver.copyWith(id: _uuid.v4())
        : driver;
    await db.insert('drivers', effectiveDriver.toMap());
  }

  Future<void> updateDriver(Driver driver) async {
    final db = await _dbHelper.database;
    await db.update(
      'drivers',
      driver.toMap(),
      where: 'id = ?',
      whereArgs: [driver.id],
    );
  }

  Future<void> deleteDriver(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'drivers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
