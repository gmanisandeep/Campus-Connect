import 'package:campus_connect/core/configuration/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FeatureFlag { designSystemGallery, demoSession }

final featureFlagsProvider = Provider<Map<FeatureFlag, bool>>((ref) {
  final config = ref.watch(appConfigProvider);
  return {
    FeatureFlag.designSystemGallery: config.enableDesignSystemGallery,
    FeatureFlag.demoSession: config.enableDemoSession,
  };
});
