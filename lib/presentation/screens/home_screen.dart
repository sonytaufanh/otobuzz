import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/page_transitions.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/checklist_repository.dart';
import '../../data/repositories/custom_interval_repository.dart';
import '../../data/repositories/driver_assignment_repository.dart';
import '../../data/repositories/driver_repository.dart';
import '../../data/repositories/fuel_repository.dart';
import '../../data/repositories/vehicle_document_repository.dart';
import '../../domain/models/maintenance_schedule.dart';
import '../../domain/models/maintenance_type.dart';
import '../../domain/models/smart_tip.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/models/vehicle_type.dart';
import '../../domain/repositories/maintenance_history_repository.dart';
import '../../domain/repositories/maintenance_schedule_repository.dart';
import '../../domain/repositories/mileage_repository.dart';
import '../../domain/usecases/health_score_calculator.dart';
import '../../domain/usecases/smart_tips_engine.dart';
import '../blocs/vehicle/vehicle_bloc.dart';
import '../blocs/vehicle/vehicle_event.dart';
import '../blocs/vehicle/vehicle_state.dart';
import '../widgets/shimmer_loading.dart';
import 'add_km_screen.dart';
import 'analytics_screen.dart';
import 'budget_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'smart_tips_screen.dart';
import 'vehicle_detail_screen.dart';
import 'vehicle_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<VehicleBloc>().add(LoadVehicles());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _DashboardTab(onSwitchTab: (i) => setState(() => _currentIndex = i)),
          const AnalyticsScreen(),
          const SizedBox(), // placeholder for FAB
          const _VehicleListTab(),
          const SettingsScreen(),
        ],
      ),
      floatingActionButton: _buildFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.4),
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
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
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
            const SizedBox(height: 20),
            Text(
              'Aksi Cepat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _QuickActionTile(
              icon: Icons.add_road_rounded,
              label: 'Input KM',
              color: AppTheme.primaryColor,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context,
                    SlideUpPageRoute(page: const AddKmScreen()));
              },
            ),
            _QuickActionTile(
              icon: Icons.build_rounded,
              label: 'Catat Servis',
              color: AppTheme.secondaryColor,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
              },
            ),
            _QuickActionTile(
              icon: Icons.directions_car_rounded,
              label: 'Tambah Kendaraan',
              color: AppTheme.accentColor,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const VehicleFormScreen()));
              },
            ),
            _QuickActionTile(
              icon: Icons.local_gas_station_rounded,
              label: 'Isi BBM',
              color: Colors.orange.shade700,
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _currentIndex = 1);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 8,
      color: Colors.white,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.dashboard,
              label: 'Beranda',
              isSelected: _currentIndex == 0,
              onTap: () {
                AppHaptics.lightImpact();
                setState(() => _currentIndex = 0);
              },
            ),
            _NavItem(
              icon: Icons.bar_chart_rounded,
              label: 'Statistik',
              isSelected: _currentIndex == 1,
              onTap: () {
                AppHaptics.lightImpact();
                setState(() => _currentIndex = 1);
              },
            ),
            const SizedBox(width: 48), // space for FAB
            _NavItem(
              icon: Icons.directions_car,
              label: 'Kendaraan',
              isSelected: _currentIndex == 3,
              onTap: () {
                AppHaptics.lightImpact();
                setState(() => _currentIndex = 3);
              },
            ),
            _NavItem(
              icon: Icons.settings,
              label: 'Profil',
              isSelected: _currentIndex == 4,
              onTap: () {
                AppHaptics.lightImpact();
                setState(() => _currentIndex = 4);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Bottom Nav Item
// =============================================================================

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? AppTheme.primaryColor
        : Colors.grey.shade400;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Quick Action Tile (Bottom Sheet)
// =============================================================================

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

// =============================================================================
// Tab 1: Dashboard (CatatUang-style information-dense)
// =============================================================================

class _DashboardTab extends StatefulWidget {
  final void Function(int) onSwitchTab;

  const _DashboardTab({required this.onSwitchTab});

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Async data
  HealthScoreResult? _fleetScore;
  double _monthlyCost = 0;
  double _avgFuelEfficiency = 0;
  List<MaintenanceSchedule> _upcomingSchedules = [];
  List<_ActivityItem> _recentActivities = [];
  List<SmartTip> _smartTips = [];
  List<_DailyKmData> _weeklyKm = [];
  String _topVehicleName = '';
  double _topVehicleKm = 0;
  double _budgetSpent = 0;
  double _budgetTotal = 0;
  int _alertCount = 0;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final vehicleBloc = context.read<VehicleBloc>();
    final state = vehicleBloc.state;
    if (state is! VehicleLoaded || state.vehicles.isEmpty) return;

    final vehicles = state.vehicles;
    final mileageRepo = context.read<MileageRepository>();
    final maintenanceRepo = context.read<MaintenanceHistoryRepository>();
    final scheduleRepo = context.read<MaintenanceScheduleRepository>();
    final fuelRepo = context.read<FuelRepository>();
    final budgetRepo = context.read<BudgetRepository>();
    final documentRepo = context.read<VehicleDocumentRepository>();
    final checklistRepo = context.read<ChecklistRepository>();

    // Fleet health score
    try {
      final calculator = HealthScoreCalculator(
        maintenanceCalculator: vehicleBloc.calculator,
        mileageRepository: mileageRepo,
        documentRepository: documentRepo,
        scheduleRepository: scheduleRepo,
      );
      _fleetScore = await calculator.calculateFleetScore(vehicles);
    } catch (_) {}

    // Monthly cost
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final records = await maintenanceRepo.getRecordsByDateRange(monthStart, now);
      _monthlyCost = records.fold<double>(0, (s, r) => s + (r.cost ?? 0));
    } catch (_) {}

    // Average fuel efficiency
    try {
      double totalEff = 0;
      int effCount = 0;
      for (final v in vehicles) {
        final stats = await fuelRepo.getStatistics(v.id);
        if (stats.averageKmPerLiter > 0) {
          totalEff += stats.averageKmPerLiter;
          effCount++;
        }
      }
      if (effCount > 0) _avgFuelEfficiency = totalEff / effCount;
    } catch (_) {}

    // Upcoming schedules (nearest 3, non-overdue)
    try {
      final allSchedules = <MaintenanceSchedule>[];
      for (final v in vehicles) {
        final schedules = await scheduleRepo.getSchedules(v.id);
        allSchedules.addAll(schedules.where((s) => !s.isOverdue));
      }
      allSchedules.sort((a, b) => a.remainingKm.compareTo(b.remainingKm));
      _upcomingSchedules = allSchedules.take(3).toList();
    } catch (_) {}

    // Recent activities (mileage + maintenance, last 5)
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 14));
      final mileageRecords =
          await mileageRepo.getRecordsByDateRange(weekAgo, now);
      final maintenanceRecords =
          await maintenanceRepo.getRecordsByDateRange(weekAgo, now);

      final activities = <_ActivityItem>[];
      for (final m in mileageRecords.take(5)) {
        final vehicle = vehicles.where((v) => v.id == m.vehicleId).firstOrNull;
        activities.add(_ActivityItem(
          icon: Icons.add_road_rounded,
          title: 'Input KM - ${vehicle?.name ?? "?"}',
          subtitle: '${m.km.round()} km',
          date: m.date,
          color: AppTheme.primaryColor,
        ));
      }
      for (final r in maintenanceRecords.take(5)) {
        final vehicle = vehicles.where((v) => v.id == r.vehicleId).firstOrNull;
        activities.add(_ActivityItem(
          icon: Icons.build_rounded,
          title: '${r.type.displayName} - ${vehicle?.name ?? "?"}',
          subtitle: r.cost != null ? 'Rp ${_formatCurrency(r.cost!)}' : '',
          date: r.serviceDate,
          color: AppTheme.secondaryColor,
        ));
      }
      activities.sort((a, b) => b.date.compareTo(a.date));
      _recentActivities = activities.take(5).toList();
    } catch (_) {}

    // Smart tips
    try {
      final engine = SmartTipsEngine(
        vehicleRepository: vehicleBloc.vehicleRepository,
        mileageRepository: mileageRepo,
        maintenanceRepository: maintenanceRepo,
        scheduleRepository: scheduleRepo,
        fuelRepository: fuelRepo,
        checklistRepository: checklistRepo,
        budgetRepository: budgetRepo,
        documentRepository: documentRepo,
      );
      _smartTips = (await engine.generateTips()).take(2).toList();
    } catch (_) {}

    // Weekly KM data (last 7 days)
    try {
      final now = DateTime.now();
      final weekData = <_DailyKmData>[];
      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final dayStart = DateTime(day.year, day.month, day.day);
        final dayEnd = dayStart.add(const Duration(days: 1));
        final records = await mileageRepo.getRecordsByDateRange(dayStart, dayEnd);
        final totalKm = records.fold<double>(0, (s, r) => s + r.km);
        weekData.add(_DailyKmData(
          day: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'][day.weekday - 1],
          km: totalKm,
        ));
      }
      _weeklyKm = weekData;
    } catch (_) {}

    // Top vehicle by km this month
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      double maxKm = 0;
      String maxName = '';
      for (final v in vehicles) {
        final records = await mileageRepo.getMileageHistory(
          v.id,
          from: monthStart,
          to: now,
        );
        final km = records.fold<double>(0, (s, r) => s + r.km);
        if (km > maxKm) {
          maxKm = km;
          maxName = v.name;
        }
      }
      _topVehicleName = maxName;
      _topVehicleKm = maxKm;
    } catch (_) {}

    // Budget status
    try {
      final now = DateTime.now();
      final status = await budgetRepo.getBudgetStatus(null, now.year, now.month);
      if (status != null) {
        _budgetSpent = status.spent;
        _budgetTotal = status.budget;
      }
    } catch (_) {}

    // Alert count
    try {
      final incomplete = await checklistRepo.getIncompleteToday();
      final overBudgets = await budgetRepo.getOverBudgetThisMonth();
      _alertCount = incomplete.length + overBudgets.length;
    } catch (_) {}

    if (mounted) {
      setState(() => _dataLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFE),
        elevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            Text(
              'Dashboard Armada',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, size: 22),
            onPressed: () => Navigator.push(
              context,
              FadePageRoute(page: const SearchScreen()),
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 22),
                onPressed: () {},
              ),
              if (_alertCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$_alertCount',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<VehicleBloc, VehicleState>(
        builder: (context, state) {
          if (state is VehicleLoading) {
            return const ShimmerDashboard();
          }
          if (state is VehicleLoaded) {
            if (state.vehicles.isEmpty) {
              return _buildEmptyState(context);
            }
            if (!_dataLoaded) {
              _loadDashboardData();
              return const ShimmerDashboard();
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<VehicleBloc>().add(LoadVehicles());
                setState(() => _dataLoaded = false);
                await Future.delayed(const Duration(milliseconds: 300));
                await _loadDashboardData();
              },
              child: _buildDashboardContent(context, state),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, VehicleLoaded state) {
    final totalKm = state.vehicles.fold<double>(0, (s, v) => s + v.totalMileageKm);
    final onTimeCount = state.vehicles.length - state.overdueCount;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 8),

        // === HERO GRADIENT CARD ===
        _buildHeroCard(totalKm, onTimeCount, state.overdueCount),
        const SizedBox(height: 16),

        // === TWO ACTION BUTTONS ===
        _buildActionButtons(context),
        const SizedBox(height: 20),

        // === PERAWATAN MENDATANG ===
        _buildUpcomingSection(context, state),
        const SizedBox(height: 20),

        // === ANALITIK ARMADA ===
        _buildAnalyticsCards(),
        const SizedBox(height: 20),

        // === AKTIVITAS TERBARU ===
        _buildRecentActivities(context),
        const SizedBox(height: 20),

        // === GRID CARDS ===
        _buildGridSection(context),
        const SizedBox(height: 80),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HERO CARD
  // ---------------------------------------------------------------------------
  Widget _buildHeroCard(double totalKm, int onTime, int overdue) {
    return Container(
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
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Kilometer Armada',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatKmLarge(totalKm),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  icon: Icons.check_circle,
                  iconColor: Colors.greenAccent,
                  value: '$onTime',
                  label: 'Tepat Waktu',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroStat(
                  icon: Icons.warning_rounded,
                  iconColor: Colors.orangeAccent,
                  value: '$overdue',
                  label: 'Terlambat',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ACTION BUTTONS
  // ---------------------------------------------------------------------------
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.add_road_rounded,
            label: 'Input KM',
            gradient: AppTheme.primaryGradient,
            onTap: () => Navigator.push(
              context,
              SlideUpPageRoute(page: const AddKmScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.build_rounded,
            label: 'Catat Servis',
            gradient: AppTheme.tealGradient,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PERAWATAN MENDATANG
  // ---------------------------------------------------------------------------
  Widget _buildUpcomingSection(BuildContext context, VehicleLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Perawatan Mendatang',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_upcomingSchedules.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              ),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.add, size: 16, color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_upcomingSchedules.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Belum ada jadwal perawatan mendatang',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          )
        else
          ...List.generate(_upcomingSchedules.length, (i) {
            final schedule = _upcomingSchedules[i];
            final vehicle = state.vehicles
                .where((v) => v.id == schedule.vehicleId)
                .firstOrNull;
            return Container(
              margin: EdgeInsets.only(bottom: i < _upcomingSchedules.length - 1 ? 6 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.build_rounded,
                        size: 16, color: AppTheme.secondaryColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${schedule.type.displayName} - ${vehicle?.name ?? "?"}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                        Text(
                          'Sisa ${schedule.remainingKm.round()} km',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${schedule.remainingDays}h',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: schedule.remainingDays <= 7
                          ? Colors.orange.shade700
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ANALITIK ARMADA (3 mini cards)
  // ---------------------------------------------------------------------------
  Widget _buildAnalyticsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Analitik Armada',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const Spacer(),
            Text(
              '30 Hari',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MiniAnalyticCard(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                ),
                value: '${_fleetScore?.score ?? 0}',
                label: 'Skor Armada',
                icon: Icons.shield_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniAnalyticCard(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8F00), Color(0xFFFFB74D)],
                ),
                value: 'Rp ${_formatCurrencyShort(_monthlyCost)}',
                label: 'Biaya/bulan',
                icon: Icons.account_balance_wallet_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniAnalyticCard(
                gradient: null,
                value: _avgFuelEfficiency > 0
                    ? _avgFuelEfficiency.toStringAsFixed(1)
                    : '-',
                label: 'km/L',
                icon: Icons.local_gas_station_rounded,
                isWhite: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // AKTIVITAS TERBARU
  // ---------------------------------------------------------------------------
  Widget _buildRecentActivities(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aktivitas Terbaru',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 10),
        if (_recentActivities.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Belum ada aktivitas',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          )
        else
          ...List.generate(_recentActivities.length, (i) {
            final activity = _recentActivities[i];
            return Container(
              margin: EdgeInsets.only(bottom: i < _recentActivities.length - 1 ? 4 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: activity.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(activity.icon, size: 15, color: activity.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1A1A2E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (activity.subtitle.isNotEmpty)
                          Text(
                            activity.subtitle,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    'Tap untuk edit',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // GRID SECTION (2x2)
  // ---------------------------------------------------------------------------
  Widget _buildGridSection(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildTrenKmCard()),
            const SizedBox(width: 8),
            Expanded(child: _buildSmartTipsCard(context)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildTopVehicleCard()),
            const SizedBox(width: 8),
            Expanded(child: _buildBudgetCard(context)),
          ],
        ),
      ],
    );
  }

  Widget _buildTrenKmCard() {
    final maxKm = _weeklyKm.isEmpty
        ? 1.0
        : _weeklyKm.map((d) => d.km).reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);
    return Container(
      padding: const EdgeInsets.all(12),
      height: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tren KM 7 Hari',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _weeklyKm.map((d) {
                final height = maxKm > 0 ? (d.km / maxKm) * 40 : 0.0;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 12,
                      height: height.clamp(4.0, 40.0),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d.day,
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartTipsCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SmartTipsScreen(
            vehicleRepository: context.read<VehicleBloc>().vehicleRepository,
            mileageRepository: context.read<MileageRepository>(),
            maintenanceRepository: context.read<MaintenanceHistoryRepository>(),
            scheduleRepository: context.read<MaintenanceScheduleRepository>(),
            fuelRepository: context.read<FuelRepository>(),
            checklistRepository: context.read<ChecklistRepository>(),
            budgetRepository: context.read<BudgetRepository>(),
            documentRepository: context.read<VehicleDocumentRepository>(),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        height: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Smart Tips',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_smartTips.isEmpty)
              Text(
                'Belum ada tips',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              )
            else
              ..._smartTips.map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${tip.title}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopVehicleCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Terbanyak KM',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _topVehicleName.isNotEmpty ? _topVehicleName : '-',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A2E),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            _topVehicleKm > 0 ? '${_topVehicleKm.round()} km bulan ini' : 'Belum ada data',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context) {
    final progress = _budgetTotal > 0 ? (_budgetSpent / _budgetTotal).clamp(0.0, 1.0) : 0.0;
    return GestureDetector(
      onTap: () {
        final state = context.read<VehicleBloc>().state;
        if (state is VehicleLoaded) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BudgetScreen(
                budgetRepository: context.read<BudgetRepository>(),
                vehicles: state.vehicles,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Budget Status',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(
                  progress > 0.8 ? Colors.red : AppTheme.primaryColor,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _budgetTotal > 0
                  ? 'Rp ${_formatCurrencyShort(_budgetSpent)} / Rp ${_formatCurrencyShort(_budgetTotal)}'
                  : 'Belum ada budget',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EMPTY STATE
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.directions_car_outlined,
                  size: 48, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum ada kendaraan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan kendaraan pertama Anda\nuntuk mulai kelola perawatan',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const VehicleFormScreen())),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Tambah Kendaraan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------
  String _formatKmLarge(double km) {
    if (km >= 1000) {
      final formatted = (km / 1000).toStringAsFixed(1);
      return '$formatted k km';
    }
    return '${km.round()} km';
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} jt';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} rb';
    }
    return amount.round().toString();
  }

  String _formatCurrencyShort(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return amount.round().toString();
  }
}

// =============================================================================
// HERO STAT WIDGET
// =============================================================================

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _HeroStat({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ACTION BUTTON
// =============================================================================

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// MINI ANALYTIC CARD
// =============================================================================

class _MiniAnalyticCard extends StatelessWidget {
  final LinearGradient? gradient;
  final String value;
  final String label;
  final IconData icon;
  final bool isWhite;

  const _MiniAnalyticCard({
    required this.gradient,
    required this.value,
    required this.label,
    required this.icon,
    this.isWhite = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      height: 90,
      decoration: BoxDecoration(
        gradient: isWhite ? null : gradient,
        color: isWhite ? Colors.white : null,
        borderRadius: BorderRadius.circular(12),
        border: isWhite ? Border.all(color: Colors.grey.shade200) : null,
        boxShadow: isWhite ? AppTheme.softShadow : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            icon,
            size: 18,
            color: isWhite ? Colors.grey.shade600 : Colors.white.withValues(alpha: 0.8),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isWhite ? const Color(0xFF1A1A2E) : Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: isWhite
                      ? Colors.grey.shade500
                      : Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ACTIVITY ITEM MODEL
// =============================================================================

class _ActivityItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final DateTime date;
  final Color color;

  _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.color,
  });
}

// =============================================================================
// DAILY KM DATA MODEL
// =============================================================================

class _DailyKmData {
  final String day;
  final double km;

  _DailyKmData({required this.day, required this.km});
}

// =============================================================================
// VEHICLE LIST TAB (Tab 4: Kendaraan)
// =============================================================================

class _VehicleListTab extends StatelessWidget {
  const _VehicleListTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kendaraan',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
            ),
          ),
        ],
      ),
      body: BlocBuilder<VehicleBloc, VehicleState>(
        builder: (context, state) {
          if (state is VehicleLoading) {
            return const ShimmerList();
          }
          if (state is VehicleLoaded) {
            if (state.vehicles.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_car_outlined,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada kendaraan',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const VehicleFormScreen()),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Kendaraan'),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = state.vehicles[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _CompactVehicleCard(vehicle: vehicle),
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

// =============================================================================
// COMPACT VEHICLE CARD
// =============================================================================

class _CompactVehicleCard extends StatelessWidget {
  final Vehicle vehicle;

  const _CompactVehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        SlidePageRoute(
          page: VehicleDetailScreen(
            vehicle: vehicle,
            customIntervalRepository: context.read<CustomIntervalRepository>(),
            driverRepository: context.read<DriverRepository>(),
            driverAssignmentRepository:
                context.read<DriverAssignmentRepository>(),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                vehicle.type == VehicleType.motorcycle
                    ? Icons.two_wheeler
                    : Icons.directions_car_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    '${vehicle.plateNumber} • ${vehicle.totalMileageKm.round()} km',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}
