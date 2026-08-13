import 'package:flutter/material.dart';
import 'package:lexiora/features/home/domain/entities/latest_update.dart';

/// A reusable presentation widget for one local or future live Home update.
class LatestUpdateCard extends StatelessWidget {
  const LatestUpdateCard({
    required this.update,
    this.itemCount = 1,
    this.itemIndex = 0,
    this.onTap,
    super.key,
  });

  final LatestUpdate update;
  final int itemCount;
  final int itemIndex;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color accent = scheme.primary;

    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: accent.withValues(alpha: 0.10),
        highlightColor: accent.withValues(alpha: 0.05),
        child: Container(
          constraints: const BoxConstraints(minHeight: 96, maxHeight: 100),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.12)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: accent.withValues(alpha: 0.12),
                blurRadius: 20,
                spreadRadius: -10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(11, 8, 9, 8),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double thumbnailSize = constraints.maxWidth < 340 ? 56 : 62;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              width: 19,
                              height: 19,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.14),
                                shape: BoxShape.circle,
                              ),
                              child: Image.asset(
                                'assets/branding/app_icon.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'LATEST UPDATE',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w800,
                                fontSize: 9,
                                letterSpacing: 0.85,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Icon(Icons.auto_awesome, size: 11, color: accent),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          update.headline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            height: 1.08,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${update.source} · ${update.category} · '
                          '${update.relativeTime}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 9,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _CarouselDots(
                          count: itemCount,
                          activeIndex: itemIndex,
                          color: accent,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _NewsThumbnail(
                    accent: accent,
                    size: thumbnailSize,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NewsThumbnail extends StatelessWidget {
  const _NewsThumbnail({required this.accent, required this.size});

  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                accent.withValues(alpha: 0.82),
                const Color(0xFF211A49),
              ],
            ),
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                top: -16,
                right: -10,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Center(
                child: Icon(Icons.newspaper_rounded,
                    color: Colors.white, size: size * 0.40),
              ),
              Positioned(
                left: 7,
                bottom: 5,
                child: Text(
                  'NEWS',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: -4,
          bottom: -4,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                width: 2,
              ),
            ),
            child: const Icon(Icons.arrow_forward_rounded,
                size: 13, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _CarouselDots extends StatelessWidget {
  const _CarouselDots({
    required this.count,
    required this.activeIndex,
    required this.color,
  });

  final int count;
  final int activeIndex;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final int safeCount = count.clamp(1, 5).toInt();
    final int safeIndex = activeIndex.clamp(0, safeCount - 1).toInt();
    return Row(
      children: <Widget>[
        for (int index = 0; index < safeCount; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(right: 3),
            width: index == safeIndex ? 13 : 4,
            height: 4,
            decoration: BoxDecoration(
              color: index == safeIndex
                  ? color
                  : color.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
      ],
    );
  }
}
