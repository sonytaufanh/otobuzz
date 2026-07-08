import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/custom_interval_repository.dart';
import '../../domain/models/models.dart';

class CustomIntervalScreen extends StatefulWidget {
  final Vehicle vehicle;
  final CustomIntervalRepository customIntervalRepository;

  const CustomIntervalScreen({
    super.key,
    required this.vehicle,
    required this.customIntervalRepository,
  });

  @override
  State<CustomIntervalScreen> createState() => _CustomIntervalScreenState();
}

class _CustomIntervalScreenState extends State<CustomIntervalScreen> {
  List<CustomInterval> _customIntervals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomIntervals();
  }

  Future<void> _loadCustomIntervals() async {
    setState(() => _isLoading = true);
    final intervals = await widget.customIntervalRepository
        .getCustomIntervals(widget.vehicle.id);
    setState(() {
      _customIntervals = intervals;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final applicableTypes =
        getApplicableTypes(widget.vehicle.type,
            transmissionType: widget.vehicle.transmissionType);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interval Perawatan'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: applicableTypes.length,
              itemBuilder: (context, index) {
                final type = applicableTypes[index];
                final customInterval = _customIntervals
                    .where((ci) => ci.type == type)
                    .firstOrNull;
                final defaultInterval = getDefaultInterval(type,
                    widget.vehicle.type,
                    transmissionType: widget.vehicle.transmissionType);
                final isCustom = customInterval != null;

                final kmInterval = isCustom
                    ? customInterval.kmInterval
                    : defaultInterval.kmInterval;
                final monthsInterval = isCustom
                    ? customInterval.monthsInterval
                    : defaultInterval.monthsInterval;

                return Card(
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Expanded(child: Text(type.displayName)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCustom
                                ? Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isCustom ? 'Custom' : 'Default',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: isCustom
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '${kmInterval.round()} km / $monthsInterval bulan',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            type.description,
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
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () =>
                              _openEditDialog(type, customInterval),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Ubah Interval'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _openEditDialog(
      MaintenanceType type, CustomInterval? existing) async {
    final defaultInterval = getDefaultInterval(type, widget.vehicle.type,
        transmissionType: widget.vehicle.transmissionType);

    final kmController = TextEditingController(
      text: (existing?.kmInterval ?? defaultInterval.kmInterval)
          .round()
          .toString(),
    );
    final monthsController = TextEditingController(
      text: (existing?.monthsInterval ?? defaultInterval.monthsInterval)
          .toString(),
    );
    final warningKmController = TextEditingController(
      text: (existing?.warningBeforeKm ?? defaultInterval.warningBeforeKm)
          .round()
          .toString(),
    );
    final warningDaysController = TextEditingController(
      text: (existing?.warningBeforeDays ?? defaultInterval.warningBeforeDays)
          .toString(),
    );

    final isCustom = existing != null;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(type.displayName),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 20,
                          color: Theme.of(context)
                              .colorScheme
                              .primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          type.description,
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
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: kmController,
                  decoration: const InputDecoration(
                    labelText: 'Interval KM',
                    suffixText: 'km',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: monthsController,
                  decoration: const InputDecoration(
                    labelText: 'Interval Bulan',
                    suffixText: 'bulan',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: warningKmController,
                  decoration: const InputDecoration(
                    labelText: 'Peringatan sebelum (km)',
                    suffixText: 'km',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: warningDaysController,
                  decoration: const InputDecoration(
                    labelText: 'Peringatan sebelum (hari)',
                    suffixText: 'hari',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            if (isCustom)
              TextButton(
                onPressed: () async {
                  await widget.customIntervalRepository
                      .deleteCustomInterval(widget.vehicle.id, type);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  await _loadCustomIntervals();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reset ke Default')),
                    );
                  }
                },
                child: const Text('Reset ke Default'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                final km = double.tryParse(kmController.text);
                final months = int.tryParse(monthsController.text);
                final warningKm = double.tryParse(warningKmController.text);
                final warningDays = int.tryParse(warningDaysController.text);

                if (km == null ||
                    months == null ||
                    warningKm == null ||
                    warningDays == null ||
                    km <= 0 ||
                    months <= 0 ||
                    warningKm < 0 ||
                    warningDays < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Mohon isi semua field dengan benar')),
                  );
                  return;
                }

                final interval = CustomInterval(
                  id: existing?.id ?? const Uuid().v4(),
                  vehicleId: widget.vehicle.id,
                  type: type,
                  kmInterval: km,
                  monthsInterval: months,
                  warningBeforeKm: warningKm,
                  warningBeforeDays: warningDays,
                );

                await widget.customIntervalRepository
                    .saveCustomInterval(interval);

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                await _loadCustomIntervals();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Interval berhasil disimpan')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    kmController.dispose();
    monthsController.dispose();
    warningKmController.dispose();
    warningDaysController.dispose();
  }
}
