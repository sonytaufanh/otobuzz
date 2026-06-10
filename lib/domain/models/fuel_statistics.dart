import 'package:equatable/equatable.dart';

class MonthlyFuelSummary extends Equatable {
  final int year;
  final int month;
  final double totalLiters;
  final double totalCost;
  final double averageKmPerLiter;

  const MonthlyFuelSummary({
    required this.year,
    required this.month,
    required this.totalLiters,
    required this.totalCost,
    required this.averageKmPerLiter,
  });

  @override
  List<Object?> get props => [year, month, totalLiters, totalCost, averageKmPerLiter];
}

class FuelStatistics extends Equatable {
  final double averageKmPerLiter;
  final double totalLiters;
  final double totalCost;
  final double averageCostPerKm;
  final String trend; // 'improving', 'worsening', 'stable'
  final List<MonthlyFuelSummary> monthlySummaries;

  const FuelStatistics({
    required this.averageKmPerLiter,
    required this.totalLiters,
    required this.totalCost,
    required this.averageCostPerKm,
    required this.trend,
    required this.monthlySummaries,
  });

  factory FuelStatistics.empty() {
    return const FuelStatistics(
      averageKmPerLiter: 0,
      totalLiters: 0,
      totalCost: 0,
      averageCostPerKm: 0,
      trend: 'stable',
      monthlySummaries: [],
    );
  }

  @override
  List<Object?> get props => [
        averageKmPerLiter,
        totalLiters,
        totalCost,
        averageCostPerKm,
        trend,
        monthlySummaries,
      ];
}
