import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/undo_service.dart';
import '../../data/repositories/custom_interval_repository.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/models/vehicle_type.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../blocs/vehicle/vehicle_bloc.dart';
import '../blocs/vehicle/vehicle_event.dart';
import '../blocs/vehicle/vehicle_state.dart';
import '../widgets/delete_vehicle_dialog.dart';
import 'vehicle_detail_screen.dart';
import 'vehicle_form_screen.dart';

/// Screen that displays the full list of vehicles with type icons,
/// name, plate number, and total mileage.
class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<VehicleBloc>().add(LoadVehicles());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Kendaraan'),
      ),
      body: BlocConsumer<VehicleBloc, VehicleState>(
        listener: (context, state) {
          if (state is VehicleOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is VehicleError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        buildWhen: (previous, current) =>
            current is VehicleLoaded ||
            current is VehicleLoading ||
            current is VehicleInitial,
        builder: (context, state) {
          if (state is VehicleLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is VehicleLoaded) {
            if (state.vehicles.isEmpty) {
              return _buildEmptyState(context);
            }
            return _buildVehicleList(context, state.vehicles);
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddVehicle(context),
        tooltip: 'Tambah Kendaraan',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_outlined,
                size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum ada kendaraan terdaftar',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan kendaraan pertama Anda untuk mulai melacak perawatan.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddVehicle(context),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Kendaraan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleList(BuildContext context, List<Vehicle> vehicles) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<VehicleBloc>().add(LoadVehicles());
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: vehicles.length,
        itemBuilder: (context, index) {
          final vehicle = vehicles[index];
          return _VehicleListItem(
            vehicle: vehicle,
            onTap: () => _navigateToDetail(context, vehicle),
            onDelete: () => _confirmDelete(context, vehicle),
          );
        },
      ),
    );
  }

  void _navigateToAddVehicle(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
    );
  }

  void _navigateToDetail(BuildContext context, Vehicle vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VehicleDetailScreen(
          vehicle: vehicle,
          customIntervalRepository:
              context.read<CustomIntervalRepository>(),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Vehicle vehicle) async {
    final bloc = context.read<VehicleBloc>();
    final confirmed = await DeleteVehicleDialog.show(context, vehicle.name);
    if (confirmed == true) {
      // Delete immediately
      bloc.add(DeleteVehicle(vehicle.id));
      // Show undo snackbar
      if (context.mounted) {
        UndoService.showUndoSnackbar(
          context: context,
          message: '${vehicle.name} dihapus',
          undoAction: () async {
            // Restore the vehicle
            final repo = context.read<VehicleRepository>();
            await repo.addVehicle(vehicle);
            bloc.add(LoadVehicles());
          },
        );
      }
    }
  }
}

class _VehicleListItem extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _VehicleListItem({
    required this.vehicle,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            vehicle.type == VehicleType.motorcycle
                ? Icons.two_wheeler
                : Icons.directions_car,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(vehicle.name),
        subtitle: Text(
          '${vehicle.plateNumber} • ${vehicle.totalMileageKm.round()} km',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'Hapus',
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
