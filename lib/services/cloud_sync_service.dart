import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../core/utils/formatters.dart';
import '../database/daos/attendance_dao.dart';
import '../database/daos/homework_dao.dart';
import '../database/daos/settings_dao.dart';

class SyncResult {
  final bool success;
  final String message;
  SyncResult(this.success, this.message);
}

class CloudSyncService {
  final SettingsDao _settingsDao;
  final AttendanceDao _attendanceDao;
  final HomeworkDao _homeworkDao;

  CloudSyncService(this._settingsDao, this._attendanceDao, this._homeworkDao);

  Future<String?> _getUrl() async {
    final enabled = (await _settingsDao.getValueOr(
            AppConstants.settingsSyncEnabled, 'false')) ==
        'true';
    if (!enabled) return null;
    final url = (await _settingsDao.getValue(AppConstants.settingsSyncUrl))
        ?.trim();
    if (url == null || url.isEmpty || !url.startsWith('http')) return null;
    return url;
  }

  Future<bool> _push(String sheet, List<String>? header, List<List<String>> rows) async {
    final url = await _getUrl();
    if (url == null || rows.isEmpty) return false;
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'sheet': sheet, 'header': header, 'rows': rows}),
          )
          .timeout(const Duration(seconds: 25));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> pushAttendance(List<AttendanceWithDetails> records) async {
    final rows = records.map((r) {
      return [
        Formatters.isoFormat.format(r.attendance.date),
        r.student.rollNumber,
        r.student.name,
        r.status.name,
        r.status.label,
      ];
    }).toList();
    return _push(
      'Attendance',
      ['Date', 'Roll', 'Student', 'Status Code', 'Status Label'],
      rows,
    );
  }

  Future<bool> pushSubmission(HomeworkSubmissionSync record) {
    final now = record.submission.submittedAt;
    final late = now.isAfter(record.assignment.dueDate) ? 'Late' : 'On Time';
    return _push(
      'Homework Submissions',
      ['Assignment', 'Class', 'Division', 'Roll', 'Student', 'Submitted On',
       'Received Timely', 'Text', 'Attachment', 'Feedback'],
      [
        [
          record.assignment.title,
          record.assignment.classId.toString(),
          record.assignment.divisionId.toString(),
          record.student.rollNumber,
          record.student.name,
          Formatters.dateTimeFormat.format(now),
          late,
          record.submission.submissionText ?? '',
          record.submission.attachmentName ?? '',
          record.submission.feedback ?? '',
        ],
      ],
    );
  }

  Future<SyncResult> syncNow() async {
    try {
      final url = await _getUrl();
      if (url == null) {
        return SyncResult(
            false, 'Cloud sync is disabled or the Apps Script URL is not set. '
                'Enable it in Profile > Cloud Sync.');
      }
      final attendance = await _attendanceDao.getAllAttendanceWithDetails();
      final attRows = attendance.map((r) {
        return [
          Formatters.isoFormat.format(r.attendance.date),
          r.student.rollNumber,
          r.student.name,
          r.status.name,
          r.status.label,
        ];
      }).toList();
      final ok1 = await _push(
        'Attendance',
        ['Date', 'Roll', 'Student', 'Status Code', 'Status Label'],
        attRows,
      );

      final submissions = await _homeworkDao.getAllSubmissionsWithDetails();
      final subRows = submissions.map((s) {
        final late = s.submission.submittedAt
            .isAfter(s.assignment.dueDate);
        return [
          s.assignment.title,
          s.student.rollNumber,
          s.student.name,
          Formatters.dateTimeFormat.format(s.submission.submittedAt),
          late ? 'Late' : 'On Time',
          s.submission.submissionText ?? '',
          s.submission.attachmentName ?? '',
          s.submission.feedback ?? '',
        ];
      }).toList();
      final ok2 = await _push(
        'Homework Submissions',
        ['Assignment', 'Roll', 'Student', 'Submitted On', 'Received Timely',
         'Text', 'Attachment', 'Feedback'],
        subRows,
      );

      await _settingsDao.setValue(
        AppConstants.settingsLastSyncAt,
        DateTime.now().toIso8601String(),
      );

      final parts = <String>[
        if (ok1) '${attRows.length} attendance',
        if (ok2) '${subRows.length} homework rows',
      ];
      if (parts.isEmpty) {
        return SyncResult(false, 'Nothing was pushed. Check the URL.');
      }
      return SyncResult(true, 'Pushed: ${parts.join(', ')}');
    } catch (e) {
      return SyncResult(false, 'Sync failed: $e');
    }
  }

  Future<DateTime?> getLastSyncAt() async {
    final raw = await _settingsDao.getValue(AppConstants.settingsLastSyncAt);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}