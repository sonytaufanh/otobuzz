import 'package:equatable/equatable.dart';

abstract class MileageEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AddMileage extends MileageEvent {
  final String vehicleId;
  final double km;
  final DateTime date;
  final String? notes;
  final bool replaceDuplicate;

  AddMileage({
    required this.vehicleId,
    required this.km,
    required this.date,
    this.notes,
    this.replaceDuplicate = false,
  });

  @override
  List<Object?> get props => [vehicleId, km, date, notes, replaceDuplicate];
}

class LoadMileageHistory extends MileageEvent {
  final String vehicleId;
  final DateTime? from;
  final DateTime? to;

  LoadMileageHistory({required this.vehicleId, this.from, this.to});

  @override
  List<Object?> get props => [vehicleId, from, to];
}

class CheckDuplicateEntry extends MileageEvent {
  final String vehicleId;
  final DateTime date;

  CheckDuplicateEntry({required this.vehicleId, required this.date});

  @override
  List<Object?> get props => [vehicleId, date];
}
