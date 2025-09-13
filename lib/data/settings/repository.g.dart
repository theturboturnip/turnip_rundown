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
    <String, dynamic>{'start': instance.start, 'end': instance.end};

Settings _$SettingsFromJson(Map<String, dynamic> json) => Settings(
  temperatureUnit:
      $enumDecodeNullable(_$TempDisplayEnumMap, json['temperatureUnit']) ??
      TempDisplay.both,
  rainfallUnit:
      $enumDecodeNullable(_$LengthEnumMap, json['rainfallUnit']) ?? Length.mm,
  weatherConfig: WeatherInsightConfigV2.migrateFromJson(
    json['weatherConfig'] as Map<String, dynamic>?,
  ),
  wakingHours: json['wakingHours'] == null
      ? WakingHours.initial()
      : WakingHours.fromJson(json['wakingHours'] as Map<String, dynamic>),
  backend:
      $enumDecodeNullable(_$RequestedWeatherBackendEnumMap, json['backend']) ??
      RequestedWeatherBackend.openmeteo,
);

Map<String, dynamic> _$SettingsToJson(Settings instance) => <String, dynamic>{
  'temperatureUnit': _$TempDisplayEnumMap[instance.temperatureUnit]!,
  'rainfallUnit': _$LengthEnumMap[instance.rainfallUnit]!,
  'weatherConfig': instance.weatherConfig.toJson(),
  'wakingHours': instance.wakingHours.toJson(),
  'backend': _$RequestedWeatherBackendEnumMap[instance.backend]!,
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

const _$RequestedWeatherBackendEnumMap = {
  RequestedWeatherBackend.openmeteo: 'openmeteo',
  RequestedWeatherBackend.met: 'met',
};
