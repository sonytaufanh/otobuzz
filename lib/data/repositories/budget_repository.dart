import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import '../../domain/models/maintenance_budget.dart';
import '../database/database_helper.dart';

class BudgetRepository {
  final DatabaseHelper _dbHelper;

  BudgetRepository(this._dbHelper);

  /// Set (upsert) a budget for a specific vehicle/fleet for a given month
  Future<void> setBudget(MaintenanceBudget budget) async {
    final db = await _dbHelper.database;
    final map = budget.toMap();

    if (budget.id.isEmpty) {
      map['id'] = const Uuid().v4();
    }

    await db.insert(
      'maintenance_budgets',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get budget for a specific vehicle (or fleet-wide if vehicleId is null)
  Future<MaintenanceBudget?> getBudget(
      String? vehicleId, int year, int month) async {
    final db = await _dbHelper.database;

    final where = vehicleId != null
        ? 'vehicleId = ? AND year = ? AND month = ?'
        : 'vehicleId IS NULL AND year = ? AND month = ?';
    final args = vehicleId != null
        ? [vehicleId, year, month]
        : [year, month];

    final results = await db.query(
      'maintenance_budgets',
      where: where,
      whereArgs: args,
    );

    if (results.isEmpty) return null;
    return MaintenanceBudget.fromMap(results.first);
  }

  /// Get fleet-wide budget for a given month
  Future<MaintenanceBudget?> getFleetBudget(int year, int month) async {
    return getBudget(null, year, month);
  }

  /// Calculate budget status (spent vs budget) using maintenance_records costs
  Future<BudgetStatus?> getBudgetStatus(
      String? vehicleId, int year, int month) async {
    final budget = await getBudget(vehicleId, year, month);
    if (budget == null) return null;

    final spent = await _getMonthlySpent(vehicleId, year, month);
    return BudgetStatus.calculate(budget: budget.monthlyBudget, spent: spent);
  }

  /// Get yearly budget overview (12 months)
  Future<List<BudgetStatus?>> getYearlyBudgetOverview(
      String? vehicleId, int year) async {
    final results = <BudgetStatus?>[];
    for (int month = 1; month <= 12; month++) {
      results.add(await getBudgetStatus(vehicleId, year, month));
    }
    return results;
  }

  /// Get vehicles or fleet that exceed budget this month
  Future<List<BudgetStatus>> getOverBudgetThisMonth() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    final budgets = await db.query(
      'maintenance_budgets',
      where: 'year = ? AND month = ?',
      whereArgs: [now.year, now.month],
    );

    final overBudgets = <BudgetStatus>[];
    for (final budgetMap in budgets) {
      final budget = MaintenanceBudget.fromMap(budgetMap);
      final spent =
          await _getMonthlySpent(budget.vehicleId, budget.year, budget.month);
      final status =
          BudgetStatus.calculate(budget: budget.monthlyBudget, spent: spent);
      if (status.level == BudgetLevel.over) {
        overBudgets.add(status);
      }
    }
    return overBudgets;
  }

  /// Get monthly spent from maintenance_records + fuel_records
  Future<double> _getMonthlySpent(
      String? vehicleId, int year, int month) async {
    final db = await _dbHelper.database;
    final monthStr = month.toString().padLeft(2, '0');
    final yearStr = year.toString();

    // Maintenance costs
    String maintenanceWhere = vehicleId != null
        ? "WHERE vehicleId = ? AND strftime('%Y', serviceDate) = ? AND strftime('%m', serviceDate) = ?"
        : "WHERE strftime('%Y', serviceDate) = ? AND strftime('%m', serviceDate) = ?";
    final maintenanceArgs = vehicleId != null
        ? [vehicleId, yearStr, monthStr]
        : [yearStr, monthStr];

    final maintenanceResult = await db.rawQuery('''
      SELECT SUM(COALESCE(cost, 0)) as totalCost
      FROM maintenance_records
      $maintenanceWhere
    ''', maintenanceArgs);

    double maintenanceCost = 0;
    if (maintenanceResult.isNotEmpty &&
        maintenanceResult.first['totalCost'] != null) {
      maintenanceCost =
          (maintenanceResult.first['totalCost'] as num).toDouble();
    }

    return maintenanceCost;
  }
}
