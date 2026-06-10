import '../../domain/models/fuel_record.dart';
import '../../domain/models/fuel_statistics.dart';
import '../database/database_helper.dart';

class FuelRepository {
  final DatabaseHelper _dbHelper;

  FuelRepository(this._dbHelper);

  Future<List<FuelRecord>> getFuelRecords(String vehicleId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'fuel_records',
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => FuelRecord.fromMap(m)).toList();
  }

  Future<List<FuelRecord>> getFuelRecordsByPeriod(
    String vehicleId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'fuel_records',
      where: 'vehicleId = ? AND date >= ? AND date <= ?',
      whereArgs: [
        vehicleId,
        start.toIso8601String(),
        end.toIso8601String(),
      ],
      orderBy: 'date DESC',
    );
    return maps.map((m) => FuelRecord.fromMap(m)).toList();
  }

  Future<List<FuelRecord>> getAllFuelRecordsByPeriod(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'fuel_records',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return maps.map((m) => FuelRecord.fromMap(m)).toList();
  }

  Future<void> insertFuelRecord(FuelRecord record) async {
    final db = await _dbHelper.database;
    await db.insert('fuel_records', record.toMap());
  }

  Future<void> deleteFuelRecord(String id) async {
    final db = await _dbHelper.database;
    await db.delete('fuel_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<FuelStatistics> getStatistics(
    String vehicleId, {
    DateTime? start,
    DateTime? end,
  }) async {
    final now = DateTime.now();
    final effectiveStart = start ?? DateTime(now.year, now.month - 3, now.day);
    final effectiveEnd = end ?? now;

    final records = await getFuelRecordsByPeriod(
        vehicleId, effectiveStart, effectiveEnd);

    if (records.isEmpty) {
      return FuelStatistics.empty();
    }

    final totalLiters = records.fold<double>(0, (s, r) => s + r.liters);
    final totalCost = records.fold<double>(0, (s, r) => s + r.totalCost);

    // Calculate km/liter using full-tank method
    final averageKmPerLiter = _calculateKmPerLiter(vehicleId, records);

    // Calculate average cost per km
    final fullTankRecords = records.where((r) => r.isFullTank).toList();
    double averageCostPerKm = 0;
    if (fullTankRecords.length >= 2 && averageKmPerLiter > 0) {
      averageCostPerKm = totalCost / (totalLiters * averageKmPerLiter);
    }

    // Calculate trend
    final trend = _calculateTrend(records);

    // Monthly summaries
    final monthlySummaries = _buildMonthlySummaries(records);

    return FuelStatistics(
      averageKmPerLiter: averageKmPerLiter,
      totalLiters: totalLiters,
      totalCost: totalCost,
      averageCostPerKm: averageCostPerKm,
      trend: trend,
      monthlySummaries: monthlySummaries,
    );
  }

  double _calculateKmPerLiter(String vehicleId, List<FuelRecord> records) {
    // Full-tank-to-full-tank method
    final fullTankRecords =
        records.where((r) => r.isFullTank).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    if (fullTankRecords.length < 2) return 0;

    double totalKm = 0;
    double totalLiters = 0;

    for (int i = 1; i < fullTankRecords.length; i++) {
      final kmDiff =
          fullTankRecords[i].odometerKm - fullTankRecords[i - 1].odometerKm;
      if (kmDiff > 0) {
        totalKm += kmDiff;
        totalLiters += fullTankRecords[i].liters;
      }
    }

    if (totalLiters == 0) return 0;
    return totalKm / totalLiters;
  }

  String _calculateTrend(List<FuelRecord> records) {
    final fullTankRecords =
        records.where((r) => r.isFullTank).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    if (fullTankRecords.length < 4) return 'stable';

    // Compare first half vs second half consumption
    final mid = fullTankRecords.length ~/ 2;
    final firstHalf = fullTankRecords.sublist(0, mid);
    final secondHalf = fullTankRecords.sublist(mid);

    final firstKmPerLiter = _calculateKmPerLiterFromList(firstHalf);
    final secondKmPerLiter = _calculateKmPerLiterFromList(secondHalf);

    if (firstKmPerLiter == 0 || secondKmPerLiter == 0) return 'stable';

    final change = (secondKmPerLiter - firstKmPerLiter) / firstKmPerLiter;

    if (change > 0.05) return 'improving';
    if (change < -0.05) return 'worsening';
    return 'stable';
  }

  double _calculateKmPerLiterFromList(List<FuelRecord> records) {
    if (records.length < 2) return 0;
    double totalKm = 0;
    double totalLiters = 0;
    for (int i = 1; i < records.length; i++) {
      final kmDiff = records[i].odometerKm - records[i - 1].odometerKm;
      if (kmDiff > 0) {
        totalKm += kmDiff;
        totalLiters += records[i].liters;
      }
    }
    if (totalLiters == 0) return 0;
    return totalKm / totalLiters;
  }

  List<MonthlyFuelSummary> _buildMonthlySummaries(List<FuelRecord> records) {
    final Map<String, List<FuelRecord>> grouped = {};
    for (final r in records) {
      final key = '${r.date.year}-${r.date.month}';
      grouped.putIfAbsent(key, () => []).add(r);
    }

    final summaries = <MonthlyFuelSummary>[];
    for (final entry in grouped.entries) {
      final recs = entry.value;
      final totalLiters = recs.fold<double>(0, (s, r) => s + r.liters);
      final totalCost = recs.fold<double>(0, (s, r) => s + r.totalCost);
      final avgKmPerLiter = _calculateKmPerLiterFromList(
        recs.where((r) => r.isFullTank).toList()
          ..sort((a, b) => a.date.compareTo(b.date)),
      );
      summaries.add(MonthlyFuelSummary(
        year: recs.first.date.year,
        month: recs.first.date.month,
        totalLiters: totalLiters,
        totalCost: totalCost,
        averageKmPerLiter: avgKmPerLiter,
      ));
    }

    summaries.sort((a, b) {
      final yearCmp = a.year.compareTo(b.year);
      return yearCmp != 0 ? yearCmp : a.month.compareTo(b.month);
    });

    return summaries;
  }
}
