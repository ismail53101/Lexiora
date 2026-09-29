import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/core/widgets/error_view.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_lesson.dart';
import 'package:lexiora/modules/grammar/presentation/pages/lesson_page.dart';
import 'package:lexiora/modules/grammar/presentation/providers/grammar_providers.dart';
import 'package:lexiora/modules/grammar/presentation/widgets/grammar_section_card.dart';

class TypeDetailPage extends ConsumerWidget {
  const TypeDetailPage({
    super.key,
    required this.lessonId,
    required this.typeName,
  });

  final String lessonId;
  final String typeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<GrammarLesson?> lessonAsync =
        ref.watch(grammarLeafProvider(lessonId));

    return Scaffold(
      appBar: AppBar(
        title: Text(typeName, overflow: TextOverflow.ellipsis),
      ),
      body: lessonAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) => ErrorView(
          title: 'Could not open noun type',
          message: 'Something went wrong loading this section.',
          onRetry: () => ref.invalidate(grammarLeafProvider(lessonId)),
        ),
        data: (GrammarLesson? lesson) {
          if (lesson == null) {
            return const EmptyState(
              icon: Icons.search_off,
              title: 'Section not found',
              message: 'This noun section is not available offline.',
            );
          }

          GrammarType? selected;
          for (final GrammarType type in <GrammarType>[
            ...lesson.types,
            ...lesson.additionalTypes,
            ...lesson.degreeTypes,
          ]) {
            selected = _findGrammarType(type, typeName);
            if (selected != null) break;
          }

          if (selected == null) {
            return const EmptyState(
              icon: Icons.search_off,
              title: 'Section not found',
              message: 'This noun section is not available offline.',
            );
          }

          if (selected.childTypes.isNotEmpty) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: <Widget>[
                GrammarSectionCard(
                  icon: Icons.account_tree_outlined,
                  title: selected.name,
                  child: Column(
                    children: <Widget>[
                      for (final GrammarType child in selected.childTypes)
                        _NestedGrammarFolder(
                          title: child.name,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => TypeDetailPage(
                                lessonId: lessonId,
                                typeName: child.name,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: <Widget>[
              GrammarSectionCard(
                icon: Icons.account_tree_outlined,
                title: selected.name,
                child: GrammarTypeContent(type: selected),
              ),
            ],
          );
        },
      ),
    );
  }
}

GrammarType? _findGrammarType(GrammarType type, String name) {
  if (type.name == name) return type;
  for (final GrammarType child in type.childTypes) {
    final GrammarType? found = _findGrammarType(child, name);
    if (found != null) return found;
  }
  return null;
}

class _NestedGrammarFolder extends StatelessWidget {
  const _NestedGrammarFolder({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: <Widget>[
              Icon(Icons.folder_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
