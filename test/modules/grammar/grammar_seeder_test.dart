import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/constants/db_constants.dart';
import 'package:lexiora/core/database/app_database.dart';
import 'package:lexiora/modules/grammar/data/datasources/grammar_local_data_source.dart';
import 'package:lexiora/modules/grammar/data/grammar_seeder.dart';
import 'package:lexiora/modules/grammar/domain/entities/grammar_lesson.dart';

class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this._data);
  final Map<String, String> _data;

  @override
  Future<ByteData> load(String key) async {
    final String? s = _data[key];
    if (s == null) throw FlutterError('no fake asset "$key"');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(s)));
  }
}

void main() {
  late AppDatabase db;
  late GrammarLocalDataSource ds;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    ds = GrammarLocalDataSource(db);
  });

  tearDown(() async {
    await db.close();
  });

  const String tree = '''
  [
    {"id":"c","parentId":null,"title":"Category","order":1,"isLeaf":false},
    {"id":"c/l","parentId":"c","title":"Leaf","order":1,"isLeaf":true,
     "content":{"englishExplanation":"hello","rules":["r"],"practice":[],"quiz":[]}},
    {"title":"NoId","order":2}
  ]
  ''';

  test('seeds the tree, skips id-less nodes, and is idempotent', () async {
    final GrammarSeeder seeder = GrammarSeeder(
      ds,
      bundle: _FakeBundle(<String, String>{
        GrammarConstants.topicsAssetPath: tree,
      }),
    );

    await seeder.ensureSeeded();
    expect(await ds.topicCount(), 2, reason: 'the id-less node is skipped');
    expect(seeder.ready.value, isTrue);

    final GrammarLesson? leaf = await ds.leaf('c/l');
    expect(leaf, isNotNull);
    expect(leaf!.englishExplanation, 'hello');

    await seeder.ensureSeeded();
    expect(await ds.topicCount(), 2, reason: 'idempotent');
  });
}
