import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/modules/study_hub/presentation/widgets/study_hub_common.dart';

/// ⚡ Quick Actions — jump straight into studying from the dashboard.
class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_Action> actions = <_Action>[
      const _Action(
        icon: Icons.play_circle_outline,
        label: 'Continue studying',
        route: AppRoutes.library,
      ),
      const _Action(
        icon: Icons.style_outlined,
        label: "Today's Vocabulary",
        route: AppRoutes.vocabulary,
      ),
      const _Action(
        icon: Icons.folder_copy_outlined,
        label: 'Open Library',
        route: AppRoutes.library,
      ),
      const _Action(
        icon: Icons.search,
        label: 'Search Dictionary',
        route: AppRoutes.dictionary,
      ),
    ];

    return SectionCard(
      icon: Icons.bolt,
      title: 'Quick Actions',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          const double gap = 12;
          final double w = (c.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: <Widget>[
              for (final _Action a in actions)
                SizedBox(width: w, child: _ActionTile(action: a)),
            ],
          );
        },
      ),
    );
  }
}

class _Action {
  const _Action({required this.icon, required this.label, required this.route});
  final IconData icon;
  final String label;
  final String route;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});
  final _Action action;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(action.route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: <Widget>[
              Icon(action.icon, color: theme.colorScheme.onSecondaryContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  action.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
