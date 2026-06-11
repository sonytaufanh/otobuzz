import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/daily_checklist.dart';
import '../../domain/models/vehicle_type.dart';
import '../database/database_helper.dart';

class ChecklistRepository {
  final DatabaseHelper _dbHelper;

  ChecklistRepository(this._dbHelper);

  /// Default checklist items per vehicle type
  static List<ChecklistItem> getDefaultItems(VehicleType type) {
    if (type == VehicleType.motorcycle) {
      return const [
        ChecklistItem(name: 'Ban depan & belakang (kondisi & tekanan)'),
        ChecklistItem(name: 'Lampu depan & belakang'),
        ChecklistItem(name: 'Rem depan & belakang'),
        ChecklistItem(name: 'Klakson'),
        ChecklistItem(name: 'Spion'),
        ChecklistItem(name: 'Rantai (kekencangan & pelumasan)'),
        ChecklistItem(name: 'Oli (level)'),
        ChecklistItem(name: 'BBM (cukup)'),
      ];
    } else {
      return const [
        ChecklistItem(name: 'Ban 4 roda (kondisi & tekanan)'),
        ChecklistItem(name: 'Lampu depan, belakang, sein'),
        ChecklistItem(name: 'Rem'),
        ChecklistItem(name: 'Klakson'),
        ChecklistItem(name: 'Spion & kaca'),
        ChecklistItem(name: 'Wiper'),
        ChecklistItem(name: 'Oli (level)'),
        ChecklistItem(name: 'Coolant (level)'),
        ChecklistItem(name: 'BBM (cukup)'),
        ChecklistItem(name: 'AC (fungsi)'),
      ];
    }
  }

  /// Save or update a checklist
  Future<void> saveChecklist(DailyChecklist checklist) async {
    final db = await _dbHelper.database;
    final map = checklist.toMap();

    // If id is empty, generate one
    if (checklist.id.isEmpty) {
      map['id'] = const Uuid().v4();
    }

    await db.insert(
      'daily_checklists',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get checklist for a vehicle on a specific date
  Future<DailyChecklist?> getChecklist(String vehicleId, DateTime date) async {
    final db = await _dbHelper.database;
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final results = await db.query(
      'daily_checklists',
      where: 'vehicleId = ? AND date = ?',
      whereArgs: [vehicleId, dateStr],
    );

    if (results.isEmpty) return null;
    return DailyChecklist.fromMap(results.first);
  }

  /// Get checklist history for a vehicle within a date range
  Future<List<DailyChecklist>> getChecklistHistory(
    String vehicleId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await _dbHelper.database;
    String where = 'vehicleId = ?';
    final args = <dynamic>[vehicleId];

    if (from != null) {
      where += ' AND date >= ?';
      args.add(
          '${from.year.toString().padLeft(4, '0')}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}');
    }
    if (to != null) {
      where += ' AND date <= ?';
      args.add(
          '${to.year.toString().padLeft(4, '0')}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}');
    }

    final results = await db.query(
      'daily_checklists',
      where: where,
      whereArgs: args,
      orderBy: 'date DESC',
    );

    return results.map((row) => DailyChecklist.fromMap(row)).toList();
  }

  /// Quick status check for today (returns null if not done)
  Future<ChecklistStatus?> getTodayStatus(String vehicleId) async {
    final now = DateTime.now();
    final checklist = await getChecklist(vehicleId, now);
    return checklist?.overallStatus;
  }

  /// Get vehicles that haven't done checklist today
  Future<List<String>> getIncompleteToday() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final dateStr =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final results = await db.rawQuery('''
      SELECT v.id FROM vehicles v
      WHERE v.id NOT IN (
        SELECT vehicleId FROM daily_checklists WHERE date = ?
      )
    ''', [dateStr]);

    return results.map((row) => row['id'] as String).toList();
  }
}
