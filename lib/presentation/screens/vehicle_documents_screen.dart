import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/vehicle_document_repository.dart';
import '../../data/services/notification_service.dart';
import '../../domain/models/models.dart';

class VehicleDocumentsScreen extends StatefulWidget {
  final Vehicle vehicle;
  final VehicleDocumentRepository documentRepository;

  const VehicleDocumentsScreen({
    super.key,
    required this.vehicle,
    required this.documentRepository,
  });

  @override
  State<VehicleDocumentsScreen> createState() => _VehicleDocumentsScreenState();
}

class _VehicleDocumentsScreenState extends State<VehicleDocumentsScreen> {
  VehicleDocument? _pajakDoc;
  VehicleDocument? _stnkDoc;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    final pajak = await widget.documentRepository
        .getDocument(widget.vehicle.id, DocumentType.pajak);
    final stnk = await widget.documentRepository
        .getDocument(widget.vehicle.id, DocumentType.stnk);
    setState(() {
      _pajakDoc = pajak;
      _stnkDoc = stnk;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pajak & STNK'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDocuments,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Vehicle info
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          widget.vehicle.type == VehicleType.motorcycle
                              ? Icons.two_wheeler
                              : Icons.directions_car,
                        ),
                      ),
                      title: Text(widget.vehicle.name),
                      subtitle: Text(widget.vehicle.plateNumber),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pajak section
                  _DocumentSection(
                    title: 'Pajak Kendaraan',
                    icon: Icons.receipt_long,
                    document: _pajakDoc,
                    documentType: DocumentType.pajak,
                    onSetDate: () => _showSetDateDialog(DocumentType.pajak),
                    onMarkPaid: () => _showPaymentDialog(DocumentType.pajak),
                  ),
                  const SizedBox(height: 16),

                  // STNK section
                  _DocumentSection(
                    title: 'STNK',
                    icon: Icons.card_membership,
                    document: _stnkDoc,
                    documentType: DocumentType.stnk,
                    onSetDate: () => _showSetDateDialog(DocumentType.stnk),
                    onMarkPaid: () => _showPaymentDialog(DocumentType.stnk),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _showSetDateDialog(DocumentType type) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      helpText: 'Tanggal berlaku sampai',
    );

    if (picked == null || !mounted) return;

    final existingDoc = type == DocumentType.pajak ? _pajakDoc : _stnkDoc;
    final doc = VehicleDocument(
      id: existingDoc?.id ?? const Uuid().v4(),
      vehicleId: widget.vehicle.id,
      documentType: type,
      expiryDate: picked,
      lastPaidDate: existingDoc?.lastPaidDate,
      cost: existingDoc?.cost,
      notes: existingDoc?.notes,
    );

    await widget.documentRepository.saveDocument(doc);
    await _scheduleDocumentNotifications(doc);
    await _loadDocuments();
  }

  Future<void> _showPaymentDialog(DocumentType type) async {
    final existingDoc = type == DocumentType.pajak ? _pajakDoc : _stnkDoc;
    final result = await showDialog<_PaymentResult>(
      context: context,
      builder: (ctx) => _PaymentDialog(
        documentType: type,
        existingDoc: existingDoc,
      ),
    );

    if (result == null || !mounted) return;

    final doc = VehicleDocument(
      id: existingDoc?.id ?? const Uuid().v4(),
      vehicleId: widget.vehicle.id,
      documentType: type,
      expiryDate: result.newExpiryDate,
      lastPaidDate: result.paidDate,
      cost: result.cost,
      notes: result.notes,
    );

    await widget.documentRepository.saveDocument(doc);
    await _scheduleDocumentNotifications(doc);
    await _loadDocuments();
  }

  Future<void> _scheduleDocumentNotifications(VehicleDocument doc) async {
    final notificationService = NotificationService();
    final vehicleName = widget.vehicle.name;
    final prefix = widget.vehicle.type == VehicleType.motorcycle
        ? 'Motor'
        : 'Mobil';

    // Base notification ID from document id
    final baseId = doc.id.hashCode.abs() % 100000;

    // Cancel existing notifications for this document
    await notificationService.cancelNotification(baseId);
    await notificationService.cancelNotification(baseId + 1);
    await notificationService.cancelNotification(baseId + 2);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(
        doc.expiryDate.year, doc.expiryDate.month, doc.expiryDate.day);

    // 30 days before
    final thirtyDaysBefore = expiry.subtract(const Duration(days: 30));
    if (thirtyDaysBefore.isAfter(today)) {
      final message = doc.documentType == DocumentType.pajak
          ? '$prefix $vehicleName pajak jatuh tempo dalam 30 hari'
          : '$prefix $vehicleName STNK habis dalam 30 hari';
      await _showScheduledNotification(baseId, message, thirtyDaysBefore);
    }

    // 7 days before
    final sevenDaysBefore = expiry.subtract(const Duration(days: 7));
    if (sevenDaysBefore.isAfter(today)) {
      final message = doc.documentType == DocumentType.pajak
          ? '$prefix $vehicleName pajak jatuh tempo dalam 7 hari'
          : '$prefix $vehicleName STNK habis dalam 7 hari';
      await _showScheduledNotification(baseId + 1, message, sevenDaysBefore);
    }

    // On expiry date
    if (expiry.isAfter(today) || expiry.isAtSameMomentAs(today)) {
      final message = doc.documentType == DocumentType.pajak
          ? '$prefix $vehicleName pajak sudah jatuh tempo!'
          : '$prefix $vehicleName STNK sudah habis!';
      await _showScheduledNotification(baseId + 2, message, expiry);
    }
  }

  Future<void> _showScheduledNotification(
      int id, String message, DateTime scheduledDate) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (scheduledDate.isAtSameMomentAs(today) ||
        scheduledDate.isBefore(today.add(const Duration(days: 1)))) {
      final notificationService = NotificationService();
      await notificationService.showDocumentReminder(
        notificationId: id,
        message: message,
      );
    }
  }
}

