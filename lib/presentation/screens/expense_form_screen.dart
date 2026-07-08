import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/expense_repository.dart';
import '../../domain/models/expense_record.dart';
import '../../domain/models/vehicle.dart';

class ExpenseFormScreen extends StatefulWidget {
  final Vehicle vehicle;
  final ExpenseRepository expenseRepository;

  const ExpenseFormScreen({
    super.key,
    required this.vehicle,
    required this.expenseRepository,
  });

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  ExpenseCategory? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Pengeluaran'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Vehicle info
            Card(
              child: ListTile(
                leading: const Icon(Icons.directions_car),
                title: Text(widget.vehicle.name),
                subtitle: Text(widget.vehicle.plateNumber),
              ),
            ),
            const SizedBox(height: 24),

            // Category selector
            Text(
              'Kategori',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildCategoryGrid(),
            if (_selectedCategory == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Pilih kategori pengeluaran',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 24),

            // Amount field
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Nominal',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
                hintText: '0',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Masukkan nominal';
                }
                final amount = int.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Masukkan nominal yang valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date picker
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (opsional)',
                border: OutlineInputBorder(),
                hintText: 'Contoh: Tol Cipularang',
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
            const SizedBox(height: 24),

            // Submit button
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Simpan Pengeluaran'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ExpenseCategory.values.map((category) {
        final isSelected = _selectedCategory == category;
        return ChoiceChip(
          label: Text(category.displayName),
          avatar: Icon(
            _getCategoryIcon(category),
            size: 18,
            color: isSelected ? null : _getCategoryColor(category),
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedCategory = selected ? category : null;
            });
          },
        );
      }).toList(),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _submit() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final record = ExpenseRecord(
        id: const Uuid().v4(),
        vehicleId: widget.vehicle.id,
        category: _selectedCategory!,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        notes: _notesController.text.isNotEmpty
            ? _notesController.text
            : null,
      );

      await widget.expenseRepository.addExpense(record);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengeluaran berhasil disimpan')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.toll:
        return Icons.toll;
      case ExpenseCategory.parking:
        return Icons.local_parking;
      case ExpenseCategory.washing:
        return Icons.local_car_wash;
      case ExpenseCategory.insurance:
        return Icons.security;
      case ExpenseCategory.tax:
        return Icons.receipt_long;
      case ExpenseCategory.fine:
        return Icons.gavel;
      case ExpenseCategory.accessory:
        return Icons.build;
      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.toll:
        return Colors.blue;
      case ExpenseCategory.parking:
        return Colors.purple;
      case ExpenseCategory.washing:
        return Colors.cyan;
      case ExpenseCategory.insurance:
        return Colors.teal;
      case ExpenseCategory.tax:
        return Colors.orange;
      case ExpenseCategory.fine:
        return Colors.red;
      case ExpenseCategory.accessory:
        return Colors.indigo;
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }
}
