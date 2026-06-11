import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/models/vehicle_type.dart';
import '../blocs/vehicle/vehicle_bloc.dart';
import '../blocs/vehicle/vehicle_event.dart';
import '../blocs/vehicle/vehicle_state.dart';
import '../widgets/gradient_button.dart';

class VehicleFormScreen extends StatefulWidget {
  final Vehicle? vehicle; // null for add, non-null for edit

  const VehicleFormScreen({super.key, this.vehicle});

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _plateController = TextEditingController();
  final _yearController = TextEditingController();
  VehicleType _selectedType = VehicleType.motorcycle;

  bool get isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    if (widget.vehicle != null) {
      _nameController.text = widget.vehicle!.name;
      _plateController.text = widget.vehicle!.plateNumber;
      _yearController.text = widget.vehicle!.year.toString();
      _selectedType = widget.vehicle!.type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  String? _validatePlateNumber(String? value) {
    return validatePlateNumber(value);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final vehicle = Vehicle(
      id: widget.vehicle?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      type: _selectedType,
      plateNumber: _plateController.text.trim().toUpperCase(),
      year: int.parse(_yearController.text),
      totalMileageKm: widget.vehicle?.totalMileageKm ?? 0,
      createdAt: widget.vehicle?.createdAt ?? DateTime.now(),
    );

    if (isEditing) {
      context.read<VehicleBloc>().add(UpdateVehicle(vehicle));
    } else {
      context.read<VehicleBloc>().add(AddVehicle(vehicle));
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = isEditing ? AppTheme.tealGradient : AppTheme.primaryGradient;

    return BlocListener<VehicleBloc, VehicleState>(
      listener: (context, state) {
        if (state is VehicleOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          Navigator.pop(context);
        } else if (state is VehicleError) {
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
              Text(isEditing ? 'Edit Kendaraan' : 'Tambah Kendaraan'),
              Text(
                'Isi data kendaraan Anda',
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
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                ),
                child: Center(
                  child: Icon(
                    isEditing ? Icons.edit_note_rounded : Icons.directions_car_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Kendaraan',
                  hintText: 'contoh: Vario 160, Avanza 2020',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                maxLength: 50,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama kendaraan wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Vehicle type selector
              if (!isEditing) ...[
                Text(
                  'Tipe Kendaraan',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: AppTheme.softShadow,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: SegmentedButton<VehicleType>(
                    segments: const [
                      ButtonSegment(
                        value: VehicleType.motorcycle,
                        icon: Icon(Icons.two_wheeler),
                        label: Text('Motor'),
                      ),
                      ButtonSegment(
                        value: VehicleType.car,
                        icon: Icon(Icons.directions_car),
                        label: Text('Mobil'),
                      ),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (set) {
                      setState(() => _selectedType = set.first);
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppTheme.primaryColor.withValues(alpha: 0.1);
                        }
                        return Colors.transparent;
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Plate number field
              TextFormField(
                controller: _plateController,
                decoration: const InputDecoration(
                  labelText: 'Nomor Plat',
                  hintText: 'contoh: B 1234 XYZ',
                  prefixIcon: Icon(Icons.pin_outlined),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: _validatePlateNumber,
              ),
              const SizedBox(height: 20),

              // Year field
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(
                  labelText: 'Tahun',
                  hintText: 'contoh: 2023',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tahun wajib diisi';
                  }
                  final year = int.tryParse(value);
                  if (year == null ||
                      year < 1970 ||
                      year > DateTime.now().year + 1) {
                    return 'Tahun harus antara 1970 - ${DateTime.now().year + 1}';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Premium submit button
              GradientButton(
                text: isEditing ? 'Simpan Perubahan' : 'Tambah Kendaraan',
                onPressed: _submit,
                gradient: gradient,
                icon: isEditing ? Icons.save_rounded : Icons.add_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
