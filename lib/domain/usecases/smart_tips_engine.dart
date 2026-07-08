import 'package:uuid/uuid.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/checklist_repository.dart';
import '../../data/repositories/fuel_repository.dart';
import '../../data/repositories/vehicle_document_repository.dart';
import '../models/maintenance_schedule.dart';
import '../models/maintenance_type.dart';
import '../models/smart_tip.dart';
import '../models/vehicle.dart';
import '../repositories/maintenance_history_repository.dart';
import '../repositories/maintenance_schedule_repository.dart';
import '../repositories/mileage_repository.dart';
import '../repositories/vehicle_repository.dart';

/// Rule-based recommendation engine that analyzes fleet data
/// and generates smart tips. Works 100% offline.
class SmartTipsEngine {
  final VehicleRepository vehicleRepository;
  final MileageRepository mileageRepository;
  final MaintenanceHistoryRepository maintenanceRepository;
  final MaintenanceScheduleRepository scheduleRepository;
  final FuelRepository fuelRepository;
  final ChecklistRepository checklistRepository;
  final BudgetRepository budgetRepository;
  final VehicleDocumentRepository documentRepository;

  static const _uuid = Uuid();

  SmartTipsEngine({
    required this.vehicleRepository,
    required this.mileageRepository,
    required this.maintenanceRepository,
    required this.scheduleRepository,
    required this.fuelRepository,
    required this.checklistRepository,
    required this.budgetRepository,
    required this.documentRepository,
  });

  /// Analyze all data and generate applicable tips.
  /// Returns sorted by priority (high first).
  Future<List<SmartTip>> generateTips() async {
    final vehicles = await vehicleRepository.getAllVehicles();
    if (vehicles.isEmpty) return [];

    final tips = <SmartTip>[];
    final now = DateTime.now();

    // Generate tips for each vehicle
    for (final vehicle in vehicles) {
      tips.addAll(await _generateMaintenanceTips(vehicle, now));
      tips.addAll(await _generateSafetyTips(vehicle, now));
      tips.addAll(await _generateUsageTips(vehicle, now));
      tips.addAll(await _generateEfficiencyTips(vehicle, now));
    }

    // Generate fleet-wide tips
    tips.addAll(await _generateCostTips(vehicles, now));
    tips.addAll(await _generateReminderTips(vehicles, now));

    // Sort by priority
    tips.sort((a, b) => a.priority.sortOrder.compareTo(b.priority.sortOrder));

    return tips;
  }

  // ===========================================================================
  // MAINTENANCE TIPS
  // ===========================================================================

