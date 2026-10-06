import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lexiora/core/services/rewarded_ad_manager.dart';
import 'package:lexiora/core/utils/logger.dart';

/// Wraps a major feature route and offers the shared return interstitial once
/// on Back when policy allows it. The ad is best-effort; Back never waits for it.
class AdReturnNavigationScope extends StatefulWidget {
  const AdReturnNavigationScope({
    super.key,
    required this.manager,
    required this.child,
  });

  final RewardedAdManager manager;
  final Widget child;

  @override
  State<AdReturnNavigationScope> createState() => _AdReturnNavigationScopeState();
}

class _AdReturnNavigationScopeState extends State<AdReturnNavigationScope> {
  bool _handlingBack = false;

  @override
  void initState() {
    super.initState();
    // Make sure an interstitial is already loaded by the time the learner
    // presses Back (no-op when one is ready/loading or the SDK is not up yet).
    unawaited(widget.manager.loadInterstitial());
  }

  void _handleBack() {
    if (_handlingBack || !mounted) return;
    _handlingBack = true;
    final NavigatorState navigator = Navigator.of(context);
    unawaited(_showOptionalInterstitial());
    try {
      if (navigator.canPop()) {
        navigator.pop();
      } else {
        _handlingBack = false;
      }
    } on Object catch (error, stackTrace) {
      _handlingBack = false;
      AppLogger.e(
        'Return navigation failed after optional interstitial request',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _showOptionalInterstitial() async {
    try {
      await widget.manager.showReturnInterstitial();
    } on Object catch (error, stackTrace) {
      AppLogger.e(
        'Optional return interstitial failed; navigation continues',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (!didPop) _handleBack();
        },
        child: widget.child,
      );
}