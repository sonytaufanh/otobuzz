import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/di/service_locator.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/usecases/predict_maintenance_cost_usecase.dart';

class MaintenanceCostPredictionScreen extends StatefulWidget {
  final Vehicle vehicle;

  const MaintenanceCostPredictionScreen({super.key, required this.vehicle});

  @override
  State<MaintenanceCostPredictionScreen> createState() =>
      _MaintenanceCostPredictionScreenState();
}

class _MaintenanceCostPredictionScreenState
    extends State<MaintenanceCostPredictionScreen> {
  final _useCase = sl<PredictMaintenanceCostUseCase>();
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  int _selectedDays = 30;
  MaintenanceCostPrediction? _prediction;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrediction();
  }

  Future<void> _loadPrediction() async {
    setState(() => _isLoading = true);
    final prediction = await _useCase.execute(
      vehicleId: widget.vehicle.id,
      daysAhead: _selectedDays,
    );
    setState(() {
      _prediction = prediction;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prediksi Biaya Perawatan'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Period selector
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Periode Prediksi',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          SegmentedButton<int>(
                            segments: const [
                              ButtonSegment(value: 30, label: Text('30 hari')),
                              ButtonSegment(value: 60, label: Text('60 hari')),
                              ButtonSegment(value: 90, label: Text('90 hari')),
                            ],
                            selected: {_selectedDays},
                            onSelectionChanged: (selected) {
                              setState(() => _selectedDays = selected.first);
                              _loadPrediction();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Total cost card
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            size: 48,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Estimasi Total Biaya',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _prediction!.totalEstimatedCost > 0
                                ? _currencyFormat
                                    .format(_prediction!.totalEstimatedCost)
                                : 'Tidak ada data',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Dalam $_selectedDays hari ke depan',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info card
                  if (_prediction!.upcomingMaintenance.isEmpty)
                    Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Tidak ada perawatan yang jatuh tempo dalam $_selectedDays hari ke depan 🎉',
                                style: TextStyle(color: Colors.green.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    Text(
                      'Perawatan yang Jatuh Tempo',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ...(_prediction!.upcomingMaintenance.map((item) {
                      final hasEstimate = item.estimatedCost != null;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.type.displayName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getDaysColor(item.daysUntilDue),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${item.daysUntilDue} hari lagi',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Jatuh tempo: ${_dateFormat.format(item.schedule.dueByDate)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.speed, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Sisa: ${item.schedule.remainingKm.toStringAsFixed(0)} km',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    hasEstimate
                                        ? Icons.attach_money
                                        : Icons.help_outline,
                                    size: 20,
                                    color: hasEstimate
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    hasEstimate
                                        ? 'Estimasi: ${_currencyFormat.format(item.estimatedCost)}'
                                        : 'Belum ada data biaya',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: hasEstimate
                                          ? Colors.green.shade700
                                          : Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              if (!hasEstimate) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Catatlah biaya saat servis nanti untuk prediksi lebih akurat',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    })),
                  ],

                  const SizedBox(height: 16),
                  // Tips card
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_outline,
                              color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tips',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Prediksi ini berdasarkan rata-rata biaya 5 servis terakhir. Biaya aktual bisa berbeda tergantung kondisi dan bengkel.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Color _getDaysColor(int days) {
    if (days <= 7) return Colors.red;
    if (days <= 14) return Colors.orange;
    if (days <= 30) return Colors.amber;
    return Colors.green;
  }
}
