import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/dictionary/data/services/online_dictionary_service.dart';
import 'package:lexiora/modules/dictionary/domain/entities/dictionary_entry.dart';
import 'package:lexiora/modules/dictionary/domain/entities/word_profile.dart';

void main() {
  test('parses phonetics, audio, senses, examples and related words', () {
    final OnlineDefinition? result = OnlineDictionaryService.parseDefinition(
      jsonEncode(<Map<String, Object>>[
        <String, Object>{
          'word': 'bright',
          'phonetic': '/braɪt/',
          'phonetics': <Map<String, String>>[
            <String, String>{
              'text': '/braɪt/',
              'audio': 'https://example.test/bright.mp3',
            },
          ],
          'meanings': <Map<String, Object>>[
            <String, Object>{
              'partOfSpeech': 'adjective',
              'synonyms': <String>['brilliant'],
              'antonyms': <String>['dim'],
              'definitions': <Map<String, String>>[
                <String, String>{
                  'definition': 'Giving out or reflecting a lot of light.',
                  'example': 'The bright lamp lit the room.',
                },
              ],
            },
          ],
        },
      ]),
    );

    expect(result, isNotNull);
    expect(result!.phonetic, '/braɪt/');
    expect(result.audioUrl, 'https://example.test/bright.mp3');
    expect(result.senses.single.example, 'The bright lamp lit the room.');
    expect(result.synonyms, contains('brilliant'));
    expect(result.antonyms, contains('dim'));
  });

  test('malformed or empty API responses fail closed', () {
    expect(OnlineDictionaryService.parseDefinition('{bad json'), isNull);
    expect(OnlineDictionaryService.parseDefinition('[]'), isNull);
  });

  test('local dictionary fields remain authoritative over external fields', () {
    const WordProfile profile = WordProfile(
      word: 'policy',
      wordLower: 'policy',
      base: WordDetails(
        word: 'policy',
        wordLower: 'policy',
        isFavorite: false,
        senses: <DictionaryEntry>[
          DictionaryEntry(
            id: 1,
            word: 'policy',
            meaning: 'a course of action adopted by an organization',
            partOfSpeech: 'noun',
            ipaPronunciation: '/ˈpɒləsi/',
            exampleSentence: 'The policy was reviewed.',
          ),
        ],
      ),
      freeDictionary: FreeDictionaryProfile(
        word: 'policy',
        phonetic: '/ˈpɑːləsi/',
        senses: <FreeDictionarySense>[
          FreeDictionarySense(
            meaning: 'an insurance contract',
            partOfSpeech: 'noun',
            example: 'She renewed the policy.',
          ),
        ],
      ),
    );

    expect(profile.englishDefinition,
        'a course of action adopted by an organization');
    expect(profile.pronunciation, '/ˈpɒləsi/');
    expect(profile.partOfSpeech, 'noun');
  });
}
