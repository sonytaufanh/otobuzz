import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import '../../core/utils/semantics_labels.dart';
import '../../data/repositories/checklist_repository.dart';
import '../../data/repositories/custom_interval_repository.dart';
import '../../data/repositories/driver_assignment_repository.dart';
import '../../data/repositories/driver_repository.dart';
import '../../data/repositories/vehicle_document_repository.dart';
import '../../data/services/pdf_report_service.dart';
import '../../data/services/whatsapp_service.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/maintenance_history_repository.dart';
import '../../domain/repositories/maintenance_schedule_repository.dart';
import '../../domain/repositories/mileage_repository.dart';
import '../../domain/usecases/health_score_calculator.dart';
import '../blocs/maintenance/maintenance_bloc.dart';
import '../blocs/vehicle/vehicle_bloc.dart';
import '../widgets/health_score_widget.dart';
import '../widgets/shimmer_loading.dart';
import 'add_km_screen.dart';
import 'custom_interval_screen.dart';
import 'daily_checklist_screen.dart';
import 'driver_history_screen.dart';
import 'health_score_screen.dart';
import 'maintenance_dashboard_screen.dart';
import 'maintenance_history_screen.dart';
import 'mileage_history_screen.dart';
import 'vehicle_documents_screen.dart';

class VehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;
  final CustomIntervalRepository customIntervalRepository;
  final DriverRepository? driverRepository;
  final DriverAssignmentRepository? driverAssignmentRepository;

  const VehicleDetailScreen({
    super.key,
    required this.vehicle,
    required this.customIntervalRepository,
    this.driverRepository,
    this.driverAssignmentRepository,
  });

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  HealthScoreResult? _healthScore;
  bool _loadingScore = true;

  @override
  void initState() {
    super.initState();
    _loadHealthScore();
  }

  Future<void> _loadHealthScore() async {
    final scheduleRepo = context.read<MaintenanceScheduleRepository>();
    final mileageRepo = context.read<MileageRepository>();
    final documentRepo = context.read<VehicleDocumentRepository>();
    final vehicleBloc = context.read<VehicleBloc>();

    // Get the MaintenanceCalculator from VehicleBloc
    final calculator = vehicleBloc.calculator;

    final healthCalculator = HealthScoreCalculator(
      maintenanceCalculator: calculator,
      mileageRepository: mileageRepo,
      documentRepository: documentRepo,
      scheduleRepository: scheduleRepo,
    );

    final result = await healthCalculator.calculateScore(widget.vehicle);
    if (mounted) {
      setState(() {
        _healthScore = result;
        _loadingScore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicle.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Ekspor PDF',
            onPressed: () => _exportVehiclePdf(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Vehicle info card
          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(
                  widget.vehicle.type == VehicleType.motorcycle
                      ? Icons.two_wheeler
                      : Icons.directions_car,
                ),
              ),
              title: Text(widget.vehicle.name),
              subtitle: Text(
                '${widget.vehicle.plateNumber} • ${widget.vehicle.year}',
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Health Score Card
          _buildHealthScoreCard(context),
          const SizedBox(height: 16),

          // Total mileage card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Kilometer',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.vehicle.totalMileageKm.round()} km',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          Text(
            'Aksi Cepat',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          // Input KM
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.add_road),
              ),
              title: const Text('Input KM Harian'),
              subtitle: const Text('Catat kilometer hari ini'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddKmScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Maintenance dashboard
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.build),
              ),
              title: const Text('Jadwal Perawatan'),
              subtitle: const Text('Lihat jadwal dan catat perawatan'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<MaintenanceBloc>(),
                      child: MaintenanceDashboardScreen(vehicle: widget.vehicle),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Maintenance history
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.history),
              ),
              title: const Text('Riwayat Perawatan'),
              subtitle: const Text('Lihat riwayat servis kendaraan'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<MaintenanceBloc>(),
                      child: MaintenanceHistoryScreen(vehicle: widget.vehicle),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Mileage history
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.timeline),
              ),
              title: const Text('Riwayat Kilometer'),
              subtitle: const Text('Lihat catatan km harian'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MileageHistoryScreen(vehicle: widget.vehicle),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Custom intervals
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.tune),
              ),
              title: const Text('Atur Interval Perawatan'),
              subtitle: const Text('Sesuaikan interval per kendaraan'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomIntervalScreen(
                      vehicle: widget.vehicle,
                      customIntervalRepository: widget.customIntervalRepository,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Pajak & STNK
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.description),
              ),
              title: const Text('Pajak & STNK'),
              subtitle: const Text('Kelola pajak dan STNK kendaraan'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VehicleDocumentsScreen(
                      vehicle: widget.vehicle,
                      documentRepository: context
                          .read<VehicleDocumentRepository>(),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Daily Checklist
          _DailyChecklistCard(vehicle: widget.vehicle),
          const SizedBox(height: 24),

          // Driver section
          if (widget.driverRepository != null && widget.driverAssignmentRepository != null)
            ..._buildDriverSection(context),
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard(BuildContext context) {
    if (_loadingScore) {
      return const ShimmerCard();
    }

    final result = _healthScore;
    if (result == null) return const SizedBox();

    return Semantics(
      label: AppSemantics.vehicleHealthScore(
          widget.vehicle.name, result.score),
      child: Card(
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HealthScoreScreen(
                  vehicle: widget.vehicle,
                  result: result,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                HealthScoreWidget(
                  result: result,
                  size: 72,
                  compact: true,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Skor Kesehatan Kendaraan',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.description,
                        style: TextStyle(
                          color: result.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (result.issues.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${result.issues.length} masalah ditemukan',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.red,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportVehiclePdf(BuildContext context) async {
    final scheduleRepo = context.read<MaintenanceScheduleRepository>();
    final historyRepo = context.read<MaintenanceHistoryRepository>();
    final mileageRepo = context.read<MileageRepository>();

    final schedules = await scheduleRepo.getSchedules(widget.vehicle.id);
    final history = await historyRepo.getHistory(widget.vehicle.id);
    final recentHistory = history.length > 10
        ? history.sublist(0, 10)
        : history;
    final totalMileage = await mileageRepo.getTotalMileage(widget.vehicle.id);
    final avgDaily = await mileageRepo.getAverageDailyMileage(widget.vehicle.id);

    final pdfService = PdfReportService();
    final pdfBytes = await pdfService.generateVehicleReport(
      vehicle: widget.vehicle,
      schedules: schedules,
      recentHistory: recentHistory,
      totalMileage: totalMileage,
      avgDailyMileage: avgDaily,
    );

    if (!context.mounted) return;

    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'OtoBuzz_Laporan_${widget.vehicle.name}',
    );
  }

  List<Widget> _buildDriverSection(BuildContext context) {
    return [
      Text(
        'Driver',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 12),

      // Today's driver card
      _TodayDriverCard(
        vehicle: widget.vehicle,
        driverRepository: widget.driverRepository!,
        driverAssignmentRepository: widget.driverAssignmentRepository!,
      ),
      const SizedBox(height: 8),

      // Driver history
      Card(
        child: ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.history),
          ),
          title: const Text('Riwayat Driver'),
          subtitle: const Text('Lihat riwayat penugasan driver'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DriverHistoryScreen(
                  assignmentRepository: widget.driverAssignmentRepository!,
                  driverRepository: widget.driverRepository!,
                  vehicle: widget.vehicle,
                ),
              ),
            );
          },
        ),
      ),
    ];
  }
}

// =============================================================================
// Daily Checklist Card Widget
// =============================================================================

class _DailyChecklistCard extends StatefulWidget {
  final Vehicle vehicle;

  const _DailyChecklistCard({required this.vehicle});

  @override
  State<_DailyChecklistCard> createState() => _DailyChecklistCardState();
}

class _DailyChecklistCardState extends State<_DailyChecklistCard> {
  ChecklistStatus? _todayStatus;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final repo = context.read<ChecklistRepository>();
    final status = await repo.getTodayStatus(widget.vehicle.id);
    if (mounted) {
      setState(() {
        _todayStatus = status;
        _loading = false;
      });
    }
  }

  String _statusText() {
    if (_todayStatus == null) return 'Belum dilakukan hari ini';
    return _todayStatus!.displayName;
  }

  Color _statusColor() {
    if (_todayStatus == null) return Colors.orange;
    switch (_todayStatus!) {
      case ChecklistStatus.ok:
        return Colors.green;
      case ChecklistStatus.warning:
        return Colors.orange;
      case ChecklistStatus.critical:
        return Colors.red;
    }
  }

  IconData _statusIcon() {
    if (_todayStatus == null) return Icons.pending_actions;
    switch (_todayStatus!) {
      case ChecklistStatus.ok:
        return Icons.check_circle;
      case ChecklistStatus.warning:
        return Icons.warning;
      case ChecklistStatus.critical:
        return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ChecklistRepository>();
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor().withValues(alpha: 0.2),
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_statusIcon(), color: _statusColor()),
        ),
        title: const Text('Checklist Harian'),
        subtitle: Text(
          _loading ? 'Memuat...' : _statusText(),
          style: TextStyle(color: _statusColor()),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => DailyChecklistScreen(
                vehicle: widget.vehicle,
                checklistRepository: repo,
              ),
            ),
          );
          if (result == true) {
            _loadStatus();
          }
        },
      ),
    );
  }
}

