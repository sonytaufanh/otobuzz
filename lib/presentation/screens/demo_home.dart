import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/checklist_repository.dart';
import '../../data/repositories/custom_interval_repository.dart';
import '../../data/repositories/driver_assignment_repository.dart';
import '../../data/repositories/driver_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/fuel_repository.dart';
import '../../domain/models/maintenance_record.dart';
import '../../domain/models/maintenance_schedule.dart';
import '../../domain/models/maintenance_type.dart';
import '../../domain/models/mileage_record.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/models/vehicle_type.dart';
import '../../domain/repositories/maintenance_history_repository.dart';
import '../../domain/repositories/mileage_repository.dart';
import '../blocs/vehicle/vehicle_bloc.dart';
import '../blocs/vehicle/vehicle_event.dart';
import '../blocs/vehicle/vehicle_state.dart';
import 'add_km_screen.dart';
import 'analytics_screen.dart';
import 'backup_restore_screen.dart';
import 'budget_screen.dart';
import 'cost_report_screen.dart';
import 'daily_checklist_screen.dart';
import 'driver_list_screen.dart';
import 'expense_screen.dart';
import 'fuel_screen.dart';
import 'gas_station_map_screen.dart';
import 'maintenance_history_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'vehicle_detail_screen.dart';
import 'vehicle_form_screen.dart';

class DemoHomeScreen extends StatefulWidget {
  const DemoHomeScreen({super.key});

  @override
  State<DemoHomeScreen> createState() => _DemoHomeScreenState();
}

class _DemoHomeScreenState extends State<DemoHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load vehicles on start
    context.read<VehicleBloc>().add(LoadVehicles());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            const _BerandaTab(),
            const AnalyticsScreen(),
            const SizedBox(), // placeholder for FAB
            const _VehicleListTab(),
            const _LainnyaTab(),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showQuickActions(context),
          elevation: 0,
          backgroundColor: Colors.transparent,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 8,
        color: Colors.white,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(
                icon: Icons.dashboard,
                label: 'Beranda',
                isActive: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _BottomNavItem(
                icon: Icons.bar_chart,
                label: 'Statistik',
                isActive: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              const SizedBox(width: 48),
              _BottomNavItem(
                icon: Icons.directions_car,
                label: 'Kendaraan',
                isActive: _currentIndex == 3,
                onTap: () => setState(() => _currentIndex = 3),
              ),
              _BottomNavItem(
                icon: Icons.grid_view_rounded,
                label: 'Lainnya',
                isActive: _currentIndex == 4,
                onTap: () => setState(() => _currentIndex = 4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Aksi Cepat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _QuickActionSheetItem(
                  icon: Icons.add_road,
                  label: 'Input KM',
                  color: AppTheme.primaryColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AddKmScreen()));
                  },
                ),
                _QuickActionSheetItem(
                  icon: Icons.build,
                  label: 'Catat Servis',
                  color: AppTheme.secondaryColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AnalyticsScreen()));
                  },
                ),
                _QuickActionSheetItem(
                  icon: Icons.local_gas_station,
                  label: 'Isi BBM',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FuelScreen()));
                  },
                ),
                _QuickActionSheetItem(
                  icon: Icons.directions_car,
                  label: 'Tambah\nKendaraan',
                  color: const Color(0xFF43A047),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const VehicleFormScreen()));
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BERANDA TAB (Main Home Content) — Connected to real data
// ============================================================

class _BerandaTab extends StatefulWidget {
  const _BerandaTab();

  @override
  State<_BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<_BerandaTab> {
  double _monthlyCost = 0;
  double _monthlyFuelCost = 0;
  double _fuelEfficiency = 0;
  List<MileageRecord> _recentMileage = [];
  List<MaintenanceRecord> _recentMaintenance = [];
  bool _summaryLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadMonthlySummary();
  }

  Future<void> _loadMonthlySummary() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    // Capture repos before async gap
    final historyRepo = context.read<MaintenanceHistoryRepository>();
    final fuelRepo = context.read<FuelRepository>();
    final mileageRepo = context.read<MileageRepository>();
    final vehicleBloc = context.read<VehicleBloc>();

