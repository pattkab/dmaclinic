import 'package:intl/intl.dart';

class DateUtilsX {
  static String todayKey() => DateFormat('d-M-y').format(DateTime.now());

  static String dateKey(DateTime d) => DateFormat('d-M-y').format(d);
}
