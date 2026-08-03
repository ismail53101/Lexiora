import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/di/injector.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/constants/app_constants.dart';
import 'package:lexiora/core/navigation/home_destination.dart';
import 'package:lexiora/core/usecase/usecase.dart';
import 'package:lexiora/core/utils/result.dart';
import 'package:lexiora/core/widgets/app_bottom_nav.dart';
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/features/library/domain/entities/library_document.dart';
import 'package:lexiora/features/library/domain/usecases/library_usecases.dart';
import 'package:lexiora/features/library/presentation/providers/library_providers.dart';
import 'package:lexiora/features/library/presentation/widgets/document_card.dart';
import 'package:lexiora/modules/study_hub/domain/entities/study_goal.dart';
import 'package:lexiora/modules/study_hub/presentation/providers/study_hub_providers.dart';

/// The Home dashboard: a personal greeting, quick search, Recent Documents,
/// Explore module list, Today's Goal, and Import PDF — the app's landing tab.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<LibraryDocument>> all =
        ref.watch(allDocumentsProvider);
    final AsyncValue<List<LibraryEntry>> continueReading =
        ref.watch(continueReadingProvider);
    final AsyncValue<List<LibraryDocument>> recent =
        ref.watch(recentDocumentsProvider);
    final AsyncValue<List<LibraryDocument>> favorites =
        ref.watch(favoriteDocumentsProvider);
    final List<HomeDestination> destinations =
        sl<HomeDestinationRegistry>().destinations;

    final bool isEmpty = all.maybeWhen(
      data: (List<LibraryDocument> d) => d.isEmpty,
      orElse: () => false,
    );

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      floatingActionButton: null,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: _GreetingRow(
                  onSearchTap: () => context.push(AppRoutes.library),
                ),
              ),
            ),
            if (isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.auto_stories_outlined,
                  title: 'Welcome to Sapiora',
                  message:
                      'Sapiora automatically finds the PDF files already on '
                      'your device — or import your own with the Import PDF '
                      'button. Everything stays on your device.',
                  action: FilledButton.icon(
                    onPressed: () => context.push(AppRoutes.library),
                    icon: const Icon(Icons.folder_open_outlined),
                    label: const Text('Open library'),
                  ),
                ),
              )
            else ...[
              _entryStrip(context, 'Continue reading', continueReading),
              _docStrip(context, 'Recent Documents', recent,
                  showViewAll: true),
              _docStrip(context, 'Favorites', favorites),
            ],
            SliverToBoxAdapter(
              child: _ExploreSection(destinations: destinations),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: _GoalAndImportRow(
                  onImport: () => _import(context, ref),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _HomeFooter()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Result<ImportOutcome> result =
        await ref.read(importPdfsProvider).call(const NoParams());
    result.fold(
      (failure) => messenger.showSnackBar(
        SnackBar(content: Text('Import failed: ${failure.message}')),
      ),
      (ImportOutcome o) {
        if (o.picked == 0) return; // cancelled
        final String msg = o.added > 0
            ? 'Imported ${o.added} PDF${o.added == 1 ? '' : 's'}'
                '${o.duplicates > 0 ? ' · skipped ${o.duplicates} already added' : ''}'
            : (o.duplicates == 1
                ? 'That PDF is already in your library'
                : 'Those PDFs are already in your library');
        messenger.showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  Widget _entryStrip(
    BuildContext context,
    String title,
    AsyncValue<List<LibraryEntry>> async,
  ) {
    final List<LibraryEntry> entries = async.maybeWhen(
        data: (List<LibraryEntry> e) => e, orElse: () => const []);
    if (entries.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: _Section(
        title: title,
        child: _HorizontalList(
          itemCount: entries.length,
          itemBuilder: (BuildContext context, int i) {
            final LibraryEntry e = entries[i];
            return DocumentCard(
              document: e.document,
              progress: e.percent,
              onOpen: () => context.push(AppRoutes.reader(e.document.id)),
            );
          },
        ),
      ),
    );
  }

  Widget _docStrip(
    BuildContext context,
    String title,
    AsyncValue<List<LibraryDocument>> async, {
    bool showViewAll = false,
  }) {
    final List<LibraryDocument> docs = async.maybeWhen(
      data: (List<LibraryDocument> d) => d,
      orElse: () => const [],
    );
    if (docs.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: _Section(
        title: title,
        onViewAll:
            showViewAll ? () => context.push(AppRoutes.library) : null,
        child: _HorizontalList(
          itemCount: docs.length,
          itemBuilder: (BuildContext context, int i) => DocumentCard(
            document: docs[i],
            onOpen: () => context.push(AppRoutes.reader(docs[i].id)),
          ),
        ),
      ),
    );
  }
}

/// "Good Evening, Ismail 👋" + subtitle, with the circular search button.
class _GreetingRow extends StatelessWidget {
  const _GreetingRow({required this.onSearchTap});
  final VoidCallback onSearchTap;

  String get _greeting {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text.rich(
                TextSpan(
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                  children: <InlineSpan>[
                    TextSpan(text: '$_greeting, '),
                    TextSpan(
                      text: AppConstants.userDisplayName,
                      style: TextStyle(color: scheme.primary),
                    ),
                    const TextSpan(text: ' 👋'),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Keep learning, keep growing.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _GlowIconButton(icon: Icons.search_rounded, onTap: onSearchTap),
      ],
    ).animate().fadeIn(duration: 320.ms).slideY(begin: -0.08, end: 0);
  }
}

/// A circular, softly-glowing icon button — used for the header search entry.
class _GlowIconButton extends StatefulWidget {
  const _GlowIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_GlowIconButton> createState() => _GlowIconButtonState();
}

class _GlowIconButtonState extends State<_GlowIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[scheme.primary, scheme.tertiary],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.38),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(widget.icon, color: scheme.onPrimary),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.onViewAll});
  final String title;
  final Widget child;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('View all'),
                  ),
              ],
            ),
          ),
          child,
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0);
  }
}

