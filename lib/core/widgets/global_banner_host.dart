import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/services/rewarded_ad_manager.dart';

/// Keeps ONE banner ad permanently pinned to the bottom of the whole app.
///
/// It wraps the app's Navigator (see `MaterialApp.router(builder:)`), so the
/// banner stays put and is never reloaded while the learner moves between
/// screens. It is intentionally hidden only when it would be in the way:
///  * on the splash screen,
///  * while the keyboard is open (so it never floats over the keyboard),
///  * on the Dictionary screen, which shows its own in-page banner instead.
class GlobalBannerHost extends StatefulWidget {
  const GlobalBannerHost({
    super.key,
    required this.router,
    required this.child,
  });

  final GoRouter router;
  final Widget child;

  @override
  State<GlobalBannerHost> createState() => _GlobalBannerHostState();
}

class _GlobalBannerHostState extends State<GlobalBannerHost> {
  BannerAdSlot? _slot;

  @override
  void initState() {
    super.initState();
    if (sl.isRegistered<RewardedAdManager>()) {
      _slot = BannerAdSlot(
        manager: sl<RewardedAdManager>(),
        placementName: 'global_bottom',
      )..addListener(_rebuild);
      unawaited(_slot!.start());
    }
    widget.router.routeInformationProvider.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.router.routeInformationProvider.removeListener(_rebuild);
    _slot?.removeListener(_rebuild);
    _slot?.dispose();
    super.dispose();
  }

  bool get _routeAllowsBanner {
    final String path = widget.router.routeInformationProvider.value.uri.path;
    return path != AppRoutes.splash && path != AppRoutes.dictionary;
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final BannerAd? ad = _slot?.ad;
    final bool keyboardOpen = mq.viewInsets.bottom > 0;
    final bool show = ad != null && !keyboardOpen && _routeAllowsBanner;

    // The tree shape is identical whether or not the banner shows, so the
    // Navigator below is never re-parented or rebuilt from scratch.
    return Column(
      children: <Widget>[
        Expanded(
          child: MediaQuery(
            // The banner now owns the bottom safe-area inset, so the screen
            // above it must not pad for it a second time.
            data: show
                ? mq.copyWith(
                    padding: mq.padding.copyWith(bottom: 0),
                    viewPadding: mq.viewPadding.copyWith(bottom: 0),
                  )
                : mq,
            child: widget.child,
          ),
        ),
        if (show)
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: EdgeInsets.only(bottom: mq.padding.bottom),
              child: SizedBox(
                width: double.infinity,
                height: ad.size.height.toDouble(),
                child: Center(child: BannerAdView(ad: ad)),
              ),
            ),
          ),
      ],
    );
  }
}