// =============================================================================
// Document Section Widget
// =============================================================================

class _DocumentSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final VehicleDocument? document;
  final DocumentType documentType;
  final VoidCallback onSetDate;
  final VoidCallback onMarkPaid;

  const _DocumentSection({
    required this.title,
    required this.icon,
    required this.document,
    required this.documentType,
    required this.onSetDate,
    required this.onMarkPaid,
  });

  Color _getStatusColor() {
    if (document == null) return Colors.grey;
    if (document!.isExpired) return Colors.red;
    if (document!.isExpiringSoon) return Colors.orange;
    return Colors.green;
  }

  String _getStatusText() {
    if (document == null) return 'Belum diatur';
    final days = document!.daysRemaining;
    if (days < 0) return 'Sudah lewat ${-days} hari';
    if (days == 0) return 'Jatuh tempo hari ini';
    return 'Sisa $days hari';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
    final statusColor = _getStatusColor();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (document != null) ...[
              Row(
                children: [
                  const Icon(Icons.event, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Jatuh tempo: ${dateFormat.format(document!.expiryDate)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              if (document!.lastPaidDate != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.payments, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Terakhir bayar: ${dateFormat.format(document!.lastPaidDate!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              if (document!.cost != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Biaya: Rp ${NumberFormat('#,###', 'id_ID').format(document!.cost!.round())}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              if (document!.notes != null &&
                  document!.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.notes, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        document!.notes!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onMarkPaid,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Tandai Sudah Bayar'),
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'Belum ada data. Atur tanggal jatuh tempo untuk mulai.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onSetDate,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Atur Tanggal'),
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
// Payment Dialog
// =============================================================================

class _PaymentResult {
  final DateTime paidDate;
  final DateTime newExpiryDate;
  final double? cost;
  final String? notes;

  _PaymentResult({
    required this.paidDate,
    required this.newExpiryDate,
    this.cost,
    this.notes,
  });
}

class _PaymentDialog extends StatefulWidget {
  final DocumentType documentType;
  final VehicleDocument? existingDoc;

  const _PaymentDialog({
    required this.documentType,
    this.existingDoc,
  });

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  late DateTime _paidDate;
  late DateTime _newExpiryDate;
  final _costController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _paidDate = DateTime.now();
    // Default new expiry: 1 year from today for pajak, 5 years for STNK
    final yearsToAdd =
        widget.documentType == DocumentType.pajak ? 1 : 5;
    _newExpiryDate = DateTime(
      DateTime.now().year + yearsToAdd,
      DateTime.now().month,
      DateTime.now().day,
    );
  }

  @override
  void dispose() {
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    final title = widget.documentType == DocumentType.pajak
        ? 'Bayar Pajak'
        : 'Perpanjang STNK';

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Tanggal bayar'),
              subtitle: Text(dateFormat.format(_paidDate)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _paidDate,
                  firstDate:
                      DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _paidDate = picked);
                }
              },
            ),

            // New expiry date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: const Text('Tanggal berlaku sampai'),
              subtitle: Text(dateFormat.format(_newExpiryDate)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _newExpiryDate,
                  firstDate: DateTime.now(),
                  lastDate:
                      DateTime.now().add(const Duration(days: 365 * 10)),
                );
                if (picked != null) {
                  setState(() => _newExpiryDate = picked);
                }
              },
            ),

            const SizedBox(height: 8),

            // Cost field
            TextField(
              controller: _costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Biaya (opsional)',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Notes field
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            final cost = double.tryParse(
              _costController.text.replaceAll(RegExp(r'[^\d.]'), ''),
            );
            final notes = _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim();

            Navigator.pop(
              context,
              _PaymentResult(
                paidDate: _paidDate,
                newExpiryDate: _newExpiryDate,
                cost: cost,
                notes: notes,
              ),
            );
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