    try {
      // Monthly maintenance cost
      final records =
          await historyRepo.getRecordsByDateRange(startOfMonth, now);
      final cost =
          records.fold<double>(0, (sum, r) => sum + (r.cost ?? 0));

      // Monthly fuel cost
      final fuelRecords =
          await fuelRepo.getAllFuelRecordsByPeriod(startOfMonth, now);
      final fuelCost =
          fuelRecords.fold<double>(0, (sum, r) => sum + r.totalCost);

      // Fuel efficiency — average across all vehicles with data
      double totalEfficiency = 0;
      int vehiclesWithData = 0;
      final vehicleState = vehicleBloc.state;
      if (vehicleState is VehicleLoaded) {
        for (final v in vehicleState.vehicles) {
          final stats = await fuelRepo.getStatistics(v.id);
          if (stats.averageKmPerLiter > 0) {
            totalEfficiency += stats.averageKmPerLiter;
            vehiclesWithData++;
          }
        }
      }

      // Recent mileage records (last 5)
      final mileageRecords = await mileageRepo.getRecordsByDateRange(
          now.subtract(const Duration(days: 7)), now);
      mileageRecords.sort((a, b) => b.date.compareTo(a.date));

      // Recent maintenance records (last 5)
      final maintenanceRecords =
          await historyRepo.getRecordsByDateRange(
              now.subtract(const Duration(days: 30)), now);
      maintenanceRecords.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));

      if (mounted) {
        setState(() {
          _monthlyCost = cost;
          _monthlyFuelCost = fuelCost;
          _fuelEfficiency = vehiclesWithData > 0
              ? totalEfficiency / vehiclesWithData
              : 0;
          _recentMileage = mileageRecords.take(5).toList();
          _recentMaintenance = maintenanceRecords.take(5).toList();
          _summaryLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _summaryLoaded = true);
      }
    }
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return 'Rp ${(value / 1000000).toStringAsFixed(1)}jt';
    } else if (value >= 1000) {
      return 'Rp ${(value / 1000).toStringAsFixed(0)}rb';
    }
    return 'Rp ${value.toStringAsFixed(0)}';
  }

  String _formatKm(double km) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return '${formatter.format(km.round())} km';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleBloc, VehicleState>(
      builder: (context, state) {
        // Extract data from state
        List<Vehicle> vehicles = [];
        int overdueCount = 0;
        double totalKm = 0;
        List<MaintenanceSchedule> urgentSchedules = [];
        Map<String, List<MaintenanceSchedule>> scheduleMap = {};

        if (state is VehicleLoaded) {
          vehicles = state.vehicles;
          overdueCount = state.overdueCount;
          totalKm = vehicles.fold<double>(
              0, (sum, v) => sum + v.totalMileageKm);
          scheduleMap = state.vehicleSchedules;

          // Gather urgent schedules (overdue + upcoming within 30 days)
          for (final v in vehicles) {
            final schedules = scheduleMap[v.id] ?? [];
            for (final s in schedules) {
              if (s.isOverdue || s.remainingDays <= 30) {
                urgentSchedules.add(s);
              }
            }
          }
          urgentSchedules.sort((a, b) {
            if (a.isOverdue && !b.isOverdue) return -1;
            if (!a.isOverdue && b.isOverdue) return 1;
            return a.remainingKm.compareTo(b.remainingKm);
          });
        }

        final isLoading = state is VehicleLoading;

        return RefreshIndicator(
          onRefresh: () async {
            context.read<VehicleBloc>().add(LoadVehicles());
            await _loadMonthlySummary();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('OB',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Halo!',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A2E))),
                          Text('Dashboard Armada',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500)),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SearchScreen())),
                        child: Icon(Icons.search,
                            color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 16),
                      Stack(
                        children: [
                          Icon(Icons.notifications_outlined,
                              color: Colors.grey.shade600),
                          if (urgentSchedules.isNotEmpty)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // HERO CARD
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF0097A7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF1565C0).withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Kilometer Armada',
                            style: TextStyle(
                                fontSize: 12, color: Colors.white70)),
                        const SizedBox(height: 4),
                        isLoading
                            ? _buildShimmerBox(width: 200, height: 36)
                            : Text(_formatKm(totalKm),
                                style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _HeroStatPill(
                              icon: Icons.directions_car,
                              value: '${vehicles.length}',
                              label: 'Kendaraan',
                            ),
                            const SizedBox(width: 8),
                            _HeroStatPill(
                              icon: Icons.check_circle,
                              value:
                                  '${vehicles.length - overdueCount}',
                              label: 'Tepat Waktu',
                            ),
                            const SizedBox(width: 8),
                            _HeroStatPill(
                              icon: Icons.warning_rounded,
                              value: '$overdueCount',
                              label: 'Terlambat',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3 QUICK ACTION BUTTONS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.add_road,
                          label: 'Input KM',
                          color: AppTheme.primaryColor,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AddKmScreen())),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.build,
                          label: 'Catat Servis',
                          color: AppTheme.secondaryColor,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const AnalyticsScreen())),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.local_gas_station,
                          label: 'Isi BBM',
                          color: const Color(0xFFFF8F00),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const FuelScreen())),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // PERAWATAN SEGERA
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text('Perawatan Segera',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E))),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                            '${urgentSchedules.length}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.red)),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const AnalyticsScreen())),
                        child: Text('Lihat Semua →',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: urgentSchedules.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: Text('Semua perawatan tepat waktu ✓',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF43A047),
                                      fontWeight: FontWeight.w500)),
                            ),
                          )
                        : Column(
                            children: _buildScheduleItems(
                                urgentSchedules.take(3).toList(),
                                vehicles),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // RINGKASAN BULAN INI
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text('Ringkasan Bulan Ini',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E))),
                      const Spacer(),
                      Text(
                          DateFormat('MMMM yyyy', 'id_ID')
                              .format(DateTime.now()),
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.6,
                    children: [
                      _SummaryMetricCard(
                        icon: Icons.build_circle,
                        iconColor: const Color(0xFF1565C0),
                        value: _summaryLoaded
                            ? _formatCurrency(_monthlyCost)
                            : '-',
                        label: 'Perawatan',
                      ),
                      _SummaryMetricCard(
                        icon: Icons.local_gas_station,
                        iconColor: const Color(0xFFFF8F00),
                        value: _summaryLoaded
                            ? _formatCurrency(_monthlyFuelCost)
                            : '-',
                        label: 'BBM',
                      ),
                      _SummaryMetricCard(
                        icon: Icons.speed,
                        iconColor: AppTheme.secondaryColor,
                        value: _summaryLoaded && _fuelEfficiency > 0
                            ? '${_fuelEfficiency.toStringAsFixed(1)} km/L'
                            : '-',
                        label: 'Efisiensi',
                      ),
                      _SummaryMetricCard(
                        icon: Icons.shield,
                        iconColor: const Color(0xFF43A047),
                        value: _calculateFleetScore(
                            vehicles, overdueCount),
                        label: 'Skor Armada',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // AKTIVITAS TERBARU
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text('Aktivitas Terbaru',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E))),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          if (vehicles.isNotEmpty) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        MaintenanceHistoryScreen(
                                            vehicle: vehicles.first)));
                          }
                        },
                        child: Text('Lihat Semua →',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _buildActivityList(vehicles),
                  ),
                ),
                const SizedBox(height: 24),

                // TIPS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE7F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tips: Ganti oli tepat waktu bisa hemat BBM hingga 5%',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildScheduleItems(
      List<MaintenanceSchedule> schedules, List<Vehicle> vehicles) {
    final widgets = <Widget>[];
    for (int i = 0; i < schedules.length; i++) {
      final s = schedules[i];
      final vehicle =
          vehicles.where((v) => v.id == s.vehicleId).firstOrNull;
      final vehicleName = vehicle?.name ?? '-';
      final remaining = s.isOverdue
          ? 'Terlambat ${s.remainingKm.abs().toStringAsFixed(0)} km'
          : 'Sisa ${NumberFormat('#,###', 'id_ID').format(s.remainingKm.round())} km';

      widgets.add(_MaintenanceCompactItem(
        isOverdue: s.isOverdue,
        type: s.type.displayName,
        vehicle: vehicleName,
        remaining: remaining,
      ));
      if (i < schedules.length - 1) {
        widgets.add(const Divider(height: 16, thickness: 0.5));
      }
    }
    return widgets;
  }

  Widget _buildActivityList(List<Vehicle> vehicles) {
    final activities = <Widget>[];

    // Combine mileage and maintenance into activity items
    final allActivities = <_ActivityData>[];

    for (final m in _recentMileage) {
      final vehicle =
          vehicles.where((v) => v.id == m.vehicleId).firstOrNull;
      allActivities.add(_ActivityData(
        color: AppTheme.primaryColor,
        text: 'Input KM - ${vehicle?.name ?? '-'} - ${m.km.toStringAsFixed(0)}km',
        date: m.date,
      ));
    }

    for (final r in _recentMaintenance) {
      final vehicle =
          vehicles.where((v) => v.id == r.vehicleId).firstOrNull;
      allActivities.add(_ActivityData(
        color: AppTheme.secondaryColor,
        text: '${r.type.displayName} - ${vehicle?.name ?? '-'}',
        date: r.serviceDate,
      ));
    }

    allActivities.sort((a, b) => b.date.compareTo(a.date));
    final displayActivities = allActivities.take(3).toList();

    if (displayActivities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text('Belum ada aktivitas',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
        ),
      );
    }

    for (int i = 0; i < displayActivities.length; i++) {
      final a = displayActivities[i];
      activities.add(_ActivityCompactRow(
        color: a.color,
        text: a.text,
        time: _timeAgo(a.date),
      ));
      if (i < displayActivities.length - 1) {
        activities.add(const Divider(height: 16, thickness: 0.5));
      }
    }
    return Column(children: activities);
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';
    return DateFormat('dd/MM').format(date);
  }

  String _calculateFleetScore(List<Vehicle> vehicles, int overdueCount) {
    if (vehicles.isEmpty) return '-';
    // Simple score: 100 - (overdue vehicles * 15)
    final score = (100 - (overdueCount * 15)).clamp(0, 100);
    return '$score';
  }

  Widget _buildShimmerBox({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

// ============================================================
// VEHICLE LIST TAB (Tab 3 "Kendaraan")
// ============================================================

class _VehicleListTab extends StatelessWidget {
  const _VehicleListTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleBloc, VehicleState>(
      builder: (context, state) {
        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                children: [
                  const Text('Kendaraan Saya',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E))),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const VehicleFormScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('Tambah',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Kelola semua kendaraan Anda',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade500)),
              ),
            ),
            // Content
            Expanded(
              child: _buildVehicleContent(context, state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVehicleContent(BuildContext context, VehicleState state) {
    if (state is VehicleLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is VehicleLoaded) {
      if (state.vehicles.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.directions_car_outlined,
                  size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('Belum ada kendaraan',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              Text('Tambahkan kendaraan pertama Anda',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade400)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const VehicleFormScreen())),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Kendaraan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: state.vehicles.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final vehicle = state.vehicles[index];
          return _VehicleListItem(
            vehicle: vehicle,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => VehicleDetailScreen(
                          vehicle: vehicle,
                          customIntervalRepository:
                              context.read<CustomIntervalRepository>(),
                          driverRepository:
                              context.read<DriverRepository>(),
                          driverAssignmentRepository:
                              context.read<DriverAssignmentRepository>(),
                        ))),
          );
        },
      );
    }

    // Error or initial
    return const Center(child: Text('Memuat...'));
  }
}

