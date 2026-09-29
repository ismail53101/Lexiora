import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/grammar/presentation/widgets/grammar_voice_colors.dart';

void main() {
  group('voice colors', () {
    test('passive green and active blue are theme-aware and distinct', () {
      final Color passiveDark = passiveVoiceColorFor(Brightness.dark);
      final Color passiveLight = passiveVoiceColorFor(Brightness.light);
      final Color activeDark = activeVoiceColorFor(Brightness.dark);
      final Color activeLight = activeVoiceColorFor(Brightness.light);

      // Theme-aware: the two themes use different tones.
      expect(passiveDark, isNot(passiveLight));
      expect(activeDark, isNot(activeLight));

      // Never the same color for active and passive in either theme.
      expect(passiveDark, isNot(activeDark));
      expect(passiveLight, isNot(activeLight));

      // Bright-but-soft green on dark; deep readable green on light.
      expect(passiveDark, const Color(0xFF4ADE80));
      expect(passiveLight, const Color(0xFF15803D));
      expect(activeDark, const Color(0xFF64B5F6));
      expect(activeLight, const Color(0xFF1976D2));
    });

    test('passive detection matches real lesson sentences', () {
      // Passive sentences (be-verb + by-agent).
      expect(isPassiveVoiceSentence('A letter **is written** by Ali.'), isTrue);
      expect(isPassiveVoiceSentence('The room is not cleaned by her.'), isTrue);
      expect(isPassiveVoiceSentence('Is cricket played by them?'), isTrue);
      expect(isPassiveVoiceSentence('Was the door opened by the boy?'), isTrue);
      expect(isPassiveVoiceSentence('The homework was completed by the students.'), isTrue);

      // Patterns/formulas never match.
      expect(isPassiveVoiceSentence('Object + is/am/are + V3 + by + Subject'), isFalse);
      expect(isPassiveVoiceSentence('Subject + V1(s/es) + Object'), isFalse);

      // Active/other sentences never match.
      expect(isPassiveVoiceSentence('He writes a letter.'), isFalse);
      expect(isPassiveVoiceSentence('Does he write a letter?'), isFalse);
      expect(isPassiveVoiceSentence('The subject does the action.'), isFalse);

      // Urdu never matches.
      expect(isPassiveVoiceSentence('ایک خط علی کے ذریعے لکھا جاتا ہے۔'), isFalse);
    });

    test('active detection matches standalone example sentences', () {
      expect(looksLikeExampleSentence('He writes a letter.'), isTrue);
      expect(looksLikeExampleSentence('Does he write a letter?'), isTrue);
      expect(looksLikeExampleSentence('Do they play cricket?'), isTrue);
      expect(looksLikeExampleSentence('Does Ali help Ahmed?'), isTrue);

      // Explanations and patterns stay default-colored.
      expect(looksLikeExampleSentence('The subject does the action.'), isFalse);
      expect(looksLikeExampleSentence('Subject + V1(s/es) + Object'), isFalse);
      expect(looksLikeExampleSentence('In active voice, we focus on the doer.'), isFalse);
    });

    test('formula cells are never treated as example sentences', () {
      expect(looksLikeEnglishSentence('Subject + V1(s/es) + Object'), isFalse);
      expect(looksLikeEnglishSentence('Object + is/am/are + V3 + by + Subject'), isFalse);
      expect(looksLikeEnglishSentence('He writes a letter.'), isTrue);
    });

    test('highlight yellow is theme-aware and distinct', () {
      final Color dark = highlightYellowColorFor(Brightness.dark);
      final Color light = highlightYellowColorFor(Brightness.light);
      expect(dark, isNot(light));
      expect(dark, const Color(0xFFFFD54F)); // amber on dark
      expect(light, const Color(0xFFB45309)); // deep amber on light
    });

    test('@@ markup is stripped before sentence detection', () {
      // Highlighted pattern cells stay uncolored (formula, not sentence).
      expect(looksLikeEnglishSentence('Subject + @@will have@@ + @@V3@@ + Object'), isFalse);
      expect(isPassiveVoiceSentence('Object + @@will have been@@ + @@V3@@ + by + Subject'), isFalse);

      // Highlighted real sentences still detect their voice.
      expect(isPassiveVoiceSentence('Cricket @@will have been@@ played by them.'), isTrue);
      expect(looksLikeEnglishSentence('They @@will have@@ played cricket.'), isTrue);

      // Stripping returns the raw words.
      expect(stripHighlightMarkup('Use @@will have@@ according to the subject.'),
          'Use will have according to the subject.');
    });
  });
}
