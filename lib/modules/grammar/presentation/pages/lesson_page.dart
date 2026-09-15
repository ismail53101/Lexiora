import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/core/widgets/error_view.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_lesson.dart';
import 'package:lexiora/modules/grammar/domain/usecases/grammar_usecases.dart';
import 'package:lexiora/modules/grammar/presentation/providers/grammar_providers.dart';
import 'package:lexiora/modules/grammar/presentation/widgets/grammar_section_card.dart';
import 'package:lexiora/modules/grammar/presentation/widgets/grammar_voice_colors.dart';
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

class _BilingualText extends StatelessWidget {
  const _BilingualText({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<InlineSpan> spans = <InlineSpan>[];
    final RegExp latin = RegExp(r'[A-Za-z][A-Za-z0-9+\-]*(?:[&/][A-Za-z0-9+\-]+)*');
    int cursor = 0;
    for (final RegExpMatch match in latin.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: style.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ));
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text.rich(
        TextSpan(style: style, children: spans),
        textAlign: TextAlign.right,
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
    final bool isPhraseLesson = lesson.id.startsWith('phrases/');
    final bool isConditionalLesson =
        lesson.id.startsWith('conditional-sentences/');
    final bool isPhraseOrClauseLesson = isPhraseLesson ||
        lesson.id.startsWith('clauses/') ||
        isConditionalLesson;
    if (lesson.id == 'pos/quiz') {
      return _AllInOneQuizView(lesson: lesson);
    }
    if (lesson.id == 'pos/noun' ||
        lesson.id == 'pos/pronoun' ||
        lesson.id == 'pos/verb' ||
        lesson.id == 'pos/adjective' ||
        lesson.id == 'pos/adverb' ||
        lesson.id == 'pos/preposition' ||
        lesson.id == 'pos/conjunction' ||
        lesson.id == 'pos/interjection' ||
        lesson.id == 'pos/determiner') {
      return _NounLandingView(lesson: lesson);
    }
    // Numbered vertical rules layout (General Rules of Conversion).
    if (lesson.rulesConversion != null && lesson.rulesConversion!.isNotEmpty) {
      return _RulesConversionView(
        lessonId: lesson.id,
        title: lesson.title,
        data: lesson.rulesConversion!,
      );
    }
    // Numbered tense-section layout (Structure → Main Rule → Examples).
    if (lesson.tenseSections != null && lesson.tenseSections!.isNotEmpty) {
      return _TenseSectionsView(
        lessonId: lesson.id,
        title: lesson.title,
        data: lesson.tenseSections!,
      );
    }
    // Two-column voice comparison layout (Active vs Passive Voice).
    if (lesson.voiceComparison != null && lesson.voiceComparison!.isNotEmpty) {
      return _VoiceComparisonView(
        lessonId: lesson.id,
        title: lesson.title,
        data: lesson.voiceComparison!,
      );
    }
    // Structure-only lessons (content arrives in a later pass) show a friendly
    // placeholder instead of an empty page.
    final bool hasNoContent = lesson.providedMaterial.isEmpty &&
        lesson.introduction.isEmpty &&
        lesson.urduExplanation.isEmpty &&
        lesson.englishExplanation.isEmpty &&
        lesson.types.isEmpty &&
        lesson.additionalTypes.isEmpty &&
        lesson.degreeTypes.isEmpty &&
        lesson.rules.isEmpty &&
        lesson.structure.isEmpty &&
        lesson.examples.isEmpty &&
        lesson.commonMistakes.isEmpty &&
        lesson.examTips.isEmpty &&
        lesson.practice.isEmpty &&
        lesson.quiz.isEmpty &&
        lesson.summary.isEmpty &&
        lesson.tableRows.isEmpty;
    if (hasNoContent) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          Text(lesson.title,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 48),
          const EmptyState(
            icon: Icons.menu_book_outlined,
            title: 'Content coming soon',
            message: 'Lesson material for this section will be added soon.',
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        Text(lesson.title,
            style: lesson.id.startsWith('tenses/')
                ? theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)
                : (isPhraseLesson
                    ? theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)
                    : theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800))),
        const SizedBox(height: 14),

        if (lesson.providedMaterial.isNotEmpty)
            GrammarSectionCard(
            icon: Icons.article_outlined,
            title: '',
            showHeader: false,
            child: TenseRichText(
              text: lesson.providedMaterial,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
              bilingual: isPhraseOrClauseLesson,
            ),
          ),

        if (lesson.introduction.isNotEmpty)
          GrammarSectionCard(
            icon: Icons.info_outline,
            title: 'Introduction',
            child: lesson.id.startsWith('tenses/')
                ? TenseRichText(
                    text: lesson.introduction,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                  )
                : Text(
                    lesson.introduction,
                    style: (isPhraseLesson
                            ? theme.textTheme.bodyMedium
                            : theme.textTheme.bodyLarge)
                        ?.copyWith(height: isPhraseLesson ? 1.4 : 1.5),
                  ),
          ),

        if (lesson.urduExplanation.isNotEmpty)
          GrammarSectionCard(
            icon: Icons.translate,
            title: 'Urdu Explanation',
            child: _BilingualText(
              text: lesson.urduExplanation,
              style: ((lesson.id.startsWith('tenses/')
                          ? theme.textTheme.bodyMedium
                          : (isPhraseLesson
                              ? theme.textTheme.bodyMedium
                              : theme.textTheme.titleMedium)) ??
                      const TextStyle())
                  .copyWith(height: lesson.id.startsWith('tenses/')
                      ? 1.4
                      : (isPhraseLesson ? 1.55 : 1.7)),
            ),
          ),

        if (lesson.englishExplanation.isNotEmpty)
          GrammarSectionCard(
            icon: Icons.menu_book_outlined,
            title: 'English Explanation',
            child: lesson.id.startsWith('tenses/')
                ? TenseRichText(
                    text: lesson.englishExplanation,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                  )
                : Text(
                    lesson.englishExplanation,
                    style: (isPhraseLesson
                            ? theme.textTheme.bodyMedium
                            : theme.textTheme.bodyLarge)
                        ?.copyWith(height: isPhraseLesson ? 1.4 : 1.5),
                  ),
          ),

