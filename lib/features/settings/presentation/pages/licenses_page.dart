import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:lexiora/core/constants/app_constants.dart';

/// One attributed data set: a title, a short summary, and the full license
/// text bundled with the app (kept under `assets/` so it stays in sync with
/// the shipped data).
class _LicenseEntry {
  const _LicenseEntry({
    required this.title,
    required this.summary,
    required this.assetPath,
  });

  final String title;
  final String summary;
  final String assetPath;
}

const List<_LicenseEntry> _entries = <_LicenseEntry>[
  _LicenseEntry(
    title: 'Dictionary data',
    summary:
        'Wordset (Creative Commons Attribution-ShareAlike 4.0) and WordNet 3.0 '
        '(Princeton University).',
    assetPath: 'assets/dictionary/DICTIONARY_LICENSE.txt',
  ),
  _LicenseEntry(
    title: 'Translation data',
    summary:
        'Bundled English\u2013Urdu translation set, distributed under the '
        'GNU General Public License v2.',
    assetPath: 'assets/translations/TRANSLATIONS_LICENSE.txt',
  ),
];

/// Licenses & Credits — the attribution required by the data sets bundled with
/// Sapiora (dictionary + translations), plus the open-source licenses of the
/// software the app is built on.
class LicensesPage extends StatefulWidget {
  const LicensesPage({super.key});

  @override
  State<LicensesPage> createState() => _LicensesPageState();
}

class _LicensesPageState extends State<LicensesPage> {
  final Map<String, String> _texts = <String, String>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final Map<String, String> texts = <String, String>{};
    for (final _LicenseEntry e in _entries) {
      try {
        texts[e.assetPath] = await rootBundle.loadString(e.assetPath);
      } on Object {
        texts[e.assetPath] = '(License text unavailable.)';
      }
    }
    if (mounted) {
      setState(() {
        _texts..clear()..addAll(texts);
        _loading = false;
      });
    }
  }

  void _showOpenSourceLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationLegalese:
          '${AppConstants.appName} is built with Flutter and open-source '
          'packages, each covered by its own license.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Licenses & Credits')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(
              'Sapiora includes data sets and software created by others. '
              'Their licenses are shown here, as required by each license.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Open-source software'),
                  subtitle: const Text(
                    'Flutter and the packages Sapiora is built with',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showOpenSourceLicenses(context),
                ),
                for (final _LicenseEntry e in _entries)
                  ExpansionTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(e.title),
                    subtitle: Text(
                      e.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    children: [
                      _loading
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: SelectableText(
                                _texts[e.assetPath] ?? '',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  height: 1.4,
                                ),
                              ),
                            ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