  Future<List<SmartTip>> _generateMaintenanceTips(
      Vehicle vehicle, DateTime now) async {
    final tips = <SmartTip>[];
    final schedules = await scheduleRepository.getSchedules(vehicle.id);

    // Check for multiple overdue items
    final overdueSchedules =
        schedules.where((s) => s.isOverdue).toList();

    if (overdueSchedules.length >= 3) {
      final mostCritical = _getMostCriticalType(overdueSchedules);
      tips.add(SmartTip(
        id: _uuid.v4(),
        category: SmartTipCategory.maintenance,
        priority: SmartTipPriority.high,
        title: 'Banyak perawatan terlambat',
        description:
            'Kendaraan ${vehicle.name} punya ${overdueSchedules.length} perawatan terlambat. Prioritaskan yang paling kritis: ${mostCritical.displayName}',
        actionText: 'Lihat Jadwal',
        vehicleId: vehicle.id,
        generatedAt: now,
      ));
    }

    // Check oil change pattern (frequent late oil changes)
    final oilHistory = await maintenanceRepository.getHistory(
      vehicle.id,
      type: MaintenanceType.oilChange,
    );
    if (oilHistory.length >= 3) {
      final oilSchedule = schedules
          .where((s) => s.type == MaintenanceType.oilChange)
          .toList();
      if (oilSchedule.isNotEmpty && oilSchedule.first.isOverdue) {
        // Check if this is a pattern (overdue again)
        tips.add(SmartTip(
          id: _uuid.v4(),
          category: SmartTipCategory.maintenance,
          priority: SmartTipPriority.medium,
          title: 'Pola keterlambatan ganti oli',
          description:
              'Pola: ${vehicle.name} sering terlambat ganti oli. Pertimbangkan interval lebih pendek.',
          actionText: 'Atur Interval',
          vehicleId: vehicle.id,
          generatedAt: now,
        ));
      }
    }

    // Predict tire replacement based on daily km
    final avgDailyKm =
        await mileageRepository.getAverageDailyMileage(vehicle.id);
    if (avgDailyKm > 0) {
      final tireSchedule = schedules
          .where((s) => s.type == MaintenanceType.tireReplacement)
          .toList();
      if (tireSchedule.isNotEmpty && !tireSchedule.first.isOverdue) {
        final remainingKm = tireSchedule.first.remainingKm;
        if (remainingKm > 0 && remainingKm < 5000) {
          final daysUntilDue = (remainingKm / avgDailyKm).round();
          final estimatedDate = now.add(Duration(days: daysUntilDue));
          tips.add(SmartTip(
            id: _uuid.v4(),
            category: SmartTipCategory.maintenance,
            priority: SmartTipPriority.low,
            title: 'Prediksi ganti ban',
            description:
                'Waktu optimal ganti ban ${vehicle.name} berdasarkan km harian: sekitar ${_formatDate(estimatedDate)}',
            actionText: 'Lihat Detail',
            vehicleId: vehicle.id,
            generatedAt: now,
          ));
        }
      }
    }

    // V-Belt overdue — sangat kritis, bisa putus saat jalan
    final vbeltSchedule =
        schedules.where((s) => s.type == MaintenanceType.cvtVBelt).toList();
    if (vbeltSchedule.isNotEmpty && vbeltSchedule.first.isOverdue) {
      tips.add(SmartTip(
        id: _uuid.v4(),
        category: SmartTipCategory.maintenance,
        priority: SmartTipPriority.high,
        title: 'V-Belt melewati batas!',
        description:
            'V-Belt ${vehicle.name} sudah melewati batas penggantian. '
            'Risiko putus saat jalan — motor bisa langsung berhenti mendadak!',
        actionText: 'Lihat Jadwal',
        vehicleId: vehicle.id,
        generatedAt: now,
      ));
    }

    // Kampas kopling overdue
    final clutchSchedule = schedules
        .where((s) => s.type == MaintenanceType.clutchPlate)
        .toList();
    if (clutchSchedule.isNotEmpty && clutchSchedule.first.isOverdue) {
      tips.add(SmartTip(
        id: _uuid.v4(),
        category: SmartTipCategory.maintenance,
        priority: SmartTipPriority.high,
        title: 'Kampas kopling habis!',
        description:
            'Kampas kopling ${vehicle.name} sudah melewati batas. '
            'Kopling slip = tenaga tidak tersalur, boros BBM, dan berbahaya.',
        actionText: 'Lihat Jadwal',
        vehicleId: vehicle.id,
        generatedAt: now,
      ));
    }

    // Oli gardan overdue
    final gardanSchedule = schedules
        .where((s) => s.type == MaintenanceType.finalDriveOil)
        .toList();
    if (gardanSchedule.isNotEmpty && gardanSchedule.first.isOverdue) {
      tips.add(SmartTip(
        id: _uuid.v4(),
        category: SmartTipCategory.maintenance,
        priority: SmartTipPriority.medium,
        title: 'Oli gardan perlu diganti',
        description:
            'Oli gardan ${vehicle.name} sudah melewati jadwal. '
            'Gardan kering bisa menyebabkan suara berisik dan kerusakan permanen.',
        actionText: 'Lihat Jadwal',
        vehicleId: vehicle.id,
        generatedAt: now,
      ));
    }

    // CVT roller overdue
    final rollerSchedule = schedules
        .where((s) => s.type == MaintenanceType.cvtRoller)
        .toList();
    if (rollerSchedule.isNotEmpty && rollerSchedule.first.isOverdue) {
      tips.add(SmartTip(
        id: _uuid.v4(),
        category: SmartTipCategory.maintenance,
        priority: SmartTipPriority.medium,
        title: 'Roller CVT aus',
        description:
            'Roller CVT ${vehicle.name} sudah waktunya diganti. '
            'Roller gepeng membuat tarikan berat, akselerasi lambat, dan konsumsi BBM boros.',
        actionText: 'Lihat Jadwal',
        vehicleId: vehicle.id,
        generatedAt: now,
      ));
    }

    // Rantai perlu dilumasi
    final chainSchedule = schedules
        .where((s) => s.type == MaintenanceType.chainLube)
        .toList();
    if (chainSchedule.isNotEmpty && chainSchedule.first.isOverdue) {
      tips.add(SmartTip(
        id: _uuid.v4(),
        category: SmartTipCategory.maintenance,
        priority: SmartTipPriority.medium,
        title: 'Rantai perlu dilumasi',
        description:
            'Rantai ${vehicle.name} sudah waktunya dilumasi. '
            'Rantai kering cepat aus, berisik, dan bisa putus tiba-tiba.',
        actionText: 'Lihat Jadwal',
        vehicleId: vehicle.id,
        generatedAt: now,
      ));
    }

    // Aki perlu diganti
    final batterySchedule = schedules
        .where((s) => s.type == MaintenanceType.battery)
        .toList();
    if (batterySchedule.isNotEmpty && batterySchedule.first.isOverdue) {
      tips.add(SmartTip(
        id: _uuid.v4(),
        category: SmartTipCategory.maintenance,
        priority: SmartTipPriority.medium,
        title: 'Aki sudah tua',
        description:
            'Aki ${vehicle.name} sudah melewati usia pakai. '
            'Aki lemah bisa bikin motor tidak bisa distarter, terutama saat pagi atau hujan.',
        actionText: 'Lihat Jadwal',
        vehicleId: vehicle.id,
        generatedAt: now,
      ));
    }

    // Transmisi belum diatur — ingatkan user
    if (vehicle.transmissionType == null) {
      tips.add(SmartTip(
        id: _uuid.v4(),
        category: SmartTipCategory.maintenance,
        priority: SmartTipPriority.medium,
        title: 'Lengkapi data ${vehicle.name}',
        description:
            'Jenis transmisi ${vehicle.name} belum diatur. '
            'Jadwal perawatan CVT, rantai, dan kopling tidak akan muncul sampai transmisi dipilih.',
        actionText: 'Atur Sekarang',
        vehicleId: vehicle.id,
        generatedAt: now,
      ));
    }

    return tips;
  }

