import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../database/app_database.dart';
import '../../database/daos/teacher_dao.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class CreateAssignmentScreen extends ConsumerStatefulWidget {
  const CreateAssignmentScreen({super.key});

  @override
  ConsumerState<CreateAssignmentScreen> createState() =>
      _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState
    extends ConsumerState<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  List<ClassesWithDivision> _classes = [];
  bool _isLoading = true;
  bool _isSaving = false;
  int? _classIndex;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final session = ref.read(authStateProvider);
    final teacherId = session.userId ?? 0;
    final classes = await ref
        .read(teacherDaoProvider)
        .getClassesForTeacher(teacherId);
    if (!mounted) return;
    setState(() {
      _classes = classes;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: now,
      lastDate: DateTime(now.year + 3),
      helpText: 'Due Date',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate),
    );
    if (time == null || !mounted) return;
    setState(() {
      _dueDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_classIndex == null) {
      await showAppSnackBar(
          context, 'Please select a class & division', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final session = ref.read(authStateProvider);
      final cls = _classes[_classIndex!];
      await ref.read(homeworkDaoProvider).createAssignment(
            HomeworkAssignmentsCompanion.insert(
              teacherId: session.userId ?? 0,
              classId: cls.classData.id,
              divisionId: cls.divisionData.id,
              schoolId: session.schoolId ?? 1,
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? const Value(null)
                  : Value(_descriptionController.text.trim()),
              dueDate: _dueDate,
            ),
          );
      if (!mounted) return;
      await showAppSnackBar(context, 'Assignment created');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      await showAppSnackBar(context, 'Error: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Assignment')),
      body: _isLoading
          ? const LoadingIndicator()
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: Validators.required,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Instructions / Description',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _classIndex,
                    hint: const Text('Select Class & Division'),
                    items: [
                      for (var i = 0; i < _classes.length; i++)
                        DropdownMenuItem(
                          value: i,
                          child: Text(
                              'Class ${_classes[i].classData.name} - Division ${_classes[i].divisionData.name}'),
                        ),
                    ],
                    onChanged: (v) => setState(() => _classIndex = v),
                  ),
                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Due Date & Time',
                      border: OutlineInputBorder(),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_outlined),
                      title: Text(Formatters.formatDateTime(_dueDate)),
                      trailing: TextButton(
                        onPressed: _pickDueDate,
                        child: const Text('Pick'),
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
            label: 'Create Assignment',
            icon: Icons.add,
            isLoading: _isSaving,
            onPressed: _save,
          ),
        ),
      ),
    );
  }
}