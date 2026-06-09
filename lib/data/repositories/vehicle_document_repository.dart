import '../../domain/models/vehicle_document.dart';
import '../database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class VehicleDocumentRepository {
  final DatabaseHelper _dbHelper;

  VehicleDocumentRepository(this._dbHelper);

  /// Returns all documents for a vehicle
  Future<List<VehicleDocument>> getDocuments(String vehicleId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'vehicle_documents',
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
    );
    return maps.map((m) => VehicleDocument.fromMap(m)).toList();
  }

  /// Returns specific document type for a vehicle
  Future<VehicleDocument?> getDocument(
      String vehicleId, DocumentType type) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'vehicle_documents',
      where: 'vehicleId = ? AND documentType = ?',
      whereArgs: [vehicleId, type.name],
    );
    if (maps.isEmpty) return null;
    return VehicleDocument.fromMap(maps.first);
  }

  /// Upsert a document (insert or replace)
  Future<void> saveDocument(VehicleDocument doc) async {
    final db = await _dbHelper.database;
    await db.insert(
      'vehicle_documents',
      doc.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Delete a document by id
  Future<void> deleteDocument(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'vehicle_documents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Returns documents expiring within N days (not yet expired)
  Future<List<VehicleDocument>> getExpiringSoon(int warningDays) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadline = today.add(Duration(days: warningDays));

    final maps = await db.query(
      'vehicle_documents',
      where: 'expiryDate >= ? AND expiryDate <= ?',
      whereArgs: [
        today.toIso8601String(),
        deadline.toIso8601String(),
      ],
    );
    return maps.map((m) => VehicleDocument.fromMap(m)).toList();
  }

  /// Returns all documents past their expiry date
  Future<List<VehicleDocument>> getAllExpired() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final maps = await db.query(
      'vehicle_documents',
      where: 'expiryDate < ?',
      whereArgs: [today.toIso8601String()],
    );
    return maps.map((m) => VehicleDocument.fromMap(m)).toList();
  }
}
