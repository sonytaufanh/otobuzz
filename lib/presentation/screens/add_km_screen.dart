import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/semantics_labels.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/models/vehicle_type.dart';
import '../blocs/mileage/mileage_bloc.dart';
import '../blocs/mileage/mileage_event.dart';
import '../blocs/mileage/mileage_state.dart';
import '../blocs/vehicle/vehicle_bloc.dart';
import '../blocs/vehicle/vehicle_state.dart';
import '../widgets/duplicate_entry_dialog.dart';
import '../widgets/gradient_button.dart';

/// Key used in SharedPreferences to persist the last selected vehicle ID.
const String _lastVehicleIdKey = 'last_selected_vehicle_id';

class AddKmScreen extends StatefulWidget {
  final Vehicle? preselectedVehicle;

  const AddKmScreen({super.key, this.preselectedVehicle});

  @override
  State<AddKmScreen> createState() => _AddKmScreenState();
}

class _AddKmScreenState extends State<AddKmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kmController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  Vehicle? _selectedVehicle;
  String? _lastSavedVehicleId;

  @override
  void initState() {
    super.initState();
    _selectedVehicle = widget.preselectedVehicle;
    _loadLastSelectedVehicle();
  }

  Future<void> _loadLastSelectedVehicle() async {
    if (_selectedVehicle != null) return; // preselected takes priority
    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getString(_lastVehicleIdKey);
    if (lastId != null && mounted) {
      setState(() {
        _lastSavedVehicleId = lastId;
      });
    }
  }

  Future<void> _saveLastSelectedVehicle(String vehicleId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastVehicleIdKey, vehicleId);
  }

  @override
  void dispose() {
    _kmController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit({bool replaceDuplicate = false}) {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kendaraan terlebih dahulu')),
      );
      return;
    }

    context.read<MileageBloc>().add(AddMileage(
          vehicleId: _selectedVehicle!.id,
          km: double.parse(_kmController.text),
          date: _selectedDate,
          notes:
              _notesController.text.isNotEmpty ? _notesController.text : null,
          replaceDuplicate: replaceDuplicate,
        ));
  }

  void _showDuplicateDialog(MileageDuplicateFound state) async {
    final shouldReplace = await DuplicateEntryDialog.show(
      context,
      existingKm: state.existingKm,
    );
    if (shouldReplace) {
      _submit(replaceDuplicate: true);
    }
  }

  /// Resolves the initial vehicle from the loaded vehicle list using persisted ID.
  Vehicle? _resolveInitialVehicle(List<Vehicle> vehicles) {
    if (_selectedVehicle != null) {
      // Check if the selected vehicle is still in the list
      final match = vehicles.where((v) => v.id == _selectedVehicle!.id);
      if (match.isNotEmpty) return match.first;
    }
    if (_lastSavedVehicleId != null) {
      final match = vehicles.where((v) => v.id == _lastSavedVehicleId);
      if (match.isNotEmpty) return match.first;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return BlocListener<MileageBloc, MileageState>(
      listener: (context, state) {
        if (state is MileageAdded) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'KM berhasil dicatat! Total: ${state.updatedVehicle.totalMileageKm.round()} km'),
            ),
          );
          Navigator.pop(context);
        } else if (state is MileageDuplicateFound) {
          _showDuplicateDialog(state);
        } else if (state is MileageError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Catat Kilometer Harian'),
              Text(
                'Rekam perjalanan harian Anda',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Header illustration area
              Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                ),
                child: const Center(
                  child: Icon(
                    Icons.speed_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Vehicle selector
              BlocBuilder<VehicleBloc, VehicleState>(
                builder: (context, state) {
                  if (state is VehicleLoaded) {
                    // Auto-select persisted vehicle on first build
                    if (_selectedVehicle == null && state.vehicles.isNotEmpty) {
                      final resolved = _resolveInitialVehicle(state.vehicles);
                      if (resolved != null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _selectedVehicle == null) {
                            setState(() => _selectedVehicle = resolved);
                          }
                        });
                      }
                    }
                    final currentValue = _selectedVehicle != null &&
                            state.vehicles
                                .any((v) => v.id == _selectedVehicle!.id)
                        ? state.vehicles
                            .firstWhere((v) => v.id == _selectedVehicle!.id)
                        : null;
                    return DropdownButtonFormField<Vehicle>(
                      // ignore: deprecated_member_use
                      value: currentValue,
                      decoration: const InputDecoration(
                        labelText: 'Kendaraan',
                        prefixIcon: Icon(Icons.directions_car_outlined),
                      ),
                      items: state.vehicles.map((v) {
                        return DropdownMenuItem(
                          value: v,
                          child: Row(
                            children: [
                              Icon(
                                v.type == VehicleType.motorcycle
                                    ? Icons.two_wheeler
                                    : Icons.directions_car,
                                size: 20,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${v.name} (${v.plateNumber})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        setState(() => _selectedVehicle = v);
                        if (v != null) {
                          _saveLastSelectedVehicle(v.id);
                        }
                      },
                      validator: (v) => v == null ? 'Pilih kendaraan' : null,
                    );
                  }
                  return const LinearProgressIndicator();
                },
              ),
              const SizedBox(height: 20),

              // KM input — prominent and large
              Semantics(
                label: AppSemantics.kmInputField,
                child: TextFormField(
                  controller: _kmController,
                  decoration: const InputDecoration(
                    labelText: 'Jarak tempuh hari ini (km)',
                    hintText: 'Masukkan km yang ditempuh',
                    prefixIcon: Icon(Icons.speed_outlined),
                    suffixText: 'km',
                  ),
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan jarak tempuh';
                    }
                    final km = double.tryParse(value);
                    if (km == null || km < 1 || km > 2000) {
                      return 'Masukkan jarak yang valid (1-2000 km)';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Date picker — card-like button
              Semantics(
                label: AppSemantics.dateSelector,
                button: true,
                child: InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: AppTheme.softShadow,
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tanggal',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateFormat.format(_selectedDate),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  hintText: 'contoh: perjalanan ke Bandung',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // Current total display
              if (_selectedVehicle != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppTheme.secondaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Total km saat ini: ${_selectedVehicle!.totalMileageKm.round()} km',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.secondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Premium submit button
              BlocBuilder<MileageBloc, MileageState>(
                builder: (context, state) {
                  return Semantics(
                    label: AppSemantics.submitKmButton,
                    button: true,
                    child: GradientButton(
                      text: 'Simpan',
                      onPressed: _submit,
                      gradient: AppTheme.primaryGradient,
                      icon: Icons.save_rounded,
                      isLoading: state is MileageLoading,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
