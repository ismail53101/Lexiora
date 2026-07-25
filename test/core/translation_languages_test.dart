import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/constants/translation_languages.dart';

/// Guards Urdu's first-class, prioritised status in the translation config.
void main() {
  test('Urdu is the default target language', () {
    expect(kDefaultTranslationLanguage, 'ur');
    expect(isSupportedTranslationLanguage('ur'), isTrue);
  });

  test('Urdu is listed first (prioritised in the picker)', () {
    expect(kTranslationLanguages.first.code, 'ur');
    expect(kTranslationLanguages.first.englishName, 'Urdu');
    expect(kTranslationLanguages.first.nativeName, 'اردو');
  });

  test('all advertised languages are present and resolvable', () {
    for (final String code in <String>['ur', 'fr', 'pt', 'hi', 'ar']) {
      expect(isSupportedTranslationLanguage(code), isTrue, reason: code);
      expect(translationLanguageByCode(code).code, code);
    }
  });

  test('unknown codes fall back to the first (Urdu)', () {
    expect(translationLanguageByCode('zz').code, 'ur');
    expect(translationLanguageByCode('').code, 'ur');
  });
}