  // ===========================================================================
  // SAFETY TIPS
  // ===========================================================================

  Future<List<SmartTip>> _generateSafetyTips(
      Vehicle vehicle, DateTime now) async {
    final tips = <SmartTip>[];

    // Check checklist for brake issues
    final weekAgo = now.subtract(const Duration(days: 7));
    final checklists = await checklistRepository.getChecklistHistory(
      vehicle.id,
      from: weekAgo,
      to: now,
    );

    int brakeIssueCount = 0;
    for (final checklist in checklists) {
      for (final item in checklist.items) {
        if (item.name.toLowerCase().contains('rem') && !item.checked) {
          brakeIssueCount++;
        }
      }
    }

    if (brakeIssueCount >= 3) {
      tips.add(SmartTip(
        id: _uuid.v4(),
        category: SmartTipCategory.safety,
        priority: SmartTipPriority.high,
        title: 'Masalah rem terdeteksi!',
        description:
            'Checklist ${vehicle.name} menunjukkan masalah rem ${brakeIssueCount}x dalam seminggu. Segera periksa!',
        actionText: 'Lihat Checklist',
        vehicleId: vehicle.id,
        generatedAt: now,
      ));
    }

    // Check document expiry (STNK, Pajak)
    final documents = await documentRepository.getDocuments(vehicle.id);
    for (final doc in documents) {
      final daysUntilExpiry = doc.expiryDate.difference(now).inDays;
      if (daysUntilExpiry <= 7 && daysUntilExpiry > 0) {
        tips.add(SmartTip(
          id: _uuid.v4(),
          category: SmartTipCategory.safety,
          priority: SmartTipPriority.high,
          title: 'Dokumen segera expire',
          description:
              '${doc.documentTypeLabel} ${vehicle.name} expire dalam $daysUntilExpiry hari. Segera perpanjang.',
          actionText: 'Lihat Dokumen',
          vehicleId: vehicle.id,
          generatedAt: now,
        ));
      } else if (daysUntilExpiry <= 0) {
        tips.add(SmartTip(
          id: _uuid.v4(),
          category: SmartTipCategory.safety,
          priority: SmartTipPriority.high,
          title: 'Dokumen sudah expired!',
          description:
              '${doc.documentTypeLabel} ${vehicle.name} sudah expired ${(-daysUntilExpiry)} hari lalu. Segera perpanjang!',
          actionText: 'Lihat Dokumen',
          vehicleId: vehicle.id,
          generatedAt: now,
        ));
      }
    }

    // Check tire safety based on km
    final schedules = await scheduleRepository.getSchedules(vehicle.id);
    final tireSchedule = schedules
        .where((s) => s.type == MaintenanceType.tireReplacement)
        .toList();
    if (tireSchedule.isNotEmpty && tireSchedule.first.isOverdue) {
      tips.add(SmartTip(
        id: _uuid.v4(),
        category: SmartTipCategory.safety,
        priority: SmartTipPriority.high,
        title: 'Ban melewati batas aman',
        description:
            'Ban ${vehicle.name} sudah melewati batas aman berdasarkan km. Segera ganti!',
        actionText: 'Lihat Jadwal',
        vehicleId: vehicle.id,
        generatedAt: now,
      ));
    }

    return tips;
  }

