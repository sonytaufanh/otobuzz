import 'package:flutter/material.dart';
import '../../data/repositories/fuel_repository.dart';
import '../../data/services/ai_service.dart';
import '../../domain/repositories/maintenance_history_repository.dart';
import '../../domain/repositories/maintenance_schedule_repository.dart';
import '../../domain/repositories/mileage_repository.dart';
import '../../domain/repositories/vehicle_repository.dart';

class AiChatScreen extends StatefulWidget {
  final AiService aiService;
  final VehicleRepository vehicleRepository;
  final MileageRepository mileageRepository;
  final MaintenanceHistoryRepository maintenanceRepository;
  final MaintenanceScheduleRepository scheduleRepository;
  final FuelRepository fuelRepository;

  const AiChatScreen({
    super.key,
    required this.aiService,
    required this.vehicleRepository,
    required this.mileageRepository,
    required this.maintenanceRepository,
    required this.scheduleRepository,
    required this.fuelRepository,
  });

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  static const List<String> _quickQuestions = [
    'Bagaimana kondisi armada saya?',
    'Kendaraan mana yang paling bermasalah?',
    'Prediksi biaya perawatan bulan depan',
    'Saran penghematan biaya',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _buildFleetContext() async {
    final vehicles = await widget.vehicleRepository.getAllVehicles();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    int overdueCount = 0;
    int upcomingCount = 0;
    final vehicleSummaries = <Map<String, dynamic>>[];

    for (final vehicle in vehicles) {
      final schedules =
          await widget.scheduleRepository.getSchedules(vehicle.id);
      final overdue = schedules.where((s) => s.isOverdue).length;
      final upcoming =
          schedules.where((s) => !s.isOverdue && s.remainingDays <= 30).length;
      overdueCount += overdue;
      upcomingCount += upcoming;

      String status = 'Baik';
      if (overdue > 0) {
        status = '$overdue terlambat';
      } else if (upcoming > 0) {
        status = '$upcoming segera';
      }

      vehicleSummaries.add({
        'name': vehicle.name,
        'plate': vehicle.plateNumber,
        'km': vehicle.totalMileageKm.round(),
        'status': status,
      });
    }

    // Monthly maintenance cost
    final maintenanceRecords =
        await widget.maintenanceRepository.getRecordsByDateRange(
      monthStart,
      now,
    );
    final monthlySpent =
        maintenanceRecords.fold<double>(0, (s, r) => s + (r.cost ?? 0));

    return {
      'totalVehicles': vehicles.length,
      'vehicles': vehicleSummaries,
      'overdueCount': overdueCount,
      'upcomingCount': upcomingCount,
      'monthlySpent': monthlySpent.round(),
    };
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      final context = await _buildFleetContext();
      final response = await widget.aiService.askAboutFleet(
        question: text,
        fleetContext: context,
      );

      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(text: response, isUser: false));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } on AiServiceException catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            text: e.message,
            isUser: false,
            isError: true,
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.aiService.isConfigured) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Assistant')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.smart_toy_outlined,
                    size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'AI Assistant Belum Aktif',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fitur AI memerlukan kunci API Google Gemini. Aktifkan di Pengaturan > Kecerdasan Buatan.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.settings),
                  label: const Text('Ke Pengaturan'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return _buildLoadingBubble();
                      }
                      return _ChatBubble(message: _messages[index]);
                    },
                  ),
          ),

          // Input area
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Tanyakan tentang armada Anda...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                      enabled: !_isLoading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isLoading
                        ? null
                        : () => _sendMessage(_textController.text),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.smart_toy_outlined,
              size: 60, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Halo! Saya AI Assistant Anda',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Tanyakan apa saja tentang kondisi armada Anda',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 32),
          Text(
            'Pertanyaan cepat:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          ..._quickQuestions.map(
            (q) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _sendMessage(q),
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: Text(q, textAlign: TextAlign.left),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 8, right: 60),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Sedang menganalisis...'),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Chat Message Model
// =============================================================================

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  });
}

// =============================================================================
// Chat Bubble Widget
// =============================================================================

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 8,
          left: message.isUser ? 60 : 0,
          right: message.isUser ? 0 : 60,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : message.isError
                  ? Colors.red.shade50
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SelectableText(
          message.text,
          style: TextStyle(
            color: message.isError ? Colors.red.shade800 : null,
          ),
        ),
      ),
    );
  }
}
