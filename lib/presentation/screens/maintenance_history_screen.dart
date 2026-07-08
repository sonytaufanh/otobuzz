import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/models/models.dart';
import '../blocs/maintenance/maintenance_bloc.dart';
import '../blocs/maintenance/maintenance_event.dart';
import '../blocs/maintenance/maintenance_state.dart';

class MaintenanceHistoryScreen extends StatefulWidget {
  final Vehicle vehicle;

  const MaintenanceHistoryScreen({super.key, required this.vehicle});

  @override
  State<MaintenanceHistoryScreen> createState() =>
      _MaintenanceHistoryScreenState();
}

class _MaintenanceHistoryScreenState extends State<MaintenanceHistoryScreen> {
  MaintenanceType? _filterType;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    context.read<MaintenanceBloc>().add(LoadMaintenanceHistory(
          vehicleId: widget.vehicle.id,
          filterType: _filterType,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final applicableTypes = getApplicableTypes(widget.vehicle.type,
        transmissionType: widget.vehicle.transmissionType);

    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Perawatan - ${widget.vehicle.name}'),
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Semua'),
                  selected: _filterType == null,
                  onSelected: (selected) {
                    setState(() => _filterType = null);
                    _loadHistory();
                  },
                ),
                const SizedBox(width: 8),
                ...applicableTypes.map((type) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(type.displayName),
                        selected: _filterType == type,
                        onSelected: (selected) {
                          setState(
                              () => _filterType = selected ? type : null);
                          _loadHistory();
                        },
                      ),
                    )),
              ],
            ),
          ),
          // History list
          Expanded(
            child: BlocBuilder<MaintenanceBloc, MaintenanceState>(
              builder: (context, state) {
                if (state is MaintenanceLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is MaintenanceHistoryLoaded) {
                  return Column(
                    children: [
                      // Total cost summary
                      if (state.totalCost > 0)
                        Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.payments, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Total biaya: ${currencyFormat.format(state.totalCost)}',
                                  style:
                                      Theme.of(context).textTheme.titleSmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      Expanded(
                        child: state.records.isEmpty
                            ? const Center(
                                child: Text('Belum ada riwayat perawatan'))
                            : ListView.builder(
                                itemCount: state.records.length,
                                itemBuilder: (context, index) {
                                  final record = state.records[index];
                                  return ExpansionTile(
                                    leading: CircleAvatar(
                                      child: Icon(_getIconForType(record.type)),
                                    ),
                                    title: Text(record.type.displayName),
                                    subtitle: Text(
                                      '${dateFormat.format(record.serviceDate)} • ${record.mileageAtService.round()} km'
                                      '${record.workshopName != null ? ' • ${record.workshopName}' : ''}',
                                    ),
                                    trailing: record.cost != null
                                        ? Text(
                                            currencyFormat
                                                .format(record.cost),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          )
                                        : null,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.lightbulb_outline,
                                                    size: 18,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    record.type.description,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: Theme.of(context)
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (record.workshopName != null) ...[
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Icon(Icons.store, size: 16),
                                                  const SizedBox(width: 6),
                                                  Text(record.workshopName!,
                                                      style: Theme.of(context).textTheme.bodySmall),
                                                  const Spacer(),
                                                  // Star rating display
                                                  if (record.workshopRating != null)
                                                    Row(
                                                      children: List.generate(5, (i) => Icon(
                                                        i < record.workshopRating! ? Icons.star : Icons.star_border,
                                                        size: 16,
                                                        color: Colors.amber,
                                                      )),
                                                    ),
                                                  const SizedBox(width: 8),
                                                  TextButton.icon(
                                                    onPressed: () => _showRatingDialog(context, record),
                                                    icon: Icon(
                                                      record.workshopRating != null ? Icons.edit : Icons.star_outline,
                                                      size: 16,
                                                    ),
                                                    label: Text(record.workshopRating != null ? 'Edit Rating' : 'Beri Rating'),
                                                    style: TextButton.styleFrom(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                                      visualDensity: VisualDensity.compact,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (record.workshopReview != null) ...[
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.format_quote, size: 14, color: Colors.grey),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        record.workshopReview!,
                                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                          fontStyle: FontStyle.italic,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
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
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.oilChange:
        return Icons.oil_barrel;
      case MaintenanceType.tireReplacement:
        return Icons.tire_repair;
      case MaintenanceType.brakePads:
        return Icons.do_not_step;
      case MaintenanceType.airFilter:
        return Icons.air;
      case MaintenanceType.sparkPlug:
        return Icons.bolt;
      case MaintenanceType.chainLube:
        return Icons.link;
      case MaintenanceType.chainAdjust:
        return Icons.tune;
      case MaintenanceType.coolant:
        return Icons.water_drop;
      case MaintenanceType.brakeFluid:
        return Icons.water;
      case MaintenanceType.brakeFluidFlush:
        return Icons.cleaning_services;
      case MaintenanceType.transmission:
        return Icons.settings;
      case MaintenanceType.finalDriveOil:
        return Icons.settings_suggest;
      case MaintenanceType.cvtRoller:
        return Icons.circle;
      case MaintenanceType.cvtVBelt:
        return Icons.timeline;
      case MaintenanceType.cvtClutchShoe:
        return Icons.do_not_step;
      case MaintenanceType.cvtDrivePlate:
        return Icons.album;
      case MaintenanceType.cvtSpring:
        return Icons.compress;
      case MaintenanceType.clutchPlate:
        return Icons.do_not_step;
      case MaintenanceType.valveAdjust:
        return Icons.tune;
      case MaintenanceType.throttleBodyClean:
        return Icons.cleaning_services;
      case MaintenanceType.injectorClean:
        return Icons.cleaning_services;
      case MaintenanceType.battery:
        return Icons.battery_charging_full;
      case MaintenanceType.wheelBearing:
        return Icons.settings;
      case MaintenanceType.suspension:
        return Icons.airline_seat_recline_normal;
    }
  }

  Future<void> _showRatingDialog(BuildContext context, MaintenanceRecord record) async {
    int rating = record.workshopRating ?? 0;
    final reviewController = TextEditingController(text: record.workshopReview ?? '');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Rating ${record.workshopName ?? "Bengkel"}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return IconButton(
                      icon: Icon(
                        i < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 36,
                      ),
                      onPressed: () => setState(() => rating = i + 1),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reviewController,
                  decoration: const InputDecoration(
                    labelText: 'Review (opsional)',
                    hintText: 'Pelayanan ramah, harga terjangkau',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: rating > 0
                  ? () => Navigator.pop(ctx, {
                        'rating': rating,
                        'review': reviewController.text.isEmpty ? null : reviewController.text,
                      })
                  : null,
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (result != null && context.mounted) {
      final updatedRecord = record.copyWith(
        workshopRating: result['rating'] as int,
        workshopReview: result['review'] as String?,
      );
      context.read<MaintenanceBloc>().add(UpdateMaintenanceRecord(updatedRecord));
      _loadHistory();
    }
  }
}
