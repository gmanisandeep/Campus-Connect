import 'dart:async';

import 'package:campus_connect/core/configuration/providers.dart';
import 'package:campus_connect/core/networking/connectivity_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('ConnectivityPlusService', () {
    test('current maps connected and disconnected results', () async {
      final connectivity = _MockConnectivity();
      final service = ConnectivityPlusService(connectivity: connectivity);

      when(
        connectivity.checkConnectivity,
      ).thenAnswer((_) async => const [ConnectivityResult.none]);
      expect(await service.current(), NetworkStatus.offline);

      when(
        connectivity.checkConnectivity,
      ).thenAnswer((_) async => const [ConnectivityResult.wifi]);
      expect(await service.current(), NetworkStatus.online);
    });

    test('changes suppresses consecutive mapped duplicates', () async {
      final connectivity = _MockConnectivity();
      final source = StreamController<List<ConnectivityResult>>();
      addTearDown(source.close);
      when(
        () => connectivity.onConnectivityChanged,
      ).thenAnswer((_) => source.stream);
      final service = ConnectivityPlusService(connectivity: connectivity);
      final result = service.changes.take(3).toList();

      source
        ..add(const [ConnectivityResult.wifi])
        ..add(const [ConnectivityResult.mobile])
        ..add(const [ConnectivityResult.none])
        ..add(const [ConnectivityResult.none])
        ..add(const [ConnectivityResult.ethernet]);

      expect(await result, const [
        NetworkStatus.online,
        NetworkStatus.offline,
        NetworkStatus.online,
      ]);
    });
  });

  test(
    'connectivityProvider emits current status before subsequent changes',
    () async {
      final service = _FakeConnectivityService(NetworkStatus.offline);
      final container = ProviderContainer(
        overrides: [connectivityServiceProvider.overrideWithValue(service)],
      );
      final observed = <NetworkStatus>[];
      final sawInitial = Completer<void>();
      final sawChange = Completer<void>();
      final subscription = container.listen(connectivityProvider, (_, next) {
        next.whenData((status) {
          observed.add(status);
          if (observed.length == 1) {
            sawInitial.complete();
          } else if (observed.length == 2) {
            sawChange.complete();
          }
        });
      }, fireImmediately: true);
      addTearDown(subscription.close);
      addTearDown(container.dispose);
      addTearDown(service.close);

      await sawInitial.future;
      expect(observed, const [NetworkStatus.offline]);
      expect(service.currentCalls, 1);

      service.emit(NetworkStatus.online);
      await sawChange.future;

      expect(observed, const [NetworkStatus.offline, NetworkStatus.online]);
    },
  );
}

class _MockConnectivity extends Mock implements Connectivity {}

class _FakeConnectivityService implements ConnectivityService {
  _FakeConnectivityService(this._initial);

  final NetworkStatus _initial;
  final StreamController<NetworkStatus> _changes = StreamController();
  int currentCalls = 0;

  @override
  Stream<NetworkStatus> get changes => _changes.stream;

  @override
  Future<NetworkStatus> current() async {
    currentCalls += 1;
    return _initial;
  }

  void emit(NetworkStatus status) => _changes.add(status);

  Future<void> close() => _changes.close();
}
