import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lexiora/core/utils/logger.dart';

typedef PremiumChecker = FutureOr<bool> Function();
typedef RewardCallback = FutureOr<void> Function();

/// Centralized AdMob configuration. Test IDs are used in debug/profile builds;
/// production IDs are selected only for release builds.
abstract final class AdConfiguration {
  static const String androidTestAppId =
      'ca-app-pub-3940256099942544~3347511713';
  static const String androidProductionAppId =
      'ca-app-pub-4342811933559577~399306324';
  static const String testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String productionBannerId =
      'ca-app-pub-4342811933559577/9332447492';
  static const String testInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String productionInterstitialId =
      'ca-app-pub-4342811933559577/7060583937';
  static const String testRewardedId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String productionRewardedId =
      'ca-app-pub-4342811933559577/5768607000';
  static const int rewardedQuizMilestone = 5;
  /// Central AI usage configuration; change these values without changing the
  /// AI Assistant flow or rewarded-ad implementation.
  static const int FREE_AI_REQUEST_LIMIT = 7;
  static const int REWARDED_AI_REQUEST_BONUS = 7;

  static String get bannerId => kReleaseMode
      ? _productionOrTest(productionBannerId, testBannerId)
      : testBannerId;
  static String get interstitialId => kReleaseMode
      ? _productionOrTest(productionInterstitialId, testInterstitialId)
      : testInterstitialId;
  static String get rewardedId => kReleaseMode
      ? _productionOrTest(productionRewardedId, testRewardedId)
      : testRewardedId;

  /// A production ID may only be used when it is well-formed. The Google
  /// Mobile Ads SDK rejects malformed IDs (and crashes on a malformed App ID
  /// at process start), so anything that does not match AdMob's official
  /// ca-app-pub-{16}~{10} / ca-app-pub-{16}/{10} shape silently falls back to
  /// the matching Google test ID.
  static bool _isWellFormed(String id) =>
      RegExp(r'^ca-app-pub-[0-9]{16}[~/][0-9]{10}$').hasMatch(id);

  static String _productionOrTest(String id, String testId) =>
      _isWellFormed(id) ? id : testId;
}

enum RewardedAdPlacement {
  grammarQuiz,
  quiz,
  aiAssistant,
}

enum RewardedAdResult {
  rewarded,
  premium,
  cooldown,
  unavailable,
  dismissedWithoutReward,
  failed,
}

/// The single owner of all AdMob lifecycle and monetization policy.
///
/// Feature code must call this service rather than importing
/// `google_mobile_ads`. Ads are optional: unavailable or failed ads never
/// prevent navigation, studying, or AI use. The entitlement callback is the
/// future integration point for authentication and billing.
class RewardedAdManager {
  RewardedAdManager({
    required PremiumChecker isPremium,
    this.interstitialCooldown = const Duration(minutes: 10),
    this.rewardedCooldown = const Duration(minutes: 5),
  }) : _isPremium = isPremium;

  final PremiumChecker _isPremium;
  final Duration interstitialCooldown;
  final Duration rewardedCooldown;

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  Future<void>? _rewardedLoadInFlight;
  Future<void>? _interstitialLoadInFlight;
  DateTime? _lastInterstitialShown;
  bool _returnInterstitialShownThisSession = false;
  final Map<RewardedAdPlacement, DateTime> _lastRewardedShown =
      <RewardedAdPlacement, DateTime>{};
  int _mainQuizCompletions = 0;
  int _grammarQuizCompletions = 0;
  int _aiRequestsRemaining = AdConfiguration.FREE_AI_REQUEST_LIMIT;
  bool _initialized = false;
  bool _showingInterstitial = false;
  bool _showingRewarded = false;

  bool get isLoaded => _rewardedAd != null;
  bool get isInterstitialLoaded => _interstitialAd != null;
  int get aiRequestsRemaining => _aiRequestsRemaining;

