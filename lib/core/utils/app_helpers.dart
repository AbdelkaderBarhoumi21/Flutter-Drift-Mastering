import 'package:flutter/material.dart';
import 'package:flutter_drift_advanced_project/features/transactions/presentation/bloc/transaction/transaction_state.dart';

class AppHelpers {
  const AppHelpers._();

  static void showConflictDialog(
    BuildContext context,
    SyncConflictState state,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sync Conflict'),
        content: const Text(
          'The transaction was modified on another device. '
          'Which version would you like to keep?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Resolve conflict (keep local)
              Navigator.pop(dialogContext);
            },
            child: const Text('Keep Mine'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Resolve conflict (accept remote)
              Navigator.pop(dialogContext);
            },
            child: const Text('Use Server Version'),
          ),
        ],
      ),
    );
  }
}
