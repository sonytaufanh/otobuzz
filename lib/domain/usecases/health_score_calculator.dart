import 'package:flutter/material.dart';
import '../../data/repositories/vehicle_document_repository.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import 'maintenance_calculator.dart';

/// Result of a vehicle health score calculation.
class HealthScoreResult {
  final int score;
  final String grade;
  final Color color;
  final String description;
  final List<String> issues;
  final List<String> recommendations;
  final HealthScoreBreakdown breakdown;

  const HealthScoreResult({
    required this.score,
    required this.grade,
    required this.color,
    required this.description,
    required this.issues,
    required this.recommendations,
    required this.breakdown,
  });
}

/// Detailed breakdown of how the score was calculated.
class HealthScoreBreakdown {
  final int baseScore;
  final int overduePenalty;
  final int warningPenalty;
  final int onTimeBonus;
  final int consistencyBonus;
  final int documentPenalty;
  final int overdueCount;
  final int warningCount;
  final int onTimeCount;
  final int kmLoggingStreak;
  final bool pajakExpired;
  final bool stnkExpired;

  const HealthScoreBreakdown({
    required this.baseScore,
    required this.overduePenalty,
    required this.warningPenalty,
    required this.onTimeBonus,
    required this.consistencyBonus,
    required this.documentPenalty,
    required this.overdueCount,
    required this.warningCount,
    required this.onTimeCount,
    required this.kmLoggingStreak,
    required this.pajakExpired,
    required this.stnkExpired,
  });
}

/// Calculates a health score (0-100) for a vehicle based on maintenance
/// status, document validity, and usage consistency.
class HealthScoreCalculator {
  final MaintenanceCalculator _maintenanceCalculator;
  final MileageRepository _mileageRepository;
  final VehicleDocumentRepository _documentRepository;
  final MaintenanceScheduleRepository _scheduleRepository;

  HealthScoreCalculator({
    required MaintenanceCalculator maintenanceCalculator,
    required MileageRepository mileageRepository,
    required VehicleDocumentRepository documentRepository,
    required MaintenanceScheduleRepository scheduleRepository,
  })  : _maintenanceCalculator = maintenanceCalculator,
        _mileageRepository = mileageRepository,
        _documentRepository = documentRepository,
        _scheduleRepository = scheduleRepository;

