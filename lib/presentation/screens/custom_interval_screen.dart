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
    final applicableTypes = getApplicableTypes(widget.vehicle.type);

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
                final defaultInterval =
                    getDefaultInterval(type, widget.vehicle.type);
                final isCustom = customInterval != null;

                final kmInterval = isCustom
                    ? customInterval.kmInterval
                    : defaultInterval.kmInterval;
                final monthsInterval = isCustom
                    ? customInterval.monthsInterval
                    : defaultInterval.monthsInterval;

                return Card(
                  child: ListTile(
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
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openEditDialog(type, customInterval),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _openEditDialog(
      MaintenanceType type, CustomInterval? existing) async {
    final defaultInterval = getDefaultInterval(type, widget.vehicle.type);

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
              children: [
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
