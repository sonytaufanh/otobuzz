import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/driver_assignment_repository.dart';
import '../../data/repositories/driver_repository.dart';
import '../../domain/models/models.dart';

/// Shows driver assignment history.
/// - For a vehicle: shows which driver used it on each date.
/// - For a driver: shows which vehicles they drove on each date.
class DriverHistoryScreen extends StatefulWidget {
  final DriverAssignmentRepository assignmentRepository;
  final DriverRepository driverRepository;

  /// If provided, shows history for this vehicle.
  final Vehicle? vehicle;

  /// If provided, shows history for this driver.
  final Driver? driver;

  /// Map of vehicle IDs to names (used when showing driver history).
  final Map<String, String>? vehicleNames;

  const DriverHistoryScreen({
    super.key,
    required this.assignmentRepository,
    required this.driverRepository,
    this.vehicle,
    this.driver,
    this.vehicleNames,
  }) : assert(vehicle != null || driver != null);

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  List<DriverAssignment> _assignments = [];
  Map<String, String> _driverNames = {};
  bool _loading = true;

  bool get _isVehicleMode => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);

    if (_isVehicleMode) {
      _assignments = await widget.assignmentRepository
          .getAssignmentHistory(widget.vehicle!.id);
      // Load driver names
      final drivers = await widget.driverRepository.getAllDrivers();
      _driverNames = {for (var d in drivers) d.id: d.name};
    } else {
      _assignments = await widget.assignmentRepository
          .getDriverAssignments(widget.driver!.id);
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isVehicleMode
            ? 'Riwayat Driver - ${widget.vehicle!.name}'
            : 'Riwayat Kendaraan - ${widget.driver!.name}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _assignments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('Belum ada riwayat penugasan'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    itemCount: _assignments.length,
                    itemBuilder: (context, index) {
                      final assignment = _assignments[index];
                      final subtitle = _isVehicleMode
                          ? _driverNames[assignment.driverId] ??
                              'Driver tidak ditemukan'
                          : widget.vehicleNames?[assignment.vehicleId] ??
                              'Kendaraan tidak ditemukan';

                      return ListTile(
                        leading: CircleAvatar(
                          child: Icon(_isVehicleMode
                              ? Icons.person
                              : Icons.directions_car),
                        ),
                        title: Text(dateFormat.format(assignment.date)),
                        subtitle: Text(subtitle),
                        trailing: assignment.notes != null
                            ? Tooltip(
                                message: assignment.notes!,
                                child: const Icon(Icons.note, size: 20),
                              )
                            : null,
                      );
                    },
                  ),
                ),
    );
  }
}
