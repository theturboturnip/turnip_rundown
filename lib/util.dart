import 'package:intl/intl.dart';

String jmLocalTime(DateTime date) {
  return DateFormat.jm().format(date.toLocal());
}
