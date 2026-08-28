import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_topic.dart';
import 'package:lexiora/modules/grammar/presentation/providers/grammar_providers.dart';
import 'package:lexiora/modules/grammar/presentation/widgets/grammar_topic_tile.dart';

/// A category / subcategory screen: lists the children of a branch node. Tapping
/// a branch drills deeper; tapping a leaf opens its dedicated lesson.
class TopicPage extends ConsumerWidget {
  const TopicPage({super.key, required this.topicId});

  final String topicId;

  void _open(BuildContext context, GrammarTopicSummary t) {
    if (t.isLeaf) {
      context.push(AppRoutes.grammarLesson(t.id));
    } else {
      context.push(AppRoutes.grammarTopic(t.id));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String title = ref.watch(grammarTopicTitleProvider(topicId)).maybeWhen(
          data: (String? t) => t ?? 'Grammar',
          orElse: () => 'Grammar',
        );
    final AsyncValue<List<GrammarTopicSummary>> children =
        ref.watch(grammarChildrenProvider(topicId));

    return Scaffold(
      appBar: AppBar(title: Text(title, overflow: TextOverflow.ellipsis)),
      body: children.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const EmptyState(
          icon: Icons.error_outline,
          title: 'Could not open topic',
          message: 'Please try again.',
        ),
        data: (List<GrammarTopicSummary> list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.inbox_outlined,
              title: 'Nothing here yet',
              message: 'This topic has no lessons yet.',
            );
          }
          final bool isTensesOverview = topicId == 'tenses';
          final bool isPhrasesFolder = topicId == 'phrases';
          final bool isClausesFolder = topicId == 'clauses';
          final bool isConditionalsFolder = topicId == 'conditional-sentences';
          final int extraItems = (isTensesOverview ? 1 : 0) +
              (isPhrasesFolder ? 1 : 0) +
              (isClausesFolder ? 1 : 0) +
              (isConditionalsFolder ? 1 : 0);
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: list.length + extraItems,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int i) {
              if (isPhrasesFolder && i == 0) {
                return const _PhraseIntroduction();
              }
              if (isClausesFolder && i == 0) {
                return const _ClauseIntroduction();
              }
              if (isConditionalsFolder && i == 0) {
                return const _ConditionalIntroduction();
              }
              final int topicIndex = (isPhrasesFolder || isClausesFolder || isConditionalsFolder) ? i - 1 : i;
              if (isTensesOverview && topicIndex == list.length) {
                return const _TensesReferenceImage();
              }
              return GrammarTopicTile(
                topic: list[topicIndex],
                onTap: () => _open(context, list[topicIndex]),
              );
            },
          );
        },
      ),
    );
  }
}

class _PhraseIntroduction extends StatelessWidget {
  const _PhraseIntroduction();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle body = theme.textTheme.bodyMedium ?? const TextStyle();
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Phrase', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Definition', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('English:', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Text('A phrase is a group of words that works together as a unit but does not express a complete thought by itself.', style: body),
            const SizedBox(height: 10),
            Text('Urdu:', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                'Phrase (فقرہ) الفاظ کا ایسا مجموعہ ہے جو جملے میں ایک اکائی کے طور پر کام کرتا ہے، لیکن اکیلا مکمل خیال بیان نہیں کرتا۔',
                textAlign: TextAlign.right,
                style: body.copyWith(height: 1.7),
              ),
            ),
            const SizedBox(height: 12),
            Text('Examples', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('in the morning — صبح کے وقت\na beautiful girl — ایک خوبصورت لڑکی\nafter the class — کلاس کے بعد', style: body),
            const SizedBox(height: 12),
            Text('Quick Tip', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('A phrase adds meaning or detail to a sentence but cannot normally stand alone as a complete sentence.', style: body),
          ],
        ),
      ),
    );
  }
}

