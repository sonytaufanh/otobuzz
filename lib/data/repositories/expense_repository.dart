import '../../domain/models/expense_record.dart';
import '../database/database_helper.dart';

class ExpenseRepository {
  final DatabaseHelper _dbHelper;

  ExpenseRepository(this._dbHelper);

  Future<void> addExpense(ExpenseRecord record) async {
    final db = await _dbHelper.database;
    await db.insert('expense_records', record.toMap());
  }

  Future<List<ExpenseRecord>> getExpenses(
    String vehicleId, {
    DateTime? from,
    DateTime? to,
    ExpenseCategory? category,
  }) async {
    final db = await _dbHelper.database;

    final conditions = <String>['vehicleId = ?'];
    final args = <dynamic>[vehicleId];

    if (from != null) {
      conditions.add('date >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      conditions.add('date <= ?');
      args.add(to.toIso8601String());
    }
    if (category != null) {
      conditions.add('category = ?');
      args.add(category.name);
    }

    final whereClause = conditions.join(' AND ');

    final results = await db.query(
      'expense_records',
      where: whereClause,
      whereArgs: args,
      orderBy: 'date DESC',
    );

    return results.map((row) => ExpenseRecord.fromMap(row)).toList();
  }

  Future<Map<ExpenseCategory, double>> getTotalByCategory(
    String vehicleId,
    DateTime from,
    DateTime to,
  ) async {
    final db = await _dbHelper.database;

    final results = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM expense_records
      WHERE vehicleId = ? AND date >= ? AND date <= ?
      GROUP BY category
    ''', [vehicleId, from.toIso8601String(), to.toIso8601String()]);

    final map = <ExpenseCategory, double>{};
    for (final row in results) {
      final category = ExpenseCategory.values.firstWhere(
        (e) => e.name == row['category'],
        orElse: () => ExpenseCategory.other,
      );
      map[category] = (row['total'] as num).toDouble();
    }
    return map;
  }

  Future<double> getMonthlyTotal(
    String vehicleId,
    int year,
    int month,
  ) async {
    final db = await _dbHelper.database;
    final from = DateTime(year, month, 1);
    final to = DateTime(year, month + 1, 0, 23, 59, 59);

    final results = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM expense_records
      WHERE vehicleId = ? AND date >= ? AND date <= ?
    ''', [vehicleId, from.toIso8601String(), to.toIso8601String()]);

    if (results.isEmpty || results.first['total'] == null) return 0;
    return (results.first['total'] as num).toDouble();
  }

  Future<double> getTotalExpenses(
    String? vehicleId,
    DateTime from,
    DateTime to,
  ) async {
    final db = await _dbHelper.database;

    final whereClause = vehicleId != null
        ? 'WHERE vehicleId = ? AND date >= ? AND date <= ?'
        : 'WHERE date >= ? AND date <= ?';
    final args = vehicleId != null
        ? [vehicleId, from.toIso8601String(), to.toIso8601String()]
        : [from.toIso8601String(), to.toIso8601String()];

    final results = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM expense_records
      $whereClause
    ''', args);

    if (results.isEmpty || results.first['total'] == null) return 0;
    return (results.first['total'] as num).toDouble();
  }

  Future<void> deleteExpense(String id) async {
    final db = await _dbHelper.database;
    await db.delete('expense_records', where: 'id = ?', whereArgs: [id]);
  }
}
