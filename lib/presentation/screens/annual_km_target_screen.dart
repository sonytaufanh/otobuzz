import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/di/service_locator.dart';
import '../../domain/models/annual_km_target.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/repositories/annual_km_target_repository.dart';
import '../../domain/repositories/mileage_repository.dart';

class AnnualKmTargetScreen extends StatefulWidget {
  final Vehicle vehicle;

  const AnnualKmTargetScreen({super.key, required this.vehicle});

  @override
  State<AnnualKmTargetScreen> createState() => _AnnualKmTargetScreenState();
}

class _AnnualKmTargetScreenState extends State<AnnualKmTargetScreen> {
  final _repository = sl<AnnualKmTargetRepository>();
  final _mileageRepository = sl<MileageRepository>();
  final _numberFormat = NumberFormat('#,###', 'id_ID');

  int _selectedYear = DateTime.now().year;
  AnnualKmTarget? _currentTarget;
  double _kmThisYear = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final target = await _repository.getTarget(widget.vehicle.id, _selectedYear);
    final records = await _mileageRepository.getRecordsByDateRange(
      DateTime(_selectedYear, 1, 1),
      DateTime(_selectedYear, 12, 31),
      vehicleId: widget.vehicle.id,
    );
    final kmThisYear = records.fold<double>(0, (sum, r) => sum + r.km);
    setState(() {
      _currentTarget = target;
      _kmThisYear = kmThisYear;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final progress = _currentTarget != null && _currentTarget!.targetKm > 0
        ? (_kmThisYear / _currentTarget!.targetKm).clamp(0.0, 1.0)
        : 0.0;
    final remaining = _currentTarget != null
        ? (_currentTarget!.targetKm - _kmThisYear).clamp(0.0, double.infinity)
        : 0.0;
    final dayOfYear = DateTime.now().difference(DateTime(_selectedYear, 1, 1)).inDays + 1;
    final daysInYear = DateTime(_selectedYear, 12, 31).difference(DateTime(_selectedYear, 1, 1)).inDays + 1;
    final expectedProgress = _selectedYear == currentYear ? dayOfYear / daysInYear : 1.0;
    final isOnTrack = progress >= expectedProgress * 0.9;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Target KM Tahunan'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Year selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() => _selectedYear--);
                          _loadData();
                        },
                      ),
                      Text(
                        '$_selectedYear',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _selectedYear >= currentYear
                            ? null
                            : () {
                                setState(() => _selectedYear++);
                                _loadData();
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.directions_car, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                widget.vehicle.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (_currentTarget == null) ...[
                            const Center(
                              child: Text(
                                'Belum ada target untuk tahun ini',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ] else ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Sudah ditempuh',
                                        style: Theme.of(context).textTheme.bodySmall),
                                    Text(
                                      '${_numberFormat.format(_kmThisYear)} km',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Target',
                                        style: Theme.of(context).textTheme.bodySmall),
                                    Text(
                                      '${_numberFormat.format(_currentTarget!.targetKm)} km',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: progress,
                              minHeight: 12,
                              borderRadius: BorderRadius.circular(6),
                              backgroundColor: Colors.grey.shade200,
                              color: isOnTrack ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${(progress * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: isOnTrack ? Colors.green : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_selectedYear == currentYear)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isOnTrack
                                          ? Colors.green.shade100
                                          : Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isOnTrack ? '✅ On Track' : '⚠️ Perlu Tambah KM',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isOnTrack
                                            ? Colors.green.shade800
                                            : Colors.orange.shade800,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Stats row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    context,
                                    'Sisa',
                                    '${_numberFormat.format(remaining)} km',
                                    Icons.flag,
                                    Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStatCard(
                                    context,
                                    'Rata-rata/hari',
                                    '${(dayOfYear > 0 ? _kmThisYear / dayOfYear : 0).toStringAsFixed(1)} km',
                                    Icons.today,
                                    Colors.purple,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_selectedYear == currentYear && remaining > 0)
                                  Expanded(
                                    child: _buildStatCard(
                                      context,
                                      'Target/hari',
                                      '${(remaining / (daysInYear - dayOfYear + 1)).toStringAsFixed(1)} km',
                                      Icons.speed,
                                      Colors.teal,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Set / Edit target button
                  FilledButton.icon(
                    onPressed: () => _showSetTargetDialog(context),
                    icon: Icon(_currentTarget == null ? Icons.add : Icons.edit),
                    label: Text(_currentTarget == null
                        ? 'Set Target $_selectedYear'
                        : 'Ubah Target'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  if (_currentTarget != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context),
                      icon: const Icon(Icons.delete),
                      label: const Text('Hapus Target'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Future<void> _showSetTargetDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: _currentTarget?.targetKm.toStringAsFixed(0) ?? '',
    );
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Target KM $_selectedYear'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Masukkan target kilometer yang ingin dicapai di tahun $_selectedYear',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Target KM',
                hintText: '15000',
                border: OutlineInputBorder(),
                suffixText: 'km',
                prefixIcon: Icon(Icons.speed),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final km = double.tryParse(controller.text);
              if (km != null && km > 0) Navigator.pop(ctx, km);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != null) {
      final target = AnnualKmTarget(
        id: _currentTarget?.id ?? const Uuid().v4(),
        vehicleId: widget.vehicle.id,
        year: _selectedYear,
        targetKm: result,
        createdAt: _currentTarget?.createdAt ?? DateTime.now(),
      );
      await _repository.setTarget(target);
      _loadData();
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Target'),
        content: Text('Hapus target KM tahun $_selectedYear?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (result == true && _currentTarget != null) {
      await _repository.deleteTarget(_currentTarget!.id);
      _loadData();
    }
  }
}