  // ===========================================================================
  // USAGE TIPS
  // ===========================================================================

  Future<List<SmartTip>> _generateUsageTips(
      Vehicle vehicle, DateTime now) async {
    final tips = <SmartTip>[];

    // Check last mileage record date
    final recentMileage = await mileageRepository.getMileageHistory(
      vehicle.id,
      from: now.subtract(const Duration(days: 30)),
      to: now,
    );

    if (recentMileage.isEmpty) {
      // Vehicle not used in 30 days
      final allMileage = await mileageRepository.getMileageHistory(vehicle.id);
      if (allMileage.isNotEmpty) {
        final lastRecord = allMileage.first;
        final daysSinceUsed = now.difference(lastRecord.date).inDays;
        if (daysSinceUsed >= 14) {
          tips.add(SmartTip(
            id: _uuid.v4(),
            category: SmartTipCategory.usage,
            priority: SmartTipPriority.medium,
            title: 'Kendaraan tidak dipakai',
            description:
                'Kendaraan ${vehicle.name} belum dipakai $daysSinceUsed hari. Periksa kondisi aki dan ban.',
            actionText: 'Input KM',
            vehicleId: vehicle.id,
            generatedAt: now,
          ));
        }
      }
    } else {
      // Check for higher than usual daily km
      final avgDailyKm =
          await mileageRepository.getAverageDailyMileage(vehicle.id);
      final avgLast7Days = await mileageRepository.getAverageDailyMileage(
          vehicle.id,
          lastDays: 7);

      if (avgDailyKm > 0 && avgLast7Days > avgDailyKm * 1.5) {
        tips.add(SmartTip(
          id: _uuid.v4(),
          category: SmartTipCategory.usage,
          priority: SmartTipPriority.medium,
          title: 'Penggunaan lebih tinggi',
          description:
              '${vehicle.name} rata-rata ${avgLast7Days.round()}km/hari, lebih tinggi dari biasanya (${avgDailyKm.round()}km). Perawatan mungkin perlu lebih sering.',
          actionText: 'Lihat Riwayat',
          vehicleId: vehicle.id,
          generatedAt: now,
        ));
      }

      // Check for gaps in mileage recording
      final last7Days = await mileageRepository.getMileageHistory(
        vehicle.id,
        from: now.subtract(const Duration(days: 7)),
        to: now,
      );
      final missingDays = 7 - last7Days.length;
      if (missingDays >= 3) {
        tips.add(SmartTip(
          id: _uuid.v4(),
          category: SmartTipCategory.usage,
          priority: SmartTipPriority.low,
          title: 'KM belum dicatat',
          description:
              'KM harian ${vehicle.name} belum dicatat $missingDays hari. Input teratur membantu prediksi lebih akurat.',
          actionText: 'Input KM',
          vehicleId: vehicle.id,
          generatedAt: now,
        ));
      }
    }

    return tips;
  }

  // ===========================================================================
  // EFFICIENCY TIPS
  // ===========================================================================

  Future<List<SmartTip>> _generateEfficiencyTips(
      Vehicle vehicle, DateTime now) async {
    final tips = <SmartTip>[];

    // Analyze fuel consumption trend
    final currentMonth = DateTime(now.year, now.month, 1);
    final lastMonth = DateTime(now.year, now.month - 1, 1);

    final currentFuel = await fuelRepository.getFuelRecordsByPeriod(
      vehicle.id,
      currentMonth,
      now,
    );
    final lastFuel = await fuelRepository.getFuelRecordsByPeriod(
      vehicle.id,
      lastMonth,
      currentMonth,
    );

    if (currentFuel.length >= 2 && lastFuel.length >= 2) {
      final stats = await fuelRepository.getStatistics(vehicle.id);
      if (stats.trend == 'worsening') {
        tips.add(SmartTip(
          id: _uuid.v4(),
          category: SmartTipCategory.efficiency,
          priority: SmartTipPriority.medium,
          title: 'Konsumsi BBM menurun',
          description:
              'Konsumsi BBM ${vehicle.name} memburuk bulan ini. Kemungkinan masalah mesin atau tekanan ban kurang.',
          actionText: 'Lihat BBM',
          vehicleId: vehicle.id,
          generatedAt: now,
        ));
      }
    }

    return tips;
  }

