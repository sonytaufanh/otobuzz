import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/models/models.dart';
import '../blocs/maintenance/maintenance_bloc.dart';
import '../blocs/maintenance/maintenance_event.dart';
import '../blocs/maintenance/maintenance_state.dart';
import 'maintenance_form_screen.dart';
import 'maintenance_history_screen.dart';

class MaintenanceDashboardScreen extends StatefulWidget {
  final Vehicle vehicle;

  const MaintenanceDashboardScreen({super.key, required this.vehicle});

  @override
  State<MaintenanceDashboardScreen> createState() =>
      _MaintenanceDashboardScreenState();
}

class _MaintenanceDashboardScreenState
    extends State<MaintenanceDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MaintenanceBloc>().add(LoadSchedules(widget.vehicle.id));
  }

  Color _getStatusColor(MaintenanceSchedule schedule) {
    if (schedule.isOverdue) {
      return Colors.red;
    }
    // Check if within warning threshold
    final interval = getDefaultInterval(schedule.type, widget.vehicle.type);
    if (schedule.remainingKm <= interval.warningBeforeKm ||
        schedule.remainingDays <= interval.warningBeforeDays) {
      return Colors.amber;
    }
    return Colors.green;
  }

  String _formatEstimatedDate(MaintenanceSchedule schedule) {
    if (schedule.isOverdue) {
      return 'Sudah lewat';
    }
    if (schedule.estimatedDueDate != null) {
      final dateFormat = DateFormat('dd/MM/yyyy');
      return 'Estimasi: ${dateFormat.format(schedule.estimatedDueDate!)}';
    }
    final dateFormat = DateFormat('dd/MM/yyyy');
    return 'Batas: ${dateFormat.format(schedule.dueByDate)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perawatan - ${widget.vehicle.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Riwayat Perawatan',
            onPressed: () {
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
        ],
      ),
      body: BlocBuilder<MaintenanceBloc, MaintenanceState>(
        builder: (context, state) {
          if (state is MaintenanceLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MaintenanceSchedulesLoaded) {
            final schedules = state.schedules;
            if (schedules.isEmpty) {
              return const Center(
                child: Text('Tidak ada jadwal perawatan'),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final schedule = schedules[index];
                final statusColor = _getStatusColor(schedule);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: statusColor, width: 1.5),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withValues(alpha: 0.2),
                      child: Icon(
                        _getIconForType(schedule.type),
                        color: statusColor,
                      ),
                    ),
                    title: Text(
                      schedule.type.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          schedule.isOverdue
                              ? 'Sudah lewat ${schedule.remainingKm.abs().round()} km'
                              : 'Sisa ${schedule.remainingKm.round()} km',
                          style: TextStyle(color: statusColor),
                        ),
                        Text(
                          _formatEstimatedDate(schedule),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: schedule.isOverdue
                        ? const Icon(Icons.warning, color: Colors.red)
                        : null,
                    isThreeLine: true,
                  ),
                );
              },
            );
          }
          if (state is MaintenanceError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final bloc = context.read<MaintenanceBloc>();
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: bloc,
                child: MaintenanceFormScreen(vehicle: widget.vehicle),
              ),
            ),
          );
          // Reload schedules after recording maintenance
          if (mounted) {
            bloc.add(LoadSchedules(widget.vehicle.id));
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Catat Perawatan'),
      ),
    );
  }

  IconData _getIconForType(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.oilChange:
        return Icons.oil_barrel;
      case MaintenanceType.tireReplacement:
        return Icons.tire_repair;
      case MaintenanceType.brakePads:
        return Icons.do_not_step;
      case MaintenanceType.airFilter:
        return Icons.air;
      case MaintenanceType.sparkPlug:
        return Icons.bolt;
      case MaintenanceType.chainLube:
        return Icons.link;
      case MaintenanceType.coolant:
        return Icons.water_drop;
      case MaintenanceType.brakeFluid:
        return Icons.water;
      case MaintenanceType.transmission:
        return Icons.settings;
    }
  }
}
