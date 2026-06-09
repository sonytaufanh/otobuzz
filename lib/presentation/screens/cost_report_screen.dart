import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import '../../data/repositories/cost_report_repository.dart';
import '../../data/services/pdf_report_service.dart';
import '../../domain/models/maintenance_record.dart';
import '../../domain/models/maintenance_type.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/repositories/maintenance_history_repository.dart';
import '../blocs/cost_report/cost_report_bloc.dart';
import '../blocs/cost_report/cost_report_event.dart';
import '../blocs/cost_report/cost_report_state.dart';
import '../blocs/vehicle/vehicle_bloc.dart';
import '../blocs/vehicle/vehicle_state.dart';

class CostReportScreen extends StatefulWidget {
  const CostReportScreen({super.key});

  @override
  State<CostReportScreen> createState() => _CostReportScreenState();
}

class _CostReportScreenState extends State<CostReportScreen> {
  CostReportPeriod _selectedPeriod = CostReportPeriod.thisMonth;
  String? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  void _loadReport() {
    final now = DateTime.now();
    final dates = _getDateRange(_selectedPeriod, now);
    context.read<CostReportBloc>().add(LoadCostReport(
          vehicleId: _selectedVehicleId,
          from: dates.$1,
          to: dates.$2,
        ));
  }

