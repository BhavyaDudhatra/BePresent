import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final DateFormat dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat monthYearFormat = DateFormat('MMM yyyy');
  static final DateFormat dayFormat = DateFormat('EEEE');
  static final DateFormat shortDateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat isoFormat = DateFormat('yyyy-MM-dd');

  static String formatDate(DateTime date) => dateFormat.format(date);
  static String formatDateTime(DateTime date) => dateTimeFormat.format(date);
  static String formatMonthYear(DateTime date) => monthYearFormat.format(date);
  static String formatDay(DateTime date) => dayFormat.format(date);
  static String formatShortDate(DateTime date) => shortDateFormat.format(date);

  static String attendancePercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }
}
