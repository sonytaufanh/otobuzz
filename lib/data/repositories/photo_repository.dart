import '../../domain/models/maintenance_photo.dart';
import '../database/database_helper.dart';

class PhotoRepository {
  final DatabaseHelper _dbHelper;

  PhotoRepository(this._dbHelper);

  Future<List<MaintenancePhoto>> getPhotosForRecord(
      String maintenanceRecordId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'maintenance_photos',
      where: 'maintenanceRecordId = ?',
      whereArgs: [maintenanceRecordId],
      orderBy: 'createdAt ASC',
    );
    return maps.map((m) => MaintenancePhoto.fromMap(m)).toList();
  }

  Future<void> insertPhoto(MaintenancePhoto photo) async {
    final db = await _dbHelper.database;
    await db.insert('maintenance_photos', photo.toMap());
  }

  Future<void> deletePhoto(String id) async {
    final db = await _dbHelper.database;
    await db.delete('maintenance_photos', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deletePhotosForRecord(String maintenanceRecordId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'maintenance_photos',
      where: 'maintenanceRecordId = ?',
      whereArgs: [maintenanceRecordId],
    );
  }
}
