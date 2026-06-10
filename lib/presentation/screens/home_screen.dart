import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/custom_interval_repository.dart';
import '../../data/repositories/driver_assignment_repository.dart';
import '../../data/repositories/driver_repository.dart';
import '../../data/repositories/vehicle_document_repository.dart';
import '../../domain/models/maintenance_schedule.dart';
import '../../domain/models/maintenance_type.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/models/vehicle_type.dart';
import '../../domain/repositories/maintenance_schedule_repository.dart';
import '../../domain/repositories/mileage_repository.dart';
import '../../domain/usecases/health_score_calculator.dart';
import '../blocs/vehicle/vehicle_bloc.dart';
import '../blocs/vehicle/vehicle_event.dart';
import '../blocs/vehicle/vehicle_state.dart';
import '../widgets/health_score_widget.dart';
import 'add_km_screen.dart';
import 'analytics_screen.dart';
import 'cost_report_screen.dart';
import 'driver_list_screen.dart';
import 'fuel_screen.dart';
import 'health_score_screen.dart';
import 'settings_screen.dart';
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
        children: const [
          _FleetOverview(),
          _VehicleListTab(),
          _InputKmTab(),
          FuelScreen(),
          CostReportScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: 'Kendaraan',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_road_outlined),
            selectedIcon: Icon(Icons.add_road),
            label: 'Input KM',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_gas_station_outlined),
            selectedIcon: Icon(Icons.local_gas_station),
            label: 'BBM',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Laporan',
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Tab 1: Fleet Overview (Beranda)
// =============================================================================

