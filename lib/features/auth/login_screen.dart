import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../providers/providers.dart';
import '../../router/be_present_router.dart';
import '../../widgets/common_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rollController = TextEditingController();
  DateTime? _selectedDob;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _selectedRole = AppConstants.roleAdmin;

  bool get _isStudent => _selectedRole == AppConstants.roleStudent;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _rollController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 12),
      firstDate: DateTime(now.year - 25),
      lastDate: now,
      helpText: 'Select Date of Birth',
    );
    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = ref.read(authStateProvider.notifier);
      bool success = false;

      if (_selectedRole == AppConstants.roleAdmin) {
        success = await auth.loginAdmin(
          _usernameController.text.trim(),
          _passwordController.text,
        );
      } else if (_selectedRole == AppConstants.roleTeacher) {
        success = await auth.loginTeacher(
          _usernameController.text.trim(),
          _passwordController.text,
        );
      } else {
        final roll = _rollController.text.trim();
        success = roll.isNotEmpty && _selectedDob != null
            ? await auth.loginStudent(roll, _selectedDob!)
            : false;
      }

      if (!mounted) return;

      if (success) {
        await showAppSnackBar(context, 'Welcome!');
        if (mounted) {
          final session = ref.read(authStateProvider);
          if (session.isAdmin) {
            context.go(AppRoutes.adminDashboard.path);
          } else if (session.isTeacher) {
            context.go(AppRoutes.teacherDashboard.path);
          } else {
            context.go(AppRoutes.studentDashboard.path);
          }
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          await showAppSnackBar(
            context,
            'Invalid credentials. Please check and try again.',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      await showAppSnackBar(context, 'Login failed: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.school_rounded,
                      size: 72,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Be Present',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to continue',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: AppConstants.roleAdmin,
                          label: Text('Admin'),
                          icon: Icon(Icons.admin_panel_settings),
                        ),
                        ButtonSegment(
                          value: AppConstants.roleTeacher,
                          label: Text('Teacher'),
                          icon: Icon(Icons.person),
                        ),
                        ButtonSegment(
                          value: AppConstants.roleStudent,
                          label: Text('Student'),
                          icon: Icon(Icons.school_outlined),
                        ),
                      ],
                      selected: {_selectedRole},
                      onSelectionChanged: (selection) {
                        setState(() => _selectedRole = selection.first);
                      },
                    ),
                    const SizedBox(height: 24),
                    if (_isStudent) ...[
                      TextFormField(
                        controller: _rollController,
                        decoration: const InputDecoration(
                          labelText: 'Roll Number',
                          prefixIcon: Icon(Icons.tag),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) return 'Enter your roll number';
                          if (int.tryParse(v) == null) {
                            return 'Roll number must be a number';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        readOnly: true,
                        onTap: _pickDob,
                        controller: TextEditingController(
                          text: _selectedDob == null
                              ? ''
                              : Formatters.formatDate(_selectedDob!),
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth',
                          hintText: 'Tap to pick date',
                          prefixIcon: Icon(Icons.cake_outlined),
                        ),
                        validator: (value) {
                          if (_selectedDob == null) {
                            return 'Select your date of birth';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Students: use your roll number (e.g. 101) and date of '
                        'birth as shown in the school records.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: Validators.username,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                          ),
                        ),
                        validator: Validators.password,
                        obscureText: _obscurePassword,
                        onFieldSubmitted: (_) => _login(),
                      ),
                    ],
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: _isStudent ? 'Sign In as Student' : 'Sign In',
                      icon: Icons.login,
                      isLoading: _isLoading,
                      onPressed: _login,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isStudent
                          ? 'Preview account: Roll 101, DOB 12-05-2012 (Class 8A)'
                          : 'Preview accounts:\n'
                              'Admin: admin / admin123\n'
                              'Teacher: sharma / teacher123',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}