        if (lesson.types.isNotEmpty) ...<Widget>[
          GrammarSectionCard(
            icon: Icons.account_tree_outlined,
            title: lesson.id == 'pos/adjective'
                ? 'Kinds of Adjective'
                : 'Types of Noun',
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

        if (lesson.structure.isNotEmpty)
          GrammarSectionCard(
            icon: Icons.architecture,
            title: 'Structure / Formula',
            child: Column(
              children: <Widget>[
                for (final String s in lesson.structure)
                  GrammarBullet(
                    text: s,
                    compact: lesson.id.startsWith('tenses/') || isPhraseOrClauseLesson,
                  ),
              ],
            ),
          ),

        if (lesson.rules.isNotEmpty)
          GrammarSectionCard(
            icon: Icons.rule,
            title: 'Rules',
            child: Column(
              children: <Widget>[
                for (final String r in lesson.rules)
                  GrammarBullet(
                    text: r,
                    compact: lesson.id.startsWith('tenses/') || isPhraseOrClauseLesson,
                  ),
              ],
            ),
          ),

        if (lesson.tableRows.isNotEmpty)
          GrammarSectionCard(
            icon: Icons.table_chart_outlined,
            title: lesson.tableTitle.isEmpty ? 'Comparison Table' : lesson.tableTitle,
            child: _GrammarTable(
              columns: lesson.tableColumns,
              rows: lesson.tableRows,
              compact: lesson.id.startsWith('tenses/') || isPhraseOrClauseLesson,
            ),
          ),
        if (lesson.examples.isNotEmpty)
          GrammarSectionCard(
            icon: Icons.format_quote,
            title: 'Examples',
            child: Column(
              children: <Widget>[
                for (final GrammarExample e in lesson.examples)
                  _ExampleItem(
                    example: e,
                    compact: lesson.id.startsWith('tenses/') || isPhraseOrClauseLesson,
                  ),
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
                  _MistakeItem(
                    mistake: m,
                    compact: lesson.id.startsWith('tenses/') || isPhraseOrClauseLesson,
                  ),
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
                for (final String t in lesson.examTips)
                  GrammarBullet(
                    text: t,
                    compact: lesson.id.startsWith('tenses/') || isPhraseOrClauseLesson,
                  ),
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
                style: (lesson.id.startsWith('tenses/')
                        ? theme.textTheme.bodySmall
                        : theme.textTheme.bodyLarge)
                    ?.copyWith(height: lesson.id.startsWith('tenses/') ? 1.3 : 1.5)),
          ),
      ],
    );
  }
}

/// Numbered vertical rules layout for "General Rules of Conversion".
/// Matches the reference image: heading, purple circular markers 1–7,
/// bold white rule headings, blue example sentences, and a compact formula
/// table at the bottom. Single-column vertical flow — no boxes, no slides.
class _RulesConversionView extends StatelessWidget {
  const _RulesConversionView({
    required this.lessonId,
    required this.title,
    required this.data,
  });

  final String lessonId;
  final String title;
  final Map<String, dynamic> data;

  // Reference-image palette (matches the two-column voice layout).
  static const Color _purple = Color(0xFFAB47BC);
  static const Color _markerPurple = Color(0xFF7E57C2);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextStyle bodyStyle =
        theme.textTheme.bodySmall?.copyWith(height: 1.4, color: scheme.onSurface) ??
            const TextStyle();

    final String heading = (data['heading'] as String?) ?? title;
    final List<dynamic> rules = (data['rules'] as List<dynamic>?) ?? [];
    final Map<String, dynamic>? formula = data['formula'] as Map<String, dynamic>?;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: <Widget>[
        // ── Section heading (e.g. "2. General Rules of Conversion") ────
        Text(
          heading,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 14),

        // ── Numbered rules, vertical flow ───────────────────────────────
        for (final dynamic r in rules)
          _ConversionRule(
            rule: r as Map<String, dynamic>,
            index: rules.indexOf(r) + 1,
            bodyStyle: bodyStyle,
          ),

        // ── General Formula (compact table) ─────────────────────────────
        if (formula != null) ...<Widget>[
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Icon(Icons.calculate_outlined, size: 20, color: _purple),
              const SizedBox(width: 8),
              Text(
                (formula['title'] as String?) ?? 'General Formula',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: _purple,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _FormulaTable(
            rows: (formula['rows'] as List<dynamic>? ?? [])
                .whereType<Map<String, dynamic>>()
                .toList(growable: false),
            bodyStyle: bodyStyle,
            borderColor: scheme.outlineVariant.withValues(alpha: 0.45),
            headerFill: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
          ),
        ],
      ],
    );
  }
}

/// One numbered rule: purple circle marker + bold heading + body lines.
class _ConversionRule extends StatelessWidget {
  const _ConversionRule({
    required this.rule,
    required this.index,
    required this.bodyStyle,
  });

