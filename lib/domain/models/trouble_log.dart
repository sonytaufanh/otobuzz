import 'package:equatable/equatable.dart';

enum TroubleSeverity {
  low,
  medium,
  high,
  critical,
}

extension TroubleSeverityExtension on TroubleSeverity {
  String get displayName {
    switch (this) {
      case TroubleSeverity.low:
        return 'Ringan';
      case TroubleSeverity.medium:
        return 'Sedang';
      case TroubleSeverity.high:
        return 'Tinggi';
      case TroubleSeverity.critical:
        return 'Kritis';
    }
  }

  String get emoji {
    switch (this) {
      case TroubleSeverity.low:
        return '🟢';
      case TroubleSeverity.medium:
        return '🟡';
      case TroubleSeverity.high:
        return '🟠';
      case TroubleSeverity.critical:
        return '🔴';
    }
  }
}

class TroubleLog extends Equatable {
  final String id;
  final String vehicleId;
  final String title;
  final String description;
  final TroubleSeverity severity;
  final DateTime reportedDate;
  final double? odometerKm;
  final bool isResolved;
  final DateTime? resolvedDate;
  final String? resolutionNotes;
  final String? maintenanceRecordId; // Link ke maintenance_records jika sudah diperbaiki

  const TroubleLog({
    required this.id,
    required this.vehicleId,
    required this.title,
    required this.description,
    required this.severity,
    required this.reportedDate,
    this.odometerKm,
    this.isResolved = false,
    this.resolvedDate,
    this.resolutionNotes,
    this.maintenanceRecordId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'title': title,
      'description': description,
      'severity': severity.index,
      'reportedDate': reportedDate.toIso8601String(),
      'odometerKm': odometerKm,
      'isResolved': isResolved ? 1 : 0,
      'resolvedDate': resolvedDate?.toIso8601String(),
      'resolutionNotes': resolutionNotes,
      'maintenanceRecordId': maintenanceRecordId,
    };
  }

  factory TroubleLog.fromMap(Map<String, dynamic> map) {
    return TroubleLog(
      id: map['id'] as String,
      vehicleId: map['vehicleId'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      severity: TroubleSeverity.values[map['severity'] as int],
      reportedDate: DateTime.parse(map['reportedDate'] as String),
      odometerKm: map['odometerKm'] != null ? (map['odometerKm'] as num).toDouble() : null,
      isResolved: (map['isResolved'] as int) == 1,
      resolvedDate: map['resolvedDate'] != null ? DateTime.parse(map['resolvedDate'] as String) : null,
      resolutionNotes: map['resolutionNotes'] as String?,
      maintenanceRecordId: map['maintenanceRecordId'] as String?,
    );
  }

  TroubleLog copyWith({
    String? id,
    String? vehicleId,
    String? title,
    String? description,
    TroubleSeverity? severity,
    DateTime? reportedDate,
    double? odometerKm,
    bool? isResolved,
    DateTime? resolvedDate,
    String? resolutionNotes,
    String? maintenanceRecordId,
  }) {
    return TroubleLog(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      title: title ?? this.title,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      reportedDate: reportedDate ?? this.reportedDate,
      odometerKm: odometerKm ?? this.odometerKm,
      isResolved: isResolved ?? this.isResolved,
      resolvedDate: resolvedDate ?? this.resolvedDate,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      maintenanceRecordId: maintenanceRecordId ?? this.maintenanceRecordId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vehicleId,
        title,
        description,
        severity,
        reportedDate,
        odometerKm,
        isResolved,
        resolvedDate,
        resolutionNotes,
        maintenanceRecordId,
      ];
}
