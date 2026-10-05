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
      'ca-app-pub-4342811933559577~3999306324';
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
  mainQuizPakistanAffairs,
  mainQuizIslamicStudies,
  mainQuizGeneralScienceAbility,
  mainQuizEnglish,
  aiAssistant,
}

enum RewardedAdResult {
  rewarded,
  premium,
  cooldown,
  unavailable,
  failed,
}

enum RewardedAdReadiness { ready, loading, retrying, showing, notReady }

/// The single owner of all AdMob lifecycle and monetization policy.
///
/// Feature code must call this service rather than importing
/// `google_mobile_ads`. Ads are optional: unavailable or failed ads never
/// prevent navigation, studying, or AI use. The entitlement callback is the
/// future integration point for authentication and billing.
class RewardedAdManager {
  static const Duration _rewardedLoadTimeout = Duration(seconds: 45);
  static const int _maxRewardedAutoRetries = 3;

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
  Future<void>? _initializationInFlight;
  Timer? _rewardedRetryTimer;
  int _rewardedRetryAttempt = 0;
  DateTime? _lastInterstitialShown;
  bool _returnInterstitialShownThisSession = false;
  final Map<RewardedAdPlacement, DateTime> _lastRewardedShown =
      <RewardedAdPlacement, DateTime>{};
  int _legacyOtherQuizCompletions = 0;
  int _aiRequestsRemaining = AdConfiguration.FREE_AI_REQUEST_LIMIT;
  bool _initialized = false;
  bool _showingInterstitial = false;
  bool _showingRewarded = false;
  bool _disposed = false;

  bool get isLoaded => _rewardedAd != null;
  bool get isRewardedLoading => _rewardedLoadInFlight != null;
  RewardedAdReadiness get rewardedReadiness {
    if (_rewardedAd != null) return RewardedAdReadiness.ready;
    if (_showingRewarded) return RewardedAdReadiness.showing;
    if (_rewardedLoadInFlight != null) return RewardedAdReadiness.loading;
    if (_rewardedRetryTimer?.isActive ?? false) {
      return RewardedAdReadiness.retrying;
    }
    return RewardedAdReadiness.notReady;
  }
  bool get isInterstitialLoaded => _interstitialAd != null;
  bool get isInitialized => _initialized;
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
  Future<void> initialize() {
    if (_disposed) return Future<void>.value();
    if (_initialized) return Future<void>.value();
    final Future<void>? inFlight = _initializationInFlight;
    if (inFlight != null) return inFlight;
    final Future<void> initialization = Future<void>.microtask(_initializeSdk);
    _initializationInFlight = initialization;
    return initialization;
  }

  Future<void> _initializeSdk() async {
    try {
      AppLogger.i('AdMob SDK initialization started (release=$kReleaseMode)');
      await MobileAds.instance.initialize();
      _initialized = true;
      AppLogger.i(
        'AdMob SDK initialization succeeded '
        '(bannerUnit=${AdConfiguration.bannerId}, '
        'interstitialUnit=${AdConfiguration.interstitialId}, '
        'rewardedUnit=${AdConfiguration.rewardedId})',
      );
    } on Object catch (error, stackTrace) {
      _initialized = false;
      AppLogger.e(
        'AdMob SDK initialization failed',
        error: error,
        stackTrace: stackTrace,
      );
      return;
    } finally {
      _initializationInFlight = null;
    }
    unawaited(loadRewarded());
    unawaited(loadInterstitial());
  }

  Future<void> loadRewarded() => _loadRewarded(isRetry: false);

