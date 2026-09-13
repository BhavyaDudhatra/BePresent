import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;

import '../../core/utils/validators.dart';
import '../../database/app_database.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class AddEditStudentScreen extends ConsumerStatefulWidget {
  final int? studentId;

  const AddEditStudentScreen({super.key, this.studentId});

  @override
  ConsumerState<AddEditStudentScreen> createState() =>
      _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends ConsumerState<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rollController = TextEditingController();
  final _genderController = TextEditingController();
  final _dobController = TextEditingController();
  late Future<List<SchoolClass>> _classesFuture;
  List<SchoolClass> _classes = [];
  List<Division> _divisions = [];
  int? _selectedClassId;
  int? _selectedDivisionId;

  final List<({String name, String phone, String relationship, bool isPrimary})>
      _guardians = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _classesFuture = _loadClasses();
    _guardians.add((name: '', phone: '', relationship: 'Parent', isPrimary: true));
  }

  Future<List<SchoolClass>> _loadClasses() async {
    final classes = await ref.read(classDaoProvider).getAllClasses();
    if (mounted) {
      setState(() => _classes = classes);
    }
    if (widget.studentId != null) {
      await _loadStudent(widget.studentId!);
    }
    return classes;
  }

  Future<void> _loadStudent(int studentId) async {
    final dao = ref.read(studentDaoProvider);
    final student = await dao.getStudentById(studentId);
    final guardians = await dao.getGuardiansForStudent(studentId);
    if (!mounted || student == null) return;

    final division = await ref
        .read(classDaoProvider)
        .getDivisionById(student.divisionId);

    setState(() {
      _nameController.text = student.name;
      _rollController.text = student.rollNumber;
      _genderController.text = student.gender ?? '';
      _selectedDivisionId = student.divisionId;
      _selectedClassId = division?.classId;
      _guardians.clear();
      for (final g in guardians) {
        _guardians.add((
          name: g.name,
          phone: g.phone,
          relationship: g.relationship,
          isPrimary: g.isPrimary,
        ));
      }
      if (student.dateOfBirth != null) {
        _dobController.text =
            '${student.dateOfBirth!.year}-${student.dateOfBirth!.month.toString().padLeft(2, '0')}-${student.dateOfBirth!.day.toString().padLeft(2, '0')}';
      }
    });

    await _loadDivisions(division?.classId);
  }

  Future<void> _loadDivisions(int? classId) async {
    if (classId == null) return;
    final divisions =
        await ref.read(classDaoProvider).getDivisionsForClass(classId);
    if (!mounted) return;
    setState(() {
      _divisions = divisions;
      _selectedClassId = classId;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    _genderController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 365 * 10)),
      firstDate: DateTime(now.year - 60),
      lastDate: now,
      helpText: 'Select Date of Birth',
    );
    if (picked != null) {
      _dobController.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDivisionId == null) {
      await showAppSnackBar(context, 'Please select a class and division',
          isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dao = ref.read(studentDaoProvider);
      final schoolId = ref.read(authStateProvider).schoolId ?? 1;

      DateTime? dob;
      if (_dobController.text.isNotEmpty) {
        dob = DateTime.tryParse(_dobController.text);
      }

if (widget.studentId == null) {
        final studentId = await dao.createStudent(StudentsCompanion.insert(
          name: _nameController.text.trim(),
          rollNumber: _rollController.text.trim(),
gender: Value(_genderController.text.trim().isEmpty
              ? null
              : _genderController.text.trim()),
          dateOfBirth: Value(dob),
          divisionId: _selectedDivisionId!,
          schoolId: schoolId,
        ));

        for (final g in _guardians) {
          if (g.name.isNotEmpty && g.phone.isNotEmpty) {
            await dao.addParentGuardian(ParentGuardiansCompanion.insert(
              name: g.name.trim(),
              phone: g.phone.trim(),
              relationship: g.relationship,
              isPrimary: Value(g.isPrimary),
              studentId: studentId,
            ));
          }
        }
      } else {
        await dao.updateStudent(StudentsCompanion(
          id: Value(widget.studentId!),
          name: Value(_nameController.text.trim()),
          rollNumber: Value(_rollController.text.trim()),
          gender: Value(_genderController.text.trim().isEmpty
              ? null
              : _genderController.text.trim()),
          dateOfBirth: dob != null ? Value(dob) : const Value(null),
          divisionId: Value(_selectedDivisionId!),
        ));

        final existingGuardians =
            await dao.getGuardiansForStudent(widget.studentId!);
        for (var i = 0; i < existingGuardians.length; i++) {
          await dao.deleteParentGuardian(existingGuardians[i].id);
        }
        for (final g in _guardians) {
          if (g.name.isNotEmpty && g.phone.isNotEmpty) {
            await dao.addParentGuardian(ParentGuardiansCompanion.insert(
              name: g.name.trim(),
              phone: g.phone.trim(),
              relationship: g.relationship,
              isPrimary: Value(g.isPrimary),
              studentId: widget.studentId!,
            ));
          }
        }
      }

      if (mounted) {
        await showAppSnackBar(
            context, widget.studentId == null ? 'Student added' : 'Student updated');
        Navigator.of(context).pop();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studentId == null ? 'Add Student' : 'Edit Student'),
      ),
      body: FutureBuilder<List<SchoolClass>>(
        future: _classesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingIndicator();
          }
          if (snapshot.hasError) {
            return ErrorDisplay(message: '${snapshot.error}');
          }
          return _buildForm();
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryButton(
            label: widget.studentId == null ? 'Add Student' : 'Save Changes',
            icon: Icons.save,
            isLoading: _isLoading,
            onPressed: _save,
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionLabel('Student Information'),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Full Name'),
            validator: Validators.required,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _rollController,
                  decoration: const InputDecoration(labelText: 'Roll Number'),
                  validator: Validators.required,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _genderController.text.isEmpty
                      ? null
                      : _genderController.text,
                  hint: const Text('Gender'),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (value) =>
                      _genderController.text = value ?? '',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _dobController,
            decoration: const InputDecoration(
              labelText: 'Date of Birth',
              suffixIcon: Icon(Icons.calendar_today_outlined),
            ),
            readOnly: true,
            onTap: _pickDate,
          ),
          const SizedBox(height: 24),
          _SectionLabel('Class & Division'),
          DropdownButtonFormField<int>(
            initialValue: _selectedClassId,
            hint: const Text('Select Class'),
            items: _classes
                .map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text('Class ${c.name}'),
                    ))
                .toList(),
            onChanged: (value) async {
              setState(() {
                _selectedClassId = value;
                _selectedDivisionId = null;
              });
              await _loadDivisions(value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _selectedDivisionId,
            hint: const Text('Select Division'),
            items: _divisions
                .map((d) => DropdownMenuItem(
                      value: d.id,
                      child: Text('Division ${d.name}'),
                    ))
                .toList(),
            onChanged: (value) =>
                setState(() => _selectedDivisionId = value),
          ),
const SizedBox(height: 24),
          _SectionLabel('Parent / Guardian'),
          ..._guardians.asMap().entries.map((entry) {
            final index = entry.key;
            final guardian = entry.value;
            return _GuardianForm(
              key: ValueKey('guardian_$index'),
              index: index,
              initialGuardian: guardian,
              onChanged: (i, name, phone, relationship) {
                setState(() {
                  _guardians[i] = (
                    name: name,
                    phone: phone,
                    relationship: relationship,
                    isPrimary: _guardians[i].isPrimary,
                  );
                });
              },
              onAdd: index == _guardians.length - 1
                  ? () => setState(() {
                        _guardians.add((
                          name: '',
                          phone: '',
                          relationship: 'Parent',
                          isPrimary: false,
                        ));
                      })
                  : null,
              onRemove: () => setState(() => _guardians.removeAt(index)),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}


class _GuardianForm extends StatefulWidget {
  final int index;
  final ({String name, String phone, String relationship, bool isPrimary})
      initialGuardian;
  final void Function(int index, String name, String phone, String relationship)
      onChanged;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  const _GuardianForm({
    super.key,
    required this.index,
    required this.initialGuardian,
    required this.onChanged,
    this.onAdd,
    this.onRemove,
  });

  @override
  State<_GuardianForm> createState() => _GuardianFormState();
}

class _GuardianFormState extends State<_GuardianForm> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.initialGuardian.name);
  late final TextEditingController _phoneController =
      TextEditingController(text: widget.initialGuardian.phone);
  late String _relationship = widget.initialGuardian.relationship;

  @override
  void didUpdateWidget(covariant _GuardianForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialGuardian != oldWidget.initialGuardian) {
      if (_nameController.text != widget.initialGuardian.name) {
        _nameController.text = widget.initialGuardian.name;
      }
      if (_phoneController.text != widget.initialGuardian.phone) {
        _phoneController.text = widget.initialGuardian.phone;
      }
      if (_relationship != widget.initialGuardian.relationship) {
        _relationship = widget.initialGuardian.relationship;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      widget.index,
      _nameController.text.trim(),
      _phoneController.text.trim(),
      _relationship,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Guardian ${widget.index + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                  onPressed: widget.onAdd,
                  tooltip: 'Add another guardian',
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Colors.red),
                  onPressed: widget.index == 0 ? null : widget.onRemove,
                ),
              ],
            ),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Guardian Name'),
              onChanged: (_) => _emit(),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  v == null || v.isEmpty ? null : Validators.phone(v),
              onChanged: (_) => _emit(),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _relationship,
              decoration: const InputDecoration(labelText: 'Relationship'),
              items: const [
                DropdownMenuItem(value: 'Father', child: Text('Father')),
                DropdownMenuItem(value: 'Mother', child: Text('Mother')),
                DropdownMenuItem(value: 'Guardian', child: Text('Guardian')),
                DropdownMenuItem(value: 'Parent', child: Text('Parent')),
              ],
              onChanged: (v) {
                setState(() => _relationship = v ?? 'Parent');
                _emit();
              },
            ),
          ],
        ),
      ),
    );
  }
}
