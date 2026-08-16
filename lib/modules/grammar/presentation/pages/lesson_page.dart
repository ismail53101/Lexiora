import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/core/widgets/error_view.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_lesson.dart';
import 'package:lexiora/modules/grammar/domain/usecases/grammar_usecases.dart';
import 'package:lexiora/modules/grammar/presentation/providers/grammar_providers.dart';
import 'package:lexiora/modules/grammar/presentation/widgets/grammar_section_card.dart';
import 'package:lexiora/modules/grammar/presentation/widgets/practice_question_card.dart';

/// A single dedicated grammar lesson (a tree leaf): Introduction, Urdu & English
/// explanation, Types, Rules, Structure, Examples (with Urdu translation),
/// Common Mistakes, Exam Tips, Practice, Quiz and Summary. Empty sections are
/// hidden, so lessons only show the parts they actually provide.
class LessonPage extends ConsumerStatefulWidget {
  const LessonPage({super.key, required this.lessonId});

  final String lessonId;

  @override
  ConsumerState<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends ConsumerState<LessonPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(markLessonViewedProvider).call(widget.lessonId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<GrammarLesson?> lessonAsync =
        ref.watch(grammarLeafProvider(widget.lessonId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lessonAsync.maybeWhen(
            data: (GrammarLesson? l) => l?.title ?? 'Lesson',
            orElse: () => 'Lesson',
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: <Widget>[
          lessonAsync.maybeWhen(
            data: (GrammarLesson? l) => l == null
                ? const SizedBox.shrink()
                : _FavoriteAction(lessonId: l.id, title: l.title),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: lessonAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => ErrorView(
          title: 'Could not open lesson',
          message: 'Something went wrong loading this lesson.',
          onRetry: () => ref.invalidate(grammarLeafProvider(widget.lessonId)),
        ),
        data: (GrammarLesson? lesson) => lesson == null
            ? const EmptyState(
                icon: Icons.search_off,
                title: 'Lesson not found',
                message: 'This grammar lesson is not available offline.',
              )
            : _LessonView(lesson: lesson),
      ),
      bottomNavigationBar: lessonAsync.maybeWhen(
        data: (GrammarLesson? l) =>
            l == null ? null : _CompleteBar(lessonId: l.id),
        orElse: () => null,
      ),
    );
  }
}

class _FavoriteAction extends ConsumerWidget {
  const _FavoriteAction({required this.lessonId, required this.title});
  final String lessonId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isFavorite = ref
        .watch(isLeafFavoriteProvider(lessonId))
        .maybeWhen(data: (bool v) => v, orElse: () => false);
    return IconButton(
      icon: Icon(isFavorite ? Icons.star : Icons.star_border,
          color: isFavorite ? Colors.amber : null),
      tooltip: isFavorite ? 'Remove from favorites' : 'Save to favorites',
      onPressed: () => ref.read(toggleLessonFavoriteProvider).call(
            FavoriteParams(leafId: lessonId, title: title),
          ),
    );
  }
}

class _CompleteBar extends ConsumerWidget {
  const _CompleteBar({required this.lessonId});
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GrammarProgressStatus status = ref
        .watch(leafStatusProvider(lessonId))
        .maybeWhen(
          data: (GrammarProgressStatus s) => s,
          orElse: () => GrammarProgressStatus.notStarted,
        );
    final bool completed = status == GrammarProgressStatus.completed;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: completed
          ? OutlinedButton.icon(
              onPressed: () => ref.read(setLessonCompletedProvider).call(
                    SetCompletedParams(lessonId, completed: false),
                  ),
              icon: const Icon(Icons.check_circle),
              label: const Text('Completed — mark as unread'),
            )
          : FilledButton.icon(
              onPressed: () => ref.read(setLessonCompletedProvider).call(
                    SetCompletedParams(lessonId, completed: true),
                  ),
              icon: const Icon(Icons.done_all),
              label: const Text('Mark as complete'),
            ),
    );
  }
}

class _LessonView extends StatelessWidget {
  const _LessonView({required this.lesson});

  final GrammarLesson lesson;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (lesson.id == 'pos/noun' || lesson.id == 'pos/pronoun' || lesson.id == 'pos/verb') {
      return _NounLandingView(lesson: lesson);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        Text(lesson.title,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),

        if (lesson.introduction.isNotEmpty)
          GrammarSectionCard(
            icon: Icons.info_outline,
            title: 'Introduction',
            child: Text(lesson.introduction,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
          ),

        if (lesson.urduExplanation.isNotEmpty)
          GrammarSectionCard(
            icon: Icons.translate,
            title: 'Urdu Explanation',
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                lesson.urduExplanation,
                textAlign: TextAlign.right,
                style: theme.textTheme.titleMedium?.copyWith(height: 1.7),
              ),
            ),
          ),

