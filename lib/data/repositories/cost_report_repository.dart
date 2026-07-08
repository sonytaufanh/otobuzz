import '../../domain/models/maintenance_type.dart';
import '../database/database_helper.dart';

/// Model for monthly cost summary
class MonthlyCostSummary {
  final int month;
  final int year;
  final double totalCost;
  final double expenseCost;

  const MonthlyCostSummary({
    required this.month,
    required this.year,
    required this.totalCost,
    this.expenseCost = 0,
  });

  double get grandTotal => totalCost + expenseCost;
}

/// Model for cost grouped by maintenance type
class CostByType {
  final MaintenanceType type;
  final double totalCost;
  final int count;

  const CostByType({
    required this.type,
    required this.totalCost,
    required this.count,
  });
}

/// Model for cost grouped by vehicle
class CostByVehicle {
  final String vehicleId;
  final String vehicleName;
  final double totalCost;
  final int count;

  const CostByVehicle({
    required this.vehicleId,
    required this.vehicleName,
    required this.totalCost,
    required this.count,
  });
}

class CostReportRepository {
  final DatabaseHelper _dbHelper;

  CostReportRepository(this._dbHelper);

  /// Returns monthly totals for a given year, optionally filtered by vehicle.
  Future<List<MonthlyCostSummary>> getMonthlyCostSummary(
      String? vehicleId, int year) async {
    final db = await _dbHelper.database;

    final whereClause = vehicleId != null
        ? "WHERE vehicleId = ? AND strftime('%Y', serviceDate) = ?"
        : "WHERE strftime('%Y', serviceDate) = ?";
    final args = vehicleId != null ? [vehicleId, year.toString()] : [year.toString()];

    final results = await db.rawQuery('''
      SELECT 
        CAST(strftime('%m', serviceDate) AS INTEGER) as month,
        SUM(COALESCE(cost, 0)) as totalCost
      FROM maintenance_records
      $whereClause
      GROUP BY strftime('%m', serviceDate)
      ORDER BY month
    ''', args);

    return results.map((row) {
      return MonthlyCostSummary(
        month: row['month'] as int,
        year: year,
        totalCost: (row['totalCost'] as num).toDouble(),
      );
    }).toList();
  }

  /// Returns costs grouped by maintenance type within a date range.
  Future<List<CostByType>> getCostByType(
      String? vehicleId, DateTime from, DateTime to) async {
    final db = await _dbHelper.database;

    final whereClause = vehicleId != null
        ? 'WHERE vehicleId = ? AND serviceDate >= ? AND serviceDate <= ?'
        : 'WHERE serviceDate >= ? AND serviceDate <= ?';
    final args = vehicleId != null
        ? [vehicleId, from.toIso8601String(), to.toIso8601String()]
        : [from.toIso8601String(), to.toIso8601String()];

    final results = await db.rawQuery('''
      SELECT 
        type,
        SUM(COALESCE(cost, 0)) as totalCost,
        COUNT(*) as count
      FROM maintenance_records
      $whereClause
      GROUP BY type
      ORDER BY totalCost DESC
    ''', args);

    return results.map((row) {
      return CostByType(
        type: MaintenanceType.values[row['type'] as int],
        totalCost: (row['totalCost'] as num).toDouble(),
        count: (row['count'] as int),
      );
    }).toList();
  }

  /// Returns costs grouped by vehicle within a date range.
  Future<List<CostByVehicle>> getCostByVehicle(
      DateTime from, DateTime to) async {
    final db = await _dbHelper.database;

    final results = await db.rawQuery('''
      SELECT 
        m.vehicleId,
        v.name as vehicleName,
        SUM(COALESCE(m.cost, 0)) as totalCost,
        COUNT(*) as count
      FROM maintenance_records m
      LEFT JOIN vehicles v ON m.vehicleId = v.id
      WHERE m.serviceDate >= ? AND m.serviceDate <= ?
      GROUP BY m.vehicleId
      ORDER BY totalCost DESC
    ''', [from.toIso8601String(), to.toIso8601String()]);

    return results.map((row) {
      return CostByVehicle(
        vehicleId: row['vehicleId'] as String,
        vehicleName: (row['vehicleName'] as String?) ?? 'Kendaraan Dihapus',
        totalCost: (row['totalCost'] as num).toDouble(),
        count: row['count'] as int,
      );
    }).toList();
  }

  /// Returns the total cost within a date range, optionally filtered by vehicle.
  Future<double> getTotalCost(
      String? vehicleId, DateTime from, DateTime to) async {
    final db = await _dbHelper.database;

    final whereClause = vehicleId != null
        ? 'WHERE vehicleId = ? AND serviceDate >= ? AND serviceDate <= ?'
        : 'WHERE serviceDate >= ? AND serviceDate <= ?';
    final args = vehicleId != null
        ? [vehicleId, from.toIso8601String(), to.toIso8601String()]
        : [from.toIso8601String(), to.toIso8601String()];

    final results = await db.rawQuery('''
      SELECT SUM(COALESCE(cost, 0)) as totalCost
      FROM maintenance_records
      $whereClause
    ''', args);

    if (results.isEmpty || results.first['totalCost'] == null) return 0;
    return (results.first['totalCost'] as num).toDouble();
  }

  /// Returns the total cost including expenses within a date range.
  Future<double> getTotalCostWithExpenses(
      String? vehicleId, DateTime from, DateTime to) async {
    final maintenanceCost = await getTotalCost(vehicleId, from, to);

    final db = await _dbHelper.database;
    final whereClause = vehicleId != null
        ? 'WHERE vehicleId = ? AND date >= ? AND date <= ?'
        : 'WHERE date >= ? AND date <= ?';
    final args = vehicleId != null
        ? [vehicleId, from.toIso8601String(), to.toIso8601String()]
        : [from.toIso8601String(), to.toIso8601String()];

    final results = await db.rawQuery('''
      SELECT SUM(amount) as totalExpense
      FROM expense_records
      $whereClause
    ''', args);

    double expenseCost = 0;
    if (results.isNotEmpty && results.first['totalExpense'] != null) {
      expenseCost = (results.first['totalExpense'] as num).toDouble();
    }

    return maintenanceCost + expenseCost;
  }
}
