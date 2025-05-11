import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

class UtcDateTime implements Comparable<UtcDateTime> {
  UtcDateTime(DateTime time) : timeAsUtc = time.toUtc();

  factory UtcDateTime.direct(
    int year,
    int month,
    int day, {
    int hour = 0,
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

  @override
  String toString() {
    return timeAsUtc.toString();
  }
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

  @override
  String toString() {
    return timeAsLocal.toString();
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

/// Compares a and b and returns the one which is ordered first,
/// preferring a if the comparison returns 0.
T anyMin<T extends Comparable<T>>(T a, T b) {
  final cmp = a.compareTo(b);
  // a.compareTo(b) returns negative if a is ordered before b
  // -------------- returns zero if a and b are equal
  // -------------- returns positive if a is ordered after b
  if (cmp <= 0) {
    return a;
  } else {
    return b;
  }
}

/// Compares a and b and returns the one which is ordered last,
/// preferring a if the comparison returns 0.
T anyMax<T extends Comparable<T>>(T a, T b) {
  final cmp = a.compareTo(b);
  // a.compareTo(b) returns negative if a is ordered before b
  // -------------- returns zero if a and b are equal
  // -------------- returns positive if a is ordered after b
  if (cmp >= 0) {
    return a;
  } else {
    return b;
  }
}

List<(T, int, int)> buildLikeRanges<T, TElem>(Iterable<TElem> iter, {required T Function(TElem) firstFunc, required (bool, T) Function(T, TElem) shouldCombineFunc}) {
  var ranges = <(T, int, int)>[];
  var iterator = iter.iterator;
  if (iterator.moveNext()) {
    int currentRangeStart = 0;
    T currentRangeVal = firstFunc(iterator.current);
    int i = 1;
    while (iterator.moveNext()) {
      final (shouldCombine, next) = shouldCombineFunc(currentRangeVal, iterator.current);
      // If we're still in the same range as the previous hour
      if (shouldCombine) {
        currentRangeVal = next;
        continue;
      } else {
        ranges.add((currentRangeVal, currentRangeStart, i - 1));
        currentRangeStart = i;
        currentRangeVal = next;
      }

      i++;
    }
    ranges.add((currentRangeVal, currentRangeStart, i - 1));
  }
  return ranges;
}