        if (lesson.englishExplanation.isNotEmpty)
          GrammarSectionCard(
            icon: Icons.menu_book_outlined,
            title: 'English Explanation',
            child: Text(lesson.englishExplanation,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
          ),

        if (lesson.types.isNotEmpty) ...<Widget>[
          GrammarSectionCard(
            icon: Icons.account_tree_outlined,
            title: 'Types of Noun',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final GrammarType type in lesson.types)
                  Chip(label: Text(type.name)),
              ],
            ),
          ),
          for (final GrammarType type in lesson.types)
            GrammarSectionCard(
              icon: Icons.account_tree_outlined,
              title: type.name,
              child: GrammarTypeContent(type: type),
            ),
        ],

        if (lesson.rules.isNotEmpty)
          GrammarSectionCard(
            icon: Icons.rule,
            title: 'Rules',
            child: Column(
              children: <Widget>[
                for (final String r in lesson.rules) GrammarBullet(text: r),
              ],
            ),
          ),

        if (lesson.structure.isNotEmpty)
          GrammarSectionCard(
            icon: Icons.architecture,
            title: 'Structure',
            child: Column(
              children: <Widget>[
                for (final String s in lesson.structure) GrammarBullet(text: s),
              ],
            ),
          ),

        if (lesson.examples.isNotEmpty)
          GrammarSectionCard(
            icon: Icons.format_quote,
            title: 'Examples',
            child: Column(
              children: <Widget>[
                for (final GrammarExample e in lesson.examples)
                  _ExampleItem(example: e),
              ],
            ),
          ),

        if (lesson.commonMistakes.isNotEmpty)
          GrammarSectionCard(
            icon: Icons.report_gmailerrorred_outlined,
            title: 'Common Mistakes',
            accent: theme.colorScheme.error,
            child: Column(
              children: <Widget>[
                for (final GrammarMistake m in lesson.commonMistakes)
                  _MistakeItem(mistake: m),
              ],
            ),
          ),

        if (lesson.examTips.isNotEmpty)
          GrammarSectionCard(
            icon: Icons.tips_and_updates_outlined,
            title: 'Exam Tips',
            accent: theme.colorScheme.tertiary,
            child: Column(
              children: <Widget>[
                for (final String t in lesson.examTips) GrammarBullet(text: t),
              ],
            ),
          ),

        if (lesson.practice.isNotEmpty)
          GrammarSectionCard(
            icon: Icons.edit_note,
            title: 'Practice',
            child: Column(
              children: <Widget>[
                for (int i = 0; i < lesson.practice.length; i++)
                  PracticeQuestionCard(
                      question: lesson.practice[i], index: i + 1),
              ],
            ),
          ),

        if (lesson.quiz.isNotEmpty)
          GrammarSectionCard(
            icon: Icons.quiz_outlined,
            title: 'Quiz',
            child: Column(
              children: <Widget>[
                for (int i = 0; i < lesson.quiz.length; i++)
                  PracticeQuestionCard(question: lesson.quiz[i], index: i + 1),
              ],
            ),
          ),

        if (lesson.summary.isNotEmpty)
          GrammarSectionCard(
            icon: Icons.lightbulb_outline,
            title: 'Summary',
            accent: theme.colorScheme.tertiary,
            child: Text(lesson.summary,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
          ),
      ],
    );
  }
}

class _NounLandingView extends StatelessWidget {
  const _NounLandingView({required this.lesson});

  final GrammarLesson lesson;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GrammarExample? overviewExample =
        lesson.examples.isEmpty ? null : lesson.examples.first;
    const List<Color> accents = <Color>[
      Color(0xFF35B85A),
      Color(0xFF287BE8),
      Color(0xFF8749D6),
      Color(0xFFF28A18),
      Color(0xFFFFB20F),
      Color(0xFF16A6A0),
      Color(0xFFE83D82),
      Color(0xFF139BD2),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        GrammarSectionCard(
          icon: Icons.description_outlined,
          title: lesson.title,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (lesson.introduction.isNotEmpty)
                Text(lesson.introduction,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.35)),
              if (lesson.urduExplanation.isNotEmpty) ...<Widget>[
                const Divider(height: 24),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    lesson.urduExplanation,
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
                  ),
                ),
              ],
              if (overviewExample != null) ...<Widget>[
                const Divider(height: 24),
                Text('Example',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    )),
                const SizedBox(height: 6),
                Text(overviewExample.text,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.35)),
                if (overviewExample.urdu?.isNotEmpty ?? false) ...<Widget>[
                  const SizedBox(height: 5),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      overviewExample.urdu!,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        for (int index = 0; index < lesson.types.length; index++)
          _NounTypeRow(
            type: lesson.types[index],
            number: index + 1,
            accent: accents[index % accents.length],
            lessonId: lesson.id,
          ),
      ],
    );
  }
}

