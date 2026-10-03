import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/utils/logger.dart';
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

  // Versioned IDs migrate devices away from the original channels, which may
  // already have been created as silent. The mode suffix is also necessary
  // because Android persists channel audio settings after first creation.
  static const String studyChannelId = 'study_reminders_v3';
  static const String breakChannelId = 'break_reminders_v3';
  static const String wordChannelId = 'word_of_the_day_v3';
  static const int _studyIdBase = 100000;
  static const int _studyOneMinuteIdBase = 150000;
  static const int _studyFollowUpIdBase = 175000;
  static const int _breakIdBase = 200000;
  static const int _implicitBreakIdBase = 225000;
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
  Future<void> _rescheduleTail = Future<void>.value();

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
      AppLogger.i('Notifications timezone initialized: ${tz.local.name}');
    } on Object {
      // Keep the package's default location if the platform does not expose a
      // valid IANA name. Android normally returns one on supported releases.
      AppLogger.w('Could not resolve device timezone; using ${tz.local.name}');
    }

    try {
      await _plugin.initialize(
        settings: InitializationSettings(
          android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          AppLogger.i(
            'Notification callback: id=${response.id}, '
            'action=${response.actionId}, payload=${response.payload}',
          );
          final String? payload = response.payload;
          if (payload == null || payload.isEmpty) return;
          if (response.actionId == 'start_studying') {
            _markTaskStarted(payload);
          }
          final void Function(String payload)? handler = _onTap;
          if (handler != null) {
            handler(payload);
          } else {
            _pendingPayload = payload;
          }
        },
      );
      AppLogger.i('Flutter local notifications plugin initialized');
    } on Object catch (error, stackTrace) {
      AppLogger.e(
        'Flutter local notifications plugin initialization failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
    final NotificationAppLaunchDetails? launch =
        await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      final String? payload = launch?.notificationResponse?.payload;
      if (payload != null &&
          launch?.notificationResponse?.actionId == 'start_studying') {
        _markTaskStarted(payload);
      }
      if (payload != null && payload.isNotEmpty) _pendingPayload = payload;
    }
    _initialized = true;
  }

  void _markTaskStarted(String payload) {
    try {
      final Object? decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        final String? taskId = decoded['taskId'] as String?;
        if (taskId != null && taskId.isNotEmpty) {
          unawaited(_studyHub.setTaskStatus(taskId, TaskStatus.inProgress));
        }
      }
    } on Object {
      // A malformed payload should never prevent the notification tap from
      // opening the planner.
    }
  }

  Future<bool> requestPermission() async {
    await initialize();
    final bool? granted = await _androidPlugin?.requestNotificationsPermission();
    final bool? exactGranted = await _androidPlugin?.requestExactAlarmsPermission();
    final bool? exactAvailable =
        await _androidPlugin?.canScheduleExactNotifications();
    AppLogger.i(
      'Notification permissions: notifications=$granted, '
      'exactAlarmRequest=$exactGranted, exactAlarmAvailable=$exactAvailable',
    );
    final bool enabled = await _isEnabled();
    if (enabled) {
      await rescheduleAll();
    }
    return granted ?? enabled;
  }

  Future<bool> notificationsEnabled() async {
    await initialize();
    final bool enabled = await _isEnabled();
    AppLogger.i('Android notification permission status: enabled=$enabled');
    return enabled;
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
  Future<void> rescheduleAll() {
    final Future<void> next = _rescheduleTail
        .catchError((Object _) {})
        .then((_) => _rescheduleAll());
    _rescheduleTail = next.catchError((Object _) {});
    return next;
  }

  Future<void> _rescheduleAll() async {
    await initialize();
    final bool enabled = await _isEnabled();
    final bool? exact = await _androidPlugin?.canScheduleExactNotifications();
    AppLogger.i(
      'Rescheduling notifications: enabled=$enabled, '
      'exactAlarmAvailable=$exact, timezone=${tz.local.name}',
    );
    if (!enabled) {
      await _cancelManagedNotifications();
      AppLogger.w('Notifications disabled by Android; cancelled all pending notifications');
      return;
    }
    final AppSettings settings = await _settings.getSettings();
    AppLogger.i(
      'Reminder settings: study=${settings.studyRemindersEnabled}, '
      'lead=${settings.studyReminderMinutes}m, '
      'followUp=${settings.followUpReminderEnabled}, '
      'sound=${settings.notificationSound.label}, '
      'soundEnabled=${settings.notificationSoundEnabled}, '
      'vibration=${settings.notificationVibrationEnabled}',
    );
    await _cancelManagedNotifications();

    if (settings.studyRemindersEnabled || settings.breakRemindersEnabled) {
      await _schedulePlanner(settings);
    }
    if (settings.dailyWordEnabled) {
      await _scheduleWordOfDay(settings);
    }
    final List<PendingNotificationRequest> pending =
        await _plugin.pendingNotificationRequests();
    final List<int> pendingIds =
        pending.map((PendingNotificationRequest e) => e.id).toList();
    AppLogger.i(
      'Notification reschedule complete: count=${pending.length}, '
      'ids=${pendingIds.join(',')}, '
      'duplicateIds=${pendingIds.length != pendingIds.toSet().length}',
    );
    final List<AndroidNotificationChannel>? channels =
        await _androidPlugin?.getNotificationChannels();
    if (channels != null) {
      for (final AndroidNotificationChannel channel in channels.where(
        (AndroidNotificationChannel channel) =>
            channel.id.contains(studyChannelId),
      )) {
        AppLogger.i(
          'Android channel state: id=${channel.id}, '
          'playSound=${channel.playSound}, sound=${channel.sound}, '
          'enableVibration=${channel.enableVibration}, '
          'vibrationPattern=${channel.vibrationPattern}',
        );
      }
    }
  }

  Future<void> _schedulePlanner(AppSettings settings) async {
    final String startDay = todayKey();
    final String endDay = dayKey(
      DateTime.now().add(const Duration(days: _lookAheadDays)),
    );
    final List<StudyTask> tasks =
        await _studyHub.watchTasksInRange(startDay, endDay).first;
    final List<StudyTask> scheduledTasks = tasks
        .where((StudyTask task) => task.startMinute != null)
        .toList()
      ..sort((StudyTask a, StudyTask b) {
        final int byDay = a.day.compareTo(b.day);
        if (byDay != 0) return byDay;
        return a.startMinute!.compareTo(b.startMinute!);
      });
    final DateTime now = DateTime.now();
    AppLogger.i(
      'Planner notification scan: tasks=${scheduledTasks.length}, '
      'range=$startDay..$endDay, now=$now',
    );
    for (int index = 0; index < scheduledTasks.length; index++) {
      final StudyTask task = scheduledTasks[index];
      final int? start = task.startMinute;
      if (start == null) {
        AppLogger.d('Skipping task ${task.id}: no start time');
        continue;
      }
      final bool isBreak = task.isBreak;
      final DateTime date = _parseDay(task.day);
      final DateTime startLocal = DateTime(
        date.year,
        date.month,
        date.day,
      ).add(Duration(minutes: start));
      AppLogger.d(
        'Task ${task.id} "${task.displaySubject}": '
        'startLocal=$startLocal, '
        'timezone=${tz.local.name}',
      );
      final Map<String, String> payload = <String, String>{
        'type': isBreak ? 'break' : 'study',
        'taskId': task.id,
        'day': task.day,
        'route': AppRoutes.studyHubDailyFor(task.day, task.id),
      };
      if (isBreak) {
        if (settings.breakRemindersEnabled) {
          await _scheduleBreakReminder(
            id: _stableId(_breakIdBase.toString(), '${task.day}:${task.id}:break'),
            breakStart: startLocal,
            payload: payload,
            settings: settings,
          );
        }
        continue;
      }
      if (!settings.studyRemindersEnabled || task.status != TaskStatus.pending) {
        AppLogger.d(
          'Skipping study reminders for ${task.id}: '
          'enabled=${settings.studyRemindersEnabled}, status=${task.status}',
        );
        continue;
      }
      final int lead = settings.studyReminderMinutes;
      final DateTime leadLocal = startLocal.subtract(Duration(minutes: lead));
      if (lead > 0 && leadLocal.isAfter(now)) {
        await _schedule(
          id: _stableId(_studyIdBase.toString(), '${task.day}:${task.id}:lead'),
          title: 'Study Time Soon',
          body: '${task.displaySubject} starts in $lead minutes.',
          scheduledLocal: leadLocal,
          payload: payload,
          settings: settings,
          sound: NotificationSound.gentle,
          channelId: '${studyChannelId}_pre',
          channelName: 'Study reminders',
        );
      }
      final DateTime oneMinuteLocal =
          startLocal.subtract(const Duration(minutes: 1));
      if (oneMinuteLocal.isAfter(now)) {
        await _schedule(
          id: _stableId(
            _studyOneMinuteIdBase.toString(),
            '${task.day}:${task.id}:oneMinute',
          ),
          title: 'Get Ready',
          body: 'Get ready! ${_taskLabel(task)} starts in 1 minute.',
          scheduledLocal: oneMinuteLocal,
          payload: payload,
          settings: settings,
          sound: settings.notificationSound,
          channelId: '${studyChannelId}_one_minute',
          channelName: 'Study reminders',
          includeStartAction: true,
        );
      }
      if (settings.followUpReminderEnabled) {
        final DateTime followUpLocal = startLocal.add(const Duration(minutes: 5));
        if (followUpLocal.isAfter(now)) {
          await _schedule(
            id: _stableId(
              _studyFollowUpIdBase.toString(),
              '${task.day}:${task.id}:followUp',
            ),
            title: 'Study Follow-up',
            body: "You haven't started ${_taskLabel(task)} yet.",
            scheduledLocal: followUpLocal,
            payload: payload,
            settings: settings,
            sound: NotificationSound.alert,
            channelId: '${studyChannelId}_follow_up',
            channelName: 'Study follow-up reminders',
            includeStartAction: true,
          );
        }
      }
      if (settings.breakRemindersEnabled && task.endMinute != null) {
        final StudyTask? next = _nextTask(scheduledTasks, index, task.day);
        if (next != null &&
            !next.isBreak &&
            next.startMinute != null &&
            next.startMinute! > task.endMinute!) {
          final DateTime breakStart = DateTime(
            date.year,
            date.month,
            date.day,
          ).add(Duration(minutes: task.endMinute!));
          await _scheduleBreakReminder(
            id: _stableId(
              _implicitBreakIdBase.toString(),
              '${task.day}:${task.id}:implicitBreak',
            ),
            breakStart: breakStart,
            payload: <String, String>{
              'type': 'break',
              'taskId': task.id,
              'day': task.day,
              'route': AppRoutes.studyHubDailyFor(task.day, task.id),
            },
            settings: settings,
          );
        }
      }
    }
  }

  Future<void> _cancelManagedNotifications() async {
    final List<PendingNotificationRequest> pending =
        await _plugin.pendingNotificationRequests();
    int cancelled = 0;
    for (final PendingNotificationRequest request in pending) {
      final String? payload = request.payload;
      if (payload == null || payload.isEmpty) continue;
      try {
        final Object? decoded = jsonDecode(payload);
        final Object? type = decoded is Map<String, dynamic>
            ? decoded['type']
            : null;
        if (type == 'study' || type == 'break' || type == 'wordOfDay') {
          await _plugin.cancel(request.id);
          cancelled++;
        }
      } on Object catch (error, stackTrace) {
        AppLogger.w(
          'Could not inspect pending notification id=${request.id}; keeping it',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    AppLogger.i('Cancelled managed local notifications: count=$cancelled');
  }

  StudyTask? _nextTask(
    List<StudyTask> tasks,
    int currentIndex,
    String day,
  ) {
    for (int index = currentIndex + 1; index < tasks.length; index++) {
      final StudyTask candidate = tasks[index];
      if (candidate.day != day) return null;
      return candidate;
    }
    return null;
  }

  Future<void> _scheduleBreakReminder({
    required int id,
    required DateTime breakStart,
    required Map<String, String> payload,
    required AppSettings settings,
  }) async {
    await _schedule(
      id: id,
      title: 'Break Reminder',
      body: 'Take a break now! Your break starts in 1 minute.',
      scheduledLocal: breakStart.subtract(const Duration(minutes: 1)),
      payload: payload,
      settings: settings,
      sound: NotificationSound.gentle,
      channelId: breakChannelId,
      channelName: 'Break reminders',
    );
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledLocal,
    required Map<String, String> payload,
    required AppSettings settings,
    required NotificationSound sound,
    required String channelId,
    required String channelName,
    bool includeStartAction = false,
  }) async {
    final DateTime now = DateTime.now();
    if (!scheduledLocal.isAfter(now)) {
      AppLogger.w(
        'Skipping notification id=$id because scheduled time $scheduledLocal '
        'is not after now $now',
      );
      return;
    }
    final bool exact =
        await _androidPlugin?.canScheduleExactNotifications() ?? true;
    if (!exact) {
      AppLogger.e(
        'Exact alarm permission unavailable; refusing to schedule '
        'time-sensitive notification id=$id at $scheduledLocal',
      );
      return;
    }
    final tz.TZDateTime scheduledTz = _toTz(scheduledLocal);
    AppLogger.i(
      'Scheduling notification: id=$id, title="$title", '
      'local=$scheduledLocal, tz=$scheduledTz (${tz.local.name}), '
        'mode=exactAllowWhileIdle, '
      'sound=${sound.label}/${sound.resourceName}, '
      'soundEnabled=${settings.notificationSoundEnabled}, '
      'vibration=${settings.notificationVibrationEnabled}, '
      'channel=$channelId',
    );
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledTz,
        payload: jsonEncode(payload),
        notificationDetails: NotificationDetails(
          android: _details(
            channelId: channelId,
            channelName: channelName,
            settings: settings,
            sound: sound,
            includeStartAction: includeStartAction,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      AppLogger.i('Scheduled local notification successfully: id=$id');
    } on Object catch (error, stackTrace) {
      AppLogger.e(
        'Failed to schedule local notification id=$id at $scheduledLocal',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  String _taskLabel(StudyTask task) => task.topic == null || task.topic!.isEmpty
      ? task.displaySubject
      : '${task.displaySubject} — ${task.topic}';

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
    NotificationSound? sound,
    bool includeStartAction = false,
  }) {
    final NotificationSound selectedSound = sound ?? settings.notificationSound;
    final String selectedResource = selectedSound.resourceName;
    final String soundMode =
        settings.notificationSoundEnabled ? 'sound' : 'silent';
    final String vibrationMode =
        settings.notificationVibrationEnabled ? 'vibrate' : 'quiet';
    AppLogger.d(
      'Notification channel config: '
      'id=${channelId}_${selectedResource}_${soundMode}_$vibrationMode, '
      'sound=$selectedResource, '
      'playSound=${settings.notificationSoundEnabled}, '
      'enableVibration=${settings.notificationVibrationEnabled}, '
      'pattern=[0,180]',
    );
    return AndroidNotificationDetails(
      '${channelId}_${selectedResource}_${soundMode}_$vibrationMode',
      channelName,
      channelDescription: 'Sapiora learning reminders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: settings.notificationSoundEnabled,
      sound: settings.notificationSoundEnabled
          ? RawResourceAndroidNotificationSound(selectedResource)
          : null,
      enableVibration: settings.notificationVibrationEnabled,
      vibrationPattern: settings.notificationVibrationEnabled
          ? Int64List.fromList(<int>[0, 180])
          : null,
      actions: includeStartAction
          ? <AndroidNotificationAction>[
              const AndroidNotificationAction(
                'start_studying',
                'Start Studying',
                showsUserInterface: true,
              ),
            ]
          : null,
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