  Future<bool> isPremiumUser() async {
    try {
      return await _isPremium();
    } on Object catch (error, stackTrace) {
      AppLogger.e(
        'Premium entitlement check failed; using free-ad behavior',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Returns whether a new AI request may start. Premium bypasses the free
  /// allowance; free users must have an unconsumed successful-request slot.
  Future<bool> canStartAiRequest() async =>
      await isPremiumUser() || _aiRequestsRemaining > 0;

  /// Consumes one slot only after the AI provider reports a successful reply.
  void recordSuccessfulAiRequest() {
    if (_aiRequestsRemaining > 0) _aiRequestsRemaining--;
  }

  /// Adds exactly one configured allowance after a completed rewarded ad.
  void grantAiRequestsAfterReward() {
    _aiRequestsRemaining += AdConfiguration.REWARDED_AI_REQUEST_BONUS;
  }

  /// Initializes the SDK once and preloads the shared full-screen ads.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await MobileAds.instance.initialize();
      unawaited(loadRewarded());
      unawaited(loadInterstitial());
    } on Object catch (error, stackTrace) {
      _initialized = false;
      AppLogger.e('AdMob initialization failed', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> loadRewarded() async {
    if (!_initialized || _rewardedAd != null || _rewardedLoadInFlight != null) return;
    final Completer<void> done = Completer<void>();
    _rewardedLoadInFlight = done.future;
    try {
      await RewardedAd.load(
        adUnitId: AdConfiguration.rewardedId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            final RewardedAd? previous = _rewardedAd;
            if (previous != null) unawaited(previous.dispose());
            _rewardedAd = ad;
            done.complete();
          },
          onAdFailedToLoad: (LoadAdError error) {
            AppLogger.w('Rewarded ad failed to load: $error');
            done.complete();
          },
        ),
      );
      await done.future;
    } on Object catch (error, stackTrace) {
      AppLogger.e('Rewarded ad load failed unexpectedly', error: error, stackTrace: stackTrace);
      if (!done.isCompleted) done.complete();
    } finally {
      _rewardedLoadInFlight = null;
    }
  }

  Future<void> loadInterstitial() async {
    if (!_initialized || _interstitialAd != null || _interstitialLoadInFlight != null) return;
    final Completer<void> done = Completer<void>();
    _interstitialLoadInFlight = done.future;
    try {
      await InterstitialAd.load(
        adUnitId: AdConfiguration.interstitialId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            final InterstitialAd? previous = _interstitialAd;
            if (previous != null) unawaited(previous.dispose());
            _interstitialAd = ad;
            done.complete();
          },
          onAdFailedToLoad: (LoadAdError error) {
            AppLogger.w('Interstitial ad failed to load: $error');
            done.complete();
          },
        ),
      );
      await done.future;
    } on Object catch (error, stackTrace) {
      AppLogger.e('Interstitial ad load failed unexpectedly', error: error, stackTrace: stackTrace);
      if (!done.isCompleted) done.complete();
    } finally {
      _interstitialLoadInFlight = null;
    }
  }

  /// Shows one return-navigation interstitial when it is already ready.
  /// Returns immediately with false when policy or availability says no ad.
  Future<bool> showReturnInterstitial() async {
    if (await isPremiumUser() ||
        _showingInterstitial ||
        _returnInterstitialShownThisSession) return false;
    final DateTime now = DateTime.now();
    if (_lastInterstitialShown != null &&
        now.difference(_lastInterstitialShown!) < interstitialCooldown) {
      return false;
    }
    final InterstitialAd? ad = _interstitialAd;
    if (ad == null) {
      unawaited(loadInterstitial());
      return false;
    }
    _interstitialAd = null;
    _showingInterstitial = true;
    _returnInterstitialShownThisSession = true;
    _lastInterstitialShown = now;
    final Completer<bool> result = Completer<bool>();
    bool completed = false;

    void finish(bool shown) {
      if (completed) return;
      completed = true;
      _showingInterstitial = false;
      if (!result.isCompleted) result.complete(shown);
      unawaited(loadInterstitial());
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (InterstitialAd dismissedAd) {
        unawaited(dismissedAd.dispose());
        finish(true);
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd failedAd, AdError error) {
        AppLogger.w('Interstitial ad failed to show: $error');
        unawaited(failedAd.dispose());
        _lastInterstitialShown = null;
        _returnInterstitialShownThisSession = false;
        finish(false);
      },
    );
    try {
      await ad.show();
    } on Object catch (error, stackTrace) {
      AppLogger.e('Interstitial ad show failed unexpectedly', error: error, stackTrace: stackTrace);
      unawaited(ad.dispose());
      _lastInterstitialShown = null;
      _returnInterstitialShownThisSession = false;
      finish(false);
    }
    return result.future;
  }

  /// Explicit AI action used by the limit dialog. The allowance is granted
  /// only after the official rewarded completion callback returns success.
  Future<bool> watchAdForMoreAi() async {
    final RewardedAdResult result = await showRewarded(
      placement: RewardedAdPlacement.aiAssistant,
    );
    if (result != RewardedAdResult.rewarded) return false;
    grantAiRequestsAfterReward();
    return true;
  }