  // ===========================================================================
  // COST TIPS (Fleet-wide)
  // ===========================================================================

  Future<List<SmartTip>> _generateCostTips(
      List<Vehicle> vehicles, DateTime now) async {
    final tips = <SmartTip>[];

    // Check budget status for each vehicle
    for (final vehicle in vehicles) {
      final budgetStatus = await budgetRepository.getBudgetStatus(
        vehicle.id,
        now.year,
        now.month,
      );

      if (budgetStatus != null && budgetStatus.percentage > 80) {
        tips.add(SmartTip(
          id: _uuid.v4(),
          category: SmartTipCategory.cost,
          priority: budgetStatus.percentage >= 100
              ? SmartTipPriority.high
              : SmartTipPriority.medium,
          title: 'Budget perawatan tinggi',
          description:
              'Total biaya armada ${vehicle.name} sudah ${budgetStatus.percentage.round()}% dari budget. Sisa budget: Rp ${_formatCurrency(budgetStatus.remaining)}',
          actionText: 'Lihat Budget',
          vehicleId: vehicle.id,
          generatedAt: now,
        ));
      }
    }

    // Check fleet-wide budget
    final fleetBudgetStatus = await budgetRepository.getBudgetStatus(
      null,
      now.year,
      now.month,
    );
    if (fleetBudgetStatus != null && fleetBudgetStatus.percentage > 80) {
      tips.add(SmartTip(
        id: _uuid.v4(),
        category: SmartTipCategory.cost,
        priority: fleetBudgetStatus.percentage >= 100
            ? SmartTipPriority.high
            : SmartTipPriority.medium,
        title: 'Budget armada hampir habis',
        description:
            'Total biaya armada sudah ${fleetBudgetStatus.percentage.round()}% dari budget bulanan. Sisa: Rp ${_formatCurrency(fleetBudgetStatus.remaining)}',
        actionText: 'Lihat Budget',
        generatedAt: now,
      ));
    }

    // Check maintenance cost trends per vehicle
    final monthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);

    for (final vehicle in vehicles) {
      final currentRecords =
          await maintenanceRepository.getRecordsByDateRange(
        monthStart,
        now,
        vehicleId: vehicle.id,
      );
      final lastMonthRecords =
          await maintenanceRepository.getRecordsByDateRange(
        lastMonthStart,
        monthStart,
        vehicleId: vehicle.id,
      );

      final currentCost =
          currentRecords.fold<double>(0, (s, r) => s + (r.cost ?? 0));
      final lastMonthCost =
          lastMonthRecords.fold<double>(0, (s, r) => s + (r.cost ?? 0));

      if (lastMonthCost > 0 && currentCost > lastMonthCost * 1.5) {
        tips.add(SmartTip(
          id: _uuid.v4(),
          category: SmartTipCategory.cost,
          priority: SmartTipPriority.medium,
          title: 'Biaya perawatan meningkat',
          description:
              'Bulan ini biaya perawatan ${vehicle.name} 50%+ lebih tinggi dari bulan lalu. Review pengeluaran.',
          actionText: 'Lihat Laporan',
          vehicleId: vehicle.id,
          generatedAt: now,
        ));
      }
    }

    // Find most used workshop
    final allRecords = await maintenanceRepository.getRecordsByDateRange(
      now.subtract(const Duration(days: 90)),
      now,
    );
    final workshopCount = <String, int>{};
    for (final record in allRecords) {
      if (record.workshopName != null && record.workshopName!.isNotEmpty) {
        workshopCount[record.workshopName!] =
            (workshopCount[record.workshopName!] ?? 0) + 1;
      }
    }
    if (workshopCount.isNotEmpty) {
      final topWorkshop =
          workshopCount.entries.reduce((a, b) => a.value > b.value ? a : b);
      if (topWorkshop.value >= 5) {
        tips.add(SmartTip(
          id: _uuid.v4(),
          category: SmartTipCategory.cost,
          priority: SmartTipPriority.low,
          title: 'Bengkel langganan',
          description:
              'Bengkel ${topWorkshop.key} paling sering digunakan (${topWorkshop.value}x). Pertimbangkan langganan untuk diskon.',
          generatedAt: now,
        ));
      }
    }

