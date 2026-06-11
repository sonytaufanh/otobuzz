import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/fuel_record.dart';
import '../blocs/fuel/fuel_bloc.dart';
import '../blocs/fuel/fuel_event.dart';

class FuelFormScreen extends StatefulWidget {
  final String vehicleId;
  final double currentOdometer;

  const FuelFormScreen({
    super.key,
    required this.vehicleId,
    required this.currentOdometer,
  });

  @override
  State<FuelFormScreen> createState() => _FuelFormScreenState();
}

class _FuelFormScreenState extends State<FuelFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _litersController = TextEditingController();
  final _priceController = TextEditingController();
  final _totalCostController = TextEditingController();
  final _odometerController = TextEditingController();
  final _stationController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedFuelType;
  bool _isFullTank = true;
  bool _autoCalculate = true;

  final _fuelTypes = [
    'Pertalite',
    'Pertamax',
    'Pertamax Turbo',
    'Solar',
    'Dexlite',
    'Pertamina Dex',
    'Shell V-Power',
    'Shell Super',
    'BP Ultimate',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _odometerController.text = widget.currentOdometer.toStringAsFixed(0);
    _litersController.addListener(_recalculate);
    _priceController.addListener(_recalculate);
  }

  void _recalculate() {
    if (!_autoCalculate) return;
    final liters = double.tryParse(_litersController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    if (liters > 0 && price > 0) {
      _totalCostController.text = (liters * price).toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _litersController.dispose();
    _priceController.dispose();
    _totalCostController.dispose();
    _odometerController.dispose();
    _stationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final record = FuelRecord(
      id: const Uuid().v4(),
      vehicleId: widget.vehicleId,
      liters: double.parse(_litersController.text),
      pricePerLiter: double.parse(_priceController.text),
      totalCost: double.parse(_totalCostController.text),
      odometerKm: double.parse(_odometerController.text),
      date: _selectedDate,
      stationName:
          _stationController.text.isEmpty ? null : _stationController.text,
      fuelType: _selectedFuelType,
      isFullTank: _isFullTank,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    context.read<FuelBloc>().add(AddFuelRecord(record));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data BBM berhasil disimpan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Isi BBM'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Liters
            TextFormField(
              controller: _litersController,
              decoration: const InputDecoration(
                labelText: 'Jumlah Liter *',
                suffixText: 'L',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Wajib diisi';
                final val = double.tryParse(v);
                if (val == null || val <= 0) return 'Harus > 0';
                if (val > 200) return 'Maksimal 200 liter';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Price per liter
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Harga per Liter *',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Wajib diisi';
                final val = double.tryParse(v);
                if (val == null || val <= 0) return 'Harus > 0';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Total cost
            TextFormField(
              controller: _totalCostController,
              decoration: InputDecoration(
                labelText: 'Total Biaya *',
                prefixText: 'Rp ',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_autoCalculate ? Icons.lock : Icons.lock_open),
                  tooltip: _autoCalculate
                      ? 'Auto-hitung aktif'
                      : 'Input manual aktif',
                  onPressed: () =>
                      setState(() => _autoCalculate = !_autoCalculate),
                ),
              ),
              keyboardType: TextInputType.number,
              readOnly: _autoCalculate,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Wajib diisi';
                final val = double.tryParse(v);
                if (val == null || val <= 0) return 'Harus > 0';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Odometer
            TextFormField(
              controller: _odometerController,
              decoration: const InputDecoration(
                labelText: 'Odometer Saat Isi *',
                suffixText: 'km',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Wajib diisi';
                final val = double.tryParse(v);
                if (val == null || val <= 0) return 'Harus > 0';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Tanggal'),
              subtitle: Text(dateFormat.format(_selectedDate)),
              trailing: const Icon(Icons.edit),
              onTap: _selectDate,
            ),
            const SizedBox(height: 8),

            // Full tank checkbox
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Full Tank'),
              subtitle: const Text(
                  'Centang jika mengisi penuh (untuk hitung konsumsi akurat)'),
              value: _isFullTank,
              onChanged: (v) => setState(() => _isFullTank = v),
            ),
            const SizedBox(height: 16),

            // Fuel type
            DropdownButtonFormField<String>(
              initialValue: _selectedFuelType,
              decoration: const InputDecoration(
                labelText: 'Jenis BBM',
                border: OutlineInputBorder(),
              ),
              items: _fuelTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedFuelType = v),
            ),
            const SizedBox(height: 16),

            // Station
            TextFormField(
              controller: _stationController,
              decoration: const InputDecoration(
                labelText: 'SPBU / Lokasi',
                border: OutlineInputBorder(),
                hintText: 'Contoh: SPBU Shell Sudirman',
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save),
              label: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