class _VehicleListItem extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;

  const _VehicleListItem({required this.vehicle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                vehicle.type == VehicleType.car
                    ? Icons.directions_car
                    : Icons.two_wheeler,
                color: AppTheme.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vehicle.name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                      '${vehicle.plateNumber} • ${NumberFormat('#,###', 'id_ID').format(vehicle.totalMileageKm.round())} km',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// LAINNYA TAB (Grid Menu) — with real navigation
// ============================================================

class _LainnyaTab extends StatelessWidget {
  const _LainnyaTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Text('Menu Lainnya',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Text('Akses semua fitur Otobuzz',
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.9,
              children: [
                _MenuGridItem(
                  icon: Icons.map,
                  label: 'SPBU\nTerdekat',
                  color: const Color(0xFFE53935),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const GasStationMapScreen())),
                ),
                _MenuGridItem(
                  icon: Icons.receipt_long,
                  label: 'Pengeluaran',
                  color: const Color(0xFF1565C0),
                  onTap: () => _navigateWithVehicleSelector(
                      context, _MenuAction.expense),
                ),
                _MenuGridItem(
                  icon: Icons.account_balance_wallet,
                  label: 'Budget',
                  color: const Color(0xFFFF8F00),
                  onTap: () {
                    final state = context.read<VehicleBloc>().state;
                    final vehicles = state is VehicleLoaded
                        ? state.vehicles
                        : <Vehicle>[];
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => BudgetScreen(
                                  budgetRepository:
                                      context.read<BudgetRepository>(),
                                  vehicles: vehicles,
                                )));
                  },
                ),
                _MenuGridItem(
                  icon: Icons.person,
                  label: 'Driver',
                  color: const Color(0xFF5E35B1),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => DriverListScreen(
                              driverRepository:
                                  context.read<DriverRepository>()))),
                ),
                _MenuGridItem(
                  icon: Icons.checklist,
                  label: 'Checklist',
                  color: const Color(0xFF00897B),
                  onTap: () => _navigateWithVehicleSelector(
                      context, _MenuAction.checklist),
                ),
                _MenuGridItem(
                  icon: Icons.description,
                  label: 'Pajak &\nSTNK',
                  color: const Color(0xFF6D4C41),
                  onTap: () => _navigateWithVehicleSelector(
                      context, _MenuAction.documents),
                ),
                _MenuGridItem(
                  icon: Icons.smart_toy,
                  label: 'AI\nAssistant',
                  color: const Color(0xFF0288D1),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen())),
                ),
                _MenuGridItem(
                  icon: Icons.cloud_upload,
                  label: 'Backup &\nRestore',
                  color: const Color(0xFF43A047),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BackupRestoreScreen())),
                ),
                _MenuGridItem(
                  icon: Icons.picture_as_pdf,
                  label: 'Export\nPDF',
                  color: const Color(0xFFD32F2F),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CostReportScreen())),
                ),
                _MenuGridItem(
                  icon: Icons.settings,
                  label: 'Pengaturan',
                  color: const Color(0xFF546E7A),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _navigateWithVehicleSelector(
      BuildContext context, _MenuAction action) {
    final state = context.read<VehicleBloc>().state;
    if (state is! VehicleLoaded || state.vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tambahkan kendaraan terlebih dahulu')),
      );
      return;
    }

    final vehicles = state.vehicles;

    // If only 1 vehicle, navigate directly
    if (vehicles.length == 1) {
      _navigateToAction(context, vehicles.first, action);
      return;
    }

    // Show vehicle selector bottom sheet
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Pilih Kendaraan',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...vehicles.map((v) => ListTile(
                  leading: Icon(
                    v.type == VehicleType.car
                        ? Icons.directions_car
                        : Icons.two_wheeler,
                    color: AppTheme.primaryColor,
                  ),
                  title: Text(v.name),
                  subtitle: Text(v.plateNumber),
                  onTap: () {
                    Navigator.pop(ctx);
                    _navigateToAction(context, v, action);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _navigateToAction(
      BuildContext context, Vehicle vehicle, _MenuAction action) {
    switch (action) {
      case _MenuAction.expense:
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ExpenseScreen(
                      vehicle: vehicle,
                      expenseRepository:
                          context.read<ExpenseRepository>(),
                    )));
        break;
      case _MenuAction.checklist:
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => DailyChecklistScreen(
                      vehicle: vehicle,
                      checklistRepository:
                          context.read<ChecklistRepository>(),
                    )));
        break;
      case _MenuAction.documents:
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => VehicleDetailScreen(
                      vehicle: vehicle,
                      customIntervalRepository:
                          context.read<CustomIntervalRepository>(),
                      driverRepository:
                          context.read<DriverRepository>(),
                      driverAssignmentRepository:
                          context.read<DriverAssignmentRepository>(),
                    )));
        break;
    }
  }
}

