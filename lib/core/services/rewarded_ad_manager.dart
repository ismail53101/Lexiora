import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lexiora/core/services/ai_usage_store.dart';
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

  /// After the free searches run out, the learner can either wait this long
  /// for a fresh free batch, or watch a rewarded ad to continue right away.
  static const Duration AI_FREE_REFILL_INTERVAL = Duration(hours: 1);

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
  static const int _maxRewardedAutoRetries = 8;
  static const int _maxInterstitialAutoRetries = 6;

  RewardedAdManager({
    required PremiumChecker isPremium,
    this.interstitialCooldown = const Duration(minutes: 10),
    this.rewardedCooldown = const Duration(minutes: 5),
    AiUsageStore? aiUsageStore,
  })  : _isPremium = isPremium,
        _aiUsageStore = aiUsageStore;

  final AiUsageStore? _aiUsageStore;
  DateTime? _aiExhaustedAt;
  Future<void>? _aiUsageLoad;

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
  Timer? _interstitialRetryTimer;
  int _interstitialRetryAttempt = 0;
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

  Future<void> _ensureAiUsageLoaded() => _aiUsageLoad ??= () async {
        final AiUsageStore? store = _aiUsageStore;
        if (store == null) return;
        final AiUsageSnapshot? saved = await store.read();
        if (saved == null) return;
        _aiRequestsRemaining = saved.remaining;
        _aiExhaustedAt = saved.exhaustedAt;
        if (_aiRequestsRemaining <= 0) {
          _aiExhaustedAt ??= DateTime.now();
        }
      }();

  void _persistAiUsage() {
    final AiUsageStore? store = _aiUsageStore;
    if (store == null) return;
    unawaited(
      store.write(
        AiUsageSnapshot(
          remaining: _aiRequestsRemaining,
          exhaustedAt: _aiExhaustedAt,
        ),
      ),
    );
  }

  /// Hands out a fresh free batch once the refill interval has passed.
  void _refillIfDue() {
    final DateTime? exhaustedAt = _aiExhaustedAt;
    if (_aiRequestsRemaining > 0 || exhaustedAt == null) return;
    if (DateTime.now().difference(exhaustedAt) <
        AdConfiguration.AI_FREE_REFILL_INTERVAL) {
      return;
    }
    _aiRequestsRemaining = AdConfiguration.FREE_AI_REQUEST_LIMIT;
    _aiExhaustedAt = null;
    _persistAiUsage();
  }

  /// How long until the next free batch, or null when searches are available.
  Duration? get aiRefillRemaining {
    final DateTime? exhaustedAt = _aiExhaustedAt;
    if (_aiRequestsRemaining > 0 || exhaustedAt == null) return null;
    final Duration left = AdConfiguration.AI_FREE_REFILL_INTERVAL -
        DateTime.now().difference(exhaustedAt);
    return left.isNegative ? Duration.zero : left;
  }

  /// Returns whether a new AI request may start. Premium bypasses the free
  /// allowance; free users need an unconsumed slot (a new free batch appears
  /// automatically one hour after the previous one ran out).
  Future<bool> canStartAiRequest() async {
    if (await isPremiumUser()) return true;
    await _ensureAiUsageLoaded();
    _refillIfDue();
    return _aiRequestsRemaining > 0;
  }

  /// Consumes one slot only after the AI provider reports a successful reply.
  void recordSuccessfulAiRequest() {
    if (_aiRequestsRemaining > 0) _aiRequestsRemaining--;
    if (_aiRequestsRemaining <= 0) _aiExhaustedAt ??= DateTime.now();
    _persistAiUsage();
  }

  /// Adds exactly one configured allowance after a completed rewarded ad.
  void grantAiRequestsAfterReward() {
    _aiRequestsRemaining += AdConfiguration.REWARDED_AI_REQUEST_BONUS;
    _aiExhaustedAt = null;
    _persistAiUsage();
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
      final String configuredAppId = kReleaseMode
          ? AdConfiguration.androidProductionAppId
          : AdConfiguration.androidTestAppId;
      AppLogger.i(
        'ADMOB_INIT_START release=$kReleaseMode appId=$configuredAppId',
      );
      final InitializationStatus status =
          await MobileAds.instance.initialize();
      final String adapterDetails = status.adapterStatuses.entries
          .map(
            (entry) => '${entry.key}:state=${entry.value.state},'
                'latency=${entry.value.latency}s,'
                'description=${entry.value.description}',
          )
          .join(' | ');
      _initialized = true;
      AppLogger.i(
        'ADMOB_INIT_SUCCESS release=$kReleaseMode appId=$configuredAppId '
        'adapters=[$adapterDetails] '
        'bannerUnit=${AdConfiguration.bannerId} '
        'interstitialUnit=${AdConfiguration.interstitialId} '
        'rewardedUnit=${AdConfiguration.rewardedId}',
      );
    } on Object catch (error, stackTrace) {
      _initialized = false;
      AppLogger.e(
        'ADMOB_INIT_FAILURE release=$kReleaseMode '
        'errorMessage=$error',
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
      String? responseInfo,
      Object? error,
      StackTrace? stackTrace,
    }) {
      if (failureLogged) return;
      failureLogged = true;
      retryAfterFailure = true;
      AppLogger.w(
        'REWARDED_LOAD_FAILED unit=${AdConfiguration.rewardedId} '
        'code=$code domain=${domain ?? 'unknown'} message=$message '
        'responseInfo=${responseInfo ?? 'unavailable'}',
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
              responseInfo: error.responseInfo?.toString(),
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
      seconds: (5 * (1 << (_rewardedRetryAttempt > 4 ? 4 : _rewardedRetryAttempt)))
          .clamp(5, 60)
          .toInt(),
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
    AppLogger.i(
      'INTERSTITIAL_LOAD_REQUEST unit=${AdConfiguration.interstitialId} '
      'initialized=$_initialized adExists=${_interstitialAd != null} '
      'loading=${_interstitialLoadInFlight != null}',
    );
    if (!_initialized) {
      AppLogger.i('INTERSTITIAL_LOAD_REQUEST skipped reason=sdk_not_initialized');
      return;
    }
    if (_interstitialAd != null) {
      AppLogger.i('INTERSTITIAL_LOAD_REQUEST skipped reason=already_ready');
      return;
    }
    if (_interstitialLoadInFlight != null) {
      AppLogger.i('INTERSTITIAL_LOAD_REQUEST skipped reason=already_loading');
      return;
    }
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
            _interstitialRetryTimer?.cancel();
            _interstitialRetryTimer = null;
            _interstitialRetryAttempt = 0;
            AppLogger.i(
              'INTERSTITIAL_LOAD_SUCCESS unit=${AdConfiguration.interstitialId} '
              'responseInfo=${ad.responseInfo}',
            );
            done.complete();
          },
          onAdFailedToLoad: (LoadAdError error) {
            AppLogger.w(
              'INTERSTITIAL_LOAD_FAILED '
              'unit=${AdConfiguration.interstitialId} '
              'code=${error.code} domain=${error.domain} '
              'message=${error.message} responseInfo=${error.responseInfo}',
            );
            if (!done.isCompleted) done.complete();
            _scheduleInterstitialRetry();
          },
        ),
      );
      await done.future;
    } on Object catch (error, stackTrace) {
      AppLogger.e(
        'INTERSTITIAL_LOAD_FAILED unit=${AdConfiguration.interstitialId} '
        'code=exception message=$error',
        error: error,
        stackTrace: stackTrace,
      );
      if (!done.isCompleted) done.complete();
      _scheduleInterstitialRetry();
    } finally {
      _interstitialLoadInFlight = null;
    }
  }

  /// A failed interstitial load (no fill, flaky network) must not leave the
  /// app without an ad for the rest of the session: retry with backoff so one
  /// is ready by the time the learner presses Back.
  void _scheduleInterstitialRetry() {
    if (_disposed || !_initialized || _interstitialAd != null) return;
    if (_interstitialRetryTimer?.isActive ?? false) return;
    if (_interstitialRetryAttempt >= _maxInterstitialAutoRetries) return;
    final int seconds =
        (10 * (1 << _interstitialRetryAttempt)).clamp(10, 120).toInt();
    _interstitialRetryAttempt++;
    AppLogger.i(
      'INTERSTITIAL_RELOAD_REQUEST reason=load_failure '
      'retry=$_interstitialRetryAttempt delay=${seconds}s',
    );
    _interstitialRetryTimer = Timer(Duration(seconds: seconds), () {
      _interstitialRetryTimer = null;
      if (_disposed || _interstitialAd != null) return;
      unawaited(loadInterstitial());
    });
  }

  /// Shows one return-navigation interstitial when it is already ready.
  /// Returns immediately with false when policy or availability says no ad.
  Future<bool> showReturnInterstitial() async {
    AppLogger.i(
      'INTERSTITIAL_SHOW_REQUEST placement=return_navigation '
      'unit=${AdConfiguration.interstitialId} ready=${_interstitialAd != null} '
      'loading=${_interstitialLoadInFlight != null} initialized=$_initialized',
    );
    if (await isPremiumUser()) {
      AppLogger.i('INTERSTITIAL_SHOW_SKIPPED reason=premium');
      return false;
    }
    if (_showingInterstitial) {
      AppLogger.i('INTERSTITIAL_SHOW_SKIPPED reason=already_showing');
      return false;
    }
    if (_returnInterstitialShownThisSession) {
      AppLogger.i('INTERSTITIAL_SHOW_SKIPPED reason=already_shown_this_session');
      return false;
    }
    final DateTime now = DateTime.now();
    if (_lastInterstitialShown != null &&
        now.difference(_lastInterstitialShown!) < interstitialCooldown) {
      AppLogger.i('INTERSTITIAL_SHOW_SKIPPED reason=cooldown');
      return false;
    }
    final InterstitialAd? ad = _interstitialAd;
    if (ad == null) {
      AppLogger.w(
        'INTERSTITIAL_SHOW_SKIPPED reason=not_ready '
        'unit=${AdConfiguration.interstitialId} '
        'loading=${_interstitialLoadInFlight != null}',
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
      AppLogger.i(
        'INTERSTITIAL_RELOAD_REQUEST unit=${AdConfiguration.interstitialId} '
        'previousShowSucceeded=$shown',
      );
      unawaited(loadInterstitial());
    }

    AppLogger.i(
      'INTERSTITIAL_SHOW_REQUEST reached=true '
      'placement=return_navigation unit=${AdConfiguration.interstitialId} '
      'responseInfo=${ad.responseInfo}',
    );
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdShowedFullScreenContent: (InterstitialAd shownAd) {
        AppLogger.i(
          'INTERSTITIAL_SHOW_SUCCESS placement=return_navigation '
          'unit=${AdConfiguration.interstitialId} '
          'responseInfo=${shownAd.responseInfo}',
        );
      },
      onAdDismissedFullScreenContent: (InterstitialAd dismissedAd) {
        AppLogger.i(
          'INTERSTITIAL_DISMISSED placement=return_navigation '
          'unit=${AdConfiguration.interstitialId} '
          'responseInfo=${dismissedAd.responseInfo}',
        );
        unawaited(dismissedAd.dispose());
        finish(true);
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd failedAd, AdError error) {
        AppLogger.w(
          'INTERSTITIAL_SHOW_FAILED '
          'unit=${AdConfiguration.interstitialId} '
          'code=${error.code} domain=${error.domain} '
          'message=${error.message} responseInfo=${failedAd.responseInfo}',
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
      AppLogger.e(
        'INTERSTITIAL_SHOW_FAILED unit=${AdConfiguration.interstitialId} '
        'code=exception message=$error',
        error: error,
        stackTrace: stackTrace,
      );
      unawaited(ad.dispose());
      _lastInterstitialShown = null;
      _returnInterstitialShownThisSession = false;
      finish(false);
    }
    return result.future;
  }

  /// Explicit AI action used by the limit dialog. The allowance is granted
  /// only after the official rewarded completion callback returns success.
  Future<bool> watchAdForMoreAi() async =>
      (await watchAdForMoreAiResult()) == RewardedAdResult.rewarded;

  /// Same as [watchAdForMoreAi] but reports WHY nothing was granted, so the
  /// UI can tell the learner what happened. Because the learner has just
  /// pressed the button, this waits for the ad to finish loading instead of
  /// failing instantly when it is still being fetched.
  Future<RewardedAdResult> watchAdForMoreAiResult() async {
    final RewardedAdResult result = await showRewarded(
      placement: RewardedAdPlacement.aiAssistant,
      waitForLoad: const Duration(seconds: 20),
    );
    if (result == RewardedAdResult.rewarded) grantAiRequestsAfterReward();
    return result;
  }

  /// Makes sure a rewarded ad is loaded, actively (re)starting the load and
  /// waiting for it up to [timeout]. Unlike the background retry, this resets
  /// the retry back-off, so an ad that failed to load earlier gets a fresh
  /// attempt the moment the learner asks for it.
  Future<bool> ensureRewardedReady(Duration timeout) async {
    if (_rewardedAd != null) return true;
    if (_disposed) return false;
    if (!_initialized) await initialize();
    if (!_initialized) return false;
    final DateTime end = DateTime.now().add(timeout);
    while (_rewardedAd == null && DateTime.now().isBefore(end)) {
      final Future<void>? inFlight = _rewardedLoadInFlight;
      if (inFlight != null) {
        await inFlight.timeout(
          end.difference(DateTime.now()),
          onTimeout: () {},
        );
      } else {
        _rewardedRetryTimer?.cancel();
        _rewardedRetryTimer = null;
        _rewardedRetryAttempt = 0;
        await _loadRewarded(isRetry: false);
      }
      if (_rewardedAd != null) break;
      // Brief pause so a hard "no fill" does not spin the loop.
      await Future<void>.delayed(const Duration(milliseconds: 800));
    }
    return _rewardedAd != null;
  }

  /// Shows a rewarded ad only when the caller has already obtained explicit
  /// user consent (for example, after pressing “Watch Ad for More AI”).
  Future<RewardedAdResult> showRewarded({
    required RewardedAdPlacement placement,
    RewardCallback? onRewarded,
    Duration? waitForLoad,
  }) async {
    AppLogger.i(
      'REWARDED_SHOW_REQUEST placement=$placement readiness=$rewardedReadiness '
      'ready=${_rewardedAd != null} loading=${_rewardedLoadInFlight != null} '
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
    if (_rewardedAd == null && waitForLoad != null) {
      await ensureRewardedReady(waitForLoad);
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
    _interstitialRetryTimer?.cancel();
    _interstitialRetryTimer = null;
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

/// Owns one banner ad for as long as it lives and keeps trying to fill it.
///
/// A single failed load (no fill, offline at launch, SDK still starting) used
/// to leave the banner area empty until the screen was rebuilt. This slot
/// retries with backoff for its whole lifetime, so banners are effectively
/// permanent: as soon as the network/fill is available the ad appears.
class BannerAdSlot extends ChangeNotifier {
  BannerAdSlot({required this.manager, required this.placementName});

  final RewardedAdManager manager;
  final String placementName;

  BannerAd? _ad;
  bool _loaded = false;
  bool _starting = false;
  bool _disposed = false;
  int _attempt = 0;
  Timer? _retryTimer;

  /// The loaded banner, or null while nothing is available to show.
  BannerAd? get ad => _loaded ? _ad : null;

  Future<void> start() async {
    if (_disposed || _starting || _loaded) return;
    _starting = true;
    try {
      await manager.initialize();
      if (_disposed) return;
      if (!manager.isInitialized) {
        _scheduleRetry('sdk_not_initialized');
        return;
      }
      if (await manager.isPremiumUser()) {
        AppLogger.i('BANNER_LOAD_SKIPPED placement=$placementName reason=premium');
        return;
      }
      if (_disposed) return;
      final BannerAd banner = BannerAd(
        adUnitId: AdConfiguration.bannerId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (Ad loaded) {
            AppLogger.i(
              'BANNER_LOAD_SUCCESS placement=$placementName '
              'unit=${AdConfiguration.bannerId}',
            );
            if (_disposed) {
              unawaited(loaded.dispose());
              return;
            }
            _attempt = 0;
            _loaded = true;
            notifyListeners();
          },
          onAdFailedToLoad: (Ad failed, LoadAdError error) {
            AppLogger.w(
              'BANNER_LOAD_FAILED placement=$placementName '
              'unit=${AdConfiguration.bannerId} code=${error.code} '
              'domain=${error.domain} message=${error.message}',
            );
            unawaited(failed.dispose());
            if (identical(_ad, failed)) _ad = null;
            _loaded = false;
            _scheduleRetry('load_failed');
          },
        ),
      );
      _ad = banner;
      AppLogger.i(
        'BANNER_LOAD_REQUEST placement=$placementName '
        'unit=${AdConfiguration.bannerId}',
      );
      await banner.load();
    } on Object catch (error, stackTrace) {
      AppLogger.e(
        'BANNER_LOAD_FAILED placement=$placementName code=exception '
        'message=$error',
        error: error,
        stackTrace: stackTrace,
      );
      final BannerAd? broken = _ad;
      _ad = null;
      _loaded = false;
      if (broken != null) unawaited(broken.dispose());
      _scheduleRetry('exception');
    } finally {
      _starting = false;
    }
  }

  void _scheduleRetry(String reason) {
    if (_disposed || _loaded) return;
    if (_retryTimer?.isActive ?? false) return;
    final int seconds =
        (15 * (1 << (_attempt > 3 ? 3 : _attempt))).clamp(15, 120).toInt();
    _attempt++;
    AppLogger.i(
      'BANNER_RELOAD_REQUEST placement=$placementName reason=$reason '
      'delay=${seconds}s',
    );
    _retryTimer = Timer(Duration(seconds: seconds), () {
      _retryTimer = null;
      unawaited(start());
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    final BannerAd? current = _ad;
    _ad = null;
    _loaded = false;
    if (current != null) unawaited(current.dispose());
    super.dispose();
  }
}

/// Renders a banner slot's ad (320x50) and collapses to nothing while no ad
/// is available, so an unfilled banner never leaves a blank gap.
class BannerAdView extends StatelessWidget {
  const BannerAdView({super.key, required this.ad});

  final BannerAd ad;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      );
}

/// A lifecycle-safe in-page banner (used by the Dictionary). It owns its own
/// [BannerAdSlot], so it keeps retrying until an ad is shown.
class ManagedBannerAd extends StatefulWidget {
  const ManagedBannerAd({
    super.key,
    required this.manager,
    this.placementName = 'unspecified',
  });

  final RewardedAdManager manager;
  final String placementName;