  Future<void> _loadRewarded({required bool isRetry}) async {
    final String source = isRetry ? 'retry' : 'explicit';
    AppLogger.i(
      'REWARDED_LOAD_REQUEST source=$source '
      'readiness=$rewardedReadiness unit=${AdConfiguration.rewardedId}',
    );
    if (_disposed) {
      AppLogger.w('REWARDED_LOAD_REQUEST skipped reason=manager_disposed');
      return;
    }
    if (!_initialized) {
      AppLogger.w('REWARDED_LOAD_REQUEST skipped reason=sdk_not_initialized');
      return;
    }
    if (_rewardedAd != null) {
      AppLogger.i('REWARDED_LOAD_REQUEST skipped reason=already_ready');
      return;
    }
    if (_rewardedLoadInFlight != null) {
      AppLogger.i('REWARDED_LOAD_REQUEST skipped reason=already_loading');
      return;
    }
    if (_rewardedRetryTimer?.isActive ?? false) {
      AppLogger.i('REWARDED_LOAD_REQUEST skipped reason=retry_backoff');
      return;
    }
    if (!isRetry) _rewardedRetryAttempt = 0;

    final Completer<void> done = Completer<void>();
    final Future<void> requestFuture = done.future;
    _rewardedLoadInFlight = requestFuture;
    bool retryAfterFailure = false;
    bool failureLogged = false;
    AppLogger.i('REWARDED_LOAD_STARTED unit=${AdConfiguration.rewardedId}');

    void failLoad({
      required String code,
      required String message,
      String? domain,
      Object? error,
      StackTrace? stackTrace,
    }) {
      if (failureLogged) return;
      failureLogged = true;
      retryAfterFailure = true;
      AppLogger.w(
        'REWARDED_LOAD_FAILED unit=${AdConfiguration.rewardedId} '
        'code=$code message=$message domain=${domain ?? 'unknown'}',
      );
      if (error != null) {
        AppLogger.e(
          'Rewarded load failure details',
          error: error,
          stackTrace: stackTrace,
        );
      }
      if (!done.isCompleted) done.complete();
    }

    try {
      final Future<void> platformLoad = RewardedAd.load(
        adUnitId: AdConfiguration.rewardedId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            if (_disposed) {
              unawaited(ad.dispose());
              if (!done.isCompleted) done.complete();
              return;
            }
            final RewardedAd? previous = _rewardedAd;
            if (previous != null && !identical(previous, ad)) {
              unawaited(previous.dispose());
            }
            _rewardedAd = ad;
            _rewardedRetryTimer?.cancel();
            _rewardedRetryTimer = null;
            _rewardedRetryAttempt = 0;
            AppLogger.i(
              'REWARDED_LOAD_SUCCESS unit=${AdConfiguration.rewardedId} '
              'responseInfo=${ad.responseInfo}',
            );
            if (!done.isCompleted) done.complete();
          },
          onAdFailedToLoad: (LoadAdError error) {
            failLoad(
              code: '${error.code}',
              message: error.message,
              domain: error.domain,
              error: error,
            );
          },
        ),
      );
      unawaited(
        platformLoad.catchError((Object error, StackTrace stackTrace) {
          failLoad(
            code: 'exception',
            message: error.toString(),
            error: error,
            stackTrace: stackTrace,
          );
        }),
      );
      await requestFuture.timeout(_rewardedLoadTimeout);
    } on TimeoutException catch (error, stackTrace) {
      failLoad(
        code: 'timeout',
        message: 'No rewarded load callback within $_rewardedLoadTimeout',
        error: error,
        stackTrace: stackTrace,
      );
    } on Object catch (error, stackTrace) {
      failLoad(
        code: 'exception',
        message: error.toString(),
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (identical(_rewardedLoadInFlight, requestFuture)) {
        _rewardedLoadInFlight = null;
      }
      if (retryAfterFailure && _rewardedAd == null) {
        _scheduleRewardedRetry();
      }
    }
  }

  void _scheduleRewardedRetry() {
    if (_disposed || !_initialized || _rewardedAd != null) return;
    if (_rewardedLoadInFlight != null) return;
    if (_rewardedRetryTimer?.isActive ?? false) return;
    if (_rewardedRetryAttempt >= _maxRewardedAutoRetries) {
      AppLogger.w(
        'REWARDED_RELOAD_REQUEST skipped reason=retry_limit_reached '
        'attempts=$_rewardedRetryAttempt',
      );
      return;
    }

    final int retryNumber = _rewardedRetryAttempt + 1;
    final Duration delay = Duration(
      seconds: 5 * (1 << _rewardedRetryAttempt),
    );
    _rewardedRetryAttempt++;
    AppLogger.i(
      'REWARDED_RELOAD_REQUEST reason=load_failure retry=$retryNumber '
      'delay=${delay.inSeconds}s',
    );
    _rewardedRetryTimer = Timer(delay, () {
      _rewardedRetryTimer = null;
      if (_disposed || !_initialized || _rewardedAd != null) return;
      unawaited(_loadRewarded(isRetry: true));
    });
  }

  Future<void> loadInterstitial() async {
    if (!_initialized || _interstitialAd != null || _interstitialLoadInFlight != null) return;
    AppLogger.i(
      'Interstitial ad load requested '
      '(unit=${AdConfiguration.interstitialId})',
    );
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
            AppLogger.i(
              'Interstitial ad loaded (responseInfo=${ad.responseInfo})',
            );
            done.complete();
          },
          onAdFailedToLoad: (LoadAdError error) {
            AppLogger.w(
              'Interstitial ad failed to load '
              '(unit=${AdConfiguration.interstitialId}, '
              'code=${error.code}, message=${error.message}, '
              'domain=${error.domain}, responseInfo=${error.responseInfo})',
            );
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
    AppLogger.i('Return-navigation interstitial check started');
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
      AppLogger.w(
        'Return-navigation interstitial unavailable; no loaded ad is ready',
      );
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

    AppLogger.i(
      'Return-navigation interstitial show requested '
      '(responseInfo=${ad.responseInfo})',
    );
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdShowedFullScreenContent: (InterstitialAd shownAd) {
        AppLogger.i(
          'Return-navigation interstitial shown '
          '(responseInfo=${shownAd.responseInfo})',
        );
      },
      onAdDismissedFullScreenContent: (InterstitialAd dismissedAd) {
        AppLogger.i(
          'Return-navigation interstitial dismissed '
          '(responseInfo=${dismissedAd.responseInfo})',
        );
        unawaited(dismissedAd.dispose());
        finish(true);
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd failedAd, AdError error) {
        AppLogger.w(
          'Return-navigation interstitial failed to show '
          '(code=${error.code}, message=${error.message}, '
          'domain=${error.domain}, responseInfo=${failedAd.responseInfo})',
        );
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
    AppLogger.i(
      'REWARDED_SHOW_REQUEST placement=$placement readiness=$rewardedReadiness '
      'unit=${AdConfiguration.rewardedId}',
    );
    if (await isPremiumUser()) return RewardedAdResult.premium;
    if (_showingRewarded) {
      AppLogger.w(
        'REWARDED_SHOW_FAILED placement=$placement reason=another_rewarded_ad_is_showing',
      );
      return RewardedAdResult.unavailable;
    }
    final DateTime? lastShown = _lastRewardedShown[placement];
    // A single Grammar placement covers three independent section ladders and
    // repeated milestones. A wall-clock cooldown here would block legitimate
    // rewards for those other sections/stages even when an ad is ready.
    if (placement != RewardedAdPlacement.grammarQuiz &&
        lastShown != null &&
        DateTime.now().difference(lastShown) < rewardedCooldown) {
      AppLogger.w(
        'REWARDED_SHOW_FAILED placement=$placement reason=cooldown '
        'remaining=${rewardedCooldown - DateTime.now().difference(lastShown)}',
      );
      return RewardedAdResult.cooldown;
    }
    if (!_initialized) await initialize();
    if (!_initialized) {
      AppLogger.w(
        'REWARDED_SHOW_FAILED placement=$placement reason=sdk_not_initialized',
      );
      return RewardedAdResult.unavailable;
    }
    final RewardedAd? ad = _rewardedAd;
    if (ad == null) {
      AppLogger.w(
        'REWARDED_SHOW_FAILED placement=$placement reason=not_ready '
        'readiness=$rewardedReadiness unit=${AdConfiguration.rewardedId}',
      );
      if (rewardedReadiness == RewardedAdReadiness.notReady) {
        unawaited(loadRewarded());
      }
      return RewardedAdResult.unavailable;
    }

    _rewardedAd = null;
    _showingRewarded = true;
    _lastRewardedShown[placement] = DateTime.now();
    final Completer<RewardedAdResult> result = Completer<RewardedAdResult>();
    bool rewarded = false;
    bool completed = false;
    Future<void>? rewardCallbackInFlight;

    void finish(RewardedAdResult value) {
      if (completed) return;
      completed = true;
      unawaited(() async {
        // Persist any caller-owned entitlement before exposing completion. The
        // callback is started only by AdMob's official earned-reward event.
        await rewardCallbackInFlight;
        _showingRewarded = false;
        if (value == RewardedAdResult.failed) {
          _lastRewardedShown.remove(placement);
        }
        if (!result.isCompleted) result.complete(value);
        final String reloadReason = value == RewardedAdResult.rewarded
            ? 'ad_consumed'
            : 'show_finished';
        AppLogger.i(
          'REWARDED_RELOAD_REQUEST reason=$reloadReason placement=$placement',
        );
        unawaited(loadRewarded());
      }());
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdShowedFullScreenContent: (RewardedAd shownAd) {
        AppLogger.i(
          'REWARDED_SHOW_SUCCESS placement=$placement '
          'responseInfo=${shownAd.responseInfo}',
        );
      },
      onAdDismissedFullScreenContent: (RewardedAd dismissedAd) {
        AppLogger.i(
          'REWARDED_AD_DISMISSED placement=$placement earned=$rewarded '
          'responseInfo=${dismissedAd.responseInfo}',
        );
        unawaited(dismissedAd.dispose());
        finish(rewarded ? RewardedAdResult.rewarded : RewardedAdResult.failed);
      },
      onAdFailedToShowFullScreenContent: (RewardedAd failedAd, AdError error) {
        AppLogger.w(
          'REWARDED_SHOW_FAILED placement=$placement code=${error.code} '
          'message=${error.message} domain=${error.domain} '
          'responseInfo=${failedAd.responseInfo}',
        );
        unawaited(failedAd.dispose());
        finish(RewardedAdResult.failed);
      },
    );
    try {
      await ad.show(
        onUserEarnedReward: (AdWithoutView shownAd, RewardItem reward) {
          if (rewarded) return;
          rewarded = true;
          AppLogger.i(
            'REWARDED_EARNED placement=$placement '
            'amount=${reward.amount} type=${reward.type}',
          );
          if (onRewarded != null) {
            rewardCallbackInFlight = Future<void>.sync(onRewarded).catchError(
              (Object error, StackTrace stackTrace) {
                AppLogger.e(
                  'Rewarded ad earned callback failed',
                  error: error,
                  stackTrace: stackTrace,
                );
              },
            );
          }
        },
      );
    } on Object catch (error, stackTrace) {
      AppLogger.e(
        'REWARDED_SHOW_FAILED placement=$placement reason=exception',
        error: error,
        stackTrace: stackTrace,
      );
      unawaited(ad.dispose());
      finish(RewardedAdResult.failed);
    }
    return result.future;
  }

  /// Keeps the legacy non-Main-Quiz streak prompt available to topic/Grammar
  /// ladders. Main Quiz uses independent subject + milestone unlock records.
  bool recordNonMainQuizCompletion() {
    _legacyOtherQuizCompletions++;
    return _legacyOtherQuizCompletions % 5 == 0;
  }

  void dispose() {
    _disposed = true;
    _rewardedRetryTimer?.cancel();
    _rewardedRetryTimer = null;
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
  const ManagedBannerAd({
    super.key,
    required this.manager,
    this.placementName = 'unspecified',
  });

  final RewardedAdManager manager;
  final String placementName;

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
    AppLogger.i(
      'Banner ad load requested '
      '(placement=${widget.placementName}, unit=${AdConfiguration.bannerId})',
    );
    await widget.manager.initialize();
    if (!widget.manager.isInitialized) {
      AppLogger.w(
        'Banner ad request skipped because AdMob SDK initialization failed '
        '(placement=${widget.placementName})',
      );
      return;
    }
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
          AppLogger.i(
            'Banner ad loaded (placement=${widget.placementName}, '
            'unit=${AdConfiguration.bannerId}, '
            'responseInfo=${(ad as BannerAd).responseInfo})',
          );
          setState(() {
            _ad = ad;
            _loaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          AppLogger.w(
            'Banner ad failed to load '
            '(placement=${widget.placementName}, '
            'unit=${AdConfiguration.bannerId}, code=${error.code}, '
            'message=${error.message}, domain=${error.domain}, '
            'responseInfo=${error.responseInfo})',
          );
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
