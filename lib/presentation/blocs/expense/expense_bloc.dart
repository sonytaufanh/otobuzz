import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../domain/models/expense_record.dart';
import 'expense_event.dart';
import 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final ExpenseRepository _expenseRepository;

  ExpenseBloc(this._expenseRepository) : super(ExpenseInitial()) {
    on<LoadExpenses>(_onLoadExpenses);
    on<AddExpense>(_onAddExpense);
    on<DeleteExpense>(_onDeleteExpense);
  }

  Future<void> _onLoadExpenses(
    LoadExpenses event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading());
    try {
      final records = await _expenseRepository.getExpenses(
        event.vehicleId,
        from: event.from,
        to: event.to,
        category: event.category,
      );

      final totalAmount = records.fold<double>(
        0,
        (sum, record) => sum + record.amount,
      );

      // Calculate totals by category
      final totalByCategory = <ExpenseCategory, double>{};
      for (final record in records) {
        totalByCategory[record.category] =
            (totalByCategory[record.category] ?? 0) + record.amount;
      }

      emit(ExpenseLoaded(
        records: records,
        totalAmount: totalAmount,
        totalByCategory: totalByCategory,
      ));
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  Future<void> _onAddExpense(
    AddExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      await _expenseRepository.addExpense(event.record);
      add(LoadExpenses(event.record.vehicleId));
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  Future<void> _onDeleteExpense(
    DeleteExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      await _expenseRepository.deleteExpense(event.id);
      add(LoadExpenses(event.vehicleId));
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }
}
