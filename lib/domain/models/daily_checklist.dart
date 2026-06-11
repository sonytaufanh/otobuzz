import 'dart:convert';
import 'package:equatable/equatable.dart';

class ChecklistItem extends Equatable {
  final String name;
  final bool checked;
  final String? notes;

  const ChecklistItem({
    required this.name,
    this.checked = false,
    this.notes,
  });

  ChecklistItem copyWith({
    String? name,
    bool? checked,
    String? notes,
  }) {
    return ChecklistItem(
      name: name ?? this.name,
      checked: checked ?? this.checked,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item': name,
      'checked': checked,
      'notes': notes ?? '',
    };
  }

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      name: map['item'] as String,
      checked: map['checked'] as bool? ?? false,
      notes: (map['notes'] as String?)?.isEmpty == true ? null : map['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [name, checked, notes];
}

enum ChecklistStatus { ok, warning, critical }

extension ChecklistStatusExtension on ChecklistStatus {
  String get displayName {
    switch (this) {
      case ChecklistStatus.ok:
        return 'Semua Baik';
      case ChecklistStatus.warning:
        return 'Ada Masalah';
      case ChecklistStatus.critical:
        return 'Kritis';
    }
  }

  String get dbValue {
    switch (this) {
      case ChecklistStatus.ok:
        return 'ok';
      case ChecklistStatus.warning:
        return 'warning';
      case ChecklistStatus.critical:
        return 'critical';
    }
  }

  static ChecklistStatus fromDbValue(String value) {
    switch (value) {
      case 'ok':
        return ChecklistStatus.ok;
      case 'warning':
        return ChecklistStatus.warning;
      case 'critical':
        return ChecklistStatus.critical;
      default:
        return ChecklistStatus.ok;
    }
  }
}

class DailyChecklist extends Equatable {
  final String id;
  final String vehicleId;
  final String? driverId;
  final DateTime date;
  final List<ChecklistItem> items;
  final ChecklistStatus overallStatus;
  final String? notes;
  final DateTime createdAt;

  const DailyChecklist({
    required this.id,
    required this.vehicleId,
    this.driverId,
    required this.date,
    required this.items,
    required this.overallStatus,
    this.notes,
    required this.createdAt,
  });

  DailyChecklist copyWith({
    String? id,
    String? vehicleId,
    String? driverId,
    DateTime? date,
    List<ChecklistItem>? items,
    ChecklistStatus? overallStatus,
    String? notes,
    DateTime? createdAt,
  }) {
    return DailyChecklist(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      driverId: driverId ?? this.driverId,
      date: date ?? this.date,
      items: items ?? this.items,
      overallStatus: overallStatus ?? this.overallStatus,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'driverId': driverId,
      'date': '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'items': jsonEncode(items.map((i) => i.toMap()).toList()),
      'overallStatus': overallStatus.dbValue,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DailyChecklist.fromMap(Map<String, dynamic> map) {
    final itemsList = jsonDecode(map['items'] as String) as List;
    return DailyChecklist(
      id: map['id'] as String,
      vehicleId: map['vehicleId'] as String,
      driverId: map['driverId'] as String?,
      date: DateTime.parse(map['date'] as String),
      items: itemsList
          .map((item) => ChecklistItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      overallStatus: ChecklistStatusExtension.fromDbValue(map['overallStatus'] as String),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props =>
      [id, vehicleId, driverId, date, items, overallStatus, notes, createdAt];
}
