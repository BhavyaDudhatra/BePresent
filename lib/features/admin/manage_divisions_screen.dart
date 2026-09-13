import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/validators.dart';
import '../../database/app_database.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class ManageDivisionsScreen extends ConsumerWidget {
  const ManageDivisionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(allClassesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Divisions')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDivisionDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Division'),
      ),
      body: classesAsync.when(
        data: (classes) {
          if (classes.isEmpty) {
            return const EmptyStateWidget(
              message: 'Create classes first',
              hint: 'Manage Classes to add classes, then add divisions',
              icon: Icons.class_outlined,
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              for (final cls in classes)
                _ClassDivisionsSection(
                  cls: cls,
                  onAdd: () => _showAddDivisionDialog(context, ref, cls),
                  onEdit: (div) => _showEditDivisionDialog(context, ref, div),
                  onDelete: (div) => _deleteDivision(context, ref, div),
                ),
            ],
          );
        },
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorDisplay(message: '$e'),
      ),
    );
  }

  Future<void> _showAddDivisionDialog(
    BuildContext context,
    WidgetRef ref, [
    SchoolClass? presetClass,
  ]) async {
    final classes = await ref.read(classDaoProvider).getAllClasses();
    if (!context.mounted || classes.isEmpty) return;

    SchoolClass? selectedClass = presetClass;
    final nameController = TextEditingController();

    var result = await showDialog<({SchoolClass cls, String name})>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Division'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<SchoolClass>(
                    initialValue: selectedClass ?? classes.first,
                    decoration: const InputDecoration(labelText: 'Class'),
                    items: classes.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text('Class ${c.name}'),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => selectedClass = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Division Name',
                      hintText: 'e.g. A, B, C',
                    ),
                    autofocus: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (selectedClass == null ||
                        Validators.required(nameController.text) != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Class is required and division name is required'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(
                      context,
                      (cls: selectedClass!, name: nameController.text.trim()),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && context.mounted) {
      try {
        final dao = ref.read(classDaoProvider);
        await dao.createDivision(DivisionsCompanion.insert(
          name: result.name,
          classId: result.cls.id,
          schoolId: ref.read(authStateProvider).schoolId ?? 1,
        ));
        if (context.mounted) {
          await showAppSnackBar(context, 'Division added');
        }
      } catch (e) {
        if (context.mounted) {
          await showAppSnackBar(context, 'Error: $e', isError: true);
        }
      }
    }
  }

  Future<void> _showEditDivisionDialog(
    BuildContext context,
    WidgetRef ref,
    Division division,
  ) async {
    final controller = TextEditingController(text: division.name);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Division'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Division Name'),
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
                    const SnackBar(content: Text('Division name is required')),
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
        await ref.read(classDaoProvider).updateDivision(
          DivisionsCompanion(id: Value(division.id), name: Value(result)),
        );
        if (context.mounted) {
          await showAppSnackBar(context, 'Division updated');
        }
      } catch (e) {
        if (context.mounted) {
          await showAppSnackBar(context, 'Error: $e', isError: true);
        }
      }
    }
  }

  Future<void> _deleteDivision(
    BuildContext context,
    WidgetRef ref,
    Division division,
  ) async {
    final confirmed = await ConfirmationDialog(
      title: 'Delete Division ${division.name}',
      message: 'This will delete all students in this division. '
          'This action cannot be undone.',
    ).show(context);

    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(classDaoProvider).deleteDivision(division.id);
      if (context.mounted) {
        await showAppSnackBar(context, 'Division deleted');
      }
    } catch (e) {
      if (context.mounted) {
        await showAppSnackBar(context, 'Error: $e', isError: true);
      }
    }
  }
}

class _ClassDivisionsSection extends ConsumerWidget {
  final SchoolClass cls;
  final VoidCallback onAdd;
  final void Function(Division) onEdit;
  final void Function(Division) onDelete;

  const _ClassDivisionsSection({
    required this.cls,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final divisionsAsync = ref.watch(divisionsForClassProvider(cls.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Class ${cls.name}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        divisionsAsync.when(
          data: (divisions) {
            if (divisions.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('No divisions yet'),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: divisions.map((division) {
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.withValues(alpha: 0.15),
                      child: const Icon(Icons.grid_view, color: Colors.teal),
                    ),
                    title: Text('Division ${division.name}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => onEdit(division),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: Theme.of(context).colorScheme.error,
                          onPressed: () => onDelete(division),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          ),
          error: (e, _) => Text('Error: $e'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text('Add Division to Class ${cls.name}'),
          ),
        ),
      ],
    );
  }
}