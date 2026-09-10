import 'package:flutter/material.dart';

/// Native Ads are disabled per project configuration.
/// Returns an empty widget with no ad requests.
class NativeAdCardWidget extends StatelessWidget {
  final String? adUnitId;

  const NativeAdCardWidget({
    super.key,
    this.adUnitId,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
