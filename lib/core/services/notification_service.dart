import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/features/home/domain/services/word_of_day_service.dart';
import 'package:lexiora/features/settings/domain/entities/app_settings.dart';
import 'package:lexiora/features/settings/domain/repositories/settings_repository.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_task.dart';
import 'package:lexiora/modules/study_hub/domain/repositories/study_hub_repository.dart';
import 'package:lexiora/modules/study_hub/domain/study_dates.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// A local, reusable notification coordinator for planner reminders and
/// vocabulary learning. It owns only notification scheduling; the planner's
/// existing persistence and automatic scheduling remain the source of truth.
class NotificationService {
  NotificationService(this._settings, this._studyHub);

  static const String studyChannelId = 'study_reminders';
  static const String wordChannelId = 'word_of_the_day';
  static const int _studyIdBase = 100000;
  static const int _breakIdBase = 200000;
  static const int _wordIdBase = 300000;
  static const int _lookAheadDays = 45;

  final SettingsRepository _settings;
  final StudyHubRepository _studyHub;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void>? _initialization;
  void Function(String payload)? _onTap;
  String? _pendingPayload;
  bool _initialized = false;

  bool get initialized => _initialized;
  String? takePendingPayload() {
    final String? payload = _pendingPayload;
    _pendingPayload = null;
    return payload;
  }

