import 'dart:convert';
import 'dart:math' as math;

import 'package:json_annotation/json_annotation.dart';
import 'package:turnip_rundown/data/units.dart';
import 'package:turnip_rundown/data/weather/insights.dart';
import 'package:turnip_rundown/util.dart';

part 'repository.g.dart';

@JsonEnum()
enum TempDisplay {
  celsius,
  farenheit,
  both;

  Iterable<Temp> displayUnits() {
    switch (this) {
      case TempDisplay.celsius:
        return [Temp.celsius];
      case TempDisplay.farenheit:
        return [Temp.farenheit];
      case TempDisplay.both:
        return [Temp.celsius, Temp.farenheit];
    }
  }
}

@JsonSerializable()
class WakingHours {
  /// 0..=23, indicates the start of the user's "waking hours" in 24hr local time.
  final int start;

  /// 0..=23, indicates the end of the user's "waking hours" in 24hr local time.
  ///
  /// if [end] > [start], the user wakes up at (0:00AM + [start]) and falls asleep at (0:00AM + [end]).
  ///  the total hours awake = (end - start), which will always be < 24.
  ///
  /// if [end] == [start], the user is always awake.
  ///  the total hours awake = 24.
  ///
  /// if [end] < [start], the user wakes up at (0:00AM + [start]) and falls asleep at (0:00AM + [end] + 24) i.e. falls asleep the next calendar day.
  ///  the total hours awake = (end + 24 - start), which will always be < 24 and will always be > 0.
  final int end;

  const WakingHours({required this.start, required this.end});

  factory WakingHours.initial() => const WakingHours(start: 8, end: 22);

  factory WakingHours.fromJson(Map<String, dynamic> json) => _$WakingHoursFromJson(json);
  Map<String, dynamic> toJson() => _$WakingHoursToJson(this);

  WakingHours copyWith({int? start, int? end}) {
    return WakingHours(
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  int numHoursToLookaheadWhenUnlocked(int currentHourLocalTime) {
    if (end == start) return 24;
    if (end > start) {
      final hoursAsleep = 24 - (end - start);
      if (currentHourLocalTime < start) {
        // we're in the pre-start time
        if ((start - currentHourLocalTime) > hoursAsleep / 2) {
          // we are further than halfway from waking up
          // => lookahead until the wake-up time
          return start - currentHourLocalTime;
        } else {
          // we are closer than halfway to waking up
          // => lookahead for the *next* day i.e. until the end time
          return end - currentHourLocalTime;
        }
      } else if (currentHourLocalTime < end) {
        // we're in the mid-time, make the weather prediction look ahead until the end hour
        return (end - currentHourLocalTime) + 1;
      } else {
        // we're in the post-end time
        if ((currentHourLocalTime - end) <= hoursAsleep / 2) {
          // we are not yet halfway to waking up
          // => lookahead until the wake-up time tomorrow
          return start + 24 - currentHourLocalTime;
        } else {
          // we are closer than halfway to waking up
          // => lookahead for the next day i.e. until the end time
          return end + 24 - currentHourLocalTime;
        }
      }
    } else {
      // end < start
      final hoursAsleep = (start - end);

      if (currentHourLocalTime >= start) {
        // we're awake, at the start of the day
        // => lookahead until the end of the day
        return end + 24 - currentHourLocalTime;
      } else if (currentHourLocalTime < end) {
        // we're awake, before the end of the day
        // => lookahead until the end of the day
        return end - currentHourLocalTime;
      } else {
        // we're asleep, end < currentHourLocalTime < start
        if ((currentHourLocalTime - end) > hoursAsleep / 2) {
          // we're closer to the start of the next day then to the end of the previous
          // => lookahead for the *next* day i.e. until the end time
          return end + 24 - currentHourLocalTime;
        } else {
          // we're closer to the end of the previous day than the start of the next day
          // => lookahead until the start of the next day
          return start - currentHourLocalTime;
        }
      }
    }
  }

  int numHoursToLookahead(UtcDateTime? lockedUtcLookaheadTo) {
    final utcTime = UtcDateTime.timestamp();

    if (lockedUtcLookaheadTo != null && utcTime.isBefore(lockedUtcLookaheadTo)) {
      return math.min(24, (lockedUtcLookaheadTo.difference(utcTime).inMinutes / 60).ceil());
    }

    return numHoursToLookaheadWhenUnlocked(utcTime.toLocal().hour);
  }
}

@JsonEnum(alwaysCreate: true)
enum RequestedWeatherBackend {
  openmeteo,
  met,
}

@JsonSerializable()
class Settings {
  Settings({
    required this.temperatureUnit,
    required this.rainfallUnit,
    required this.weatherConfig,
    required this.wakingHours,
    required this.backend,
  });

  @JsonKey(defaultValue: TempDisplay.both)
  final TempDisplay temperatureUnit;
  @JsonKey(defaultValue: Rainfall.mm)
  final Rainfall rainfallUnit;

  // TODO round current location preference

  @JsonKey(fromJson: WeatherInsightConfigV2.migrateFromJson)
  final WeatherInsightConfigV2 weatherConfig;

  @JsonKey(defaultValue: WakingHours.initial)
  final WakingHours wakingHours;

  @JsonKey(defaultValue: RequestedWeatherBackend.openmeteo) // TODO set the default to met when it's ready
  final RequestedWeatherBackend backend;

  factory Settings.initial() => Settings.fromJson(jsonDecode("{}"));

  factory Settings.fromJson(Map<String, dynamic> json) => _$SettingsFromJson(json);
  Map<String, dynamic> toJson() => _$SettingsToJson(this);
}

abstract interface class SettingsRepository {
  Settings get settings;
  Future<void> storeSettings(Settings settings);
  UtcDateTime? get lockedUtcLookaheadTo;
  Future<void> storeLockedUtcLookaheadTo(UtcDateTime? lockedUtcLookaheadTo);
  Coordinate? get lastGeocoordLookup;
  Future<void> storeLastGeocoordLookup(Coordinate? lastGeocoordLookup);
}
