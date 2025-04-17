// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OpenMeteoHourlyRequest _$OpenMeteoHourlyRequestFromJson(
        Map<String, dynamic> json) =>
    OpenMeteoHourlyRequest(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      generationtime_ms: (json['generationtime_ms'] as num).toDouble(),
      utc_offset_seconds: (json['utc_offset_seconds'] as num).toDouble(),
      timezone: json['timezone'] as String,
      timezone_abbreviation: json['timezone_abbreviation'] as String,
      elevation: (json['elevation'] as num).toDouble(),
      hourly_units: Map<String, String>.from(json['hourly_units'] as Map),
      hourly: OpenMeteoHourlyDatapoints.fromJson(
          json['hourly'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OpenMeteoHourlyRequestToJson(
        OpenMeteoHourlyRequest instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'generationtime_ms': instance.generationtime_ms,
      'utc_offset_seconds': instance.utc_offset_seconds,
      'timezone': instance.timezone,
      'timezone_abbreviation': instance.timezone_abbreviation,
      'elevation': instance.elevation,
      'hourly_units': instance.hourly_units,
      'hourly': instance.hourly,
    };

OpenMeteoHourlyDatapoints _$OpenMeteoHourlyDatapointsFromJson(
        Map<String, dynamic> json) =>
    OpenMeteoHourlyDatapoints(
      time: (json['time'] as List<dynamic>).map((e) => e as String).toList(),
      temperature: (json['temperature_2m'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      relHumidity: (json['relative_humidity_2m'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      dewPoint: (json['dew_point_2m'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      precipitationProb: (json['precipitation_probability'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      precipitation: (json['precipitation'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      windspeed: (json['wind_speed_10m'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      directRadiation: (json['direct_radiation_instant'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      snowfall: (json['snowfall'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      cloudCover: (json['cloud_cover'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      uvIndex: (json['uv_index'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
    );

Map<String, dynamic> _$OpenMeteoHourlyDatapointsToJson(
        OpenMeteoHourlyDatapoints instance) =>
    <String, dynamic>{
      'time': instance.time,
      'temperature_2m': instance.temperature,
      'relative_humidity_2m': instance.relHumidity,
      'dew_point_2m': instance.dewPoint,
      'precipitation_probability': instance.precipitationProb,
      'precipitation': instance.precipitation,
      'wind_speed_10m': instance.windspeed,
      'direct_radiation_instant': instance.directRadiation,
      'snowfall': instance.snowfall,
      'cloud_cover': instance.cloudCover,
      'uv_index': instance.uvIndex,
    };
