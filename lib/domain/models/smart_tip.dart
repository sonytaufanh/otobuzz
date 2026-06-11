import 'package:equatable/equatable.dart';

enum SmartTipCategory {
  maintenance,
  cost,
  usage,
  safety,
  efficiency,
  reminder,
}

extension SmartTipCategoryExtension on SmartTipCategory {
  String get displayName {
    switch (this) {
      case SmartTipCategory.maintenance:
        return 'Perawatan';
      case SmartTipCategory.cost:
        return 'Biaya';
      case SmartTipCategory.usage:
        return 'Penggunaan';
      case SmartTipCategory.safety:
        return 'Keselamatan';
      case SmartTipCategory.efficiency:
        return 'Efisiensi';
      case SmartTipCategory.reminder:
        return 'Pengingat';
    }
  }

  String get icon {
    switch (this) {
      case SmartTipCategory.maintenance:
        return '🔧';
      case SmartTipCategory.cost:
        return '💰';
      case SmartTipCategory.usage:
        return '📊';
      case SmartTipCategory.safety:
        return '⚠️';
      case SmartTipCategory.efficiency:
        return '⛽';
      case SmartTipCategory.reminder:
        return '🔔';
    }
  }
}

enum SmartTipPriority { high, medium, low }

extension SmartTipPriorityExtension on SmartTipPriority {
  String get displayName {
    switch (this) {
      case SmartTipPriority.high:
        return 'Penting';
      case SmartTipPriority.medium:
        return 'Perhatikan';
      case SmartTipPriority.low:
        return 'Info';
    }
  }

  int get sortOrder {
    switch (this) {
      case SmartTipPriority.high:
        return 0;
      case SmartTipPriority.medium:
        return 1;
      case SmartTipPriority.low:
        return 2;
    }
  }
}

class SmartTip extends Equatable {
  final String id;
  final SmartTipCategory category;
  final SmartTipPriority priority;
  final String title;
  final String description;
  final String? actionText;
  final String? vehicleId;
  final DateTime generatedAt;

  const SmartTip({
    required this.id,
    required this.category,
    required this.priority,
    required this.title,
    required this.description,
    this.actionText,
    this.vehicleId,
    required this.generatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        category,
        priority,
        title,
        description,
        actionText,
        vehicleId,
        generatedAt,
      ];
}