  Future<void> initialize({void Function(String payload)? onTap}) {
    _onTap = onTap ?? _onTap;
    final Future<void>? current = _initialization;
    if (current != null) return current;
    final Future<void> run = _initialize();
    _initialization = run;
    return run;
  }

  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    try {
      final TimezoneInfo local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } on Object {
      // Keep the package's default location if the platform does not expose a
      // valid IANA name. Android normally returns one on supported releases.
    }

    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final String? payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        final void Function(String payload)? handler = _onTap;
        if (handler != null) {
          handler(payload);
        } else {
          _pendingPayload = payload;
        }
      },
    );
    final NotificationAppLaunchDetails? launch =
        await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      final String? payload = launch?.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) _pendingPayload = payload;
    }
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    final bool? granted = await _androidPlugin?.requestNotificationsPermission();
    return granted ?? await _isEnabled();
  }

  Future<bool> notificationsEnabled() async {
    await initialize();
    return _isEnabled();
  }

  Future<bool> _isEnabled() async =>
      await _androidPlugin?.areNotificationsEnabled() ?? true;

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  Future<void> openNotificationSettings() async {
    await initialize();
    await _androidPlugin?.openAppNotificationSettings();
  }

  /// Reschedules the complete notification set from persisted settings and
  /// persisted planner rows. Cancelling our set first makes this idempotent
  /// after restart, edits, deletes, and preference changes.
  Future<void> rescheduleAll() async {
    await initialize();
    final bool enabled = await _isEnabled();
    if (!enabled) {
      await _plugin.cancelAll();
      return;
    }
    final AppSettings settings = await _settings.getSettings();
    await _plugin.cancelAll();

    if (settings.studyRemindersEnabled || settings.breakRemindersEnabled) {
      await _schedulePlanner(settings);
    }
    if (settings.dailyWordEnabled) {
      await _scheduleWordOfDay(settings);
    }
  }

  Future<void> _schedulePlanner(AppSettings settings) async {
    final String startDay = todayKey();
    final String endDay = dayKey(
      DateTime.now().add(const Duration(days: _lookAheadDays)),
    );
    final List<StudyTask> tasks =
        await _studyHub.watchTasksInRange(startDay, endDay).first;
    final DateTime now = DateTime.now();
    for (final StudyTask task in tasks) {
      final int? start = task.startMinute;
      if (start == null || task.endMinute == null) continue;
      final bool isBreak = task.isBreak;
      if (isBreak && !settings.breakRemindersEnabled) continue;
      if (!isBreak && !settings.studyRemindersEnabled) continue;

      final int lead = isBreak ? 0 : settings.studyReminderMinutes;
      final DateTime date = _parseDay(task.day);
      final DateTime scheduledLocal = DateTime(
        date.year,
        date.month,
        date.day,
      ).add(Duration(minutes: start - lead));
      if (!scheduledLocal.isAfter(now)) continue;

      final int id = _stableId(
        (isBreak ? _breakIdBase : _studyIdBase).toString(),
        task.id,
      );
      final String title = isBreak ? 'Break Reminder' : 'Study Reminder';
      final String body = isBreak
          ? '${task.title} starts now.'
          : '${task.displaySubject} starts in $lead minutes.';
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: _toTz(scheduledLocal),
        payload: jsonEncode(<String, String>{
          'type': isBreak ? 'break' : 'study',
          'taskId': task.id,
          'day': task.day,
          'route': AppRoutes.studyHubDailyFor(task.day, task.id),
        }),
        notificationDetails: NotificationDetails(
          android: _details(
            channelId: studyChannelId,
            channelName: 'Study Planner',
            settings: settings,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> _scheduleWordOfDay(AppSettings settings) async {
    final DateTime now = DateTime.now();
    final DateTime firstDay = DateTime(now.year, now.month, now.day);
    final List<String> retainedRecords = <String>[];
    for (int offset = 0; offset < _lookAheadDays; offset++) {
      final DateTime date = firstDay.add(Duration(days: offset));
      final String day = dayKey(date);
      final Map<String, dynamic>? entry =
          await WordOfDayService.forDate(date);
      if (entry == null) continue;
      final String? word = (entry['word'] as String?)?.trim();
      if (word == null || word.isEmpty) continue;
      retainedRecords.add('$day|$word');

      final DateTime localDate = DateTime(
        date.year,
        date.month,
        date.day,
        settings.dailyWordHour,
        settings.dailyWordMinute,
      );
      if (!localDate.isAfter(now)) continue;
      final List<dynamic> urduMeanings =
          (entry['urduMeanings'] as List<dynamic>?) ?? const <dynamic>[];
      final String urdu = urduMeanings.isNotEmpty
          ? urduMeanings.first.toString()
          : 'See the vocabulary detail for the full meaning.';
      final String definition =
          (entry['englishDefinition'] as String?)?.trim() ?? '';
      await _plugin.zonedSchedule(
        id: _wordIdBase + offset,
        title: 'Word of the Day — $word',
        body: 'Meaning: $urdu\n$definition',
        scheduledDate: _toTz(localDate),
        payload: jsonEncode(<String, String>{
          'type': 'wordOfDay',
          'word': word,
          'route': AppRoutes.dictionaryWord(word),
        }),
        notificationDetails: NotificationDetails(
          android: _details(
            channelId: wordChannelId,
            channelName: 'Word of the Day',
            settings: settings,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    await _settings.updateSettings(
      settings.copyWith(dailyWordHistory: retainedRecords),
    );
  }

  AndroidNotificationDetails _details({
    required String channelId,
    required String channelName,
    required AppSettings settings,
  }) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Sapiora learning reminders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: settings.notificationSoundEnabled,
      enableVibration: settings.notificationVibrationEnabled,
    );
  }

  tz.TZDateTime _toTz(DateTime local) => tz.TZDateTime(
        tz.local,
        local.year,
        local.month,
        local.day,
        local.hour,
        local.minute,
      );

  DateTime _parseDay(String value) {
    final List<String> parts = value.split('-');
    if (parts.length != 3) return DateTime.now();
    return DateTime(
      int.tryParse(parts[0]) ?? DateTime.now().year,
      int.tryParse(parts[1]) ?? DateTime.now().month,
      int.tryParse(parts[2]) ?? DateTime.now().day,
    );
  }

  int _stableId(String prefix, String value) {
    int hash = 17;
    for (final int codeUnit in '$prefix:$value'.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash;
  }
}
