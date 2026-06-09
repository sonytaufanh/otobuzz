import 'package:equatable/equatable.dart';

abstract class CostReportEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadCostReport extends CostReportEvent {
  final String? vehicleId;
  final DateTime from;
  final DateTime to;

  LoadCostReport({
    this.vehicleId,
    required this.from,
    required this.to,
  });

  @override
  List<Object?> get props => [vehicleId, from, to];
}

class ChangePeriod extends CostReportEvent {
  final CostReportPeriod period;

  ChangePeriod(this.period);

  @override
  List<Object?> get props => [period];
}

enum CostReportPeriod {
  thisMonth,
  threeMonths,
  thisYear,
  custom,
}
