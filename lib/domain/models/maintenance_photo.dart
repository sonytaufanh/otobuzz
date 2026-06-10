import 'package:equatable/equatable.dart';

class MaintenancePhoto extends Equatable {
  final String id;
  final String maintenanceRecordId;
  final String photoPath;
  final DateTime createdAt;

  const MaintenancePhoto({
    required this.id,
    required this.maintenanceRecordId,
    required this.photoPath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'maintenanceRecordId': maintenanceRecordId,
      'photoPath': photoPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MaintenancePhoto.fromMap(Map<String, dynamic> map) {
    return MaintenancePhoto(
      id: map['id'] as String,
      maintenanceRecordId: map['maintenanceRecordId'] as String,
      photoPath: map['photoPath'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [id, maintenanceRecordId, photoPath, createdAt];
}
