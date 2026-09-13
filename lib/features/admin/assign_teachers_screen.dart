import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/app_database.dart';
import '../../database/daos/class_dao.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class AssignTeachersScreen extends ConsumerStatefulWidget {
  const AssignTeachersScreen({super.key});

  @override
  ConsumerState<AssignTeachersScreen> createState() =>
      _AssignTeachersScreenState();
}

class _AssignTeachersScreenState extends ConsumerState<AssignTeachersScreen> {
  late Future<List<Teacher>> _teachersFuture;
  late Future<List<DivisionWithClass>> _divisionsFuture;
  int? _selectedTeacherId;
  int? _selectedDivisionId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _teachersFuture = ref.read(teacherDaoProvider).getActiveTeachers();
    _divisionsFuture = ref.read(classDaoProvider).getAllDivisionsWithClass();
    _loadCurrentAssignments();
  }

  Future<void> _loadCurrentAssignments() async {}

  Future<void> _assign() async {
    if (_selectedTeacherId == null || _selectedDivisionId == null) {
      await showAppSnackBar(context,
          'Select both a teacher and a class/division', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dao = ref.read(teacherDaoProvider);
      final schoolId = ref.read(authStateProvider).schoolId ?? 1;
      final divisionsWithClass = await _divisionsFuture;
      final selected = divisionsWithClass
          .firstWhere((d) => d.division.id == _selectedDivisionId);

      await dao.assignTeacherToClass(TeacherClassAssignmentsCompanion.insert(
        teacherId: _selectedTeacherId!,
        classId: selected.classData.id,
        divisionId: _selectedDivisionId!,
        schoolId: schoolId,
      ));

      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedTeacherId = null;
          _selectedDivisionId = null;
        });
        await showAppSnackBar(context, 'Teacher assigned successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        await showAppSnackBar(
          context,
          e.toString().contains('UNIQUE')
              ? 'This teacher is already assigned to that division'
              : 'Error: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Teachers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                FutureBuilder<List<Teacher>>(
                  future: _teachersFuture,
                  builder: (context, snapshot) {
                    final teachers = snapshot.data ?? [];
                    return DropdownButtonFormField<int>(
                      initialValue: _selectedTeacherId,
                      hint: const Text('Select Teacher'),
                      items: teachers
                          .map((t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(t.name),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedTeacherId = v),
                    );
                  },
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<DivisionWithClass>>(
                  future: _divisionsFuture,
                  builder: (context, snapshot) {
                    final divisions = snapshot.data ?? [];
                    return DropdownButtonFormField<int>(
                      initialValue: _selectedDivisionId,
                      hint: const Text('Select Class / Division'),
                      items: divisions
                          .map((d) => DropdownMenuItem(
                                value: d.division.id,
                                child: Text('Class ${d.classData.name} - '
                                    'Division ${d.division.name}'),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedDivisionId = v),
                    );
                  },
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Assign Teacher',
                  icon: Icons.how_to_reg,
                  isLoading: _isLoading,
                  onPressed: _assign,
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(child: _CurrentAssignments()),
        ],
      ),
    );
  }
}

class _CurrentAssignments extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync =
        ref.watch(allAssignmentsStreamProvider);

    return assignmentsAsync.when(
      data: (assignments) {
        if (assignments.isEmpty) {
          return const EmptyStateWidget(
            message: 'No assignments yet',
            hint: 'Assign a teacher to a class and division',
            icon: Icons.how_to_reg_outlined,
          );
        }
        return FutureBuilder(
          future: _buildAssignmentList(context, ref, assignments),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LoadingIndicator();
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return const EmptyStateWidget(
                message: 'No assignments yet',
                icon: Icons.how_to_reg_outlined,
              );
            }
            return ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'Current Assignments',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ...items,
              ],
            );
          },
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => ErrorDisplay(message: '$e'),
    );
  }

  Future<List<Widget>> _buildAssignmentList(
    BuildContext context,
    WidgetRef ref,
    List<TeacherClassAssignment> assignments,
  ) async {
    final teacherDao = ref.read(teacherDaoProvider);
    final classDao = ref.read(classDaoProvider);
    final widgets = <Widget>[];

    for (final assignment in assignments) {
      final teacher = await teacherDao.getTeacherById(assignment.teacherId);
      final cls = await classDao.getClassById(assignment.classId);
      final division =
          await classDao.getDivisionById(assignment.divisionId);

      widgets.add(
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple.withValues(alpha: 0.15),
              child: const Icon(Icons.person, color: Colors.purple),
            ),
            title: Text(teacher?.name ?? 'Unknown Teacher'),
            subtitle: Text(
                'Class ${cls?.name ?? '?'} - Division ${division?.name ?? '?'}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Theme.of(context).colorScheme.error,
              tooltip: 'Remove assignment',
              onPressed: () async {
                final confirmed = await ConfirmationDialog(
                  title: 'Remove Assignment',
                  message: 'Remove ${teacher?.name ?? ''} from '
                      'Class ${cls?.name ?? ''}-${division?.name ?? ''}?',
                ).show(context);
                if (confirmed && context.mounted) {
                  await teacherDao
                      .removeTeacherClassAssignment(assignment.id);
                }
              },
            ),
          ),
        ),
      );
    }
    return widgets;
  }
}