import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../database/app_database.dart';
import '../../database/daos/attendance_dao.dart';
import '../../database/daos/class_dao.dart';
import '../../database/daos/student_dao.dart';
import '../../providers/providers.dart';
import '../../services/sms_service.dart';
import '../../widgets/common_widgets.dart';

class SendMessageScreen extends ConsumerStatefulWidget {
  const SendMessageScreen({super.key});

  @override
  ConsumerState<SendMessageScreen> createState() => _SendMessageScreenState();
}

class _SendMessageScreenState extends ConsumerState<SendMessageScreen> {
  DateTime _selectedDate = DateTime.now();
  int? _assignmentId;
  int? _selectedDivisionId;
  bool _includeAll = true;
  late final Future<List<DivisionWithClass>> _divisionsFuture;

  @override
  void initState() {
    super.initState();
    _divisionsFuture = ref.read(classDaoProvider).getAllDivisionsWithClass();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authStateProvider);
    final isAdmin = session.isAdmin;
    final teacherId = session.userId ?? 0;

    final recordsAsync = isAdmin
        ? _selectedDivisionId == null
            ? null
            : ref.watch(attendanceForDivisionAndDateProvider(
                (divisionId: _selectedDivisionId!, date: _selectedDate)))
        : _assignmentId == null
            ? null
            : ref.watch(allAttendanceWithDetailsProvider(
                (assignmentId: _assignmentId!, date: _selectedDate)));

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Send Attendance Reports' : 'Send Message'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _ScopeBar(
              isAdmin: isAdmin,
              teacherId: teacherId,
              divisionsFuture: _divisionsFuture,
              selectedDivisionId: _selectedDivisionId,
              selectedDate: _selectedDate,
              includeAll: _includeAll,
              onDivisionChanged: (id) =>
                  setState(() => _selectedDivisionId = id),
              onAssignmentChanged: (id) =>
                  setState(() => _assignmentId = id),
              onDateChanged: (d) => setState(() => _selectedDate = d),
              onIncludeAllChanged: (v) => setState(() => _includeAll = v),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: recordsAsync == null
                ? EmptyStateWidget(
                    message: isAdmin
                        ? 'Select a class / division and date'
                        : 'Select a class and date',
                    hint: 'Students with their attendance will appear here',
                    icon: Icons.sms_outlined,
                  )
                : _MessageArea(
                    recordsAsync: recordsAsync,
                    date: _selectedDate,
                    includeAll: _includeAll,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ScopeBar extends ConsumerStatefulWidget {
  final bool isAdmin;
  final int teacherId;
  final Future<List<DivisionWithClass>> divisionsFuture;
  final int? selectedDivisionId;
  final DateTime selectedDate;
  final bool includeAll;
  final void Function(int id) onDivisionChanged;
  final void Function(int id) onAssignmentChanged;
  final void Function(DateTime) onDateChanged;
  final void Function(bool) onIncludeAllChanged;

  const _ScopeBar({
    required this.isAdmin,
    required this.teacherId,
    required this.divisionsFuture,
    required this.selectedDivisionId,
    required this.selectedDate,
    required this.includeAll,
    required this.onDivisionChanged,
    required this.onAssignmentChanged,
    required this.onDateChanged,
    required this.onIncludeAllChanged,
  });

  @override
  ConsumerState<_ScopeBar> createState() => _ScopeBarState();
}

class _ScopeBarState extends ConsumerState<_ScopeBar> {
  int? _assignmentId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.isAdmin) ...[
              Expanded(
                child: _DivisionDropdown(
                  divisionsFuture: widget.divisionsFuture,
                  selectedId: widget.selectedDivisionId,
                  onChanged: widget.onDivisionChanged,
                ),
              ),
              const SizedBox(width: 8),
            ] else ...[
              Expanded(
                child: _AssignmentDropdown(
                  teacherId: widget.teacherId,
                  selectedId: _assignmentId,
                  onChanged: (id) {
                    setState(() => _assignmentId = id);
                    widget.onAssignmentChanged(id);
                  },
                ),
              ),
              const SizedBox(width: 8),
            ],
            OutlinedButton.icon(
              onPressed: () async {
                final today = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: widget.selectedDate,
                  firstDate: DateTime(today.year - 10),
                  lastDate: today,
                );
                if (picked != null) widget.onDateChanged(picked);
              },
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(Formatters.formatShortDate(widget.selectedDate)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                'Reports for the selected class & date go to each '
                'student\'s parent.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Include Present'),
              selected: widget.includeAll,
              onSelected: widget.onIncludeAllChanged,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }
}

