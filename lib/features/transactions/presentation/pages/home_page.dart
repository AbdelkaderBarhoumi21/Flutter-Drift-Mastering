import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_drift_advanced_project/core/utils/app_helpers.dart';
import 'package:flutter_drift_advanced_project/features/transactions/presentation/bloc/transaction/transaction_bloc.dart';
import 'package:flutter_drift_advanced_project/features/transactions/presentation/bloc/transaction/transaction_event.dart';
import 'package:flutter_drift_advanced_project/features/transactions/presentation/bloc/transaction/transaction_state.dart';
import 'package:flutter_drift_advanced_project/features/transactions/presentation/widgets/home_page_empty_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Expense Tracker'),
      actions: const [
        // CustomSyncIndicator(),
      ],
    ),
    body: BlocConsumer<TransactionBloc, TransactionState>(
      listener: (context, state) {
        if (state is TransactionOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is TransactionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        } else if (state is SyncConflictState) {
          AppHelpers.showConflictDialog(context, state);
        }
      },
      builder: (context, state) {
        if (state is TransactionLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is TransactionLoaded) {
          if (state.transactions.isEmpty) {
            return const HomePageEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<TransactionBloc>().add(SyncRequestedEvent());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.transactions.length,
              itemBuilder: (context, index) {
                final transaction = state.transactions[index];
                return Center(child: CircularProgressIndicator());
              },
            ),
          );
        }
        return Center(child: CircularProgressIndicator());
      },
    ),
  );
}
