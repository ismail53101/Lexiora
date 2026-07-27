import 'dart:async';

import 'package:lexiora/core/constants/db_constants.dart';
import 'package:lexiora/modules/quiz/data/datasources/quiz_local_data_source.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_bank.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_question.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_subject.dart';
import 'package:lexiora/modules/quiz/domain/entities/quiz_topic.dart';
import 'package:lexiora/modules/quiz/domain/repositories/quiz_repository.dart';

/// Seeds a tiny, fully-editable DEMO of the subject-first workflow once, on
/// first use. This is demonstration data only: it lives in the normal quiz
/// tables (fixed `demo_*` ids so re-seeding upserts rather than duplicates), so
/// the Admin CMS can edit or delete any of it and the app always renders
/// whatever rows exist. Nothing here is hardcoded into UI logic.
///
/// Only four subjects carry content (Pakistan Affairs, English, Islamic Studies,
/// General Science), five quizzes each — exactly as specified for v0.9.1.
class QuizSeeder {
  QuizSeeder(this._repo, this._local);

  final QuizRepository _repo;
  final QuizLocalDataSource _local;
  Future<void>? _inFlight;

  Future<void> ensureSeeded() {
    final Future<void>? existing = _inFlight;
    if (existing != null) return existing;
    final Future<void> run = _run();
    _inFlight = run;
    unawaited(run.then<void>((_) {}, onError: (_, _) => _inFlight = null));
    return run;
  }

  Future<void> _run() async {
    if (await _local.seededVersion() == QuizConstants.datasetVersion) return;
    final DateTime now = DateTime.now();

    for (final _DemoSubject s in _demo) {
      await _repo.saveSubject(QuizSubject(
        id: s.id,
        name: s.name,
        icon: s.icon,
        color: s.color,
        orderIndex: s.order,
        source: QuizConstants.demoSource,
        createdAt: now,
        updatedAt: now,
      ));
      for (int ti = 0; ti < s.topics.length; ti++) {
        final _DemoTopic t = s.topics[ti];
        if (t.id.isNotEmpty) {
          await _repo.saveTopic(QuizTopic(
            id: t.id,
            subjectId: s.id,
            name: t.name,
            orderIndex: ti,
            createdAt: now,
            updatedAt: now,
          ));
        }
      }
      for (int qi = 0; qi < s.quizzes.length; qi++) {
        final _DemoQuiz quiz = s.quizzes[qi];
        await _repo.saveBank(QuizBank(
          id: quiz.id,
          name: quiz.name,
          subject: s.name,
          topic: quiz.topicName,
          subjectId: s.id,
          topicId: quiz.topicId.isEmpty ? null : quiz.topicId,
          orderIndex: qi,
          version: '1.0',
          source: QuizConstants.demoSource,
          createdAt: now,
          updatedAt: now,
        ));
        for (int i = 0; i < quiz.questions.length; i++) {
          final QuizQuestion base = quiz.questions[i];
          await _repo.saveQuestion(QuizQuestion(
            id: '${quiz.id}_q$i',
            bankId: quiz.id,
            type: base.type,
            prompt: base.prompt,
            options: base.options,
            answerIndex: base.answerIndex,
            answerBool: base.answerBool,
            answerTexts: base.answerTexts,
            explanation: base.explanation,
            subject: s.name,
            topic: quiz.topicName,
            subjectId: s.id,
            topicId: quiz.topicId.isEmpty ? null : quiz.topicId,
            difficulty: base.difficulty,
            createdAt: now,
            updatedAt: now,
          ));
        }
      }
    }

    await _local.setSeededVersion(QuizConstants.datasetVersion);
  }
}

// ── Compact demo authoring helpers ────────────────────────────────────────────

