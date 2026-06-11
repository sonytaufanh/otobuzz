import 'package:flutter/material.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/checklist_repository.dart';
import '../../data/repositories/fuel_repository.dart';
import '../../data/repositories/vehicle_document_repository.dart';
import '../../data/services/ai_service.dart';
import '../../domain/models/smart_tip.dart';
import '../../domain/repositories/maintenance_history_repository.dart';
import '../../domain/repositories/maintenance_schedule_repository.dart';
import '../../domain/repositories/mileage_repository.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../../domain/usecases/smart_tips_engine.dart';
import 'ai_chat_screen.dart';

class SmartTipsScreen extends StatefulWidget {
  final VehicleRepository vehicleRepository;
  final MileageRepository mileageRepository;
  final MaintenanceHistoryRepository maintenanceRepository;
  final MaintenanceScheduleRepository scheduleRepository;
  final FuelRepository fuelRepository;
  final ChecklistRepository checklistRepository;
  final BudgetRepository budgetRepository;
  final VehicleDocumentRepository documentRepository;
  final AiService? aiService;

  const SmartTipsScreen({
    super.key,
    required this.vehicleRepository,
    required this.mileageRepository,
    required this.maintenanceRepository,
    required this.scheduleRepository,
    required this.fuelRepository,
    required this.checklistRepository,
    required this.budgetRepository,
    required this.documentRepository,
    this.aiService,
  });

  @override
  State<SmartTipsScreen> createState() => _SmartTipsScreenState();
}

class _SmartTipsScreenState extends State<SmartTipsScreen> {
  List<SmartTip> _tips = [];
  bool _isLoading = true;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _loadTips();
  }

  Future<void> _loadTips() async {
    setState(() => _isLoading = true);

    final engine = SmartTipsEngine(
      vehicleRepository: widget.vehicleRepository,
      mileageRepository: widget.mileageRepository,
      maintenanceRepository: widget.maintenanceRepository,
      scheduleRepository: widget.scheduleRepository,
      fuelRepository: widget.fuelRepository,
      checklistRepository: widget.checklistRepository,
      budgetRepository: widget.budgetRepository,
      documentRepository: widget.documentRepository,
    );

    try {
      final tips = await engine.generateTips();
      if (mounted) {
        setState(() {
          _tips = tips;
          _isLoading = false;
          _lastUpdated = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final highTips =
        _tips.where((t) => t.priority == SmartTipPriority.high).toList();
    final mediumTips =
        _tips.where((t) => t.priority == SmartTipPriority.medium).toList();
    final lowTips =
        _tips.where((t) => t.priority == SmartTipPriority.low).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tips Cerdas'),
        actions: [
          if (widget.aiService != null && widget.aiService!.isConfigured)
            IconButton(
              icon: const Icon(Icons.smart_toy_outlined),
              tooltip: 'AI Assistant',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AiChatScreen(
                      aiService: widget.aiService!,
                      vehicleRepository: widget.vehicleRepository,
                      mileageRepository: widget.mileageRepository,
                      maintenanceRepository: widget.maintenanceRepository,
                      scheduleRepository: widget.scheduleRepository,
                      fuelRepository: widget.fuelRepository,
                    ),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadTips,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Sedang menganalisis...'),
                ],
              ),
            )
          : _tips.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada tips',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tambahkan data kendaraan untuk mendapatkan rekomendasi',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTips,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Header
                      Text(
                        'Rekomendasi berdasarkan data armada Anda',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                      if (_lastUpdated != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Terakhir diperbarui: ${_formatTime(_lastUpdated!)}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                    ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // High priority tips (cards)
                      if (highTips.isNotEmpty) ...[
                        _SectionLabel(
                          label: 'Penting',
                          color: Colors.red,
                          count: highTips.length,
                        ),
                        const SizedBox(height: 8),
                        ...highTips.map((tip) => _HighPriorityTipCard(tip: tip)),
                        const SizedBox(height: 16),
                      ],

                      // Medium priority tips (list items)
                      if (mediumTips.isNotEmpty) ...[
                        _SectionLabel(
                          label: 'Perhatikan',
                          color: Colors.orange,
                          count: mediumTips.length,
                        ),
                        const SizedBox(height: 8),
                        ...mediumTips
                            .map((tip) => _MediumPriorityTipItem(tip: tip)),
                        const SizedBox(height: 16),
                      ],

                      // Low priority tips (expandable)
                      if (lowTips.isNotEmpty) ...[
                        _LowPrioritySection(tips: lowTips),
                      ],
                    ],
                  ),
                ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

// =============================================================================
// Section Label
// =============================================================================

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  final int count;

  const _SectionLabel({
    required this.label,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$label ($count)',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// High Priority Tip Card
// =============================================================================

class _HighPriorityTipCard extends StatelessWidget {
  final SmartTip tip;

  const _HighPriorityTipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  tip.category.icon,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tip.category.displayName,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tip.description,
              style: TextStyle(color: Colors.red.shade900),
            ),
            if (tip.actionText != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: () {
                    // TODO: Navigate to relevant screen based on tip type
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red.shade800,
                  ),
                  child: Text(tip.actionText!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Medium Priority Tip Item
// =============================================================================

class _MediumPriorityTipItem extends StatelessWidget {
  final SmartTip tip;

  const _MediumPriorityTipItem({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(
          tip.category.icon,
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(
          tip.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(tip.description),
        ),
        isThreeLine: true,
        trailing: tip.actionText != null
            ? Icon(Icons.chevron_right,
                color: Theme.of(context).colorScheme.outline)
            : null,
        onTap: tip.actionText != null
            ? () {
                // TODO: Navigate to relevant screen
              }
            : null,
      ),
    );
  }
}

// =============================================================================
// Low Priority Section (Expandable)
// =============================================================================

class _LowPrioritySection extends StatelessWidget {
  final List<SmartTip> tips;

  const _LowPrioritySection({required this.tips});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Info (${tips.length})',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Tips Lainnya',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
      children: tips.map((tip) {
        return ListTile(
          leading: Text(tip.category.icon),
          title: Text(tip.title, style: const TextStyle(fontSize: 14)),
          subtitle: Text(
            tip.description,
            style: const TextStyle(fontSize: 12),
          ),
          isThreeLine: true,
          dense: true,
        );
      }).toList(),
    );
  }
}
