import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/models.dart';

class TripChecklistScreen extends StatefulWidget {
  final Vehicle vehicle;

  const TripChecklistScreen({super.key, required this.vehicle});

  @override
  State<TripChecklistScreen> createState() => _TripChecklistScreenState();
}

class _TripChecklistScreenState extends State<TripChecklistScreen> {
  late TripChecklist _checklist;
  final _destinationController = TextEditingController();
  final _kmController = TextEditingController();
  DateTime _tripDate = DateTime.now();
  bool _isSetup = false;

  @override
  void dispose() {
    _destinationController.dispose();
    _kmController.dispose();
    super.dispose();
  }

  void _startChecklist() {
    if (_destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan tujuan perjalanan')),
      );
      return;
    }
    final isMotorcycle = widget.vehicle.type == VehicleType.motorcycle;
    final items = getDefaultTripCheckItems(isMotorcycle: isMotorcycle);
    setState(() {
      _checklist = TripChecklist(
        id: const Uuid().v4(),
        vehicleId: widget.vehicle.id,
        destination: _destinationController.text.trim(),
        estimatedKm: int.tryParse(_kmController.text) ?? 0,
        tripDate: _tripDate,
        items: items,
        createdAt: DateTime.now(),
      );
      _isSetup = true;
    });
  }

  void _toggleItem(String itemId) {
    setState(() {
      _checklist = _checklist.copyWith(
        items: _checklist.items.map((item) {
          if (item.id == itemId) return item.copyWith(isChecked: !item.isChecked);
          return item;
        }).toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cek Kendaraan Sebelum Jalan'),
      ),
      body: _isSetup ? _buildChecklist() : _buildSetup(),
    );
  }

  Widget _buildSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero card
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.directions_car, size: 56),
                  const SizedBox(height: 12),
                  Text(
                    'Perjalanan Jauh / Mudik',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sebelum berangkat, pastikan kendaraan kamu sudah siap untuk perjalanan jauh',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _destinationController,
            decoration: const InputDecoration(
              labelText: 'Tujuan Perjalanan',
              hintText: 'Surabaya, Bali, Yogyakarta...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.place),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _kmController,
            decoration: const InputDecoration(
              labelText: 'Estimasi Jarak (opsional)',
              hintText: '300',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.route),
              suffixText: 'km',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Tanggal Berangkat'),
            subtitle: Text(DateFormat('dd MMMM yyyy', 'id_ID').format(_tripDate)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _tripDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) setState(() => _tripDate = date);
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(height: 32),

          FilledButton.icon(
            onPressed: _startChecklist,
            icon: const Icon(Icons.checklist),
            label: const Text('Mulai Pemeriksaan'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklist() {
    final categories = TripCheckItemCategory.values;
    final progress = _checklist.checkedCount / _checklist.items.length;
    final criticalLeft = _checklist.criticalUnchecked;

    return Column(
      children: [
        // Progress header
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🗺️ ${_checklist.destination}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '${_checklist.checkedCount}/${_checklist.items.length} item selesai',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: _checklist.isComplete
                        ? Colors.green
                        : criticalLeft > 0
                            ? Colors.red
                            : Colors.orange,
                    child: Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                color: _checklist.isComplete
                    ? Colors.green
                    : criticalLeft > 0
                        ? Colors.orange
                        : Theme.of(context).colorScheme.primary,
              ),
              if (criticalLeft > 0) ...[
                const SizedBox(height: 6),
                Text(
                  '⚠️ $criticalLeft item kritis belum dicek',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
        ),

        // Checklist items
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final catItems = _checklist.items
                  .where((i) => i.category == cat)
                  .toList();
              if (catItems.isEmpty) return const SizedBox.shrink();
              return _buildCategorySection(cat, catItems);
            },
          ),
        ),

        // Bottom action
        if (_checklist.isComplete)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Kendaraan Siap!',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.green)),
                      const Text('Semua item sudah dicek. Selamat jalan! 🎉',
                          style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Berangkat!'),
                ),
              ],
            ),
          )
        else if (criticalLeft == 0 && _checklist.checkedCount > 0)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade50,
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Item kritis sudah ✅. Masih ada ${_checklist.items.length - _checklist.checkedCount} item opsional.',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCategorySection(
      TripCheckItemCategory cat, List<TripCheckItem> items) {
    final allChecked = items.every((i) => i.isChecked);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        initiallyExpanded: !allChecked,
        leading: Text(cat.emoji, style: const TextStyle(fontSize: 24)),
        title: Text(cat.displayName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${items.where((i) => i.isChecked).length}/${items.length}',
              style: TextStyle(
                fontSize: 12,
                color: allChecked ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(width: 4),
            if (allChecked)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
        children: items
            .map((item) => CheckboxListTile(
                  value: item.isChecked,
                  onChanged: (_) => _toggleItem(item.id),
                  title: Row(
                    children: [
                      Expanded(child: Text(item.label)),
                      if (item.isCritical)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'WAJIB',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    item.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: Colors.green,
                ))
            .toList(),
      ),
    );
  }
}