  /// Calculate health score for a single vehicle.
  Future<HealthScoreResult> calculateScore(Vehicle vehicle) async {
    // Get maintenance schedules
    final schedules = await _scheduleRepository.getSchedules(vehicle.id);

    // Get documents
    final documents = await _documentRepository.getDocuments(vehicle.id);

    // Get mileage history for last 14 days (to calculate logging streak)
    final now = DateTime.now();
    final fourteenDaysAgo = now.subtract(const Duration(days: 14));
    final mileageRecords = await _mileageRepository.getMileageHistory(
      vehicle.id,
      from: fourteenDaysAgo,
      to: now,
    );

    // Get maintenance intervals for warning zone calculation
    final applicableTypes =
        _maintenanceCalculator.getApplicableMaintenanceTypes(vehicle.type);

    // --- Calculate overdue items ---
    // Only consider schedules for applicable maintenance types
    final relevantSchedules = schedules
        .where((s) => applicableTypes.contains(s.type))
        .toList();
    final overdueSchedules = relevantSchedules.where((s) => s.isOverdue).toList();
    final int overdueCount = overdueSchedules.length;
    final int overduePenalty = overdueCount * 15;

    // --- Calculate warning zone items ---
    // Items not overdue but within warning threshold (remainingDays <= 30 or approaching)
    final warningSchedules = relevantSchedules
        .where((s) => !s.isOverdue && s.remainingDays <= 30)
        .toList();
    final int warningCount = warningSchedules.length;
    final int warningPenalty = warningCount * 5;

    // --- Calculate on-time bonus ---
    // Items that are well ahead of schedule (remaining > 50% of interval)
    int onTimeCount = 0;
    for (final schedule in relevantSchedules) {
      if (!schedule.isOverdue) {
        // Find the interval for this type
        final interval = _findInterval(schedule.type, vehicle.type);
        if (interval != null) {
          final halfInterval = interval.kmInterval / 2;
          if (schedule.remainingKm > halfInterval) {
            onTimeCount++;
          }
        }
      }
    }
    final int onTimeBonus = onTimeCount * 5;

    // --- Calculate consistency bonus ---
    // Count unique days with mileage records in last 14 days
    final Set<String> loggedDays = {};
    for (final record in mileageRecords) {
      final dayKey =
          '${record.date.year}-${record.date.month}-${record.date.day}';
      loggedDays.add(dayKey);
    }
    final int kmLoggingStreak = loggedDays.length;
    final int consistencyBonus = kmLoggingStreak >= 7 ? 10 : 0;

    // --- Calculate document penalties ---
    bool pajakExpired = false;
    bool stnkExpired = false;
    int documentPenalty = 0;

    for (final doc in documents) {
      if (doc.isExpired) {
        if (doc.documentType == DocumentType.pajak) {
          pajakExpired = true;
          documentPenalty += 10;
        } else if (doc.documentType == DocumentType.stnk) {
          stnkExpired = true;
          documentPenalty += 10;
        }
      }
    }

    // --- Calculate final score ---
    const int baseScore = 100;
    int rawScore = baseScore -
        overduePenalty -
        warningPenalty +
        onTimeBonus +
        consistencyBonus -
        documentPenalty;
    final int score = rawScore.clamp(0, 100);

    // --- Determine grade ---
    final grade = _getGrade(score);
    final color = _getColor(score);
    final description = _getDescription(score);

    // --- Build issues list ---
    final List<String> issues = [];
    for (final s in overdueSchedules) {
      issues.add('${_getTypeLabel(s.type)} sudah terlambat');
    }
    for (final s in warningSchedules) {
      issues.add('${_getTypeLabel(s.type)} akan segera jatuh tempo');
    }
    if (pajakExpired) {
      issues.add('Pajak kendaraan sudah expired');
    }
    if (stnkExpired) {
      issues.add('STNK kendaraan sudah expired');
    }

    // --- Build recommendations ---
    final List<String> recommendations = [];
    for (final s in overdueSchedules) {
      recommendations.add('Segera ${_getActionLabel(s.type)}');
    }
    if (pajakExpired) {
      recommendations.add('Perpanjang pajak kendaraan');
    }
    if (stnkExpired) {
      recommendations.add('Perpanjang STNK kendaraan');
    }
    if (kmLoggingStreak < 7) {
      recommendations.add(
          'Catat km harian secara rutin untuk bonus konsistensi');
    }
    for (final s in warningSchedules) {
      recommendations.add('Jadwalkan ${_getActionLabel(s.type)} dalam waktu dekat');
    }

    final breakdown = HealthScoreBreakdown(
      baseScore: baseScore,
      overduePenalty: overduePenalty,
      warningPenalty: warningPenalty,
      onTimeBonus: onTimeBonus,
      consistencyBonus: consistencyBonus,
      documentPenalty: documentPenalty,
      overdueCount: overdueCount,
      warningCount: warningCount,
      onTimeCount: onTimeCount,
      kmLoggingStreak: kmLoggingStreak,
      pajakExpired: pajakExpired,
      stnkExpired: stnkExpired,
    );

    return HealthScoreResult(
      score: score,
      grade: grade,
      color: color,
      description: description,
      issues: issues,
      recommendations: recommendations,
      breakdown: breakdown,
    );
  }

