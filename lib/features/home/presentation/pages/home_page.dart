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
import 'package:lexiora/core/widgets/empty_state.dart';
import 'package:lexiora/features/library/domain/entities/library_document.dart';
import 'package:lexiora/features/library/domain/usecases/library_usecases.dart';
import 'package:lexiora/features/library/presentation/providers/library_providers.dart';
import 'package:lexiora/features/library/presentation/widgets/document_card.dart';

/// The Home dashboard: greeting, a (UI-only) search entry, and rows for
/// Continue Reading, Recent and Favorites, plus module "Explore" tiles that
/// future modules populate through [HomeDestination]s.
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _import(context, ref),
        icon: const Icon(Icons.file_upload_outlined),
        label: const Text('Import PDF'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text(AppConstants.appName),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
                onPressed: () => context.push(AppRoutes.settings),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _SearchEntry(
                onTap: () => context.push(AppRoutes.library),
              ).animate().fadeIn(duration: 250.ms),
            ),
          ),
          if (isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.auto_stories_outlined,
                title: 'Welcome to Sapiora',
                message: 'Sapiora automatically finds the PDF files already on '
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
            _docStrip(context, 'Recent', recent),
            _docStrip(context, 'Favorites', favorites),
          ],
          SliverToBoxAdapter(
            child: _ExploreSection(destinations: destinations),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
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
    final List<LibraryEntry> entries =
        async.maybeWhen(data: (List<LibraryEntry> e) => e, orElse: () => const []);
    if (entries.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
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
    AsyncValue<List<LibraryDocument>> async,
  ) {
    final List<LibraryDocument> docs = async.maybeWhen(
      data: (List<LibraryDocument> d) => d,
      orElse: () => const [],
    );
    if (docs.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverToBoxAdapter(
      child: _Section(
        title: title,
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

class _SearchEntry extends StatelessWidget {
  const _SearchEntry({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Text(
                'Search your library',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          child,
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0);
  }
}

class _HorizontalList extends StatelessWidget {
  const _HorizontalList({required this.itemCount, required this.itemBuilder});
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 236,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (BuildContext context, int i) =>
            SizedBox(width: 150, child: itemBuilder(context, i)),
      ),
    );
  }
}

class _ExploreSection extends StatelessWidget {
  const _ExploreSection({required this.destinations});
  final List<HomeDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final List<HomeDestination> visible =
        destinations.where((HomeDestination d) => d.enabled).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text(
              'Explore',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: visible
                  .map((HomeDestination d) => _ExploreCard(destination: d))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({required this.destination});
  final HomeDestination destination;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SizedBox(
      width: 160,
      child: Card(
        child: InkWell(
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(destination.icon, color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  destination.label,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (destination.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    destination.subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (destination.comingSoon) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Soon',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
