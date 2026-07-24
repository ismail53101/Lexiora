# Lexiora — Future Integration Guide

How to turn a placeholder module in `lib/modules/` into a real feature — or add
a brand-new one — **without editing any existing code**. This is the payoff of
the `FeatureModule` architecture.

---

## The golden path (5 steps)

Suppose we are implementing the **Dictionary** module.

### 1. (If you need storage) add a table + migration

In `core/database/tables.dart` add your table, register it in
`@DriftDatabase(tables: [...])` in `app_database.dart`, bump
`DbConstants.schemaVersion` and add an `onUpgrade` step. Existing tables are
untouched.

```dart
@DataClassName('DictionaryEntryRow')
class DictionaryEntries extends Table {
  TextColumn get id => text()();
  TextColumn get term => text()();
  TextColumn get definition => text()();
  @override Set<Column<Object>> get primaryKey => {id};
}
```

```dart
// app_database.dart
@override int get schemaVersion => 2; // was 1
@override MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) => m.createAll(),
  onUpgrade: (m, from, to) async {
    if (from < 2) await m.createTable(dictionaryEntries);
  },
);
```

### 2. Domain (pure Dart)

`lib/modules/dictionary/domain/`:

```dart
// entities/dictionary_entry.dart
class DictionaryEntry extends Equatable { /* ... */ }

// repositories/dictionary_repository.dart
abstract interface class DictionaryRepository {
  Future<DictionaryEntry?> lookup(String term);
}

// usecases/lookup_word.dart
class LookupWord implements UseCase<DictionaryEntry?, String> {
  const LookupWord(this._repo);
  final DictionaryRepository _repo;
  @override ResultFuture<DictionaryEntry?> call(String term) =>
      guard(() => _repo.lookup(term));
}
```

### 3. Data (implementation)

`lib/modules/dictionary/data/repositories/dictionary_repository_impl.dart` —
implement `DictionaryRepository` using `AppDatabase` (or a bundled asset, or an
API skill). Only this layer imports infrastructure.

### 4. Presentation

`lib/modules/dictionary/presentation/` — Riverpod providers (resolving the repo
from `sl`), a `DictionaryPage`, and any widgets. Same shape as every feature.

### 5. Wire it up in the module — then register it

Fill in the existing `DictionaryModule` (currently a no-op scaffold):

```dart
class DictionaryModule extends FeatureModule {
  @override String get id => 'dictionary';
  @override String get name => 'Dictionary';

  @override
  void registerDependencies(GetIt getIt) {
    getIt.registerLazySingleton<DictionaryRepository>(
      () => DictionaryRepositoryImpl(getIt<AppDatabase>()),
    );
    // Optional: contribute a tap-on-word action (see below).
    getIt<WordActionRegistry>().register(DefineWordAction(getIt()));
  }

  @override
  List<RouteBase> routes(GetIt getIt) => [
    GoRoute(path: '/dictionary', builder: (_, _) => const DictionaryPage()),
  ];

  @override
  List<HomeDestination> homeDestinations(GetIt getIt) => const [
    HomeDestination(
      id: 'dictionary', label: 'Dictionary', subtitle: 'Look up words',
      icon: Icons.menu_book_outlined, routePath: '/dictionary', order: 10,
    ),
  ];
}
```

`DictionaryModule` is already in `appModules` (as a placeholder), so **there is
nothing else to change** — DI, routing and the Home tile activate automatically.
If you are adding a *brand-new* module, the only edit to an existing file is
appending your module to the `appModules` list in
`lib/app/di/module_registry.dart`.

---

## Adding a tap-on-word action

The reader exposes a prepared extension point. Implement `WordAction` and
register it (step 5 above):

```dart
class DefineWordAction implements WordAction {
  DefineWordAction(this._lookup);
  final LookupWord _lookup;

  @override String get id => 'dictionary.define';
  @override String get label => 'Define';
  @override IconData get icon => Icons.menu_book_outlined;
  @override int get priority => 10;

  @override
  Future<void> invoke(BuildContext context, WordActionContext ctx) async {
    final result = await _lookup(ctx.word);
    // show a bottom sheet with the definition …
  }
}
```

Because the reader renders its word popup from `WordActionRegistry.actions`,
your action appears automatically. The same pattern serves Translation,
Grammar, Synonyms, Pronunciation and Save-to-Vocabulary.

---

## Checklist

- [ ] Table + migration (only if persisting data)
- [ ] `domain/` entities, repository interface, use cases
- [ ] `data/` repository implementation
- [ ] `presentation/` providers, page(s), widgets
- [ ] Fill in the module's `FeatureModule` (DI + routes + Home tile)
- [ ] New module only: append it to `appModules`
- [ ] `dart run build_runner build` (if you changed Drift), `flutter analyze`, `flutter test`

You never modify another feature to add yours. That is the whole point.
