import 'package:campus_connect/core/logging/app_logger.dart';

abstract interface class Analytics {
  Future<void> track(String event, {Map<String, Object> properties = const {}});
}

class LoggingAnalytics implements Analytics {
  const LoggingAnalytics(this._logger);

  final AppLogger _logger;

  @override
  Future<void> track(
    String event, {
    Map<String, Object> properties = const {},
  }) async {
    assert(
      RegExp(r'^[a-z]+\.[a-z_]+\.[a-z_]+$').hasMatch(event),
      'Analytics events use area.object.action.',
    );
    _logger.info('analytics.event', fields: {'name': event, ...properties});
  }
}
