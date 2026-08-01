import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexiora/modules/admin/presentation/pages/admin_panel_page.dart';
import 'package:lexiora/modules/admin/presentation/providers/admin_providers.dart';

/// Gate in front of the Admin Panel: on first use, sets up a PIN; every time
/// after that, requires it before [AdminPanelPage] is shown. The PIN is
/// hashed (SHA-256) before being stored — see [AdminContentService] — never
/// kept in plain text.
class AdminLockPage extends ConsumerStatefulWidget {
  const AdminLockPage({super.key});

  @override
  ConsumerState<AdminLockPage> createState() => _AdminLockPageState();
}

class _AdminLockPageState extends ConsumerState<AdminLockPage> {
  final TextEditingController _pin = TextEditingController();
  final TextEditingController _confirmPin = TextEditingController();
  bool? _hasPin; // null while checking
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    _pin.dispose();
    _confirmPin.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final bool has = await ref.read(adminContentServiceProvider).hasPin();
    if (mounted) setState(() => _hasPin = has);
  }

  Future<void> _submitSetup() async {
    final String pin = _pin.text.trim();
    if (pin.length < 4) {
      setState(() => _error = 'PIN must be at least 4 digits.');
      return;
    }
    if (pin != _confirmPin.text.trim()) {
      setState(() => _error = 'PINs don\'t match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    await ref.read(adminContentServiceProvider).setPin(pin);
    if (mounted) _openPanel();
  }

  Future<void> _submitUnlock() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final bool ok =
        await ref.read(adminContentServiceProvider).verifyPin(_pin.text.trim());
    if (!mounted) return;
    if (ok) {
      _openPanel();
    } else {
      setState(() {
        _busy = false;
        _error = 'Incorrect PIN.';
        _pin.clear();
      });
    }
  }

  void _openPanel() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AdminPanelPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasPin == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final bool setup = !_hasPin!;

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  setup ? 'Set an Admin PIN' : 'Enter Admin PIN',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  setup
                      ? 'This keeps the Admin Panel hidden from regular use. '
                        'Choose a PIN you\'ll remember — it can\'t be recovered '
                        'if lost, only reset by clearing app data.'
                      : 'Protecting curated PDFs, links & notes.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _pin,
                  autofocus: true,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, letterSpacing: 6),
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '••••',
                  ),
                  onSubmitted: (_) => setup ? _submitSetup() : _submitUnlock(),
                ),
                if (setup) ...<Widget>[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPin,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, letterSpacing: 6),
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: 'Confirm PIN',
                    ),
                    onSubmitted: (_) => _submitSetup(),
                  ),
                ],
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : (setup ? _submitSetup : _submitUnlock),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(setup ? 'Set PIN & Continue' : 'Unlock'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
