import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../core/di/service_locator.dart';
import '../../domain/models/trouble_log.dart';
import '../../domain/models/vehicle.dart';
import '../blocs/trouble_log/trouble_log_bloc.dart';

class TroubleLogFormScreen extends StatefulWidget {
  final Vehicle vehicle;
  final TroubleLog? existingLog;

  const TroubleLogFormScreen({
    super.key,
    required this.vehicle,
    this.existingLog,
  });

  @override
  State<TroubleLogFormScreen> createState() => _TroubleLogFormScreenState();
}

class _TroubleLogFormScreenState extends State<TroubleLogFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _odometerController = TextEditingController();
  TroubleSeverity _selectedSeverity = TroubleSeverity.medium;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.existingLog != null) {
      _titleController.text = widget.existingLog!.title;
      _descriptionController.text = widget.existingLog!.description;
      _selectedSeverity = widget.existingLog!.severity;
      _selectedDate = widget.existingLog!.reportedDate;
      if (widget.existingLog!.odometerKm != null) {
        _odometerController.text = widget.existingLog!.odometerKm!.toStringAsFixed(0);
      }
    } else {
      _odometerController.text = widget.vehicle.totalMileageKm.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TroubleLogBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.existingLog == null ? 'Catat Kerusakan' : 'Edit Catatan'),
        ),
        body: BlocListener<TroubleLogBloc, TroubleLogState>(
          listener: (context, state) {
            if (state is TroubleLogLoaded) {
              Navigator.pop(context, true);
            } else if (state is TroubleLogError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${state.message}')),
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Info card
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Catat gejala aneh seperti bunyi, getaran, atau masalah lain sebelum ke bengkel',
                              style: TextStyle(color: Colors.blue.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Judul',
                      hintText: 'Mesin bunyi aneh',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Judul harus diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi Detail',
                      hintText: 'Bunyi tek-tek dari mesin saat akselerasi',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 4,
                    validator: (v) => v == null || v.isEmpty ? 'Deskripsi harus diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  // Severity
                  DropdownButtonFormField<TroubleSeverity>(
                    value: _selectedSeverity,
                    decoration: const InputDecoration(
                      labelText: 'Tingkat Keparahan',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.priority_high),
                    ),
                    items: TroubleSeverity.values.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Row(
                          children: [
                            Text(s.emoji),
                            const SizedBox(width: 8),
                            Text(s.displayName),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedSeverity = v);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Odometer
                  TextFormField(
                    controller: _odometerController,
                    decoration: const InputDecoration(
                      labelText: 'Kilometer (opsional)',
                      hintText: '12345',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.speed),
                      suffixText: 'km',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Date
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Tanggal Kejadian'),
                    subtitle: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit button
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.save),
                    label: Text(widget.existingLog == null ? 'Simpan' : 'Update'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final log = TroubleLog(
      id: widget.existingLog?.id ?? const Uuid().v4(),
      vehicleId: widget.vehicle.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      severity: _selectedSeverity,
      reportedDate: _selectedDate,
      odometerKm: _odometerController.text.isEmpty
          ? null
          : double.tryParse(_odometerController.text),
      isResolved: widget.existingLog?.isResolved ?? false,
      resolvedDate: widget.existingLog?.resolvedDate,
      resolutionNotes: widget.existingLog?.resolutionNotes,
      maintenanceRecordId: widget.existingLog?.maintenanceRecordId,
    );

    if (widget.existingLog == null) {
      context.read<TroubleLogBloc>().add(AddTroubleLog(log));
    } else {
      context.read<TroubleLogBloc>().add(UpdateTroubleLog(log));
    }
  }
}