    return tips;
  }

  // ===========================================================================
  // REMINDER TIPS (Fleet-wide)
  // ===========================================================================

  Future<List<SmartTip>> _generateReminderTips(
      List<Vehicle> vehicles, DateTime now) async {
    final tips = <SmartTip>[];

    // Find days since last input across all vehicles
    int maxDaysSinceInput = 0;
    for (final vehicle in vehicles) {
      final records = await mileageRepository.getMileageHistory(vehicle.id);
      if (records.isNotEmpty) {
        final daysSince = now.difference(records.first.date).inDays;
        if (daysSince > maxDaysSinceInput) {
          maxDaysSinceInput = daysSince;
        }
      }
    }

    if (maxDaysSinceInput >= 3) {
      tips.add(SmartTip(
        id: _uuid.v4(),
        category: SmartTipCategory.reminder,
        priority: SmartTipPriority.medium,
        title: 'Jangan lupa catat KM!',
        description:
            'Sudah $maxDaysSinceInput hari tidak input KM. Jangan lupa catat!',
        actionText: 'Input KM',
        generatedAt: now,
      ));
    }

    // Check vehicles without checklist today
    final incompleteToday = await checklistRepository.getIncompleteToday();
    if (incompleteToday.isNotEmpty) {
      tips.add(SmartTip(
        id: _uuid.v4(),
        category: SmartTipCategory.reminder,
        priority: SmartTipPriority.medium,
        title: 'Checklist belum selesai',
        description:
            'Ada ${incompleteToday.length} kendaraan belum checklist hari ini',
        actionText: 'Isi Checklist',
        generatedAt: now,
      ));
    }

    // Fuel efficiency tip (general)
    if (vehicles.length >= 2) {
      final efficiencies = <String, double>{};
      for (final vehicle in vehicles) {
        final stats = await fuelRepository.getStatistics(vehicle.id);
        if (stats.averageKmPerLiter > 0) {
          efficiencies[vehicle.name] = stats.averageKmPerLiter;
        }
      }

      if (efficiencies.length >= 2) {
        final sorted = efficiencies.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final best = sorted.first;
        final worst = sorted.last;

        tips.add(SmartTip(
          id: _uuid.v4(),
          category: SmartTipCategory.efficiency,
          priority: SmartTipPriority.low,
          title: 'Perbandingan efisiensi BBM',
          description:
              'Paling hemat: ${best.key} (${best.value.toStringAsFixed(1)} km/liter). Paling boros: ${worst.key} (${worst.value.toStringAsFixed(1)} km/liter)',
          generatedAt: now,
        ));
      }
    }

    // General fuel tip
    tips.add(SmartTip(
      id: _uuid.v4(),
      category: SmartTipCategory.efficiency,
      priority: SmartTipPriority.low,
      title: 'Tips hemat BBM',
      description:
          'Tips: Tekanan ban optimal bisa hemat 5% BBM. Periksa tekanan ban secara rutin.',
      generatedAt: now,
    ));

    return tips;
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  MaintenanceType _getMostCriticalType(List<MaintenanceSchedule> schedules) {
    // Urutan prioritas kritis (paling berbahaya jika diabaikan di atas)
    const criticalOrder = [
      MaintenanceType.brakePads,
      MaintenanceType.brakeFluidFlush,
      MaintenanceType.tireReplacement,
      MaintenanceType.brakeFluid,
      MaintenanceType.suspension,
      MaintenanceType.wheelBearing,
      MaintenanceType.oilChange,
      MaintenanceType.cvtVBelt,
      MaintenanceType.clutchPlate,
      MaintenanceType.coolant,
      MaintenanceType.transmission,
      MaintenanceType.finalDriveOil,
      MaintenanceType.cvtClutchShoe,
      MaintenanceType.cvtDrivePlate,
      MaintenanceType.cvtRoller,
      MaintenanceType.cvtSpring,
      MaintenanceType.sparkPlug,
      MaintenanceType.airFilter,
      MaintenanceType.chainLube,
      MaintenanceType.chainAdjust,
      MaintenanceType.battery,
      MaintenanceType.valveAdjust,
      MaintenanceType.throttleBodyClean,
      MaintenanceType.injectorClean,
    ];

    for (final type in criticalOrder) {
      if (schedules.any((s) => s.type == type)) {
        return type;
      }
    }
    return schedules.first.type;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return amount.round().toString();
  }
}