class _DivisionDropdown extends StatelessWidget {
  final Future<List<DivisionWithClass>> divisionsFuture;
  final int? selectedId;
  final void Function(int id) onChanged;

  const _DivisionDropdown({
    required this.divisionsFuture,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DivisionWithClass>>(
      future: divisionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LinearProgressIndicator();
        }
        final divisions = snapshot.data ?? [];
        if (divisions.isEmpty) {
          return const Text('No classes available');
        }
        return DropdownButton<int>(
          value: selectedId,
          isExpanded: true,
          hint: const Text('Select Class / Division'),
          items: divisions
              .map((d) => DropdownMenuItem(
                    value: d.division.id,
                    child: Text(
                      'Class ${d.classData.name} - Division ${d.division.name}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        );
      },
    );
  }
}

class _AssignmentDropdown extends ConsumerWidget {
  final int teacherId;
  final int? selectedId;
  final void Function(int id) onChanged;

  const _AssignmentDropdown({
    required this.teacherId,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(assignmentsForTeacherProvider(teacherId));

    return assignmentsAsync.when(
      data: (assignments) {
        if (assignments.isEmpty) {
          return const Text('No classes assigned yet');
        }
        return FutureBuilder<Map<int, String>>(
          future: _buildLabels(ref, assignments),
          builder: (context, snapshot) {
            final labels = snapshot.data ?? const <int, String>{};
            return DropdownButton<int>(
              value: selectedId,
              isExpanded: true,
              hint: const Text('Select Class'),
              items: [
                for (final a in assignments)
                  DropdownMenuItem(
                    value: a.id,
                    child: Text(
                      labels[a.id] ?? 'Class ${a.classId}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            );
          },
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }

  Future<Map<int, String>> _buildLabels(
      WidgetRef ref, List<dynamic> assignments) async {
    final classDao = ref.read(classDaoProvider);
    final labels = <int, String>{};
    for (final a in assignments) {
      final cls = await classDao.getClassById(a.classId);
      final div = await classDao.getDivisionById(a.divisionId);
      labels[a.id] = 'Class ${cls?.name ?? '?'} - ${div?.name ?? '?'}';
    }
    return labels;
  }
}

class _MessageArea extends ConsumerWidget {
  final AsyncValue<List<AttendanceWithDetails>> recordsAsync;
  final DateTime date;
  final bool includeAll;

  const _MessageArea({
    required this.recordsAsync,
    required this.date,
    required this.includeAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return EmptyStateWidget(
            message: 'No attendance taken for '
                '${Formatters.formatDate(date)}',
            hint: 'Take attendance first, then send messages '
                'about absent students.',
            icon: Icons.event_busy,
          );
        }

        final selected = includeAll
            ? records
            : records.where((r) => r.status.name != 'present').toList();

        return Column(
          children: [
            Card(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _MiniStat('Total', '${records.length}',
                            Colors.blueGrey),
                        _MiniStat('Selected', '${selected.length}',
                            Colors.indigo),
                        _MiniStat('Present', '${_count(records, 'present')}',
                            AppTheme.presentColor),
                        _MiniStat(
                            'Absent+Late',
                            '${_count(records, 'absent') + _count(records, 'late')}',
                            AppTheme.absentColor),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        label: selected.isEmpty
                            ? 'No Parents To Message'
                            : 'Send Reports to All Parents',
                        icon: Icons.campaign_outlined,
                        backgroundColor: Colors.teal,
                        onPressed: selected.isEmpty
                            ? null
                            : () => _sendAll(context, ref, selected),
                      ),
                    ),
                    Text(
                      'Sends one SMS to each parent automatically. '
                      'An SMS permission prompt appears once.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: selected.length,
                itemBuilder: (context, index) {
                  final record = selected[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _statusColor(record.status.name)
                            .withValues(alpha: 0.15),
                        child: Icon(
                          _statusIcon(record.status.name),
                          color: _statusColor(record.status.name),
                        ),
                      ),
                      title: Text(record.student.name),
                      subtitle:
                          Text('Roll No: ${record.student.rollNumber}'),
                      trailing: const Icon(Icons.sms_outlined,
                          color: Colors.teal),
                      onTap: () => _sendForStudent(context, ref, record),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => ErrorDisplay(message: '$e'),
    );
  }

  int _count(List<AttendanceWithDetails> records, String status) =>
      records.where((r) => r.status.name == status).length;

  Future<List<_SmsRecipient>> _buildRecipients(
    WidgetRef ref,
    List<AttendanceWithDetails> records,
  ) async {
    final studentDao = ref.read(studentDaoProvider);
    final sms = ref.read(smsServiceProvider);
    final out = <_SmsRecipient>[];
    for (final r in records) {
      final details = await studentDao.getStudentWithDetails(r.student.id);
      if (details == null || details.guardians.isEmpty) continue;
      final guardian = details.guardians.firstWhere(
        (g) => g.isPrimary,
        orElse: () => details.guardians.first,
      );
      final className = details.classData?.name ?? '';
      final divisionName = details.division?.name ?? '';
      final message = switch (r.status.name) {
        'absent' => sms.buildAbsentMessage(
            studentName: r.student.name,
            className: className,
            divisionName: divisionName,
            date: date,
          ),
        'late' => sms.buildLateMessage(
            studentName: r.student.name,
            className: className,
            divisionName: divisionName,
            date: date,
          ),
        _ => sms.buildPresentMessage(
            studentName: r.student.name,
            className: className,
            divisionName: divisionName,
            date: date,
          ),
      };
      out.add(_SmsRecipient(
        record: r,
        details: details,
        guardian: guardian,
        message: message,
      ));
    }
    return out;
  }

  Future<void> _sendAll(
    BuildContext context,
    WidgetRef ref,
    List<AttendanceWithDetails> records,
  ) async {
    final recipients = await _buildRecipients(ref, records);
    if (!context.mounted) return;
    if (recipients.isEmpty) {
      await showAppSnackBar(
        context,
        'No parent phone numbers found for the selected students',
        isError: true,
      );
      return;
    }

    final confirmed = await ConfirmationDialog(
      title: 'Send to ${recipients.length} Parents?',
      message: 'One SMS will be sent to each parent automatically.\n\n'
          'Students included: ${recipients.length}\n'
          'No phone saved: ${records.length - recipients.length}\n\n'
          'You will be asked for SMS permission once. '
          'Messages are sent via your phone\'s SMS service.',
      confirmLabel: 'Send All Now',
      icon: Icons.campaign_outlined,
      isDestructive: false,
    ).show(context);

    if (!confirmed || !context.mounted) return;

    final sms = ref.read(smsServiceProvider);
    try {
      final sent = await sms.sendBatchSms([
        for (final r in recipients)
          (phone: r.guardian.phone, message: r.message),
      ]);
      if (context.mounted) {
        await _showBulkResult(context, sent, recipients.length);
      }
    } catch (e) {
      if (!context.mounted) return;
      final message = e is SmsException ? e.message : 'Unexpected error: $e';
      final fallback = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Sending Failed'),
          content: Text(
            '$message\n\n'
            'Would you like to open the SMS app for each parent '
            'one at a time instead?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Yes, Open SMS App'),
            ),
          ],
        ),
      );
      if (fallback == true && context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _SendQueueScreen(recipients: recipients),
          ),
        );
      }
    }
  }

  Future<void> _showBulkResult(
    BuildContext context,
    int sent,
    int total,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_outline,
          color: Colors.green,
          size: 48,
        ),
        title: const Text('Reports Sent'),
        content: Text(
          '$sent of $total reports were sent to parents successfully.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendForStudent(
    BuildContext context,
    WidgetRef ref,
    AttendanceWithDetails record,
  ) async {
    try {
      final studentDao = ref.read(studentDaoProvider);
      final sms = ref.read(smsServiceProvider);

      final details = await studentDao.getStudentWithDetails(record.student.id);
      if (details == null || details.guardians.isEmpty) {
        if (context.mounted) {
          await showAppSnackBar(context,
              'No parent phone number for ${record.student.name}',
              isError: true);
        }
        return;
      }

      final guardian = details.guardians.firstWhere(
        (g) => g.isPrimary,
        orElse: () => details.guardians.first,
      );

      final message = record.status.name == 'late'
          ? sms.buildLateMessage(
              studentName: record.student.name,
              className: details.classData?.name ?? '',
              divisionName: details.division?.name ?? '',
              date: date,
            )
          : record.status.name == 'absent'
              ? sms.buildAbsentMessage(
                  studentName: record.student.name,
                  className: details.classData?.name ?? '',
                  divisionName: details.division?.name ?? '',
                  date: date,
                )
              : sms.buildPresentMessage(
                  studentName: record.student.name,
                  className: details.classData?.name ?? '',
                  divisionName: details.division?.name ?? '',
                  date: date,
                );

      if (!context.mounted) return;

      final shouldSend = await _messagePreviewDialog(
        context,
        guardian.phone,
        guardian.name,
        message,
      );

      if (shouldSend != null && context.mounted) {
        await sms.composeSms(
          phoneNumber: shouldSend.phone,
          message: shouldSend.message,
        );
      }
    } catch (e) {
      if (context.mounted) {
        await showAppSnackBar(context, 'Error: $e', isError: true);
      }
    }
  }

  Future<({String phone, String message})?> _messagePreviewDialog(
    BuildContext context,
    String phone,
    String guardianName,
    String message,
  ) async {
    final phoneController = TextEditingController(text: phone);
    final messageController = TextEditingController(text: message);

    final result = await showDialog<({String phone, String message})>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Send to $guardianName'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message (editable)',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 6,
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'This opens your device\'s SMS app. '
                    'The message is sent using your normal phone service.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(
                context,
                (
                  phone: phoneController.text.trim(),
                  message: messageController.text,
                ),
              ),
              icon: const Icon(Icons.sms_outlined),
              label: const Text('Open SMS'),
            ),
          ],
        );
      },
    );

    return result;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present':
        return AppTheme.presentColor;
      case 'absent':
        return AppTheme.absentColor;
      case 'late':
        return AppTheme.lateColor;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }
}

class _SendQueueScreen extends StatefulWidget {
  final List<_SmsRecipient> recipients;
  const _SendQueueScreen({required this.recipients});

