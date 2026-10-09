import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexiora/core/constants/app_constants.dart';
import 'package:lexiora/core/services/app_update_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lexiora/core/theme/app_theme.dart';
import 'package:lexiora/core/widgets/global_banner_host.dart';
import 'package:lexiora/features/settings/domain/entities/app_settings.dart';
import 'package:lexiora/features/settings/presentation/providers/settings_providers.dart';

/// Root widget. Binds the reactive [settingsProvider] to the Material 3 theme
/// (light/dark) and the global text scale, and drives navigation from the
/// module-assembled [GoRouter].
class SapioraApp extends ConsumerStatefulWidget {
  const SapioraApp({super.key, required this.router});

  final GoRouter router;

  @override
  ConsumerState<SapioraApp> createState() => _SapioraAppState();
}

class _SapioraAppState extends ConsumerState<SapioraApp> {
  bool _namePromptScheduled = false;
  bool _updateCheckScheduled = false;
  bool _updateDialogShowing = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AppSettings> settings = ref.watch(settingsProvider);
    final String displayName = settings.maybeWhen(
      data: (AppSettings s) => s.displayName.trim(),
      orElse: () => '',
    );
    if (!_updateCheckScheduled) {
      _updateCheckScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_checkMandatoryUpdate());
      });
    }
    if (!_namePromptScheduled && settings.hasValue && displayName.isEmpty) {
      _namePromptScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_showNameSetupDialog());
      });
    }
    final ThemeMode selectedThemeMode = settings.maybeWhen(
      data: (AppSettings s) => s.themeMode,
      orElse: () => ThemeMode.light,
    );
    // Keep the System option available in settings, but use the app's light
    // theme for it instead of inheriting a device-wide dark appearance.
    final ThemeMode themeMode = selectedThemeMode == ThemeMode.system
        ? ThemeMode.light
        : selectedThemeMode;
    final double fontScale = settings.maybeWhen(
      data: (AppSettings s) => s.fontScale,
      orElse: () => 1.0,
    );

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: widget.router,
      builder: (BuildContext context, Widget? child) {
        final MediaQueryData mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(fontScale)),
          child: GlobalBannerHost(
            router: widget.router,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  Future<void> _checkMandatoryUpdate() async {
    final AppUpdateService service = AppUpdateService();
    try {
      final UpdatePolicy? policy = await service.fetchPolicy();
      if (!mounted || policy == null || _updateDialogShowing) return;
      _updateDialogShowing = true;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text(policy.title),
            content: Text(policy.message),
            actions: <Widget>[
              FilledButton(
                onPressed: () async {
                  final Uri uri = Uri.parse(policy.storeUrl);
                  final bool opened = await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );
                  if (!opened && dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Could not open Play Store. Please try again.'),
                      ),
                    );
                  }
                },
                child: const Text('UPDATE NOW'),
              ),
            ],
          ),
        ),
      );
    } catch (_) {
      // Update checks must never prevent users from opening the learning app.
    } finally {
      _updateDialogShowing = false;
      service.dispose();
    }
  }

  Future<void> _showNameSetupDialog() async {
    final SettingsController controller = ref.read(settingsControllerProvider);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => _NameSetupDialog(
        onContinue: (String name) async {
          await controller.setDisplayName(name);
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
        },
      ),
    );
  }
}

class _NameSetupDialog extends StatefulWidget {
  const _NameSetupDialog({required this.onContinue});

  final Future<void> Function(String name) onContinue;

  @override
  State<_NameSetupDialog> createState() => _NameSetupDialogState();
}

class _NameSetupDialogState extends State<_NameSetupDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final String name = _controller.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.onContinue(name);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canContinue = _controller.text.trim().isNotEmpty && !_saving;
    return AlertDialog(
      title: const Text('What should we call you?'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(() {}),
        onSubmitted: canContinue ? (_) => _continue() : null,
        decoration: const InputDecoration(hintText: 'Enter your name'),
      ),
      actions: <Widget>[
        FilledButton(
          onPressed: canContinue ? _continue : null,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Continue'),
        ),
      ],
    );
  }
}