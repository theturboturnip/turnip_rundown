// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SunriseSunset _$SunriseSunsetFromJson(Map<String, dynamic> json) =>
    SunriseSunset(
      nextSunrise: _$JsonConverterFromJson<String, UtcDateTime>(
          json['nextSunrise'], const UtcDateTimeJsonConverter().fromJson),
      nextSunset: _$JsonConverterFromJson<String, UtcDateTime>(
          json['nextSunset'], const UtcDateTimeJsonConverter().fromJson),
    );

Map<String, dynamic> _$SunriseSunsetToJson(SunriseSunset instance) =>
    <String, dynamic>{
      'nextSunrise': _$JsonConverterToJson<String, UtcDateTime>(
          instance.nextSunrise, const UtcDateTimeJsonConverter().toJson),
      'nextSunset': _$JsonConverterToJson<String, UtcDateTime>(
          instance.nextSunset, const UtcDateTimeJsonConverter().toJson),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);

WeatherDataBank _$WeatherDataBankFromJson(Map<String, dynamic> json) =>
    WeatherDataBank(
      datapointDateTimes: (json['datapointDateTimes'] as List<dynamic>)
          .map((e) => const UtcDateTimeJsonConverter().fromJson(e as String))
          .toList(),
      precipitation: DataSeries<Length>.fromJson(
          json['precipitation'] as Map<String, dynamic>),
      precipitationProb: DataSeries<Percent>.fromJson(
          json['precipitationProb'] as Map<String, dynamic>),
      dryBulbTemp: DataSeries<Temp>.fromJson(
          json['dryBulbTemp'] as Map<String, dynamic>),
      estimatedWetBulbGlobeTemp: DataSeries<Temp>.fromJson(
          json['estimatedWetBulbGlobeTemp'] as Map<String, dynamic>),
      windspeed:
          DataSeries<Speed>.fromJson(json['windspeed'] as Map<String, dynamic>),
      relHumidity: DataSeries<Percent>.fromJson(
          json['relHumidity'] as Map<String, dynamic>),
      snowfall:
          DataSeries<Length>.fromJson(json['snowfall'] as Map<String, dynamic>),
      directRadiation: json['directRadiation'] == null
          ? null
          : DataSeries<SolarRadiation>.fromJson(
              json['directRadiation'] as Map<String, dynamic>),
      cloudCover: json['cloudCover'] == null
          ? null
          : DataSeries<Percent>.fromJson(
              json['cloudCover'] as Map<String, dynamic>),
      sunriseSunset: json['sunriseSunset'] == null
          ? null
          : SunriseSunset.fromJson(
              json['sunriseSunset'] as Map<String, dynamic>),
      uvIndex:
          DataSeries<UVIndex>.fromJson(json['uvIndex'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$WeatherDataBankToJson(WeatherDataBank instance) =>
    <String, dynamic>{
      'datapointDateTimes': instance.datapointDateTimes
          .map(const UtcDateTimeJsonConverter().toJson)
          .toList(),
      'precipitation': instance.precipitation.toJson(),
      'precipitationProb': instance.precipitationProb.toJson(),
      'dryBulbTemp': instance.dryBulbTemp.toJson(),
      'estimatedWetBulbGlobeTemp': instance.estimatedWetBulbGlobeTemp.toJson(),
      'windspeed': instance.windspeed.toJson(),
      'relHumidity': instance.relHumidity.toJson(),
      'snowfall': instance.snowfall.toJson(),
      'directRadiation': instance.directRadiation?.toJson(),
      'cloudCover': instance.cloudCover?.toJson(),
      'uvIndex': instance.uvIndex.toJson(),
      'sunriseSunset': instance.sunriseSunset?.toJson(),
    };
