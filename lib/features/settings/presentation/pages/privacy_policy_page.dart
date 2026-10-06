import 'package:flutter/material.dart';

/// In-app Privacy Policy. The content below mirrors the publicly hosted
/// privacy policy in docs/privacy-policy.html.
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
          const _Section(
            title: 'Accounts and information you provide',
            body:
                'Sapiora can be used without an account in the current version. '
                'You do not need to provide your name, phone number or email '
                'address to use the core features. Sapiora does not sell users\' '
                'personal information.',
          ),
          const _Section(
            title: 'Data stored on your device',
            body:
                'Where applicable, library data, highlights, notes, bookmarks, '
                'reading progress, saved vocabulary and locally stored AI '
                'conversation history remain on your device. PDFs are accessed '
                'locally and are not uploaded merely for reading.',
          ),
          const _Section(
            title: 'Online features',
            body:
                'When you actively request a translation and an offline '
                'translation is unavailable, selected text may be sent to '
                'Google Translate. When you actively use the AI Assistant, '
                'your request and relevant content are sent to the AI backend '
                'or service configured by the developer. If you attach or '
                'capture an image for the AI Assistant, that image is '
                'transmitted to the configured AI service for processing. '
                'Online current-affairs/news features may also connect to '
                'the online services used by Sapiora.',
          ),
          const _Section(
            title: 'Advertising and Google AdMob',
            body:
                'Sapiora currently uses Google AdMob for advertising. Google '
                'or AdMob may process information such as device information '
                'or identifiers, advertising identifiers, IP address, '
                'approximate location and ad interaction information, as '
                'applicable. Depending on AdMob configuration, consent and '
                'settings, ads may be personalized or non-personalized.',
          ),
          const _Section(
            title: 'Permissions',
            body:
                'All-files access is used to discover PDFs already on your '
                'device so you can open them in the reader. Camera is used '
                'only when you choose to capture or attach an image for the '
                'AI Assistant. Internet/network access is used for online '
                'features such as AI Assistant, online translation, '
                'current-affairs/news retrieval and advertising.',
          ),
          const _Section(
            title: 'Children\'s privacy',
            body:
                'Sapiora is intended for students and general users rather '
                'than specifically for children under 13. The current version '
                'does not require an account or ask users to provide age or '
                'other personal information. We do not knowingly collect '
                'personal information from children. Parents or guardians '
                'with questions can contact us at sapiora.app@gmail.com.',
          ),
          const _Section(
            title: 'Data security and retention',
            body:
                'Local app data remains on the user\'s device unless the user '
                'actively uses a feature that transmits information to an '
                'online service. Sapiora does not maintain a user account or '
                'a cloud account for local study history in the current '
                'version.',
          ),
          const _Section(
            title: 'Changes to this policy',
            body:
                'We may update this policy when Sapiora\'s features, services '
                'or data practices change. The hosted policy\'s effective '
                'date indicates when the current version was last updated.',
          ),
          const _Section(
            title: 'Contact',
            body:
                'Questions about this policy or Sapiora\'s privacy practices? '
                'Contact us at sapiora.app@gmail.com.',
          ),
        ],
      ),
    );
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