class _NounTypeRow extends StatelessWidget {
  const _NounTypeRow({
    required this.type,
    required this.number,
    required this.accent,
    required this.lessonId,
  });

  final GrammarType type;
  final int number;
  final Color accent;
  final String lessonId;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.grammarType(lessonId, type.name)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 22,
                backgroundColor: accent,
                child: const Icon(Icons.folder_open_outlined,
                    color: Colors.white, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$number. ${type.name}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class GrammarTypeContent extends StatelessWidget {
  const GrammarTypeContent({required this.type});
  final GrammarType type;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (!type.hasDetailedContent) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(type.name,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            if (type.description.isNotEmpty)
              Text(type.description,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
          if (type.description.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(type.description,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),
          ],
          if (type.urduExplanation.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                type.urduExplanation,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
              ),
            ),
          ],
          if (type.exampleWords.isNotEmpty) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text.rich(
                TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                  children: <InlineSpan>[
                    const TextSpan(text: 'E.g.: ', style: TextStyle(fontWeight: FontWeight.w800)),
                    TextSpan(text: type.exampleWords),
                  ],
                ),
              ),
            ),
          ],
          if (type.pronounTable.isNotEmpty) ...<Widget>[
            const _TypeSubheading(title: 'Personal Pronoun Forms', icon: Icons.table_chart_outlined),
            _PronounTable(rows: type.pronounTable),
          ],
          if (type.tableRows.isNotEmpty) ...<Widget>[
            _TypeSubheading(title: type.tableTitle.isEmpty ? 'Verb Forms' : type.tableTitle, icon: Icons.table_chart_outlined),
            _GrammarTable(columns: type.tableColumns, rows: type.tableRows),
          ],
          if (type.rules.isNotEmpty) ...<Widget>[
            const _TypeSubheading(title: 'Rules', icon: Icons.rule),
            for (int i = 0; i < type.rules.length; i++)
              _RuleItem(
                rule: type.rules[i],
                example: i < type.ruleExamples.length ? type.ruleExamples[i] : null,
              ),
          ],
          if (type.subjectVerbAgreement.isNotEmpty) ...<Widget>[
            _AgreementCard(text: type.subjectVerbAgreement),
            if (type.subjectVerbAgreementUrdu.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  type.subjectVerbAgreementUrdu,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
              ),
            ],
          ],
          if (type.examples.isNotEmpty) ...<Widget>[
            const _TypeSubheading(title: 'Examples', icon: Icons.format_quote),
            for (final GrammarExample example in type.examples)
              _ExampleItem(example: example),
          ],
          if (type.commonMistakes.isNotEmpty) ...<Widget>[
            _TypeSubheading(
              title: 'Common Mistakes',
              icon: Icons.report_gmailerrorred_outlined,
              color: theme.colorScheme.error,
            ),
            for (final GrammarMistake mistake in type.commonMistakes)
              _MistakeItem(mistake: mistake),
          ],
          if (type.practice.isNotEmpty) ...<Widget>[
            const _TypeSubheading(title: 'Practice', icon: Icons.edit_note),
            for (int i = 0; i < type.practice.length; i++)
              PracticeQuestionCard(
                question: type.practice[i],
                index: i + 1,
              ),
          ],
        ],
    );
  }
}

class _GrammarTable extends StatelessWidget {
  const _GrammarTable({required this.columns, required this.rows});
  final List<String> columns;
  final List<GrammarTableRow> rows;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final List<String> safeColumns = columns.isEmpty ? List<String>.generate(rows.first.cells.length, (int i) => 'Column ${i + 1}') : columns;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(10),
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll<Color>(scheme.primary.withValues(alpha: 0.12)),
          dataRowMinHeight: 44,
          dataRowMaxHeight: 86,
          columnSpacing: 18,
          columns: safeColumns.map((String column) => DataColumn(label: Text(column, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)))).toList(),
          rows: rows.map((GrammarTableRow row) => DataRow(cells: List<DataCell>.generate(safeColumns.length, (int i) => DataCell(Text(i < row.cells.length ? row.cells[i] : '', style: theme.textTheme.bodySmall?.copyWith(height: 1.3)))))).toList(),
        ),
      ),
    );
  }
}

