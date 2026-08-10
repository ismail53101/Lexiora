import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/translation/data/services/http_translation_service.dart';

/// Unit tests for the pure response parser — no network involved.
void main() {
  test('parses a valid MyMemory response', () {
    const String body =
        '{"responseData":{"translatedText":"کتاب","match":1},'
        '"responseStatus":200}';
    expect(HttpTranslationService.parseTranslation(body), 'کتاب');
  });

  test('trims surrounding whitespace', () {
    const String body =
        '{"responseData":{"translatedText":"  معیشت  "},"responseStatus":200}';
    expect(HttpTranslationService.parseTranslation(body), 'معیشت');
  });

  test('returns null for an empty translation', () {
    const String body =
        '{"responseData":{"translatedText":""},"responseStatus":200}';
    expect(HttpTranslationService.parseTranslation(body), isNull);
  });

  test('returns null on provider diagnostic strings', () {
    const String body =
        '{"responseData":{"translatedText":"NO QUERY SPECIFIED. EXAMPLE '
        'REQUEST: GET?Q=HELLO"},"responseStatus":403}';
    expect(HttpTranslationService.parseTranslation(body), isNull);
  });

  test('parses a valid Google Translate response', () {
    const String body =
        '[[["عمل، طریقہ یا عمل کرنے کا انداز","execution",null,null,3]],'
        'null,"en",null,null,null,null,[]]';
    expect(HttpTranslationService.parseTranslation(body),
        'عمل، طریقہ یا عمل کرنے کا انداز');
  });

  test('joins Google multi-segment responses', () {
    const String body =
        '[[["پہلا","first",null,null,3],[" دوسرا","second",null,null,3]],'
        'null,"en",null,null,null,null,[]]';
    expect(HttpTranslationService.parseTranslation(body), 'پہلا دوسرا');
  });

  test('returns null for an empty Google response', () {
    const String body = '[[],null,"en",null,null,null,null,[]]';
    expect(HttpTranslationService.parseTranslation(body), isNull);
  });

  test('returns null when responseData is missing', () {
    const String body = '{"responseStatus":200}';
    expect(HttpTranslationService.parseTranslation(body), isNull);
  });

  test('returns null on malformed JSON', () {
    expect(HttpTranslationService.parseTranslation('not json'), isNull);
    expect(HttpTranslationService.parseTranslation('[1,2,3]'), isNull);
  });
}
