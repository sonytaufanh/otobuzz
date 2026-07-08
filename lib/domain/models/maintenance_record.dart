import 'package:equatable/equatable.dart';
import 'maintenance_type.dart';

class MaintenanceRecord extends Equatable {
  final String id;
  final String vehicleId;
  final MaintenanceType type;
  final double mileageAtService;
  final DateTime serviceDate;
  final double? cost;
  final String? notes;
  final String? workshopName;
  final int? workshopRating; // 1-5 bintang
  final String? workshopReview;

  const MaintenanceRecord({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.mileageAtService,
    required this.serviceDate,
    this.cost,
    this.notes,
    this.workshopName,
    this.workshopRating,
    this.workshopReview,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'type': type.index,
      'mileageAtService': mileageAtService,
      'serviceDate': serviceDate.toIso8601String(),
      'cost': cost,
      'notes': notes,
      'workshopName': workshopName,
      'workshopRating': workshopRating,
      'workshopReview': workshopReview,
    };
  }

  factory MaintenanceRecord.fromMap(Map<String, dynamic> map) {
    return MaintenanceRecord(
      id: map['id'] as String,
      vehicleId: map['vehicleId'] as String,
      type: MaintenanceType.values[map['type'] as int],
      mileageAtService: (map['mileageAtService'] as num).toDouble(),
      serviceDate: DateTime.parse(map['serviceDate'] as String),
      cost: map['cost'] != null ? (map['cost'] as num).toDouble() : null,
      notes: map['notes'] as String?,
      workshopName: map['workshopName'] as String?,
      workshopRating: map['workshopRating'] as int?,
      workshopReview: map['workshopReview'] as String?,
    );
  }

  MaintenanceRecord copyWith({
    String? id,
    String? vehicleId,
    MaintenanceType? type,
    double? mileageAtService,
    DateTime? serviceDate,
    double? cost,
    String? notes,
    String? workshopName,
    int? workshopRating,
    String? workshopReview,
  }) {
    return MaintenanceRecord(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      type: type ?? this.type,
      mileageAtService: mileageAtService ?? this.mileageAtService,
      serviceDate: serviceDate ?? this.serviceDate,
      cost: cost ?? this.cost,
      notes: notes ?? this.notes,
      workshopName: workshopName ?? this.workshopName,
      workshopRating: workshopRating ?? this.workshopRating,
      workshopReview: workshopReview ?? this.workshopReview,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vehicleId,
        type,
        mileageAtService,
        serviceDate,
        cost,
        notes,
        workshopName,
        workshopRating,
        workshopReview,
      ];
}
