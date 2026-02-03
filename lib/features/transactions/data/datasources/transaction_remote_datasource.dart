import 'package:flutter_drift_advanced_project/core/errors/exceptions.dart';
import 'package:flutter_drift_advanced_project/core/network/api_client.dart';
import 'package:flutter_drift_advanced_project/core/utils/constants.dart';
import 'package:flutter_drift_advanced_project/features/transactions/data/models/transaction_model.dart';

abstract class TransactionRemoteDatasource {
  Future<List<TransactionModel>> getTransactions();
  Future<TransactionModel> createTransaction(TransactionModel transaction);
  Future<TransactionModel> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
  Future<void> syncTransactions(
    List<TransactionModel> transactions,
  ); // Batch Sync (Multiple Transactions at Once)
}

class TransactionRemoteDataSourceImpl implements TransactionRemoteDatasource {
  TransactionRemoteDataSourceImpl({required this.apiClient});
  final ApiClient apiClient;
  @override
  Future<List<TransactionModel>> getTransactions() async {
    try {
      final response = await apiClient.get(ApiEndpoints.transactions);
      final List<dynamic> data = response['data'] as List;
      return data.map((json) => TransactionModel.fromJson(json)).toList();
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<TransactionModel> createTransaction(
    TransactionModel transaction,
  ) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.transactions,
        body: transaction.toJson(),
      );
      return TransactionModel.fromJson(response['data']);
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<TransactionModel> updateTransaction(
    TransactionModel transaction,
  ) async {
    try {
      final response = await apiClient.put(
        '${ApiEndpoints.transactions}/${transaction.id}',
        body: transaction.toJson(),
      );
      return TransactionModel.fromJson(response['data']);
    } on SyncConflictException {
      rethrow; // Let conflict resolver handle this
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      await apiClient.delete('${ApiEndpoints.transactions}/$id');
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> syncTransactions(List<TransactionModel> transactions) async {
    try {
      final body = {
        'transactions': transactions.map((t) => t.toJson()).toList(),
      };

      await apiClient.post(ApiEndpoints.sync, body: body);
    } on SyncConflictException {
      rethrow;
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
