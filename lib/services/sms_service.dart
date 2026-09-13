import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class SmsService {
  static const MethodChannel _bulkChannel = MethodChannel('com.bepresent/sms');

  Future<void> composeSms({
    required String phoneNumber,
    required String message,
  }) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final uri = Uri(
      scheme: 'sms',
      path: cleanPhone,
      queryParameters: {'body': message},
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw SmsException('Could not open SMS composer');
    }
  }

  /// Sends a message to every parent at once using Android's SmsManager.
  /// Returns the number of messages sent. Throws [SmsException] when the
  /// runtime SMS permission is denied or sending is unavailable.
  Future<int> sendBatchSms(
    List<({String phone, String message})> messages,
  ) async {
    if (messages.isEmpty) return 0;

    if (!Platform.isAndroid) {
      throw SmsException('Auto-send is only available on Android.');
    }

    try {
      final sent = await _bulkChannel
          .invokeMethod<int>('sendBatch', {
            'messages': [
              for (final m in messages)
                {'phone': m.phone, 'message': m.message},
            ],
          })
          .timeout(const Duration(seconds: 20));
      return sent ?? 0;
    } on PlatformException catch (e) {
      throw SmsException(e.message ?? 'SMS sending failed');
    } on TimeoutException {
      throw SmsException('SMS sending timed out. Please try again.');
    }
  }

  String buildAbsentMessage({
    required String studentName,
    required String className,
    required String divisionName,
    required DateTime date,
    String schoolName = 'Be Present',
  }) {
    final dateStr = '${date.day} ${_monthName(date.month)} ${date.year}';
    return 'Dear Parent,\n\n'
        'Your child $studentName was marked ABSENT on $dateStr.\n'
        'Class: $className-$divisionName\n\n'
        'Please contact the school if necessary.\n\n'
        '— $schoolName';
  }

  String buildLateMessage({
    required String studentName,
    required String className,
    required String divisionName,
    required DateTime date,
    String schoolName = 'Be Present',
  }) {
    final dateStr = '${date.day} ${_monthName(date.month)} ${date.year}';
    return 'Dear Parent,\n\n'
        'Your child $studentName was marked LATE on $dateStr.\n'
        'Class: $className-$divisionName\n\n'
        'Please ensure timely arrival.\n\n'
        '— $schoolName';
  }

  String buildPresentMessage({
    required String studentName,
    required String className,
    required String divisionName,
    required DateTime date,
    String schoolName = 'Be Present',
  }) {
    final dateStr = '${date.day} ${_monthName(date.month)} ${date.year}';
    return 'Dear Parent,\n\n'
        'Your child $studentName was marked PRESENT on $dateStr.\n'
        'Class: $className-$divisionName\n\n'
        '— $schoolName';
  }

  String buildAttendanceReport({
    required String studentName,
    required String className,
    required String divisionName,
    required int totalDays,
    required int presentDays,
    required int absentDays,
    required int lateDays,
    required double percentage,
    String schoolName = 'Be Present',
  }) {
    return 'Attendance Report for $studentName\n'
        'Class: $className-$divisionName\n\n'
        'Total Days: $totalDays\n'
        'Present: $presentDays\n'
        'Absent: $absentDays\n'
        'Late: $lateDays\n'
        'Attendance: ${percentage.toStringAsFixed(1)}%\n\n'
        '— $schoolName';
  }

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month];
  }
}

class SmsException implements Exception {
  final String message;
  SmsException(this.message);

  @override
  String toString() => message;
}