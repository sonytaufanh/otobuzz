import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/expense_repository.dart';
import '../../domain/models/expense_record.dart';
import '../../domain/models/vehicle.dart';
import '../blocs/expense/expense_bloc.dart';
import '../blocs/expense/expense_event.dart';
import '../blocs/expense/expense_state.dart';
import 'expense_form_screen.dart';

class ExpenseScreen extends StatefulWidget {
  final Vehicle vehicle;
  final ExpenseRepository expenseRepository;

  const ExpenseScreen({
    super.key,
    required this.vehicle,
    required this.expenseRepository,
  });

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  ExpenseCategory? _selectedCategory;
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExpenseBloc(widget.expenseRepository)
        ..add(LoadExpenses(widget.vehicle.id)),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Pengeluaran Lain'),
          ),
          body: Column(
            children: [
              _buildCategoryFilter(context),
              _buildTotalSummary(context),
              Expanded(child: _buildExpenseList(context)),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _navigateToAddExpense(context),
            icon: const Icon(Icons.add),
            label: const Text('Tambah'),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Semua'),
            selected: _selectedCategory == null,
            onSelected: (_) {
              setState(() => _selectedCategory = null);
              context
                  .read<ExpenseBloc>()
                  .add(LoadExpenses(widget.vehicle.id));
            },
          ),
          const SizedBox(width: 8),
          ...ExpenseCategory.values.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(category.displayName),
                selected: _selectedCategory == category,
                onSelected: (_) {
                  setState(() => _selectedCategory = category);
                  context.read<ExpenseBloc>().add(
                        LoadExpenses(widget.vehicle.id, category: category),
                      );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTotalSummary(BuildContext context) {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, state) {
        if (state is! ExpenseLoaded) return const SizedBox();

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Pengeluaran',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                _currencyFormat.format(state.totalAmount),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpenseList(BuildContext context) {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, state) {
        if (state is ExpenseLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ExpenseError) {
          return Center(child: Text(state.message));
        }
        if (state is ExpenseLoaded) {
          if (state.records.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada pengeluaran',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.records.length,
            itemBuilder: (context, index) {
              return _buildExpenseItem(context, state.records[index]);
            },
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildExpenseItem(BuildContext context, ExpenseRecord record) {
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(record.category).withValues(alpha: 0.2),
          child: Icon(
            _getCategoryIcon(record.category),
            color: _getCategoryColor(record.category),
          ),
        ),
        title: Text(record.category.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (record.description != null && record.description!.isNotEmpty)
              Text(record.description!),
            Text(
              dateFormat.format(record.date),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Text(
          _currencyFormat.format(record.amount),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        onLongPress: () => _confirmDelete(context, record),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ExpenseRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengeluaran'),
        content: Text(
            'Hapus ${record.category.displayName} - ${_currencyFormat.format(record.amount)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ExpenseBloc>().add(
                    DeleteExpense(id: record.id, vehicleId: widget.vehicle.id),
                  );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToAddExpense(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseFormScreen(
          vehicle: widget.vehicle,
          expenseRepository: widget.expenseRepository,
        ),
      ),
    );
    if (result == true && context.mounted) {
      context.read<ExpenseBloc>().add(
            LoadExpenses(widget.vehicle.id, category: _selectedCategory),
          );
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
