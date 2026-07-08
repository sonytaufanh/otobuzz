import 'package:equatable/equatable.dart';

enum ExpenseCategory {
  toll,
  parking,
  washing,
  insurance,
  tax,
  fine,
  accessory,
  other,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.toll:
        return 'Tol';
      case ExpenseCategory.parking:
        return 'Parkir';
      case ExpenseCategory.washing:
        return 'Cuci Kendaraan';
      case ExpenseCategory.insurance:
        return 'Asuransi';
      case ExpenseCategory.tax:
        return 'Pajak';
      case ExpenseCategory.fine:
        return 'Denda/Tilang';
      case ExpenseCategory.accessory:
        return 'Aksesoris';
      case ExpenseCategory.other:
        return 'Lainnya';
    }
  }

  String get iconName {
    switch (this) {
      case ExpenseCategory.toll:
        return 'toll';
      case ExpenseCategory.parking:
        return 'local_parking';
      case ExpenseCategory.washing:
        return 'local_car_wash';
      case ExpenseCategory.insurance:
        return 'security';
      case ExpenseCategory.tax:
        return 'receipt_long';
      case ExpenseCategory.fine:
        return 'gavel';
      case ExpenseCategory.accessory:
        return 'build';
      case ExpenseCategory.other:
        return 'more_horiz';
    }
  }
}

class ExpenseRecord extends Equatable {
  final String id;
  final String vehicleId;
  final ExpenseCategory category;
  final double amount;
  final DateTime date;
  final String? description;
  final String? notes;

  const ExpenseRecord({
    required this.id,
    required this.vehicleId,
    required this.category,
    required this.amount,
    required this.date,
    this.description,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'category': category.name,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'notes': notes,
    };
  }

  factory ExpenseRecord.fromMap(Map<String, dynamic> map) {
    return ExpenseRecord(
      id: map['id'] as String,
      vehicleId: map['vehicleId'] as String,
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ExpenseCategory.other,
      ),
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      description: map['description'] as String?,
      notes: map['notes'] as String?,
    );
  }

  ExpenseRecord copyWith({
    String? id,
    String? vehicleId,
    ExpenseCategory? category,
    double? amount,
    DateTime? date,
    String? description,
    String? notes,
  }) {
    return ExpenseRecord(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [id, vehicleId, category, amount, date, description, notes];
}
