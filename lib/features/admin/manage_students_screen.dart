import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';
import '../../router/be_present_router.dart';
import '../../database/app_database.dart';
import '../../widgets/common_widgets.dart';

class ManageStudentsScreen extends ConsumerStatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  ConsumerState<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends ConsumerState<ManageStudentsScreen> {
  int? _selectedClassId;
  int? _selectedDivisionId;
  late Future<List<SchoolClass>> _classesFuture;
  late Future<List<Division>> _divisionsFuture;

  @override
  void initState() {
    super.initState();
    _classesFuture = ref.read(classDaoProvider).getAllClasses();
    _divisionsFuture = Future.value([]);
  }

  void _loadDivisions(int classId) {
    setState(() {
      _selectedDivisionId = null;
      _divisionsFuture = ref.read(classDaoProvider).getDivisionsForClass(classId);
    });
  }

  Future<void> _deleteStudent(Student student) async {
    final confirmed = await ConfirmationDialog(
      title: 'Delete Student',
      message: 'Delete ${student.name}? All attendance records will be removed.',
    ).show(context);

    if (!confirmed || !mounted) return;

    try {
      await ref.read(studentDaoProvider).deleteStudent(student.id);
      if (mounted) {
        await showAppSnackBar(context, 'Student deleted');
      }
    } catch (e) {
      if (mounted) {
        await showAppSnackBar(context, 'Error: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Students')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: FutureBuilder<List<SchoolClass>>(
                    future: _classesFuture,
                    builder: (context, snapshot) {
                      final classes = snapshot.data ?? [];
                      return DropdownButtonFormField<int>(
                        initialValue: _selectedClassId,
                        hint: const Text('Select Class'),
                        items: classes
                            .map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text('Class ${c.name}'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedClassId = value);
                          if (value != null) _loadDivisions(value);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FutureBuilder<List<Division>>(
                    future: _divisionsFuture,
                    builder: (context, snapshot) {
                      final divisions = snapshot.data ?? [];
                      return DropdownButtonFormField<int>(
                        initialValue: _selectedDivisionId,
                        hint: const Text('Select Division'),
                        items: divisions
                            .map((d) => DropdownMenuItem(
                                  value: d.id,
                                  child: Text('Division ${d.name}'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedDivisionId = value);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedDivisionId == null
                ? const EmptyStateWidget(
                    message: 'Select a class and division',
                    hint: 'Students of the selected division will appear here',
                    icon: Icons.people_outline,
                  )
                : _StudentList(
                    divisionId: _selectedDivisionId!,
                    onEdit: (student) => context.push(
                      AppRoutes.adminEditStudent
                          .build({'studentId': '${student.id}'}),
                    ),
                    onDelete: _deleteStudent,
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminAddStudent.path),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Student'),
      ),
    );
  }
}

class _StudentList extends ConsumerWidget {
  final int divisionId;
  final void Function(Student) onEdit;
  final void Function(Student) onDelete;

  const _StudentList({
    required this.divisionId,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync =
        ref.watch(studentsByDivisionProvider(divisionId));

    return studentsAsync.when(
      data: (students) {
        if (students.isEmpty) {
          return const EmptyStateWidget(
            message: 'No students in this division',
            hint: 'Tap "Add Student" to add students',
            icon: Icons.person_add_alt_1,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: students.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final student = students[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.withValues(alpha: 0.15),
                child: Text(
                  student.name.isNotEmpty ? student.name[0] : '?',
                  style: const TextStyle(color: Colors.green),
                ),
              ),
              title: Text(student.name),
              subtitle: Text('Roll No: ${student.rollNumber}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => onEdit(student),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Theme.of(context).colorScheme.error,
                    onPressed: () => onDelete(student),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => ErrorDisplay(message: '$e'),
    );
  }
}