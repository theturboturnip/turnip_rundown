// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WakingHours _$WakingHoursFromJson(Map<String, dynamic> json) => WakingHours(
      start: (json['start'] as num).toInt(),
      end: (json['end'] as num).toInt(),
    );

Map<String, dynamic> _$WakingHoursToJson(WakingHours instance) =>
    <String, dynamic>{
      'start': instance.start,
      'end': instance.end,
    };

Settings _$SettingsFromJson(Map<String, dynamic> json) => Settings(
      temperatureUnit:
          $enumDecodeNullable(_$TempDisplayEnumMap, json['temperatureUnit']) ??
              TempDisplay.both,
      rainfallUnit:
          $enumDecodeNullable(_$LengthEnumMap, json['rainfallUnit']) ??
              Length.mm,
      weatherConfig: json['weatherConfig'] == null
          ? WeatherInsightConfig.initial()
          : WeatherInsightConfig.fromJson(
              json['weatherConfig'] as Map<String, dynamic>),
      wakingHours: json['wakingHours'] == null
          ? WakingHours.initial()
          : WakingHours.fromJson(json['wakingHours'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SettingsToJson(Settings instance) => <String, dynamic>{
      'temperatureUnit': _$TempDisplayEnumMap[instance.temperatureUnit]!,
      'rainfallUnit': _$LengthEnumMap[instance.rainfallUnit]!,
      'weatherConfig': instance.weatherConfig,
      'wakingHours': instance.wakingHours,
    };

const _$TempDisplayEnumMap = {
  TempDisplay.celsius: 'celsius',
  TempDisplay.farenheit: 'farenheit',
  TempDisplay.both: 'both',
};

const _$LengthEnumMap = {
  Length.m: 'm',
  Length.cm: 'cm',
  Length.mm: 'mm',
  Length.inch: 'inch',
};
