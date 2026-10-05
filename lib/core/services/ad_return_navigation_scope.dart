import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lexiora/core/services/rewarded_ad_manager.dart';
import 'package:lexiora/core/utils/logger.dart';

/// Wraps one eligible feature route and offers the shared return interstitial
/// once when Back actually leaves that route. Unavailable ads do not delay Back.
class AdReturnNavigationScope extends StatefulWidget {
  const AdReturnNavigationScope({
    super.key,
    required this.manager,
    required this.child,
    this.navigationFallbackTimeout = const Duration(seconds: 18),
  });

  final RewardedAdManager manager;
  final Widget child;

  /// Safety boundary for a broken/missing ad callback. The real manager has a
  /// slightly shorter watchdog; this outer timeout also protects navigation
  /// from a future manager implementation that accidentally never completes.
  final Duration navigationFallbackTimeout;

  @override
  State<AdReturnNavigationScope> createState() =>
      _AdReturnNavigationScopeState();
}

class _AdReturnNavigationScopeState extends State<AdReturnNavigationScope> {
  bool _handlingBack = false;
  bool _exitAttempted = false;

  void _handleBack() {
    if (_handlingBack || !mounted) return;

    final NavigatorState navigator = Navigator.of(context);
    // A Back event that cannot leave this route is not an exit event; do not
    // request an ad on a root route or otherwise non-poppable location.
    if (!navigator.canPop()) return;

    if (_exitAttempted) {
      // Recover navigation without making another ad request if a previous
      // attempt's route pop was interrupted by another navigation event.
      _popWithoutAnotherAd(navigator);
      return;
    }

    _exitAttempted = true;
    _handlingBack = true;
    unawaited(_attemptInterstitialThenPop(navigator));
  }

  Future<void> _attemptInterstitialThenPop(NavigatorState navigator) async {
    try {
      final bool shown = await _showInterstitialSafely().timeout(
        widget.navigationFallbackTimeout,
        onTimeout: () {
          AppLogger.w(
            'INTERSTITIAL_NAVIGATION_FALLBACK '
            'reason=terminal_callback_timeout',
          );
          return false;
        },
      );
      AppLogger.i('INTERSTITIAL_EXIT_RESULT shown=$shown');
    } on Object catch (error, stackTrace) {
      AppLogger.e(
        'Optional return interstitial failed; navigation continues',
        error: error,
        stackTrace: stackTrace,
      );
    }

    if (!mounted || !navigator.mounted) return;
    try {
      if (navigator.canPop()) {
        navigator.pop();
      } else {
        _handlingBack = false;
      }
    } on Object catch (error, stackTrace) {
      _handlingBack = false;
      AppLogger.e(
        'Return navigation failed after optional interstitial attempt',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> _showInterstitialSafely() {
    final Completer<bool> result = Completer<bool>();

    void completeUnavailable() {
      if (!result.isCompleted) result.complete(false);
    }

    try {
      final Future<bool> request = widget.manager.showReturnInterstitial();
      unawaited(
        request.then<void>(
          (bool shown) {
            if (!result.isCompleted) result.complete(shown);
          },
          onError: (Object error, StackTrace stackTrace) {
            AppLogger.e(
              'Optional return interstitial failed; navigation continues',
              error: error,
              stackTrace: stackTrace,
            );
            completeUnavailable();
          },
        ),
      );
    } on Object catch (error, stackTrace) {
      AppLogger.e(
        'Optional return interstitial failed; navigation continues',
        error: error,
        stackTrace: stackTrace,
      );
      completeUnavailable();
    }

    return result.future;
  }

  void _popWithoutAnotherAd(NavigatorState navigator) {
    if (!navigator.mounted || !navigator.canPop()) {
      _handlingBack = false;
      return;
    }
    _handlingBack = true;
    try {
      navigator.pop();
    } on Object catch (error, stackTrace) {
      _handlingBack = false;
      AppLogger.e(
        'Return navigation recovery failed without a second ad request',
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