  /// Calculate average fleet health score for multiple vehicles.
  Future<HealthScoreResult> calculateFleetScore(
      List<Vehicle> vehicles) async {
    if (vehicles.isEmpty) {
      return const HealthScoreResult(
        score: 0,
        grade: 'F',
        color: Colors.red,
        description: 'Kritis',
        issues: ['Belum ada kendaraan'],
        recommendations: ['Tambahkan kendaraan untuk memulai'],
        breakdown: HealthScoreBreakdown(
          baseScore: 100,
          overduePenalty: 0,
          warningPenalty: 0,
          onTimeBonus: 0,
          consistencyBonus: 0,
          documentPenalty: 0,
          overdueCount: 0,
          warningCount: 0,
          onTimeCount: 0,
          kmLoggingStreak: 0,
          pajakExpired: false,
          stnkExpired: false,
        ),
      );
    }

    int totalScore = 0;
    final List<String> allIssues = [];
    final List<String> allRecommendations = [];

    for (final vehicle in vehicles) {
      final result = await calculateScore(vehicle);
      totalScore += result.score;
      allIssues.addAll(result.issues);
      allRecommendations.addAll(result.recommendations);
    }

    final int avgScore = (totalScore / vehicles.length).round();
    final grade = _getGrade(avgScore);
    final color = _getColor(avgScore);
    final description = _getDescription(avgScore);

    return HealthScoreResult(
      score: avgScore,
      grade: grade,
      color: color,
      description: description,
      issues: allIssues,
      recommendations: allRecommendations.toSet().toList(),
      breakdown: const HealthScoreBreakdown(
        baseScore: 100,
        overduePenalty: 0,
        warningPenalty: 0,
        onTimeBonus: 0,
        consistencyBonus: 0,
        documentPenalty: 0,
        overdueCount: 0,
        warningCount: 0,
        onTimeCount: 0,
        kmLoggingStreak: 0,
        pajakExpired: false,
        stnkExpired: false,
      ),
    );
  }

  // --- Helper methods ---

  MaintenanceInterval? _findInterval(
      MaintenanceType type, VehicleType vehicleType) {
    try {
      return defaultIntervals.firstWhere(
        (i) => i.type == type && i.vehicleType == vehicleType,
      );
    } catch (_) {
      return null;
    }
  }

  String _getGrade(int score) {
    if (score >= 90) return 'A';
    if (score >= 75) return 'B';
    if (score >= 60) return 'C';
    if (score >= 40) return 'D';
    return 'F';
  }

  Color _getColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.lightGreen;
    if (score >= 60) return Colors.amber;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getDescription(int score) {
    if (score >= 90) return 'Sangat Baik';
    if (score >= 75) return 'Baik';
    if (score >= 60) return 'Cukup';
    if (score >= 40) return 'Perlu Perhatian';
    return 'Kritis';
  }

  String _getTypeLabel(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.oilChange:
        return 'Ganti oli';
      case MaintenanceType.tireReplacement:
        return 'Ganti ban';
      case MaintenanceType.brakePads:
        return 'Ganti kampas rem';
      case MaintenanceType.airFilter:
        return 'Ganti filter udara';
      case MaintenanceType.sparkPlug:
        return 'Ganti busi';
      case MaintenanceType.chainLube:
        return 'Pelumas rantai';
      case MaintenanceType.coolant:
        return 'Ganti coolant';
      case MaintenanceType.brakeFluid:
        return 'Ganti minyak rem';
      case MaintenanceType.transmission:
        return 'Ganti oli transmisi';
    }
  }

  String _getActionLabel(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.oilChange:
        return 'ganti oli';
      case MaintenanceType.tireReplacement:
        return 'ganti ban';
      case MaintenanceType.brakePads:
        return 'ganti kampas rem';
      case MaintenanceType.airFilter:
        return 'ganti filter udara';
      case MaintenanceType.sparkPlug:
        return 'ganti busi';
      case MaintenanceType.chainLube:
        return 'lumasi rantai';
      case MaintenanceType.coolant:
        return 'ganti coolant';
      case MaintenanceType.brakeFluid:
        return 'ganti minyak rem';
      case MaintenanceType.transmission:
        return 'ganti oli transmisi';
    }
  }
}
