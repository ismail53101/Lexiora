import 'package:equatable/equatable.dart';

/// Priority of a study session.
enum TaskPriority {
  low,
  medium,
  high;

  static TaskPriority fromIndex(int? i) =>
      (i == null || i < 0 || i >= TaskPriority.values.length)
          ? TaskPriority.medium
          : TaskPriority.values[i];

  String get label => switch (this) {
        TaskPriority.low => 'Low',
        TaskPriority.medium => 'Medium',
        TaskPriority.high => 'High',
      };
}

/// Lifecycle status of a study session.
enum TaskStatus {
  pending,
  inProgress,
  completed;

  static TaskStatus fromIndex(int? i) =>
      (i == null || i < 0 || i >= TaskStatus.values.length)
          ? TaskStatus.pending
          : TaskStatus.values[i];

  String get label => switch (this) {
        TaskStatus.pending => 'Pending',
        TaskStatus.inProgress => 'In progress',
        TaskStatus.completed => 'Completed',
      };
}

/// Whether a planner entry is a study session or a (user-inserted) break.
enum SessionKind {
  session,
  breakTime;

  static SessionKind fromKey(String? k) =>
      k == 'break' ? SessionKind.breakTime : SessionKind.session;

  String get key => this == SessionKind.breakTime ? 'break' : 'session';
}

/// A planner entry for a given [day] (`YYYY-MM-DD`): a study session or a break.
///
/// Everything is user-defined — [subject], [topic] and (for breaks) the [title]
/// are free text. Backward-compatible with pre-v0.7.1 rows: old rows have only
/// [title]/[subject], which still render via [displaySubject]; [completed]
/// derives from [status].
class StudyTask extends Equatable {
  const StudyTask({
    required this.id,
    required this.day,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.subject,
    this.topic,
    this.notes,
    this.startMinute,
    this.endMinute,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.kind = SessionKind.session,
    this.durationMinutes,
    this.autoScheduled = false,
    this.orderIndex = 0,
    this.completedAt,
  });

  final String id;
  final String day;
  final String title;
  final String? subject;
  final String? topic;
  final String? notes;
  final int? startMinute;
  final int? endMinute;
  final TaskPriority priority;
  final TaskStatus status;
  final SessionKind kind;
  final int? durationMinutes;
  /// Whether the planner may move this row when an earlier automatic item changes.
  final bool autoScheduled;
  final int orderIndex;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  bool get completed => status == TaskStatus.completed;
  bool get isBreak => kind == SessionKind.breakTime;

  /// The subject headline, tolerant of pre-v0.7.1 rows (which used [title]).
  String get displaySubject =>
      (subject != null && subject!.isNotEmpty) ? subject! : title;

  StudyTask copyWith({
    String? title,
    String? subject,
    String? topic,
    String? notes,
    int? startMinute,
    int? endMinute,
    TaskPriority? priority,
    TaskStatus? status,
    SessionKind? kind,
    int? durationMinutes,
    bool? autoScheduled,
    int? orderIndex,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearSubject = false,
    bool clearTopic = false,
    bool clearNotes = false,
    bool clearTimes = false,
  }) {
    return StudyTask(
      id: id,
      day: day,
      title: title ?? this.title,
      subject: clearSubject ? null : (subject ?? this.subject),
      topic: clearTopic ? null : (topic ?? this.topic),
      notes: clearNotes ? null : (notes ?? this.notes),
      startMinute: clearTimes ? null : (startMinute ?? this.startMinute),
      endMinute: clearTimes ? null : (endMinute ?? this.endMinute),
      priority: priority ?? this.priority,
      status: status ?? this.status,
      kind: kind ?? this.kind,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      autoScheduled: autoScheduled ?? this.autoScheduled,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        day,
        title,
        subject,
        topic,
        notes,
        startMinute,
        endMinute,
        priority,
        status,
        kind,
        durationMinutes,
        autoScheduled,
        orderIndex,
        createdAt,
        updatedAt,
        completedAt,
      ];
}
