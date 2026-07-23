import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkStatus { online, offline }

abstract interface class ConnectivityService {
  Future<NetworkStatus> current();
  Stream<NetworkStatus> get changes;
}

class ConnectivityPlusService implements ConnectivityService {
  ConnectivityPlusService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<NetworkStatus> current() async =>
      _map(await _connectivity.checkConnectivity());

  @override
  Stream<NetworkStatus> get changes =>
      _connectivity.onConnectivityChanged.map(_map).distinct();

  NetworkStatus _map(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none)
      ? NetworkStatus.online
      : NetworkStatus.offline;
}