class _FleetOverview extends StatelessWidget {
  const _FleetOverview();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OtoBuzz'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Analytics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AnalyticsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Kelola Driver',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DriverListScreen(
                    driverRepository: context.read<DriverRepository>(),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Pengaturan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<VehicleBloc, VehicleState>(
        builder: (context, state) {
          if (state is VehicleLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is VehicleLoaded) {
            if (state.vehicles.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_car,
                        size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada kendaraan',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text('Tambahkan kendaraan pertama Anda'),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const VehicleFormScreen()),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Kendaraan'),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<VehicleBloc>().add(LoadVehicles());
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Fleet summary card with maintenance status
                  _FleetSummaryCard(state: state),
                  const SizedBox(height: 16),

                  // Quick action: Input KM
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddKmScreen()),
                      );
                    },
                    icon: const Icon(Icons.add_road),
                    label: const Text('Input KM Harian'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Kendaraan Anda',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...state.vehicles.map(
                    (vehicle) => _VehicleStatusCard(
                      vehicle: vehicle,
                      mostUrgentSchedule:
                          state.getMostUrgentSchedule(vehicle.id),
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

// =============================================================================
// Fleet Summary Card with overdue/upcoming counts
// =============================================================================

class _FleetSummaryCard extends StatefulWidget {
  final VehicleLoaded state;

  const _FleetSummaryCard({required this.state});

  @override
  State<_FleetSummaryCard> createState() => _FleetSummaryCardState();
}

class _FleetSummaryCardState extends State<_FleetSummaryCard> {
  HealthScoreResult? _fleetScore;

  @override
  void initState() {
    super.initState();
    _loadFleetScore();
  }

  @override
  void didUpdateWidget(_FleetSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _loadFleetScore();
    }
  }

  Future<void> _loadFleetScore() async {
    if (widget.state.vehicles.isEmpty) return;

    final vehicleBloc = context.read<VehicleBloc>();
    final mileageRepo = context.read<MileageRepository>();
    final documentRepo = context.read<VehicleDocumentRepository>();
    final scheduleRepo = context.read<MaintenanceScheduleRepository>();

    final calculator = HealthScoreCalculator(
      maintenanceCalculator: vehicleBloc.calculator,
      mileageRepository: mileageRepo,
      documentRepository: documentRepo,
      scheduleRepository: scheduleRepo,
    );

    final result = await calculator.calculateFleetScore(widget.state.vehicles);
    if (mounted) {
      setState(() => _fleetScore = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDocIssues =
        widget.state.expiredDocumentCount + widget.state.expiringSoonDocumentCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan Armada',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            // Fleet health score row
            if (_fleetScore != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: _fleetScore!.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _fleetScore!.color.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.favorite, color: _fleetScore!.color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Skor Armada: ${_fleetScore!.score}/100 (${_fleetScore!.grade})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _fleetScore!.color,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _fleetScore!.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: _fleetScore!.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                  icon: Icons.directions_car,
                  value: '${widget.state.vehicles.length}',
                  label: 'Kendaraan',
                  color: Theme.of(context).colorScheme.primary,
                ),
                _SummaryItem(
                  icon: Icons.warning_amber,
                  value: '${widget.state.overdueCount}',
                  label: 'Terlambat',
                  color: widget.state.overdueCount > 0
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
                ),
                _SummaryItem(
                  icon: Icons.schedule,
                  value: '${widget.state.upcomingCount}',
                  label: 'Segera',
                  color: widget.state.upcomingCount > 0
                      ? Colors.orange
                      : Theme.of(context).colorScheme.primary,
                ),
                _SummaryItem(
                  icon: Icons.description,
                  value: '$totalDocIssues',
                  label: 'Pajak/STNK',
                  color: widget.state.expiredDocumentCount > 0
                      ? Colors.red
                      : widget.state.expiringSoonDocumentCount > 0
                          ? Colors.orange
                          : Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Summary Item Widget
// =============================================================================

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 4),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold, color: color)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// =============================================================================
// Vehicle Status Card (shows most urgent maintenance + compact health score)
// =============================================================================

class _VehicleStatusCard extends StatefulWidget {
  final Vehicle vehicle;
  final MaintenanceSchedule? mostUrgentSchedule;

  const _VehicleStatusCard({
    required this.vehicle,
    this.mostUrgentSchedule,
  });

  @override
  State<_VehicleStatusCard> createState() => _VehicleStatusCardState();
}

class _VehicleStatusCardState extends State<_VehicleStatusCard> {
  HealthScoreResult? _healthScore;

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  Future<void> _loadScore() async {
    final vehicleBloc = context.read<VehicleBloc>();
    final mileageRepo = context.read<MileageRepository>();
    final documentRepo = context.read<VehicleDocumentRepository>();
    final scheduleRepo = context.read<MaintenanceScheduleRepository>();

    final calculator = HealthScoreCalculator(
      maintenanceCalculator: vehicleBloc.calculator,
      mileageRepository: mileageRepo,
      documentRepository: documentRepo,
      scheduleRepository: scheduleRepo,
    );

    final result = await calculator.calculateScore(widget.vehicle);
    if (mounted) {
      setState(() => _healthScore = result);
    }
  }

  String _getMaintenanceStatusText() {
    if (widget.mostUrgentSchedule == null) return 'Belum ada jadwal perawatan';
    if (widget.mostUrgentSchedule!.isOverdue) {
      return '⚠️ ${_getTypeLabel(widget.mostUrgentSchedule!.type)} terlambat!';
    }
    if (widget.mostUrgentSchedule!.remainingDays <= 30) {
      return '🔔 ${_getTypeLabel(widget.mostUrgentSchedule!.type)} dalam ${widget.mostUrgentSchedule!.remainingKm.round()} km';
    }
    return '✓ ${_getTypeLabel(widget.mostUrgentSchedule!.type)} dalam ${widget.mostUrgentSchedule!.remainingKm.round()} km';
  }

  Color _getStatusColor(BuildContext context) {
    if (widget.mostUrgentSchedule == null) {
      return Theme.of(context).colorScheme.outline;
    }
    if (widget.mostUrgentSchedule!.isOverdue) return Colors.red;
    if (widget.mostUrgentSchedule!.remainingDays <= 30) return Colors.orange;
    return Colors.green;
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            widget.vehicle.type == VehicleType.motorcycle
                ? Icons.two_wheeler
                : Icons.directions_car,
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(widget.vehicle.name)),
            if (_healthScore != null)
              CompactHealthScore(
                result: _healthScore!,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HealthScoreScreen(
                        vehicle: widget.vehicle,
                        result: _healthScore!,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.vehicle.plateNumber} • ${widget.vehicle.totalMileageKm.round()} km'),
            const SizedBox(height: 2),
            Text(
              _getMaintenanceStatusText(),
              style: TextStyle(
                fontSize: 12,
                color: _getStatusColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        isThreeLine: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VehicleDetailScreen(
                vehicle: widget.vehicle,
                customIntervalRepository:
                    context.read<CustomIntervalRepository>(),
                driverRepository: context.read<DriverRepository>(),
                driverAssignmentRepository:
                    context.read<DriverAssignmentRepository>(),
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// Tab 2: Vehicle List (Kendaraan)
// =============================================================================

class _VehicleListTab extends StatelessWidget {
  const _VehicleListTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kendaraan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<VehicleBloc, VehicleState>(
        builder: (context, state) {
          if (state is VehicleLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is VehicleLoaded) {
            if (state.vehicles.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Belum ada kendaraan'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const VehicleFormScreen()),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Kendaraan'),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              itemCount: state.vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = state.vehicles[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      vehicle.type == VehicleType.motorcycle
                          ? Icons.two_wheeler
                          : Icons.directions_car,
                    ),
                  ),
                  title: Text(vehicle.name),
                  subtitle: Text(
                      '${vehicle.plateNumber} • ${vehicle.totalMileageKm.round()} km • ${vehicle.year}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VehicleDetailScreen(
                          vehicle: vehicle,
                          customIntervalRepository:
                              context.read<CustomIntervalRepository>(),
                          driverRepository: context.read<DriverRepository>(),
                          driverAssignmentRepository:
                              context.read<DriverAssignmentRepository>(),
                        ),
                      ),
                    );
                  },
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
// Tab 3: Input KM (Quick access to daily KM input)
// =============================================================================

class _InputKmTab extends StatelessWidget {
  const _InputKmTab();

  @override
  Widget build(BuildContext context) {
    return const AddKmScreen();
  }
}
