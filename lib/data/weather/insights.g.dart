// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insights.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeatherInsightConfig _$WeatherInsightConfigFromJson(
        Map<String, dynamic> json) =>
    WeatherInsightConfig(
      useEstimatedWetBulbTemp: json['useEstimatedWetBulbTemp'] as bool,
      numberOfHoursPriorRainThreshold:
          (json['numberOfHoursPriorRainThreshold'] as num).toInt(),
      priorRainThreshold: Data<Length>.fromJson(
          json['priorRainThreshold'] as Map<String, dynamic>),
      rainProbabilityThreshold: Data<Percent>.fromJson(
          json['rainProbabilityThreshold'] as Map<String, dynamic>),
      mediumRainThreshold: Data<Length>.fromJson(
          json['mediumRainThreshold'] as Map<String, dynamic>),
      heavyRainThreshold: Data<Length>.fromJson(
          json['heavyRainThreshold'] as Map<String, dynamic>),
      highHumidityThreshold: Data<Percent>.fromJson(
          json['highHumidityThreshold'] as Map<String, dynamic>),
      maxTemperatureForHighHumidityMist: Data<Temp>.fromJson(
          json['maxTemperatureForHighHumidityMist'] as Map<String, dynamic>),
      minTemperatureForHighHumiditySweat: Data<Temp>.fromJson(
          json['minTemperatureForHighHumiditySweat'] as Map<String, dynamic>),
      minimumBreezyWindspeed: Data<Speed>.fromJson(
          json['minimumBreezyWindspeed'] as Map<String, dynamic>),
      minimumWindyWindspeed: Data<Speed>.fromJson(
          json['minimumWindyWindspeed'] as Map<String, dynamic>),
      minimumGaleyWindspeed: Data<Speed>.fromJson(
          json['minimumGaleyWindspeed'] as Map<String, dynamic>),
      boilingMinTemp: json['boilingMinTemp'] == null
          ? const Data(20, Temp.celsius)
          : Data<Temp>.fromJson(json['boilingMinTemp'] as Map<String, dynamic>),
      freezingMaxTemp: json['freezingMaxTemp'] == null
          ? const Data(5, Temp.celsius)
          : Data<Temp>.fromJson(
              json['freezingMaxTemp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$WeatherInsightConfigToJson(
        WeatherInsightConfig instance) =>
    <String, dynamic>{
      'useEstimatedWetBulbTemp': instance.useEstimatedWetBulbTemp,
      'numberOfHoursPriorRainThreshold':
          instance.numberOfHoursPriorRainThreshold,
      'priorRainThreshold': instance.priorRainThreshold,
      'rainProbabilityThreshold': instance.rainProbabilityThreshold,
      'mediumRainThreshold': instance.mediumRainThreshold,
      'heavyRainThreshold': instance.heavyRainThreshold,
      'highHumidityThreshold': instance.highHumidityThreshold,
      'maxTemperatureForHighHumidityMist':
          instance.maxTemperatureForHighHumidityMist,
      'minTemperatureForHighHumiditySweat':
          instance.minTemperatureForHighHumiditySweat,
      'minimumBreezyWindspeed': instance.minimumBreezyWindspeed,
      'minimumWindyWindspeed': instance.minimumWindyWindspeed,
      'minimumGaleyWindspeed': instance.minimumGaleyWindspeed,
      'boilingMinTemp': instance.boilingMinTemp,
      'freezingMaxTemp': instance.freezingMaxTemp,
    };