  final Map<String, dynamic> rule;
  final int index;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String heading = (rule['heading'] as String?) ?? '';
    final List<dynamic> lines = (rule['lines'] as List<dynamic>?) ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Numbered purple circular marker.
          Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(top: 1),
            decoration: const BoxDecoration(
              color: _RulesConversionView._markerPurple,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Bold white rule heading.
                if (heading.isNotEmpty)
                  Text(
                    heading,
                    style: bodyStyle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                if (heading.isNotEmpty) const SizedBox(height: 4),
                // Body lines (active/passive pairs, lists, arrow rows).
                for (final dynamic ln in lines)
                  _ConversionRuleLine(line: ln as Map<String, dynamic>, bodyStyle: bodyStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single line inside a numbered rule.
/// Types: label-pair (Active:/Passive:), arrow (write → written),
/// bullet, plain, and arrow-note (sentence → note).
class _ConversionRuleLine extends StatelessWidget {
  const _ConversionRuleLine({required this.line, required this.bodyStyle});

  final Map<String, dynamic> line;
  final TextStyle bodyStyle;

  static const Color _purple = _RulesConversionView._purple;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextStyle labelStyle = bodyStyle.copyWith(color: scheme.onSurfaceVariant);
    final String type = (line['type'] as String?) ?? 'plain';

    switch (type) {
      // "Active:" / "Passive:" labeled pair — voice-colored sentence after
      // gray label (blue for Active, theme-aware green for Passive).
      case 'pair':
        final String labelText = (line['label'] as String?) ?? '';
        final bool passivePair = labelText.toLowerCase().contains('passive');
        return Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 68,
                child: Text(
                  labelText,
                  style: labelStyle,
                ),
              ),
              Expanded(
                child: Text(
                  (line['text'] as String?) ?? '',
                  style: bodyStyle.copyWith(
                    color: passivePair
                        ? passiveVoiceColor(context)
                        : activeVoiceColor(context),
                  ),
                ),
              ),
            ],
          ),
        );

      // "write → written" transformation rows.
      case 'arrow':
        final String from = (line['from'] as String?) ?? '';
        final String to = (line['to'] as String?) ?? '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 64,
                child: Text(from, style: bodyStyle),
              ),
              Icon(Icons.arrow_forward, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(child: Text(to, style: bodyStyle)),
            ],
          ),
        );

      // Simple bullet item.
      case 'bullet':
        return Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(top: 7, right: 10),
                decoration: BoxDecoration(
                  color: _purple,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  (line['text'] as String?) ?? '',
                  style: bodyStyle,
                ),
              ),
            ],
          ),
        );

      // Supporting plain sentence (e.g. "Transitive verbs have an object.").
      case 'plain':
        return Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text((line['text'] as String?) ?? '', style: bodyStyle),
        );

      // "He plays cricket. → Passive is possible." (active sentence → blue)
      case 'arrow-note':
        return Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 128,
                child: Text(
                  (line['text'] as String?) ?? '',
                  style: bodyStyle.copyWith(color: activeVoiceColor(context)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(Icons.arrow_forward,
                    size: 14, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  (line['note'] as String?) ?? '',
                  style: bodyStyle,
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

/// Compact two-column formula table (Voice | Formula).
class _FormulaTable extends StatelessWidget {
  const _FormulaTable({
    required this.rows,
    required this.bodyStyle,
    required this.borderColor,
    required this.headerFill,
  });

  final List<Map<String, dynamic>> rows;
  final TextStyle bodyStyle;
  final Color borderColor;
  final Color headerFill;

  static const Color _purple = _RulesConversionView._purple;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) Divider(height: 1, color: borderColor),
            Container(
              color: headerFill,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 96,
                    child: Text(
                      (rows[i]['voice'] as String?) ?? '',
                      style: bodyStyle.copyWith(
                        color: _purple,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      (rows[i]['formula'] as String?) ?? '',
                      style: bodyStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VoiceComparisonView extends StatelessWidget {
  const _VoiceComparisonView({
    required this.lessonId,
    required this.title,
    required this.data,
  });

  final String lessonId;
  final String title;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextStyle bodyStyle =
        theme.textTheme.bodySmall?.copyWith(height: 1.4, color: scheme.onSurface) ??
            const TextStyle();
    final TextStyle urduStyle = bodyStyle.copyWith(height: 1.65);

    final String intro = (data['intro'] as String?) ?? '';
    final List<dynamic> columns = (data['columns'] as List<dynamic>?) ?? [];
    final Map<String, dynamic>? bottom =
        data['bottom'] as Map<String, dynamic>?;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        // ── Intro ──────────────────────────────────────────────────────
        if (intro.isNotEmpty) ...<Widget>[
          _VoiceLabel(
            label: title,
            icon: Icons.info_outline,
            color: const Color(0xFF42A5F5),
          ),
          const SizedBox(height: 6),
          Text(intro, style: bodyStyle),
          const SizedBox(height: 18),
        ],

        // ── Two-column comparison ──────────────────────────────────────
        if (columns.length >= 2) ...<Widget>[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _VoiceColumn(
                    column: columns[0] as Map<String, dynamic>,
                    bodyStyle: bodyStyle,
                    urduStyle: urduStyle,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: VerticalDivider(
                    width: 1,
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                Expanded(
                  child: _VoiceColumn(
                    column: columns[1] as Map<String, dynamic>,
                    bodyStyle: bodyStyle,
                    urduStyle: urduStyle,
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── Bottom section (Easy Way to Remember) ──────────────────────
        if (bottom != null) ...<Widget>[
          const SizedBox(height: 20),
          _VoiceLabel(
            label: (bottom['title'] as String?) ?? '',
            icon: Icons.lightbulb_outline,
            color: scheme.tertiary,
          ),
          const SizedBox(height: 8),
          for (final dynamic b
              in (bottom['blocks'] as List<dynamic>?) ?? [])
            _VoiceBlockWidget(
              block: b as Map<String, dynamic>,
              bodyStyle: bodyStyle,
              urduStyle: urduStyle,
              fullWidth: true,
            ),
        ],
      ],
    );
  }
}

/// Purple section label with icon (e.g. "Introduction to Voice", "Easy Way to Remember").
class _VoiceLabel extends StatelessWidget {
  const _VoiceLabel({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

/// A single column inside the two-column comparison (Passive or Active Voice).
class _VoiceColumn extends StatelessWidget {
  const _VoiceColumn({
    required this.column,
    required this.bodyStyle,
    required this.urduStyle,
  });

  final Map<String, dynamic> column;
  final TextStyle bodyStyle;
  final TextStyle urduStyle;

  @override
  Widget build(BuildContext context) {
    final String title = (column['title'] as String?) ?? '';
    final List<dynamic> blocks = (column['blocks'] as List<dynamic>?) ?? [];
    final bool isPassive = title.toLowerCase().contains('passive');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Column title stays purple (headings are always purple).
        _VoiceLabel(
          label: title,
          icon: isPassive ? Icons.link : Icons.volume_up,
          color: const Color(0xFFAB47BC),
        ),
        const SizedBox(height: 8),
        for (final dynamic b in blocks)
          _VoiceBlockWidget(
            block: b as Map<String, dynamic>,
            bodyStyle: bodyStyle,
            urduStyle: urduStyle,
            fullWidth: false,
            voiceColor: isPassive ? passiveVoiceColor(context) : null,
          ),
      ],
    );
  }
}

/// Renders a single content block inside a voice comparison column.
class _VoiceBlockWidget extends StatelessWidget {
  const _VoiceBlockWidget({
    required this.block,
    required this.bodyStyle,
    required this.urduStyle,
    required this.fullWidth,
    this.voiceColor,
  });

  final Map<String, dynamic> block;
  final TextStyle bodyStyle;
  final TextStyle urduStyle;
  final bool fullWidth;

  /// Optional fixed sentence color for this block's example sentences
  /// (green inside the Passive Voice column, blue inside Active).
  final Color? voiceColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String type = (block['type'] as String?) ?? 'text';
    final Color sentenceColor = voiceColor ?? activeVoiceColor(context);

    switch (type) {
      case 'text':
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text.rich(
            TextSpan(
              style: bodyStyle,
              children: _boldMarkedSpans(
                (block['text'] as String?) ?? '',
                // Passive sentences render green, standalone Active example
                // sentences blue; ordinary text keeps its style.
                color: _voiceTextColor(context, (block['text'] as String?) ?? ''),
              ),
            ),
          ),
        );

      case 'urdu':
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              (block['text'] as String?) ?? '',
              textAlign: TextAlign.right,
              style: urduStyle,
            ),
          ),
        );

      case 'example':
        final String label = (block['label'] as String?) ?? 'Example';
        final String text = (block['text'] as String?) ?? '';
        final String exampleUrdu = (block['urdu'] as String?) ?? '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // "Example" label with quote icon
              Row(
                children: <Widget>[
                  Icon(Icons.format_quote,
                      size: 16, color: const Color(0xFF42A5F5)),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: bodyStyle.copyWith(
                      color: const Color(0xFF42A5F5),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Colored example sentence
              Text.rich(
                TextSpan(
                  style: bodyStyle.copyWith(height: 1.35),
                  children: _boldMarkedSpans(
                    text,
                    color: sentenceColor,
                  ),
                ),
              ),
              if (exampleUrdu.isNotEmpty) ...<Widget>[
                const SizedBox(height: 3),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    exampleUrdu,
                    textAlign: TextAlign.right,
                    style: urduStyle.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );

      case 'breakdown':
        final String label = (block['label'] as String?) ?? 'Here:';
        final List<dynamic> rows = (block['rows'] as List<dynamic>?) ?? [];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: bodyStyle.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              for (final dynamic row in rows)
                _VoiceBreakdownRow(
                  cells: (row as List<dynamic>).map((e) => e.toString()).toList(),
                  bodyStyle: bodyStyle,
                ),
            ],
          ),
        );

      case 'bullets':
        final String label =
            (block['label'] as String?) ?? '';
        final List<dynamic> items =
            (block['items'] as List<dynamic>?) ?? [];
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (label.isNotEmpty) ...<Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.format_quote,
                        size: 16, color: const Color(0xFF42A5F5)),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: bodyStyle.copyWith(
                        color: const Color(0xFF42A5F5),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              for (final dynamic item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 5, right: 6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: sentenceColor,
                        ),
                      ),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: bodyStyle.copyWith(height: 1.35),
                            children: _boldMarkedSpans(
                              item.toString(),
                              color: sentenceColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

/// Renders a single row of the breakdown table (e.g. "A letter = subject").
class _VoiceBreakdownRow extends StatelessWidget {
  const _VoiceBreakdownRow({
    required this.cells,
    required this.bodyStyle,
  });

  final List<String> cells;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty) return const SizedBox.shrink();
    // Layout: [label] = [description]
    final String left = cells.length >= 1 ? cells[0] : '';
    final String right = cells.length >= 3 ? cells[2] : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: <Widget>[
          // Left cell (colored label)
          Expanded(
            flex: 2,
            child: Text.rich(
              TextSpan(
                style: bodyStyle.copyWith(height: 1.3),
                children: _boldMarkedSpans(
                  left,
                  color: const Color(0xFFCE93D8),
                ),
              ),
            ),
          ),
          // Equals sign
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('=', style: bodyStyle.copyWith(height: 1.3)),
          ),
          // Right cell (description)
          Expanded(
            flex: 3,
            child: Text(
              right,
              style: bodyStyle.copyWith(height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

/// Numbered tense-section layout for the Active & Passive Voice tense
/// lessons (e.g. Present Simple): "1 Structure" with proper tables,
/// "2 Main Rule" with bilingual bullets, "3 Examples" with a two-column
/// Active/Passive table. Matches the reference screenshot exactly.
class _TenseSectionsView extends StatelessWidget {
  const _TenseSectionsView({
    required this.lessonId,
    required this.title,
    required this.data,
  });

  final String lessonId;
  final String title;
  final Map<String, dynamic> data;

  // Reference-image palette (shared with the other APV views).
  static const Color _purple = Color(0xFFAB47BC);
  static const Color _markerPurple = Color(0xFF7E57C2);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextStyle bodyStyle =
        theme.textTheme.bodySmall?.copyWith(height: 1.4, color: scheme.onSurface) ??
            const TextStyle();

    final String heading = (data['heading'] as String?) ?? title;
    final List<dynamic> sections = (data['sections'] as List<dynamic>?) ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: <Widget>[
        // ── Page heading (e.g. "3. Present Simple") ─────────────────────
        Text.rich(
          TextSpan(
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
            children: _boldMarkedSpans(
              heading,
              color: scheme.onSurface,
              highlightColor: highlightYellowColor(context),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Numbered sections, vertical flow ────────────────────────────
        for (final dynamic s in sections)
          _TenseSection(
            section: s as Map<String, dynamic>,
            bodyStyle: bodyStyle,
            purple: _purple,
            markerPurple: _markerPurple,
          ),
      ],
    );
  }
}

/// One numbered section: purple circle marker + purple title + content.
class _TenseSection extends StatelessWidget {
  const _TenseSection({
    required this.section,
    required this.bodyStyle,
    required this.purple,
    required this.markerPurple,
  });

  final Map<String, dynamic> section;
  final TextStyle bodyStyle;
  final Color purple;
  final Color markerPurple;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final int number = (section['number'] as num?)?.toInt() ?? 0;
    final String title = (section['title'] as String?) ?? '';
    final String type = (section['type'] as String?) ?? 'plain';
    final String intro = (section['intro'] as String?) ?? '';
    final String note = (section['note'] as String?) ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // ── Marker + purple section title ──────────────────────────
          Row(
            children: <Widget>[
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: markerPurple,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$number',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: purple,
                      fontWeight: FontWeight.w800,
                    ),
                    children: _boldMarkedSpans(
                      title,
                      color: purple,
                      highlightColor: highlightYellowColor(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Optional gray note under the title (Special Prepositions) ──
          if (note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                note,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ),

          // ── Optional intro line (Main Rule) ─────────────────────────
          if (intro.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                intro,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.4,
                  color: scheme.onSurface,
                ),
              ),
            ),

          // ── Content by section type ──────────────────────────────────
          if (type == 'tables')
            for (final dynamic t in (section['tables'] as List<dynamic>? ?? []))
              _TenseGroupTable(
                table: t as Map<String, dynamic>,
                bodyStyle: bodyStyle,
              )
          else if (type == 'rules')
            for (final dynamic r in (section['rules'] as List<dynamic>? ?? []))
              _TenseRuleBullet(rule: r as Map<String, dynamic>, bodyStyle: bodyStyle)
          else if (type == 'table')
            _TenseGroupTable(
              table: <String, dynamic>{
                'columns': section['columns'],
                'rows': section['rows'],
              },
              bodyStyle: bodyStyle,
              hideHeading: true,
            ),
        ],
      ),
    );
  }
}

/// A proper compact bordered table with an optional bold heading above it.
class _TenseGroupTable extends StatelessWidget {
  const _TenseGroupTable({
    required this.table,
    required this.bodyStyle,
    this.hideHeading = false,
  });

  final Map<String, dynamic> table;
  final TextStyle bodyStyle;
  final bool hideHeading;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String heading = (table['heading'] as String?) ?? '';
    final List<String> columns =
        (table['columns'] as List<dynamic>? ?? []).cast<String>();
    final List<List<String>> rows = (table['rows'] as List<dynamic>? ?? [])
        .map<List<String>>((dynamic row) =>
            (row as List<dynamic>).cast<String>())
        .toList(growable: false);
    final Color borderColor = scheme.outlineVariant.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!hideHeading && heading.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                heading,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Table(
                border: TableBorder(
                  horizontalInside: BorderSide(color: borderColor),
                  verticalInside: BorderSide(color: borderColor),
                ),
                // Adaptive widths: voice column narrower, pattern/example
                // columns wider (2-col tables split evenly).
                columnWidths: columns.length >= 3
                    ? const <int, TableColumnWidth>{
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(3),
                        2: FlexColumnWidth(3),
                      }
                    : null,
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: <TableRow>[
                  TableRow(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                    ),
                    children: <Widget>[
                      for (final String column in columns)
                        _tableCell(
                          context,
                          column,
                          header: true,
                        ),
                    ],
                  ),
                  for (final List<String> row in rows)
                    TableRow(
                      children: <Widget>[
                        for (int i = 0; i < row.length; i++)
                          _tableCell(
                            context,
                            row[i],
                            headerIndex: i < columns.length ? i : -1,
                            headers: columns,
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableCell(
    BuildContext context,
    String text, {
    bool header = false,
    int headerIndex = -1,
    List<String> headers = const <String>[],
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color? voiceColor = header
        ? null
        : grammarTableCellColor(
            context, headers, headerIndex, stripHighlightMarkup(text));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Text.rich(
        TextSpan(
          style: (header ? theme.textTheme.labelMedium : bodyStyle)?.copyWith(
            color: header
                ? scheme.onSurface
                : (voiceColor ?? scheme.onSurface),
            fontWeight: header
                ? FontWeight.w800
                : (voiceColor == kGrammarHeadingPurple ? FontWeight.w700 : null),
            height: 1.25,
          ),
          children: _boldMarkedSpans(
            text,
            color: header
                ? scheme.onSurface
                : (voiceColor ?? scheme.onSurface),
            highlightColor: highlightYellowColor(context),
          ),
        ),
      ),
    );
  }
}

/// One Main Rule bullet: purple dot + bold English + Urdu below (LTR wrap).
class _TenseRuleBullet extends StatelessWidget {
  const _TenseRuleBullet({required this.rule, required this.bodyStyle});

  final Map<String, dynamic> rule;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String text = (rule['text'] as String?) ?? '';
    final String urdu = (rule['urdu'] as String?) ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 8, color: _TenseSectionsView._markerPurple),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text.rich(
                  TextSpan(
                    style: bodyStyle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                      fontSize: (bodyStyle.fontSize ?? 13) + 1,
                    ),
                    children: _boldMarkedSpans(
                      text,
                      color: scheme.onSurface,
                      highlightColor: highlightYellowColor(context),
                    ),
                  ),
                ),
                if (urdu.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(
                    urdu,
                    style: bodyStyle.copyWith(
                      color: scheme.onSurface,
                      height: 1.6,
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

class _NounLandingView extends StatelessWidget {
  const _NounLandingView({required this.lesson});

  final GrammarLesson lesson;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isTensesOverview = lesson.id == 'tenses' || lesson.id == 'tenses/overview';
    final List<GrammarExample> overviewExamples = isTensesOverview
        ? lesson.examples
        : (lesson.examples.isEmpty
            ? const <GrammarExample>[]
            : <GrammarExample>[lesson.examples.first]);
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
              if (overviewExamples.isNotEmpty) ...<Widget>[
                const Divider(height: 24),
                Text('Examples',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    )),
                const SizedBox(height: 6),
                for (int index = 0; index < overviewExamples.length; index++) ...<Widget>[
                  if (index > 0) const Divider(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('• ', style: TextStyle(color: theme.colorScheme.primary)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text.rich(
                              TextSpan(
                                style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                                children: _boldMarkedSpans(overviewExamples[index].text),
                              ),
                            ),
                            if (overviewExamples[index].urdu?.isNotEmpty ?? false) ...<Widget>[
                              const SizedBox(height: 5),
                              Directionality(
                                textDirection: TextDirection.rtl,
                                child: Text(
                                  overviewExamples[index].urdu!,
                                  textAlign: TextAlign.right,
                                  style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                                ),
                              ),
                            ],
                            if (isTensesOverview &&
                                (overviewExamples[index].note?.isNotEmpty ?? false)) ...<Widget>[
                              const SizedBox(height: 4),
                              Text(
                                overviewExamples[index].note!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        if (lesson.id == 'pos/adjective')
          const _LandingSectionLabel(title: 'Kinds of Adjective'),
        for (int index = 0; index < lesson.types.length; index++)
          _NounTypeRow(
            type: lesson.types[index],
            number: index + 1,
            accent: accents[index % accents.length],
            lessonId: lesson.id,
          ),
        for (int index = 0; index < lesson.additionalTypes.length; index++)
          _NounTypeRow(
            type: lesson.additionalTypes[index],
            number: index + 1,
            accent: accents[(index + lesson.types.length) % accents.length],
            lessonId: lesson.id,
          ),
        if (lesson.id == 'pos/adjective' && lesson.degreeTypes.isNotEmpty)
          _DegreeFolderCard(
            lesson: lesson,
            accents: accents,
          ),
        if (isTensesOverview) ...<Widget>[
          const SizedBox(height: 12),
          const _LandingSectionLabel(title: 'Tenses at a Glance'),
          const _ZoomableFooterImage(
            imagePath: 'assets/grammar/images/english_tenses_at_a_glance.png',
          ),
        ],
        if (lesson.footerImage.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          const _LandingSectionLabel(title: 'Quick Reference Guide'),
          _ZoomableFooterImage(imagePath: lesson.footerImage),
        ],
      ],
    );
  }
}

class _DegreeFolderCard extends StatelessWidget {
  const _DegreeFolderCard({required this.lesson, required this.accents});

  final GrammarLesson lesson;
  final List<Color> accents;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 2, bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.folder_open_outlined,
                      color: Colors.white, size: 23),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Degrees of Comparison',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            if (lesson.degreeNote.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                lesson.degreeNote,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
            ],
            const SizedBox(height: 6),
            for (int index = 0; index < lesson.degreeTypes.length; index++)
              _NounTypeRow(
                type: lesson.degreeTypes[index],
                number: index + 1,
                accent: accents[(index + lesson.types.length) % accents.length],
                lessonId: lesson.id,
              ),
          ],
        ),
      ),
    );
  }
}

class _LandingSectionLabel extends StatelessWidget {
  const _LandingSectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
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
  const GrammarTypeContent({super.key, required this.type});
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
            Text.rich(
              TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                children: _boldMarkedSpans(type.description),
              ),
            ),
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
              child: type.name == 'Regular Verb' || type.name == 'Irregular Verb'
                  ? _VerbFormsAwareText(
                      label: 'E.g.: ',
                      text: type.exampleWords,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                    )
                  : _MarkedLessonText(
                      label: 'E.g.: ',
                      text: type.exampleWords,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ],
          if (type.pronounTable.isNotEmpty) ...<Widget>[
            const _TypeSubheading(title: 'Personal Pronoun Forms', icon: Icons.table_chart_outlined),
            _PronounTable(rows: type.pronounTable),
          ],
          if (type.name == 'Verb Forms Tables' && type.tableGroups.isNotEmpty) ...<Widget>[
            for (final GrammarTableGroup group in type.tableGroups)
              _CompactTableSection(group: group),
          ] else if (type.name == 'Fixed Prepositions' && type.tableGroups.isNotEmpty) ...<Widget>[
            _FixedPrepositionsGroups(groups: type.tableGroups),
          ] else
            for (final GrammarTableGroup group in type.tableGroups) ...<Widget>[
              _TypeSubheading(title: group.title, icon: Icons.table_chart_outlined),
              _CompactTypeTable(columns: group.columns, rows: group.rows),
            ],
          if (type.rules.isNotEmpty) ...<Widget>[
            const _TypeSubheading(title: 'Rules', icon: Icons.rule),
            for (int i = 0; i < type.rules.length; i++)
              _RuleItem(
                rule: type.rules[i],
                example: i < type.ruleExamples.length ? type.ruleExamples[i] : null,
                verbFormRows: type.name == 'Regular Verb' || type.name == 'Irregular Verb',
                colored: true,
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
          if (type.tableRows.isNotEmpty) ...<Widget>[
            _TypeSubheading(title: type.tableTitle.isEmpty ? 'Verb Forms' : type.tableTitle, icon: Icons.table_chart_outlined),
            _GrammarTable(
              columns: type.tableColumns,
              rows: type.tableRows,
              compact: type.name == 'Regular Verbs Table' ||
                  type.name == 'Irregular Verbs Table' ||
                  type.name == 'Possessive Adjective' ||
                  type.name == 'Distributive Adjective' ||
                  type.name == 'Proper Adjective',
            ),
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

class _FixedPrepositionsGroups extends StatelessWidget {
  const _FixedPrepositionsGroups({required this.groups});

  final List<GrammarTableGroup> groups;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final GrammarTableGroup group in groups) ...<Widget>[
          _TypeSubheading(title: group.title, icon: Icons.table_chart_outlined),
          _FixedPrepositionGroup(group: group),
        ],
      ],
    );
  }
}

class _FixedPrepositionGroup extends StatelessWidget {
  const _FixedPrepositionGroup({required this.group});

  final GrammarTableGroup group;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: <Widget>[
            for (int index = 0; index < group.rows.length; index++) ...<Widget>[
              _FixedPrepositionEntry(
                row: group.rows[index],
                index: index,
              ),
              if (index < group.rows.length - 1)
                Divider(height: 12, color: scheme.outlineVariant.withValues(alpha: 0.7)),
            ],
          ],
        ),
      ),
    );
  }
}

class _FixedPrepositionEntry extends StatelessWidget {
  const _FixedPrepositionEntry({required this.row, required this.index});

  final GrammarTableRow row;
  final int index;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    String cell(int position) => position < row.cells.length ? row.cells[position] : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '${index + 1}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cell(0),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          _FixedPrepositionLabelValue(label: 'Definition', value: cell(1)),
          if (cell(2).isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Directionality(
              textDirection: TextDirection.rtl,
              child: _FixedPrepositionLabelValue(
                label: 'اردو',
                value: cell(2),
                textAlign: TextAlign.right,
              ),
            ),
          ],
          if (cell(3).isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            _FixedPrepositionLabelValue(label: 'Example', value: cell(3)),
          ],
        ],
      ),
    );
  }
}

