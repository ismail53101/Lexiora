import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lexiora/features/home/domain/entities/latest_update.dart';

/// Compact reusable Home update card for live or local story collections.
///
/// The widget owns only presentation state: the source list is supplied by the
/// caller, while timing and gesture state are disposed with the card.
class LatestUpdateCard extends StatefulWidget {
  const LatestUpdateCard({
    required this.update,
    this.updates,
    this.itemCount = 1,
    this.itemIndex = 0,
    this.onTap,
    super.key,
  });

  final LatestUpdate update;
  final List<LatestUpdate>? updates;
  final int itemCount;
  final int itemIndex;
  final VoidCallback? onTap;

  @override
  State<LatestUpdateCard> createState() => _LatestUpdateCardState();
}

class _LatestUpdateCardState extends State<LatestUpdateCard> {
  Timer? _rotationTimer;
  late List<LatestUpdate> _updates;
  late int _activeIndex;

  @override
  void initState() {
    super.initState();
    _syncUpdates();
    _startRotation();
  }

  @override
  void didUpdateWidget(covariant LatestUpdateCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.updates != widget.updates ||
        oldWidget.update != widget.update) {
      final LatestUpdate active = _activeStory;
      _syncUpdates(preferred: active);
    }
    if (_updates.length > 1 && _rotationTimer == null) {
      _startRotation();
    }
  }

  void _syncUpdates({LatestUpdate? preferred}) {
    final List<LatestUpdate> supplied = widget.updates ?? <LatestUpdate>[widget.update];
    _updates = supplied.isEmpty ? <LatestUpdate>[widget.update] : supplied.take(5).toList(growable: false);
    final int preferredIndex = preferred == null ? -1 : _updates.indexOf(preferred);
    _activeIndex = preferredIndex >= 0
        ? preferredIndex
        : widget.itemIndex.clamp(0, _updates.length - 1).toInt();
  }

  void _startRotation() {
    _rotationTimer?.cancel();
    if (_updates.length <= 1) return;
    _rotationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted || _updates.length <= 1) return;
      _showIndex((_activeIndex + 1) % _updates.length);
    });
  }

  void _showIndex(int index) {
    if (!mounted || _updates.isEmpty) return;
    setState(() => _activeIndex = index.clamp(0, _updates.length - 1).toInt());
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final double velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 180 || _updates.length <= 1) return;
    final int next = velocity < 0
        ? (_activeIndex + 1) % _updates.length
        : (_activeIndex - 1 + _updates.length) % _updates.length;
    _showIndex(next);
  }

  LatestUpdate get _activeStory => _updates[_activeIndex.clamp(0, _updates.length - 1).toInt()];

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color accent = scheme.primary;
    final LatestUpdate story = _activeStory;

    return GestureDetector(
      onHorizontalDragEnd: _handleHorizontalDragEnd,
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: accent.withValues(alpha: 0.10),
          highlightColor: accent.withValues(alpha: 0.05),
          child: Container(
            constraints: const BoxConstraints(minHeight: 96, maxHeight: 100),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.65)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: accent.withValues(alpha: theme.brightness == Brightness.dark ? 0.16 : 0.10),
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
                              Icon(Icons.auto_awesome, size: 11, color: scheme.tertiary),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 420),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                final Animation<Offset> slide = Tween<Offset>(
                                  begin: const Offset(0.12, 0),
                                  end: Offset.zero,
                                ).animate(animation);
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(position: slide, child: child),
                                );
                              },
                              child: Align(
                                key: ValueKey<String>(story.headline),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  story.headline,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    height: 1.08,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Text(
                            '${story.source} · ${story.category} · ${story.relativeTime}',
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
                            count: _updates.length,
                            activeIndex: _activeIndex,
                            color: accent,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _NewsThumbnail(
                      accent: accent,
                      size: thumbnailSize,
                      imageUrl: story.imageUrl,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NewsThumbnail extends StatelessWidget {
  const _NewsThumbnail({required this.accent, required this.size, this.imageUrl});

  final Color accent;
  final double size;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final Color surface = Theme.of(context).colorScheme.surfaceContainerHigh;
    final Widget fallback = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[accent.withValues(alpha: 0.84), Theme.of(context).colorScheme.tertiary],
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
          Center(child: Icon(Icons.newspaper_rounded, color: Colors.white, size: size * 0.40)),
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
    );

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        SizedBox(
          width: size,
          height: size,
          child: imageUrl == null
              ? fallback
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => fallback,
                  ),
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
              border: Border.all(color: surface, width: 2),
            ),
            child: const Icon(Icons.arrow_forward_rounded, size: 13, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _CarouselDots extends StatelessWidget {
  const _CarouselDots({required this.count, required this.activeIndex, required this.color});

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
              color: index == safeIndex ? color : color.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
      ],
    );
  }
}
