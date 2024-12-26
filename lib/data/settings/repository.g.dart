// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
    );

Map<String, dynamic> _$SettingsToJson(Settings instance) => <String, dynamic>{
      'temperatureUnit': _$TempDisplayEnumMap[instance.temperatureUnit]!,
      'rainfallUnit': _$LengthEnumMap[instance.rainfallUnit]!,
      'weatherConfig': instance.weatherConfig,
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