  (DateTime, DateTime) _getDateRange(CostReportPeriod period, DateTime now) {
    switch (period) {
      case CostReportPeriod.thisMonth:
        return (DateTime(now.year, now.month, 1),
            DateTime(now.year, now.month, now.day, 23, 59, 59));
      case CostReportPeriod.threeMonths:
        return (DateTime(now.year, now.month - 2, 1),
            DateTime(now.year, now.month, now.day, 23, 59, 59));
      case CostReportPeriod.thisYear:
        return (DateTime(now.year, 1, 1),
            DateTime(now.year, now.month, now.day, 23, 59, 59));
      case CostReportPeriod.custom:
        return (DateTime(now.year, now.month, 1),
            DateTime(now.year, now.month, now.day, 23, 59, 59));
    }
  }

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      locale: const Locale('id', 'ID'),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedPeriod = CostReportPeriod.custom;
      });
      context.read<CostReportBloc>().add(LoadCostReport(
            vehicleId: _selectedVehicleId,
            from: picked.start,
            to: DateTime(
                picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Biaya Perawatan'),
        actions: [
          BlocBuilder<CostReportBloc, CostReportState>(
            builder: (context, state) {
              if (state is CostReportLoaded) {
                return IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  tooltip: 'Ekspor PDF',
                  onPressed: () => _exportPdf(context, state),
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: BlocBuilder<CostReportBloc, CostReportState>(
              builder: (context, state) {
                if (state is CostReportLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is CostReportError) {
                  return Center(child: Text(state.message));
                }
                if (state is CostReportLoaded) {
                  return _buildReport(state);
                }
                return const Center(
                  child: Text('Pilih periode untuk melihat laporan'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf(
      BuildContext context, CostReportLoaded state) async {
    // Get vehicle name if filtered
    String? vehicleName;
    if (_selectedVehicleId != null) {
      final vehicleState = context.read<VehicleBloc>().state;
      if (vehicleState is VehicleLoaded) {
        final vehicle = vehicleState.vehicles
            .where((v) => v.id == _selectedVehicleId)
            .firstOrNull;
        vehicleName = vehicle?.name;
      }
    }

    // Get maintenance records for the period
    final historyRepo =
        context.read<MaintenanceHistoryRepository>();
    List<MaintenanceRecord> records = [];
    if (_selectedVehicleId != null) {
      final allRecords =
          await historyRepo.getHistory(_selectedVehicleId!);
      records = allRecords
          .where((r) =>
              !r.serviceDate.isBefore(state.from) &&
              !r.serviceDate.isAfter(state.to))
          .toList();
    } else {
      // Get records for all vehicles in the report
      for (final vehicleCost in state.byVehicle) {
        final allRecords =
            await historyRepo.getHistory(vehicleCost.vehicleId);
        records.addAll(allRecords.where((r) =>
            !r.serviceDate.isBefore(state.from) &&
            !r.serviceDate.isAfter(state.to)));
      }
      records.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
    }

    final pdfService = PdfReportService();
    final pdfBytes = await pdfService.generateMaintenanceCostReport(
      totalCost: state.totalCost,
      costByType: state.byType,
      costByVehicle: state.byVehicle,
      records: records,
      from: state.from,
      to: state.to,
      vehicleName: vehicleName,
    );

    if (!mounted) return;

    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'OtoBuzz_Laporan_Biaya_Perawatan',
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPeriodChip('Bulan Ini', CostReportPeriod.thisMonth),
                const SizedBox(width: 8),
                _buildPeriodChip('3 Bulan', CostReportPeriod.threeMonths),
                const SizedBox(width: 8),
                _buildPeriodChip('Tahun Ini', CostReportPeriod.thisYear),
                const SizedBox(width: 8),
                ActionChip(
                  label: Text(
                    'Kustom',
                    style: TextStyle(
                      color: _selectedPeriod == CostReportPeriod.custom
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                    ),
                  ),
                  backgroundColor: _selectedPeriod == CostReportPeriod.custom
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  onPressed: _selectCustomDateRange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Vehicle filter
          BlocBuilder<VehicleBloc, VehicleState>(
            builder: (context, state) {
              if (state is VehicleLoaded) {
                return _buildVehicleDropdown(state.vehicles);
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, CostReportPeriod period) {
    final isSelected = _selectedPeriod == period;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedPeriod = period);
          _loadReport();
        }
      },
    );
  }

  Widget _buildVehicleDropdown(List<Vehicle> vehicles) {
    return DropdownButtonFormField<String?>(
      initialValue: _selectedVehicleId,
      decoration: const InputDecoration(
        labelText: 'Kendaraan',
        isDense: true,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Semua Kendaraan'),
        ),
        ...vehicles.map((v) => DropdownMenuItem<String?>(
              value: v.id,
              child: Text(v.name),
            )),
      ],
      onChanged: (value) {
        setState(() => _selectedVehicleId = value);
        _loadReport();
      },
    );
  }

  Widget _buildReport(CostReportLoaded state) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Total cost summary card
        _buildTotalCostCard(state.totalCost),
        const SizedBox(height: 16),

        // Monthly trend chart
        if (state.monthly.isNotEmpty) ...[
          _buildSectionTitle('Tren Bulanan'),
          const SizedBox(height: 8),
          _buildMonthlyChart(state.monthly),
          const SizedBox(height: 16),
        ],

        // Cost by type
        if (state.byType.isNotEmpty) ...[
          _buildSectionTitle('Per Jenis Perawatan'),
          const SizedBox(height: 8),
          _buildCostByTypeList(state.byType, state.totalCost),
          const SizedBox(height: 16),
        ],

        // Cost by vehicle
        if (state.byVehicle.isNotEmpty && _selectedVehicleId == null) ...[
          _buildSectionTitle('Per Kendaraan'),
          const SizedBox(height: 8),
          _buildCostByVehicleList(state.byVehicle, state.totalCost),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTotalCostCard(double totalCost) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Total Biaya',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rp ${_formatCurrency(totalCost)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildMonthlyChart(List<MonthlyCostSummary> monthly) {
    final maxCost =
        monthly.fold<double>(0, (max, m) => m.totalCost > max ? m.totalCost : max);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: monthly.map((m) {
              final barHeight = maxCost > 0 ? (m.totalCost / maxCost) * 140 : 0.0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _formatCompactCurrency(m.totalCost),
                        style: Theme.of(context).textTheme.labelSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _monthLabel(m.month),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCostByTypeList(List<CostByType> byType, double totalCost) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: byType.map((item) {
            final percentage =
                totalCost > 0 ? (item.totalCost / totalCost) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.type.displayName,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        'Rp ${_formatCurrency(item.totalCost)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            minHeight: 8,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 45,
                        child: Text(
                          '${(percentage * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.labelSmall,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCostByVehicleList(
      List<CostByVehicle> byVehicle, double totalCost) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: byVehicle.map((item) {
            final percentage =
                totalCost > 0 ? (item.totalCost / totalCost) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.vehicleName,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        'Rp ${_formatCurrency(item.totalCost)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            minHeight: 8,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 45,
                        child: Text(
                          '${(percentage * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.labelSmall,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${item.count} perawatan',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount == 0) return '0';
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    int count = 0;
    for (int i = parts.length - 1; i >= 0; i--) {
      buffer.write(parts[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return buffer.toString().split('').reversed.join();
  }

  String _formatCompactCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return amount.toStringAsFixed(0);
  }

  String _monthLabel(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return months[month - 1];
  }
}