class _ClauseIntroduction extends StatelessWidget {
  const _ClauseIntroduction();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle body = theme.textTheme.bodyMedium ?? const TextStyle();
    final TextStyle heading = theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ) ??
        const TextStyle(fontWeight: FontWeight.bold);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Clause', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Definition', style: heading),
            const SizedBox(height: 6),
            Text('English:', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Text('A clause is a group of words that contains a subject and a verb and forms part of a sentence.', style: body),
            const SizedBox(height: 10),
            Text('Urdu:', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                'Clause (جملے کا جز) الفاظ کا ایسا مجموعہ ہے جس میں عموماً Subject اور Verb ہوتے ہیں اور جو جملے کا ایک حصہ ہوتا ہے۔',
                textAlign: TextAlign.right,
                style: body.copyWith(height: 1.7),
              ),
            ),
            const SizedBox(height: 12),
            Text('Examples', style: heading),
            const SizedBox(height: 4),
            Text(
              'She is studying for the exam.\nI know that he is honest.\nWhen the rain stopped, we went outside.',
              style: body.copyWith(color: const Color(0xFF64B5F6)),
            ),
            const SizedBox(height: 12),
            Text('Quick Tip', style: heading),
            const SizedBox(height: 4),
            Text('Clause = Subject + Verb', style: body.copyWith(color: const Color(0xFF64B5F6), fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text('Types of Clauses', style: heading),
            const SizedBox(height: 4),
            Text('Clauses are mainly divided into:', style: body),
            const SizedBox(height: 4),
            Text('Independent Clause — can express a complete thought by itself.\nDependent Clause — cannot express a complete thought by itself.', style: body),
            const SizedBox(height: 8),
            Text('Example:', style: theme.textTheme.labelLarge?.copyWith(color: const Color(0xFF42A5F5), fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Text('She went home because she was tired.\nShe went home → Independent Clause\nshe was tired → Dependent Clause', style: body.copyWith(color: const Color(0xFF64B5F6))),
          ],
        ),
      ),
    );
  }
}

class _ConditionalIntroduction extends StatelessWidget {
  const _ConditionalIntroduction();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle body = theme.textTheme.bodyMedium ?? const TextStyle();
    final TextStyle heading = theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ) ??
        const TextStyle(fontWeight: FontWeight.bold);
    const Color exampleColor = Color(0xFF64B5F6);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Conditional Sentences', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Definition', style: heading),
            const SizedBox(height: 6),
            Text('A conditional sentence is a sentence that shows a condition and its result. The result depends on whether the condition is met.', style: body),
            const SizedBox(height: 10),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                'Conditional Sentence (شرطیہ جملہ) ایسا جملہ ہے جس میں ایک شرط اور اس کا نتیجہ بیان کیا جاتا ہے۔ نتیجہ اس بات پر منحصر ہوتا ہے کہ شرط پوری ہوتی ہے یا نہیں۔',
                textAlign: TextAlign.right,
                style: body.copyWith(height: 1.7),
              ),
            ),
            const SizedBox(height: 12),
            Text('Examples', style: heading),
            const SizedBox(height: 4),
            Text(
              'If you study hard, you will pass the exam.\nIf it rains, we will stay at home.',
              style: body.copyWith(color: exampleColor, height: 1.45),
            ),
            const SizedBox(height: 4),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                'اگر تم محنت سے پڑھو گے تو امتحان پاس کر لو گے۔\nاگر بارش ہوئی تو ہم گھر پر رہیں گے۔',
                textAlign: TextAlign.right,
                style: body.copyWith(color: exampleColor, height: 1.7),
              ),
            ),
            const SizedBox(height: 12),
            Text('Basic Structure', style: heading),
            const SizedBox(height: 4),
            Text('If + Condition, Result', style: body.copyWith(color: exampleColor, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text('Example', style: heading),
            const SizedBox(height: 4),
            Text(
              'If you study hard, you will pass the exam.\nIf you study hard → Condition\nyou will pass the exam → Result',
              style: body.copyWith(color: exampleColor),
            ),
            const SizedBox(height: 12),
            Text('Types of Conditional Sentences', style: heading),
            const SizedBox(height: 4),
            Text('Zero Conditional, First Conditional, Second Conditional, Third Conditional, and Mixed Conditional.', style: body),
          ],
        ),
      ),
    );
  }
}

class _TensesReferenceImage extends StatefulWidget {
  const _TensesReferenceImage();

  @override
  State<_TensesReferenceImage> createState() => _TensesReferenceImageState();
}

class _TensesReferenceImageState extends State<_TensesReferenceImage> {
  final TransformationController _controller = TransformationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: GestureDetector(
          onDoubleTap: () {
            if (_controller.value != Matrix4.identity()) {
              _controller.value = Matrix4.identity();
            } else {
              _controller.value = Matrix4.identity()..scale(2.0);
            }
          },
          child: InteractiveViewer(
            transformationController: _controller,
            minScale: 1,
            maxScale: 4,
            child: Image.asset(
              'assets/grammar/images/english_tenses_at_a_glance.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
