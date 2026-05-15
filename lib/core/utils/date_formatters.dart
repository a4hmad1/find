import 'package:intl/intl.dart';

class DateFormatters {
  static final _date = DateFormat('yyyy/MM/dd');
  static final _time = DateFormat('HH:mm');

  static String date(DateTime? value) {
    if (value == null) return 'دیاری نەکراوە';
    return _date.format(value.toLocal());
  }

  static String time(DateTime? value) {
    if (value == null) return '';
    return _time.format(value.toLocal());
  }

  static String dateTime(DateTime? value) {
    if (value == null) return 'دیاری نەکراوە';
    return '${date(value)} - ${time(value)}';
  }
}
