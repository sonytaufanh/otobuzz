import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/models/vehicle.dart';
import '../blocs/mileage/mileage_bloc.dart';
import '../blocs/mileage/mileage_event.dart';
import '../blocs/mileage/mileage_state.dart';

class MileageHistoryScreen extends StatefulWidget {
  final Vehicle vehicle;

  const MileageHistoryScreen({super.key, required this.vehicle});

  @override
  State<MileageHistoryScreen> createState() => _MileageHistoryScreenState();
}

class _MileageHistoryScreenState extends State<MileageHistoryScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    context.read<MileageBloc>().add(LoadMileageHistory(
          vehicleId: widget.vehicle.id,
          from: _fromDate,
          to: _toDate,
        ));
  }

  Future<void> _selectFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2000),
      lastDate: _toDate ?? DateTime.now(),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) {
      setState(() => _fromDate = picked);
      _loadHistory();
    }
  }

  Future<void> _selectToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) {
      setState(() => _toDate = picked);
      _loadHistory();
    }
  }

  void _clearFilter() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,###', 'id_ID');

    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat KM - ${widget.vehicle.name}'),
      ),
      body: BlocBuilder<MileageBloc, MileageState>(
        builder: (context, state) {
          if (state is MileageLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MileageHistoryLoaded) {
            return Column(
              children: [
                // Summary card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SummaryColumn(
                          label: 'Total',
                          value: '${numberFormat.format(state.totalKm.round())} km',
                        ),
                        _SummaryColumn(
                          label: 'Rata-rata/hari',
                          value: '${state.avgDailyKm.toStringAsFixed(1)} km',
                        ),
                        _SummaryColumn(
                          label: 'Catatan',
                          value: '${state.records.length}',
                        ),
                      ],
                    ),
                  ),
                ),

                // Date filter row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _selectFromDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Dari',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              isDense: true,
                            ),
                            child: Text(
                              _fromDate != null
                                  ? dateFormat.format(_fromDate!)
                                  : 'Semua',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: _selectToDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Sampai',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              isDense: true,
                            ),
                            child: Text(
                              _toDate != null
                                  ? dateFormat.format(_toDate!)
                                  : 'Hari ini',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ),
                      if (_fromDate != null || _toDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Hapus filter',
                          onPressed: _clearFilter,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Running total info
                if (state.records.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.trending_up, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Total jarak: ${numberFormat.format(_calculateRunningTotal(state).round())} km',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            Text(
                              'Rata-rata: ${_calculateAverage(state).toStringAsFixed(1)} km/hari',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),

                // Records list
                Expanded(
                  child: state.records.isEmpty
                      ? const Center(child: Text('Belum ada catatan km'))
                      : ListView.builder(
                          itemCount: state.records.length,
                          itemBuilder: (context, index) {
                            final record = state.records[index];
                            return ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.speed),
                              ),
                              title: Text('${record.km.round()} km'),
                              subtitle: Text(dateFormat.format(record.date)),
                              trailing: record.notes != null
                                  ? Tooltip(
                                      message: record.notes!,
                                      child: const Icon(Icons.note, size: 16),
                                    )
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  double _calculateRunningTotal(MileageHistoryLoaded state) {
    return state.records.fold(0.0, (sum, r) => sum + r.km);
  }

  double _calculateAverage(MileageHistoryLoaded state) {
    if (state.records.isEmpty) return 0;
    return _calculateRunningTotal(state) / state.records.length;
  }
}

class _SummaryColumn extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
