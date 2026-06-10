import 'package:equatable/equatable.dart';

abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAnalytics extends AnalyticsEvent {
  final String? vehicleId; // null = all vehicles
  final int periodDays;

  const LoadAnalytics({this.vehicleId, this.periodDays = 30});

  @override
  List<Object?> get props => [vehicleId, periodDays];
}

class ChangeAnalyticsPeriod extends AnalyticsEvent {
  final int periodDays;

  const ChangeAnalyticsPeriod(this.periodDays);

  @override
  List<Object?> get props => [periodDays];
}

class ChangeAnalyticsVehicle extends AnalyticsEvent {
  final String? vehicleId;

  const ChangeAnalyticsVehicle(this.vehicleId);

  @override
  List<Object?> get props => [vehicleId];
}
