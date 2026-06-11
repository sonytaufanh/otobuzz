import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/checklist_repository.dart';
import '../../domain/models/daily_checklist.dart';
import '../../domain/models/vehicle.dart';

class ChecklistHistoryScreen extends StatefulWidget {
  final Vehicle vehicle;
  final ChecklistRepository checklistRepository;

  const ChecklistHistoryScreen({
    super.key,
    required this.vehicle,
    required this.checklistRepository,
  });

  @override
  State<ChecklistHistoryScreen> createState() => _ChecklistHistoryScreenState();
}

class _ChecklistHistoryScreenState extends State<ChecklistHistoryScreen> {
  List<DailyChecklist> _checklists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month - 3, now.day);
    final history = await widget.checklistRepository.getChecklistHistory(
      widget.vehicle.id,
      from: from,
      to: now,
    );
    setState(() {
      _checklists = history;
      _loading = false;
    });
  }

  Color _statusColor(ChecklistStatus status) {
    switch (status) {
      case ChecklistStatus.ok:
        return Colors.green;
      case ChecklistStatus.warning:
        return Colors.orange;
      case ChecklistStatus.critical:
        return Colors.red;
    }
  }

  IconData _statusIcon(ChecklistStatus status) {
    switch (status) {
      case ChecklistStatus.ok:
        return Icons.check_circle;
      case ChecklistStatus.warning:
        return Icons.warning;
      case ChecklistStatus.critical:
        return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Checklist'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _checklists.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.checklist, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Belum ada riwayat checklist'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _checklists.length,
                  itemBuilder: (context, index) {
                    final checklist = _checklists[index];
                    final dateStr =
                        DateFormat('EEEE, d MMMM yyyy', 'id').format(checklist.date);
                    final statusColor = _statusColor(checklist.overallStatus);
                    final checkedCount =
                        checklist.items.where((i) => i.checked).length;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withValues(alpha: 0.2),
                          child: Icon(
                            _statusIcon(checklist.overallStatus),
                            color: statusColor,
                          ),
                        ),
                        title: Text(dateStr),
                        subtitle: Text(
                          '${checklist.overallStatus.displayName} • $checkedCount/${checklist.items.length} item OK',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showDetail(checklist),
                      ),
                    );
                  },
                ),
    );
  }

  void _showDetail(DailyChecklist checklist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  DateFormat('EEEE, d MMMM yyyy', 'id').format(checklist.date),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(checklist.overallStatus.displayName),
                  backgroundColor:
                      _statusColor(checklist.overallStatus).withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: _statusColor(checklist.overallStatus),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...checklist.items.map((item) => ListTile(
                      leading: Icon(
                        item.checked ? Icons.check_box : Icons.check_box_outline_blank,
                        color: item.checked ? Colors.green : Colors.grey,
                      ),
                      title: Text(item.name),
                      subtitle: item.notes != null && item.notes!.isNotEmpty
                          ? Text(item.notes!)
                          : null,
                      dense: true,
                    )),
                if (checklist.notes != null && checklist.notes!.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Catatan:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(checklist.notes!),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
