import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/utils/formatters.dart';
import '../database/daos/attendance_dao.dart';
import '../database/daos/homework_dao.dart';
import '../database/daos/student_dao.dart';

class ExportService {
  ExportService({
    required AttendanceDao attendanceDao,
    required HomeworkDao homeworkDao,
    required StudentDao studentDao,
  })  : _attendanceDao = attendanceDao,
        _homeworkDao = homeworkDao,
        _studentDao = studentDao;

  final AttendanceDao _attendanceDao;
  final HomeworkDao _homeworkDao;
  final StudentDao _studentDao;

  static String _cell(String value) {
    final v = value.replaceAll('"', '""');
    if (v.contains(',') || v.contains('\n') || v.contains('"')) {
      return '"$v"';
    }
    return v;
  }

  static String _row(List<String> cells) =>
      '${cells.map(_cell).join(',')}\n';

  Future<File> exportAttendance({DateTime? from, DateTime? to}) async {
    final records = await _attendanceDao.getAllAttendanceWithDetails();
    final buffer = StringBuffer();
    buffer.write(_row([
      'Date',
      'Roll',
      'Student',
      'Status',
    ]));
    for (final r in records) {
      final d = r.attendance.date;
      if (from != null && d.isBefore(from)) continue;
      if (to != null && d.isAfter(to)) continue;
      buffer.write(_row([
        Formatters.isoFormat.format(d),
        r.student.rollNumber,
        r.student.name,
        r.status.name,
      ]));
    }
    return _writeFile('attendance_export', 'csv', buffer.toString());
  }

  Future<File> exportStudents() async {
    final students = await _studentDao.getAllStudents();
    final details = <StudentWithDetails>[];
    for (final s in students) {
      final d = await _studentDao.getStudentWithDetails(s.id);
      if (d != null) details.add(d);
    }

    final buffer = StringBuffer();
    buffer.write(_row([
      'Roll',
      'Name',
      'Gender',
      'Date of Birth',
      'Class',
      'Division',
      'Guardian',
      'Guardian Phone',
    ]));
    for (final d in details) {
      final guardian = d.guardians.isNotEmpty ? d.guardians.first : null;
      buffer.write(_row([
        d.student.rollNumber,
        d.student.name,
        d.student.gender ?? '',
        d.student.dateOfBirth != null
            ? Formatters.isoFormat.format(d.student.dateOfBirth!)
            : '',
        d.classData?.name ?? '',
        d.division?.name ?? '',
        guardian?.name ?? '',
        guardian?.phone ?? '',
      ]));
    }
    return _writeFile('students_export', 'csv', buffer.toString());
  }

  Future<File> exportHomework() async {
    final submissions = await _homeworkDao.getAllSubmissionsWithDetails();
    final buffer = StringBuffer();
    buffer.write(_row([
      'Assignment',
      'Status',
      'Due Date',
      'Roll',
      'Student',
      'Submitted On',
      'Text',
      'Attachment',
      'Feedback',
    ]));
    for (final s in submissions) {
      final onTime = s.submission.submittedAt.isAfter(s.assignment.dueDate)
          ? 'Late'
          : 'Submitted';
      buffer.write(_row([
        s.assignment.title,
        onTime,
        Formatters.dateTimeFormat.format(s.assignment.dueDate),
        s.student.rollNumber,
        s.student.name,
        Formatters.dateTimeFormat.format(s.submission.submittedAt),
        s.submission.submissionText ?? '',
        s.submission.attachmentName ?? '',
        s.submission.feedback ?? '',
      ]));
    }
    return _writeFile('homework_export', 'csv', buffer.toString());
  }

  Future<File> _writeFile(
      String baseName, String ext, String content) async {
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/${baseName}_$timestamp.$ext');
    await file.writeAsString(content);
    return file;
  }

  Future<void> shareFile(File file, {String? subject}) async {
    final baseName = file.path.split('\\').last.split('/').last;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: subject ?? baseName,
        text: subject,
      ),
    );
  }
}