import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lexiora/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String testRewardedId = 'ca-app-pub-3940256099942544/5224354917';
  static const String productionRewardedId =
      'ca-app-pub-4342811933559577/5768607000';
  static const bool diagnosticTestAds = bool.fromEnvironment(
    'SAPIORA_DIAGNOSTIC_TEST_ADS',
    defaultValue: false,
  );
  static const int rewardedQuizMilestone = 5;

  static bool isRewardedQuizMilestone(int quizNumber) =>
      quizNumber > 1 && (quizNumber - 1) % rewardedQuizMilestone == 0;

  /// Central AI usage configuration; change these values without changing the
  /// AI Assistant flow or rewarded-ad implementation.
  static const int FREE_AI_REQUEST_LIMIT = 7;
  static const int REWARDED_AI_REQUEST_BONUS = 7;

  static String get bannerId =>
      diagnosticTestAds || !kReleaseMode ? testBannerId : productionBannerId;
  static String get interstitialId => diagnosticTestAds || !kReleaseMode
      ? testInterstitialId
      : productionInterstitialId;
  static String get rewardedId => diagnosticTestAds || !kReleaseMode
      ? testRewardedId
      : productionRewardedId;
}

enum RewardedAdPlacement { grammarQuiz, quiz, aiAssistant }

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
  final Map<String, DateTime> _lastRewardedShown = <String, DateTime>{};
  final Map<String, int> _mainQuizCompletionsBySubject = <String, int>{};
  int _grammarQuizCompletions = 0;
  final Map<String, Set<int>> _mainQuizUnlocksBySubject =
      <String, Set<int>>{};
  final Set<int> _grammarQuizUnlocks = <int>{};
  Future<void>? _quizProgressLoad;
  SharedPreferences? _quizProgressPrefs;
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
      AppLogger.e(
        'AdMob initialization failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> loadRewarded() async {
    if (!_initialized || _rewardedAd != null || _rewardedLoadInFlight != null)
      return;
    AppLogger.i(
      'ADS_DIAGNOSTIC rewarded load started '
      '(unit=${AdConfiguration.rewardedId}, '
      'testMode=${AdConfiguration.diagnosticTestAds})',
    );
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
            AppLogger.i(
              'ADS_DIAGNOSTIC rewarded load success '
              '(objectNonNull=${_rewardedAd != null}, '
              'responseInfo=${ad.responseInfo})',
            );
            done.complete();
          },
          onAdFailedToLoad: (LoadAdError error) {
            AppLogger.w(
              'ADS_DIAGNOSTIC rewarded load failure '
              '(code=${error.code}, message=${error.message}, '
              'domain=${error.domain}, responseInfo=${error.responseInfo})',
            );
            done.complete();
          },
        ),
      );
      await done.future;
    } on Object catch (error, stackTrace) {
      AppLogger.e(
        'Rewarded ad load failed unexpectedly',
        error: error,
        stackTrace: stackTrace,
      );
      if (!done.isCompleted) done.complete();
    } finally {
      _rewardedLoadInFlight = null;
    }
  }

  Future<void> loadInterstitial() async {
    if (!_initialized ||
        _interstitialAd != null ||
        _interstitialLoadInFlight != null)
      return;
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
      AppLogger.e(
        'Interstitial ad load failed unexpectedly',
        error: error,
        stackTrace: stackTrace,
      );
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
        _returnInterstitialShownThisSession)
      return false;
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
      onAdFailedToShowFullScreenContent:
          (InterstitialAd failedAd, AdError error) {
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
      AppLogger.e(
        'Interstitial ad show failed unexpectedly',
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
  Future<bool> watchAdForMoreAi() async {
    final RewardedAdResult result = await showRewarded(
      placement: RewardedAdPlacement.aiAssistant,
    );
    if (result != RewardedAdResult.rewarded) return false;
    grantAiRequestsAfterReward();
    return true;
  }

  /// Attempts to unlock exactly one milestone quiz. The unlock is persisted
  /// only after [showRewarded] reports the official earned-reward callback.
  Future<bool> watchAdToUnlockQuiz({
    required RewardedAdPlacement placement,
    required int quizNumber,
    String? mainQuizSubjectId,
  }) async {
    if (placement == RewardedAdPlacement.quiz && mainQuizSubjectId == null) {
      AppLogger.w('Main Quiz rewarded unlock rejected without a subject ID');
      return false;
    }
    final RewardedAdResult result = await showRewarded(
      placement: placement,
      cooldownKey: mainQuizSubjectId,
    );
    if (result != RewardedAdResult.rewarded) return false;
    if (placement == RewardedAdPlacement.grammarQuiz) {
      await unlockGrammarQuiz(quizNumber);
    } else if (placement == RewardedAdPlacement.quiz) {
      await unlockMainQuiz(
        mainQuizSubjectId!,
        quizNumber,
      );
    } else {
      return false;
    }
    return true;
  }

  /// Shows a rewarded ad only when the caller has already obtained explicit
  /// user consent (for example, after pressing “Watch Ad for More AI”).
  Future<RewardedAdResult> showRewarded({
    required RewardedAdPlacement placement,
    RewardCallback? onRewarded,
    String? cooldownKey,
  }) async {
    if (await isPremiumUser()) return RewardedAdResult.premium;
    if (_showingRewarded) return RewardedAdResult.unavailable;
    final String rewardKey = _rewardedCooldownKey(placement, cooldownKey);
    final DateTime? lastShown = _lastRewardedShown[rewardKey];
    if (lastShown != null &&
        DateTime.now().difference(lastShown) < rewardedCooldown) {
      return RewardedAdResult.cooldown;
    }
    if (!_initialized) await initialize();
    final RewardedAd? ad = _rewardedAd;
    if (ad == null) {
      AppLogger.w(
        'ADS_DIAGNOSTIC rewarded show blocked: ad object is null '
        '(unit=${AdConfiguration.rewardedId})',
      );
      unawaited(loadRewarded());
      return RewardedAdResult.unavailable;
    }

    _rewardedAd = null;
    _showingRewarded = true;
    _lastRewardedShown[rewardKey] = DateTime.now();
    AppLogger.i(
      'ADS_DIAGNOSTIC rewarded show called '
      '(placement=$placement, responseInfo=${ad.responseInfo})',
    );
    final Completer<RewardedAdResult> result = Completer<RewardedAdResult>();
    bool rewarded = false;
    bool completed = false;

    void finish(RewardedAdResult value) {
      if (completed) return;
      completed = true;
      _showingRewarded = false;
      if (value == RewardedAdResult.failed) _lastRewardedShown.remove(rewardKey);
      if (!result.isCompleted) result.complete(value);
      unawaited(loadRewarded());
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (RewardedAd dismissedAd) {
        AppLogger.i(
          'ADS_DIAGNOSTIC rewarded ad closed '
          '(earned=$rewarded, responseInfo=${dismissedAd.responseInfo})',
        );
        unawaited(dismissedAd.dispose());
        finish(
          rewarded
              ? RewardedAdResult.rewarded
              : RewardedAdResult.dismissedWithoutReward,
        );
      },
      onAdFailedToShowFullScreenContent: (RewardedAd failedAd, AdError error) {
        AppLogger.w(
          'ADS_DIAGNOSTIC rewarded ad failed to show '
          '(code=${error.code}, message=${error.message}, '
          'domain=${error.domain}, responseInfo=${failedAd.responseInfo})',
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
            'ADS_DIAGNOSTIC earned reward callback '
            '(amount=${reward.amount}, type=${reward.type})',
          );
          if (onRewarded != null) {
            unawaited(Future<void>(() async => onRewarded()));
          }
        },
      );
    } on Object catch (error, stackTrace) {
      AppLogger.e(
        'Rewarded ad show failed unexpectedly',
        error: error,
        stackTrace: stackTrace,
      );
      unawaited(ad.dispose());
      AppLogger.w(
        'ADS_DIAGNOSTIC rewarded object disposed after show exception',
      );
      finish(RewardedAdResult.failed);
    }
    return result.future;
  }

  String _rewardedCooldownKey(
    RewardedAdPlacement placement,
    String? cooldownKey,
  ) =>
      '$placement:${cooldownKey ?? ''}';

  /// Returns true on every fifth completed main-Quiz session in this app run.
  Future<void> _ensureQuizProgressLoaded() async {
    if (_quizProgressPrefs != null) return;
    final Future<void>? existing = _quizProgressLoad;
    if (existing != null) {
      await existing;
      return;
    }
    final Future<void> load = () async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _quizProgressPrefs = prefs;
      _mainQuizCompletionsBySubject
        ..clear()
        ..addAll(_readMainCompletions(prefs));
      _grammarQuizCompletions =
        prefs.getInt('quiz_grammar_completed_count') ?? 0;
      _mainQuizUnlocksBySubject
        ..clear()
        ..addAll(_readMainUnlocks(prefs));
      _grammarQuizUnlocks
        ..clear()
        ..addAll(_readUnlocks(prefs, 'quiz_grammar_unlock_'));
    }();
    _quizProgressLoad = load;
    await load;
  }

  Set<int> _readUnlocks(SharedPreferences prefs, String prefix) => prefs
      .getKeys()
      .where((String key) => key.startsWith(prefix))
      .map((String key) => int.tryParse(key.substring(prefix.length)))
      .whereType<int>()
      .toSet();

  Map<String, int> _readMainCompletions(SharedPreferences prefs) {
    const String prefix = 'quiz_main_completed_count_';
    return <String, int>{
      for (final String key in prefs.getKeys())
        if (key.startsWith(prefix))
          key.substring(prefix.length): prefs.getInt(key) ?? 0,
    };
  }

  Map<String, Set<int>> _readMainUnlocks(SharedPreferences prefs) {
    const String prefix = 'quiz_main_unlock_';
    final Map<String, Set<int>> result = <String, Set<int>>{};
    for (final String key in prefs.getKeys()) {
      if (!key.startsWith(prefix)) continue;
      final String encoded = key.substring(prefix.length);
      final int separator = encoded.lastIndexOf('_');
      if (separator <= 0) continue;
      final String subjectId = encoded.substring(0, separator);
      final int? quizNumber = int.tryParse(encoded.substring(separator + 1));
      if (quizNumber == null) continue;
      result.putIfAbsent(subjectId, () => <int>{}).add(quizNumber);
    }
    return result;
  }

  int _mainCompletionsFor(String subjectId) =>
      _mainQuizCompletionsBySubject[subjectId] ?? 0;

  Set<int> _mainUnlocksFor(String subjectId) =>
      _mainQuizUnlocksBySubject.putIfAbsent(subjectId, () => <int>{});

  bool _requiresUnlock(int completed, Set<int> unlocks, int quizNumber) =>
      AdConfiguration.isRewardedQuizMilestone(quizNumber) &&
      completed >= quizNumber - 1 &&
      !unlocks.contains(quizNumber);

  Future<bool> requiresMainQuizUnlock(
    String subjectId,
    int quizNumber,
  ) async {
    await _ensureQuizProgressLoaded();
    if (await isPremiumUser()) return false;
    return _requiresUnlock(
      _mainCompletionsFor(subjectId),
      _mainUnlocksFor(subjectId),
      quizNumber,
    );
  }

  Future<bool> requiresGrammarQuizUnlock(int quizNumber) async {
    await _ensureQuizProgressLoaded();
    if (await isPremiumUser()) return false;
    return _requiresUnlock(
      _grammarQuizCompletions,
      _grammarQuizUnlocks,
      quizNumber,
    );
  }

  Future<bool> hasMainQuizUnlock(String subjectId, int quizNumber) async {
    await _ensureQuizProgressLoaded();
    return await isPremiumUser() ||
        _mainUnlocksFor(subjectId).contains(quizNumber);
  }

  Future<bool> hasGrammarQuizUnlock(int quizNumber) async {
    await _ensureQuizProgressLoaded();
    return await isPremiumUser() || _grammarQuizUnlocks.contains(quizNumber);
  }

  Future<int?> pendingMainQuizUnlock(String subjectId) async {
    await _ensureQuizProgressLoaded();
    final int completions = _mainCompletionsFor(subjectId);
    final Set<int> unlocks = _mainUnlocksFor(subjectId);
    if (completions == 0 ||
        completions % AdConfiguration.rewardedQuizMilestone != 0 ||
        unlocks.contains(completions + 1) ||
        await isPremiumUser())
      return null;
    return completions + 1;
  }

  Future<int?> pendingGrammarQuizUnlock() async {
    await _ensureQuizProgressLoaded();
    if (_grammarQuizCompletions == 0 ||
        _grammarQuizCompletions % AdConfiguration.rewardedQuizMilestone != 0 ||
        _grammarQuizUnlocks.contains(_grammarQuizCompletions + 1) ||
        await isPremiumUser())
      return null;
    return _grammarQuizCompletions + 1;
  }

  Future<void> unlockMainQuiz(String subjectId, int quizNumber) async {
    await _ensureQuizProgressLoaded();
    _mainUnlocksFor(subjectId).add(quizNumber);
    await _quizProgressPrefs!.setBool(
      'quiz_main_unlock_${subjectId}_$quizNumber',
      true,
    );
  }

  Future<void> unlockGrammarQuiz(int quizNumber) async {
    await _ensureQuizProgressLoaded();
    _grammarQuizUnlocks.add(quizNumber);
    await _quizProgressPrefs!.setBool('quiz_grammar_unlock_$quizNumber', true);
  }

  /// Persists one completed main quiz. The next gate is checked on quiz tap.
  Future<void> recordMainQuizCompletion(String subjectId) async {
    await _ensureQuizProgressLoaded();
    final int completions = _mainCompletionsFor(subjectId) + 1;
    _mainQuizCompletionsBySubject[subjectId] = completions;
    await _quizProgressPrefs!.setInt(
      'quiz_main_completed_count_$subjectId',
      completions,
    );
  }

  /// Persists one completed grammar quiz. The next gate is checked on quiz tap.
  Future<void> recordGrammarQuizCompletion() async {
    await _ensureQuizProgressLoaded();
    _grammarQuizCompletions++;
    await _quizProgressPrefs!.setInt(
      'quiz_grammar_completed_count',
      _grammarQuizCompletions,
    );
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
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    AppLogger.i(
      'ADS_DIAGNOSTIC banner load started '
      '(unit=${AdConfiguration.bannerId}, '
      'testMode=${AdConfiguration.diagnosticTestAds})',
    );
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
          _retryTimer?.cancel();
          AppLogger.i(
            'ADS_DIAGNOSTIC banner load success '
            '(responseInfo=${(ad as BannerAd).responseInfo})',
          );
          setState(() {
            _ad = ad;
            _loaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          AppLogger.w(
            'ADS_DIAGNOSTIC banner load failure '
            '(unit=${AdConfiguration.bannerId}, code=${error.code}, '
            'message=${error.message}, domain=${error.domain}, '
            'responseInfo=${error.responseInfo})',
          );
          _ad = null;
          _loaded = false;
          unawaited(ad.dispose());
          _scheduleRetry();
        },
      ),
    );
    _ad = ad;
    try {
      await ad.load();
    } on Object catch (error, stackTrace) {
      AppLogger.e(
        'Banner ad load failed unexpectedly',
        error: error,
        stackTrace: stackTrace,
      );
      unawaited(ad.dispose());
      _ad = null;
      _loaded = false;
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (!mounted) return;
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) unawaited(_load());
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    final BannerAd? ad = _ad;
    if (ad != null) {
      AppLogger.i('ADS_DIAGNOSTIC banner object disposed');
      unawaited(ad.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    AppLogger.i(
      'ADS_DIAGNOSTIC banner mounted/rendered '
      '(width=${_ad!.size.width}, height=${_ad!.size.height})',
    );
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
