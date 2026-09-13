import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/validators.dart';
import '../../database/app_database.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class SchoolSettingsScreen extends ConsumerStatefulWidget {
  const SchoolSettingsScreen({super.key});

  @override
  ConsumerState<SchoolSettingsScreen> createState() =>
      _SchoolSettingsScreenState();
}

class _SchoolSettingsScreenState extends ConsumerState<SchoolSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _loaded = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSchool();
  }

  Future<void> _loadSchool() async {
    final schoolId = ref.read(authStateProvider).schoolId;
    if (schoolId == null) return;
    final school =
        await ref.read(schoolDaoProvider).getSchoolById(schoolId);
    if (school != null && mounted) {
      setState(() {
        _nameController.text = school.name;
        _addressController.text = school.address ?? '';
        _phoneController.text = school.phone ?? '';
        _emailController.text = school.email ?? '';
        _loaded = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final schoolId = ref.read(authStateProvider).schoolId!;
      final dao = ref.read(schoolDaoProvider);
      final school = await dao.getSchoolById(schoolId);
      if (school == null) {
await dao.createSchool(SchoolsCompanion.insert(
          name: _nameController.text.trim(),
          address: Value(_addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim()),
          phone: Value(_phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim()),
          email: Value(_emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim()),
        ));
      } else {
        await dao.updateSchool(SchoolsCompanion(
          id: Value(school.id),
          name: Value(_nameController.text.trim()),
          address: Value(_addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim()),
          phone: Value(_phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim()),
          email: Value(_emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim()),
        ));
      }

      if (mounted) {
        setState(() => _isLoading = false);
        await showAppSnackBar(context, 'School information updated');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        await showAppSnackBar(context, 'Error: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('School Settings')),
        body: const LoadingIndicator(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('School Settings')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            const Center(
              child: CircleAvatar(
                radius: 40,
                child: Icon(Icons.school_rounded, size: 40),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'School Name'),
              validator: Validators.required,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address (optional)',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 8),
            const Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.blueGrey, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This information is stored only on this device.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryButton(
            label: 'Save Settings',
            icon: Icons.save,
            isLoading: _isLoading,
            onPressed: _save,
          ),
        ),
      ),
    );
  }
}