  @override
  State<_SendQueueScreen> createState() => _SendQueueScreenState();
}

class _SendQueueScreenState extends State<_SendQueueScreen> {
  final SmsService _sms = SmsService();
  int _index = 0;
  bool _opening = false;

  bool get _done => _index >= widget.recipients.length;

  Future<void> _openSms() async {
    final recipient = widget.recipients[_index];
    setState(() => _opening = true);
    try {
      await _sms.composeSms(
        phoneNumber: recipient.guardian.phone,
        message: recipient.message,
      );
    } catch (e) {
      if (mounted) {
        await showAppSnackBar(context, 'Could not open SMS: $e',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Reports to Parents')),
      body: _done ? _buildDone(context) : _buildStep(context),
    );
  }

  Widget _buildDone(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 72, color: Colors.green),
          const SizedBox(height: 16),
          Text('All ${widget.recipients.length} reports ready',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Each one was opened in your SMS app. Native SMS apps do not '
            'allow an app to auto-send, so please make sure you sent every '
            'message.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.done),
            label: const Text('Finish'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    final recipient = widget.recipients[_index];
    final progress = (_index + 1) / widget.recipients.length;
    final statusColor = _queueStatusColor(recipient.record.status.name);

    return Column(
      children: [
        LinearProgressIndicator(value: progress),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Message ${_index + 1} of ${widget.recipients.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                statusColor.withValues(alpha: 0.15),
                            child: Icon(Icons.school_outlined,
                                color: statusColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recipient.record.student.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.bold),
                                ),
                                Text('Roll No: '
                                    '${recipient.record.student.rollNumber}'),
                              ],
                            ),
                          ),
                          Chip(
                            label: Text(recipient.record.status.name),
                            backgroundColor:
                                statusColor.withValues(alpha: 0.15),
                            labelStyle:
                                TextStyle(color: statusColor),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const Divider(),
                      _infoRow(context, Icons.person_outline, 'Parent',
                          recipient.guardian.name),
                      _infoRow(context, Icons.phone_outlined, 'Phone',
                          recipient.guardian.phone),
                      const SizedBox(height: 8),
                      Text(
                        'Message',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(recipient.message),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _index = _index + 1),
                    icon: const Icon(Icons.skip_next_outlined),
                    label: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _opening ? null : _openSms,
                    icon: _opening
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sms_outlined),
                    label: const Text('Open SMS'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label,
      String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 8),
          Text('$label: ', style: Theme.of(context).textTheme.bodyMedium),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Color _queueStatusColor(String status) {
    switch (status) {
      case 'present':
        return AppTheme.presentColor;
      case 'absent':
        return AppTheme.absentColor;
      case 'late':
        return AppTheme.lateColor;
      default:
        return Colors.grey;
    }
  }
}

class _SmsRecipient {
  final AttendanceWithDetails record;
  final StudentWithDetails details;
  final ParentGuardian guardian;
  final String message;

  _SmsRecipient({
    required this.record,
    required this.details,
    required this.guardian,
    required this.message,
  });
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}