// =============================================================================
// Today's Driver Card Widget
// =============================================================================

class _TodayDriverCard extends StatefulWidget {
  final Vehicle vehicle;
  final DriverRepository driverRepository;
  final DriverAssignmentRepository driverAssignmentRepository;

  const _TodayDriverCard({
    required this.vehicle,
    required this.driverRepository,
    required this.driverAssignmentRepository,
  });

  @override
  State<_TodayDriverCard> createState() => _TodayDriverCardState();
}

class _TodayDriverCardState extends State<_TodayDriverCard> {
  Driver? _todayDriver;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayDriver();
  }

  Future<void> _loadTodayDriver() async {
    final assignment = await widget.driverAssignmentRepository
        .getAssignment(widget.vehicle.id, DateTime.now());
    if (assignment != null) {
      final driver =
          await widget.driverRepository.getDriverById(assignment.driverId);
      setState(() {
        _todayDriver = driver;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _changeDriver() async {
    final drivers = await widget.driverRepository.getAllDrivers();
    if (drivers.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Belum ada driver. Tambahkan driver terlebih dahulu.')),
        );
      }
      return;
    }

    if (!mounted) return;
    final selected = await showDialog<Driver>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Pilih Driver'),
        children: drivers.map((driver) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, driver),
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text(driver.name),
              subtitle: Text(driver.phone ?? '-'),
            ),
          );
        }).toList(),
      ),
    );

    if (selected != null) {
      final now = DateTime.now();
      final dateStr =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await widget.driverAssignmentRepository.assignDriver(
        DriverAssignment(
          id: '',
          vehicleId: widget.vehicle.id,
          driverId: selected.id,
          date: DateTime.parse(dateStr),
        ),
      );
      setState(() {
        _todayDriver = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.person_pin),
        ),
        title: Text(
          _todayDriver != null
              ? 'Driver hari ini: ${_todayDriver!.name}'
              : 'Belum ada driver hari ini',
        ),
        subtitle: _todayDriver?.phone != null
            ? Row(
                children: [
                  Text(_todayDriver!.phone!),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      WhatsAppService.sendMaintenanceReminder(
                        vehicleName: widget.vehicle.name,
                        maintenanceType: 'Info Driver',
                        remainingInfo: 'Hubungi driver',
                        phoneNumber: _todayDriver!.phone,
                      );
                    },
                    child: const Icon(
                      Icons.chat,
                      color: Colors.green,
                      size: 20,
                      semanticLabel: 'Hubungi Driver',
                    ),
                  ),
                ],
              )
            : null,
        trailing: TextButton(
          onPressed: _changeDriver,
          child: const Text('Ganti Driver'),
        ),
      ),
    );
  }
}