class _FixedPrepositionLabelValue extends StatelessWidget {
  const _FixedPrepositionLabelValue({
    required this.label,
    required this.value,
    this.textAlign,
  });

  final String label;
  final String value;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return RichText(
      textAlign: textAlign ?? TextAlign.start,
      text: TextSpan(
        style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
        children: <InlineSpan>[
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _CompactTableSection extends StatelessWidget {
  const _CompactTableSection({required this.group});

  final GrammarTableGroup group;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              group.title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            _GrammarTable(
              columns: group.columns,
              rows: group.rows,
              compact: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactTypeTable extends StatelessWidget {
  const _CompactTypeTable({required this.columns, required this.rows});

  final List<String> columns;
  final List<GrammarTableRow> rows;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: <Widget>[
          _row(
            columns,
            headers: columns,
            theme: theme,
            color: scheme.primary,
            bold: true,
          ),
          for (final GrammarTableRow row in rows) ...<Widget>[
            Divider(height: 10, color: scheme.outlineVariant.withValues(alpha: 0.65)),
            _row(row.cells, headers: columns, theme: theme, voiceAware: true),
          ],
        ],
      ),
    );
  }

  Widget _row(
    List<String> cells, {
    List<String> headers = const <String>[],
    required ThemeData theme,
    Color? color,
    bool bold = false,
    bool voiceAware = false,
  }) {
    final ThemeData effectiveTheme = theme;
    final int count = cells.length.clamp(1, 3);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < count; i++)
          Expanded(
            flex: i == 0 ? 1 : 2,
            child: Builder(
              builder: (BuildContext rowContext) {
                // rowContext resolves the theme for voice-aware colors.
                final String cell = i < cells.length ? cells[i] : '';
                final Color? cellColor = voiceAware
                    ? (grammarTableCellColor(rowContext, headers, i, cell) ?? color)
                    : color;
                return Text.rich(
                  TextSpan(
                    style: (effectiveTheme.textTheme.bodySmall ?? const TextStyle()).copyWith(
                      color: cellColor,
                      fontWeight: bold
                          ? FontWeight.w800
                          : (cellColor == kGrammarHeadingPurple
                              ? FontWeight.w700
                              : null),
                      height: 1.2,
                    ),
                    children: _boldMarkedSpans(cell, color: cellColor),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _GrammarTable extends StatelessWidget {
  const _GrammarTable({required this.columns, required this.rows, this.compact = false});
  final List<String> columns;
  final List<GrammarTableRow> rows;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final List<String> safeColumns = columns.isEmpty ? List<String>.generate(rows.first.cells.length, (int i) => 'Column ${i + 1}') : columns;
    return Card(
      margin: EdgeInsets.only(bottom: compact ? 4 : 14),
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.all(compact ? 4 : 10),
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll<Color>(scheme.primary.withValues(alpha: 0.12)),
          dataRowMinHeight: compact ? 25 : 44,
          dataRowMaxHeight: compact ? 34 : 86,
          columnSpacing: compact ? 8 : 18,
          columns: safeColumns.map((String column) => DataColumn(label: Text(column, style: theme.textTheme.labelMedium?.copyWith(fontSize: compact ? 9 : null, fontWeight: FontWeight.w700)))).toList(),
          rows: rows.map((GrammarTableRow row) {
            return DataRow(
              cells: List<DataCell>.generate(safeColumns.length, (int i) {
                final String cell = i < row.cells.length ? row.cells[i] : '';
                final Color? cellColor = grammarTableCellColor(context, safeColumns, i, cell);
                return DataCell(
                  Text(
                    cell,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: compact ? 10 : null,
                      height: compact ? 1.0 : 1.3,
                      color: cellColor,
                      fontWeight: cellColor != null && cellColor == kGrammarHeadingPurple
                          ? FontWeight.w700
                          : null,
                    ),
                  ),
                );
              }),
            );
          }).toList(),
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

/// Colors a rule string the way the previous lesson-level Rules design did:
/// sentences after an **Example:/Examples:** label render in the blue example
/// color, sentences after **Explanation:/Here:** in the purple color, and the
/// label itself in the given highlight color. Everything else keeps `color`.
List<TextSpan> _coloredRuleSpans(String text, {required Brightness brightness}) {
  final Color exampleColor = activeVoiceColorFor(brightness);
  final Color passiveColor = passiveVoiceColorFor(brightness);
  const Color explanationColor = Color(0xFFCE93D8);
  const Color labelColor = Color(0xFF42A5F5);
  final RegExp marker = RegExp(r'(Example|Examples|Explanation|Here):');
  final List<TextSpan> spans = <TextSpan>[];
  int cursor = 0;
  for (final RegExpMatch match in marker.allMatches(text)) {
    if (match.start > cursor) {
      spans.addAll(_boldMarkedSpans(text.substring(cursor, match.start)));
    }
    final bool explanation =
        match.group(1)!.startsWith('Explanation') || match.group(1) == 'Here';
    spans.add(TextSpan(
      text: text.substring(match.start, match.end),
      style: const TextStyle(color: labelColor, fontWeight: FontWeight.w700),
    ));
    cursor = match.end;
    final RegExpMatch? next = marker.firstMatch(text.substring(cursor));
    final int end = next == null ? text.length : cursor + next.start;
    final String chunk = text.substring(cursor, end);
    spans.addAll(_boldMarkedSpans(
      chunk,
      color: explanation
          ? explanationColor
          : (isPassiveVoiceSentence(chunk) ? passiveColor : exampleColor),
    ));
    cursor = end;
  }
  if (cursor < text.length) {
    spans.addAll(_boldMarkedSpans(text.substring(cursor)));
  }
  return spans.isEmpty ? <TextSpan>[TextSpan(text: text)] : spans;
}

/// Sentence color for free-form text blocks: passive green, active blue for
/// standalone example sentences, otherwise null (default text color).
Color? _voiceTextColor(BuildContext context, String text) {
  if (isPassiveVoiceSentence(text)) return passiveVoiceColor(context);
  if (looksLikeExampleSentence(text)) return activeVoiceColor(context);
  return null;
}

List<TextSpan> _boldMarkedSpans(String text,
    {Color? color, Color? highlightColor}) {
  final List<TextSpan> spans = <TextSpan>[];
  final RegExp markup =
      RegExp(r'(@@(.+?)@@|\*\*\*(.+?)\*\*\*|\*\*(.+?)\*\*|__(.+?)__)');
  int cursor = 0;
  for (final RegExpMatch match in markup.allMatches(text)) {
    if (match.start > cursor) {
      spans.add(TextSpan(
        text: text.substring(cursor, match.start).replaceAll(' > ', ' → '),
        style: TextStyle(color: color),
      ));
    }
    final String value = (match.group(2) ?? match.group(3) ?? match.group(4) ?? match.group(5)!)
        .replaceAll(' > ', ' → ');
    if (match.group(2) != null) {
      // @@yellow highlight@@ — bold theme-aware amber for important words.
      spans.add(TextSpan(
        text: value,
        style: TextStyle(
          color: highlightColor,
          fontWeight: FontWeight.w800,
        ),
      ));
    } else {
      final bool both = match.group(3) != null;
      spans.add(TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontWeight: both || match.group(4) != null ? FontWeight.w800 : null,
          decoration: match.group(5) != null || both ? TextDecoration.underline : null,
          decorationThickness: match.group(5) != null || both ? 2 : null,
        ),
      ));
    }
    cursor = match.end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(
      text: text.substring(cursor).replaceAll(' > ', ' → '),
      style: TextStyle(color: color),
    ));
  }
  return spans.isEmpty ? <TextSpan>[TextSpan(text: text, style: TextStyle(color: color))] : spans;
}

class _MarkedLessonText extends StatelessWidget {
  const _MarkedLessonText({required this.label, required this.text, this.labelStyle});

  final String label;
  final String text;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text.rich(
      TextSpan(
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
          height: 1.45,
        ),
        children: <InlineSpan>[
          TextSpan(text: label, style: labelStyle),
          ..._boldMarkedSpans(text),
        ],
      ),
    );
  }
}

class _VerbFormsAwareText extends StatelessWidget {
  const _VerbFormsAwareText({
    required this.label,
    required this.text,
    this.labelStyle,
    this.italic = false,
  });

  final String label;
  final String text;
  final TextStyle? labelStyle;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle baseStyle = (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
      color: theme.colorScheme.primary,
      fontStyle: italic ? FontStyle.italic : null,
      height: 1.4,
    );
    final List<String> parts = text.split(';');
    final bool hasForms = parts.any((String part) => _verbFormValues(part) != null);
    if (!hasForms) {
      return Text.rich(
        TextSpan(
          style: baseStyle,
          children: <InlineSpan>[
            TextSpan(text: label, style: labelStyle),
            ..._boldMarkedSpans(text),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: baseStyle.copyWith(fontWeight: labelStyle?.fontWeight)),
        const SizedBox(height: 3),
        for (final String part in parts)
          if (part.trim().isNotEmpty)
            _VerbFormPart(part: part, style: baseStyle),
      ],
    );
  }
}

class _VerbFormPart extends StatelessWidget {
  const _VerbFormPart({required this.part, required this.style});

  final String part;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final List<String>? forms = _verbFormValues(part);
    if (forms != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: _VerbFormsRow(forms: forms),
      );
    }
    return Text.rich(
      TextSpan(style: style, children: _boldMarkedSpans(part.trim())),
    );
  }
}

List<String>? _verbFormValues(String value) {
  final List<String> forms = value
      .trim()
      .replaceAll('→', '>')
      .split('>')
      .map((String item) => item.trim())
      .where((String item) => item.isNotEmpty)
      .toList(growable: false);
  return forms.length == 3 ? forms : null;
}

class _VerbFormsRow extends StatelessWidget {
  const _VerbFormsRow({required this.forms});
  final List<String> forms;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: <Widget>[
          for (int index = 0; index < forms.length; index++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                child: Text(
                  forms[index],
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  const _RuleItem({
    required this.rule,
    this.example,
    this.verbFormRows = false,
    this.colored = false,
  });
  final String rule;
  final String? example;
  final bool verbFormRows;

  /// Colors every Example/Explanation sentence inside the rule, matching the
  /// colored rendering used by the lesson-level Rules sections.
  final bool colored;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<TextSpan> spans = colored
        ? _coloredRuleSpans(rule, brightness: theme.brightness)
        : _boldMarkedSpans(rule);
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
                  if (verbFormRows)
                    _VerbFormsAwareText(
                      label: 'Example: ',
                      text: example!,
                      italic: true,
                    )
                  else if (colored)
                    TenseRichText(
                      text: 'Example: ${example!}',
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                    )
                  else
                    _MarkedLessonText(
                      label: 'Example: ',
                      text: example!,
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
  const _ExampleItem({required this.example, this.compact = false});
  final GrammarExample example;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: compact ? 8 : 10),
      padding: EdgeInsets.all(compact ? 10 : 12),
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
          Text.rich(
            TextSpan(
              style: (compact ? theme.textTheme.bodySmall : theme.textTheme.bodyLarge)
                  ?.copyWith(height: compact ? 1.25 : 1.4),
              children: _boldMarkedSpans(
                example.text,
                color: compact
                    ? voiceSentenceColor(context, example.text)
                    : null,
              ),
            ),
          ),
          if (example.urdu != null && example.urdu!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                example.urdu!,
                textAlign: TextAlign.right,
                style: (compact ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)
                    ?.copyWith(
                        height: compact ? 1.35 : 1.6,
                        color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
          if (example.note != null && example.note!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontStyle: FontStyle.italic),
                children: _boldMarkedSpans(
                  example.note!,
                  color: compact ? const Color(0xFFCE93D8) : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MistakeItem extends StatelessWidget {
  const _MistakeItem({required this.mistake, this.compact = false});
  final GrammarMistake mistake;
  final bool compact;

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
                  child: Text.rich(
                    TextSpan(
                      style: (compact ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)?.copyWith(
                          color: scheme.error,
                          decoration: TextDecoration.lineThrough),
                      children: _boldMarkedSpans(mistake.wrong),
                    ),
                  ),
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
                  child: Text.rich(
                    TextSpan(
                      style: (compact ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)
                          ?.copyWith(color: right, fontWeight: FontWeight.w600),
                      children: _boldMarkedSpans(mistake.right),
                    ),
                  ),
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
              child: Text.rich(
                TextSpan(
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: compact
                        ? const Color(0xFFCE93D8)
                        : scheme.onSurfaceVariant,
                  ),
                  children: _boldMarkedSpans(
                    mistake.note!,
                    color: compact ? const Color(0xFFCE93D8) : null,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ZoomableFooterImage extends StatefulWidget {
  const _ZoomableFooterImage({required this.imagePath});
  final String imagePath;

  @override
  State<_ZoomableFooterImage> createState() => _ZoomableFooterImageState();
}

class _ZoomableFooterImageState extends State<_ZoomableFooterImage> {
  final TransformationController _transformationController = TransformationController();
  TapDownDetails? _doubleTapDetails;

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails!.localPosition;
      _transformationController.value = Matrix4.identity()
        ..translateByVector3(Vector3(-position.dx * 1.5, -position.dy * 1.5, 0))
        ..scaleByDouble(2.5, 2.5, 2.5, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 24),
      child: GestureDetector(
        onDoubleTapDown: _handleDoubleTapDown,
        onDoubleTap: _handleDoubleTap,
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.1,
          maxScale: 10.0,
          child: Image.asset(
            widget.imagePath,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _AllInOneQuizView extends StatefulWidget {
  const _AllInOneQuizView({required this.lesson});
  final GrammarLesson lesson;

  @override
  State<_AllInOneQuizView> createState() => _AllInOneQuizViewState();
}

class _AllInOneQuizViewState extends State<_AllInOneQuizView> {
  late List<GrammarQuestion> _questions;
  int _currentIndex = 0;
  int _score = 0;
  bool _answered = false;
  bool _finished = false;
  final List<bool> _results = [];

  @override
  void initState() {
    super.initState();
    _startQuiz();
  }

  void _startQuiz() {
    setState(() {
      _questions = List.from(widget.lesson.quiz)..shuffle();
      if (_questions.length > 20) {
        _questions = _questions.take(20).toList();
      }
      _currentIndex = 0;
      _score = 0;
      _answered = false;
      _finished = false;
      _results.clear();
    });
  }

  void _handleAnswer(int index, bool isCorrect) {
    if (_answered) return;
    setState(() {
      _answered = true;
      if (isCorrect) _score++;
      _results.add(isCorrect);
    });
  }

  void _next() {
    setState(() {
      if (_currentIndex < _questions.length - 1) {
        _currentIndex++;
        _answered = false;
      } else {
        _finished = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (_finished) {
      return _QuizResultView(
        score: _score,
        total: _questions.length,
        onRetry: _startQuiz,
      );
    }

    if (_questions.isEmpty) {
      return const Center(child: Text('No questions available.'));
    }

    final q = _questions[_currentIndex];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${_currentIndex + 1} of ${_questions.length}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Score: $_score',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: (_currentIndex + 1) / _questions.length,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 24),
        PracticeQuestionCard(
          key: ValueKey('q_$_currentIndex'),
          question: q,
          onAnswer: _handleAnswer,
        ),
        const SizedBox(height: 16),
        if (_answered)
          ElevatedButton(
            onPressed: _next,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(_currentIndex < _questions.length - 1 ? 'Next Question' : 'See Results'),
          ),
      ],
    );
  }
}

class _QuizResultView extends StatelessWidget {
  const _QuizResultView({
    required this.score,
    required this.total,
    required this.onRetry,
  });

  final int score;
  final int total;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double percentage = (score / total) * 100;
    
    String performance;
    Color color;
    if (percentage >= 90) {
      performance = 'Excellent';
      color = Colors.green;
    } else if (percentage >= 75) {
      performance = 'Very Good';
      color = Colors.blue;
    } else if (percentage >= 60) {
      performance = 'Good';
      color = Colors.orange;
    } else if (percentage >= 40) {
      performance = 'Needs Improvement';
      color = Colors.deepOrange;
    } else {
      performance = 'More Practice Needed';
      color = Colors.red;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 80, color: color),
            const SizedBox(height: 24),
            Text(
              'Quiz Completed!',
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Your Score',
              style: theme.textTheme.titleMedium,
            ),
            Text(
              '$score / $total',
              style: theme.textTheme.displayMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: theme.textTheme.titleLarge?.copyWith(color: color),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Text(
                performance,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Quiz'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Parts of Speech'),
            ),
          ],
        ),
      ),
    );
  }
}
