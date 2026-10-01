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
  const _BilingualText({required this.text, required this.style, this.highlightColor});

  final String text;
  final TextStyle style;

  /// Optional override for the color used to highlight Latin words embedded
  /// in the Urdu text (defaults to the theme primary).
  final Color? highlightColor;

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
          color: highlightColor ?? theme.colorScheme.primary,
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
    // Full-page reference sheet (Direct & Indirect Speech course lessons).
    if (lesson.narrationSheet != null && lesson.narrationSheet!.isNotEmpty) {
      return _NarrationSheetView(lesson: lesson);
    }
    // Compact side-by-side Direct vs Indirect Speech layout (Introduction &
    // Basic Difference). Both panels render on the same screen — no slides.
    if (lesson.narrationIntro != null && lesson.narrationIntro!.isNotEmpty) {
      return _NarrationIntroView(lesson: lesson);
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
    final String badge = (data['badge'] as String?) ?? '';
    final String definition = (data['definition'] as String?) ?? '';
    final List<dynamic> sections = (data['sections'] as List<dynamic>?) ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: <Widget>[
        // ── Page heading (e.g. "3. Present Simple") ─────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: Text.rich(
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
            ),
            if (badge.isNotEmpty) ...<Widget>[
              const SizedBox(width: 10),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: highlightYellowColor(context), width: 1.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: highlightYellowColor(context),
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (definition.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text.rich(
              TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface,
                  height: 1.35,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: 'Definition: ',
                    style: TextStyle(
                      color: _TenseSectionsView._purple,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  ..._boldMarkedSpans(
                    definition,
                    color: scheme.onSurface,
                    highlightColor: highlightYellowColor(context),
                  ),
                ],
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
          else if (type == 'rules' && (section['boxed'] == true))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: purple, width: 1.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final dynamic r in (section['rules'] as List<dynamic>? ?? []))
                    _TenseRuleBullet(rule: r as Map<String, dynamic>, bodyStyle: bodyStyle),
                ],
              ),
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
            imagePath: 'assets/grammar/images/english_tenses_at_a_glance.webp',
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

/// ─────────────────────────────────────────────────────────────────────────────
/// Compact side-by-side "Direct Speech vs Indirect Speech" layout for the
/// Introduction & Basic Difference lesson. Both panels render on one screen —
/// never as swipeable slides — followed by a compact step-by-step method, a
/// key-difference table and an exam tip. Content comes from the lesson's
/// `narrationIntro` map (assets/grammar/grammar_topics.json).
/// ─────────────────────────────────────────────────────────────────────────────
class _NarrationIntroView extends StatelessWidget {
  const _NarrationIntroView({required this.lesson});

  final GrammarLesson lesson;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Map<String, dynamic> data =
        lesson.narrationIntro ?? const <String, dynamic>{};
    final List<Map<String, dynamic>> columns =
        _narrationMaps(data['columns']);
    final Map<String, dynamic>? method =
        data['method'] as Map<String, dynamic>?;
    final Map<String, dynamic>? keyDifference =
        data['keyDifference'] as Map<String, dynamic>?;
    final Map<String, dynamic>? examTip =
        data['examTip'] as Map<String, dynamic>?;

    final TextStyle bodyStyle = theme.textTheme.bodySmall?.copyWith(
          height: 1.35,
          fontSize: 11.5,
          color: scheme.onSurface,
        ) ??
        const TextStyle();
    final TextStyle urduStyle = bodyStyle.copyWith(
      height: 1.6,
      color: scheme.onSurfaceVariant,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 20),
      children: <Widget>[
        // ── Both sections side by side: Direct (left) | Indirect (right) ──
        if (columns.isNotEmpty)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _NarrationPanel(
                    data: columns[0],
                    accent: kGrammarHeadingPurple,
                    bodyStyle: bodyStyle,
                    urduStyle: urduStyle,
                  ),
                ),
                if (columns.length >= 2) ...<Widget>[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _NarrationPanel(
                      data: columns[1],
                      accent: passiveVoiceColor(context),
                      bodyStyle: bodyStyle,
                      urduStyle: urduStyle,
                    ),
                  ),
                ],
              ],
            ),
          ),

        // ── Step-by-Step Method (Direct → Indirect) ──────────────────────
        if (method != null) ...<Widget>[
          const SizedBox(height: 10),
          _NarrationMethod(data: method, bodyStyle: bodyStyle),
        ],

        // ── Key Difference ───────────────────────────────────────────────
        if (keyDifference != null) ...<Widget>[
          const SizedBox(height: 10),
          _NarrationKeyDifference(data: keyDifference, bodyStyle: bodyStyle),
        ],

        // ── Important Rule / Exam Tip ────────────────────────────────────
        if (examTip != null) ...<Widget>[
          const SizedBox(height: 10),
          _NarrationExamTip(data: examTip, bodyStyle: bodyStyle),
        ],

        // ── Practice (kept from the existing lesson data) ────────────────
        if (lesson.practice.isNotEmpty) ...<Widget>[
          const SizedBox(height: 4),
          GrammarSectionCard(
            icon: Icons.edit_note,
            title: 'Practice',
            child: Column(
              children: <Widget>[
                for (int i = 0; i < lesson.practice.length; i++)
                  PracticeQuestionCard(
                    question: lesson.practice[i],
                    index: i + 1,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Extracts the map entries of a JSON list, ignoring anything else.
List<Map<String, dynamic>> _narrationMaps(Object? value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value.whereType<Map<String, dynamic>>().toList(growable: false);
}

/// One side panel of the comparison (purple = Direct Speech, green = Indirect
/// Speech): definition, Urdu definition, example, parts of the sentence,
/// numbered features and the worked example explanation.
class _NarrationPanel extends StatelessWidget {
  const _NarrationPanel({
    required this.data,
    required this.accent,
    required this.bodyStyle,
    required this.urduStyle,
  });

  final Map<String, dynamic> data;
  final Color accent;
  final TextStyle bodyStyle;
  final TextStyle urduStyle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String title = (data['title'] as String?) ?? '';
    final String definition = (data['definition'] as String?) ?? '';
    final String definitionUrdu = (data['definitionUrdu'] as String?) ?? '';
    final String example = (data['example'] as String?) ?? '';
    final String exampleUrdu = (data['exampleUrdu'] as String?) ?? '';
    final List<Map<String, dynamic>> parts = _narrationMaps(data['parts']);
    final String featuresTitle =
        (data['featuresTitle'] as String?) ?? 'Features';
    final List<Map<String, dynamic>> features = _narrationMaps(data['features']);
    final Map<String, dynamic>? explain =
        data['explain'] as Map<String, dynamic>?;

    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.05),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // ── Panel header: speaker icon + title ──────────────────────────
          Container(
            width: double.infinity,
            color: accent.withValues(alpha: 0.2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: Row(
              children: <Widget>[
                Icon(Icons.volume_up, size: 15, color: accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // ── Definition + Urdu definition ────────────────────────
                _NarrationPanelLabel(
                  icon: Icons.menu_book_outlined,
                  label: 'Definition',
                  color: accent,
                ),
                const SizedBox(height: 3),
                if (definition.isNotEmpty) Text(definition, style: bodyStyle),
                if (definitionUrdu.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 3),
                  _BilingualText(
                    text: definitionUrdu,
                    style: urduStyle,
                    highlightColor: accent,
                  ),
                ],

                // ── Example + Urdu example ──────────────────────────────
                const SizedBox(height: 8),
                _NarrationPanelLabel(
                  icon: Icons.format_quote,
                  label: 'Example',
                  color: accent,
                ),
                const SizedBox(height: 3),
                if (example.isNotEmpty)
                  _NarrationSentence(
                    text: example,
                    accent: accent,
                    bodyStyle: bodyStyle,
                  ),
                if (exampleUrdu.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 3),
                  _BilingualText(
                    text: exampleUrdu,
                    style: urduStyle,
                    highlightColor: accent,
                  ),
                ],

                // ── Parts of the Sentence ───────────────────────────────
                if (parts.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  _NarrationPanelLabel(
                    icon: Icons.account_tree_outlined,
                    label: 'Parts of the Sentence',
                    color: accent,
                  ),
                  const SizedBox(height: 4),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        for (int i = 0; i < parts.length; i++) ...<Widget>[
                          if (i > 0) const SizedBox(width: 6),
                          Expanded(
                            child: _NarrationPart(
                              data: parts[i],
                              color:
                                  i == 0 ? accent : activeVoiceColor(context),
                              bodyStyle: bodyStyle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // ── Numbered features ───────────────────────────────────
                if (features.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  _NarrationPanelLabel(
                    icon: Icons.settings_outlined,
                    label: featuresTitle,
                    color: accent,
                  ),
                  const SizedBox(height: 4),
                  for (int i = 0; i < features.length; i++)
                    _NarrationFeature(
                      data: features[i],
                      index: i + 1,
                      accent: accent,
                      bodyStyle: bodyStyle,
                    ),
                ],

                // ── Example with Explanation ────────────────────────────
                if (explain != null)
                  _NarrationExplain(
                    data: explain,
                    accent: accent,
                    bodyStyle: bodyStyle,
                    mutedColor: scheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Worked example explanation inside a panel: the sentence, the numbered
/// teaching points (with their WHY lines) and the "Why used?" bullets or the
/// change summary chips for Indirect Speech.
class _NarrationExplain extends StatelessWidget {
  const _NarrationExplain({
    required this.data,
    required this.accent,
    required this.bodyStyle,
    required this.mutedColor,
  });

  final Map<String, dynamic> data;
  final Color accent;
  final TextStyle bodyStyle;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String title =
        (data['title'] as String?) ?? 'Example with Explanation';
    final String sentence = (data['sentence'] as String?) ?? '';
    final List<Map<String, dynamic>> points = _narrationMaps(data['points']);
    final String whyTitle = (data['whyTitle'] as String?) ?? '';
    final List<String> why = ((data['why'] as List<dynamic>?) ?? const <dynamic>[])
        .map((dynamic e) => e.toString())
        .toList(growable: false);
    final List<String> changes =
        ((data['changes'] as List<dynamic>?) ?? const <dynamic>[])
            .map((dynamic e) => e.toString())
            .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 8),
        _NarrationPanelLabel(
          icon: Icons.lightbulb_outline,
          label: title,
          color: accent,
        ),
        if (sentence.isNotEmpty) ...<Widget>[
          const SizedBox(height: 4),
          _NarrationSentence(
            text: sentence,
            accent: accent,
            bodyStyle: bodyStyle,
          ),
        ],
        const SizedBox(height: 5),
        for (int i = 0; i < points.length; i++)
          _NarrationPoint(
            data: points[i],
            index: i + 1,
            accent: accent,
            bodyStyle: bodyStyle,
            mutedColor: mutedColor,
          ),
        if (why.isNotEmpty) ...<Widget>[
          const SizedBox(height: 2),
          Text(
            whyTitle.isEmpty ? 'Why used?' : whyTitle,
            style: bodyStyle.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 3),
          for (final String item in why)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(top: 5, right: 6),
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: bodyStyle.copyWith(
                        height: 1.3,
                        color: mutedColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        if (changes.isNotEmpty) ...<Widget>[
          const SizedBox(height: 3),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: <Widget>[
              for (final String change in changes)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    border: Border.all(color: accent.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    change,
                    style: bodyStyle.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                      height: 1.2,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// One numbered teaching point inside "Example with Explanation".
class _NarrationPoint extends StatelessWidget {
  const _NarrationPoint({
    required this.data,
    required this.index,
    required this.accent,
    required this.bodyStyle,
    required this.mutedColor,
  });

  final Map<String, dynamic> data;
  final int index;
  final Color accent;
  final TextStyle bodyStyle;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String label = (data['label'] as String?) ?? '';
    final String text = (data['text'] as String?) ?? '';
    final String why = (data['why'] as String?) ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 15,
            height: 15,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 9.5,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text.rich(
                  TextSpan(
                    style: bodyStyle.copyWith(height: 1.3),
                    children: <InlineSpan>[
                      if (label.isNotEmpty)
                        TextSpan(
                          text: label,
                          style: bodyStyle.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                        ),
                      if (label.isNotEmpty && text.isNotEmpty)
                        const TextSpan(text: ' '),
                      if (text.isNotEmpty) TextSpan(text: text),
                    ],
                  ),
                ),
                if (why.isNotEmpty)
                  Text.rich(
                    TextSpan(
                      style: bodyStyle.copyWith(
                        height: 1.3,
                        color: mutedColor,
                      ),
                      children: _narrationWhySpans(
                        why,
                        highlightYellowColor(context),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders a WHY line with the "WHY?" prefix highlighted in amber.
List<InlineSpan> _narrationWhySpans(String why, Color highlightColor) {
  if (why.startsWith('WHY?')) {
    return <InlineSpan>[
      TextSpan(
        text: 'WHY?',
        style: TextStyle(
          color: highlightColor,
          fontWeight: FontWeight.w800,
        ),
      ),
      TextSpan(text: why.substring(4)),
    ];
  }
  return <InlineSpan>[TextSpan(text: why)];
}

/// Bordered example sentence in the panel accent color.
class _NarrationSentence extends StatelessWidget {
  const _NarrationSentence({
    required this.text,
    required this.accent,
    required this.bodyStyle,
  });

  final String text;
  final Color accent;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: bodyStyle.copyWith(
          color: accent,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
    );
  }
}

/// Small colored section label inside a panel.
class _NarrationPanelLabel extends StatelessWidget {
  const _NarrationPanelLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

/// One labelled part of the sentence (reporting clause / spoken words …).
class _NarrationPart extends StatelessWidget {
  const _NarrationPart({
    required this.data,
    required this.color,
    required this.bodyStyle,
  });

  final Map<String, dynamic> data;
  final Color color;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String text = (data['text'] as String?) ?? '';
    final String label = (data['label'] as String?) ?? '';
    final String urdu = (data['urdu'] as String?) ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: <Widget>[
          Text(
            text,
            textAlign: TextAlign.center,
            style: bodyStyle.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          if (label.isNotEmpty) ...<Widget>[
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: bodyStyle.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
                height: 1.2,
              ),
            ),
          ],
          if (urdu.isNotEmpty) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              urdu,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: bodyStyle.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 10.5,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One numbered feature: title, explanation and Urdu line.
class _NarrationFeature extends StatelessWidget {
  const _NarrationFeature({
    required this.data,
    required this.index,
    required this.accent,
    required this.bodyStyle,
  });

  final Map<String, dynamic> data;
  final int index;
  final Color accent;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String title = (data['title'] as String?) ?? '';
    final String text = (data['text'] as String?) ?? '';
    final String urdu = (data['urdu'] as String?) ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 9.5,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: bodyStyle.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                if (text.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 1),
                  Text(
                    text,
                    style: bodyStyle.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 10.5,
                      height: 1.3,
                    ),
                  ),
                ],
                if (urdu.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 1),
                  _BilingualText(
                    text: urdu,
                    style: bodyStyle.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 10.5,
                      height: 1.55,
                    ),
                    highlightColor: accent,
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

/// Compact full-width card used by the bottom narration sections.
class _NarrationCard extends StatelessWidget {
  const _NarrationCard({
    required this.accent,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle = '',
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.05),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
              if (subtitle.isNotEmpty) ...<Widget>[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: accent.withValues(alpha: 0.6)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Step-by-Step Method (Direct → Indirect): numbered steps with their example
/// transformations, ending in the final converted sentence.
class _NarrationMethod extends StatelessWidget {
  const _NarrationMethod({required this.data, required this.bodyStyle});

  final Map<String, dynamic> data;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    const Color purple = kGrammarHeadingPurple;
    final Color green = passiveVoiceColor(context);
    final List<Map<String, dynamic>> steps = _narrationMaps(data['steps']);
    final String finalLabel = (data['finalLabel'] as String?) ?? 'Final';
    final String finalText = (data['finalText'] as String?) ?? '';

    return _NarrationCard(
      accent: purple,
      icon: Icons.sync_alt,
      title: (data['title'] as String?) ?? 'Step-by-Step Method',
      subtitle: (data['subtitle'] as String?) ?? '',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < steps.length; i++)
            _NarrationStep(
              data: steps[i],
              index: i + 1,
              bodyStyle: bodyStyle,
            ),
          if (finalText.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 2),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.08),
                border: Border.all(color: green.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text.rich(
                TextSpan(
                  style: bodyStyle.copyWith(height: 1.4),
                  children: <InlineSpan>[
                    TextSpan(
                      text: '$finalLabel: ',
                      style: bodyStyle.copyWith(
                        color: purple,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: finalText,
                      style: bodyStyle.copyWith(
                        color: green,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One numbered step of the conversion method.
class _NarrationStep extends StatelessWidget {
  const _NarrationStep({
    required this.data,
    required this.index,
    required this.bodyStyle,
  });

  final Map<String, dynamic> data;
  final int index;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String title = (data['title'] as String?) ?? '';
    final String example = (data['example'] as String?) ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 1),
            decoration: const BoxDecoration(
              color: kGrammarHeadingPurple,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: bodyStyle.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                if (example.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 1),
                  Text(
                    example,
                    style: bodyStyle.copyWith(
                      color: highlightYellowColor(context),
                      fontWeight: FontWeight.w800,
                      height: 1.3,
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

/// Compact two-column Key Difference comparison (Direct | Indirect).
class _NarrationKeyDifference extends StatelessWidget {
  const _NarrationKeyDifference({required this.data, required this.bodyStyle});

  final Map<String, dynamic> data;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    final List<String> direct =
        ((data['direct'] as List<dynamic>?) ?? const <dynamic>[])
            .map((dynamic e) => e.toString())
            .toList(growable: false);
    final List<String> indirect =
        ((data['indirect'] as List<dynamic>?) ?? const <dynamic>[])
            .map((dynamic e) => e.toString())
            .toList(growable: false);

    return _NarrationCard(
      accent: const Color(0xFF42A5F5),
      icon: Icons.rule,
      title: (data['title'] as String?) ?? 'Key Difference',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: _NarrationDiffColumn(
              title: (data['directTitle'] as String?) ?? 'Direct Speech',
              items: direct,
              color: kGrammarHeadingPurple,
              bodyStyle: bodyStyle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _NarrationDiffColumn(
              title: (data['indirectTitle'] as String?) ?? 'Indirect Speech',
              items: indirect,
              color: passiveVoiceColor(context),
              bodyStyle: bodyStyle,
            ),
          ),
        ],
      ),
    );
  }
}

/// One column of the Key Difference comparison.
class _NarrationDiffColumn extends StatelessWidget {
  const _NarrationDiffColumn({
    required this.title,
    required this.items,
    required this.color,
    required this.bodyStyle,
  });

  final String title;
  final List<String> items;
  final Color color;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            color: color.withValues(alpha: 0.18),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: bodyStyle.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final String item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(top: 5, right: 6),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item,
                            style: bodyStyle.copyWith(height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Important Rule / Exam Tip strip (Direct vs Indirect + Urdu).
class _NarrationExamTip extends StatelessWidget {
  const _NarrationExamTip({required this.data, required this.bodyStyle});

  final Map<String, dynamic> data;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String direct = (data['direct'] as String?) ?? '';
    final String indirect = (data['indirect'] as String?) ?? '';
    final String urdu = (data['urdu'] as String?) ?? '';

    return _NarrationCard(
      accent: theme.colorScheme.error,
      icon: Icons.star,
      title: (data['title'] as String?) ?? 'Important Rule / Exam Tip',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (direct.isNotEmpty)
            Text.rich(
              TextSpan(
                style: bodyStyle.copyWith(height: 1.35),
                children: <InlineSpan>[
                  TextSpan(
                    text: 'Direct Speech: ',
                    style: bodyStyle.copyWith(
                      color: kGrammarHeadingPurple,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(text: direct),
                ],
              ),
            ),
          if (indirect.isNotEmpty) ...<Widget>[
            const SizedBox(height: 3),
            Text.rich(
              TextSpan(
                style: bodyStyle.copyWith(height: 1.35),
                children: <InlineSpan>[
                  TextSpan(
                    text: 'Indirect Speech: ',
                    style: bodyStyle.copyWith(
                      color: passiveVoiceColor(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(text: indirect),
                ],
              ),
            ),
          ],
          if (urdu.isNotEmpty) ...<Widget>[
            const SizedBox(height: 5),
            _BilingualText(
              text: urdu,
              style: bodyStyle.copyWith(height: 1.65),
            ),
          ],
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Full-page reference sheet for the Direct & Indirect Speech course lessons
/// (Statements, Tense/Pronoun/Time-Place Changes, Questions, Commands &
/// Requests). One fixed screen in image order: side-by-side purple/green
/// panels, conversion tables, direct→indirect rows, worked flows and summary
/// cards. No slides, no horizontal scrolling — vertical page scroll only.
/// Content comes from the lesson's `narrationSheet` map.
/// ─────────────────────────────────────────────────────────────────────────────
class _NarrationSheetView extends StatelessWidget {
  const _NarrationSheetView({required this.lesson});

  final GrammarLesson lesson;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data =
        lesson.narrationSheet ?? const <String, dynamic>{};
    final List<Map<String, dynamic>> sections = _narrationMaps(data['sections']);

    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
      children: <Widget>[
        for (int i = 0; i < sections.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == sections.length - 1 ? 0 : 8),
            child: _SheetSection(section: sections[i]),
          ),
        if (lesson.practice.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          GrammarSectionCard(
            icon: Icons.edit_note,
            title: 'Practice',
            child: Column(
              children: <Widget>[
                for (int i = 0; i < lesson.practice.length; i++)
                  PracticeQuestionCard(
                    question: lesson.practice[i],
                    index: i + 1,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// One outer rounded section of the sheet (e.g. "A — Commands and Requests").
class _SheetSection extends StatelessWidget {
  const _SheetSection({required this.section});

  final Map<String, dynamic> section;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = _sheetAccent((section['accent'] as String?) ?? 'blue');
    final String letter = (section['letter'] as String?) ?? '';
    final List<Map<String, dynamic>> blocks = _narrationMaps(section['blocks']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: accent.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(14),
        color: accent.withValues(alpha: 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (letter.isNotEmpty || (section['title'] as String?)?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: <Widget>[
                  if (letter.isNotEmpty) ...<Widget>[
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: <Color>[accent, accent.withValues(alpha: 0.6)],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        letter,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      (section['title'] as String?) ?? '',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          for (int i = 0; i < blocks.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == blocks.length - 1 ? 0 : 7),
              child: _SheetBlock(block: blocks[i]),
            ),
        ],
      ),
    );
  }
}

/// Accent colors shared by the sheet blocks (theme-aware where it matters).
Color _sheetAccent(String name) {
  switch (name) {
    case 'purple':
      return kGrammarHeadingPurple;
    case 'green':
      return const Color(0xFF10B981);
    case 'blue':
      return const Color(0xFF42A5F5);
    case 'red':
      return const Color(0xFFEF5350);
    case 'orange':
      return const Color(0xFFFB8C00);
    case 'yellow':
      return const Color(0xFFFDD835);
    case 'cyan':
      return const Color(0xFF26C6DA);
    case 'magenta':
      return const Color(0xFFEC407A);
  }
  return const Color(0xFF42A5F5);
}

/// Dispatches one block of the sheet to its renderer.
class _SheetBlock extends StatelessWidget {
  const _SheetBlock({required this.block});

  final Map<String, dynamic> block;

  @override
  Widget build(BuildContext context) {
    final String type = (block['type'] as String?) ?? 'text';
    switch (type) {
      case 'panels':
        return _SheetPanels(data: block);
      case 'items':
        return _SheetItems(data: block);
      case 'questionBlock':
        return _SheetQuestionBlock(data: block);
      case 'group':
        return _SheetGroup(data: block);
      case 'table':
        return _SheetTable(data: block);
      case 'rows':
        return _SheetRows(data: block);
      case 'truthRows':
        return _SheetTruthRows(data: block);
      case 'flow':
        return _SheetFlow(data: block);
      case 'exampleColumns':
        return _SheetExampleColumns(data: block);
      case 'checklist':
        return _SheetChecklist(data: block);
      case 'timeline':
        return _SheetTimeline(data: block);
      case 'note':
        return _SheetNote(data: block);
      case 'incorrectCorrect':
        return _SheetIncorrectCorrect(data: block);
      case 'changesCard':
        return _SheetChangesCard(data: block);
      case 'formulaCard':
        return _SheetFormulaCard(data: block);
      case 'urdu':
        return _SheetUrduLine(text: (block['text'] as String?) ?? '');
      case 'text':
        return _SheetSpansText(
          text: (block['text'] as String?) ?? '',
          color: _sheetAccent((block['accent'] as String?) ?? 'blue'),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Shared rich-text renderer: @@yellow@@, **bold** and __underline__ markup on
/// top of an explicit base color.
class _SheetSpansText extends StatelessWidget {
  const _SheetSpansText({required this.text, required this.color, this.style});

  final String text;
  final Color color;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = style ??
        Theme.of(context).textTheme.bodySmall?.copyWith(
              height: 1.35,
              fontSize: 11.5,
            ) ??
        const TextStyle();
    return Text.rich(
      TextSpan(
        style: base.copyWith(color: color),
        children: _boldMarkedSpans(
          text,
          color: color,
          highlightColor: highlightYellowColor(context),
        ),
      ),
    );
  }
}

/// RTL Urdu line (white text, optional size).
class _SheetUrduLine extends StatelessWidget {
  const _SheetUrduLine({required this.text, this.fontSize = 11});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Text(
        text,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: fontSize,
              height: 1.6,
            ),
      ),
    );
  }
}

/// A pair of side-by-side Direct (purple) / Indirect (green) panels.
class _SheetPanels extends StatelessWidget {
  const _SheetPanels({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> panels = _narrationMaps(data['columns']);
    if (panels.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < panels.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _SheetPanel(panel: panels[i])),
        ],
      ],
    );
  }
}

/// One Direct/Indirect panel: header bar + content rows.
class _SheetPanel extends StatelessWidget {
  const _SheetPanel({required this.panel});

  final Map<String, dynamic> panel;

  @override
  Widget build(BuildContext context) {
    final bool isIndirect =
        ((panel['kind'] as String?) ?? 'direct') == 'indirect';
    final Color accent = isIndirect ? _sheetAccent('green') : kGrammarHeadingPurple;
    final List<Map<String, dynamic>> rows = _narrationMaps(panel['rows']);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: accent.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SheetHeaderBox(title: (panel['title'] as String?) ?? '', accent: accent),
          Padding(
            padding: const EdgeInsets.all(7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (int i = 0; i < rows.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: i == rows.length - 1 ? 0 : 6),
                    child: _SheetPanelRow(row: rows[i], accent: accent),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The colored header bar of a Direct/Indirect panel.
class _SheetHeaderBox extends StatelessWidget {
  const _SheetHeaderBox({required this.title, required this.accent});

  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: accent.withValues(alpha: 0.22),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: <Widget>[
          Icon(
            accent == kGrammarHeadingPurple ? Icons.volume_up : Icons.volume_down,
            size: 14,
            color: accent,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One content row inside a Direct/Indirect panel:
/// label, bullets, urdu, example, formula or text.
class _SheetPanelRow extends StatelessWidget {
  const _SheetPanelRow({required this.row, required this.accent});

  final Map<String, dynamic> row;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String kind = (row['kind'] as String?) ?? 'text';
    final TextStyle bodyStyle = theme.textTheme.bodySmall?.copyWith(
          height: 1.35,
          fontSize: 11,
          color: scheme.onSurface,
        ) ??
        const TextStyle();

    switch (kind) {
      case 'label':
        return Row(
          children: <Widget>[
            Icon(
              (row['icon'] as String?) == 'bulb'
                  ? Icons.lightbulb_outline
                  : Icons.menu_book_outlined,
              size: 13,
              color: accent,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                (row['text'] as String?) ?? '',
                style: bodyStyle.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        );
      case 'bullets':
        final List<String> items =
            ((row['items'] as List<dynamic>?) ?? const <dynamic>[])
                .map((dynamic e) => e.toString())
                .toList(growable: false);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final String item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(top: 5, right: 6),
                      decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                    ),
                    Expanded(
                      child: _SheetSpansText(text: item, color: scheme.onSurface, style: bodyStyle),
                    ),
                  ],
                ),
              ),
          ],
        );
      case 'urdu':
        return _SheetUrduLine(text: (row['text'] as String?) ?? '');
      case 'example':
        final List<Map<String, dynamic>> examples = _narrationMaps(row['items']);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int i = 0; i < examples.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: i == examples.length - 1 ? 0 : 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 6, right: 6),
                        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                      ),
                      Expanded(
                        child: _SheetSpansText(
                          text: examples[i]['text'] as String? ?? '',
                          color: scheme.onSurface,
                          style: bodyStyle,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      case 'formula':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: accent.withValues(alpha: 0.55)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _SheetSpansText(
            text: (row['text'] as String?) ?? '',
            color: scheme.onSurface,
            style: bodyStyle.copyWith(fontWeight: FontWeight.w800, fontSize: 11.5),
          ),
        );
      default:
        return _SheetSpansText(
          text: (row['text'] as String?) ?? '',
          color: scheme.onSurface,
          style: bodyStyle,
        );
    }
  }
}

/// Side-by-side formula/why cards (e.g. "Why this formula?" + "Formula:").
class _SheetItems extends StatelessWidget {
  const _SheetItems({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = _narrationMaps(data['items']);
    if (items.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < items.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 7),
          Expanded(child: _SheetItemCard(item: items[i])),
        ],
      ],
    );
  }
}

/// One bordered card with a bold colored title and rich-text body.
class _SheetItemCard extends StatelessWidget {
  const _SheetItemCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color accent = _sheetAccent((item['accent'] as String?) ?? 'yellow');
    final String title = (item['title'] as String?) ?? '';
    final String text = (item['text'] as String?) ?? '';
    final List<String> lines =
        ((item['lines'] as List<dynamic>?) ?? const <dynamic>[])
            .map((dynamic e) => e.toString())
            .toList(growable: false);
    final String urdu = (item['urdu'] as String?) ?? '';

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: accent.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(9),
        color: accent.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                (item['icon'] as String?) == 'gear'
                    ? Icons.settings_outlined
                    : Icons.description_outlined,
                size: 12,
                color: accent,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
          if (text.isNotEmpty) ...<Widget>[
            const SizedBox(height: 3),
            _SheetSpansText(
              text: text,
              color: scheme.onSurface,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.35,
                fontSize: 10.5,
                color: scheme.onSurface,
              ),
            ),
          ],
          for (final String line in lines)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _SheetSpansText(
                text: line,
                color: scheme.onSurface,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.35,
                  fontSize: 10.5,
                  color: scheme.onSurface,
                ),
              ),
            ),
          if (urdu.isNotEmpty) _SheetUrduLine(text: urdu, fontSize: 10.5),
        ],
      ),
    );
  }
}

/// Numbered question block: title, Urdu, Direct box → Indirect box, and the
/// orange numbered "Changes" card beside it (Yes/No & WH question lessons).
class _SheetQuestionBlock extends StatelessWidget {
  const _SheetQuestionBlock({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color accent = _sheetAccent((data['accent'] as String?) ?? 'magenta');
    final String heading = (data['heading'] as String?) ?? '';
    final String urdu = (data['urdu'] as String?) ?? '';
    final String direct = (data['direct'] as String?) ?? '';
    final String indirect = (data['indirect'] as String?) ?? '';
    final List<String> changes =
        ((data['changes'] as List<dynamic>?) ?? const <dynamic>[])
            .map((dynamic e) => e.toString())
            .toList(growable: false);
    final TextStyle? bodyStyle = theme.textTheme.bodySmall?.copyWith(
      height: 1.35,
      fontSize: 11.5,
      color: scheme.onSurface,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: changes.isEmpty ? 1 : 3,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  border: Border.all(color: accent.withValues(alpha: 0.55)),
                  borderRadius: BorderRadius.circular(9),
                  color: accent.withValues(alpha: 0.07),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      heading,
                      style: bodyStyle?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (urdu.isNotEmpty)
                      Text(
                        urdu,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: bodyStyle?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 10.5,
                          height: 1.55,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (changes.isNotEmpty) ...<Widget>[
              const SizedBox(width: 8),
              Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  border: Border.all(color: _sheetAccent('orange').withValues(alpha: 0.6)),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.settings_outlined,
                            size: 12, color: _sheetAccent('yellow')),
                        const SizedBox(width: 5),
                        Text(
                          'Changes',
                          style: bodyStyle?.copyWith(
                            color: _sheetAccent('yellow'),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    for (int i = 0; i < changes.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 13,
                              height: 13,
                              decoration: const BoxDecoration(
                                color: _SheetColors.amber,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${i + 1}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 8.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _SheetSpansText(
                                text: changes[i],
                                color: scheme.onSurface,
                                style: bodyStyle?.copyWith(fontSize: 10.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            ],
          ],
        ),
        const SizedBox(height: 7),
        _SheetHeaderBox(title: 'Direct Speech', accent: kGrammarHeadingPurple),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: kGrammarHeadingPurple.withValues(alpha: 0.5)),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
          child: _SheetSpansText(text: direct, color: scheme.onSurface, style: bodyStyle),
        ),
        Center(
          child: Icon(Icons.arrow_downward, size: 16, color: accent),
        ),
        _SheetHeaderBox(title: 'Indirect Speech', accent: _sheetAccent('green')),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: _sheetAccent('green').withValues(alpha: 0.5)),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
          child: _SheetSpansText(
            text: indirect,
            color: scheme.onSurface,
            style: bodyStyle,
          ),
        ),
      ],
    );
  }
}

/// Fixed accent colors used by the sheet widgets.
abstract final class _SheetColors {
  static const Color amber = Color(0xFFFDD835);
  static const Color magenta = Color(0xFFEC407A);
  static const Color pink = Color(0xFFF06292);
  static const Color sky = Color(0xFF4FC3F7);
  static const Color green = Color(0xFF10B981);
  static const Color red = Color(0xFFEF5350);
  static const Color orange = Color(0xFFFB8C00);
}

/// Inner rounded group with a bold colored heading ("Changes Shown",
/// "Said vs Told", "More Examples", "Time and Place Changes Table"…).
class _SheetGroup extends StatelessWidget {
  const _SheetGroup({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = _sheetAccent((data['accent'] as String?) ?? 'blue');
    final String title = (data['title'] as String?) ?? '';
    final String? titleSuffix = (data['titleSuffix'] as String?);
    final String? note = (data['note'] as String?);
    final List<Map<String, dynamic>> blocks = _narrationMaps(data['blocks']);
    final IconData icon = switch (data['icon'] as String?) {
      'gear' => Icons.settings_outlined,
      'bulb' => Icons.lightbulb_outline,
      'book' => Icons.menu_book_outlined,
      'people' => Icons.people_outline,
      'chat' => Icons.chat_bubble_outline,
      'doc' => Icons.article_outlined,
      _ => Icons.settings_outlined,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: accent.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(10),
        color: accent.withValues(alpha: 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: <Widget>[
                  Icon(icon, size: 15, color: accent),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        text: title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                        children: <InlineSpan>[
                          if (titleSuffix != null)
                            TextSpan(
                              text: ' $titleSuffix',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (note != null && note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _SheetSpansText(
                text: note,
                color: theme.colorScheme.onSurface,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.35,
                  fontSize: 11,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          for (int i = 0; i < blocks.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == blocks.length - 1 ? 0 : 7),
              child: _SheetBlock(block: blocks[i]),
            ),
        ],
      ),
    );
  }
}

/// Conversion table with a purple/green two-tone header and an arrow column.
class _SheetTable extends StatelessWidget {
  const _SheetTable({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color leftAccent = _sheetAccent((data['leftAccent'] as String?) ?? 'purple');
    final Color rightAccent = _sheetAccent((data['rightAccent'] as String?) ?? 'green');
    final List<String> headers =
        ((data['headers'] as List<dynamic>?) ?? const <dynamic>[])
            .map((dynamic e) => e.toString())
            .toList(growable: false);
    final List<Map<String, dynamic>> rows = _narrationMaps(data['rows']);
    final TextStyle? bodyStyle = theme.textTheme.bodySmall?.copyWith(
      height: 1.3,
      fontSize: 11,
      color: scheme.onSurface,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          if (headers.isNotEmpty)
            Container(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 3,
                    child: Text(
                      headers[0],
                      textAlign: TextAlign.center,
                      style: bodyStyle?.copyWith(
                        color: leftAccent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 26),
                  Expanded(
                    flex: 3,
                    child: Text(
                      headers.length > 1 ? headers[1] : '',
                      textAlign: TextAlign.center,
                      style: bodyStyle?.copyWith(
                        color: rightAccent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (headers.length > 2)
                    Expanded(
                      flex: 3,
                      child: Text(
                        headers[2],
                        textAlign: TextAlign.center,
                        style: bodyStyle?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0)
              Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.35)),
            _SheetTableRow(
              row: rows[i],
              leftAccent: leftAccent,
              rightAccent: rightAccent,
              bodyStyle: bodyStyle,
            ),
          ],
        ],
      ),
    );
  }
}

/// One data row of a conversion table (left word → right word [+ why]).
class _SheetTableRow extends StatelessWidget {
  const _SheetTableRow({
    required this.row,
    required this.leftAccent,
    required this.rightAccent,
    required this.bodyStyle,
  });

  final Map<String, dynamic> row;
  final Color leftAccent;
  final Color rightAccent;
  final TextStyle? bodyStyle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String left = (row['left'] as String?) ?? '';
    final String right = (row['right'] as String?) ?? '';
    final String why = (row['why'] as String?) ?? '';
    final bool numbered = row['numbered'] == true;
    final int? number = (row['number'] as num?)?.toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: <Widget>[
          if (numbered)
            Container(
              width: 15,
              height: 15,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: leftAccent,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${number ?? 0}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                ),
              ),
            ),
          Expanded(
            flex: 3,
            child: Text(
              left,
              style: bodyStyle?.copyWith(
                color: leftAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 26,
            child: Icon(
              Icons.arrow_forward,
              size: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              right,
              style: bodyStyle?.copyWith(
                color: rightAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (why.isNotEmpty)
            Expanded(
              flex: 3,
              child: Text(
                why,
                style: bodyStyle?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Numbered Direct → Indirect rows (speech examples with color-coded parts).
class _SheetRows extends StatelessWidget {
  const _SheetRows({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> rows = _narrationMaps(data['rows']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < rows.length; i++)
          _SheetExampleRow(
            row: rows[i],
            index: i + 1,
          ),
      ],
    );
  }
}

/// One numbered Direct → Indirect example row with an arrow between.
class _SheetExampleRow extends StatelessWidget {
  const _SheetExampleRow({required this.row, required this.index});

  final Map<String, dynamic> row;
  final int index;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextStyle? bodyStyle = theme.textTheme.bodySmall?.copyWith(
      height: 1.3,
      fontSize: 10.5,
      color: scheme.onSurface,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.only(right: 6),
            decoration: const BoxDecoration(
              color: kGrammarHeadingPurple,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 9,
              ),
            ),
          ),
          Expanded(
            child: _SheetSpansText(
              text: (row['direct'] as String?) ?? '',
              color: scheme.onSurface,
              style: bodyStyle,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.arrow_forward,
              size: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: _SheetSpansText(
              text: (row['indirect'] as String?) ?? '',
              color: scheme.onSurface,
              style: bodyStyle,
            ),
          ),
        ],
      ),
    );
  }
}

/// When-Tense-Does-Not-Change rows (No. | name | direct → indirect).
class _SheetTruthRows extends StatelessWidget {
  const _SheetTruthRows({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> rows = _narrationMaps(data['rows']);
    return Column(
      children: <Widget>[
        for (int i = 0; i < rows.length; i++)
          _SheetTruthRow(row: rows[i], index: i + 1),
      ],
    );
  }
}

/// One truth row of the "when tense does not change" table.
class _SheetTruthRow extends StatelessWidget {
  const _SheetTruthRow({required this.row, required this.index});

  final Map<String, dynamic> row;
  final int index;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextStyle? bodyStyle = theme.textTheme.bodySmall?.copyWith(
      height: 1.3,
      fontSize: 10.5,
      color: scheme.onSurface,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 15,
            height: 15,
            margin: const EdgeInsets.only(top: 1, right: 6),
            decoration: const BoxDecoration(
              color: _SheetColors.sky,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 9,
              ),
            ),
          ),
          SizedBox(
            width: 118,
            child: Text(
              (row['name'] as String?) ?? '',
              style: bodyStyle?.copyWith(
                color: _SheetColors.magenta,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: _SheetSpansText(
              text: (row['direct'] as String?) ?? '',
              color: scheme.onSurface,
              style: bodyStyle,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.arrow_forward,
              size: 12,
              color: _SheetColors.orange,
            ),
          ),
          Expanded(
            flex: 3,
            child: _SheetSpansText(
              text: (row['indirect'] as String?) ?? '',
              color: scheme.onSurface,
              style: bodyStyle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Direct box → Changes list → Indirect box (horizontal conversion flow).
class _SheetFlow extends StatelessWidget {
  const _SheetFlow({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String direct = (data['direct'] as String?) ?? '';
    final String indirect = (data['indirect'] as String?) ?? '';
    final List<String> changes =
        ((data['changes'] as List<dynamic>?) ?? const <dynamic>[])
            .map((dynamic e) => e.toString())
            .toList(growable: false);
    final TextStyle? bodyStyle = theme.textTheme.bodySmall?.copyWith(
      height: 1.35,
      fontSize: 10.5,
      color: scheme.onSurface,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          flex: 4,
          child: _SheetMiniPanel(
            title: 'Direct Speech',
            accent: kGrammarHeadingPurple,
            child: _SheetSpansText(text: direct, color: scheme.onSurface, style: bodyStyle),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Icon(Icons.arrow_forward, size: 14, color: _sheetAccent('blue')),
        ),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              border: Border.all(color: _sheetAccent('orange').withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Changes',
                  style: bodyStyle?.copyWith(
                    color: _sheetAccent('yellow'),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                for (int i = 0; i < changes.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(right: 5),
                          decoration: const BoxDecoration(
                            color: _SheetColors.amber,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${i + 1}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 8,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _SheetSpansText(
                            text: changes[i],
                            color: scheme.onSurface,
                            style: bodyStyle?.copyWith(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Icon(Icons.arrow_forward, size: 14, color: _sheetAccent('blue')),
        ),
        Expanded(
          flex: 4,
          child: _SheetMiniPanel(
            title: 'Indirect Speech',
            accent: _sheetAccent('green'),
            child: _SheetSpansText(text: indirect, color: scheme.onSurface, style: bodyStyle),
          ),
        ),
      ],
    );
  }
}

/// Small titled box used inside conversion flows.
class _SheetMiniPanel extends StatelessWidget {
  const _SheetMiniPanel({
    required this.title,
    required this.accent,
    required this.child,
  });

  final String title;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: accent.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(9),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SheetHeaderBox(title: title, accent: accent),
          Padding(
            padding: const EdgeInsets.all(7),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Two side-by-side example columns (Example 1 | Example 2, each with a
/// Direct box, a Changes list and an Indirect box).
class _SheetExampleColumns extends StatelessWidget {
  const _SheetExampleColumns({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> examples = _narrationMaps(data['examples']);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < examples.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _SheetExampleCard(example: examples[i], index: i + 1)),
        ],
      ],
    );
  }
}

/// One worked example column: title, Direct box, Changes, Indirect box.
class _SheetExampleCard extends StatelessWidget {
  const _SheetExampleCard({required this.example, required this.index});

  final Map<String, dynamic> example;
  final int index;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextStyle? bodyStyle = theme.textTheme.bodySmall?.copyWith(
      height: 1.35,
      fontSize: 10.5,
      color: scheme.onSurface,
    );
    final List<Map<String, dynamic>> changes = _narrationMaps(example['changes']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(Icons.format_quote, size: 14, color: _sheetAccent('blue')),
            const SizedBox(width: 5),
            Text(
              (example['title'] as String?) ?? 'Example $index',
              style: theme.textTheme.titleSmall?.copyWith(
                color: _sheetAccent('blue'),
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        _SheetHeaderBox(title: 'Direct Speech', accent: kGrammarHeadingPurple),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            border: Border.all(color: kGrammarHeadingPurple.withValues(alpha: 0.5)),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(9),
              bottomRight: Radius.circular(9),
            ),
          ),
          child: _SheetSpansText(
            text: (example['direct'] as String?) ?? '',
            color: scheme.onSurface,
            style: bodyStyle,
          ),
        ),
        const SizedBox(height: 5),
        Center(
          child: Icon(Icons.arrow_downward, size: 14, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            border: Border.all(color: _SheetColors.red.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Changes',
                style: bodyStyle?.copyWith(
                  color: _SheetColors.red,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              for (final Map<String, dynamic> change in changes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 6, right: 5),
                        decoration: const BoxDecoration(
                          color: _SheetColors.pink,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: _SheetSpansText(
                          text:
                              '${change['from'] ?? ''} → ${change['to'] ?? ''}${change['why'] == null ? '' : '  (${change['why']})'}',
                          color: scheme.onSurface,
                          style: bodyStyle?.copyWith(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Center(
          child: Icon(Icons.arrow_downward, size: 14, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 5),
        _SheetHeaderBox(title: 'Indirect Speech', accent: _sheetAccent('green')),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            border: Border.all(color: _sheetAccent('green').withValues(alpha: 0.5)),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(9),
              bottomRight: Radius.circular(9),
            ),
          ),
          child: _SheetSpansText(
            text: (example['indirect'] as String?) ?? '',
            color: scheme.onSurface,
            style: bodyStyle,
          ),
        ),
      ],
    );
  }
}

/// Final conversion checklist (two columns of numbered items).
class _SheetChecklist extends StatelessWidget {
  const _SheetChecklist({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final List<String> items =
        ((data['items'] as List<dynamic>?) ?? const <dynamic>[])
            .map((dynamic e) => e.toString())
            .toList(growable: false);
    final int half = (items.length / 2).ceil();
    final List<String> left = items.take(half).toList(growable: false);
    final List<String> right = items.skip(half).toList(growable: false);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: _SheetChecklistColumn(items: left, startIndex: 1)),
        const SizedBox(width: 10),
        Expanded(
          child: _SheetChecklistColumn(items: right, startIndex: half + 1),
        ),
      ],
    );
  }
}

/// One column of the conversion checklist.
class _SheetChecklistColumn extends StatelessWidget {
  const _SheetChecklistColumn({required this.items, required this.startIndex});

  final List<String> items;
  final int startIndex;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 15,
                  height: 15,
                  margin: const EdgeInsets.only(top: 1, right: 6),
                  decoration: const BoxDecoration(
                    color: _SheetColors.sky,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${startIndex + i}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                    ),
                  ),
                ),
                Expanded(
                  child: _SheetSpansText(
                    text: items[i],
                    color: scheme.onSurface,
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.3,
                      fontSize: 10.5,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// yesterday → today → tomorrow timeline chips.
class _SheetTimeline extends StatelessWidget {
  const _SheetTimeline({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> steps = _narrationMaps(data['steps']);
    return Row(
      children: <Widget>[
        for (int i = 0; i < steps.length; i++) ...<Widget>[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.trending_flat, size: 18, color: _SheetColors.amber),
            ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                color: _SheetColors.pink.withValues(alpha: 0.2),
                border: Border.all(color: _SheetColors.pink.withValues(alpha: 0.6)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: <Widget>[
                  Text(
                    (steps[i]['title'] as String?) ?? '',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                  ),
                  if ((steps[i]['urdu'] as String?)?.isNotEmpty == true)
                    Text(
                      steps[i]['urdu'] as String,
                      textDirection: TextDirection.rtl,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white70,
                            fontSize: 9.5,
                          ),
                    ),
                  Text(
                    (steps[i]['label'] as String?) ?? '',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 9.5,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Important Note / Remember strip with red accent and Urdu support.
class _SheetNote extends StatelessWidget {
  const _SheetNote({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color accent = _sheetAccent((data['accent'] as String?) ?? 'red');
    final String title = (data['title'] as String?) ?? 'Important Note';
    final List<Map<String, dynamic>> rows = _narrationMaps(data['rows']);
    final String urdu = (data['urdu'] as String?) ?? '';
    final TextStyle? bodyStyle = theme.textTheme.bodySmall?.copyWith(
      height: 1.35,
      fontSize: 10.5,
      color: scheme.onSurface,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.star, size: 15, color: accent),
              const SizedBox(width: 6),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (final Map<String, dynamic> row in rows)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.only(top: 6, right: 6),
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: _SheetSpansText(
                                text: (row['text'] as String?) ?? '',
                                color: scheme.onSurface,
                                style: bodyStyle,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (urdu.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (final String line in urdu.split('\n'))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.only(top: 6, right: 6),
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  line,
                                  textDirection: TextDirection.rtl,
                                  style: bodyStyle?.copyWith(height: 1.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Incorrect / Correct comparison strip.
class _SheetIncorrectCorrect extends StatelessWidget {
  const _SheetIncorrectCorrect({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String incorrect = (data['incorrect'] as String?) ?? '';
    final String correct = (data['correct'] as String?) ?? '';
    final TextStyle? bodyStyle = theme.textTheme.bodySmall?.copyWith(
      height: 1.35,
      fontSize: 11,
      color: scheme.onSurface,
    );

    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: _SheetColors.red.withValues(alpha: 0.12),
            border: Border.all(color: _SheetColors.red.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.cancel, size: 15, color: _SheetColors.red),
              const SizedBox(width: 7),
              Text(
                'Incorrect:',
                style: bodyStyle?.copyWith(
                  color: _SheetColors.red,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SheetSpansText(
                  text: incorrect,
                  color: scheme.onSurface,
                  style: bodyStyle,
                ),
              ),
              Icon(Icons.close, size: 16, color: _SheetColors.red),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: _SheetColors.green.withValues(alpha: 0.12),
            border: Border.all(color: _SheetColors.green.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.check_circle, size: 15, color: _SheetColors.green),
              const SizedBox(width: 7),
              Text(
                'Correct:',
                style: bodyStyle?.copyWith(
                  color: _SheetColors.green,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SheetSpansText(
                  text: correct,
                  color: scheme.onSurface,
                  style: bodyStyle,
                ),
              ),
              Icon(Icons.check, size: 16, color: _SheetColors.green),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Said vs Told"-style two-column comparison (purple card | green card).
class _SheetChangesCard extends StatelessWidget {
  const _SheetChangesCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final List<Map<String, dynamic>> cards = _narrationMaps(data['cards']);
    final TextStyle? bodyStyle = theme.textTheme.bodySmall?.copyWith(
      height: 1.35,
      fontSize: 10.5,
      color: scheme.onSurface,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < cards.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Builder(
              builder: (BuildContext context) {
                final Map<String, dynamic> card = cards[i];
                final Color accent =
                    _sheetAccent((card['accent'] as String?) ?? 'purple');
                final List<String> items =
                    ((card['items'] as List<dynamic>?) ?? const <dynamic>[])
                        .map((dynamic e) => e.toString())
                        .toList(growable: false);
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: accent.withValues(alpha: 0.55)),
                    borderRadius: BorderRadius.circular(9),
                    color: accent.withValues(alpha: 0.06),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(Icons.person_outline, size: 13, color: accent),
                          const SizedBox(width: 5),
                          Expanded(
                            child: _SheetSpansText(
                              text: (card['title'] as String?) ?? '',
                              color: accent,
                              style: bodyStyle?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      for (final String item in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.only(top: 6, right: 6),
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: _SheetSpansText(
                                  text: item,
                                  color: scheme.onSurface,
                                  style: bodyStyle,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// Big bordered formula box (e.g. "asked + wh-word + subject + verb").
class _SheetFormulaCard extends StatelessWidget {
  const _SheetFormulaCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color accent = _sheetAccent((data['accent'] as String?) ?? 'blue');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: accent.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(10),
        color: accent.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.description_outlined, size: 14, color: accent),
              const SizedBox(width: 6),
              Text(
                (data['title'] as String?) ?? 'Formula',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          _SheetSpansText(
            text: (data['text'] as String?) ?? '',
            color: scheme.onSurface,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
