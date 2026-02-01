import 'dart:convert';
import 'dart:io';

import 'package:flutter_drift_advanced_project/core/errors/exceptions.dart';
import 'package:flutter_drift_advanced_project/core/utils/constants.dart';
import 'package:http/http.dart' as http;

// If the server does not respond within 30 seconds => timeout
// the request stops and throws an exception
// We can handle the error and display a message to the user

// ✅ .replace automatically encodes special characters
// .replace transforms 'achat & café' into 'achat%20%26%20caf%C3%A9'
class ApiClient {
  const ApiClient({required this.client, required this.baseUrl});
  final http.Client client;
  final String baseUrl;

  // Build uri with query parameters
  Uri _buildUri(String endpoint, Map<String, dynamic>? queryParameters) {
    final path =
        '${AppConstants.apiVersion}$endpoint'; // path: v1/transactions => v1 apiVersion
    if (queryParameters != null && queryParameters.isNotEmpty) {
      //https://api.yourbackend.com/v1/transactions?category=transport&page=1
      return Uri.parse(baseUrl).replace(
        path: path,
        queryParameters: queryParameters.map(
          (k, v) => MapEntry(k, v.toString()),
        ),
      );
    }
    return Uri.parse(
      baseUrl,
    ).replace(path: path); // https://api.yourbackend.com/v1/transactions
  }

  // Build headers
  Map<String, String> _buildHeaders(Map<String, String>? customHeaders) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    return headers;
  }

  // Handle API response
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    }

    //handle errors based on status code

    switch (response.statusCode) {
      case 400:
        throw ServerException('Bad request: ${response.body}');
      case 401:
        throw const ServerException('Unauthorized');
      case 403:
        throw const ServerException(
          'Forbidden',
        ); // token is valid but you dont have permission
      case 404:
        throw const ServerException(
          'Not found',
        ); //The thing we are looking for simply does not exist.
      case 409:
        // Conflict - might be sync conflict
        final body = json.decode(response.body);
        throw SyncConflictException(
          message: 'Sync conflict detected',
          localData: body['local'],
          remoteData: body['remote'],
        );
      case 500:
        throw const ServerException(
          'Internal server error',
        ); // Bug from server not client
      default:
        throw ServerException('Error ${response.statusCode}: ${response.body}');
    }
  }

  // Get request
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParameters);
      final response = await client
          .get(uri, headers: _buildHeaders(headers))
          .timeout(AppConstants.apiTimeout);
      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException(); // No internet connection is already the default value that's why we dont pass message here
    } on HttpException {
      throw const ServerException('Server error occurred');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // POST request
  Future<dynamic> post(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final uri = _buildUri(endpoint, null);

      final response = await client
          .post(uri, headers: _buildHeaders(headers), body: json.encode(body))
          .timeout(AppConstants.apiTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // PUT request
  Future<dynamic> put(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final uri = _buildUri(endpoint, null);

      final response = await client
          .put(uri, headers: _buildHeaders(headers), body: json.encode(body))
          .timeout(AppConstants.apiTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // DELETE request
  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint, null);

      final response = await client
          .delete(uri, headers: _buildHeaders(headers))
          .timeout(AppConstants.apiTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
