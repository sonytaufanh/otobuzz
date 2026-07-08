import 'package:equatable/equatable.dart';
import '../../../domain/models/expense_record.dart';

abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();

  @override
  List<Object?> get props => [];
}

class LoadExpenses extends ExpenseEvent {
  final String vehicleId;
  final ExpenseCategory? category;
  final DateTime? from;
  final DateTime? to;

  const LoadExpenses(this.vehicleId, {this.category, this.from, this.to});

  @override
  List<Object?> get props => [vehicleId, category, from, to];
}

class AddExpense extends ExpenseEvent {
  final ExpenseRecord record;

  const AddExpense(this.record);

  @override
  List<Object?> get props => [record];
}

class DeleteExpense extends ExpenseEvent {
  final String id;
  final String vehicleId;

  const DeleteExpense({required this.id, required this.vehicleId});

  @override
  List<Object?> get props => [id, vehicleId];
}
