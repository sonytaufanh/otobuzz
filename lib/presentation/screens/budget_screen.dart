import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/budget_repository.dart';
import '../../domain/models/maintenance_budget.dart';
import '../../domain/models/vehicle.dart';

class BudgetScreen extends StatefulWidget {
  final BudgetRepository budgetRepository;
  final List<Vehicle> vehicles;

  const BudgetScreen({
    super.key,
    required this.budgetRepository,
    required this.vehicles,
  });

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  bool _isFleetWide = true;
  String? _selectedVehicleId;
  final _budgetController = TextEditingController();
  BudgetStatus? _currentStatus;
  List<BudgetStatus?> _yearlyOverview = [];
  bool _loading = true;
  MaintenanceBudget? _existingBudget;

  final _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _loadBudget() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    final vehicleId = _isFleetWide ? null : _selectedVehicleId;

    final budget = await widget.budgetRepository.getBudget(
      vehicleId,
      now.year,
      now.month,
    );
    final status = await widget.budgetRepository.getBudgetStatus(
      vehicleId,
      now.year,
      now.month,
    );
    final yearly = await widget.budgetRepository.getYearlyBudgetOverview(
      vehicleId,
      now.year,
    );

    setState(() {
      _existingBudget = budget;
      _budgetController.text = budget != null
          ? budget.monthlyBudget.round().toString()
          : '';
      _currentStatus = status;
      _yearlyOverview = yearly;
      _loading = false;
    });
  }

  Future<void> _saveBudget() async {
    final amountText = _budgetController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan jumlah budget')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah budget tidak valid')),
      );
      return;
    }

    final now = DateTime.now();
    final vehicleId = _isFleetWide ? null : _selectedVehicleId;

    final budget = MaintenanceBudget(
      id: _existingBudget?.id ?? const Uuid().v4(),
      vehicleId: vehicleId,
      monthlyBudget: amount,
      year: now.year,
      month: now.month,
    );

    await widget.budgetRepository.setBudget(budget);
    await _loadBudget();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget berhasil disimpan')),
      );
    }
  }

  Color _budgetColor(BudgetLevel level) {
    switch (level) {
      case BudgetLevel.under:
        return Colors.green;
      case BudgetLevel.warning:
        return Colors.orange;
      case BudgetLevel.over:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Perawatan'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Toggle fleet-wide vs per vehicle
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Atur Budget Bulanan',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: true,
                              label: Text('Semua Kendaraan'),
                              icon: Icon(Icons.local_shipping),
                            ),
                            ButtonSegment(
                              value: false,
                              label: Text('Per Kendaraan'),
                              icon: Icon(Icons.directions_car),
                            ),
                          ],
                          selected: {_isFleetWide},
                          onSelectionChanged: (values) {
                            setState(() {
                              _isFleetWide = values.first;
                              if (!_isFleetWide &&
                                  _selectedVehicleId == null &&
                                  widget.vehicles.isNotEmpty) {
                                _selectedVehicleId = widget.vehicles.first.id;
                              }
                            });
                            _loadBudget();
                          },
                        ),
                        if (!_isFleetWide) ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedVehicleId,
                            decoration: const InputDecoration(
                              labelText: 'Pilih Kendaraan',
                              border: OutlineInputBorder(),
                            ),
                            items: widget.vehicles
                                .map((v) => DropdownMenuItem(
                                      value: v.id,
                                      child: Text(v.name),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedVehicleId = value);
                              _loadBudget();
                            },
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextField(
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Budget Bulanan (Rp)',
                            prefixText: 'Rp ',
                            border: OutlineInputBorder(),
                            hintText: '500000',
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _saveBudget,
                          icon: const Icon(Icons.save),
                          label: const Text('Simpan Budget'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 44),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Current month status
                if (_currentStatus != null) ...[
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                ],

                // Yearly overview
                if (_yearlyOverview.any((s) => s != null)) ...[
                  _buildYearlyOverview(),
                ],
              ],
            ),
    );
  }

  Widget _buildStatusCard() {
    final status = _currentStatus!;
    final color = _budgetColor(status.level);
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy', 'id').format(now);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget bulan ini: $monthName',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (status.percentage / 100).clamp(0.0, 1.5),
                minHeight: 20,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 8),
            // Amount display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Terpakai: ${_currencyFormat.format(status.spent)}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${status.percentage.round()}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Budget: ${_currencyFormat.format(status.budget)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            if (status.remaining >= 0)
              Text(
                'Sisa: ${_currencyFormat.format(status.remaining)}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              Text(
                '⚠️ Budget terlampaui! Melebihi: ${_currencyFormat.format(-status.remaining)}',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearlyOverview() {
    final now = DateTime.now();
    final monthNames = List.generate(
      12,
      (i) => DateFormat('MMM', 'id').format(DateTime(now.year, i + 1)),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan Tahunan ${now.year}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(12, (index) {
                  final status = _yearlyOverview[index];
                  final percentage = status?.percentage ?? 0;
                  final barHeight = (percentage / 100).clamp(0.0, 1.0) * 80;
                  final color = status != null
                      ? _budgetColor(status.level)
                      : Colors.grey[300]!;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (status != null)
                            Text(
                              '${percentage.round()}%',
                              style: TextStyle(
                                fontSize: 8,
                                color: color,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Container(
                            height: barHeight > 0 ? barHeight : 4,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            monthNames[index],
                            style: TextStyle(
                              fontSize: 9,
                              color: index + 1 == now.month
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                              fontWeight: index + 1 == now.month
                                  ? FontWeight.bold
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
