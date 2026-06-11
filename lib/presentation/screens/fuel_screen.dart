import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/models/fuel_record.dart';
import '../../domain/models/fuel_statistics.dart';
import '../blocs/fuel/fuel_bloc.dart';
import '../blocs/fuel/fuel_event.dart';
import '../blocs/fuel/fuel_state.dart';
import '../blocs/vehicle/vehicle_bloc.dart';
import '../blocs/vehicle/vehicle_state.dart';
import 'fuel_form_screen.dart';

class FuelScreen extends StatefulWidget {
  const FuelScreen({super.key});

  @override
  State<FuelScreen> createState() => _FuelScreenState();
}

class _FuelScreenState extends State<FuelScreen> {
  String? _selectedVehicleId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleBloc, VehicleState>(
      builder: (context, vehicleState) {
        if (vehicleState is! VehicleLoaded || vehicleState.vehicles.isEmpty) {
          return const Center(
            child: Text('Tambahkan kendaraan terlebih dahulu'),
          );
        }

        final vehicles = vehicleState.vehicles;
        _selectedVehicleId ??= vehicles.first.id;
        final selectedVehicle =
            vehicles.firstWhere((v) => v.id == _selectedVehicleId);

        return Scaffold(
          appBar: AppBar(
            title: const Text('BBM'),
          ),
          body: Column(
            children: [
              // Vehicle selector
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedVehicleId,
                  decoration: const InputDecoration(
                    labelText: 'Kendaraan',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: vehicles
                      .map((v) => DropdownMenuItem(
                            value: v.id,
                            child: Text('${v.name} (${v.plateNumber})'),
                          ))
                      .toList(),
                  onChanged: (id) {
                    setState(() => _selectedVehicleId = id);
                    if (id != null) {
                      context.read<FuelBloc>().add(LoadFuelRecords(id));
                    }
                  },
                ),
              ),

              // Content
              Expanded(
                child: BlocBuilder<FuelBloc, FuelState>(
                  builder: (context, state) {
                    if (state is FuelLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is FuelLoaded) {
                      return _buildContent(state.records, state.statistics);
                    }
                    // Initial state - trigger load
                    if (_selectedVehicleId != null) {
                      context
                          .read<FuelBloc>()
                          .add(LoadFuelRecords(_selectedVehicleId!));
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<FuelBloc>(),
                    child: FuelFormScreen(
                      vehicleId: _selectedVehicleId!,
                      currentOdometer: selectedVehicle.totalMileageKm,
                    ),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Isi BBM'),
          ),
        );
      },
    );
  }

  Widget _buildContent(List<FuelRecord> records, FuelStatistics stats) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Stats cards
        _StatsCard(stats: stats),
        const SizedBox(height: 16),

        // Records list
        if (records.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Belum ada data BBM.\nTap + untuk mencatat pengisian.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else ...[
          Text(
            'Riwayat Pengisian',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...records.map((r) => _FuelRecordTile(record: r, onDelete: () {
            context.read<FuelBloc>().add(
                DeleteFuelRecord(id: r.id, vehicleId: r.vehicleId));
          })),
        ],
        const SizedBox(height: 80), // FAB clearance
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  final FuelStatistics stats;
  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final theme = Theme.of(context);

    IconData trendIcon;
    Color trendColor;
    String trendText;

    switch (stats.trend) {
      case 'improving':
        trendIcon = Icons.trending_up;
        trendColor = Colors.green;
        trendText = 'Membaik';
        break;
      case 'worsening':
        trendIcon = Icons.trending_down;
        trendColor = Colors.red;
        trendText = 'Memburuk';
        break;
      default:
        trendIcon = Icons.trending_flat;
        trendColor = Colors.grey;
        trendText = 'Stabil';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statistik BBM',
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: theme.colorScheme.primary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Konsumsi',
                    value: stats.averageKmPerLiter > 0
                        ? '${stats.averageKmPerLiter.toStringAsFixed(1)} km/L'
                        : 'Data belum cukup',
                    icon: Icons.speed,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Total Biaya',
                    value: currencyFormat.format(stats.totalCost),
                    icon: Icons.payments,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Total Liter',
                    value: '${stats.totalLiters.toStringAsFixed(1)} L',
                    icon: Icons.local_gas_station,
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Icon(trendIcon, color: trendColor, size: 20),
                      const SizedBox(width: 4),
                      Text(trendText,
                          style: TextStyle(
                              color: trendColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}

class _FuelRecordTile extends StatelessWidget {
  final FuelRecord record;
  final VoidCallback onDelete;

  const _FuelRecordTile({required this.record, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(Icons.local_gas_station,
              color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          '${record.liters.toStringAsFixed(1)} L - ${currencyFormat.format(record.totalCost)}',
        ),
        subtitle: Text(
          '${dateFormat.format(record.date)} • ${record.odometerKm.toStringAsFixed(0)} km'
          '${record.fuelType != null ? ' • ${record.fuelType}' : ''}'
          '${record.isFullTank ? ' • Full' : ''}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _confirmDelete(context),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Record BBM?'),
        content: const Text('Data yang dihapus tidak bisa dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
