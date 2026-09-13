import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/validators.dart';
import '../../database/app_database.dart';
import '../../providers/providers.dart';
import 'package:drift/drift.dart';
import '../../widgets/common_widgets.dart';

class ManageClassesScreen extends ConsumerWidget {
  const ManageClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(allClassesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Classes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditClassDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Class'),
      ),
      body: classesAsync.when(
        data: (classes) {
          if (classes.isEmpty) {
            return const EmptyStateWidget(
              message: 'No classes yet',
              hint: 'Tap "Add Class" to create your first class',
              icon: Icons.class_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: classes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final cls = classes[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.15),
                  child: const Icon(Icons.class_outlined, color: Colors.blue),
                ),
                title: Text('Class ${cls.name}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () =>
                          _showAddEditClassDialog(context, ref, cls),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Theme.of(context).colorScheme.error,
                      onPressed: () => _deleteClass(context, ref, cls),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorDisplay(message: '$e'),
      ),
    );
  }

  Future<void> _showAddEditClassDialog(
    BuildContext context,
    WidgetRef ref, [
    SchoolClass? cls,
  ]) async {
    final controller = TextEditingController(text: cls?.name ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(cls == null ? 'Add Class' : 'Edit Class'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Class Name',
              hintText: 'e.g. 8, 9, 11',
            ),
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (Validators.required(controller.text) != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Class name is required')),
                  );
                  return;
                }
                Navigator.pop(context, controller.text.trim());
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null && context.mounted) {
      try {
        final dao = ref.read(classDaoProvider);
        if (cls == null) {
          await dao.createClass(ClassesCompanion.insert(
            name: result,
            schoolId: ref.read(authStateProvider).schoolId ?? 1,
          ));
        } else {
          await dao.updateClass(ClassesCompanion(
            id: Value(cls.id),
            name: Value(result),
          ));
        }
        if (context.mounted) {
          await showAppSnackBar(context, cls == null ? 'Class added' : 'Class updated');
        }
      } catch (e) {
        if (context.mounted) {
          await showAppSnackBar(context, 'Error: $e', isError: true);
        }
      }
    }
  }

  Future<void> _deleteClass(BuildContext context, WidgetRef ref, SchoolClass cls) async {
    final confirmed = await ConfirmationDialog(
      title: 'Delete Class ${cls.name}',
      message: 'This will also delete divisions and students in this class. '
          'This action cannot be undone.',
    ).show(context);

    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(classDaoProvider).deleteClass(cls.id);
      if (context.mounted) {
        await showAppSnackBar(context, 'Class deleted');
      }
    } catch (e) {
      if (context.mounted) {
        await showAppSnackBar(context, 'Error: $e', isError: true);
      }
    }
  }
}