class _AgreementCard extends StatelessWidget {
  const _AgreementCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = theme.colorScheme.tertiary;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(children: <Widget>[
            Icon(Icons.rule, size: 19, color: accent),
            const SizedBox(width: 7),
            Text('Subject–Verb Agreement', style: theme.textTheme.titleSmall?.copyWith(color: accent, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 9),
          Text(text, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),
        ],
      ),
    );
  }
}

class _PronounTable extends StatelessWidget {
  const _PronounTable({required this.rows});
  final List<GrammarPronounRow> rows;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Table(
      border: TableBorder.all(color: theme.colorScheme.outlineVariant),
      columnWidths: const <int, TableColumnWidth>{
        0: FlexColumnWidth(1.45),
        1: FlexColumnWidth(0.8),
        2: FlexColumnWidth(0.8),
      },
      children: <TableRow>[
        TableRow(
          decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.10)),
          children: <Widget>[
            _tableCell(theme, 'Person', bold: true),
            _tableCell(theme, 'Subject', bold: true),
            _tableCell(theme, 'Object', bold: true),
          ],
        ),
        for (final GrammarPronounRow row in rows)
          TableRow(children: <Widget>[
            _tableCell(theme, row.person),
            _tableCell(theme, row.subject),
            _tableCell(theme, row.object),
          ]),
      ],
    );
  }

  Widget _tableCell(ThemeData theme, String text, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Text(text, style: theme.textTheme.bodySmall?.copyWith(fontWeight: bold ? FontWeight.w700 : null)),
      );
}

class _TypeSubheading extends StatelessWidget {
  const _TypeSubheading({required this.title, required this.icon, this.color});

  final String title;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color tint = color ?? theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 19, color: tint),
          const SizedBox(width: 7),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: tint,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

List<TextSpan> _boldMarkedSpans(String text) {
  final List<String> parts = text.split('**');
  return <TextSpan>[
    for (int i = 0; i < parts.length; i++)
      TextSpan(
        text: parts[i],
        style: i.isOdd ? const TextStyle(fontWeight: FontWeight.w800) : null,
      ),
  ];
}

class _RuleItem extends StatelessWidget {
  const _RuleItem({required this.rule, this.example});
  final String rule;
  final String? example;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<TextSpan> spans = _boldMarkedSpans(rule);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('• ', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text.rich(TextSpan(style: theme.textTheme.bodyMedium?.copyWith(height: 1.4), children: spans)),
                if (example != null && example!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 3),
                  Text.rich(
                  TextSpan(
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontStyle: FontStyle.italic),
                    children: <InlineSpan>[
                      const TextSpan(text: 'Example: '),
                      ..._boldMarkedSpans(example!),
                    ],
                  ),
                ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleItem extends StatelessWidget {
  const _ExampleItem({required this.example});
  final GrammarExample example;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (example.referenceText != null && example.referenceText!.isNotEmpty) ...<Widget>[
            Text('Noun reference', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(example.referenceText!, style: theme.textTheme.bodyMedium?.copyWith(height: 1.35, color: theme.colorScheme.onSurfaceVariant)),
            if (example.referenceUrdu != null && example.referenceUrdu!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(example.referenceUrdu!, textAlign: TextAlign.right, style: theme.textTheme.bodySmall?.copyWith(height: 1.45, color: theme.colorScheme.onSurfaceVariant)),
              ),
            ],
            const Divider(height: 18),
          ],
          Text(example.text,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.4)),
          if (example.urdu != null && example.urdu!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                example.urdu!,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.6, color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
          if (example.note != null && example.note!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(example.note!,
                style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}

class _MistakeItem extends StatelessWidget {
  const _MistakeItem({required this.mistake});
  final GrammarMistake mistake;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    const Color right = Color(0xFF2E7D32);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (mistake.wrong.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.close, size: 18, color: scheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(mistake.wrong,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.error,
                          decoration: TextDecoration.lineThrough)),
                ),
              ],
            ),
          if (mistake.right.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.check, size: 18, color: right),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(mistake.right,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: right, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
          if (mistake.urdu != null && mistake.urdu!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  mistake.urdu!,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
          if (mistake.note != null && mistake.note!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(mistake.note!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ),
          ],
        ],
      ),
    );
  }
}
