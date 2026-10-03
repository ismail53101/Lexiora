import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lexiora/core/services/rewarded_ad_manager.dart';

/// Wraps a major feature route and offers the shared return interstitial once
/// on Back when policy allows it. If no ad is ready, Back is immediate.
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

  Future<void> _handleBack() async {
    if (_handlingBack || !mounted) return;
    _handlingBack = true;
    await widget.manager.showReturnInterstitial();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (!didPop) unawaited(_handleBack());
        },
        child: widget.child,
      );
}
