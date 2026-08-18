import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/app/router/app_routes.dart';
import 'package:lexiora/core/services/pronunciation_service.dart';
import 'package:lexiora/features/home/domain/services/word_of_day_service.dart';

/// A "Word of the Day" card for the Home screen.
///
/// Displays the daily word with its Urdu meaning, English definition,
/// a pronunciation button, and a "Tap to learn" link to the full
/// Dictionary detail page.
class WordOfDayCard extends StatefulWidget {
  const WordOfDayCard({super.key});

  @override
  State<WordOfDayCard> createState() => _WordOfDayCardState();
}

class _WordOfDayCardState extends State<WordOfDayCard> {
  Map<String, dynamic>? _entry;
  bool _loading = true;
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final Map<String, dynamic>? entry = await WordOfDayService.today();
    if (mounted) setState(() { _entry = entry; _loading = false; });
  }

  Future<void> _speak() async {
    if (_entry == null || _speaking) return;
    setState(() => _speaking = true);
    try {
      await _pronunciationService.speak(
        _entry!['word'] as String,
        languageCode: 'en-US',
      );
    } catch (_) {
      // Swallow — TTS may be unavailable on some devices.
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  void _openDetail() {
    final String word = (_entry?['word'] as String?) ?? '';
    if (word.isNotEmpty) {
      context.push(AppRoutes.dictionaryWord(word));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_entry == null) return const SizedBox.shrink();

    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String word = (_entry!['word'] as String?) ?? '';
    final String definition =
        (_entry!['englishDefinition'] as String?) ?? '';
    final List<dynamic> urduList =
        (_entry!['urduMeanings'] as List<dynamic>?) ?? const <dynamic>[];
    final String urdu =
        urduList.isNotEmpty ? urduList.first.toString() : '';

    // Truncate definition to ~60 chars for the card.
    final String shortDef =
        definition.length > 60 ? '${definition.substring(0, 57)}…' : definition;

    return GestureDetector(
      onTap: _openDetail,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              scheme.primaryContainer.withValues(alpha: 0.55),
              scheme.tertiaryContainer.withValues(alpha: 0.45),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: scheme.primary.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              // ── Left: icon + word + pronunciation + Urdu ──
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Aa',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'WORD OF THE DAY',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            word,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _speak,
                          child: Icon(
                            _speaking
                                ? Icons.volume_up_rounded
                                : Icons.volume_up_outlined,
                            size: 20,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                    if (urdu.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        urdu,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ── Right: definition + "Tap to learn" ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      shortDef,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'Tap to learn',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: scheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0);
  }
}

/// Lazy-init pronunciation service.
final PronunciationService _pronunciationService = TtsPronunciationService();
