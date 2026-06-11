import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/haptics.dart';
import '../../data/repositories/checklist_repository.dart';
import '../../domain/models/daily_checklist.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/models/vehicle_type.dart';
import 'checklist_history_screen.dart';

class DailyChecklistScreen extends StatefulWidget {
  final Vehicle vehicle;
  final ChecklistRepository checklistRepository;

  const DailyChecklistScreen({
    super.key,
    required this.vehicle,
    required this.checklistRepository,
  });

  @override
  State<DailyChecklistScreen> createState() => _DailyChecklistScreenState();
}

class _DailyChecklistScreenState extends State<DailyChecklistScreen> {
  late List<ChecklistItem> _items;
  ChecklistStatus _overallStatus = ChecklistStatus.ok;
  final _notesController = TextEditingController();
  final Map<int, TextEditingController> _itemNotesControllers = {};
  bool _loading = true;
  bool _readOnly = false;
  DailyChecklist? _existingChecklist;

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final controller in _itemNotesControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadChecklist() async {
    final existing = await widget.checklistRepository
        .getChecklist(widget.vehicle.id, DateTime.now());

    if (existing != null) {
      setState(() {
        _existingChecklist = existing;
        _items = existing.items;
        _overallStatus = existing.overallStatus;
        _notesController.text = existing.notes ?? '';
        _readOnly = true;
        _loading = false;
      });
      // Initialize item notes controllers
      for (int i = 0; i < _items.length; i++) {
        _itemNotesControllers[i] =
            TextEditingController(text: _items[i].notes ?? '');
      }
    } else {
      final defaultItems =
          ChecklistRepository.getDefaultItems(widget.vehicle.type);
      setState(() {
        _items = defaultItems;
        _loading = false;
      });
      for (int i = 0; i < _items.length; i++) {
        _itemNotesControllers[i] = TextEditingController();
      }
    }
  }

  Future<void> _saveChecklist() async {
    AppHaptics.mediumImpact();
    final now = DateTime.now();
    final checklist = DailyChecklist(
      id: _existingChecklist?.id ?? const Uuid().v4(),
      vehicleId: widget.vehicle.id,
      driverId: null,
      date: now,
      items: _items,
      overallStatus: _overallStatus,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      createdAt: _existingChecklist?.createdAt ?? now,
    );

    await widget.checklistRepository.saveChecklist(checklist);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checklist berhasil disimpan')),
      );
      Navigator.pop(context, true);
    }
  }

  void _toggleEdit() {
    setState(() {
      _readOnly = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checklist Harian')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist Harian Kendaraan'),
        actions: [
          if (_readOnly)
            TextButton.icon(
              onPressed: _toggleEdit,
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Vehicle info
          Card(
            child: ListTile(
              leading: Icon(
                widget.vehicle.type == VehicleType.motorcycle
                    ? Icons.two_wheeler
                    : Icons.directions_car,
              ),
              title: Text(widget.vehicle.name),
              subtitle: Text(widget.vehicle.plateNumber),
            ),
          ),
          const SizedBox(height: 16),

          // Checklist items
          Text(
            'Item Pemeriksaan',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...List.generate(_items.length, (index) {
            final item = _items[index];
            return Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: item.checked,
                      onChanged: _readOnly
                          ? null
                          : (value) {
                              AppHaptics.selectionClick();
                              setState(() {
                                _items[index] =
                                    item.copyWith(checked: value ?? false);
                              });
                            },
                      title: Text(item.name),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, bottom: 8),
                      child: TextField(
                        controller: _itemNotesControllers[index],
                        readOnly: _readOnly,
                        decoration: const InputDecoration(
                          hintText: 'Catatan (opsional)',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          _items[index] = item.copyWith(
                            notes: value.isEmpty ? null : value,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Overall status
          Text(
            'Status Keseluruhan',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SegmentedButton<ChecklistStatus>(
            segments: const [
              ButtonSegment(
                value: ChecklistStatus.ok,
                label: Text('Semua Baik'),
                icon: Icon(Icons.check_circle_outline),
              ),
              ButtonSegment(
                value: ChecklistStatus.warning,
                label: Text('Ada Masalah'),
                icon: Icon(Icons.warning_amber),
              ),
              ButtonSegment(
                value: ChecklistStatus.critical,
                label: Text('Kritis'),
                icon: Icon(Icons.error_outline),
              ),
            ],
            selected: {_overallStatus},
            onSelectionChanged: _readOnly
                ? null
                : (values) {
                    setState(() {
                      _overallStatus = values.first;
                    });
                  },
          ),
          const SizedBox(height: 16),

          // General notes
          Text(
            'Catatan Umum',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            readOnly: _readOnly,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Catatan tambahan...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          // Save button
          if (!_readOnly)
            FilledButton.icon(
              onPressed: _saveChecklist,
              icon: const Icon(Icons.save),
              label: const Text('Simpan'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

          if (_readOnly)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChecklistHistoryScreen(
                      vehicle: widget.vehicle,
                      checklistRepository: widget.checklistRepository,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text('Lihat Riwayat'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
        ],
      ),
    );
  }
}
