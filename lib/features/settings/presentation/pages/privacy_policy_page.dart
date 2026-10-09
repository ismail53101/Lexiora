import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// In-app Privacy Policy. The content below mirrors the publicly hosted
/// privacy policy in docs/privacy-policy.html.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const _Section(
            title: 'Accounts and information you provide',
            body:
                'DarsNexa can be used without signing in for free use of the app '
                'and its available features. Signing in is optional for users '
                'who only want to use the free version.\n\n'
                'An account is required only when a user chooses to purchase '
                'or use a Premium membership. When signing in or creating an '
                'account for Premium, the user may provide information such as '
                'an email address and other account-related information required '
                'by the authentication and membership system.\n\n'
                'Users are not required to sign in unless they choose to use '
                'features that require an account, such as Premium membership. '
                'DarsNexa does not sell users\' personal information.',
          ),
          const _Section(
            title: 'Data stored on your device',
            body:
                'Where applicable, library data, highlights, notes, bookmarks, '
                'reading progress, saved vocabulary and locally stored AI '
                'conversation history remain on your device. PDFs are accessed '
                'locally and are not uploaded merely for reading. Account-related '
                'information required for Premium may be processed by the '
                'authentication and membership services.',
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
                'the online services used by DarsNexa.',
          ),
          const _Section(
            title: 'Advertising and Google AdMob',
            body:
                'DarsNexa currently uses Google AdMob for advertising. Google '
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
                'DarsNexa is intended for students and general users rather '
                'than specifically for children under 13. Free use of the app '
                'does not require an account or ask users to provide age or '
                'other personal information. We do not knowingly collect '
                'personal information from children. Parents or guardians '
                'with questions can contact us at darsnexa.app@gmail.com.',
            linkEmail: true,
          ),
          const _Section(
            title: 'Data security and retention',
            body:
                'Local app data remains on the user\'s device unless the user '
                'actively uses a feature that transmits information to an '
                'online service. DarsNexa does not maintain a cloud account for '
                'local study history in the current version. Account-related '
                'information required for Premium may be processed by the '
                'authentication and membership services.',
          ),
          const _Section(
            title: 'Changes to this policy',
            body:
                'We may update this policy when DarsNexa\'s features, services '
                'or data practices change. The hosted policy\'s effective '
                'date indicates when the current version was last updated.',
          ),
          const _Section(
            title: 'Contact',
            body:
                'Questions about this policy or DarsNexa\'s privacy practices? '
                'Contact us at darsnexa.app@gmail.com.',
            linkEmail: true,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body, this.linkEmail = false});

  final String title;
  final String body;
  final bool linkEmail;

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
          linkEmail
              ? Text.rich(
                  _emailLinkedText(
                    body,
                    theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                  ),
                )
              : Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
        ],
      ),
    );
  }
}

TextSpan _emailLinkedText(String text, TextStyle? style) {
  const email = 'darsnexa.app@gmail.com';
  final emailStart = text.indexOf(email);
  if (emailStart == -1) {
    return TextSpan(text: text, style: style);
  }

  return TextSpan(
    style: style,
    children: [
      TextSpan(text: text.substring(0, emailStart)),
      TextSpan(
        text: email,
        style: style?.copyWith(color: Colors.blue),
        recognizer: TapGestureRecognizer()..onTap = _openEmail,
      ),
      TextSpan(text: text.substring(emailStart + email.length)),
    ],
  );
}

Future<void> _openEmail() async {
  await launchUrl(
    Uri(scheme: 'mailto', path: 'darsnexa.app@gmail.com'),
    mode: LaunchMode.externalApplication,
  );
}
