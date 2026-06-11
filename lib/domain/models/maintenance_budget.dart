import 'package:equatable/equatable.dart';

class MaintenanceBudget extends Equatable {
  final String id;
  final String? vehicleId; // null = fleet-wide
  final double monthlyBudget;
  final int year;
  final int month;
  final String? notes;

  const MaintenanceBudget({
    required this.id,
    this.vehicleId,
    required this.monthlyBudget,
    required this.year,
    required this.month,
    this.notes,
  });

  MaintenanceBudget copyWith({
    String? id,
    String? vehicleId,
    double? monthlyBudget,
    int? year,
    int? month,
    String? notes,
  }) {
    return MaintenanceBudget(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      year: year ?? this.year,
      month: month ?? this.month,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'monthlyBudget': monthlyBudget,
      'year': year,
      'month': month,
      'notes': notes,
    };
  }

  factory MaintenanceBudget.fromMap(Map<String, dynamic> map) {
    return MaintenanceBudget(
      id: map['id'] as String,
      vehicleId: map['vehicleId'] as String?,
      monthlyBudget: (map['monthlyBudget'] as num).toDouble(),
      year: map['year'] as int,
      month: map['month'] as int,
      notes: map['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, vehicleId, monthlyBudget, year, month, notes];
}

enum BudgetLevel { under, warning, over }

class BudgetStatus extends Equatable {
  final double budget;
  final double spent;
  final double remaining;
  final double percentage; // spent/budget * 100
  final BudgetLevel level;

  const BudgetStatus({
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.percentage,
    required this.level,
  });

  factory BudgetStatus.calculate({
    required double budget,
    required double spent,
  }) {
    final remaining = budget - spent;
    final percentage = budget > 0 ? (spent / budget) * 100 : 0.0;
    final BudgetLevel level;
    if (percentage > 100) {
      level = BudgetLevel.over;
    } else if (percentage >= 70) {
      level = BudgetLevel.warning;
    } else {
      level = BudgetLevel.under;
    }

    return BudgetStatus(
      budget: budget,
      spent: spent,
      remaining: remaining,
      percentage: percentage,
      level: level,
    );
  }

  @override
  List<Object?> get props => [budget, spent, remaining, percentage, level];
}