class _HorizontalList extends StatelessWidget {
  const _HorizontalList({required this.itemCount, required this.itemBuilder});
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 244,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (BuildContext context, int i) => SizedBox(
          width: 152,
          child: _ElevatedCard(
            child: itemBuilder(context, i),
          ),
        ),
      ),
    );
  }
}

/// Wraps a document card with a soft, premium drop shadow — the card's own
/// internal styling is untouched, this only affects how it sits on the page.
class _ElevatedCard extends StatelessWidget {
  const _ElevatedCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _HomeFooter extends StatelessWidget {
  const _HomeFooter();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.primary.withValues(alpha: 0.16),
                scheme.tertiary.withValues(alpha: 0.16),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite, size: 14, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Developed by Ismail Lashari',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Explore module list — a vertical stack of rows (icon, label, subtitle,
/// chevron), one per [HomeDestination].
class _ExploreSection extends StatelessWidget {
  const _ExploreSection({required this.destinations});
  final List<HomeDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final List<HomeDestination> visible =
        destinations.where((HomeDestination d) => d.enabled).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text(
              'Explore',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: <Widget>[
                for (int i = 0; i < visible.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ExploreRow(destination: visible[i], index: i),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreRow extends StatelessWidget {
  const _ExploreRow({required this.destination, required this.index});
  final HomeDestination destination;
  final int index;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        splashColor: scheme.primary.withValues(alpha: 0.10),
        highlightColor: scheme.primary.withValues(alpha: 0.06),
        onTap: () {
          if (destination.comingSoon) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text('${destination.label} is coming soon.')),
              );
          } else {
            context.push(destination.routePath);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      scheme.primary.withValues(alpha: 0.85),
                      scheme.tertiary.withValues(alpha: 0.85),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(destination.icon, color: scheme.onPrimary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          destination.label,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (destination.comingSoon) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 1),
                            decoration: BoxDecoration(
                              color: scheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Soon',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (destination.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        destination.subtitle!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    )
        .animate(delay: (40 * index).ms)
        .fadeIn(duration: 260.ms)
        .slideX(begin: 0.04, end: 0);
  }
}

/// Today's Goal (real data from Study Hub's daily goals) side-by-side with
/// the Import PDF action.
class _GoalAndImportRow extends ConsumerWidget {
  const _GoalAndImportRow({required this.onImport});
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Expanded(flex: 6, child: _TodaysGoalCard()),
          const SizedBox(width: 12),
          Expanded(flex: 5, child: _ImportPdfButton(onTap: onImport)),
        ],
      ),
    );
  }
}

class _TodaysGoalCard extends ConsumerWidget {
  const _TodaysGoalCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AsyncValue<List<StudyGoal>> goalsAsync =
        ref.watch(studyGoalsProvider);
    final List<StudyGoal> goals = goalsAsync.maybeWhen(
        data: (List<StudyGoal> g) => g, orElse: () => const <StudyGoal>[]);

    final int total = goals.length;
    final int done = goals.where((StudyGoal g) => g.achieved).length;
    final double fraction = total == 0 ? 0 : done / total;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.push(AppRoutes.studyHub),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: fraction),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (BuildContext context, double value, _) =>
                        CircularProgressIndicator(
                      value: value,
                      strokeWidth: 6,
                      backgroundColor:
                          scheme.outlineVariant.withValues(alpha: 0.4),
                      valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                    ),
                  ),
                  Text(
                    total == 0 ? '—' : '${(fraction * 100).round()}%',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    "Today's Goal",
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    total == 0 ? 'Set a goal' : '$done / $total Topics',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportPdfButton extends StatefulWidget {
  const _ImportPdfButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_ImportPdfButton> createState() => _ImportPdfButtonState();
}

class _ImportPdfButtonState extends State<_ImportPdfButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[scheme.primary, scheme.tertiary],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.upload_rounded, color: scheme.onPrimary, size: 26),
              const SizedBox(height: 10),
              Text(
                'Import PDF',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Add and study anywhere',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onPrimary.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
