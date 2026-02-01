import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
}

class NetworkInfoImpl implements NetworkInfo {
  const NetworkInfoImpl(this.connectivity);
  final Connectivity connectivity;
  @override
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }

  @override
  Stream<bool> get onConnectivityChanged async* {
    await for (final result in connectivity.onConnectivityChanged) {
      yield result.any((r) => r != ConnectivityResult.none);
    }
  }
}