enum _MenuAction { expense, checklist, documents }

// ============================================================
// HELPER WIDGETS (unchanged visual design)
// ============================================================

/// Internal data class for activity list building
class _ActivityData {
  final Color color;
  final String text;
  final DateTime date;

  _ActivityData({
    required this.color,
    required this.text,
    required this.date,
  });
}

// Hero stat pill inside the gradient card
class _HeroStatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeroStatPill({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(width: 3),
            Flexible(
              child: Text(label,
                  style:
                      const TextStyle(fontSize: 9, color: Colors.white70),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

// Quick action button (rounded rectangle, solid color)
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// Compact maintenance item with colored dot
class _MaintenanceCompactItem extends StatelessWidget {
  final bool isOverdue;
  final String type;
  final String vehicle;
  final String remaining;

  const _MaintenanceCompactItem({
    required this.isOverdue,
    required this.type,
    required this.vehicle,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = isOverdue ? Colors.red : Colors.orange;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              Text(type,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Text('• $vehicle',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
        Text(remaining,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color:
                    isOverdue ? Colors.red : Colors.grey.shade600)),
      ],
    );
  }
}

// Summary metric card for 2x2 grid
class _SummaryMetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _SummaryMetricCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 2),
          Text(label,
              style:
                  TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

// Compact activity row
class _ActivityCompactRow extends StatelessWidget {
  final Color color;
  final String text;
  final String time;

  const _ActivityCompactRow({
    required this.color,
    required this.text,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        Text(time,
            style:
                TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }
}

// Menu grid item for Lainnya tab
class _MenuGridItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _MenuGridItem({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.3)),
          ],
        ),
      ),
    );
  }
}

// Quick action item in bottom sheet
class _QuickActionSheetItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionSheetItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// Bottom nav item
class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 22,
                color: isActive
                    ? AppTheme.primaryColor
                    : Colors.grey.shade400),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? AppTheme.primaryColor
                        : Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}
