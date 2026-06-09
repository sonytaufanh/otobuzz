import 'package:equatable/equatable.dart';

enum DocumentType { pajak, stnk }

class VehicleDocument extends Equatable {
  final String id;
  final String vehicleId;
  final DocumentType documentType;
  final DateTime expiryDate;
  final DateTime? lastPaidDate;
  final double? cost;
  final String? notes;

  const VehicleDocument({
    required this.id,
    required this.vehicleId,
    required this.documentType,
    required this.expiryDate,
    this.lastPaidDate,
    this.cost,
    this.notes,
  });

  VehicleDocument copyWith({
    String? id,
    String? vehicleId,
    DocumentType? documentType,
    DateTime? expiryDate,
    DateTime? lastPaidDate,
    double? cost,
    String? notes,
  }) {
    return VehicleDocument(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      documentType: documentType ?? this.documentType,
      expiryDate: expiryDate ?? this.expiryDate,
      lastPaidDate: lastPaidDate ?? this.lastPaidDate,
      cost: cost ?? this.cost,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'documentType': documentType.name,
      'expiryDate': expiryDate.toIso8601String(),
      'lastPaidDate': lastPaidDate?.toIso8601String(),
      'cost': cost,
      'notes': notes,
    };
  }

  factory VehicleDocument.fromMap(Map<String, dynamic> map) {
    return VehicleDocument(
      id: map['id'] as String,
      vehicleId: map['vehicleId'] as String,
      documentType: DocumentType.values.firstWhere(
        (e) => e.name == map['documentType'],
      ),
      expiryDate: DateTime.parse(map['expiryDate'] as String),
      lastPaidDate: map['lastPaidDate'] != null
          ? DateTime.parse(map['lastPaidDate'] as String)
          : null,
      cost: map['cost'] != null ? (map['cost'] as num).toDouble() : null,
      notes: map['notes'] as String?,
    );
  }

  /// Returns the number of days remaining until expiry (negative if expired)
  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  bool get isExpired => daysRemaining < 0;

  bool get isExpiringSoon => !isExpired && daysRemaining <= 30;

  String get documentTypeLabel =>
      documentType == DocumentType.pajak ? 'Pajak Kendaraan' : 'STNK';

  @override
  List<Object?> get props =>
      [id, vehicleId, documentType, expiryDate, lastPaidDate, cost, notes];
}
