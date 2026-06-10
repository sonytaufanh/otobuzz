import 'package:equatable/equatable.dart';

class DailyKm {
  final DateTime date;
  final double km;
  DailyKm({required this.date, required this.km});
}

class MonthlyCost {
  final int year;
  final int month;
  final double cost;
  MonthlyCost({required this.year, required this.month, required this.cost});
}

class MaintenanceTypeCost {
  final String typeName;
  final double cost;
  MaintenanceTypeCost({required this.typeName, required this.cost});
}

class MonthlyFuel {
  final int year;
  final int month;
  final double cost;
  final double kmPerLiter;
  MonthlyFuel({
    required this.year,
    required this.month,
    required this.cost,
    required this.kmPerLiter,
  });
}

abstract class AnalyticsState extends Equatable {
  const AnalyticsState();

  @override
  List<Object?> get props => [];
}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {}

class AnalyticsLoaded extends AnalyticsState {
  // Summary
  final double totalKmThisMonth;
  final double totalKmLastMonth;
  final double totalMaintenanceCostThisMonth;
  final double totalFuelCostThisMonth;
  final double averageFleetKmPerLiter;

  // Chart data
  final List<DailyKm> dailyKmData;
  final List<MonthlyCost> monthlyCostData;
  final List<MaintenanceTypeCost> typeCostData;
  final List<MonthlyFuel> monthlyFuelData;

  // Filters
  final String? selectedVehicleId;
  final int periodDays;

  const AnalyticsLoaded({
    required this.totalKmThisMonth,
    required this.totalKmLastMonth,
    required this.totalMaintenanceCostThisMonth,
    required this.totalFuelCostThisMonth,
    required this.averageFleetKmPerLiter,
    required this.dailyKmData,
    required this.monthlyCostData,
    required this.typeCostData,
    required this.monthlyFuelData,
    this.selectedVehicleId,
    this.periodDays = 30,
  });

  @override
  List<Object?> get props => [
        totalKmThisMonth,
        totalKmLastMonth,
        totalMaintenanceCostThisMonth,
        totalFuelCostThisMonth,
        averageFleetKmPerLiter,
        dailyKmData,
        monthlyCostData,
        typeCostData,
        monthlyFuelData,
        selectedVehicleId,
        periodDays,
      ];
}

class AnalyticsError extends AnalyticsState {
  final String message;
  const AnalyticsError(this.message);

  @override
  List<Object?> get props => [message];
}
