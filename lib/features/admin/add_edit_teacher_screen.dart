import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/password_utils.dart';
import '../../core/utils/validators.dart';
import '../../database/app_database.dart';
import '../../providers/providers.dart';
import 'package:drift/drift.dart';
import '../../widgets/common_widgets.dart';

class AddEditTeacherScreen extends ConsumerStatefulWidget {
  final int? teacherId;
  const AddEditTeacherScreen({super.key, this.teacherId});

  @override
  ConsumerState<AddEditTeacherScreen> createState() =>
      _AddEditTeacherScreenState();
}

class _AddEditTeacherScreenState extends ConsumerState<AddEditTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isActive = true;
  bool _showPasswordField = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _showPasswordField = widget.teacherId == null;
    if (widget.teacherId != null) {
      _loadTeacher();
    }
  }

  Future<void> _loadTeacher() async {
    final teacher = await ref
        .read(teacherDaoProvider)
        .getTeacherById(widget.teacherId!);
    if (teacher != null && mounted) {
      setState(() {
        _nameController.text = teacher.name;
        _usernameController.text = teacher.username;
        _phoneController.text = teacher.phone ?? '';
        _emailController.text = teacher.email ?? '';
        _isActive = teacher.isActive;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dao = ref.read(teacherDaoProvider);
      final schoolId = ref.read(authStateProvider).schoolId ?? 1;

if (widget.teacherId == null) {
        await dao.createTeacher(TeachersCompanion.insert(
          name: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          passwordHash: PasswordUtils.hashPassword(_passwordController.text),
          phone: Value(_phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim()),
          email: Value(_emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim()),
          schoolId: schoolId,
        ));
      } else {
        await dao.updateTeacher(TeachersCompanion(
          id: Value(widget.teacherId!),
          name: Value(_nameController.text.trim()),
          username: Value(_usernameController.text.trim()),
          phone: Value(_phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim()),
          email: Value(_emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim()),
          isActive: Value(_isActive),
        ));
      }

      if (mounted) {
        await showAppSnackBar(
            context, widget.teacherId == null ? 'Teacher added' : 'Teacher updated');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (e.toString().contains('UNIQUE')) {
          await showAppSnackBar(context, 'Username already exists',
              isError: true);
        } else {
          await showAppSnackBar(context, 'Error: $e', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.teacherId == null ? 'Add Teacher' : 'Edit Teacher'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: Validators.required,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: Validators.username,
            ),
            const SizedBox(height: 12),
            if (_showPasswordField) ...[
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: Validators.password,
                obscureText: true,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              validator: Validators.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
            if (widget.teacherId != null) ...[
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v ?? true),
                title: const Text('Active account'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              Text(
                'Inactive teachers cannot log in but their records are retained.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryButton(
            label: widget.teacherId == null ? 'Add Teacher' : 'Save Changes',
            icon: Icons.save,
            isLoading: _isLoading,
            onPressed: _save,
          ),
        ),
      ),
    );
  }
}