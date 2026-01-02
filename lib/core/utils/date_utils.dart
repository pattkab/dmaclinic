import 'package:intl/intl.dart';

class DateUtilsX {
  static String todayKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  static String dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
}
