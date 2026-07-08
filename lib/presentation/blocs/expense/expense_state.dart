import 'package:equatable/equatable.dart';
import '../../../domain/models/expense_record.dart';

abstract class ExpenseState extends Equatable {
  const ExpenseState();

  @override
  List<Object?> get props => [];
}

class ExpenseInitial extends ExpenseState {}

class ExpenseLoading extends ExpenseState {}

class ExpenseLoaded extends ExpenseState {
  final List<ExpenseRecord> records;
  final double totalAmount;
  final Map<ExpenseCategory, double> totalByCategory;

  const ExpenseLoaded({
    required this.records,
    required this.totalAmount,
    required this.totalByCategory,
  });

  @override
  List<Object?> get props => [records, totalAmount, totalByCategory];
}

class ExpenseError extends ExpenseState {
  final String message;

  const ExpenseError(this.message);

  @override
  List<Object?> get props => [message];
}
