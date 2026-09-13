import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../router/be_present_router.dart';
import '../../services/pin_service.dart';
import '../../widgets/common_widgets.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  final _controller = TextEditingController();
  bool _error = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _controller.text.trim();
    if (pin.length != 4) return;
    final ok = await ref.read(pinServiceProvider).verify(pin);
    if (!mounted) return;
    if (ok) {
      final auth = ref.read(authStateProvider);
      if (auth.isAuthenticated) {
        context.go(auth.isAdmin
            ? AppRoutes.adminDashboard.path
            : auth.isTeacher
                ? AppRoutes.teacherDashboard.path
                : AppRoutes.studentDashboard.path);
      } else {
        context.go(AppRoutes.login.path);
      }
    } else {
      setState(() => _error = true);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Enter PIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This app is protected by a PIN.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _error
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Incorrect PIN. Try again.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      textAlign: TextAlign.center,
                      maxLength: 4,
                      style:
                          theme.textTheme.headlineMedium?.copyWith(
                        letterSpacing: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      autofocus: true,
                      onSubmitted: (_) => _submit(),
                      onChanged: (_) {
                        if (_error) setState(() => _error = false);
                        if (_controller.text.length == 4) _submit();
                      },
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        hintText: '••••',
                        hintStyle: TextStyle(letterSpacing: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog used from Profile to setup / change / remove the app PIN.
Future<void> showPinSetupDialog(BuildContext context, WidgetRef ref) async {
  final pinService = ref.read(pinServiceProvider);
  final hasPin = await pinService.isPinSet();
  if (!context.mounted) return;

  if (!hasPin) {
    await _showSetPinDialog(context, ref);
    return;
  }

  final action = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.change_circle_outlined),
            title: const Text('Change PIN'),
            onTap: () => Navigator.pop(context, 'change'),
          ),
          ListTile(
            leading: const Icon(Icons.lock_open, color: Colors.red),
            title: const Text('Remove PIN'),
            onTap: () => Navigator.pop(context, 'remove'),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted) return;
  if (action == 'change') await _showSetPinDialog(context, ref);
  if (action == 'remove') await _showVerifyThenRemoveDialog(context, pinService);
}

Future<void> _showSetPinDialog(BuildContext context, WidgetRef ref) async {
  final newPin = await showDialog<String>(
    context: context,
    builder: (context) => const _PinInputDialog(title: 'Set PIN', confirmLabel: 'Save'),
  );
  if (newPin == null || !context.mounted) return;
  await ref.read(pinServiceProvider).setPin(newPin);
  if (context.mounted) {
    await showAppSnackBar(context, 'PIN set successfully');
  }
}

Future<void> _showVerifyThenRemoveDialog(
    BuildContext context, PinService pinService) async {
  final pin = await showDialog<String>(
    context: context,
    builder: (context) => const _PinInputDialog(
        title: 'Enter Current PIN', confirmLabel: 'Remove'),
  );
  if (pin == null || !context.mounted) return;
  final ok = await pinService.verify(pin);
  if (!context.mounted) return;
  if (ok) {
    await pinService.clearPin();
    await showAppSnackBar(context, 'PIN removed');
  } else {
    await showAppSnackBar(context, 'Incorrect PIN', isError: true);
  }
}

class _PinInputDialog extends StatefulWidget {
  final String title;
  final String confirmLabel;
  const _PinInputDialog({required this.title, required this.confirmLabel});

  @override
  State<_PinInputDialog> createState() => _PinInputDialogState();
}

class _PinInputDialogState extends State<_PinInputDialog> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    final p = _pin.text.trim();
    final c = _confirm.text.trim();
    if (p.length != 4) {
      showAppSnackBar(context, 'PIN must be 4 digits', isError: true);
      return;
    }
    if (p != c) {
      showAppSnackBar(context, 'PINs do not match', isError: true);
      return;
    }
    Navigator.pop(context, p);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pin,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              labelText: 'New PIN',
              counterText: '',
              hintText: '4 digits',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirm,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              labelText: 'Confirm PIN',
              counterText: '',
              hintText: 'Repeat the PIN',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}