QuizQuestion _mcq(String prompt, List<String> options, int answer,
        {String? explanation}) =>
    QuizQuestion(
      id: '',
      bankId: '',
      type: QuestionType.mcqSingle,
      prompt: prompt,
      options: options,
      answerIndex: answer,
      explanation: explanation,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

QuizQuestion _tf(String prompt, bool answer, {String? explanation}) =>
    QuizQuestion(
      id: '',
      bankId: '',
      type: QuestionType.trueFalse,
      prompt: prompt,
      answerBool: answer,
      explanation: explanation,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

QuizQuestion _blank(String prompt, List<String> accepted, {String? explanation}) =>
    QuizQuestion(
      id: '',
      bankId: '',
      type: QuestionType.fillBlank,
      prompt: prompt,
      answerTexts: accepted,
      explanation: explanation,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

class _DemoSubject {
  const _DemoSubject(this.id, this.name, this.icon, this.color, this.order,
      this.topics, this.quizzes);
  final String id;
  final String name;
  final int icon;
  final int color;
  final int order;
  final List<_DemoTopic> topics;
  final List<_DemoQuiz> quizzes;
}

class _DemoTopic {
  const _DemoTopic(this.id, this.name);
  final String id;
  final String name;
}

class _DemoQuiz {
  const _DemoQuiz(this.id, this.name, this.topicId, this.topicName, this.questions);
  final String id;
  final String name;
  final String topicId;
  final String? topicName;
  final List<QuizQuestion> questions;
}

// Indices into kQuizIcons (see quiz_icons.dart) — never raw code points.
const int _iFlag = 1;
const int _iBook = 2;
const int _iMosque = 3;
const int _iScience = 4;

// Neutral, factual demo questions. All editable/deletable via the Admin CMS.
final List<_DemoSubject> _demo = <_DemoSubject>[
  _DemoSubject(
    'demo_subj_pak', 'Pakistan Affairs', _iFlag, 0xFF00695C, 0,
    const <_DemoTopic>[
      _DemoTopic('demo_topic_pak_eco', 'Economy'),
      _DemoTopic('demo_topic_pak_his', 'History'),
      _DemoTopic('demo_topic_pak_fp', 'Foreign Policy'),
      _DemoTopic('demo_topic_pak_con', 'Constitution'),
      _DemoTopic('demo_topic_pak_geo', 'Geography'),
    ],
    <_DemoQuiz>[
      _DemoQuiz('demo_quiz_pak_eco', 'Economy Basics', 'demo_topic_pak_eco',
          'Economy', <QuizQuestion>[
        _mcq('What is the currency of Pakistan?',
            <String>['Rupee', 'Taka', 'Rupiah', 'Riyal'], 0),
        _mcq('Which city is the financial hub of Pakistan?',
            <String>['Lahore', 'Karachi', 'Peshawar', 'Quetta'], 1),
      ]),
      _DemoQuiz('demo_quiz_pak_his', 'History Milestones', 'demo_topic_pak_his',
          'History', <QuizQuestion>[
        _mcq('In which year did Pakistan gain independence?',
            <String>['1947', '1930', '1956', '1971'], 0),
        _tf('Pakistan became a republic in 1956.', true),
      ]),
      _DemoQuiz('demo_quiz_pak_fp', 'Foreign Policy', 'demo_topic_pak_fp',
          'Foreign Policy', <QuizQuestion>[
        _mcq('Pakistan is a founding member of which regional bloc?',
            <String>['ASEAN', 'SAARC', 'EU', 'NAFTA'], 1),
        _blank('The headquarters of SAARC is located in ____.',
            <String>['Kathmandu']),
      ]),
      _DemoQuiz('demo_quiz_pak_con', 'Constitution', 'demo_topic_pak_con',
          'Constitution', <QuizQuestion>[
        _mcq('How many articles are broadly grouped in the 1973 Constitution?',
            <String>['Around 280', 'Exactly 100', 'Around 50', 'Around 500'], 0),
        _tf('The 1973 Constitution established a parliamentary system.', true),
      ]),
      _DemoQuiz('demo_quiz_pak_geo', 'Geography', 'demo_topic_pak_geo',
          'Geography', <QuizQuestion>[
        _mcq('Which is the highest peak in Pakistan?',
            <String>['Nanga Parbat', 'K2', 'Tirich Mir', 'Rakaposhi'], 1),
        _blank('The ____ river is the longest in Pakistan.',
            <String>['Indus']),
      ]),
    ],
  ),
  _DemoSubject(
    'demo_subj_eng', 'English', _iBook, 0xFF1565C0, 1,
    const <_DemoTopic>[],
    <_DemoQuiz>[
      _DemoQuiz('demo_quiz_eng_gr', 'Grammar Basics', '', null, <QuizQuestion>[
        _mcq('Which word is a noun?',
            <String>['Quickly', 'Happiness', 'Run', 'Blue'], 1),
        _tf('An adjective describes a noun.', true),
      ]),
      _DemoQuiz('demo_quiz_eng_tn', 'Tenses', '', null, <QuizQuestion>[
        _mcq('Choose the past tense of "go".',
            <String>['goed', 'gone', 'went', 'going'], 2),
        _blank('The present continuous of "eat" (I ___ eating) uses ____.',
            <String>['am']),
      ]),
      _DemoQuiz('demo_quiz_eng_vc', 'Vocabulary', '', null, <QuizQuestion>[
        _mcq('A synonym of "happy" is:',
            <String>['sad', 'joyful', 'angry', 'tired'], 1),
        _mcq('An antonym of "increase" is:',
            <String>['expand', 'reduce', 'grow', 'raise'], 1),
      ]),
      _DemoQuiz('demo_quiz_eng_pr', 'Prepositions', '', null, <QuizQuestion>[
        _mcq('She is good ___ mathematics.',
            <String>['at', 'in', 'on', 'of'], 0),
        _tf('"Between" is used for two things.', true),
      ]),
      _DemoQuiz('demo_quiz_eng_sy', 'Synonyms & Antonyms', '', null,
          <QuizQuestion>[
        _mcq('A synonym of "big" is:',
            <String>['tiny', 'large', 'narrow', 'short'], 1),
        _blank('The antonym of "hot" is ____.', <String>['cold']),
      ]),
    ],
  ),
  _DemoSubject(
    'demo_subj_isl', 'Islamic Studies', _iMosque, 0xFF2E7D32, 2,
    const <_DemoTopic>[],
    <_DemoQuiz>[
      _DemoQuiz('demo_quiz_isl_p', 'Pillars', '', null, <QuizQuestion>[
        _mcq('How many pillars of Islam are there?',
            <String>['3', '4', '5', '6'], 2),
        _tf('Salah (prayer) is one of the pillars of Islam.', true),
      ]),
      _DemoQuiz('demo_quiz_isl_q', 'The Quran', '', null, <QuizQuestion>[
        _mcq('How many chapters (Surahs) are in the Quran?',
            <String>['100', '114', '120', '99'], 1),
        _blank('The first Surah of the Quran is Al-____.',
            <String>['Fatiha', 'Fatihah']),
      ]),
      _DemoQuiz('demo_quiz_isl_f', 'Fasting', '', null, <QuizQuestion>[
        _mcq('In which month do Muslims fast?',
            <String>['Rajab', 'Ramadan', 'Shaban', 'Muharram'], 1),
        _tf('Fasting is observed from dawn to sunset.', true),
      ]),
      _DemoQuiz('demo_quiz_isl_h', 'Hajj', '', null, <QuizQuestion>[
        _mcq('Hajj is performed in which city?',
            <String>['Madinah', 'Makkah', 'Jerusalem', 'Cairo'], 1),
        _tf('Hajj is obligatory once for those who are able.', true),
      ]),
      _DemoQuiz('demo_quiz_isl_e', 'Eid', '', null, <QuizQuestion>[
        _mcq('Which Eid follows Ramadan?',
            <String>['Eid al-Adha', 'Eid al-Fitr', 'Eid Milad', 'Shab-e-Barat'],
            1),
        _blank('Eid al-____ is the festival of sacrifice.', <String>['Adha']),
      ]),
    ],
  ),
  _DemoSubject(
    'demo_subj_sci', 'General Science', _iScience, 0xFF6A1B9A, 3,
    const <_DemoTopic>[],
    <_DemoQuiz>[
      _DemoQuiz('demo_quiz_sci_ph', 'Physics Basics', '', null, <QuizQuestion>[
        _mcq('What is the SI unit of force?',
            <String>['Joule', 'Newton', 'Watt', 'Pascal'], 1),
        _tf('Light travels faster than sound.', true),
      ]),
      _DemoQuiz('demo_quiz_sci_ch', 'Chemistry Basics', '', null,
          <QuizQuestion>[
        _blank('The chemical formula of water is ____.',
            <String>['H2O', 'h2o']),
        _mcq('Which gas do plants absorb for photosynthesis?',
            <String>['Oxygen', 'Nitrogen', 'Carbon dioxide', 'Hydrogen'], 2),
      ]),
      _DemoQuiz('demo_quiz_sci_bi', 'Biology Basics', '', null, <QuizQuestion>[
        _mcq('Which organ pumps blood in the human body?',
            <String>['Liver', 'Heart', 'Lung', 'Kidney'], 1),
        _tf('Humans have 206 bones as adults.', true),
      ]),
      _DemoQuiz('demo_quiz_sci_sp', 'Space', '', null, <QuizQuestion>[
        _mcq('Which planet is known as the Red Planet?',
            <String>['Venus', 'Mars', 'Jupiter', 'Saturn'], 1),
        _blank('The Earth\'s natural satellite is the ____.',
            <String>['Moon']),
      ]),
      _DemoQuiz('demo_quiz_sci_hb', 'Human Body', '', null, <QuizQuestion>[
        _mcq('How many lungs does a human have?',
            <String>['1', '2', '3', '4'], 1),
        _tf('The skin is the largest organ of the human body.', true),
      ]),
    ],
  ),
];
