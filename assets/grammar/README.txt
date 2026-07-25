Sapiora offline grammar lessons
===============================

grammar_lessons.json is the bundled, offline data set for the Grammar module
(Phase v0.4.0). It is a JSON array of lesson objects; each lesson carries its
category, title, summary, keywords and the full body (explanation, rules,
examples, notes, tips, common mistakes and multiple-choice practice questions).

On first launch the data set is seeded once into the app's local Drift/SQLite
database (the `grammar_lessons` table). Reading progress and saved (favorite)
lessons are stored in separate tables, so the lessons can be re-seeded to ship
new or updated content — by bumping GrammarConstants.datasetVersion and updating
this file — without ever affecting what the user has read or saved.

The lesson content is original material written for Sapiora and is covered by
the application's MIT license (see the repository LICENSE). No third-party data
is redistributed here.