  /// Shows a rewarded ad only when the caller has already obtained explicit
  /// user consent (for example, after pressing “Watch Ad for More AI”).
  Future<RewardedAdResult> showRewarded({
    required RewardedAdPlacement placement,
    RewardCallback? onRewarded,
  }) async {
    if (await isPremiumUser()) return RewardedAdResult.premium;
    if (_showingRewarded) return RewardedAdResult.unavailable;
    final DateTime? lastShown = _lastRewardedShown[placement];
    if (lastShown != null && DateTime.now().difference(lastShown) < rewardedCooldown) {
      return RewardedAdResult.cooldown;
    }
    if (!_initialized) await initialize();
    final RewardedAd? ad = _rewardedAd;
    if (ad == null) {
      unawaited(loadRewarded());
      return RewardedAdResult.unavailable;
    }

    _rewardedAd = null;
    _showingRewarded = true;
    _lastRewardedShown[placement] = DateTime.now();
    final Completer<RewardedAdResult> result = Completer<RewardedAdResult>();
    bool rewarded = false;
    bool completed = false;

    void finish(RewardedAdResult value) {
      if (completed) return;
      completed = true;
      _showingRewarded = false;
      if (value == RewardedAdResult.failed) _lastRewardedShown.remove(placement);
      if (!result.isCompleted) result.complete(value);
      unawaited(loadRewarded());
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (RewardedAd dismissedAd) {
        unawaited(dismissedAd.dispose());
        finish(rewarded
            ? RewardedAdResult.rewarded
            : RewardedAdResult.dismissedWithoutReward);
      },
      onAdFailedToShowFullScreenContent: (RewardedAd failedAd, AdError error) {
        AppLogger.w('Rewarded ad failed to show: $error');
        unawaited(failedAd.dispose());
        finish(RewardedAdResult.failed);
      },
    );
    try {
      await ad.show(
        onUserEarnedReward: (AdWithoutView shownAd, RewardItem reward) {
          if (rewarded) return;
          rewarded = true;
          if (onRewarded != null) {
            unawaited(Future<void>(() async => onRewarded()));
          }
        },
      );
    } on Object catch (error, stackTrace) {
      AppLogger.e('Rewarded ad show failed unexpectedly', error: error, stackTrace: stackTrace);
      unawaited(ad.dispose());
      finish(RewardedAdResult.failed);
    }
    return result.future;
  }

  /// Returns true on every fifth completed main-Quiz session in this app run.
  bool recordMainQuizCompletion() {
    _mainQuizCompletions++;
    return _mainQuizCompletions % AdConfiguration.rewardedQuizMilestone == 0;
  }

  /// Returns true only for every fifth completed grammar quiz.
  bool recordGrammarQuizCompletion() {
    _grammarQuizCompletions++;
    return _grammarQuizCompletions % AdConfiguration.rewardedQuizMilestone == 0;
  }

  void dispose() {
    final RewardedAd? rewarded = _rewardedAd;
    final InterstitialAd? interstitial = _interstitialAd;
    if (rewarded != null) unawaited(rewarded.dispose());
    if (interstitial != null) unawaited(interstitial.dispose());
    _rewardedAd = null;
    _interstitialAd = null;
  }
}

/// Temporary entitlement adapter until authentication and billing exist.
class NoPremiumEntitlementService {
  const NoPremiumEntitlementService();
  Future<bool> get isPremium async => false;
}

/// A lifecycle-safe banner widget backed by the centralized AdMob config.
class ManagedBannerAd extends StatefulWidget {
  const ManagedBannerAd({super.key, required this.manager});

  final RewardedAdManager manager;

  @override
  State<ManagedBannerAd> createState() => _ManagedBannerAdState();
}

class _ManagedBannerAdState extends State<ManagedBannerAd> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await widget.manager.initialize();
    if (await widget.manager.isPremiumUser()) return;
    final BannerAd ad = BannerAd(
      adUnitId: AdConfiguration.bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          if (!mounted) {
            unawaited(ad.dispose());
            return;
          }
          setState(() {
            _ad = ad as BannerAd;
            _loaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          AppLogger.w('Banner ad failed to load: $error');
          unawaited(ad.dispose());
        },
      ),
    );
    _ad = ad;
    try {
      await ad.load();
    } on Object catch (error, stackTrace) {
      AppLogger.e('Banner ad load failed unexpectedly', error: error, stackTrace: stackTrace);
      unawaited(ad.dispose());
    }
  }

  @override
  void dispose() {
    final BannerAd? ad = _ad;
    if (ad != null) unawaited(ad.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        width: _ad!.size.width.toDouble(),
        height: _ad!.size.height.toDouble(),
        child: AdWidget(ad: _ad!),
      ),
    );
  }
}
