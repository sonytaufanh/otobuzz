import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/models/models.dart';
import '../blocs/maintenance/maintenance_bloc.dart';
import '../blocs/maintenance/maintenance_event.dart';
import '../blocs/maintenance/maintenance_state.dart';

class MaintenanceFormScreen extends StatefulWidget {
  final Vehicle vehicle;

  const MaintenanceFormScreen({super.key, required this.vehicle});

  @override
  State<MaintenanceFormScreen> createState() => _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends State<MaintenanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mileageController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  final _workshopController = TextEditingController();
  MaintenanceType? _selectedType;
  DateTime _serviceDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _mileageController.text = widget.vehicle.totalMileageKm.round().toString();
  }

  @override
  void dispose() {
    _mileageController.dispose();
    _costController.dispose();
    _notesController.dispose();
    _workshopController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _serviceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) {
      setState(() => _serviceDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jenis perawatan')),
      );
      return;
    }

    context.read<MaintenanceBloc>().add(RecordMaintenance(
          vehicleId: widget.vehicle.id,
          type: _selectedType!,
          mileageAtService: double.parse(_mileageController.text),
          serviceDate: _serviceDate,
          cost: _costController.text.isNotEmpty
              ? double.tryParse(_costController.text.replaceAll('.', ''))
              : null,
          notes:
              _notesController.text.isNotEmpty ? _notesController.text : null,
          workshopName: _workshopController.text.isNotEmpty
              ? _workshopController.text
              : null,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final applicableTypes = getApplicableTypes(widget.vehicle.type);

    return BlocListener<MaintenanceBloc, MaintenanceState>(
      listener: (context, state) {
        if (state is MaintenanceRecorded) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          Navigator.pop(context);
        } else if (state is MaintenanceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Catat Perawatan')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Vehicle info
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: ListTile(
                  leading: Icon(
                    widget.vehicle.type == VehicleType.motorcycle
                        ? Icons.two_wheeler
                        : Icons.directions_car,
                  ),
                  title: Text(widget.vehicle.name),
                  subtitle: Text(widget.vehicle.plateNumber),
                ),
              ),
              const SizedBox(height: 16),

              // Maintenance type
              DropdownButtonFormField<MaintenanceType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Jenis Perawatan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.build),
                ),
                items: applicableTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (type) => setState(() => _selectedType = type),
                validator: (v) => v == null ? 'Pilih jenis perawatan' : null,
              ),
              const SizedBox(height: 16),

              // Mileage at service
              TextFormField(
                controller: _mileageController,
                decoration: const InputDecoration(
                  labelText: 'KM Saat Servis',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.speed),
                  suffixText: 'km',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Masukkan km saat servis';
                  }
                  final km = double.tryParse(value);
                  if (km == null || km < 0) {
                    return 'Masukkan angka yang valid';
                  }
                  if (km > widget.vehicle.totalMileageKm) {
                    return 'Tidak boleh lebih dari total km kendaraan';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Servis',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(dateFormat.format(_serviceDate)),
                ),
              ),
              const SizedBox(height: 16),

              // Cost (optional)
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(
                  labelText: 'Biaya (opsional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payments),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Workshop (optional)
              TextFormField(
                controller: _workshopController,
                decoration: const InputDecoration(
                  labelText: 'Nama Bengkel (opsional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
              ),
              const SizedBox(height: 16),

              // Notes (optional)
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: const Text('Simpan Perawatan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
