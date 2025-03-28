import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

class UtcDateTime implements Comparable<UtcDateTime> {
  UtcDateTime(DateTime time) : timeAsUtc = time.toUtc();

  factory UtcDateTime.direct(
    int year,
    int month,
    int day, {
    required int hour,
    int minute = 0,
  }) =>
      UtcDateTime(DateTime.utc(year, month, day, hour, minute));

  factory UtcDateTime.timestamp() => UtcDateTime(DateTime.timestamp());

  static UtcDateTime? tryParseAndCoerceFullIso8601(String str) {
    final time = DateTime.tryParse(str);
    if (time == null) {
      return null;
    } else {
      return UtcDateTime(time);
    }
  }

  factory UtcDateTime.parseAndCoerceFullIso8601(String full) => UtcDateTime(DateTime.parse(full));
  factory UtcDateTime.parsePartialIso8601AsUtc(String partial) => UtcDateTime(DateTime.parse("${partial}Z"));

  final DateTime timeAsUtc;

  LocalDateTime toLocal() => LocalDateTime(timeAsUtc.toLocal());

  bool isBefore(UtcDateTime other) => timeAsUtc.isBefore(other.timeAsUtc);

  bool isAfter(UtcDateTime other) => timeAsUtc.isAfter(other.timeAsUtc);

  UtcDateTime add(Duration duration) => UtcDateTime(timeAsUtc.add(duration));

  UtcDateTime subtract(Duration duration) => UtcDateTime(timeAsUtc.subtract(duration));

  /// Returns a [Duration] with the difference when subtracting [other] from this [DateTime].
  ///
  /// The returned [Duration] will be negative if [other] occurs after this [DateTime].
  ///
  /// ```
  /// final berlinWallFell = DateTime.utc(1989, DateTime.november, 9);
  /// final dDay = DateTime.utc(1944, DateTime.june, 6);
  ///
  /// final difference = berlinWallFell.difference(dDay);
  /// print(difference.inDays); // 16592
  /// ```
  Duration difference(UtcDateTime other) => timeAsUtc.difference(other.timeAsUtc);

  String toIso8601String() => timeAsUtc.toIso8601String();

  @override
  int compareTo(UtcDateTime other) => timeAsUtc.compareTo(other.timeAsUtc);
}

class UtcDateTimeJsonConverter extends JsonConverter<UtcDateTime, String> {
  const UtcDateTimeJsonConverter();

  @override
  UtcDateTime fromJson(String json) => UtcDateTime.parseAndCoerceFullIso8601(json);

  @override
  String toJson(UtcDateTime object) => object.toIso8601String();
}

class LocalDateTime {
  LocalDateTime(DateTime time) : timeAsLocal = time.toLocal();

  final DateTime timeAsLocal;

  UtcDateTime toUtc() => UtcDateTime(timeAsLocal.toUtc());

  LocalDateTime add(Duration duration) => LocalDateTime(timeAsLocal.add(duration));

  LocalDateTime subtract(Duration duration) => LocalDateTime(timeAsLocal.subtract(duration));

  Duration difference(UtcDateTime other) => timeAsLocal.difference(other.timeAsUtc);

  int get hour => timeAsLocal.hour;
  int get minute => timeAsLocal.minute;

  String jmFormat() {
    return DateFormat.jm().format(timeAsLocal);
  }
}

class UtcDateTimeConverter implements JsonConverter<UtcDateTime, String> {
  const UtcDateTimeConverter();

  @override
  UtcDateTime fromJson(String json) => UtcDateTime(DateTime.parse(json));

  @override
  String toJson(UtcDateTime dateTime) => dateTime.timeAsUtc.toIso8601String();
}

// TODO UtcDateTimeMatcher to get the tests to pass

String jmFormatHour(int hour) => DateFormat.jm().format(DateTime(2000, 1, 1, hour = hour));
