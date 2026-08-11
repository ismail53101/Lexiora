import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/modules/dictionary/data/services/definition_sense.dart';

void main() {
  group('pickBestDefinition', () {
    test('picks the general sense for "attention" (not treatment/care)', () {
      const List<String> defs = <String>[
        'the work of providing treatment for or attending to someone or something',
        'a courteous act indicating affection',
        'a motionless erect stance with arms at the sides and feet together',
        'the faculty or power of mental concentration',
        'the process whereby a person concentrates on some features of the environment',
        'a general interest that leads people to want to know more',
      ];
      expect(
        pickBestDefinition(defs),
        'the faculty or power of mental concentration',
      );
    });

    test('picks the sad-event sense for "tragedy" (not the drama genre)', () {
      const List<String> defs = <String>[
        'drama in which the protagonist is overcome by some superior force or circumstance',
        'an event resulting in great loss and misfortune',
      ];
      expect(
        pickBestDefinition(defs),
        'an event resulting in great loss and misfortune',
      );
    });

    test('picks the concentration sense for "focus" (tie-break on markers)', () {
      const List<String> defs = <String>[
        'maximum clarity or distinctness of an image rendered by an optical system',
        'maximum clarity or distinctness of an idea',
        'the concentration of attention or energy on something',
        'a fixed reference point on the concave side of a conic section',
        'a point of convergence of light (or other radiation) or a point from which it diverges',
        'a central point or locus of an infection in an organism',
      ];
      expect(
        pickBestDefinition(defs),
        'the concentration of attention or energy on something',
      );
    });

    test('picks the danger sense for "crisis"', () {
      const List<String> defs = <String>[
        'a crucial stage or turning point in the course of something',
        'an unstable situation of extreme danger or difficulty',
      ];
      expect(
        pickBestDefinition(defs),
        'an unstable situation of extreme danger or difficulty',
      );
    });

    test('a single definition is returned as-is; empty is null', () {
      expect(pickBestDefinition(<String>['to give']), 'to give');
      expect(pickBestDefinition(<String>[]), isNull);
      expect(pickBestDefinitionIndex(<String>[]), isNull);
    });
  });
}
