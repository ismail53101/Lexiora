import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// The public, hosted copy of this policy (served from the repo's `docs/`
/// folder via GitHub Pages). Shown to users who tap "Open in browser".
const String kPrivacyPolicyUrl =
    'https://ismail53101.github.io/Lexiora/privacy-policy.html';

/// In-app Privacy Policy. Sapiora is offline-first, so the text below mirrors
/// the hosted policy at [kPrivacyPolicyUrl] — keep the two in sync when the
/// policy changes.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _Section(
            title: 'No account, no ads, no tracking',
            body:
                'Sapiora does not require an account and does not collect your '
                'name, email or phone number. It shows no ads and uses no '
                'analytics, advertising identifiers or third-party trackers.',
          ),
          _Section(
            title: 'Data stored on your device',
            body:
                'Your library, highlights, notes, bookmarks, reading progress '
                'and saved vocabulary stay in Sapiora\u2019s private on-device '
                'storage. PDFs you read are referenced in place, never copied. '
                'Your AI Assistant conversations are stored locally too.',
          ),
          _Section(
            title: 'When information leaves your device',
            body:
                'Only when you actively use a networked feature: if a word has '
                'no offline translation, the selected text is sent to Google '
                'Translate to fetch a translation; and when you message the AI '
                'Assistant (including any photo you attach), your prompt is sent '
                'to the AI service configured by the developer to generate a '
                'reply. Nothing is sold or shared.',
          ),
          _Section(
            title: 'Permissions',
            body:
                'All-files access lists the PDFs already on your device so you '
                'can open them in the reader (files are never modified or '
                'uploaded). Camera is used only when you attach a photo to the '
                'AI Assistant. Internet is used only for Translation and the AI '
                'Assistant.',
          ),
          _Section(
            title: 'Children\u2019s privacy',
            body:
                'Sapiora is not directed at children under 13 and does not '
                'knowingly collect personal information from them.',
          ),
          _Section(
            title: 'Contact',
            body:
                'Questions about this policy or the app? Contact us at '
                'support@sapiora.app.',
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Open in browser'),
            onPressed: () => _openUrl(context),
          ),
          const SizedBox(height: 6),
          Text(
            kPrivacyPolicyUrl,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(BuildContext context) async {
    final Uri uri = Uri.parse(kPrivacyPolicyUrl);
    final bool opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not open the browser.')),
        );
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}
