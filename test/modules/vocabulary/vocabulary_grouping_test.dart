import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/vocabulary/domain/entities/vocabulary_word.dart';
import 'package:lexiora/modules/vocabulary/domain/vocabulary_grouping.dart';

VocabularyWord _w(String word, String urdu, {String? english}) => VocabularyWord(
      id: 'general/${word.toLowerCase()}',
      listId: 'general',
      word: word,
      letter: word[0].toUpperCase(),
      urduMeaning: urdu,
      englishMeaning: english ?? 'meaning of $word',
    );

void main() {
  final List<VocabularyWord> words = <VocabularyWord>[
    _w('Apple', 'سیب'),
    _w('Ability', 'صلاحیت'),
    _w('Banana', 'کیلا'),
    _w('Cat', 'بلی'),
  ];

  group('matches', () {
    test('matches the English word case-insensitively', () {
      expect(_w('Apple', 'سیب').matches('app'), isTrue);
      expect(_w('Apple', 'سیب').matches('APP'), isTrue);
      expect(_w('Apple', 'سیب').matches('ple'), isTrue);
      expect(_w('Apple', 'سیب').matches('dog'), isFalse);
    });

    test('matches the Urdu meaning', () {
      expect(_w('Cat', 'بلی').matches('بلی'), isTrue);
      expect(_w('Cat', 'بلی').matches('کتا'), isFalse);
    });

    test('empty query matches everything', () {
      expect(_w('Cat', 'بلی').matches('   '), isTrue);
    });
  });

  group('filterVocabulary', () {
    test('filters by English word', () {
      final List<VocabularyWord> r = filterVocabulary(words, 'ba');
      expect(r.map((VocabularyWord w) => w.word), <String>['Banana']);
    });

    test('filters by Urdu meaning', () {
      final List<VocabularyWord> r = filterVocabulary(words, 'سیب');
      expect(r.single.word, 'Apple');
    });

    test('empty query returns all', () {
      expect(filterVocabulary(words, ''), hasLength(words.length));
    });
  });

  group('groupByLetter', () {
    test('groups contiguous letters into ordered sections', () {
      // Order the way the DB returns them (by lowercased word).
      final List<VocabularyWord> ordered = <VocabularyWord>[
        _w('Ability', 'صلاحیت'),
        _w('Apple', 'سیب'),
        _w('Banana', 'کیلا'),
        _w('Cat', 'بلی'),
      ];
      final List<VocabularySection> sections = groupByLetter(ordered);
      expect(sections.map((VocabularySection s) => s.letter),
          <String>['A', 'B', 'C']);
      expect(sections.first.words, hasLength(2));
      expect(sections[1].words.single.word, 'Banana');
    });

    test('empty input yields no sections', () {
      expect(groupByLetter(const <VocabularyWord>[]), isEmpty);
    });
  });
}
